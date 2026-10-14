---
name: rust
description: Rustのコードを書く、レビューする、リファクタリングするときの規約。安全性を回避する記法の扱い、エラー処理、型の設計、検証手順を定める。
---

# Rustの規約

リポジトリに規約やrustfmt、Clippyなどの設定がある場合は、そちらに従う。この規約にない事項は、一般的なベストプラクティスに従う。

## 安全性を回避する記法を使わない

次の記法や変更は使わない。どうしても必要な場合は、理由を示してユーザーに確認する。

- `unsafe`
- `Box::leak`、`std::mem::forget`
- unstable機能（`#![feature(...)]`）
- 警告を抑制する属性（`#[allow(...)]`、`#![allow(...)]`）
- Clippyのlintレベルの緩和
- テストコード以外での`unwrap()`、`panic!`、`todo!`、`unimplemented!`
- 借用エラーを避けるためだけの`clone()`、`Rc<RefCell<T>>`、`Arc<Mutex<T>>`

`unsafe`を使う場合は、ブロックの直前に`// SAFETY:`で安全性の根拠を書く。

## エラー処理

- 失敗しうる処理は`Result`で返し、`?`で伝播する。
- `expect()`は、失敗がプログラムのバグを意味する場合にだけ使い、メッセージに前提条件を書く。
- ライブラリのエラーは`thiserror`で型付きのenumとして定義する。アプリケーションでは`anyhow`を使い、`.context()`で状況を補う。
- `From`は、追加の情報なしで決まる単純な変換にだけ実装する。
- ログを出すためだけに`match`を書かず、`inspect_err`を使う。
- ネストした`if let`や`match`より、`let-else`による早期リターンを使う。

## 型の設計

- IDや単位など、意味の異なる値はnewtypeで区別する。
- 公開範囲は必要最小限にする。
- 数値の変換には`as`ではなく`From`や`TryFrom`を使う。

## 検証

作業の区切りで次を実行する。

- `cargo fmt --check`
- `cargo clippy --all-targets -- -D warnings`
- `cargo test`
