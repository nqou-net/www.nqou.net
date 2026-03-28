# 構造案: コード探偵ロックの事件簿【Anti-Corruption Layer】

## メタ情報

| 項目 | 内容 |
|------|------|
| タイトル | コード探偵ロックの事件簿【Anti-Corruption Layer】翻訳なき外交官〜異国の書式が壊す捜査本部〜 |
| パターン | Anti-Corruption Layer |
| アンチパターン | Domain Pollution（ドメイン汚染）——外部システムの独自フォーマットがドメインコード全体に散らばり、外部仕様変更のたびに自システムの何十箇所も修正が必要になる |
| slug | anti-corruption-layer |
| 公開日時 | 2026-04-17T07:07:05+09:00 |
| ファイルパス | content/post/2026/04/17/070705.md |

---

## 語り部プロファイル（依頼人）

| 項目 | 内容 |
|------|------|
| 名前 | 藤村 真帆（ふじむら まほ） |
| 年齢 | 26歳 |
| 職種 | 自社ECサイトと外部倉庫管理システムの連携担当エンジニア |
| 一人称 | 私 |
| 性格 | 几帳面で責任感が強いが、外部APIの仕様変更に振り回されて疲弊している |
| 背景 | 自社ECサイトの在庫管理を担当。外部の倉庫管理APIが返すデータ形式が独特（`qty_avlbl` のような略語カラム名、`YYYYDDMM` の歪な日付形式、`1/0` のステータス）で、自社ドメインコード全体に外部形式の変換処理が散らばっている。先月の外部API仕様変更で、二十箇所以上を修正する羽目になった |

---

## コード設計

### Beforeコード（アンチパターン: Domain Pollution）

```perl
package OrderService;
use Moo;
use Types::Standard qw(Object);

has warehouse_api => (is => 'ro', isa => Object, required => 1);

sub check_availability {
    my ($self, $product_id) = @_;
    my $raw = $self->warehouse_api->get_stock($product_id);

    # 外部APIの形式を直接解釈
    my $quantity  = $raw->{qty_avlbl};   # 略語カラム名
    my $raw_date  = $raw->{lst_upd};     # YYYYDDMM 形式
    my $available = $raw->{sts} == 1;    # 1/0 ステータス

    # 歪な日付を変換
    my ($y, $d, $m) = $raw_date =~ /^(\d{4})(\d{2})(\d{2})$/;
    my $updated_at = "$y-$m-$d";

    return {
        quantity   => $quantity,
        available  => $available,
        updated_at => $updated_at,
    };
}

sub place_order {
    my ($self, $product_id, $amount) = @_;
    my $stock = $self->check_availability($product_id);
    die "Out of stock" unless $stock->{available};
    die "Insufficient stock" unless $stock->{quantity} >= $amount;

    # 外部APIへ在庫減算を依頼（またも外部形式）
    return $self->warehouse_api->reduce_stock({
        prd_id  => $product_id,
        qty_rdc => $amount,
        sts     => 1,
    });
}
```

**問題点**:
- `qty_avlbl`, `lst_upd`, `sts` など外部APIの独自カラム名がドメインコードに直接登場
- `YYYYDDMM` の歪な日付変換が呼び出し側に散らばる
- 外部APIの仕様変更（カラム名変更、日付形式変更）で自ドメインの何十箇所も修正が必要
- ドメインロジック（在庫確認・注文処理）と外部形式の変換が混在

### Afterコード（Anti-Corruption Layer パターン）

```perl
# ドメインオブジェクト: 自ドメインの言語で表現
package Stock;
use Moo;
use Types::Standard qw(Int Str Bool);

has product_id => (is => 'ro', isa => Int, required => 1);
has quantity   => (is => 'ro', isa => Int, required => 1);
has available  => (is => 'ro', isa => Bool, required => 1);
has updated_at => (is => 'ro', isa => Str, required => 1);

# Anti-Corruption Layer: 外部形式とドメインの翻訳層
package WarehouseTranslator;
use Moo;
use Types::Standard qw(Object);

has api => (is => 'ro', isa => Object, required => 1);

sub fetch_stock {
    my ($self, $product_id) = @_;
    my $raw = $self->api->get_stock($product_id);
    return $self->_to_stock($product_id, $raw);
}

sub reduce_stock {
    my ($self, $product_id, $amount) = @_;
    return $self->api->reduce_stock(
        $self->_to_external_reduce($product_id, $amount)
    );
}

sub _to_stock {
    my ($self, $product_id, $raw) = @_;
    my ($y, $d, $m) = $raw->{lst_upd} =~ /^(\d{4})(\d{2})(\d{2})$/;
    return Stock->new(
        product_id => $product_id,
        quantity   => $raw->{qty_avlbl},
        available  => $raw->{sts} == 1,
        updated_at => "$y-$m-$d",
    );
}

sub _to_external_reduce {
    my ($self, $product_id, $amount) = @_;
    return {
        prd_id  => $product_id,
        qty_rdc => $amount,
        sts     => 1,
    };
}

# ドメインサービス: 自ドメインの言語だけで書かれている
package OrderService;
use Moo;
use Types::Standard qw(Object);

has warehouse => (is => 'ro', isa => Object, required => 1);

sub check_availability {
    my ($self, $product_id) = @_;
    return $self->warehouse->fetch_stock($product_id);
}

sub place_order {
    my ($self, $product_id, $amount) = @_;
    my $stock = $self->check_availability($product_id);
    die "Out of stock" unless $stock->available;
    die "Insufficient stock" unless $stock->quantity >= $amount;
    return $self->warehouse->reduce_stock($product_id, $amount);
}
```

**改善点**:
- `WarehouseTranslator` が外部形式とドメインの唯一の翻訳層
- `OrderService` は `Stock` オブジェクトだけを扱い、外部カラム名を一切知らない
- 外部API仕様変更時の修正は `WarehouseTranslator` の1箇所だけ
- ドメインロジックと外部形式変換が完全に分離

---

## 5幕プロット

### I. 依頼（事務所への来客）

- 場面: LCI事務所。ロックは外国語の辞書を数冊並べて、翻訳作業のふりをしている
- 藤村が「外部APIの仕様が変わるたびに、自社コードの二十箇所以上を直す羽目になるんです」と訪問
- ロック「翻訳なき外交官だね。異国の書式をそのまま自国の公文書に混ぜれば、異国の政策が変わるたびに自国の法律を書き直す羽目になる」
- 藤村「外交官？　APIの話なんですが……」

### II. 現場検証（コードの指紋）

- ロックが OrderService を精読
- 「`qty_avlbl`、`lst_upd`、`sts`——この暗号のような名前は外部APIのものだね。それが OrderService の中に直接書かれている」
- 藤村「外部APIが返す形式だから、仕方なく……」
- ロック「初歩的なにおいだよ、ワトソン君。**Domain Pollution**——外部の汚れが自ドメインを侵食している」

### III. 推理披露（鮮やかなリファクタリング）

- ロック「解決策は **Anti-Corruption Layer** だ。外部との境界に翻訳層を置く」
- Stock（ドメインオブジェクト）、WarehouseTranslator（防腐層）、OrderService（浄化済み）の三層を実装
- 藤村「OrderService から外部APIの痕跡が消えた……！」
- ロック「外交には通訳がいる。異国の書類を直接読むな、翻訳してから読め」

### IV. 解決（平和なビルド）

- テスト実行。ドメインテストと翻訳テストがすべてパス
- 外部API仕様変更シミュレーション: Translator だけ修正すれば OrderService は無傷
- ロック「報酬は、翻訳した属性の数と同じ杯数のダージリンでいい」

### V. 報告書（探偵の調査報告書）

---

## フロントマター（予定）

```yaml
title: "コード探偵ロックの事件簿【Anti-Corruption Layer】翻訳なき外交官〜異国の書式が壊す捜査本部〜"
date: "2026-04-17T07:07:05+09:00"
draft: false
categories: [tech]
tags:
  - design-pattern
  - perl
  - moo
  - anti-corruption-layer
  - domain-pollution
  - refactoring
  - code-detective
```
