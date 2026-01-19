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
        elsif ($self->state eq 'dispensing') {
            say "払い出し中です。お待ちください";
        }
        elsif ($self->state eq 'sold_out') {
            say "売り切れです。コインを受け付けられません";
        }
    }

    sub select_product ($self) {
        if ($self->state eq 'waiting') {
            say "先にコインを入れてください";
        }
        elsif ($self->state eq 'coin_inserted') {
            if ($self->stock > 0) {
                say "商品を選択しました。払い出しを開始します";
                $self->state('dispensing');
            }
            else {
                say "申し訳ありません。売り切れです";
                say "コインを返却します";
                $self->state('sold_out');
            }
        }
        elsif ($self->state eq 'dispensing') {
            say "払い出し中です。お待ちください";
        }
        elsif ($self->state eq 'sold_out') {
            say "売り切れです";
        }
    }

    sub dispense ($self) {
        if ($self->state eq 'waiting') {
            say "払い出す商品がありません";
        }
        elsif ($self->state eq 'coin_inserted') {
            say "先に商品を選択してください";
        }
        elsif ($self->state eq 'dispensing') {
            say "商品を払い出しました";
            $self->stock($self->stock - 1);
            say "残り在庫: " . $self->stock . "個";
            if ($self->stock > 0) {
                $self->state('waiting');
            }
            else {
                say "在庫がなくなりました";
                $self->state('sold_out');
            }
        }
        elsif ($self->state eq 'sold_out') {
            say "売り切れです。払い出せません";
        }
    }
}

# 動作確認
my $vm = VendingMachine->new(stock => 2);

say "=== 自動販売機シミュレーター（在庫2個）===";
say "";

# 1回目の購入
say "[操作] コインを投入";
$vm->insert_coin;
say "[操作] 商品を選択";
$vm->select_product;
say "[操作] 払い出し";
$vm->dispense;
say "";

# 2回目の購入
say "[操作] コインを投入";
$vm->insert_coin;
say "[操作] 商品を選択";
$vm->select_product;
say "[操作] 払い出し";
$vm->dispense;
say "";

# 売り切れ後
say "[操作] コインを投入";
$vm->insert_coin;
