---
name: typescript-guidelines
description: TypeScriptのコードを書く、レビューする、リファクタリングするときの型の規約。型注釈の付け方と、型アサーション・any・unknownの扱いを定める。
---

# TypeScriptの型の規約

リポジトリに規約やtsconfig、ESLintなどの設定がある場合は、そちらに従う。この規約にない事項は、一般的なベストプラクティスに従う。テストコードにも同じ規約を適用する。

## 型注釈

- ローカル変数など、推論で十分な箇所には型注釈を付けない。
- exportする関数は、引数と戻り値の型を明示する。
- exportする変数は、推論される型が意図より広い、または読み取りにくい場合に型注釈を付ける。

## 型安全性を回避する記法を使わない

次の記法や変更は使わない。どうしても必要な場合は、理由を示してユーザーに確認する。

- 型アサーション（`as`、`<T>value`）。ただし`as const`は使ってよい。
- 非nullアサーション（`!`）
- `any`
- 型エラーを抑制するコメント（`@ts-ignore`、`@ts-expect-error`、`@ts-nocheck`、`eslint-disable`、`biome-ignore`）
- tsconfigの`strict`系オプションやLintルールの無効化・緩和
- 型エラーを避けるために、型を`object`、`{}`、`Function`などの曖昧な型に広げること

代わりに次の手段で型を絞り込む。

- `typeof`、`instanceof`、`in`、判別共用体によるnarrowing
- 型ガード関数（`value is T`）
- 型を検査しつつ推論を保つ`satisfies`
- ジェネリクス

テストデータはファクトリ関数で作り、モックはテストフレームワークの型付きヘルパーで作る。

## unknown

- `unknown`は、実行時まで型が決まらない値（外部入力、`JSON.parse`の結果、`catch`で受けた値）にだけ使う。
- `unknown`で受けた値は、narrowingやスキーマ検証で具体的な型にしてから使う。
