#!/usr/bin/env perl
# 第8回 コード例2: SendCommand, DeleteCommand - Commandパターンの実装
use v5.36;
use Moo;
use namespace::clean;

package Command::Role {
    use Moo::Role;
    use namespace::clean;
    requires 'execute';
    requires 'undo';
    has 'executed' => (is => 'rw', default => 0);
}

package Message {
    use Moo;
    use namespace::clean;
    has 'sender'    => (is => 'ro', required => 1);
    has 'recipient' => (is => 'ro', required => 1);
    has 'body'      => (is => 'ro', required => 1);
    has 'timestamp' => (is => 'ro', default  => sub {time});
}

package MessageBox {
    use Moo;
    use namespace::clean;
    has 'owner'    => (is => 'ro', required => 1);
    has 'messages' => (is => 'rw', default  => sub { [] });

    sub add($self, $msg)             { push $self->messages->@*, $msg }
    sub remove_last($self)           { pop $self->messages->@* }
    sub remove_at($self, $idx)       { splice $self->messages->@*, $idx, 1 }
    sub insert_at($self, $idx, $msg) { splice $self->messages->@*, $idx, 0, $msg }
    sub count($self)                 { scalar $self->messages->@* }
    sub get_all($self)               { $self->messages->@* }
}

# 送信コマンド
package SendCommand {
    use Moo;
    with 'Command::Role';
    use namespace::clean;

    has 'box'     => (is => 'ro', required => 1);
    has 'message' => (is => 'ro', required => 1);

    sub execute($self) {
        $self->box->add($self->message);
    }

    sub undo($self) {
        $self->box->remove_last;
    }
}

# 削除コマンド
package DeleteCommand {
    use Moo;
    with 'Command::Role';
    use namespace::clean;

    has 'box'         => (is => 'ro', required => 1);
    has 'index'       => (is => 'ro', required => 1);
    has 'deleted_msg' => (is => 'rw');    # Undo用に保存

    sub execute($self) {
        my ($msg) = $self->box->remove_at($self->index);
        $self->deleted_msg($msg);
    }

    sub undo($self) {
        $self->box->insert_at($self->index, $self->deleted_msg);
    }
}

# コマンド履歴マネージャー
package CommandHistory {
    use Moo;
    use namespace::clean;

    has 'history' => (is => 'rw', default => sub { [] });

    sub execute($self, $command) {
        $command->execute;
        push $self->history->@*, $command;
    }

    sub undo($self) {
        return unless $self->history->@*;
        my $command = pop $self->history->@*;
        $command->undo;
        return $command;
    }

    sub can_undo($self) {
        return scalar $self->history->@* > 0;
    }
}

# デモ
sub demo {
    say "=== 第8回: Commandパターン導入 ===\n";

    my $box     = MessageBox->new(owner => 'Bob');
    my $history = CommandHistory->new;

    # コマンドで操作
    $history->execute(
        SendCommand->new(
            box     => $box,
            message => Message->new(sender => 'Alice', recipient => 'Bob', body => 'Hello!')
        )
    );
    $history->execute(
        SendCommand->new(
            box     => $box,
            message => Message->new(sender => 'Charlie', recipient => 'Bob', body => 'Hi!')
        )
    );
    say "送信後: ", $box->count, "件";

    $history->execute(DeleteCommand->new(box => $box, index => 0));
    say "削除後: ", $box->count, "件";

    $history->undo;
    say "Undo後: ", $box->count, "件";

    $history->undo;
    say "もう一度Undo: ", $box->count, "件";

    say "\n改善点:";
    say "- 各操作がCommandオブジェクトとして独立";
    say "- Undo/Redoが簡単に実装可能";
    say "- 新しい操作の追加が容易";
    say "- テストが容易";
}

demo() unless caller;

1;
