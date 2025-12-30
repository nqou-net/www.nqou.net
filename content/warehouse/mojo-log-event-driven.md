---
title: "Mojo::Log で学ぶイベント駆動プログラミング入門 — 調査レポート"
slug: "mojo-log-event-driven"
date: 2025-12-29
tags:
  - mojo-log
  - event-driven
  - perl
description: "Mojo::Log とイベント駆動プログラミングの基礎、Observer パターン、実用例をまとめた調査レポート。"
image: /favicon.png
draft: false
---

## 調査目的

「Mojo::Log で学ぶイベント駆動プログラミング入門」という記事を作成するための事前調査。

### 対象読者

- 初歩的なプログラミングの知識を身につけた入門者
- イベント駆動が面白そうだと感じているが、自分で書くとなるとピンとこない人

### 目標

- Perlでイベント駆動プログラミングの基礎的な知識が得られる

## 実施日

2025-12-29

## 参照元 (URL)

### 公式ドキュメント

- Mojo::Log 公式ドキュメント（英語）: https://docs.mojolicious.org/Mojo/Log
- Mojo::Log MetaCPAN: https://metacpan.org/pod/Mojo::Log
- Mojo::Log 公式ドキュメント（日本語訳）: https://mojodoc.perlzemi.com/Mojo::Log.html
- Mojo::EventEmitter 公式ドキュメント（英語）: https://docs.mojolicious.org/Mojo/EventEmitter
- Mojo::EventEmitter 公式ドキュメント（日本語訳）: https://mojodoc.perlzemi.com/Mojo::EventEmitter.html
- Mojolicious 公式サイト: https://mojolicious.org/
- Mojolicious ドキュメント: https://docs.mojolicious.org/

### 参考記事

- Perl+Mojoでイベント駆動プログラミング (Qiita): https://qiita.com/skaji/items/c226f894581881796ed1
- PythonでのイベントObserverパターンとPubSubの実装 (Qiita): https://qiita.com/Tadataka_Takahashi/items/475f6d160e94984156d2
- The Observer vs Pub-Sub Pattern (Design Gurus): https://www.designgurus.io/blog/observer-vs-pub-sub-pattern
- Observer pattern (Wikipedia): https://en.wikipedia.org/wiki/Observer_pattern
- イベント駆動型プログラミング (Wikipedia): https://ja.wikipedia.org/wiki/%E3%82%A4%E3%83%99%E3%83%B3%E3%83%88%E9%A7%86%E5%8B%95%E5%9E%8B%E3%83%97%E3%83%AD%E3%82%B0%E3%83%A9%E3%83%9F%E3%83%B3%E3%82%B0
- イベントループ (Wikipedia): https://ja.wikipedia.org/wiki/%E3%82%A4%E3%83%99%E3%83%B3%E3%83%88%E3%83%AB%E3%83%BC%E3%83%97
- Stack Overflow: Mojo::Log how to log to file and to stderr?: https://stackoverflow.com/questions/75815292/mojolog-how-to-log-to-file-and-to-stderr

---

## 発見・結論

### 1. Mojo::Log の基本情報

#### Mojo::Log とは何か

- Mojoliciousフレームワークで使われるシンプルなロガーモジュール
- `Mojo::EventEmitter` を継承しており、イベント駆動機能を持つ
- 軽量で拡張性が高く、入門者にイベント駆動を学ぶのに最適な教材

#### 公式ドキュメントURL

- 英語版: https://docs.mojolicious.org/Mojo/Log
- 日本語訳: https://mojodoc.perlzemi.com/Mojo::Log.html
- MetaCPAN: https://metacpan.org/pod/Mojo::Log

#### バージョン情報

- Mojo::Log は Mojolicious ディストリビューションに含まれる
- 現在の最新バージョン: Mojolicious 9.42 以降（2025年12月時点）
- Mojolicious のバージョンアップに合わせて更新される

#### 主要なAPIと機能

**コンストラクタ:**
```perl
my $log = Mojo::Log->new;
my $log = Mojo::Log->new(path => '/var/log/mojo.log', level => 'warn');
```

**ログ出力メソッド:**
- `$log->trace('メッセージ')` - 最も詳細なログ
- `$log->debug('メッセージ')` - デバッグ情報
- `$log->info('メッセージ')` - 一般情報
- `$log->warn('メッセージ')` - 警告
- `$log->error('メッセージ')` - エラー
- `$log->fatal('メッセージ')` - 致命的エラー

**主要な属性:**
- `color` - ログ出力の色付け
- `format` - ログフォーマットコールバック
- `handle` - 出力先ファイルハンドル
- `level` - ログレベル
- `path` - ログファイルパス
- `history` / `max_history_size` - ログ履歴保持

---

### 2. Mojo::Log のイベント駆動機能

#### Mojo::Log が発火するイベント

Mojo::Log は `message` イベントを発火する:

```perl
# ログメッセージが出力されるたびに message イベントが発火
$log->on(message => sub {
    my ($log, $level, @lines) = @_;
    say "$level: ", @lines;
});
```

#### `on` メソッドによるイベント購読

```perl
use Mojo::Log;

my $log = Mojo::Log->new;

# イベントを購読
$log->on(message => sub {
    my ($log, $level, @lines) = @_;
    # $log - Mojo::Log オブジェクト
    # $level - ログレベル (trace, debug, info, warn, error, fatal)
    # @lines - ログメッセージ
    say "[$level] ", join(' ', @lines);
});

$log->info('これはinfoメッセージです');
# 出力: [info] これはinfoメッセージです
```

#### `emit` メソッドによるイベント発火

`emit` メソッドは `Mojo::EventEmitter` から継承:

```perl
# 内部的には各ログメソッドが emit を呼び出す
# $log->info('message') は内部で以下のように動作:
# $log->emit(message => 'info', 'message');
```

#### 実際のイベント駆動コード例

```perl
use Mojo::Log;

my $log = Mojo::Log->new;

# 複数のイベントリスナーを登録できる
$log->on(message => sub {
    my ($log, $level, @lines) = @_;
    # ファイルに書き込み
    print STDERR "[$level] ", join(' ', @lines), "\n";
});

$log->on(message => sub {
    my ($log, $level, @lines) = @_;
    # エラー以上なら特別な処理
    if ($level eq 'error' || $level eq 'fatal') {
        # アラート送信など
        warn "ALERT: ", join(' ', @lines);
    }
});

$log->info('通常のログ');
$log->error('エラーが発生しました');
```

---

### 3. イベント駆動プログラミングの基礎概念

#### イベント駆動プログラミングとは何か

- 「何かが起きたときに、それに応じて処理を実行する」設計思想
- ユーザーの操作、データの更新、センサー信号などの「イベント」を検知して動く
- GUIアプリ、Webサービス、IoTなど幅広く使われる

**特徴:**
- 非同期処理がしやすい
- 部品同士の結合度が低く、柔軟に設計できる
- 拡張や変更に強い

**従来の同期処理との違い:**

```perl
# 同期処理（逐次実行）
sub process_all {
    my $result1 = process_step1();
    my $result2 = process_step2();  # step1完了後に実行
    my $result3 = process_step3();  # step2完了後に実行
    return $result3;
}

# イベント駆動（イベントに応じて実行）
$emitter->on(step1_done => sub { process_step2() });
$emitter->on(step2_done => sub { process_step3() });
$emitter->emit('step1_done');  # イベント発火
```

#### Observerパターン（Pub/Subパターン）との関係

**Observerパターン:**
- 1つの「Subject」（監視対象）が複数の「Observer」（監視者）を持つ
- Subjectに変化があるとObserver全員に通知
- Mojo::EventEmitter はこのパターンを実装

```perl
# Mojo::EventEmitter = Observer パターンの実装
package Cat;
use Mojo::Base 'Mojo::EventEmitter';

sub poke {
    my $self = shift;
    $self->emit(roar => 3);  # イベント発行（Subject → Observer への通知）
}

# 使用例
my $tiger = Cat->new;
$tiger->on(roar => sub {        # Observer を登録
    my ($tiger, $times) = @_;
    say 'RAWR!' for 1 .. $times;
});
$tiger->poke;  # Subject が変化 → Observer に通知
```

**Pub/Subパターン:**
- Publisher（発行者）と Subscriber（購読者）が直接関与しない
- 間に「ブローカー/イベントバス」が入る
- より疎結合で、分散システムに適している

**比較:**

| 項目 | Observer | Pub/Sub |
|------|----------|---------|
| 結合度 | やや強い | 弱い（仲介あり） |
| スコープ | 同一プロセス内 | 複数システム、分散環境 |
| 通知方法 | 同期・直接呼び出し | 非同期・イベントバス経由 |

Mojo::EventEmitter は **Observer パターン** の実装であり、同一プロセス内でのイベント通知に適している。

#### イベントループとの違い

**イベント駆動プログラミング:**
- 設計スタイル・考え方
- 「イベントが来たら動く」「普段は待つ」

**イベントループ:**
- イベント駆動プログラミングを実現するための仕組み（技術）
- 「イベントキューを監視し、処理すべきイベントがあれば対応する」ループ構造

```
[発生したイベント] → [イベントキュー] → [イベントループ] → [イベントハンドラ]
```

**Perlでの例:**
- `Mojo::IOLoop` - Mojolicious のイベントループ
- `IO::Async::Loop` - IO::Async のイベントループ

**Mojo::Log との関係:**
- Mojo::Log 自体はイベントループを必要としない
- イベント発火（emit）は同期的に処理される
- イベントループと組み合わせることで非同期処理も可能

---

### 4. Mojo::EventEmitter との関係

#### Mojo::EventEmitter の役割

- イベント発行・購読を簡単に扱える基底クラス
- 複数のイベントリスナー（callback）を登録可能
- 任意のイベントを自由に発行＆購読できる

#### Mojo::Log が継承している機能

Mojo::Log は Mojo::EventEmitter を継承:

```perl
package Mojo::Log;
use Mojo::Base 'Mojo::EventEmitter';
```

これにより以下のメソッドが使える:
- `emit('event', @args)` - イベント発行
- `on('event' => sub {...})` - イベントリスナー追加
- `once('event' => sub {...})` - 一度だけ実行されるリスナー
- `has_subscribers('event')` - 購読者の有無確認
- `subscribers('event')` - 購読者リスト取得
- `unsubscribe('event')` - 購読解除

#### 他のMojo::*モジュールでのイベント駆動例

**Mojo::IOLoop:**
```perl
use Mojo::IOLoop;

# タイマーイベント
Mojo::IOLoop->timer(3 => sub { say '3秒後に実行' });

# 繰り返しタイマー
Mojo::IOLoop->recurring(1 => sub { say '1秒ごとに実行' });

Mojo::IOLoop->start;
```

**Mojo::UserAgent:**
```perl
use Mojo::UserAgent;

my $ua = Mojo::UserAgent->new;

# トランザクションイベント
$ua->on(start => sub {
    my ($ua, $tx) = @_;
    say 'リクエスト開始: ', $tx->req->url;
});

$ua->get('https://example.com');
```

**Mojo::Transaction:**
```perl
# finish イベント
$tx->on(finish => sub {
    my $tx = shift;
    say 'トランザクション完了';
});
```

---

### 5. 実用例・ユースケース

#### ログのカスタマイズ（フォーマット変更）

```perl
use Mojo::Log;

my $log = Mojo::Log->new;

# カスタムフォーマット
$log->format(sub {
    my ($time, $level, @lines) = @_;
    my $timestamp = localtime($time);
    return "[$timestamp][$level] " . join(' ', @lines) . "\n";
});

$log->info('カスタムフォーマットでログ出力');
# 出力: [Sun Dec 29 15:30:00 2025][info] カスタムフォーマットでログ出力
```

**JSON形式のログ:**

```perl
use Mojo::JSON qw(encode_json);

$log->format(sub {
    my ($time, $level, @lines) = @_;
    return encode_json({
        timestamp => $time,
        level     => $level,
        message   => join(' ', @lines),
    }) . "\n";
});
```

#### 複数のログ出力先への同時配信

```perl
use Mojo::Log;

my $log = Mojo::Log->new;

# ファイルハンドルを開く
open my $fh, '>>', '/var/log/app.log' or die $!;

# 複数の出力先にログを送る
$log->on(message => sub {
    my ($log, $level, @lines) = @_;
    my $msg = "[$level] " . join(' ', @lines) . "\n";
    
    # 標準エラー出力へ
    print STDERR $msg;
    
    # ファイルへ
    print $fh $msg;
    $fh->flush;
});

$log->info('両方に出力されます');
```

#### エラー時の通知システム

```perl
use Mojo::Log;
use Mojo::UserAgent;

my $log = Mojo::Log->new;
my $ua  = Mojo::UserAgent->new;
my $slack_webhook = $ENV{SLACK_WEBHOOK_URL};

# エラー以上のレベルでSlack通知
$log->on(message => sub {
    my ($log, $level, @lines) = @_;
    
    # error または fatal の場合のみ通知
    return unless $level eq 'error' || $level eq 'fatal';
    
    my $text = "[$level] " . join(' ', @lines);
    
    # Slack Webhook に POST
    $ua->post($slack_webhook => json => {
        text => ":warning: *$level* \n$text",
    });
});

$log->error('データベース接続エラー');  # Slack に通知される
$log->info('通常のログ');                # Slack には通知されない
```

#### ログレベルによる出力先の振り分け

```perl
use Mojo::Log;

my $log = Mojo::Log->new;

$log->on(message => sub {
    my ($log, $level, @lines) = @_;
    my $msg = join(' ', @lines);
    
    if ($level eq 'info' || $level eq 'debug' || $level eq 'trace') {
        # 通常のログは STDOUT へ
        say $msg;
    } else {
        # warn/error/fatal は STDERR へ
        warn $msg;
    }
});
```

---

### 6. 関連記事・内部リンク調査

#### このリポジトリ内の関連記事

以下のタグを持つ記事が関連性が高い:

- **perl**: 多数の記事あり
- **mojo-ioloop**: 非同期処理・イベントループ関連
- **async**: 非同期処理関連

**特に関連性の高い記事:**

1. **Mojolicious入門 — Mojolicious::Liteで始めるPerlのWeb開発** (2025/12/04)
   - タグ: perl, Mojolicious, Web, Tutorial
   - Mojoliciousフレームワークの入門記事

2. **Perlでの非同期処理 — IO::Async と Mojo::IOLoop** (2025/12/17)
   - タグ: perl, async, io-async, mojo-ioloop, non-blocking
   - イベントループとイベント駆動の関係を理解するのに役立つ

3. **PerlでのWebスクレイピング - Web::Scraper と Mojo::UserAgent** (2025/12/22)
   - タグ: perl, web-scraping, web-scraper, mojo-useragent, mojo-dom
   - Mojoliciousのツールキット使用例

#### 参照すべき外部リソース

**公式リソース:**
- Mojo::Log 公式ドキュメント: https://docs.mojolicious.org/Mojo/Log
- Mojo::EventEmitter 公式ドキュメント: https://docs.mojolicious.org/Mojo/EventEmitter
- Mojolicious チュートリアル: https://docs.mojolicious.org/Mojolicious/Guides/Tutorial

**日本語リソース:**
- Mojolicious日本語ドキュメント: https://mojodoc.perlzemi.com/
- Perl+Mojoでイベント駆動プログラミング (Qiita): https://qiita.com/skaji/items/c226f894581881796ed1

**概念理解に役立つリソース:**
- Observer pattern (Wikipedia): https://en.wikipedia.org/wiki/Observer_pattern
- イベント駆動型プログラミング (Wikipedia): https://ja.wikipedia.org/wiki/%E3%82%A4%E3%83%99%E3%83%B3%E3%83%88%E9%A7%86%E5%8B%95%E5%9E%8B%E3%83%97%E3%83%AD%E3%82%B0%E3%83%A9%E3%83%9F%E3%83%B3%E3%82%B0

---

## 次のステップ

1. **アウトライン作成依頼** (search-engine-optimizationエージェント)
   - 調査結果に基づいて記事のアウトライン案を3つ作成
   - 各案は異なる視点やアプローチを持つ

2. **記事作成** (perl-mongerエージェント)
   - 入門者向けのわかりやすいコード例を多用
   - Mojo::Log を題材にイベント駆動の概念を解説

3. **挿絵の追加** (illustration-craftspersonエージェント)
   - イベント駆動の仕組みを図解（Mermaid記法）
   - Observer パターンの図解

4. **校正・SEO** (各エージェント)
   - proofreaderエージェントによる校正
   - search-engine-optimizationエージェントによるSEO最適化

---

## 記事作成時の注意点

### 入門者向けのポイント

1. **イベント駆動の「なぜ」を先に説明**
   - 従来の逐次処理との違い
   - イベント駆動のメリット（疎結合、拡張性）

2. **Mojo::Log を題材にする理由**
   - シンプルで理解しやすい
   - 実用的なユースケースがある
   - Mojoliciousの他のモジュールへの橋渡し

3. **段階的な説明**
   - まず `on` と `emit` の基本
   - 次に `message` イベントの活用
   - 最後に実用例（複数出力、通知など）

4. **コード例は動作するものを**
   - コピー＆ペーストで動くコード
   - コメントで各行の意味を説明

### 推奨タグ

- perl
- mojolicious
- event-driven
- mojo-eventemitter
- mojo-log
