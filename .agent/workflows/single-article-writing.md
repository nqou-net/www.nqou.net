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
   - 強調表現（**太字**）は使用しない
3. 出力: `content/post/YYYY/MM/DD/HHMMSS.md`

---

## Step 2: 挿絵追加

**各記事に最低1つの挿絵が必要**

1. アイキャッチ画像を生成:
   - 記事のテーマを視覚化した画像
   - 保存先: `static/public_images/%Y/<article-slug>.png`
   - frontmatterに `image:` で指定

2. 本文挿絵を生成（任意）:
   - 記事の主要トピックを視覚化した画像
   - 挿入位置: 導入部の直後

3. Mermaid図の追加（任意）:
   - 推奨: クラス図/シーケンス図/フローチャート/構成図
   - アスキーアート（罫線文字などで描いた図）は使用せず、Mermaid記法に変換する

4. 完了後 → `/single-article-review` へ進む
