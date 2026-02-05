# Plot Outline

## Scene 1: The Emergency (Admission)
- **Situation**: 深夜の会議室。ホワイトボード一面に描かれた巨大なクラス図（継承の蜘蛛の巣）の前で、患者（拡張性中毒のアーキテクト気取り）が頭を抱えている。「完璧なはずだ…なぜSlack通知を追加するだけで10個もクラスを作らなきゃいけないんだ？」
- **Doctor's Entry**: ドクターが音もなく入室し、ホワイトボードの端（サブクラスの末端）を指で擦り消し始める。「無駄な枝葉だ」
- **Interaction**:
  - 患者：「やめてください！ それは『汎用メッセージング基盤 ver.3.0』の要なんです！」
  - ドクター：「基盤？ いや、これは『迷宮』だ。出口のないな」
  - 助手：「神経と筋肉が癒着してしまっていますね。これでは指一本動かすのにも、全身の骨格を作り変えなければなりません」

## Scene 2: The Examination
- **Action**: ドクターがコード（Perlモジュール）を開く。`lib/MyApp/Notifier/Urgent/Email.pm`, `lib/MyApp/Notifier/Normal/Email.pm`... と続くファイルツリーをスクロールし続ける。
- **Dialogue**:
  - ドクター：「Slack対応はどうするつもりだ？」
  - 患者：「ええ、ですから `MyApp::Notifier::Urgent::Slack`, `MyApp::Notifier::Normal::Slack`... を作って...」
  - ドクター：「もし『優先度』に『最優先（Critical）』を追加したら？」
  - 患者：「それは... 全ての媒体（Email, SMS, Slack, Line...）に対して `Critical` クラスを作れば... うっ」
- **Metaphor**: 助手「掛け算が、足し算ではなく『組み合わせ爆発』を起こしています。多次元増殖症候群の末期ですね」

## Scene 3: The Surgery (Bridge Pattern)
- **Procedure**:
  - 1. **切断**: 「機能（優先度）」と「実装（通知手段）」の継承関係を断ち切る。
  - 2. **接続**: `Notifier` クラスに `Implementation`（ここでは `Sender` インターフェース）への参照を持たせる（委譲）。
  - 3. **再構築**:
    - `Notifier` (Abstraction): `Urgent`, `Normal`
    - `Sender` (Implementation): `Email`, `SMS`, `Slack`
- **Highlight**:
  - 患者：「継承が... なくなった？ 私の美しい階層構造が！」
  - ドクター：「階層ではない。『橋』を架けたのだ」
  - コードの変化：`$urgent_email = UrgentNotifier->new(sender => EmailSender->new)` という構成（コンコンポジション）に。
  - 患者のカタルシス：「機能と実装が... 独立して動く...！ Slackを追加しても、修正は `SlackSender` を作るだけ...！？」

## Scene 4: The Prognosis (Comedy)
- **Event**: 治療後、ドクターが患者に「積み木セット（橋を作るキット）」を手渡す。
- **Patient's Misunderstanding**:
  - 患者（涙ぐみながら）：「分かりました... この橋のように、人と人との架け橋になれというメッセージですね！ アーキテクチャとは技術ではなく、心なんだと...！」
  - 患者は「心の架け橋エンジニア」を目指すと宣言して去っていく。
- **Closing**:
  - 助手：「...リハビリ用の玩具ですが、随分と壮大な解釈をされましたね」
  - ドクター：「あながち間違いではない。システムも人間関係も、結合（Coupling）より疎通（Communication）が大事だからな」
  - 助手（無言でドクターのネクタイの歪みを直す）
