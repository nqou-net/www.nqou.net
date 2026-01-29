---
description: OOP-FPハイブリッド設計シリーズ（連載版・全8回）のワークフロー
---

# OOP-FP ハイブリッド設計シリーズ（連載版）

> 親: `/oop-fp-hybrid` | 参照: [構造案](../../agents/structure/oop-fp-hybrid-design-series-structure.md)

---

## 概要

連載構造案を元に、全8回のシリーズ記事 + 目次記事を作成する。

**出力**:
- 記事（8回）: `content/post/%Y/%m/%d/%H%M%S.md`
- 目次記事: 最終回の17秒後
- テストコード: `agents/tests/oop-fp-hybrid-design/`
- 画像: `static/public_images/%Y/oop-fp-hybrid-*.png`

---

## フェーズ構成

| Phase | コマンド | 内容 |
|-------|---------|------|
| 1 | `/oop-fp-hybrid-prepare` | 準備・公開日時決定 |
| 2 | `/oop-fp-hybrid-code` | コード実装・テスト |
| 3 | `/oop-fp-hybrid-series-write` | 連載原稿作成（8回） |
| 4 | `/oop-fp-hybrid-series-nav` | ナビゲーション・目次 |
| 5 | `/oop-fp-hybrid-visual` | Mermaid図・挿絵 |
| 6 | `/oop-fp-hybrid-review` | レビュー・最終確認 |

---

## 使い方

```
/oop-fp-hybrid-series
```

全フェーズを順次実行します。個別フェーズを実行する場合は、上記のコマンドを直接呼び出してください。
