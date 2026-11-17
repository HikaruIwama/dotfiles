"""Markdownの本文を、行、段落、文に分ける。"""

import re
from typing import NamedTuple

FENCE = re.compile(r"^ {0,3}(`{3,}|~{3,})")
CODE = re.compile(r"(`+)(.+?)\1|(?<=\])\([^)\s]*\)")
LIST_ITEM = re.compile(r"^\s*(?:[-*+]|\d+\.)\s+")
OPEN_BRACKETS = "「『（(“"
CLOSE_BRACKETS = "」』）)”"
TERMINATORS = "。！？"


class Char(NamedTuple):
    masked: str
    original: str
    lineno: int
    col: int


def mask_code(line):
    """インラインコードとリンク先を同じ長さのNUL文字に置き換え、列位置を保つ。"""
    return CODE.sub(lambda m: "\x00" * len(m.group(0)), line)


def masked_text(chars):
    return "".join(ch.masked for ch in chars)


def original_text(chars):
    return "".join(ch.original for ch in chars)


def prose_lines(lines):
    """コードブロックを除いた行を、(行番号, 伏せた行, 元の行)で返す。"""
    fence = None
    for lineno, line in enumerate(lines, 1):
        m = FENCE.match(line)
        if fence:
            if m and m.group(1)[0] == fence[0] and len(m.group(1)) >= len(fence):
                fence = None
            continue
        if m:
            fence = m.group(1)
            continue
        yield lineno, mask_code(line), line


def front_matter_end(lines):
    """YAML front matterの終わりの行番号を返す。なければ0。"""
    if lines and lines[0] == "---":
        for lineno, line in enumerate(lines[1:], 2):
            if line == "---":
                return lineno
    return 0


def paragraphs(lines):
    """段落をCharの並びで返す。見出しと表は除き、リスト項目は1項目を1段落とする。"""
    para = []
    for lineno, masked, line in lines:
        stripped = masked.strip()
        item = LIST_ITEM.match(masked)
        if not stripped or stripped.startswith(("#", "|")) or item:
            if para:
                yield para
            para = []
            if not item:
                continue
        start = item.end() if item else len(masked) - len(masked.lstrip())
        para += [
            Char(masked[i], line[i], lineno, i + 1) for i in range(start, len(masked))
        ]
    if para:
        yield para


def bracket_depths(chars):
    """各文字と、括弧の入れ子の深さの組を返す。括弧そのものは内側に数える。"""
    depth = 0
    for ch in chars:
        if ch.masked in OPEN_BRACKETS:
            depth += 1
            yield ch, depth
        elif ch.masked in CLOSE_BRACKETS:
            yield ch, depth
            depth = max(depth - 1, 0)
        else:
            yield ch, depth


def outside_brackets(chars):
    """引用や作例を除くため、括弧の外の文字だけを返す。"""
    return [ch for ch, depth in bracket_depths(chars) if depth == 0]


def sentences(para):
    """括弧の外の句点で段落を文に分ける。"""
    current = []
    for ch, depth in bracket_depths(para):
        current.append(ch)
        if ch.masked in TERMINATORS and depth == 0:
            yield current
            current = []
    if current:
        yield current
