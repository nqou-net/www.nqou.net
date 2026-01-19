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

    with 'VendingMachineState';

    sub insert_coin ($self) {
        say "すでにコインが入っています";
        return $self;
    }

    sub select_product ($self) {
        say "商品を選択しました。払い出しを開始します";
        return DispensingState->new;
    }

    sub dispense ($self) {
        say "先に商品を選択してください";
        return $self;
    }
}

package DispensingState {
    use Moo;
    use v5.36;

    with 'VendingMachineState';

    sub insert_coin ($self) {
        say "払い出し中です。お待ちください";
        return $self;
    }

    sub select_product ($self) {
        say "払い出し中です。お待ちください";
        return $self;
    }

    sub dispense ($self) {
        say "商品を払い出しました";
        return WaitingState->new;
    }
}

package VendingMachine {
    use Moo;
    use v5.36;

    has state => (
        is      => 'rw',
        default => sub { WaitingState->new },
    );

    has stock => (
        is      => 'rw',
        default => sub { 5 },
    );

    sub insert_coin ($self) {
        my $next_state = $self->state->insert_coin;
        $self->state($next_state);
    }

    sub select_product ($self) {
        my $next_state = $self->state->select_product;
        $self->state($next_state);
    }

    sub dispense ($self) {
        my $next_state = $self->state->dispense;
        $self->state($next_state);
    }

    sub current_state_name ($self) {
        return ref($self->state);
    }
}

# 動作確認
say "=== 自動販売機シミュレーター ===";
say "";

my $vm = VendingMachine->new;

say "初期状態: " . $vm->current_state_name;
say "";

say "[操作] 商品を選択（コインなし）";
$vm->select_product;
say "現在の状態: " . $vm->current_state_name;
say "";

say "[操作] コインを投入";
$vm->insert_coin;
say "現在の状態: " . $vm->current_state_name;
say "";

say "[操作] 商品を選択";
$vm->select_product;
say "現在の状態: " . $vm->current_state_name;
say "";

say "[操作] 払い出し";
$vm->dispense;
say "現在の状態: " . $vm->current_state_name;
