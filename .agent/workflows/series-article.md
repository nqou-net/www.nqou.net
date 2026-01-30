---
description: シリーズ記事の作成ワークフロー（プランニング→ライティング→レビュー）
---

# シリーズ記事作成ワークフロー

> 参照: [WORKFLOWS.md](../../WORKFLOWS.md), [AGENTS.md](../../AGENTS.md), [PLANNING_STATUS.md](../../PLANNING_STATUS.md)

---

## フェーズ構成

| Phase | コマンド | 内容 |
|---|---|---|
| 1 | `/series-article-planning` | 調査→構造案→レビュー→選定 |
| 2 | `/series-article-writing` | 原稿作成→挿絵追加 |
| 3 | `/series-article-review` | 校正→品質レビュー→公開 |

---

## 使い方

1. `/series-article-planning` でプランニングを開始
2. 構造案が承認されたら `/series-article-writing` で原稿作成
3. 原稿完成後 `/series-article-review` でレビュー・公開

または、このワークフロー `/series-article` を呼び出すと全フェーズを順次実行します。
