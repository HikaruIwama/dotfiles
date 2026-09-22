---
name: git-commit-workflow
description: コミットを作成するときのワークフロー。変更の分割、staging、メッセージ作成、検証の手順を定める。
---

# Git Commit Workflow

コミットを作成するときのワークフロー。エージェントが実行する。対話的な操作は使わない。

## ワークフロー

1. 現状把握

   ```sh
   git status --short
   git diff HEAD
   git log --oneline -10
   ```

2. 変更を意味のある単位に分割する
   → `references/granularity.md`を参照

3. ユニットごとにstagingする
   → `references/staging.md`を参照

4. Conventional Commits形式でメッセージを書く
   → `references/commit-message.md`を参照

5. コミット後に検証する
   → `references/verification.md`を参照

## やってはいけないこと

詳細は`references/prohibitions.md`を参照。

- 対話的なstaging操作（`git add -p`など）
- 包括的なstaging操作（`git add -A`など）
- `git commit -a` / `-am`
- `git reset`、force-push
- `fix typo`だけのコミット
- 複数の無関係な変更を1コミットにまとめる

## 参照

- `references/granularity.md`：コミットの粒度と分割基準
- `references/staging.md`：非対話的なstaging方法
- `references/commit-message.md`：Conventional Commits形式のメッセージ規範
- `references/prohibitions.md`：禁止事項の詳細
- `references/verification.md`：コミット前後の確認手順
