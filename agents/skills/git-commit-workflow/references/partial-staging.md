# 部分的なstaging

1つのファイルに複数ユニットの変更が混ざっている場合、patchファイルを編集して`git apply --cached`でstagingする。

## 手順

1. 対象ファイルの差分をpatchファイルに出力する

   ```sh
   git diff --output=<patchファイル> -- <path>
   ```

   patchファイルはリポジトリ外の一時ディレクトリに置く。シェルのリダイレクト（`>`）は使わない。PowerShell 5.1の`>`はUTF-16LEで書き出すため、patchが壊れる。

2. patchファイルを編集して、stagingしたい部分だけ残す

3. 編集したpatchをstagingする

   ```sh
   git apply --cached --recount <patchファイル>
   ```

   `--recount`を付けると、hunkの途中の行を削ったときも`@@`行の行数を直さずに適用できる。

## patchファイルの編集

```diff
diff --git a/src/auth.ts b/src/auth.ts
index abc123..def456 100644
--- a/src/auth.ts
+++ b/src/auth.ts
@@ -10,6 +10,8 @@ function login() {
   const user = getUser(id);
+  const resetToken = generateToken();
+  sendResetMail(user, resetToken);
   return user;
 }
@@ -20,6 +22,7 @@ function logout() {
   clearSession();
+  clearCache();
   redirect('/');
 }
```

- hunk（`@@`で始まるブロック）単位で不要なものを削除する。
- hunkの途中の変更を外す場合、`+`行は削除し、`-`行は先頭の`-`を半角スペースに置き換えてコンテキスト行にする。
- コンテキスト行（先頭が半角スペース）は変更しない。

## 新規ファイルの一部だけstagingする

未追跡のファイルは`git diff`に出ない。先に`git add -N <path>`で追跡対象にしてから、上の手順を使う。

## エラーが出た場合

- `error: patch failed`：patchのコンテキスト行が現在のファイルと一致していない。patchを作り直す。
- `error: corrupt patch`：編集でpatchの構造が壊れている。`--recount`を付け忘れていないか確認し、直らなければpatchを作り直す。
- `error: ... does not match index`：既にstaging済みの変更と競合している。`git diff --cached`で確認し、必要なら`git restore --staged <path>`で外す。
