---
description: 単体記事のプランニングフェーズ（調査→アウトライン作成）
---

# 単体記事: プランニング

> 参照: [WORKFLOWS.md](../../WORKFLOWS.md), [AGENTS.md](../../AGENTS.md)
> 次: `/single-article-writing`

---

## Step 1: 調査・情報収集
// turbo
1. `content/warehouse/` 配下に調査ファイルが既存か確認
2. 存在しない場合、investigative-research エージェントとして以下を実行:
   - 最新かつ信頼性の高い情報を収集
   - 各項目に**要点**、**根拠**、**仮定**、**出典**（URL/ASIN/ISBN）、**信頼度**（1-10）を付記
   - 競合記事分析
   - 内部リンク調査（`content/post` 配下を grep）
3. 出力: `content/warehouse/<slug>.md`

---

## Step 2: アウトライン作成

1. search-engine-optimization エージェントとしてアウトライン案3つ（A/B/C）作成:
   - 異なる視点・アプローチ
   - 生成後レビュー3回
2. 各案の必須項目:
   - 要約（1行）
   - H2/H3見出し階層
   - 推奨タグ（5個まで、英小文字ハイフン）
   - meta description
   - 構造化データ提案
3. ユーザーに提示し、案を選定
4. 完了後 → `/single-article-writing` へ進む
