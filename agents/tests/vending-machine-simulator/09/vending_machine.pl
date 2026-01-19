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
        my $name = ref($self->state);
        my %ja_names = (
            WaitingState      => '待機中',
            CoinInsertedState => 'コイン投入済み',
            DispensingState   => '払い出し中',
            SoldOutState      => '売り切れ',
        );
        return $ja_names{$name} // $name;
    }
}

# 対話的CLI
sub run_cli ($vm) {
    say "=== 自動販売機シミュレーター ===";
    say "コマンド: c(コイン投入), s(商品選択), d(払い出し), q(終了)";
    say "";

    while (1) {
        print "現在の状態: " . $vm->current_state_name;
        print " / 在庫: " . $vm->stock . "個";
        print "\n> ";

        my $input = <STDIN>;
        last unless defined $input;
        chomp $input;

        if ($input eq 'c') {
            $vm->insert_coin;
        }
        elsif ($input eq 's') {
            $vm->select_product;
        }
        elsif ($input eq 'd') {
            $vm->dispense;
        }
        elsif ($input eq 'q') {
            say "終了します";
            last;
        }
        elsif ($input eq '') {
            next;
        }
        else {
            say "不明なコマンドです: $input";
        }
        say "";
    }
}

# メイン
my $vm = VendingMachine->new(stock => 3);
run_cli($vm);
