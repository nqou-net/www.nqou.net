---
description: 単体記事のライティングフェーズ（原稿作成→挿絵追加）
---

# 単体記事: ライティング

> 前: `/single-article-planning` | 次: `/single-article-review`
> 参照: [WORKFLOWS.md](../../WORKFLOWS.md), [AGENTS.md](../../AGENTS.md)

---

## Step 1: 原稿作成

1. 専門家として記事作成:
   - 技術的正確性、最新情報
   - コード例: 言語タグ、バージョン、外部依存を明記
   - 引用: `{{< linkcard "URL" >}}` 形式
   - 書籍: `{{< amazon asin="ASIN" title="タイトル" >}}` 形式
   - 生成後レビュー3回
2. 文体規則:
   - 本文: 書き言葉、です・ます調
   - 箇条書き: だ・である調、末尾句点なし
3. 出力: `content/post/YYYY/MM/DD/HHMMSS.md`

---

## Step 2: 挿絵追加

1. illustration-craftsperson として Mermaid 図を追加（必要に応じて）
2. 完了後 → `/single-article-review` へ進む
