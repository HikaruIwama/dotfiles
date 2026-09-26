# Conventional Commits形式のコミットメッセージ

コミットメッセージは以下の形式で書く。

```text
type(scope): subject

body

footer
```

- `type`：必須。変更の種類。
- `scope`：任意。変更の範囲（モジュール、機能名など）。
- `subject`：必須。変更内容の要約。
- `body`：任意。変更の理由や背景。
- `footer`：任意。BREAKING CHANGEやissue参照。

メッセージは原則として英語で書く。直近のコミットが日本語中心なら日本語に合わせる。

## type一覧

| type | 用途 | 例 |
| --- | --- | --- |
| `feat` | 新機能 | `feat(auth): add login support` |
| `fix` | バグ修正 | `fix(api): handle null user responses` |
| `docs` | ドキュメントのみ | `docs: add setup instructions to README` |
| `style` | コードの意味に影響しない変更 | `style: use two-space indentation` |
| `refactor` | リファクタリング | `refactor(core): extract shared utilities` |
| `perf` | パフォーマンス改善 | `perf(db): eliminate N+1 queries` |
| `test` | テストの追加・修正 | `test(auth): cover failed logins` |
| `build` | ビルドシステムや依存関係 | `build(deps): update react to 18.2.0` |
| `ci` | CI設定 | `ci: add GitHub Actions workflow` |
| `chore` | その他の雑多な変更 | `chore: ignore tmp directory` |

## subjectの書き方

- 英語では命令形、日本語では動詞の連体形で始める。
- 50文字以内。
- 末尾にピリオド（`.`）や句点（`。`）を付けない。
- 「バグ修正」だけのような曖昧な表現にしない。何をどう変えたかが1文でわかるようにする。

良い例：

- `feat(auth): add password reset support`
- `fix(api): handle user ID 0`
- `refactor(ui): simplify button props`

悪い例：

- `fix: バグ修正` ← 何を修正したかわからない
- `update README.md.` ← ピリオドが付いている、updateはtypeではない
- `WIP` ← typeがない、内容が不明

## bodyの書き方

subjectだけでは理由が伝わらない場合に書く。

- 空行を挟んでsubjectと分ける。
- 「何を変えたか」ではなく「なぜ変えたか」を書く。
- 72文字ごとに折り返す。

例：

```text
fix(api): handle user ID 0

Validation rejected user ID 0, which exists in production data.
```

## footerの書き方

- 後方互換性のない変更：`BREAKING CHANGE: 説明`または`type!:`で表す。
- issueを閉じる場合：`Closes #123`

例：

```text
feat(api)!: update response format to v2

BREAKING CHANGE: remove email from user responses
Closes #456
```
