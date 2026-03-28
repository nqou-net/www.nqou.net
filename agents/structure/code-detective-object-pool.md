# 構造案: コード探偵ロックの事件簿【Object Pool】

## メタ情報

| 項目 | 内容 |
|------|------|
| タイトル | コード探偵ロックの事件簿【Object Pool】回転ドアの人材派遣〜使い捨て接続が招くシステム崩壊〜 |
| パターン | Object Pool |
| アンチパターン | Excessive Object Creation（高コストオブジェクトの繰り返し生成・破棄）——DB接続を処理のたびに生成・切断し、負荷増大時にリソース枯渇を起こす |
| slug | object-pool |
| 公開日時 | 2026-04-13T07:07:05+09:00 |
| ファイルパス | content/post/2026/04/13/070705.md |

---

## 語り部プロファイル（依頼人）

| 項目 | 内容 |
|------|------|
| 名前 | 中西 蓮（なかにし れん） |
| 年齢 | 28歳 |
| 職種 | 社内バッチ処理システムの運用担当エンジニア |
| 一人称 | 僕 |
| 性格 | 実直で真面目だが、パフォーマンス問題には経験が浅い。障害が起きると慌ててログを追いかけるタイプ |
| 背景 | 社内の月末売上集計バッチを運用している。通常時は問題ないが、月末の大量データ処理時にDB接続数の上限に達してタイムアウトする障害が頻発。調査したところ、各レコードの処理ごとにDB接続を生成・切断していた。前任者が書いたコードをそのまま使い続けていたが、データ量の増加で限界に達した |

---

## コード設計

### Beforeコード（アンチパターン: Excessive Object Creation）

`lib/DatabaseConnection.pm`（共通）

```perl
package DatabaseConnection;
use Moo;
use Types::Standard qw(Str Int Bool);

has host     => (is => 'ro', isa => Str, default => 'localhost');
has port     => (is => 'ro', isa => Int, default => 5432);
has database => (is => 'ro', isa => Str, default => 'sales');
has _connected => (is => 'rw', isa => Bool, default => 0);

our $TOTAL_CREATED = 0;

sub connect {
    my ($self) = @_;
    $TOTAL_CREATED++;
    # 実際にはTCPハンドシェイク・認証等の高コスト処理
    $self->_connected(1);
    return $self;
}

sub disconnect {
    my ($self) = @_;
    $self->_connected(0);
    return;
}

sub execute {
    my ($self, $query, @params) = @_;
    die "Not connected" unless $self->_connected;
    # 簡易シミュレーション: クエリと引数を返す
    return { query => $query, params => \@params, status => 'ok' };
}

sub is_connected { $_[0]->_connected }
```

`lib/BatchProcessor.pm`（Before）

```perl
package BatchProcessor;
use Moo;

sub process_records {
    my ($self, $records) = @_;

    my @results;
    for my $record (@$records) {
        # 毎回接続を生成して切断する
        my $conn = DatabaseConnection->new;
        $conn->connect;

        my $result = $conn->execute(
            'SELECT * FROM sales WHERE id = ?', $record->{id}
        );
        push @results, $result;

        $conn->disconnect;
    }
    return \@results;
}
```

**問題点**:
- レコードごとにDB接続を生成・切断している
- 1000件のレコードで1000回の接続生成が発生
- 接続生成はTCPハンドシェイク・認証を含む高コスト処理
- 同時接続数の上限に達するとシステムがタイムアウトする
- 接続のオーバーヘッドが処理時間の大半を占める

### Afterコード（Object Pool パターン）

`lib/ConnectionPool.pm`（After）

```perl
package ConnectionPool;
use Moo;
use Types::Standard qw(Int ArrayRef CodeRef);
use Carp qw(croak);

has max_size   => (is => 'ro', isa => Int, default => 5);
has factory    => (is => 'ro', isa => CodeRef, required => 1);
has _available => (is => 'ro', isa => ArrayRef, default => sub { [] });
has _in_use    => (is => 'ro', isa => ArrayRef, default => sub { [] });

sub acquire {
    my ($self) = @_;
    my $obj;
    if (@{ $self->_available }) {
        $obj = pop @{ $self->_available };
    }
    elsif ($self->size < $self->max_size) {
        $obj = $self->factory->();
    }
    else {
        croak "Pool exhausted: all ${\$self->max_size} objects in use";
    }
    push @{ $self->_in_use }, $obj;
    return $obj;
}

sub release {
    my ($self, $obj) = @_;
    my @remaining;
    my $found = 0;
    for my $item (@{ $self->_in_use }) {
        if (!$found && $item == $obj) {
            $found = 1;
            next;
        }
        push @remaining, $item;
    }
    croak "Object not found in pool" unless $found;
    @{ $self->_in_use } = @remaining;
    push @{ $self->_available }, $obj;
    return;
}

sub size {
    my ($self) = @_;
    return scalar(@{ $self->_available }) + scalar(@{ $self->_in_use });
}

sub available_count {
    my ($self) = @_;
    return scalar @{ $self->_available };
}

sub in_use_count {
    my ($self) = @_;
    return scalar @{ $self->_in_use };
}
```

`lib/BatchProcessor.pm`（After）

```perl
package BatchProcessor;
use Moo;

has pool => (is => 'ro', required => 1);

sub process_records {
    my ($self, $records) = @_;

    my @results;
    for my $record (@$records) {
        my $conn = $self->pool->acquire;

        my $result = $conn->execute(
            'SELECT * FROM sales WHERE id = ?', $record->{id}
        );
        push @results, $result;

        $self->pool->release($conn);
    }
    return \@results;
}
```

**改善点**:
- 接続をプールに保持し、使い終わったら返却して再利用
- 1000件のレコードでも接続生成は最大 `max_size` 回（例: 5回）
- プールの上限により同時接続数を制御可能
- 接続生成のオーバーヘッドが劇的に減少
- `acquire` / `release` の明確なライフサイクル管理

---

## 5幕プロット

### I. 依頼（事務所への来客）

- 場面: 雑居ビルの一室「LCI」。ロックは使い終わったエナジードリンクの缶を棚に並べ、「再利用可能」のラベルを貼っている（語り部ツッコミ：缶は再利用できないのでは）
- 中西が「月末のバッチが毎回タイムアウトして、DB接続数が上限に達するんです」と訪問
- ロック「ほう。回転ドアの人材派遣だね」
- 中西「回転ドア？　人材派遣？」
- ロック「一つの仕事のたびに新人を雇い、仕事が終わったら即クビにする。毎回採用面接からやり直しだ。そんな現場が効率的なわけがない。——僕を見たまえ。ワトソン君を毎回クビにして新しい助手を雇い直していたら、事務所が回るかね？」
- 中西（心の中）：「助手になった覚えはないし、それ以前にこの人の事務所に常勤スタッフがいるとも思えないけど……」

### II. 現場検証（コードの指紋）

- ロックが BatchProcessor の process_records メソッドを精読
- 「見たまえ。ループの中で毎回 `DatabaseConnection->new` して `connect` して、処理が終わったら `disconnect` している」
- 中西「普通のことじゃないですか？　使ったら閉じるのがマナーだと思っていました」
- ロック「一つのレコードに一つの接続。1000件なら1000回の接続生成。TCPハンドシェイク、認証、リソース確保……毎回これをやっている。犯人の名は **Excessive Object Creation**——高コストなオブジェクトの使い捨てだ」
- ロック「初歩的なにおいだよ、ワトソン君。接続を使い捨てにすれば、いつか資源は枯渇する」

### III. 推理披露（鮮やかなリファクタリング）

- ロック「解決策は**Object Pool**だ。生成コストの高いオブジェクトをプールに保持し、使い終わったら捨てるのではなく返却する。次に必要になったときは、プールから取り出すだけでいい」
- ConnectionPool の実装・解説
  - `factory`: 接続生成方法をクロージャで注入（テスト容易性の確保）
  - `acquire`: プールに空きがあれば再利用、なければ上限内で新規生成
  - `release`: 使い終わったオブジェクトをプールに返却
  - `max_size`: 同時使用の上限
- BatchProcessor のリファクタリング: `pool->acquire` / `pool->release` に置き換え
- 中西「1000件でも接続は5つだけ……！　196倍も節約できるんですね」
- ロック「人材を大切にすることだよ、ワトソン君。優秀な部下は使い捨てにするものではない」

### IV. 解決（平和なビルド）

- テスト実行。プールの生成数テスト、再利用テスト、上限テストがすべてパス
- 中西「月末のバッチも、これなら接続数の上限に引っかからない……」
- ロック「報酬は、プールの `max_size` と同じ杯数のバーボンでいい」
- 中西（心の中）：「5杯……仕事中なのに……」

### V. 報告書（探偵の調査報告書）

- 事件概要表（アンチパターン → パターンの対応）
- 推理のステップ
- ロックからワトソン君へのメッセージ：「高価なリソースは使い捨てにするな。回転ドアの人材派遣を続ければ、いつか誰も来なくなる」

---

## フロントマター（予定）

```yaml
title: "コード探偵ロックの事件簿【Object Pool】回転ドアの人材派遣〜使い捨て接続が招くシステム崩壊〜"
date: "2026-04-13T07:07:05+09:00"
draft: false
categories: [tech]
tags:
  - design-pattern
  - perl
  - moo
  - object-pool
  - excessive-object-creation
  - refactoring
  - code-detective
```
