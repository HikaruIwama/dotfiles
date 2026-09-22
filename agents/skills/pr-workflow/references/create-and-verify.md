# PRの作成と検証

`gh pr create`でPRを作成し、作成後に状態を確認する。

## 作成前の前提

内容の承認、Draftの可否、オプション指定は確認ステップ（`references/confirm-content.md`）で完了済みとする。ここで再度ユーザーに確認はしない。

headブランチが未pushの場合は、承認後に`git push -u origin <branch>`でpush済みのはず。`gh pr create`のpushプロンプトに任せない。

## PRの作成

以下の形式で実行する。

```sh
gh pr create --title "<タイトル>" --body-file <本文ファイル> --base <baseブランチ> [オプション]
```

オプション：

- Draftの場合：`--draft`
- レビュワー：`--reviewer <login>`（複数指定可）
- アサイニー：`--assignee <login>`（自分なら`@me`）
- ラベル：`--label <name>`（複数指定可）

注意：

- 本文は必ず`--body-file`で渡す。`--body`に直接埋め込まない（`references/shell-and-body.md`を参照）
- `--fill`は使わない。コミット履歴からの自動生成ではなく、差分を読んで作成した本文を使う
- 対話的なプロンプトに頼らない。必要な情報はすべてフラグで渡す

## 作成後の検証

### PRの確認

```sh
gh pr view --json title,baseRefName,headRefName,url
```

- タイトルが意図した内容で登録されているか
- base・headブランチが正しいか

本文の確認は`--json`に含めず、`--jq`で別途取り出す。

```sh
gh pr view --json body --jq .body
```

`--json body`だけだと出力がJSON文字列のままで、改行が`\n`のエスケープシーケンスとして表示される。本文が1行に潰れて見えるため、セクション構成や文字化けの目視確認ができない。`--jq .body`で値だけを取り出せば、実際の改行で表示されてそのまま読める。

確認すること：

- 本文が意図した内容で登録されているか
- 本文が文字化けしていないか
- Markdownのセクション構成が保たれているか

### CIの確認

```sh
gh pr checks
```

- CIが設定されている場合、チェックの状態を確認する
- 即座に失敗している場合は原因を調べてユーザーに報告する
- 実行中の場合はその旨を伝える

### ユーザーへの報告

最後にPRのURLを提示する。

```text
PRを作成しました：<URL>
```

CIの状態や注意点があればあわせて伝える。

## 作成に失敗した場合

- 「already exists」系のエラー：既存PRがある。`gh pr list --head <branch>`で確認し、新規作成ではなく既存PRの更新が必要かユーザーに相談する
- 認証エラー：`gh auth status`で認証状態を確認し、ユーザーに伝える
- baseブランチが見つからない：指定したbaseが正しいか確認する
