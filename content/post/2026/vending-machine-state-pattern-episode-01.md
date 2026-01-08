---
title: '第1回-自動販売機の状態をif/elseで管理しよう - Mooを使って自動販売機シミュレーターを作ってみよう'
description: 自動販売機の動作をPerlで再現！「待機中」「コイン投入済み」をif/elseで切り替える状態管理の基礎を学びます。Mooで始めるオブジェクト指向プログラミング入門。
iso8601: 2026-01-09T23:58:23+09:00
draft: true
tags:
  - perl
  - moo
  - vending-machine
  - state-management
  - if-else
---

[@nqounet](https://x.com/nqounet)です。

新シリーズ「Mooを使って自動販売機シミュレーターを作ってみよう」を始めます！

このシリーズでは、自動販売機の動作をPerlでシミュレートしながら、オブジェクト指向プログラミングの考え方を深く学んでいきます。

## このシリーズの前提知識

このシリーズは「Mooで覚えるオブジェクト指向プログラミング」シリーズの続編です。以下の知識があることを前提としています。

- `has`と`sub`でクラスを定義できる
- `new`でオブジェクトを生成できる
- `Moo::Role`と`with`でロールを使える
- 委譲（`handles`）の概念を理解している

まだこれらに不安がある方は、先に「Mooで覚えるオブジェクト指向プログラミング」シリーズを読んでみてください。

## 自動販売機の動作を考えよう

自動販売機は、私たちが日常的に使っている身近な機械です。その動作を思い出してみましょう。

1. **待機中**: コインが投入されるのを待っている
2. **コイン投入済み**: コインが入っていて、商品を選べる状態
3. 商品を選ぶと払い出される

この「状態」によって、同じ操作でも結果が変わります。

- 待機中に商品ボタンを押しても、何も起きない
- コインを入れてから商品ボタンを押すと、商品が出てくる

今回は、この状態管理をプログラムで表現してみましょう。

## if/elseで状態を管理する

まずは素朴に、if/elseを使って状態を管理してみます。

今回作る自動販売機の仕様は以下の通りです。

- 状態は「待機中（waiting）」と「コイン投入済み（coin_inserted）」の2つ
- 操作は「コイン投入（insert_coin）」と「商品選択（select_product）」の2つ
- 商品は1種類で価格は100円
- 在庫は5個

```perl
#!/usr/bin/env perl
use v5.36;
use Moo;

package VendingMachine {
    use Moo;

    has state => (
        is      => 'rw',
        default => sub { 'waiting' },
    );

    has stock => (
        is      => 'rw',
        default => sub { 5 },
    );

    sub insert_coin ($self) {
        if ($self->state eq 'waiting') {
            say "コインを受け付けました";
            $self->state('coin_inserted');
        }
        elsif ($self->state eq 'coin_inserted') {
            say "すでにコインが入っています";
        }
    }

    sub select_product ($self) {
        if ($self->state eq 'waiting') {
            say "先にコインを入れてください";
        }
        elsif ($self->state eq 'coin_inserted') {
            say "商品を払い出します";
            $self->stock($self->stock - 1);
            say "残り在庫: " . $self->stock . "個";
            $self->state('waiting');
        }
    }
}

# 動作確認
my $vm = VendingMachine->new;

say "=== 自動販売機シミュレーター ===";
say "";

say "[操作] 商品を選択（コインなし）";
$vm->select_product;
say "";

say "[操作] コインを投入";
$vm->insert_coin;
say "";

say "[操作] 商品を選択";
$vm->select_product;
say "";

say "[操作] コインを投入";
$vm->insert_coin;
say "";

say "[操作] 商品を選択";
$vm->select_product;
```

## 実行してみよう

このスクリプトを`vending_machine.pl`として保存し、実行してみましょう。

```shell
perl vending_machine.pl
```

出力結果：

```
=== 自動販売機シミュレーター ===

[操作] 商品を選択（コインなし）
先にコインを入れてください

[操作] コインを投入
コインを受け付けました

[操作] 商品を選択
商品を払い出します
残り在庫: 4個

[操作] コインを投入
コインを受け付けました

[操作] 商品を選択
商品を払い出します
残り在庫: 3個
```

状態に応じて、適切なメッセージが表示されていますね。

## 今回のポイント

今回は、if/elseを使って自動販売機の2つの状態を管理しました。

- **状態**: `state`属性で現在の状態を保持
- **状態に応じた分岐**: if/elseで状態をチェックして処理を変える
- **状態遷移**: 処理の結果として`$self->state()`で状態を変更

この方法はシンプルでわかりやすいですね。

しかし、実際の自動販売機にはもっと多くの状態があります。「払い出し中」「売り切れ」といった状態も必要です。

状態が増えたとき、このコードはどうなるでしょうか？

## 今回の完成コード

```perl
#!/usr/bin/env perl
use v5.36;
use Moo;

package VendingMachine {
    use Moo;

    has state => (
        is      => 'rw',
        default => sub { 'waiting' },
    );

    has stock => (
        is      => 'rw',
        default => sub { 5 },
    );

    sub insert_coin ($self) {
        if ($self->state eq 'waiting') {
            say "コインを受け付けました";
            $self->state('coin_inserted');
        }
        elsif ($self->state eq 'coin_inserted') {
            say "すでにコインが入っています";
        }
    }

    sub select_product ($self) {
        if ($self->state eq 'waiting') {
            say "先にコインを入れてください";
        }
        elsif ($self->state eq 'coin_inserted') {
            say "商品を払い出します";
            $self->stock($self->stock - 1);
            say "残り在庫: " . $self->stock . "個";
            $self->state('waiting');
        }
    }
}

# 動作確認
my $vm = VendingMachine->new;

say "=== 自動販売機シミュレーター ===";
say "";

say "[操作] 商品を選択（コインなし）";
$vm->select_product;
say "";

say "[操作] コインを投入";
$vm->insert_coin;
say "";

say "[操作] 商品を選択";
$vm->select_product;
say "";

say "[操作] コインを投入";
$vm->insert_coin;
say "";

say "[操作] 商品を選択";
$vm->select_product;
```

## まとめ

- 自動販売機の「待機中」「コイン投入済み」という2つの状態をif/elseで管理しました
- 状態に応じて`insert_coin`と`select_product`の振る舞いが変わることを確認しました
- `state`属性を使って現在の状態を追跡しました

次回「第2回-状態を増やすと大変！条件分岐の悩み」では、状態を増やしたときにコードがどうなるか見ていきます。お楽しみに！
