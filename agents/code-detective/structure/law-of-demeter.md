# 構造案: コード探偵ロックの事件簿【Law of Demeter】

## メタ情報

| 項目 | 内容 |
|------|------|
| タイトル | コード探偵ロックの事件簿【Law of Demeter】列車事故の共犯者たち〜メソッドの連鎖が暴く内部構造の地図〜 |
| コードスメル | Law of Demeter 違反（Train Wreck / Message Chains） |
| 解決策 | Moo の `handles`（委譲） + Facade 的インターフェース |
| slug | law-of-demeter |
| 公開日時 | 2026-04-07T07:07:05+09:00 |
| ファイルパス | content/post/2026/04/07/070705.md |
| アーク | コードの悪臭捜査編（2/7） |
| 関連回 | Feature Envy（1/7）— 他クラスへの過度な関心という共通テーマ |

---

## 語り部プロファイル（依頼人）

| 項目 | 内容 |
|------|------|
| 名前 | 森川 ユウジ（もりかわ ゆうじ） |
| 年齢 | 30歳 |
| 職種 | ECシステムのインフラ兼バックエンド（3年目、夜間障害対応あり） |
| 一人称 | 僕 |
| 性格 | 実務優先で短気。エレガントさより「今動くこと」を求める。ただし根底に「ちゃんと直したい」は持っている |
| 背景 | 深夜の障害対応中。顧客住所テーブルのリファクタリング後、配送料計算が軒並み壊れた。`$order->customer->address->prefecture` のような連鎖が至る所にあり、影響範囲が見えない |
| 話し方 | ぶっきらぼうだが丁寧語。焦りが口調のテンポに出る。回りくどい説明には「つまりどういうことですか」と遮る |
| 事前知識 | LCI を知らない。同じビルの別フロアにいることも知らなかった |
| 呼称 | 地の文ではロックを「この男」→「ロックさん」に移行（信用した時点で切り替え） |

---

## 変化点（今回の差分）

### 1. 語り部の声の差分
- 直近3本: 椎名（懐疑観察型）、田中（真面目疲弊型）、高橋（反論型）
- **今回**: 切迫実務型。障害対応中で「今夜中に直す」がゴール。奇行に付き合う余裕がない。感情表現は愚痴っぽく、状況説明は短い

### 2. 導入の差分
- 直近3本: 勉強会の控え室、Slack DM→事務所、ファミレスで偶然
- **今回**: 深夜のオフィスで障害対応中、同じビルの別フロア（LCI）に灯りがついているのを見つけて「SEのフロアだ」と勘違いして飛び込む。事務所の扉を語り部が自分から開ける（受動ではなく能動）

### 3. 対話の差分
- 直近3本: 観察型、戸惑い型、反論型
- **今回**: 切迫型→半信半疑→実感。テンポが速く「つまり何をすればいいんですか」と急かす。ロックの比喩を遮って実装の話に引き戻す場面がある

### 4. 終わり方の差分
- 直近3本: 静かな余韻（Feature Envy）、帳簿の整合（Unit of Work）、テスト安定（CQRS）
- **今回**: 障害対応が解決した達成感＋「これ、前回のやつ（Feature Envy 回を暗示）とどう違うんですか」という語り部の質問にロックが皮肉で返す。報酬は「夜食のピザ1切れ」

### 5. 関係性の差分
- 直近3本: 勉強会の講師↔参加者、Slack→事務所、偶然の隣席
- **今回**: 語り部がロックの事務所に「助けを求めて」飛び込む（緊急性が関係の起点）。ロックは序盤からワトソン君と呼ぶが、語り部は「今それどこじゃないです」と流す

### 6. 質問の差分
- **Train Wreck の判定基準**: 「メソッドチェーンが何段までならOKなんですか」（ドットカウントの誤解を突く入口）
- **handles と直アクセスの違い**: 「handles で1層挟むだけなら、内部構造が変わったら同じじゃないですか」（Middle Man 懸念）
- **Feature Envy との違い**: 「前に聞いた Feature Envy と何が違うんですか」（前回との接続。ロック: 「Feature Envyはデータの覗き見、こっちは構造の踏み越え」）

---

## プロット（5幕構成）

### I. 導入：深夜の灯り

**状況**: 深夜1時、ECサイトの配送料計算が全滅。語り部（森川）は自社オフィスで障害対応中。住所テーブルのカラムをリファクタリングしたら、配送料計算・税計算・請求書生成が軒並み壊れた。どこが壊れているか特定できない。
**展開**: ビルの他のフロアに灯りがついているのを見つけ、「IT系のフロアだ、誰かに相談できるかも」と飛び込む。ドアには「レガシー・コード・インベスティゲーション」の看板。中にはロックがいて、壁に貼ったクラス図にピンを刺している（探偵の捜査ボード風）。
**ロックの奇行**: 壁一面に印刷したクラス図を貼り、赤い糸でクラス間の依存関係を結んでいる（刑事ドラマの捜査ボードのパロディ）。
**ワトソン君呼び**: ロックはすぐ呼ぶ。森川は「森川です。今それどころじゃないんです」と流す。

### II. 現場検証：列車事故の現場

**展開**: 森川がノートPCのコードを見せる。`$order->customer->address->prefecture` のような4段連鎖が配送料計算メソッドの中に散在。
**ロックの指摘**: 「この連鎖は列車だ。客車が4両つながっている。先頭車両（`$order`）から最後尾（`prefecture`）まで、すべての車両を知らなければ到達できない。途中の車両を入れ替えたら——列車事故だ」
**Beforeコード提示**: `ShippingCalculator` が `$order->customer->address->prefecture` を使って配送料を計算するコード。
**Mermaid図**: 4段連鎖の依存関係を図示。

### III. 推理披露：handles による遮断

**展開**: ロックが3段階でリファクタリングを実演。
1. **Address に prefecture ベースのロジックを移動**: 配送ゾーン判定を Address の責務にする
2. **Customer に handles で Address の必要メソッドを委譲**: Customer が Address の存在を隠す
3. **Order に handles で Customer の必要メソッドを委譲**: Order が Customer の存在を隠す
4. **ShippingCalculator は Order の1段だけを見る**: 連鎖が解消

**語り部の質問（Middle Man 懸念）**: 「handles で1層挟むだけなら、中間の構造が変わったら同じじゃないですか」
**ロックの回答**: 「委譲は地図を持つことではない。地図を持たなくて済むようにすることだ。`ShippingCalculator` は `$order->shipping_zone` と話すだけでいい。`shipping_zone` の裏に `Address` がいるのか `GeoAPI` がいるのかは、`Order` が知っていればいい」

**語り部の質問（Feature Envy との違い）**: 「前に聞いた Feature Envy と何が違うんですか」（前回のアーク1回目を暗示）
**ロックの回答**: 「Feature Envy はデータの覗き見だ。他人のポケットに手を突っ込んでいた。こちらは構造の踏み越え——他人の家の廊下を通って、さらにその奥の部屋のドアを開けている。問題の根は『知りすぎている』だが、知っているものが違う。Feature Envyはデータを知りすぎ、Train Wreckは経路を知りすぎている」

### IV. 解決：テストの独立

**展開**: リファクタリング後のテストを実行。各クラスが自分の責務だけでテストできることを確認。
- `Address` のテスト: `shipping_zone` が prefecture だけで決まる
- `Customer` のテスト: `handles` 経由で `shipping_zone` が呼べる
- `Order` のテスト: `handles` 経由で `shipping_zone` が呼べる
- `ShippingCalculator` のテスト: `$order->shipping_zone` だけで配送料が計算できる

障害の根本原因が判明: `address` テーブルのカラム名変更で `prefecture` → `region` になったが、4段連鎖の途中で壊れたため、`ShippingCalculator` 側では原因が見えなかった。委譲にしていれば、壊れる場所は `Address` の `handles` 宣言の1箇所だけだった。

### V. 報告書：探偵の調査報告書

**待て**: フォーマットコンポーネント（footer-detective-report.md）に従う。
**報酬ギャグ**: 深夜なので「夜食のピザ1切れ」。杯数ネタではない。
**ロックの締め**: 「見知らぬ者に道を尋ねるな。友人に聞けば済む」（LoD の格言を探偵風にアレンジ。標語型ではなく助言のトーン）

---

## コード設計

### Beforeコード（Train Wreck / LoD 違反）

`ShippingCalculator` が4段のメソッドチェーンで顧客住所にアクセスし、配送料を計算。

```perl
package ShippingCalculator;
use Moo;

has order => (is => 'ro', required => 1);

sub calculate ($self) {
    my $pref = $self->order->customer->address->prefecture;
    my %zone = (
        '東京都' => 'kanto', '神奈川県' => 'kanto', '千葉県' => 'kanto',
        '大阪府' => 'kansai', '京都府' => 'kansai',
    );
    my $zone = $zone{$pref} // 'other';
    my %rate = (kanto => 500, kansai => 700, other => 1000);
    return $rate{$zone};
}
```

### Afterコード（handles による委譲）

#### Address: 配送ゾーン判定の責務

```perl
package Address;
use v5.36;
use Moo;

has prefecture => (is => 'ro', required => 1);

sub shipping_zone ($self) {
    my %zone = (
        '東京都' => 'kanto', '神奈川県' => 'kanto', '千葉県' => 'kanto',
        '大阪府' => 'kansai', '京都府' => 'kansai',
    );
    return $zone{$self->prefecture} // 'other';
}
```

#### Customer: Address への委譲

```perl
package Customer;
use v5.36;
use Moo;

has name    => (is => 'ro', required => 1);
has email   => (is => 'ro', required => 1);
has address => (
    is       => 'ro',
    required => 1,
    handles  => [qw(shipping_zone)],
);
```

#### Order: Customer への委譲

```perl
package Order;
use v5.36;
use Moo;

has item_name  => (is => 'ro', required => 1);
has quantity   => (is => 'ro', required => 1);
has unit_price => (is => 'ro', required => 1);
has customer   => (
    is       => 'ro',
    required => 1,
    handles  => [qw(shipping_zone)],
);
```

#### ShippingCalculator: 1段アクセスのみ

```perl
package ShippingCalculator;
use v5.36;
use Moo;

has order => (
    is       => 'ro',
    required => 1,
    handles  => [qw(shipping_zone)],
);

sub calculate ($self) {
    my %rate = (kanto => 500, kansai => 700, other => 1000);
    return $rate{$self->shipping_zone};
}
```
