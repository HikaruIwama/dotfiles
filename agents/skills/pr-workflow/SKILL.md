---
name: pr-workflow
description: PRを作成するときのワークフロー。シェル確認、事前チェック、baseブランチ決定、タイトル・本文生成、gh pr create実行、検証の手順を定める。
---

# PR Workflow

PRを作成するときのワークフロー。エージェントが実行する。対話的な操作は使わない。

## ワークフロー

0. 実行シェルを確認する
   → `references/shell-and-body.md`を参照

   以降のコマンドの書き方はすべてそのシェルに合わせる。

1. 事前確認
   → `references/pre-checks.md`を参照

   - 変更内容の把握（`git status`、`git diff`、コミット履歴）
   - 既存PRの重複確認（`gh pr list --head`）
   - PRタイトル・本文の言語判定（リポジトリの慣習に従う）
   - リポジトリに検証コマンド（lint/test）があれば実行

2. baseブランチを決定する

   - ユーザー指定があればそれを使う
   - なければ`gh-merge-base` config、それもなければリポジトリのデフォルトブランチ

3. タイトル・本文を作成する
   → `references/title-and-body.md`、`references/repo-template.md`を参照

   - リポジトリのPRテンプレがあればそれに従う
   - なければデフォルトテンプレを使う
   - 判定した言語で記述する

4. PRの内容をユーザーに確認する
   → `references/confirm-content.md`を参照

   - タイトルと本文の全文を提示して承認を得る
   - Draftで作成するかも同時に確認する
   - 修正要望があれば内容を調整して再度提示する
   - まだpushしていない場合、承認前にpushしない

5. pushする

   承認後、未pushまたはリモートに遅れている場合は`git push -u origin <branch>`でpushする。

6. PRを作成する
   → `references/create-and-verify.md`を参照

   本文は必ず一時ファイルに書き出し、`gh pr create --body-file`で非対話的に実行する。

7. 検証する
   → `references/create-and-verify.md`を参照

   - 作成されたPRのURLをユーザーに提示する
   - `gh pr checks`でCIの状態を確認する

## やってはいけないこと

- force-push、baseブランチへの直接push
- `--body`への複数行文字列の直接埋め込み（特にPowerShell環境で壊れる）
- シェルのリダイレクト・ヒアドキュメントでの本文ファイル生成（文字コードが破損する場合がある）
- 差分を読まずにコミットメッセージだけで本文を書く
- 既存PRの重複確認をスキップする
- 対話的な`gh pr create`（プロンプトに頼る実行）
- レビュワー・ラベルの自動推測
- タイトル・本文をユーザーに提示せずにPRを作成する
- 内容確認の承認前にpushする
- リポジトリに検証コマンド（lint/test）があるのに未実行でPRを作成する

## 参照

- `references/shell-and-body.md`：実行シェルの確認方法と本文の渡し方（`--body-file`必須化）
- `references/pre-checks.md`：事前確認（変更把握、既存PR重複、言語判定）
- `references/title-and-body.md`：タイトル規範（Conventional Commits準拠）とデフォルト本文テンプレ
- `references/repo-template.md`：リポジトリのPRテンプレの検出方法
- `references/confirm-content.md`：PR内容のユーザー確認（タイトル・本文の提示と承認、Draft確認）
- `references/create-and-verify.md`：`gh pr create`の実行と作成後の検証
