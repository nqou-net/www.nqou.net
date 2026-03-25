# 構造案: コード探偵ロックの事件簿【Unit of Work】

## メタ情報

| 項目 | 内容 |
|------|------|
| タイトル | コード探偵ロックの事件簿【Unit of Work】宙に浮く証拠品の行方〜バラバラに届く提出書類と壊れた帳簿〜 |
| パターン | Unit of Work |
| アンチパターン | Scattered Writes（散弾銃的DB更新） |
| slug | unit-of-work |
| 公開日時 | 2026-04-05T07:07:05+09:00 |
| ファイルパス | content/post/2026/04/05/070705.md |

---

## 語り部プロファイル（依頼人）

| 項目 | 内容 |
|------|------|
| 名前 | 田中 誠（たなか まこと） |
| 年齢 | 32歳 |
| 職種 | ECサイトのバックエンドエンジニア |
| 一人称 | 僕 |
| 性格 | 真面目で几帳面。原因不明のバグに疲弊し、自己不信に陥りかけている |
| 背景 | 担当ECサイトの注文処理で、週に数回「注文は完了しているのに在庫が減らない」または「在庫は減っているのに注文記録がない」という不整合が発生。ログにエラーなし。毎回手動でDB修正している。先週末もまたクレームが来て、月曜の朝にLCIを訪れた |

---

## コード設計

### Beforeコード（アンチパターン: Scattered Writes）

`lib/OrderService.pm`

```perl
package OrderService;
use Moo;
use OrderRepository;
use InventoryRepository;
use PaymentRepository;

has order_repo     => (is => 'ro', default => sub { OrderRepository->new });
has inventory_repo => (is => 'ro', default => sub { InventoryRepository->new });
has payment_repo   => (is => 'ro', default => sub { PaymentRepository->new });

sub create_order {
    my ($self, $params) = @_;

    my $order = Order->new(
        item_id  => $params->{item_id},
        quantity => $params->{quantity},
        user_id  => $params->{user_id},
    );

    # それぞれ独立して保存。どれかが失敗しても残りは実行済み
    $self->order_repo->save($order);                          # 1. 注文を保存
    $self->inventory_repo->decrease(                          # 2. 在庫を減らす
        $params->{item_id}, $params->{quantity}
    );
    $self->payment_repo->save(Payment->new(order => $order)); # 3. 支払いを保存
}
```

**問題点**:
- 3つのDB操作がそれぞれ独立している
- 2番目（在庫更新）でエラーが発生した場合、注文は保存済み・在庫は更新されずという不整合状態になる
- エラーが起きてもトランザクション的なロールバックがない

### Afterコード（Unit of Work）

`lib/UnitOfWork.pm`

```perl
package UnitOfWork;
use Moo;
use Carp qw(croak);

has _new_objects      => (is => 'ro', default => sub { [] });
has _dirty_objects    => (is => 'ro', default => sub { [] });
has _removed_objects  => (is => 'ro', default => sub { [] });
has _dbh              => (is => 'ro', required => 1);

sub register_new {
    my ($self, $obj) = @_;
    push @{ $self->_new_objects }, $obj;
}

sub register_dirty {
    my ($self, $obj) = @_;
    push @{ $self->_dirty_objects }, $obj;
}

sub commit {
    my ($self) = @_;
    my $dbh = $self->_dbh;

    $dbh->begin_work;
    eval {
        for my $obj (@{ $self->_new_objects }) {
            $obj->insert($dbh);
        }
        for my $obj (@{ $self->_dirty_objects }) {
            $obj->update($dbh);
        }
        $dbh->commit;
    };
    if ($@) {
        $dbh->rollback;
        croak "Transaction failed, rolled back: $@";
    }
}
```

`lib/OrderService.pm`（リファクタリング後）

```perl
package OrderService;
use Moo;
use UnitOfWork;

has _dbh => (is => 'ro', required => 1);

sub create_order {
    my ($self, $params) = @_;

    my $uow = UnitOfWork->new(dbh => $self->_dbh);

    my $order = Order->new(
        item_id  => $params->{item_id},
        quantity => $params->{quantity},
        user_id  => $params->{user_id},
    );

    my $inventory = Inventory->find($self->_dbh, $params->{item_id});
    $inventory->decrease($params->{quantity});

    my $payment = Payment->new(order => $order);

    # すべての変更をUnit of Workに登録
    $uow->register_new($order);
    $uow->register_dirty($inventory);
    $uow->register_new($payment);

    # 一括コミット（失敗すれば全ロールバック）
    $uow->commit;
}
```

---

## 5幕プロット

### I. 依頼（事務所への来客）

- 場面: 雑居ビルの一室「LCI」。ロックはロッキングチェアで量子コンピュータの学術論文を読みながらエナジードリンクを飲んでいる
- 田中が「月曜の朝にまた在庫と注文の帳簿が合いませんでした」と駆け込む
- ロックは論文から目を離さず「そのコードのにおいは、宙に浮く証拠品のにおいだよ、ワトソン君」と呟く
- 田中「え、ワトソン…？僕は田中です」
- ロック「君は今日から助手だ。ワトソン君と呼ぶ。反論は認めない」

### II. 現場検証（コードの指紋）

- ロックが OrderService::create_order を精読
- 「見たまえ、ワトソン君。3つの保存操作が、それぞれ独立した封筒で証拠品として提出されている」
- 田中「でも、エラーログがないんです。エラーが出ていないのに不整合になるなんて……」
- ロック「ふむ。エラーは出ている。ただし、君が見ていない場所で」
- 2番目の在庫更新で稀に例外が起き、evalなどで握りつぶされていることを指摘（あるいは単純に例外が呼び出し元に伝播するが注文は既に保存済み）
- 「真犯人はここだ、ワトソン君。アトミックなき更新地獄、別名『散弾銃的DB更新』だ」

### III. 推理披露（鮮やかなリファクタリング）

- ロック「解決策は『証拠品を一括封印する金庫』を用意することだ」
- 田中「金庫？」
- ロック「Unit of Work——作業単位だよ。すべての変更をこの金庫に預け、最後にまとめて提出する。途中で何か起きれば、金庫ごと破棄する」
- UnitOfWork.pm の実装を解説（register_new / register_dirty / commit）
- 田中「つまり、DBへの書き込みをすぐに行わず、全部準備してから一気にトランザクションで実行するということですか？」
- ロック「その通りだよ、ワトソン君。初歩的なことだ」（初めて田中を褒める）
- OrderService.pm のリファクタリングをロックが実演

### IV. 解決（平和なビルド）

- テストを実行。在庫更新が失敗するシナリオで注文も保存されないことを確認
- 正常系でも在庫・注文・支払いがすべて揃うことを確認
- ビルドが緑色に点灯
- 田中「これで月曜の朝が怖くなくなります……」
- ロック「報酬は、このリポジトリの行数と同じミリ数のバーボンでいい」
- 田中（心の中）：「そんな都合のいい換算方法があるか」

### V. 報告書（探偵の調査報告書）

- 事件概要表
- 推理のステップ（リファクタリング手順）
- ロックからワトソン君へのメッセージ

---

## フロントマター（予定）

```yaml
title: "コード探偵ロックの事件簿【Unit of Work】宙に浮く証拠品の行方〜バラバラに届く提出書類と壊れた帳簿〜"
date: "2026-04-05T07:07:05+09:00"
draft: false
categories: [tech]
tags:
  - design-pattern
  - perl
  - moo
  - unit-of-work
  - scattered-writes
  - refactoring
  - code-detective
```
