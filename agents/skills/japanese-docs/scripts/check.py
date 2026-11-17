#!/usr/bin/env python3
"""日本語文書を機械的に検査し、規則違反の候補を出力する。

使い方：python check.py <対象ファイル>...
出力：<ファイル>:<行>:<列>: <分類>（<参照先>）: <ヒットした文字列>
終了コード：0 ヒットなし、1 ヒットあり、2 ファイルを読めない
"""

import re
import sys

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
        rf"！|(?<=[{JA}])!|―|—|～",
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
        "英語の構文",
        "references/sentence.md 英語の構文を写さない",
        r"重要なのは|掘り下げる|深掘りする|を示しており|を物語っている",
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
        "太字ラベル",
        "SKILL.md 構成と論証の規則",
        r"\*\*[^*]{1,20}[:：]\*\*",
        False,
    ),
    (
        "敬語",
        "references/conventions.md 敬語",
        r"させていただ|おっしゃられ|に関しまして",
        False,
    ),
]

COMPILED = [(name, ref, re.compile(pat), raw) for name, ref, pat, raw in CHECKS]
FENCE = re.compile(r"^ {0,3}(`{3,}|~{3,})")
INLINE_CODE = re.compile(r"(`+)(.+?)\1")


def mask_inline_code(line):
    """インラインコードを同じ長さのNUL文字に置き換え、列位置を保つ。"""
    return INLINE_CODE.sub(lambda m: "\x00" * len(m.group(0)), line)


def check_file(path):
    with open(path, encoding="utf-8") as f:
        lines = f.read().splitlines()

    hits = []
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

        masked = mask_inline_code(line)
        line_hits = []
        for name, ref, pattern, raw in COMPILED:
            for hit in pattern.finditer(line if raw else masked):
                line_hits.append((hit.start() + 1, name, ref, hit.group(0)))
        for col, name, ref, text in sorted(line_hits):
            hits.append(f"{path}:{lineno}:{col}: {name}（{ref}）: {text}")
    return hits


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
