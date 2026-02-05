# Phase 3 Context: Code Implementation

> **Source of Truth**: 独立（技術制約中心）
> **Last Synced**: 2026-02-06
> **Related**: Perl version constraints, directory structure

> **Scope**: Before/Afterコード実装に必要な技術情報のみ
> **Note**: キャラクター設定、物語構成はこのフェーズでは不要

## 1. 技術的制約

### Perl バージョン
```perl
use v5.36;  # または use feature qw(signatures postderef);
```

### 必須プラグマ
- `use strict;` / `use warnings;` 相当（v5.36で自動有効）
- シグネチャ構文: `sub foo($bar, $baz) { ... }`
- 後置デリファレンス: `$hashref->%*`, `$arrayref->@*`

## 2. Before Code（患部）設計

### 目的
患者のスキルレベルに合わせた「リアルなダメコード」

### ガイドライン
- わざとらしくしすぎない
- 初心者がやりがちなミスを模倣
- 仕様変更で崩れた設計を再現

### 推奨要素
```perl
# TODO: なぜか動いてるので触らない
# FIXME: 時間がなくて後で直す（嘘）
```

## 3. After Code（処方）設計

### 目的
デザインパターンを適用した理想的なコード

### ガイドライン
- 無駄のない簡潔さ
- 明確な命名規則
- パターンの本質が見える構造

## 4. ディレクトリ構成

```
agents/code-doctor-series/<slug>/tests/
├── before/
│   ├── lib/
│   │   └── [Module].pm
│   └── t/
│       └── [test].t
└── after/
    ├── lib/
    │   └── [Module].pm
    └── t/
        └── [test].t
```

## 5. テスト要件

- 全テストがPASSすること
- Before: アンチパターンでも動作する（問題が顕在化するテストケースを含む）
- After: パターン適用後のメリットが見えるテストケース
