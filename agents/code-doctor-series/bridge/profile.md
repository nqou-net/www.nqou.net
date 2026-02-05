# Patient Profile
- Name: 拡張性中毒のアーキテクト気取り (29)
- Role: メッセージング基盤チームのリード
- Personality: 「将来の拡張性」を何よりも重視するが、あらゆる問題を継承関係で解決しようとする癖がある。「汎用的」「疎結合」という言葉を好むが、実際には密結合を作り出していることに気づいていない。
- Background: 以前のプロジェクトで仕様変更に苦しんだトラウマから、今回は最初からあらゆる通知手段と優先度に対応できる「最強の基盤」を作ろうと意気込んでいる。
- Main Complaint: 「クラスが増えすぎて、新しい通知手段を追加するのが苦痛です。IDEのクラス一覧が埋め尽くされてしまって...」
- First Person: 「私（ワタシ）」

# Medical Chart
- Symptom: `UrgentEmailNotifier`, `NormalEmailNotifier`, `UrgentSMSNotifier`, `NormalSMSNotifier`... のように、「機能（優先度）」と「実装（通知手段）」の組み合わせ数だけサブクラスが爆発的に増殖している（クラス爆発）。
- Metaphor: 「多次元増殖症候群」。神経系統（抽象化）と筋肉（実装）が癒着しており、新しい動き（実装）を覚えようとすると、神経系ごと作り変える必要がある状態。
- Cure: Bridge Patternによる「神経（Abstraction）」と「筋肉（Implementation）」の分離手術。
