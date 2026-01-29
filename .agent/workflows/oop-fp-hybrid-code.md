---
description: OOP-FPハイブリッド設計シリーズ Phase 2: コード実装・テスト
---

# Phase 2: コード実装・テスト

> 前: `/oop-fp-hybrid-prepare` | 次: `/oop-fp-hybrid-series-write` または `/oop-fp-hybrid-unified-write`

---

## 概要

原稿作成前に、全8回分のコード例を先に実装し、テストで動作確認する。
これにより、記事内のコード例が確実に動作することを保証する。

---

## Step 1: テストディレクトリ作成

```bash
mkdir -p agents/tests/oop-fp-hybrid-design/{lib,t}
```

---

## Step 2: コード例の実装

各回のコード例を実装（構造案の「コード例1」「コード例2」に対応）:

| 回 | ファイル | 内容 |
|----|---------|------|
| 1 | `lib/Order/Mutable.pm` | MutableなOrderクラス（バグあり） |
| 1 | `t/01_mutable_problem.t` | デバッグの困難さを示すテスト |
| 2 | `lib/Order/Immutable.pm` | イミュータブルなOrderクラス |
| 2 | `t/02_immutable.t` | `with_*` メソッドのテスト |
| 3 | `lib/Calculator/Impure.pm` | 副作用ありの計算メソッド |
| 3 | `lib/Calculator/Pure.pm` | 純粋関数に分離 |
| 3 | `t/03_pure_function.t` | 純粋関数のテスト |
| 4 | `lib/OrderProcessor.pm` | map/grep/reduce による処理 |
| 4 | `t/04_higher_order.t` | 高階関数のテスト |
| 5 | `lib/OrderCalculator.pm` | Functional Core |
| 5 | `lib/OrderService.pm` | Imperative Shell |
| 5 | `t/05_fcis.t` | FCIS パターンのテスト |
| 6 | `lib/Order/Typed.pm` | Types::Standard で型制約 |
| 6 | `t/06_type_constraint.t` | 型制約のテスト |
| 7 | `t/07_core_unit.t` | Coreの単体テスト |
| 7 | `t/07_shell_integration.t` | Shellの統合テスト |
| 8 | `lib/ECShop/*.pm` | 完成したシステム全体 |
| 8 | `t/08_complete_system.t` | 統合テスト |

---

## Step 3: コード規約

すべてのコードで守るべきルール:

- **`use v5.36;`** を必ず明示
- `Test::More` を使う場合は明示的に `use Test::More;` する（`v5.36`には含まれない）
- `List::Util` 関数（`sum0`, `reduce` 等）は明示的にインポートする
- **Moo** でクラス定義
- **Types::Standard** で型制約
- **List::Util** の `reduce`, `any`, `all` などを活用
- 警告なし（`use warnings;` は v5.36 で自動有効）

---

## Step 4: テスト実行

// turbo
```bash
cd agents/tests/oop-fp-hybrid-design && prove -l t/
```

すべてのテストが PASS し、警告がないことを確認。

---

## 完了後

- 連載版 → `/oop-fp-hybrid-series-write` へ進む
- 統合版 → `/oop-fp-hybrid-unified-write` へ進む