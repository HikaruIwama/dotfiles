# リポジトリのPRテンプレの検出

リポジトリにPRテンプレがあれば、デフォルトテンプレではなくそちらに従う。

## テンプレの配置場所

以下の順に探す。見つかった時点でそれを使う。

1. `.github/pull_request_template.md`
2. `.github/PULL_REQUEST_TEMPLATE.md`
3. `.github/PULL_REQUEST_TEMPLATE/`配下のファイル（複数ある場合。どれを使うかユーザーに確認）
4. `docs/pull_request_template.md`
5. リポジトリルートの`pull_request_template.md`

## テンプレが見つかった場合

- テンプレのセクション構成をそのまま使う
- 各セクションに差分とコミット履歴から得た内容を記入する
- テンプレ内のチェックリストは、実際に確認した項目だけチェックを入れる
- テンプレの言語（日本語・英語）に合わせて記述する。テンプレの言語が事前確認での判定と異なる場合はテンプレを優先する

## テンプレが見つからなかった場合

`references/title-and-body.md`のデフォルトテンプレを使う。
