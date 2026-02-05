# Patient Profile
- Name: 効率重視のシニアエンジニア (29)
- Role: 自社ECサイトの検索エンジン開発リード
- Personality: 「動けば正義」がモットー。コードの短さと実装スピードを何より重視するが、実は保守性の低さに密かに悩んでいる。強気だが、ドクターの眼光には弱い。
- First Person: 「俺」
- Background: サービスの成長に伴い、商品検索のフィルタリング条件が爆発的に増加。当初はシンプルな文字列結合で作っていたSQL構築ロジックが、今や誰も触れない「聖域」となってしまった。
- Main Complaint: 「条件分岐が複雑すぎて、条件を一つ足すだけでデグレる。もうSQLを直接いじりたくない」

# Medical Chart
- Symptom: 巨大なサブルーチン内で、多数のフラグ引数に基づいてSQLの断片（WHERE句、JOIN句）を文字列結合している。引数の順番制御も呼び出し元に依存している。
- Metaphor: 「増築を繰り返した迷宮建築（違法建築の継ぎ接ぎ）」
- Diagnosis: 「複雑性結合ヘルニア（Construction Hernia）」
- Prescription: Builder Patternによる「建築工程の規格化（プレハブ工法）」と「安全な構築」。
