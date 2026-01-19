#!/usr/bin/env perl
use v5.36;
use Moo;

package WaitingState {
    use Moo;
    use v5.36;

    sub insert_coin ($self) {
        say "コインを受け付けました";
        return CoinInsertedState->new;
    }

    sub select_product ($self) {
        say "先にコインを入れてください";
        return $self;
    }

    sub dispense ($self) {
        say "払い出す商品がありません";
        return $self;
    }
}

package CoinInsertedState {
    use Moo;
    use v5.36;

    sub insert_coin ($self) {
        say "すでにコインが入っています";
        return $self;
    }

    sub select_product ($self) {
        say "商品を選択しました";
        # 簡略化のため、払い出し後は待機状態に戻る
        return WaitingState->new;
    }

    sub dispense ($self) {
        say "先に商品を選択してください";
        return $self;
    }
}

# 動作確認
say "=== 状態クラスのテスト ===";
say "";

my $state = WaitingState->new;

say "[操作] 商品を選択（待機中）";
$state = $state->select_product;
say "現在の状態: " . ref($state);
say "";

say "[操作] コインを投入";
$state = $state->insert_coin;
say "現在の状態: " . ref($state);
say "";

say "[操作] 商品を選択";
$state = $state->select_product;
say "現在の状態: " . ref($state);
