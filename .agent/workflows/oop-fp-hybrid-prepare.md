---
description: OOP-FPハイブリッド設計シリーズ Phase 1: 準備・公開日時決定
---

# Phase 1: 準備

> 次: `/oop-fp-hybrid-code`

---

## Step 1: 構造案の確認

1. 構造案ファイルを読み込み: `agents/structure/oop-fp-hybrid-design-series-structure.md`
2. 推薦案「案A: 痛みから始まる改善」（v2.0）を使用することを確認
3. 連載構造表を確認:
   - 全8回の構成
   - 各回のタイトル、新概念、ストーリー、コード例

---

## Step 2: 公開日時の決定

**連載版の場合**:
1. ユーザーに第1回の公開日時を確認（推奨: 毎週月曜 09:00）
2. 公開スケジュールを生成:
   - 第1回: ユーザー指定日時
   - 第2〜8回: 前回の1週間後（同時刻）
   - 目次: 第8回の17秒後

**統合版の場合**:
1. ユーザーに公開日時を確認
2. ファイル名形式: `content/post/%Y/%m/%d/%H%M%S.md`

---

## Step 3: 技術スタック確認

以下の技術スタックを使用:
- Perl v5.36以降（`use v5.36;` 必須）
- Moo（オブジェクト指向）
- Types::Standard（型制約）
- List::Util（高階関数）

Perl v5.36+ の機能を積極的に活用:
- `builtin::true`, `builtin::false`
- `try/catch` 構文
- `isa` 演算子

---

## 完了後

→ `/oop-fp-hybrid-code` へ進む
