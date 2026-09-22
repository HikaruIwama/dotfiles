# Staging

エージェントが使える非対話的なstaging方法。

## 基本ルール

### 許可される操作

- `git add <path>`：ファイル単位でstaging
- `git apply --cached`：patchファイルを使って部分的にstaging

### 禁止される操作

- `git add -A`、`git add .`、`git add -u`：無関係な変更を巻き込む
- `git add -p`、`git add -i`：対話的な操作（エージェントは使えない）
- `git commit -a`、`git commit -am`：indexを経由しない

## ファイル単位のstaging

変更が1ファイルに閉じている場合：

```sh
git add path/to/file.ts
```

複数ファイルをまとめてstaging：

```sh
git add src/auth/login.ts src/auth/logout.ts
```

## 部分的なstaging

1つのファイルに複数の変更が混ざっている場合、`git apply --cached`を使う。

### 手順

1. 現在の差分をpatchファイルに出力

   ```sh
   git diff > /tmp/changes.patch
   ```

2. patchファイルを編集して、stagingしたい部分だけ残す

3. 編集したpatchをstaging

   ```sh
   git apply --cached /tmp/changes.patch
   ```

### patchファイルの編集

patchファイルは以下の構造：

```diff
diff --git a/src/auth.ts b/src/auth.ts
index abc123..def456 100644
--- a/src/auth.ts
+++ b/src/auth.ts
@@ -10,6 +10,8 @@ function login() {
   const user = getUser(id);
+  // パスワードリセット機能を追加
+  const resetToken = generateToken();
   return user;
 }
@@ -20,6 +22,7 @@ function logout() {
   clearSession();
+  // typo修正
   redirect('/');
 }
```

不要なhunk（`@@`で始まるブロック）を削除して保存する。

### トラブルシューティング

エラーが出た場合：

- `error: patch failed`：patchのコンテキスト行が現在のファイルと一致していない。patchを作り直す。
- `error: does not match index`：既にstaging済みの変更と競合している。`git diff --cached`で確認し、必要なら`git restore --staged`で外す。

## 既にstaging済みの変更を扱う

ビルドプロセスなどで既にstaging済みの変更がある場合、それを信用しない。

### 確認

```sh
git diff --cached --stat
```

### 不要な変更を外す

```sh
git restore --staged path/to/file.ts
```

すべて外す場合：

```sh
git restore --staged .
```

## staging後の確認

stagingが意図した範囲か確認：

```sh
git diff --cached --stat
git diff --cached
```

問題なければコミットに進む。
