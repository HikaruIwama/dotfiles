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

## type一覧

| type | 用途 | 例 |
| --- | --- | --- |
| `feat` | 新機能 | `feat(auth): ログイン機能を追加` |
| `fix` | バグ修正 | `fix(api): ユーザー取得時のnull参照を修正` |
| `docs` | ドキュメントのみ | `docs: READMEにセットアップ手順を追加` |
| `style` | コードの意味に影響しない変更 | `style: インデントをスペース2に統一` |
| `refactor` | リファクタリング | `refactor(core): 共通処理をutilsに切り出し` |
| `perf` | パフォーマンス改善 | `perf(db): クエリのN+1問題を解消` |
| `test` | テストの追加・修正 | `test(auth): ログイン失敗時のテストを追加` |
| `build` | ビルドシステムや依存関係 | `build(deps): reactを18.2.0に更新` |
| `ci` | CI設定 | `ci: GitHub Actionsのワークフローを追加` |
| `chore` | その他の雑多な変更 | `chore: .gitignoreにtmp/を追加` |

## subjectの書き方

- 日本語OK。英語でもよい。
- 命令形または動詞の連体形で始める。「追加する」「修正する」「更新する」など。
- 50文字以内。
- 末尾にピリオド（`.`）や句点（`。`）を付けない。
- 「バグ修正」だけのような曖昧な表現にしない。何をどう変えたかが1文でわかるようにする。

良い例：

- `feat(auth): パスワードリセット機能を追加`
- `fix(api): ユーザーIDが0のときにエラーになる問題を修正`
- `refactor(ui): ボタンコンポーネントのpropsを整理`

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
fix(api): ユーザーIDが0のときにエラーになる問題を修正

ユーザーIDに0を許可するバリデーションが抜けていた。
本番データにID=0のユーザーが存在するため、修正が必要。
```

## footerの書き方

- 後方互換性のない変更：`BREAKING CHANGE: 説明`または`type!:`で表す。
- issueを閉じる場合：`Closes #123`

例：

```text
feat(api)!: レスポンス形式をv2に変更

BREAKING CHANGE: ユーザー情報のレスポンスからemailフィールドを削除
Closes #456
```
