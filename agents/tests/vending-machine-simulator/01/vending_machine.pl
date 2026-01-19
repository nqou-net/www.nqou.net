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
