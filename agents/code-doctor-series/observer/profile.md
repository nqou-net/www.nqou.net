# Patient Profile
- **Name**: 健気な新卒エンジニア (23)
- **Role**: Webメディア企業のバックエンド担当
- **Personality**: 真面目で責任感が強い。「言われたことは全部やる」が信条だが、構造を考える余裕がない。先輩に質問するのを遠慮しがち。
- **First Person**: 「僕」
- **Background**: 自社CMSの開発を担当。「記事公開時にSlackに通知したい」という要望に応えた後、「やっぱりDiscordも」「メールも」「LINEも」と次々に要望が追加され、そのたびに`publish_article`メソッドに直接通知ロジックを書き足していった。
- **Main Complaint**: 「機能追加のたびにメインの処理を書き換えるのが怖いです。テストも全部やり直しになるし……」

# Medical Chart
- **Symptom (Subjective)**: 
  - 「新しい通知先を追加するたびに、巨大な`if`文の塊をコピペしています」
  - 「通知の処理に失敗すると、記事の公開自体が止まってしまうことがあります」
- **Symptom (Objective/Technical)**:
  - **密結合 (Tight Coupling)**: `Article`クラスが`SlackNotifier`, `EmailNotifier`などの具象クラスに直接依存している。
  - **単一責任の原則 (SRP) 違反**: 記事の公開ロジックと通知ロジックが混在。
  - **開放閉鎖の原則 (OCP) 違反**: 通知先の追加に対して閉じていない（既存コードの修正が必要）。
- **Metaphor**:
  - **Diagnosis/Condition**: 「急性癒着性神経痛 (Acute Adhesive Neuralgia)」
  - **Explanation**: 本来独立して動くべき「脳からの指令（イベント）」と「手足の動作（通知）」が、神経レベルで癒着している。そのせいで、指先（通知先）を一つ増やすだけで、全身（メインロジック）を切開しなければならない状態。
- **Prescription**: 
  - **Observer Pattern**: 「神経伝達物質（Event）」による分離手術。
  - **Procedure**: `Subject`（脳）は「何かが起きた」と発信するだけにし、受取手である`Observer`（手足）がそれに反応するように神経回路を繋ぎ変える。
