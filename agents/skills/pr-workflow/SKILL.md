---
name: pr-workflow
description: PRを作成するときのワークフロー。事前チェック、baseブランチ決定、タイトル・本文生成、gh pr create実行、検証の手順を定める。
---

# PR Workflow

PRを作成するときのワークフロー。エージェントが実行する。対話的な操作は使わない。

## 1. 事前確認

変更内容を把握する。`<base>`がまだ決まっていない場合は、デフォルトブランチ（`main`や`master`）に対して実行する。

```sh
git status --short
git log --oneline -10
git diff <base>...HEAD
```

- どのファイルがどう変わったか
- コミットが意味のある単位に分割されているか。不適切な場合はPR作成に進む前にユーザーへ相談する
- デバッグ用コード（`console.log`など）や無関係な変更が混ざっていないか

同じブランチから既にPRが作られていないか確認する。既存PRがある場合は新規作成せず、既存PRの更新が必要かユーザーに確認する。

```sh
gh pr list --head <branch>
```

リポジトリにlintやtestのコマンドがあれば実行する。`package.json`のscripts、`Makefile`、`lefthook.yml`、`.github/workflows/`などから特定する。失敗した場合は修正してから進む。失敗したまま作成する場合はユーザーに理由を確認する。

PRの言語はリポジトリの慣習に従う。上のコミット履歴と`gh pr list --state all --limit 10`で判定する。

- 日本語中心なら日本語、英語中心なら英語で書く。混在している場合は直近の傾向を優先する
- 判定できない場合（新規リポジトリなど）はユーザーに確認する

## 2. baseブランチを決定する

以下の順で決める。

1. ユーザーの指定
2. `git config branch.<current>.gh-merge-base`
3. リポジトリのデフォルトブランチ（`gh repo view --json defaultBranchRef`）

## 3. タイトル・本文を作成する

`references/title-and-body.md`に従う。

## 4. PRの内容をユーザーに確認する

base・headブランチ、タイトル、本文の全文をまとめて提示し、承認を得る。タイトルや要約だけの提示では不十分。

```text
以下の内容でPRを作成します。

base: main ← head: feat/xxx

タイトル:
feat: ログイン機能を追加

本文:
---
## 概要

...
---

この内容でよいですか？Draftで作成しますか？
```

- Draftで作成するかを同時に確認する
- レビュワー・ラベル・アサイニーは、ユーザーから明示的な指示がある場合のみ付与する。推測して提案しない
- 修正要望があれば調整して再度提示する。承認されるまで繰り返す

## 5. pushする

承認後、未pushまたはリモートに遅れている場合は`git push -u origin <branch>`でpushする。`gh pr create`のpushプロンプトに任せない。

## 6. PRを作成する

本文はファイル書き込みツールで一時ファイルに書き出し、`--body-file`で渡す。`--body`への直接埋め込みや、シェルのリダイレクト・ヒアドキュメントでのファイル作成は、PowerShellでは文字の解釈や文字コード（5.1の`>`はUTF-16LE）で本文が壊れるため使わない。

```sh
gh pr create --title "<タイトル>" --body-file <本文ファイル> --base <baseブランチ> [オプション]
```

- Draft：`--draft`
- レビュワー：`--reviewer <login>`（複数指定可）
- アサイニー：`--assignee <login>`（自分なら`@me`）
- ラベル：`--label <name>`（複数指定可）

`--fill`は使わない。PowerShellでタイトルに`$`やバッククォートを含む場合はシングルクォートで囲む。タイトルにダブルクォートは使わない。

作成に失敗した場合：

- 「already exists」系のエラー：既存PRがある。新規作成ではなく既存PRの更新が必要かユーザーに相談する
- 認証エラー：`gh auth status`で認証状態を確認し、ユーザーに伝える
- baseブランチが見つからない：指定したbaseが正しいか確認する

## 7. 検証する

本文が文字化けせず、Markdownのセクション構成が保たれているか確認する。`--jq`で値だけを取り出すと、改行がエスケープされずにそのまま読める。

```sh
gh pr view --json body --jq .body
gh pr checks
```

CIが即座に失敗している場合は原因を調べる。最後にPRのURLを提示し、CIの状態や注意点があればあわせて伝える。

## やってはいけないこと

- force-push、baseブランチへの直接push
- `--body`への本文の直接埋め込み
- 承認前のpush、タイトル・本文を提示せずにPRを作成する
- 対話的な`gh pr create`（プロンプトに頼る実行）
- レビュワー・ラベルの推測
