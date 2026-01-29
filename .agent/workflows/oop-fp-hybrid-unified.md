---
description: OOP-FPハイブリッド設計シリーズ（統合版・1記事）のワークフロー
---

# OOP-FP ハイブリッド設計シリーズ（統合版）

> 親: `/oop-fp-hybrid` | 参照: [構造案](../../agents/structure/oop-fp-hybrid-design-series-structure.md)

---

## 概要

連載構造案の全8回を、8章構成の1記事に統合して作成する。

**出力**:
- 記事（1本）: `content/post/%Y/%m/%d/%H%M%S.md`
- テストコード: `agents/tests/oop-fp-hybrid-design/`
- 画像: `static/public_images/%Y/oop-fp-hybrid-*.png`

---

## フェーズ構成

| Phase | コマンド | 内容 |
|-------|---------|------|
| 1 | `/oop-fp-hybrid-prepare` | 準備・公開日時決定 |
| 2 | `/oop-fp-hybrid-code` | コード実装・テスト |
| 3 | `/oop-fp-hybrid-unified-write` | 統合原稿作成（目次なし・8章1記事） |
| 5 | `/oop-fp-hybrid-visual` | Mermaid図・挿絵 |
| 6 | `/oop-fp-hybrid-review` | レビュー・最終確認 |

---

## 使い方

```
/oop-fp-hybrid-unified
```

全フェーズを順次実行します。個別フェーズを実行する場合は、上記のコマンドを直接呼び出してください。