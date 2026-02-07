# Patient Profile
- Name: 苦悩するインフラリーダー (35)
- Role: 大規模Webサービス基盤チームリーダー
- Personality: 真面目で責任感が強い。システムの整合性を何よりも重んじるが、現状のカオスに心を痛めている。少し疲れ気味。
- Background: サービス拡大に伴い、設定ファイルの読み込みが各所でバラバラに行われるようになり、バッチとアプリで挙動が違うなどの障害に直面している。
- First Person: 「私」

# Medical Chart
- Symptom: `Config`クラスが至る所で`new`され、その都度設定ファイルを読み込んでいる。コンポーネントごとに異なる設定値（記憶）を持ってしまっている。
- Diagnosis: 多重人格症候群（解離性同一性障害）
- Metaphor: 「指揮官が複数いて、現場に矛盾した命令を出している状態」「システムの記憶が乖離している」
- Cure: Singleton Pattern (state変数) による人格の統合。Single Source of Truthの確立。
