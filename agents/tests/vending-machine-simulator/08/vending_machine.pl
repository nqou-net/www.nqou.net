#!/usr/bin/env perl
use v5.36;
use Moo;

package VendingMachineState {
    use Moo::Role;

    requires 'insert_coin';
    requires 'select_product';
    requires 'dispense';
}

package WaitingState {
    use Moo;
    use v5.36;

    with 'VendingMachineState';

    sub insert_coin ($self, $context) {
        say "コインを受け付けました";
        $context->set_state(CoinInsertedState->new);
    }

    sub select_product ($self, $context) {
        say "先にコインを入れてください";
    }

    sub dispense ($self, $context) {
        say "払い出す商品がありません";
    }
}

package CoinInsertedState {
    use Moo;
    use v5.36;

    with 'VendingMachineState';

    sub insert_coin ($self, $context) {
        say "すでにコインが入っています";
    }

    sub select_product ($self, $context) {
        if ($context->stock > 0) {
            say "商品を選択しました。払い出しを開始します";
            $context->set_state(DispensingState->new);
        }
        else {
            say "申し訳ありません。売り切れです";
            say "コインを返却します";
            $context->set_state(SoldOutState->new);
        }
    }

    sub dispense ($self, $context) {
        say "先に商品を選択してください";
    }
}

package DispensingState {
    use Moo;
    use v5.36;

    with 'VendingMachineState';

    sub insert_coin ($self, $context) {
        say "払い出し中です。お待ちください";
    }

    sub select_product ($self, $context) {
        say "払い出し中です。お待ちください";
    }

    sub dispense ($self, $context) {
        say "商品を払い出しました";
        $context->stock($context->stock - 1);
        say "残り在庫: " . $context->stock . "個";

        if ($context->stock > 0) {
            $context->set_state(WaitingState->new);
        }
        else {
            say "在庫がなくなりました";
            $context->set_state(SoldOutState->new);
        }
    }
}

package SoldOutState {
    use Moo;
    use v5.36;

    with 'VendingMachineState';

    sub insert_coin ($self, $context) {
        say "売り切れです。コインを受け付けられません";
    }

    sub select_product ($self, $context) {
        say "売り切れです";
    }

    sub dispense ($self, $context) {
        say "売り切れです。払い出せません";
    }
}

package VendingMachine {
    use Moo;
    use v5.36;

    has state => (
        is      => 'rw',
        default => sub { WaitingState->new },
        isa    => sub { # 型チェック追加
            my $value = shift;
            die "state must do VendingMachineState role"
                unless $value->does('VendingMachineState');
        },
    );

    has stock => (
        is      => 'rw',
        default => sub { 5 },
    );

    sub set_state ($self, $new_state) {
        $self->state($new_state);
    }

    sub insert_coin ($self) {
        $self->state->insert_coin($self);
    }

    sub select_product ($self) {
        $self->state->select_product($self);
    }

    sub dispense ($self) {
        $self->state->dispense($self);
    }

    sub current_state_name ($self) {
        return ref($self->state);
    }
}

# 動作確認
say "=== 自動販売機シミュレーター（売り切れ対応版）===";
say "";

my $vm = VendingMachine->new(stock => 2);
say "初期在庫: " . $vm->stock . "個";
say "";

for my $i (1..3) {
    say "--- 購入 $i 回目 ---";
    say "[操作] コインを投入";
    $vm->insert_coin;
    say "[操作] 商品を選択";
    $vm->select_product;
    say "[操作] 払い出し";
    $vm->dispense;
    say "現在の状態: " . $vm->current_state_name;
    say "";
}
