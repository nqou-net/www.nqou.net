---
title: "IO::Async 調査メモ"
date: 2025-12-19
tags:
  - perl
  - io-async
  - asynchronous-io
  - event-driven
description: "Perl用の非同期I/Oライブラリ IO::Async に関する調査・技術情報のメモ"
---

# IO::Async 調査メモ

## 概要
IO::Async は Perl 用の非同期 I/O ライブラリで、イベントループ（リアクタ）とそれを構成する再利用可能なコンポーネント群を提供します。高レベルな抽象（ストリーム、リスナー、タイマー、プロセスラッパーなど）と、Future ベースの制御フローを組み合わせて書ける点が特徴です。

目的:
- 非ブロッキング I/O を簡潔に扱うための共通インターフェースを提供
- 小さなコンポーネントを組み合わせて複雑な非同期処理を構築
- CPAN エコシステムと連携しやすい設計

インストール例:
```
cpanm IO::Async
# もしくは
cpan IO::Async
```
IO::Async は多くのサブモジュールを含むため、必要に応じて個別にインストールされることもあります。

## 設計と主要概念
- Loop（`IO::Async::Loop`）: イベントループ本体。タイマー、シグナル、ソケットなどの監視を行う。基本はループにコンポーネントを `add` して `run` で実行。
- Component（コンポーネント）: ループに追加できる単位（Listener, Stream, Timer 等）。コンポーネントはライフサイクル制御用のメソッドを持ち、必要に応じて開始・停止できる。
- Stream（`IO::Async::Stream`）: ソケットやファイルディスクリプタに対する非同期の読み書きを扱う。データ受信時のコールバックや書き込みキューを持つ。
- Listener（`IO::Async::Listener`）: サーバーソケットの受け入れを抽象化。接続ごとに Stream を作るパターンが多い。
- Timer（`IO::Async::Timer::Periodic` 等）: 一回または周期的なタイマー処理。
- Future（`Future` モジュール）: 非同期処理の結果を表すプロミス風オブジェクト。IO::Async は Future ベースで連結（then）や待機が可能。
- Process / Child（`IO::Async::Process` など）: 子プロセス管理（入出力の非同期ハンドリングを含む）。

設計上のポイント:
- 明示的にループへコンポーネントを追加して制御する「明示的リアクタ」スタイル
- Future によるエラーハンドリングとチェインが容易
- 小さなコンポーネントを合成して複雑な処理を作る

## 基本的な使い方（抜粋）
- シンプルなループ + タイマー
```perl
use IO::Async::Loop;
use IO::Async::Timer::Periodic;

my $loop = IO::Async::Loop->new;
my $timer = IO::Async::Timer::Periodic->new(
  interval => 1,
  on_tick => sub { print "tick\n" },
);
$loop->add($timer);
$timer->start;
$loop->run;
```

- TCP エコーサーバ（概念例）
```perl
use IO::Async::Loop;
use IO::Async::Listener;
use IO::Async::Stream;
use IO::Socket::INET;

my $loop = IO::Async::Loop->new;
my $listener = IO::Async::Listener->new(
  on_stream => sub {
    my ($listener, $stream) = @_;
    $stream->configure(
      on_read => sub {
        my ($stream, $buffref) = @_;
        $stream->write($$buffref); # 受け取ったデータをそのまま返す
        $$buffref = undef;
        return 0;
      }
    );
  }
);
$listener->listen(handle => IO::Socket::INET->new(Listen => 5, LocalPort => 12345));
$loop->add($listener);
$loop->run;
```
（実際にはエラーチェックや終了処理を追加する）

- Future を使った非同期フローの例
```perl
use Future;
# 何らかの Future を返す関数 chain
async_operation()->then(sub {
  my $result = shift;
  return another_async($result);
})->on_done(sub { print "done\n" })->on_fail(sub { warn shift });
```

## 実用パターンと注意点
- 長時間ブロッキングする処理（CPU 集中型）は別スレッドまたは子プロセスに切り離す。IO::Async は I/O のための設計であり、同期的な重い処理はループを阻害する。
- バッファ管理と backpressure（書き込みキューが溜まる状況）に注意。`IO::Async::Stream` は書き込みキューを持つため、キューサイズ管理や遅延書き込みに配慮する。
- エラー処理は Future の `on_fail` で集中管理すると扱いやすい。
- グレースフルシャットダウン: ループ上のコンポーネントを順に停止してから `exit` するのが安全。

## 周辺エコシステムと代替
- AnyEvent: Perl で広く使われるイベントループ抽象。バックエンド（EV, Event, IO::Poll 等）を切り替えられるのが特徴。IO::Async はより高レベルなコンポーネント設計に傾く。
- Future: IO::Async は `Future` モジュールと相性が良く、Future を用いた制御フローが標準的。
- Coro / AnyEvent::AIO 等: 協調的なコルーチンスタイルを使いたい場合の選択肢。

比較の観点:
- 学習曲線: IO::Async はコンポーネント設計を理解する必要がありやや学習コストがあるが、慣れると可読性の高い非同期プログラムが書ける。
- エコシステム: AnyEvent はより多くのバックエンドと互換性があるが、IO::Async は統一された API で構成しやすい。

## デバッグとプロファイリング
- ログ出力を増やしてコンポーネントのライフサイクルを追う。
- 長時間動作するタスクは外部プロセスに切り出し、プロセスレベルで監視する。
- Future の `on_fail` でスタックトレースやエラー情報を集中してログに出す。

## 参考リンク
- CPAN: https://metacpan.org/pod/IO::Async
- GitHub / ソース（リポジトリがあれば）: 検索して最新版の README を参照
- Future モジュール: https://metacpan.org/pod/Future
- AnyEvent（比較参考）: https://metacpan.org/pod/AnyEvent

---

## 追加メモ（実運用で検討する点）
- TLS 対応: `IO::Async::TLS` のようなモジュール（存在する場合）を検討。あるいは `IO::Socket::SSL` と組み合わせる方法。
- 高負荷: 接続数やレイテンシの要件に応じてバックエンドや OS レベルのチューニングを行う。
- テスト: 非同期コードはモックやタイムアウト付きテストを準備して回帰を防ぐ。

---

作成日: 2025-12-19
作成者: エージェント（調査メモ）
