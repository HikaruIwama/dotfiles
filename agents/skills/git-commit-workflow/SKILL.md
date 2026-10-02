---
name: git-commit-workflow
description: コミットを作成するときのワークフロー。変更の分割、staging、メッセージ作成、検証の手順を定める。
---

# Git Commit Workflow

コミットを作成するときのワークフロー。エージェントが実行する。対話的な操作は使わない。

## 1. 現状を把握する

```sh
git status --short
git diff HEAD
git log --oneline -10
```

既にstaging済みの変更があれば、今回のコミットに含めてよいか確認する。判断できない場合はユーザーに確認する。

## 2. 変更を意味のある単位に分割する

1コミットは目的を1つにし、そのコミット単体でビルド・テストが通る状態にする。

- 種類の異なる変更（`feat`、`fix`、`refactor`、`docs`など）は別コミットにする
- 「ついでに直した」無関係な変更は別コミットにする
- 依存関係がある場合は、依存される側を先にコミットする
- ファイル移動と参照の更新は1コミットにまとめる。分けると片方だけの状態でビルドが壊れる

```text
refactor(api): extract shared error handling
feat(api): add user creation endpoint
docs: fix typo in README
```

以降の3〜5をユニットごとに繰り返す。

## 3. stagingする

ファイル単位で`git add <path>`する。1つのファイルに複数ユニットの変更が混ざっている場合は、`references/partial-staging.md`に従う。

stagingが意図した範囲か確認する。想定外のファイル、無関係な変更、デバッグ用コード（`console.log`など）が含まれていれば`git restore --staged <path>`で外して、stagingし直す。

```sh
git diff --cached --stat
git diff --cached
git diff --cached --check
```

## 4. コミットする

メッセージは`references/commit-message.md`に従って書く。

subjectだけなら`-m`で渡してよい。bodyやfooterがある場合は、ファイル書き込みツールで一時ファイルに書き出し、`-F`で渡す。PowerShellでは複数行の引数や`$`、バッククォートが壊れるため、`-m`に複数行を埋め込まない。

```sh
git commit -m "fix(api): handle user ID 0"
git commit -F <メッセージファイル>
```

pre-commitフックが失敗した場合は、原因を直してから再度コミットする。フックがファイルを書き換えた場合は、差分を確認してstagingし直す。

## 5. 検証する

```sh
git show --stat HEAD
git log --oneline -5
```

- メッセージと差分が意図した内容か
- 直近のコミットが意図した順序で並んでいるか

問題が見つかった場合：

- 未pushの直前コミットのメッセージ誤り：`git commit --amend -F <メッセージファイル>`。indexに変更が残っていないことを先に確認する
- 内容の誤り：修正を新しいコミットとして追加する
- コミット自体の取り消し：`git revert --no-edit <commit>`

## やってはいけないこと

- 対話的な操作（`git add -p`、`git add -i`、エディタを開く`git commit`・`--amend`・`git revert`）。エージェントは実行できない
- 包括的なstaging（`git add -A`、`git add .`、`git add -u`）、`git commit -a`／`-am`。無関係な変更を巻き込む
- `--no-verify`によるフックの回避
- ユーザーの明示的な指示がない限り、以下は使わない
  - HEADを動かす`git reset`（`--soft`、`--hard`、コミット指定）、force-push、push済みコミットのamend。履歴を書き換える
  - `git restore <path>`（`--staged`なし）、`git checkout -- <path>`、`git clean`、`git stash`。作業ツリーの変更を失う
