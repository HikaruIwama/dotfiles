import os
import re
import tempfile
import unittest

import check

SKILL_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
HIT = re.compile(r"^.*?:(\d+):(\d+): (.+?)（(.+?)）: (.*)$")


def run(text):
    with tempfile.NamedTemporaryFile(
        "w", encoding="utf-8", suffix=".md", delete=False
    ) as f:
        f.write(text)
    try:
        lines = check.check_file(f.name)
    finally:
        os.unlink(f.name)
    hits = []
    for line in lines:
        m = HIT.match(line)
        assert m, line
        hits.append((int(m[1]), int(m[2]), m[3], m[5]))
    return hits


def categories(text):
    return [h[2] for h in run(text)]


class ExistingChecksTest(unittest.TestCase):
    def test_reports_line_column_category_and_match(self):
        self.assertEqual(run("一行目\n確認を行う。\n"), [(2, 3, "述語", "を行")])

    def test_line_patterns(self):
        cases = [
            ("設定する事。", "漢字表記"),
            ("実行することができる。", "述語"),
            ("APIを使う LLM が", "和欧間スペース"),
            ("１件", "全角数字"),
            ("先週決めた。", "相対日付"),
            ("完了！", "記号"),
            ("それはケースバイケースだ。", "確信度"),
            ("業界の専門家によると正しい。", "出典不明"),
            ("重要なのは速さだ。", "英語の構文"),
            ("非常に速い。", "抽象語"),
            ("ソリューションを入れる。", "ビジネスジャーゴン"),
            ("- **速さ：**十分", "太字"),
            ("拝見させていただきました。", "敬語"),
        ]
        for text, category in cases:
            with self.subTest(text=text):
                self.assertIn(category, categories(text))

    def test_skips_code_blocks_and_inline_code(self):
        text = "```\n確認を行う。\n```\n`確認を行う`ことにする\n"
        self.assertEqual(run(text), [])

    def test_space_check_looks_around_inline_code(self):
        self.assertEqual(categories("`foo` を使う"), ["和欧間スペース"])

    def test_clean_text_has_no_hits(self):
        self.assertEqual(run("設定ファイルを確認する。\n"), [])


class AddedLinePatternsTest(unittest.TestCase):
    def test_hits(self):
        cases = [
            ("負荷試験の実施が求められる。", "受動態", "が求められ"),
            ("対応が必要とされている。", "受動態", "が必要とされ"),
            ("単なる修正ではなく、設計の変更だ。", "対比", "単なる修正ではなく"),
            ("待つ...", "記号", "..."),
            ("待つ…", "記号", "…"),
            ("関数(引数)を呼ぶ", "記号", "数("),
            ("設計・実装・試験を行う", "記号", "設計・実装・試験"),
            ("2026/08/06に決めた", "日付形式", "2026/08/06"),
            ("リリース🚀", "絵文字", "🚀"),
        ]
        for text, category, match in cases:
            with self.subTest(text=text):
                self.assertIn(category, categories(text))
                self.assertIn(match, [h[3] for h in run(text)])

    def test_allowed_forms(self):
        cases = [
            "`a`・`b`・`c`を使う",
            "[手順](../a.md)を読む",
            "待つ……",
            "（引数）を呼ぶ",
            "PR・Issueの説明",
            "2026-08-06に決めた",
            "原因は特定されていない。",
        ]
        for text in cases:
            with self.subTest(text=text):
                self.assertEqual(run(text), [])


class BoldTest(unittest.TestCase):
    def test_bold_in_a_sentence(self):
        self.assertEqual(
            run("設定は**必ず**保存し、__再起動__する。\n"),
            [(1, 4, "太字", "**必ず**"), (1, 14, "太字", "__再起動__")],
        )

    def test_code_and_identifiers_are_not_bold(self):
        self.assertEqual(run("`**kwargs`と`__init__`を使う。\n"), [])


class TermTableTest(unittest.TestCase):
    def test_flags_terms_listed_as_not_used(self):
        self.assertEqual(
            run("サインインして、分かる。"),
            [(1, 1, "用語", "サインイン"), (1, 9, "用語", "分かる")],
        )

    def test_terms_listed_as_used_are_allowed(self):
        self.assertEqual(run("ログインして、わかる。"), [])


class SentenceTest(unittest.TestCase):
    def test_long_sentence_is_reported_at_its_start(self):
        text = "前置き。" + "あ" * 100 + "。\n"
        self.assertEqual(run(text), [(1, 5, "長い文", "あ" * 20 + "…（101字）")])

    def test_sentence_of_100_chars_is_allowed(self):
        self.assertEqual(run("あ" * 99 + "。\n"), [])

    def test_sentence_spanning_lines_is_one_sentence(self):
        text = "あ" * 60 + "\n" + "い" * 60 + "。\n"
        self.assertEqual(categories(text), ["長い文"])

    def test_three_clauses_joined_by_commas(self):
        self.assertEqual(
            run("変更し、再起動して、確認したが、遅い。短い。\n"),
            [(1, 1, "節の連鎖", "変更し、再起動して、確認したが、遅い。")],
        )

    def test_two_clause_commas_are_allowed(self):
        self.assertEqual(run("変更し、再起動して、確認した。\n"), [])

    def test_commas_in_an_enumeration_are_not_counted(self):
        self.assertEqual(run("設計、実装、試験、運用、保守を担う。\n"), [])

    def test_front_matter_is_not_a_paragraph(self):
        text = "---\nname: a\ndescription: " + "あ" * 60 + "\n---\n" + "い" * 60 + "。\n"
        self.assertEqual(run(text), [])

    def test_period_inside_brackets_does_not_split(self):
        text = "例は「" + "あ。" * 30 + "」と" + "い" * 50 + "。\n"
        self.assertEqual(categories(text), ["長い文"])

    def test_list_items_and_table_rows_are_separate(self):
        text = "- " + "あ" * 60 + "\n- " + "い" * 60 + "\n| " + "う" * 60 + " |\n"
        self.assertEqual(run(text), [])


class ModalityTest(unittest.TestCase):
    def test_stacked_guesses_in_one_sentence(self):
        self.assertEqual(
            run("前置き。原因は不整合である可能性があると考えられる。\n"),
            [(1, 5, "推量の重ね", "可能性がある＋と考えられる")],
        )

    def test_quoted_examples_are_not_counted(self):
        text = (
            "悪い例：「変更し、再起動して、確認したが、遅い。」\n\n"
            "悪い例：「不整合の可能性があると考えられる。」\n\n"
            "「失敗することがある」「直る場合がある」と書く。\n"
        )
        self.assertEqual(run(text), [])

    def test_single_guess_is_allowed(self):
        self.assertEqual(run("原因は不整合と考えられる。ログは未確認かもしれない。\n"), [])

    def test_hedges_in_one_paragraph(self):
        text = "失敗することがある。\n再試行で直る場合がある。\n\n別の段落で起きることがある。\n"
        self.assertEqual(run(text), [(2, 7, "ヘッジの重ね", "場合がある")])

    def test_conjunctions_in_one_paragraph(self):
        text = "Aを直した。また、Bを直した。さらに、Cを直した。\n\nまた、Dを直した。\n"
        self.assertEqual(run(text), [(1, 16, "接続詞の重ね", "さらに")])


class StyleTest(unittest.TestCase):
    def test_reports_sentences_in_the_minority_style(self):
        text = "設定を変更します。再起動する。\n\n- ログを確認してください。\n"
        self.assertEqual(run(text), [(1, 10, "文体の混在", "再起動する。")])

    def test_tie_keeps_the_style_of_the_first_sentence(self):
        text = "設定を変更した。再起動しました。\n"
        self.assertEqual(run(text), [(1, 9, "文体の混在", "再起動しました。")])

    def test_unterminated_and_quoted_endings_are_not_counted(self):
        text = "設定を変更します。\n\n- 再起動する\n\n悪い例：「再起動する。」\n"
        self.assertEqual(run(text), [])


class ReferenceTest(unittest.TestCase):
    def test_every_reference_points_to_an_existing_heading(self):
        for name, ref, *_ in check.CHECKS:
            filename, section = ref.split(" ", 1)
            path = os.path.join(SKILL_DIR, filename)
            with self.subTest(name=name, ref=ref):
                with open(path, encoding="utf-8") as f:
                    headings = re.findall(r"^#+ (.+)$", f.read(), re.M)
                self.assertIn(section, headings)


if __name__ == "__main__":
    unittest.main()
