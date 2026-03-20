# 構造案: コード探偵ロックの事件簿【Abstract Factory】（リライト）

## メタデータ
- シリーズ: code-detective
- パターン: Abstract Factory
- アンチパターン: Mismatched Product Family（製品ファミリー不一致）
- slug: abstract-factory-pattern
- 公開日時: 2026-03-26T07:07:05+09:00
- タイトル: コード探偵ロックの事件簿【Abstract Factory】混沌の箱庭〜血統を守らぬ創造主〜

## 語り部プロファイル
- **名前**: 神崎（Kanzaki）
- **年齢**: 26歳、男性
- **一人称**: 僕
- **職種**: ゲーム会社「Arclight Studios」サーバーサイドエンジニア（経験4年）
- **性格**: 真面目だがやや楽観的。自分のコードに問題があるとは思っていなかったが、遷移ゾーンのバグで目が覚める
- **背景**: Elysium Online のプロシージャル世界生成担当。3バイオーム（森・砂漠・海）を管理。遷移ゾーン実装でファミリー不一致バグが発覚、火山バイオーム追加の要件で限界を感じLCIを訪問

## プロット（5幕構成）
- I. 依頼: 砂漠にクラーケン問題→LCI訪問
- II. 現場検証: WorldGenerator のif/elsif分岐、遷移ゾーンのバグ
- III. 推理披露: BiomeFactory ロール、具象Factory、WorldGenerator のリファクタリング、VolcanoFactory 追加
- IV. 解決: テスト結果（Before/After）
- V. 報告書: 調査報告書テーブル、推理のステップ、ロックより
