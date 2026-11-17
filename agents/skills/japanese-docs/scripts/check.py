#!/usr/bin/env python3
"""日本語文書を機械的に検査し、規則違反の候補を出力する。

使い方：python check.py <対象ファイル>...
出力：<ファイル>:<行>:<列>: <分類>（<参照先>）: <ヒットした文字列>
終了コード：0 ヒットなし、1 ヒットあり、2 ファイルを読めない
"""

import os
import re
import sys

from prose import (
    front_matter_end,
    masked_text,
    original_text,
    outside_brackets,
    paragraphs,
    prose_lines,
    sentences,
)

JA = r"\u3005\u3040-\u30ff\u3400-\u4dbf\u4e00-\u9fff"

# (分類, 参照先, パターン, インラインコードも検査するか)
CHECKS = [
    (
        "漢字表記",
        "references/conventions.md 漢字とひらがなの使い分け",
        r"出来|下さい|する事|た事|事が|事は|為|無い|様々|更に|及び|但し|又は",
        False,
    ),
    (
        "述語",
        "references/sentence.md 述語に中身を入れる",
        r"ことができ|ことが可能|を行",
        False,
    ),
    (
        "和欧間スペース",
        "references/conventions.md チームの決定事項",
        rf"[A-Za-z0-9`] [{JA}]|[{JA}] [A-Za-z0-9`]",
        True,
    ),
    ("全角数字", "references/conventions.md 数字", r"[０-９]", False),
    (
        "相対日付",
        "references/conventions.md 日付・時刻",
        r"先日|先週|今週|来週|先月|今月|来月|昨日|明日|最近",
        False,
    ),
    (
        "記号",
        "references/conventions.md 記号",
        rf"！|(?<=[{JA}])!|―|—|～|\.\.\.|(?<!…)…(?!…)"
        rf"|[{JA}][()]|[()][{JA}]|[^\s・、。\x00\u3040-\u309f]+・[^\s・、。\x00\u3040-\u309f]+・[^\s・、。\x00\u3040-\u309f]+",
        False,
    ),
    (
        "日付形式",
        "references/conventions.md 日付・時刻",
        r"\d{4}/\d{1,2}/\d{1,2}",
        False,
    ),
    (
        "絵文字",
        "references/conventions.md 記号",
        r"[🌀-🫿☀-➿]",
        False,
    ),
    (
        "確信度",
        "references/sentence.md 確信度は文末で一度だけ示す",
        r"に他ならない|ケースバイケース|一概には言えません",
        False,
    ),
    (
        "出典不明",
        "references/sentence.md 動作主を読み手がたどれるようにする",
        r"業界の専門家によると|調査結果が示すように",
        False,
    ),
    (
        "受動態",
        "references/sentence.md 動作主を読み手がたどれるようにする",
        r"が求められ|が必要とされ|とされてい|が望まれ",
        False,
    ),
    (
        "英語の構文",
        "references/sentence.md 英語の構文を写さない",
        r"重要なのは|掘り下げる|深掘りする|を示しており|を物語っている",
        False,
    ),
    (
        "対比",
        "references/sentence.md 英語の構文を写さない",
        r"単なる[^。、]*ではなく",
        False,
    ),
    (
        "抽象語",
        "references/sentence.md 具体的な動作は具体的な語で書く",
        r"多角的|包括的|非常に|極めて|大いに|という形|という観点から|という側面から",
        False,
    ),
    (
        "ビジネスジャーゴン",
        "references/sentence.md 具体的な動作は具体的な語で書く",
        r"レバレッジ|ソリューション|イノベーティブ|コミットする|アライン"
        r"|ディープダイブ|スケールする|ピボット",
        False,
    ),
    (
        "太字",
        "SKILL.md 構成と論証の規則",
        r"\*\*[^*\s][^*]*\*\*|__[^_\s][^_]*__",
        False,
    ),
    (
        "敬語",
        "references/conventions.md 敬語",
        r"させていただ|おっしゃられ|に関しまして",
        False,
    ),
]

CONVENTIONS = os.path.join(
    os.path.dirname(os.path.abspath(__file__)), "..", "references", "conventions.md"
)


def unused_terms():
    """用語統一表の「表記（使わない）」列の語を返す。"""
    with open(CONVENTIONS, encoding="utf-8") as f:
        section = f.read().split("## 用語統一表", 1)[1].split("\n## ", 1)[0]
    rows = [line for line in section.splitlines() if line.startswith("|")]
    terms = []
    for row in rows[2:]:
        cells = [c.strip() for c in row.strip("|").split("|")]
        terms += [t.strip() for t in cells[1].split("、") if t.strip()]
    return terms


CHECKS.append(
    (
        "用語",
        "references/conventions.md 用語統一表",
        "|".join(map(re.escape, unused_terms())),
        False,
    )
)

COMPILED = [(name, ref, re.compile(pat), raw) for name, ref, pat, raw in CHECKS]

MAX_SENTENCE_LENGTH = 100
MAX_CLAUSE_COMMAS = 2
CLAUSE_COMMA = re.compile(r"(?:[してでがりばらく]|ところ|ため)、")
GUESS = re.compile(r"可能性がある|かもしれない|と考えられる|と思われる|と推測される|だろう")
HEDGE = re.compile(r"ことがある|場合がある|可能性がある")
CONJUNCTION = re.compile(r"(さらに|また|加えて)、")
POLITE = re.compile(r"(?:です|ます|でした|ました|ません|ましょう|でしょう|ください)[かね]?。$")
PLAIN = re.compile(r"[るただうい]。$")

ONE_THING = "references/sentence.md 一文に一つの事柄を書く"
CONFIDENCE = "references/sentence.md 確信度は文末で一度だけ示す"
RELATION = "references/sentence.md 文と文の関係を一つ選んで示す"
STYLE = "references/conventions.md 文体"


def snippet(text):
    return text if len(text) <= 20 else text[:20] + "…"


def sentence_hits(sentence):
    masked = masked_text(sentence)
    text = original_text(sentence)
    lineno, col = sentence[0].lineno, sentence[0].col
    hits = []
    if len(masked) > MAX_SENTENCE_LENGTH:
        hits.append((lineno, col, "長い文", ONE_THING, f"{snippet(text)}（{len(masked)}字）"))
    own = masked_text(outside_brackets(sentence))
    if len(CLAUSE_COMMA.findall(own)) > MAX_CLAUSE_COMMAS:
        hits.append((lineno, col, "節の連鎖", ONE_THING, snippet(text)))
    guesses = GUESS.findall(own)
    if len(guesses) > 1:
        hits.append((lineno, col, "推量の重ね", CONFIDENCE, "＋".join(guesses)))
    return hits


def paragraph_hits(para):
    """段落内で2回目以降に現れたヘッジと文頭の接続詞を返す。"""
    hits = []
    own = outside_brackets(para)
    for m in list(HEDGE.finditer(masked_text(own)))[1:]:
        ch = own[m.start()]
        hits.append((ch.lineno, ch.col, "ヘッジの重ね", CONFIDENCE, m.group(0)))
    starts = []
    for sentence in sentences(para):
        m = CONJUNCTION.match(masked_text(sentence))
        if m:
            starts.append((sentence, m.group(1)))
    for sentence, word in starts[1:]:
        ch = sentence[0]
        hits.append((ch.lineno, ch.col, "接続詞の重ね", RELATION, word))
    return hits


def style(sentence):
    masked = masked_text(sentence)
    if POLITE.search(masked):
        return "敬体"
    if PLAIN.search(masked):
        return "常体"
    return None


def style_hits(all_sentences):
    """文書の多数派と異なる文体の文を返す。同数なら最初の文の文体を多数派とする。"""
    styled = [(s, style(s)) for s in all_sentences]
    styled = [(s, st) for s, st in styled if st]
    if not styled:
        return []
    counts = {st: sum(1 for _, x in styled if x == st) for _, st in styled}
    majority = max(counts, key=counts.get)
    hits = []
    for sentence, st in styled:
        if st != majority:
            ch = sentence[0]
            text = snippet(original_text(sentence))
            hits.append((ch.lineno, ch.col, "文体の混在", STYLE, text))
    return hits


def line_hits(lineno, masked, line):
    hits = []
    for name, ref, pattern, raw in COMPILED:
        for hit in pattern.finditer(line if raw else masked):
            hits.append((lineno, hit.start() + 1, name, ref, hit.group(0)))
    return hits


def check_file(path):
    with open(path, encoding="utf-8") as f:
        raw = f.read().splitlines()
    lines = list(prose_lines(raw))
    body = [line for line in lines if line[0] > front_matter_end(raw)]

    hits = []
    for line in lines:
        hits += line_hits(*line)
    all_sentences = []
    for para in paragraphs(body):
        hits += paragraph_hits(para)
        for sentence in sentences(para):
            hits += sentence_hits(sentence)
            all_sentences.append(sentence)
    hits += style_hits(all_sentences)
    return [
        f"{path}:{lineno}:{col}: {name}（{ref}）: {text}"
        for lineno, col, name, ref, text in sorted(hits, key=lambda h: h[:2])
    ]


def main(argv):
    sys.stdout.reconfigure(encoding="utf-8")
    sys.stderr.reconfigure(encoding="utf-8")
    if not argv:
        print(__doc__.strip(), file=sys.stderr)
        return 2

    status = 0
    for path in argv:
        try:
            hits = check_file(path)
        except (OSError, UnicodeDecodeError) as e:
            print(f"{path}: {e}", file=sys.stderr)
            status = 2
            continue
        for hit in hits:
            print(hit)
        if hits:
            status = max(status, 1)
    return status


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
