# 構造案: コード探偵ロックの事件簿【Bulkhead】

## メタ情報

| 項目 | 内容 |
|------|------|
| タイトル | コード探偵ロックの事件簿【Bulkhead】全館停電の共犯者〜一室の暴走が招く連鎖崩壊〜 |
| パターン | Bulkhead |
| アンチパターン | Shared Resource Pool（共有リソースプールの独占）——複数サービスが単一のコネクションプールを共有し、一つの遅延サービスが全リソースを占有して他サービスも道連れにする |
| slug | bulkhead |
| 公開日時 | 2026-04-16T07:07:05+09:00 |
| ファイルパス | content/post/2026/04/16/070705.md |

---

## 語り部プロファイル（依頼人）

| 項目 | 内容 |
|------|------|
| 名前 | 白石 彩音（しらいし あやね） |
| 年齢 | 25歳 |
| 職種 | ECサイトのバックエンド開発者 |
| 一人称 | 私 |
| 性格 | 責任感が強く、障害が起きると一人で抱え込みがち。前回の事件（Circuit Breaker）でロックの腕を信頼している |
| 背景 | 前回Circuit Breakerを導入して外部API障害時の共倒れは解消した。しかし今度は「APIが落ちてはいないが極端に遅い」状況で、画像変換処理がコネクションプールを長時間占有し、注文処理や通知サービスまで接続を取れず停止する新たな障害に直面。Circuit Breakerは発動しない（エラーではなく遅延のため）という盲点に苦しんでいる |

---

## コード設計

### Beforeコード（アンチパターン: Shared Resource Pool）

`lib/SharedPool.pm`（Before）

```perl
package SharedPool;
use Moo;
use Types::Standard qw(Int ArrayRef);
use Carp qw(croak);

has max_size    => (is => 'ro', isa => Int, default => 5);
has _available  => (is => 'rw', isa => Int, lazy => 1, builder => '_build_available');
has _log        => (is => 'ro', isa => ArrayRef, default => sub { [] });

sub _build_available { $_[0]->max_size }

sub acquire {
    my ($self, $label) = @_;
    if ($self->_available <= 0) {
        push @{$self->_log}, "REJECTED:$label";
        croak "Pool exhausted: no connections available for '$label'";
    }
    $self->_available($self->_available - 1);
    push @{$self->_log}, "ACQUIRED:$label";
    return 1;
}

sub release {
    my ($self, $label) = @_;
    if ($self->_available < $self->max_size) {
        $self->_available($self->_available + 1);
        push @{$self->_log}, "RELEASED:$label";
    }
}

sub available { $_[0]->_available }
sub log       { @{$_[0]->_log} }
```

`lib/ServiceRunner.pm`（Before）

```perl
package ServiceRunner;
use Moo;
use Types::Standard qw(InstanceOf);

has pool => (is => 'ro', isa => InstanceOf['SharedPool'], required => 1);

sub run_image_processing {
    my ($self) = @_;
    # 画像変換は重い——接続を長時間占有
    $self->pool->acquire('image');
    # ... 重い処理（接続を保持したまま）...
    $self->pool->release('image');
    return 'image_done';
}

sub run_order_processing {
    my ($self) = @_;
    # 注文処理は軽い——だがプールが空なら取得できない
    $self->pool->acquire('order');
    $self->pool->release('order');
    return 'order_done';
}

sub run_notification {
    my ($self) = @_;
    $self->pool->acquire('notify');
    $self->pool->release('notify');
    return 'notify_done';
}
```

**問題点**:
- 全サービスが単一の SharedPool（max_size=5）を共有
- 画像変換が遅延すると接続を長時間保持し、プールを占有
- 注文処理や通知は軽量なのに、接続を取得できずエラーになる
- Circuit Breakerは「失敗」を検知するが、「遅延による占有」は検知しない

### Afterコード（Bulkhead パターン）

`lib/Bulkhead.pm`（After）

```perl
package Bulkhead;
use Moo;
use Types::Standard qw(Int Str ArrayRef);
use Carp qw(croak);

has name           => (is => 'ro', isa => Str, required => 1);
has max_concurrent => (is => 'ro', isa => Int, required => 1);
has _active_count  => (is => 'rw', isa => Int, default => 0);
has _log           => (is => 'ro', isa => ArrayRef, default => sub { [] });

sub execute {
    my ($self, $action) = @_;
    if ($self->_active_count >= $self->max_concurrent) {
        push @{$self->_log}, "REJECTED:" . $self->name;
        croak sprintf(
            "Bulkhead '%s' is full (%d/%d): request rejected",
            $self->name, $self->_active_count, $self->max_concurrent,
        );
    }
    $self->_active_count($self->_active_count + 1);
    push @{$self->_log}, "ADMITTED:" . $self->name;
    my $result = eval { $action->() };
    my $err = $@;
    $self->_active_count($self->_active_count - 1);
    push @{$self->_log}, "RELEASED:" . $self->name;
    die $err if $err;
    return $result;
}

sub active_count { $_[0]->_active_count }
sub log          { @{$_[0]->_log} }
```

`lib/IsolatedServiceRunner.pm`（After）

```perl
package IsolatedServiceRunner;
use Moo;
use Types::Standard qw(InstanceOf);

has image_bulkhead => (
    is      => 'ro',
    isa     => InstanceOf['Bulkhead'],
    default => sub { Bulkhead->new(name => 'image', max_concurrent => 2) },
);
has order_bulkhead => (
    is      => 'ro',
    isa     => InstanceOf['Bulkhead'],
    default => sub { Bulkhead->new(name => 'order', max_concurrent => 3) },
);
has notify_bulkhead => (
    is      => 'ro',
    isa     => InstanceOf['Bulkhead'],
    default => sub { Bulkhead->new(name => 'notify', max_concurrent => 2) },
);

sub run_image_processing {
    my ($self) = @_;
    return $self->image_bulkhead->execute(sub {
        # 画像変換処理（重い）
        return 'image_done';
    });
}

sub run_order_processing {
    my ($self) = @_;
    return $self->order_bulkhead->execute(sub {
        return 'order_done';
    });
}

sub run_notification {
    my ($self) = @_;
    return $self->notify_bulkhead->execute(sub {
        return 'notify_done';
    });
}
```

**改善点**:
- 各サービスが独立した Bulkhead（隔壁）を持ち、同時実行数を個別に制限
- 画像変換が枠（max_concurrent=2）を使い切っても、注文処理（枠3）と通知（枠2）は影響を受けない
- 枠が満杯なら即座に拒否（遅延ではなく即時エラー）——待ち行列にならない
- Circuit Breakerと組み合わせることで「失敗の遮断」と「リソースの隔離」を両立

---

## 5幕プロット

### I. 依頼（再訪するワトソン）

- 場面: LCI事務所。ロックはデスクの上に小さな船の模型を組み立てている
- 白石が息を切らして再来訪「ロックさん、またシステムが落ちたんです！　Circuit Breakerを入れたのに！」
- ロック「ほう、また君か。今度はどんな事件かね、ワトソン君」
- 白石「APIは落ちてないんです。ただ、画像変換が異常に遅くて、他のサービスが全部止まって……」
- ロック（船の模型を見せながら）「この船にはいくつの区画がある？　一つの区画に水が入っても、他の区画は浸水しない。そういう設計になっている。だが、君のシステムは——壁のない船だ」

### II. 現場検証（コードの指紋）

- ロックが SharedPool と ServiceRunner のコードを精読
- 「全員が同じプールで泳いでいる。画像変換が5枠中4枠を占有した瞬間、注文処理は残り1枠を奪い合うことになる」
- 白石「でもCircuit Breakerは？」
- ロック「Circuit Breakerは**失敗**を数える。だが画像変換は失敗していない——ただ**遅い**だけだ。遅延は失敗ではない。しかし遅延がリソースを食い尽くすのは、沈黙の殺人だよ、ワトソン君」
- Mermaid図で共有プールの占有状況を可視化
- ロック「犯人の名は **Shared Resource Pool**——全員が同じ部屋にいるから、一人が暴れると全員が倒れる」

### III. 推理披露（鮮やかなリファクタリング）

- ロック「解決策は **Bulkhead（隔壁）** だ。船の隔壁と同じ原理。各サービスに専用の区画を割り当てる」
- Bulkhead クラスの構造を解説（name, max_concurrent, execute）
- IsolatedServiceRunner で各サービスが独立した Bulkhead を持つ構造を解説
- Mermaid図で隔離されたリソース配分を可視化
- 白石「画像変換の枠が満杯になっても、注文処理は自分の枠を使えるんですね！」
- ロック「その通り。そして枠が満杯なら即座に拒否する。待たせるのではなく、断る。行列に並ばせるより、門前払いの方が被害は少ない」
- 白石「Circuit Breakerと一緒に使えるんですか？」
- ロック「もちろんだ。Circuit Breakerが**回路の遮断**なら、Bulkheadは**部屋の隔離**だ。前回は回路を直した。今回は壁を建てる」

### IV. 解決（平和なビルド）

- テスト実行。隔離テスト、枠満杯テスト、独立動作テストがすべてパス
- 白石「画像変換が遅くなっても、注文はちゃんと通る……！」
- ロック「報酬は——この船の模型と同じ区画数のエスプレッソだ。つまり5杯」
- 白石「（船の区画の数と関係あるんだろうか……）」

### V. 報告書（探偵の調査報告書）

- 事件概要表: 容疑（Shared Resource Pool） / 真実（Bulkhead） / 証拠（効果）
- 推理のステップ
- ロックからワトソン君へのメッセージ（Circuit Breakerとの組み合わせに言及）

---

## フロントマター（予定）

```yaml
title: "コード探偵ロックの事件簿【Bulkhead】全館停電の共犯者〜一室の暴走が招く連鎖崩壊〜"
date: "2026-04-16T07:07:05+09:00"
draft: false
categories: [tech]
tags:
  - design-pattern
  - perl
  - moo
  - bulkhead
  - shared-resource-pool
  - refactoring
  - code-detective
```
