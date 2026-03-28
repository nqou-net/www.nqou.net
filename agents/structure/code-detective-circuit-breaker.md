# 構造案: コード探偵ロックの事件簿【Circuit Breaker】

## メタ情報

| 項目 | 内容 |
|------|------|
| タイトル | コード探偵ロックの事件簿【Circuit Breaker】帰らない密偵たち〜落ちた通信網に送り続ける忠義の代償〜 |
| パターン | Circuit Breaker |
| アンチパターン | Cascading Failure（障害のある外部サービスへの無限リトライ）——外部API障害時にリトライを繰り返し、呼び出し側もリソースを使い果たして共倒れする |
| slug | circuit-breaker |
| 公開日時 | 2026-04-14T07:07:05+09:00 |
| ファイルパス | content/post/2026/04/14/070705.md |

---

## 語り部プロファイル（依頼人）

| 項目 | 内容 |
|------|------|
| 名前 | 白石 彩音（しらいし あやね） |
| 年齢 | 25歳 |
| 職種 | ECサイトのバックエンド開発者 |
| 一人称 | 私 |
| 性格 | 責任感が強く、障害が起きると一人で抱え込みがち。真面目だが視野が狭くなるタイプ |
| 背景 | ECサイトの注文処理を担当。在庫確認で外部の倉庫管理APIを呼び出しているが、API障害時にECサイト全体が応答不能になる。リトライ処理を追加したが、障害時にリトライが殺到しむしろ悪化。月に一度の倉庫API障害のたびに全面ダウンが発生 |

---

## コード設計

### Beforeコード（アンチパターン: Cascading Failure）

`lib/ExternalApiClient.pm`（Before）

```perl
package ExternalApiClient;
use Moo;
use Types::Standard qw(Str Int);

has endpoint => (is => 'ro', isa => Str, required => 1);
has max_retries => (is => 'ro', isa => Int, default => 3);

sub call {
    my ($self, $params) = @_;

    my $attempts = 0;
    while ($attempts < $self->max_retries) {
        $attempts++;
        my $result = $self->_do_request($params);
        return $result if $result->{success};
        # 失敗したら即リトライ
    }
    die "API call failed after $attempts attempts";
}

sub _do_request {
    my ($self, $params) = @_;
    # 外部APIへのHTTPリクエスト（シミュレーション）
    ...
}
```

**問題点**:
- API障害時、全リクエストが max_retries 回ずつリトライを試みる
- 各リトライでタイムアウトまで待機し、スレッド/接続を占有
- 100件のリクエストが来ると 300回（100×3）のリトライが発生
- 障害中のAPIに対してリトライが殺到し、呼び出し側もリソース枯渇で共倒れ

### Afterコード（Circuit Breaker パターン）

`lib/CircuitBreaker.pm`（After）

```perl
package CircuitBreaker;
use Moo;
use Types::Standard qw(Int Num Str CodeRef);
use Carp qw(croak);

has failure_threshold => (is => 'ro', isa => Int, default => 3);
has recovery_timeout  => (is => 'ro', isa => Num, default => 30);
has _state           => (is => 'rw', isa => Str, default => 'closed');
has _failure_count   => (is => 'rw', isa => Int, default => 0);
has _last_failure_time => (is => 'rw', isa => Num, default => 0);
has _now_func        => (is => 'ro', isa => CodeRef, default => sub { sub { time() } });

# Closed: 正常。リクエストを通す。失敗を数える。
# Open: 遮断中。リクエストを即座に拒否。
# Half-Open: 試験中。1件だけリクエストを通して回復を確認。

sub call {
    my ($self, $action) = @_;

    if ($self->_state eq 'open') {
        if ($self->_now_func->() - $self->_last_failure_time >= $self->recovery_timeout) {
            $self->_state('half_open');
        } else {
            croak "Circuit is open: requests are blocked";
        }
    }

    my $result = eval { $action->() };
    if ($@) {
        $self->_on_failure;
        croak $@;
    }
    $self->_on_success;
    return $result;
}

sub _on_success {
    my ($self) = @_;
    $self->_failure_count(0);
    $self->_state('closed');
}

sub _on_failure {
    my ($self) = @_;
    $self->_failure_count($self->_failure_count + 1);
    $self->_last_failure_time($self->_now_func->());
    if ($self->_failure_count >= $self->failure_threshold) {
        $self->_state('open');
    }
}

sub state { $_[0]->_state }
sub failure_count { $_[0]->_failure_count }
```

**改善点**:
- 失敗が閾値を超えるとCircuitが Open になり、リクエストを即座に拒否
- API障害中はリトライが発生せず、リソースを消費しない
- recovery_timeout 経過後に Half-Open で試行し、成功すれば Closed に復帰
- 外部APIの回復を待つ間、自システムは正常に応答できる

---

## 5幕プロット

### I. 依頼（事務所への来客）

- 場面: LCI事務所。ロックは壁にブレーカー（配電盤の遮断器）のカタログを貼って眺めている
- 白石が「外部APIが落ちるたびに、ECサイト全体が巻き添えで止まるんです」と訪問
- ロック「帰らない密偵を追って、次の密偵を送り込む。三人目が帰らなくなったら、もう送るべきではない」
- 白石「密偵？　APIのリトライの話なんですが」
- ロック「リトライは忠誠心の証だ。だが忠誠心が仲間を殺すこともある。証拠を見せたまえ」

### II. 現場検証（コードの指紋）

- ロックが ExternalApiClient の call メソッドを精読
- 「失敗しても即座にリトライ。三回繰り返す。だがAPIが落ちているなら、三回とも失敗する。100件のリクエストが来たら300回の無駄なリトライだ」
- 白石「リトライすれば、たまたま復旧するかもしれないと思って……」
- ロック「密偵が三人帰ってこないのに、四人目を送るのは希望ではない。無謀だ。犯人の名は **Cascading Failure**——忠実なリトライが、自分自身を巻き添えにする連鎖崩壊だ」

### III. 推理披露（鮮やかなリファクタリング）

- ロック「解決策は **Circuit Breaker** だ。電気のブレーカーと同じ原理。過負荷を検知したら回路を遮断し、被害の拡大を防ぐ」
- CircuitBreaker の三つの状態（Closed / Open / Half-Open）を解説
- 状態遷移図（Mermaid）
- `call` メソッドの実装・解説
- 白石「失敗が3回を超えたら、もうAPIを呼ばないんですか？」
- ロック「呼ばない。即座にエラーを返す。密偵を送るのをやめるんだ。そして一定時間後に一人だけ送ってみる。帰ってきたら、通信網が復旧した証拠だ」

### IV. 解決（平和なビルド）

- テスト実行。状態遷移テスト、閾値テスト、回復テストがすべてパス
- 白石「APIが落ちても、ECサイト自体は動き続ける……！」
- ロック「報酬は、このブレーカーの failure_threshold と同じ杯数のアールグレイでいい」

### V. 報告書（探偵の調査報告書）

- 事件概要表
- 推理のステップ
- ロックからワトソン君へのメッセージ

---

## フロントマター（予定）

```yaml
title: "コード探偵ロックの事件簿【Circuit Breaker】帰らない密偵たち〜落ちた通信網に送り続ける忠義の代償〜"
date: "2026-04-14T07:07:05+09:00"
draft: false
categories: [tech]
tags:
  - design-pattern
  - perl
  - moo
  - circuit-breaker
  - cascading-failure
  - refactoring
  - code-detective
```
