#!/usr/bin/env perl
use v5.34;
use warnings;
use feature 'signatures';
no warnings "experimental::signatures";

# モック用外部APIとDB（Beforeと同じ）
package External::PaymentAPI {
    use Moo;
    sub charge ($self, $amount) { print "[API] Charged $amount to credit card.\n"; return 1; }
    sub refund ($self, $amount) { print "[API] Refunded $amount to credit card.\n"; return 1; }
}

package Database {
    use Moo;
    sub begin_transaction ($self) { print "[DB] BEGIN TRANSACTION\n"; }
    sub commit ($self)            { print "[DB] COMMIT\n"; }
    sub rollback ($self)          { print "[DB] ROLLBACK\n"; }
    sub save_order ($self, $order) {
        die "DB Error: Could not save order!\n" if $order->{should_fail};
        print "[DB] Order saved.\n";
        return 1;
    }
}

# -----------------------------------
# 1. Command Role (約束事)
# -----------------------------------
package Command::Role {
    use Moo::Role;
    requires 'execute';
    requires 'unexecute'; # 取り消し用
}

# -----------------------------------
# 2. 具体的なCommandたち
# -----------------------------------
package Command::Payment {
    use Moo;
    with 'Command::Role';
    has api    => (is => 'ro', required => 1);
    has amount => (is => 'ro', required => 1);

    sub execute ($self) {
        $self->api->charge($self->amount);
    }
    sub unexecute ($self) {
        # 過去に行った処理を逆にたどる（返金）
        print "[UNDO] Reversing Payment...\n";
        $self->api->refund($self->amount);
    }
}

package Command::SaveOrder {
    use Moo;
    with 'Command::Role';
    has db    => (is => 'ro', required => 1);
    has order => (is => 'ro', required => 1);

    sub execute ($self) {
        $self->db->save_order($self->order);
    }
    sub unexecute ($self) {
        # ここではロールバックはトランザクションで代用するか、Deleteを呼ぶなど
        # 今回はDBのエラーで止まる想定なので、何もしない（あるいはログ）
        print "[UNDO] Command::SaveOrder unexecuted (handled by DB rollback)\n";
    }
}

# -----------------------------------
# 3. Invoker (履歴管理者)
# -----------------------------------
package OrderInvoker {
    use Moo;
    has history => (is => 'rw', default => sub { [] });

    sub execute_command ($self, $command) {
        $command->execute();
        push @{$self->history}, $command;
    }

    sub undo_all ($self) {
        while (my $cmd = pop @{$self->history}) {
            $cmd->unexecute();
        }
    }
}

# -----------------------------------
# 4. Context (利用側・メインロジック)
# -----------------------------------
package OrderProcessorSmart {
    use Moo;
    has api => (is => 'ro', default => sub { External::PaymentAPI->new });
    has db  => (is => 'ro', default => sub { Database->new });

    sub process_order ($self, $order) {
        my $invoker = OrderInvoker->new;
        $self->db->begin_transaction();

        eval {
            # 決済コマンドの発行
            $invoker->execute_command(
                Command::Payment->new(api => $self->api, amount => $order->{amount})
            );
            
            # 保存コマンドの発行
            $invoker->execute_command(
                Command::SaveOrder->new(db => $self->db, order => $order)
            );
        };
        if ($@) {
            print "[SYSTEM] Error occurred. Starting compensation process (Undo)...\n";
            $self->db->rollback();
            $invoker->undo_all(); # APIの返金などがここで行われる
            die "Order processing failed: $@";
        }

        $self->db->commit();
        return 1;
    }
}

1;
