# 構造案: コード探偵ロックの事件簿【Feature Envy】

## メタ情報

| 項目 | 内容 |
|------|------|
| タイトル | コード探偵ロックの事件簿【Feature Envy】よそ見するメソッドの末路〜他人のポケットに手を突っ込む関数たち〜 |
| コードスメル | Feature Envy |
| 解決策 | Move Method + Moo の `handles`（委譲） |
| slug | feature-envy |
| 公開日時 | 2026-04-06T07:07:05+09:00 |
| ファイルパス | content/post/2026/04/06/070705.md |
| アーク | コードの悪臭捜査編（1/7） |

---

## 語り部プロファイル（依頼人）

| 項目 | 内容 |
|------|------|
| 名前 | 椎名 ミカ（しいな みか） |
| 年齢 | 26歳 |
| 職種 | SaaS企業の機能追加担当エンジニア（2年目） |
| 一人称 | 私 |
| 性格 | 冷静で観察力がある。困惑よりも懐疑的で、目の前の奇人を一歩引いて観察する。素直に「分からない」と聞く。ロックの奇行はスルーする耐性あり |
| 背景 | 前任者が残した「万能コントローラ」を引き継いで半年。機能追加のたびにテストが3本壊れる。メソッドの中で他クラスのゲッターが列をなしているが、どこから手を付ければいいか分からない |
| 話し方 | 実務寄りで簡潔。先輩に聞くべきか迷う世代。敬語だが距離を詰めない |
| 事前知識 | LCI は知らない。社内の先輩（元チームメイト）から「コードの設計を見てくれる人がいる」と紹介された |

---

## 変化点（今回の差分）

### 1. 語り部の声の差分
- 直近3本: 田中（真面目疲弊型）、高橋（反論型）、日下部（実務的諦観型）
- **今回**: 懐疑観察型。奇人を評価するまで判断を保留する。感情の起伏は小さいが、理解した瞬間の納得は深い

### 2. 導入の差分
- 直近3本: Slack DM→事務所訪問、ファミレスで偶然遭遇、同僚の紹介→デスク訪問
- **今回**: 社内の「コードレビュー勉強会」にロックが外部講師として来ている。語り部は参加者。勉強会の後に個別相談として接触。事務所にもファミレスにも行かない

### 3. 対話の差分
- 直近3本: 即ツッコミ型、反論型、戸惑い型
- **今回**: 観察型。ロックの言動を「これは何なのだろう」と一歩引いて見る。質問は実装の具体性（「それはこのクラスのテストも書き直しですか？」）に寄る

### 4. 終わり方の差分
- 直近3本: 監査対応の完了、テスト安定化、帳簿の整合
- **今回**: 報酬ギャグなし。リファクタリング後のテストが全部通った画面を見て「初めて自分のコードだと思えた」という静かな余韻

### 5. 関係性の差分
- 直近3本: 全員初対面で即ワトソン君
- **今回**: 勉強会の講師と参加者という「公式な場」での出会い。ロックはしばらく語り部のコードを見てから初めて「ワトソン君」と呼ぶ（序盤は呼ばない）

### 6. 質問の差分
- **Feature Envy の判定基準**: 「何割くらい他クラスを使っていたらアウトなんですか？」（数値的な目安を聞く）
- **Move Method の限界**: 「全部移動したら、元のクラスが空になりませんか？」（Middle Man化の懸念を先回り）
- **handles の実用性**: 「委譲って、呼び出し側のテストはどうなりますか？」

---

## コード設計

### Beforeコード（Feature Envy）

`lib/ReportGenerator.pm` — レポート生成クラスが、Order と Customer のデータに過度に依存

```perl
package ReportGenerator;
use Moo;

has order => (is => 'ro', required => 1);

sub generate_summary {
    my ($self) = @_;

    # 自分のデータをほぼ使わず、order と customer のゲッターばかり呼ぶ
    my $item_name  = $self->order->item_name;
    my $quantity   = $self->order->quantity;
    my $unit_price = $self->order->unit_price;
    my $subtotal   = $quantity * $unit_price;

    my $name    = $self->order->customer->name;
    my $email   = $self->order->customer->email;
    my $tier    = $self->order->customer->membership_tier;

    my $discount = 0;
    if ($tier eq 'gold') {
        $discount = $subtotal * 0.1;
    }
    elsif ($tier eq 'platinum') {
        $discount = $subtotal * 0.2;
    }

    my $total = $subtotal - $discount;

    return {
        customer_name  => $name,
        customer_email => $email,
        item           => $item_name,
        quantity       => $quantity,
        subtotal       => $subtotal,
        discount       => $discount,
        total          => $total,
    };
}
```

**問題点**:
- `generate_summary` は `$self` の属性を一切使っていない。`order` と `customer` のゲッターだけで構成されている
- 割引計算は Customer の `membership_tier` に完全に依存 → Customer に属すべきロジック
- 小計計算は Order の `quantity` と `unit_price` に完全に依存 → Order に属すべきロジック
- ReportGenerator を修正すると Order のテストも Customer のテストも影響を受ける

### Afterコード（Move Method + handles）

#### Step 1: 割引計算を Customer に移動

`lib/Customer.pm`

```perl
package Customer;
use v5.36;
use Moo;

has name            => (is => 'ro', required => 1);
has email           => (is => 'ro', required => 1);
has membership_tier => (is => 'ro', default => 'standard');

sub discount_rate ($self) {
    my %rates = (gold => 0.1, platinum => 0.2);
    return $rates{$self->membership_tier} // 0;
}
```

#### Step 2: 小計・合計計算を Order に移動

`lib/Order.pm`

```perl
package Order;
use v5.36;
use Moo;

has item_name  => (is => 'ro', required => 1);
has quantity   => (is => 'ro', required => 1);
has unit_price => (is => 'ro', required => 1);
has customer   => (is => 'ro', required => 1);

sub subtotal ($self) {
    return $self->quantity * $self->unit_price;
}

sub discount ($self) {
    return $self->subtotal * $self->customer->discount_rate;
}

sub total ($self) {
    return $self->subtotal - $self->discount;
}
```

#### Step 3: ReportGenerator を handles で簡素化

`lib/ReportGenerator.pm`

```perl
package ReportGenerator;
use v5.36;
use Moo;

has order => (
    is       => 'ro',
    required => 1,
    handles  => [qw(item_name quantity subtotal discount total)],
);

has _customer => (
    is      => 'lazy',
    builder => sub ($self) { $self->order->customer },
    handles => {
        customer_name  => 'name',
        customer_email => 'email',
    },
);

sub generate_summary ($self) {
    return {
        customer_name  => $self->customer_name,
        customer_email => $self->customer_email,
        item           => $self->item_name,
        quantity       => $self->quantity,
        subtotal       => $self->subtotal,
        discount       => $self->discount,
        total          => $self->total,
    };
}
```

**改善点**:
- 各メソッドは自クラスのデータだけを使っている（Feature Envy 解消）
- `discount_rate` は Customer が自分の `membership_tier` から計算（データと振る舞いの凝集）
- `subtotal`/`total` は Order が自分の `quantity`/`unit_price` から計算
- ReportGenerator は `handles` で委譲し、他クラスのゲッター連鎖が消えた
- 各クラスを独立してテスト可能

---

## プロット構成（5幕）

### I. 導入（勉強会の席で）

社内コードレビュー勉強会の終了後。語り部・椎名ミカは、外部講師として来ていたロックに声をかけられる。ロックは勉強会中に参加者のコードをチラ見し、椎名の画面に映っていたコードの「匂い」を嗅ぎ取っていた。

ロックの小道具: 勉強会のスライド操作用にヴィンテージの赤外線リモコンを使っていた（「レーザーポインタではなくリモコンである理由」をもったいぶって語る）。

勉強会の控え室で、椎名がノートPCを開く。

### II. 現場検証（よそ見するメソッドの指紋）

ロックが `ReportGenerator#generate_summary` を見て、`$self->order->customer->...` の連鎖に注目。「このメソッドは自分のクラスのデータを一つも使っていない。他人の家の冷蔵庫を勝手に開けて料理しているようなものだ」と指摘。

椎名が「でもこのクラスの仕事はレポートを作ることですよね？」と反論 → ロックが「仕事の名前と仕事の中身は別物だ」と返す。

Mermaid 図でアクセサの呼び出し方向を可視化。

### III. 推理披露（Move Method と handles）

3段階のリファクタリングを実演:
1. `discount_rate` を Customer に移動 → 椎名「全部移動したら元のクラスが空になりませんか？」→ ロック「移動するのは他人のデータに依存しているメソッドだけだ。Middle Man にしてはいけない」
2. `subtotal`/`total` を Order に移動
3. ReportGenerator に `handles` を導入 → 椎名「委譲って要するにショートカットですか？」→ ロック「ショートカットではない。インターフェースの約束だ」

### IV. 解決（テストが通る瞬間）

各クラス単独でテストを実行。Customer のテストは Customer の変更だけで完結し、Order のテストは Order だけで完結する。ReportGenerator のテストは委譲先のモックで独立動作。

以前は ReportGenerator を修正すると3モジュール分のテストが壊れていたが、今はそれぞれ独立している。

### V. 報告書（探偵の調査報告書）

テーブル: Feature Envy → Move Method + handles
推理のステップ: 3段階のリファクタリング手順
ロックより: 報酬ギャグなし。静かに「自分のデータを知っているメソッドだけが、信用に足る証言者だ」のような一言で締める。
