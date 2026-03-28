# 構造案: コード探偵ロックの事件簿【Service Locator】

## メタ情報

| 項目 | 内容 |
|------|------|
| タイトル | コード探偵ロックの事件簿【Service Locator】便利な情報屋の裏の顔〜テストが壊す本番データの怪〜 |
| パターン | Service Locator → DI（Dependency Injection） |
| アンチパターン | Hidden Dependencies via Service Locator（Service Locatorによる暗黙の依存） |
| slug | service-locator |
| 公開日時 | 2026-04-09T07:07:05+09:00 |
| ファイルパス | content/post/2026/04/09/070705.md |

---

## 語り部プロファイル（依頼人）

| 項目 | 内容 |
|------|------|
| 名前 | 岡田 翔太（おかだ しょうた） |
| 年齢 | 34歳 |
| 職種 | 社内ツール開発チームリーダー |
| 一人称 | 僕 |
| 性格 | 責任感が強く、チームのテスト文化を育てようとする改革派。だが壁にぶつかると眉間にしわが寄る |
| 背景 | 社内の在庫管理ツールにテストを導入しようとしたが、テストを実行するたびに本番DBのデータが変わるという怪現象に遭遇。調べると、アプリ全体が ServiceLocator というグローバルレジストリから DB接続やメール送信サービスを取得しており、テスト環境でもそのまま本番インスタンスを掴んでしまう。モック差し替えの方法がわからず、テスト導入が頓挫しかけている |

---

## コード設計

### Beforeコード（アンチパターン: Service Locator による暗黙の依存）

`lib/ServiceLocator.pm`

```perl
package ServiceLocator;
use Moo;

my %registry;

sub register {
    my ($class, $name, $instance) = @_;
    $registry{$name} = $instance;
}

sub get {
    my ($class, $name) = @_;
    die "Service not found: $name\n" unless exists $registry{$name};
    return $registry{$name};
}

sub clear {
    my ($class) = @_;
    %registry = ();
}
```

`lib/OrderService.pm`（Before）

```perl
package OrderService;
use Moo;

sub place_order {
    my ($self, $item_id, $quantity) = @_;

    my $db    = ServiceLocator->get('db');
    my $mailer = ServiceLocator->get('mailer');

    my $order = { id => int(rand(10000)), item_id => $item_id, quantity => $quantity };
    $db->insert('orders', $order);
    $mailer->send(to => 'admin@example.com', subject => "New order: $item_id");

    return $order;
}
```

**問題点**:
- OrderService のコンストラクタからは DB やメーラーへの依存が見えない
- テスト時にモック差し替えするには ServiceLocator のグローバル状態を書き換える必要がある
- テスト間で ServiceLocator の状態がリセットされないと、テスト順序依存や本番データ破壊が起きる
- 依存関係がコードの内部に隠蔽されているため、依存グラフが把握できない

### Afterコード（DI: Dependency Injection）

`lib/OrderService.pm`（After）

```perl
package OrderService;
use Moo;

has db     => (is => 'ro', required => 1);
has mailer => (is => 'ro', required => 1);

sub place_order {
    my ($self, $item_id, $quantity) = @_;

    my $order = { id => int(rand(10000)), item_id => $item_id, quantity => $quantity };
    $self->db->insert('orders', $order);
    $self->mailer->send(to => 'admin@example.com', subject => "New order: $item_id");

    return $order;
}
```

**改善点**:
- コンストラクタの `has` 宣言で依存が明示的（「正面玄関から入る」）
- テスト時はモックオブジェクトをコンストラクタで渡すだけ
- ServiceLocator のグローバル状態に依存しないため、テスト間の干渉がゼロ
- 依存関係がインタフェースとして表明されるため、依存グラフが一目瞭然

---

## 5幕プロット

### I. 依頼（事務所への来客）

- 場面: 雑居ビルの一室「LCI」。ロックはヴィンテージの技術書（初版の「デザインパターン」GoF本）をルーペで眺めている
- 岡田が「テストを実行すると本番のデータが壊れるんです」と駆け込む
- ロック「ほう。テストが本番を壊す——よくある事件だが、犯人は意外なところにいることが多い。見せたまえ、ワトソン君」
- 岡田「岡田です。犯人って、テストコードのバグですか？」
- ロック「テストコードは無実だよ。真犯人は、君たちが頼りにしている情報屋だ」

### II. 現場検証（コードの指紋）

- ロックが ServiceLocator.pm と OrderService.pm を精読
- 「見たまえ。`ServiceLocator->get('db')` ——このクラスはどこからでもDBを手に入れられる。便利だね？」
- 岡田「ええ、ServiceLocator に登録しておけば、どのクラスからでもサービスを取得できます」
- ロック「それが問題なんだよ、ワトソン君。この情報屋は、誰にでも分け隔てなくサービスを渡す。テストコードにも、本番コードにも、まったく同じ本番インスタンスを」
- テスト環境でも ServiceLocator に本番DB接続が登録されたままであることを指摘
- 「依存が裏口から入ってくる——これが Service Locator の裏の顔だ」

### III. 推理披露（鮮やかなリファクタリング）

- ロック「解決策は、情報屋を排除して正面玄関を開くことだ」
- 岡田「正面玄関？」
- ロック「**Dependency Injection**——依存をコンストラクタで明示的に渡す。裏口で情報屋に頼む代わりに、正面玄関から堂々と入れるんだ」
- After の OrderService を実装・解説
- 岡田「`has db => (is => 'ro', required => 1)` って、DBをコンストラクタの引数として要求するんですか？」
- ロック「そうだ。依存が見える。テスト時はモックを渡せばいい。本番時は本物を渡せばいい。情報屋に問い合わせる必要はない」

### IV. 解決（平和なビルド）

- テストを実行。InMemoryDB（モック）を使い、本番DBに一切触れずにテストが通る
- メール送信もモックで、実際にメールを送らずに送信内容を検証
- 岡田「テストが安全に動く……！ 本番データに一切触れていない」
- ロック「報酬は、ServiceLocator に登録されていたサービスの数と同じ杯数のエスプレッソでいい」
- 岡田（心の中）：「二つしか登録されていなかったから、二杯か。割に合っている……のか？」

### V. 報告書（探偵の調査報告書）

- 事件概要表（容疑 → 真実 → 証拠）
- 推理のステップ（リファクタリング手順）
- ロックからワトソン君へのメッセージ

---

## フロントマター（予定）

```yaml
title: "コード探偵ロックの事件簿【Service Locator】便利な情報屋の裏の顔〜テストが壊す本番データの怪〜"
date: "2026-04-09T07:07:05+09:00"
draft: false
categories: [tech]
tags:
  - design-pattern
  - perl
  - moo
  - service-locator
  - hidden-dependencies
  - refactoring
  - code-detective
```
