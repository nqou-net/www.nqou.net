# 出力形式: 処方箋まとめ（退院時のメモ）

## 概要
記事の最後（`術後経過`の後）に水平線（`---`）を挟んで「処方箋まとめ」を含めること。
これは「**助手から患者へ手渡された退院時のメモ**」という設定であり、次回予告は含めない。

## Format
1.  **Separator**: `---` (Must be inserted before the heading)
2.  **Heading**: `## 処方箋まとめ`
3.  **Table**: 適用基準（Symptoms vs Application）
    *   Columns: `| 症状 | 適用すべき | 経過観察 |`
    *   Checkmarks: Apply `✓` to the correct column.
4.  **List**: 治療のステップ
    *   Heading: `### 治療のステップ`
    *   読者が自身で適用するためのステップバイステップの解説。
5.  **Message**: 助手からのメッセージ
    *   Heading: `### 助手より`
    *   Content: 技術的な励ましや、ドクターの厳しさへのフォロー、あるいは患者の今後の活躍を祈る**温かい一言**。ですます調。
