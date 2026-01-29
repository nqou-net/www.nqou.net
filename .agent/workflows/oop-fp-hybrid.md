---
description: OOP-FPハイブリッド設計シリーズの記事作成（連載版/統合版を選択）
---

# OOP-FP ハイブリッド設計シリーズ

> 参照: [構造案](../../agents/structure/oop-fp-hybrid-design-series-structure.md)

---

## 概要

連載構造案「OOPとFPの融合：ハイブリッド設計のすすめ」を元に記事を作成するワークフロー。

**入力**: `agents/structure/oop-fp-hybrid-design-series-structure.md`
**推薦案**: 案A「痛みから始まる改善」（v2.0）

---

## 出力形式の選択

ユーザーに以下の選択肢を提示:

1. **連載版**（全8回シリーズ + 目次）→ `/oop-fp-hybrid-series`
2. **統合版**（1記事に統合）→ `/oop-fp-hybrid-unified`

---

## 使い方

```
/oop-fp-hybrid
```

選択後、対応するワークフローが全フェーズを順次実行します。

---

## フェーズ構成

| Phase | ワークフロー | 内容 | 共通/固有 |
|-------|------------|------|----------|
| 1 | `/oop-fp-hybrid-prepare` | 準備・公開日時決定 | 共通 |
| 2 | `/oop-fp-hybrid-code` | コード実装・テスト | 共通 |
| 3a | `/oop-fp-hybrid-series-write` | 連載原稿作成（8回） | 連載版 |
| 3b | `/oop-fp-hybrid-unified-write` | 統合原稿作成（1記事） | 統合版 |
| 4a | `/oop-fp-hybrid-series-nav` | ナビゲーション・目次 | 連載版 |
| 5 | `/oop-fp-hybrid-visual` | Mermaid図・挿絵 | 共通 |
| 6 | `/oop-fp-hybrid-review` | レビュー・最終確認 | 共通 |
