#!/usr/bin/env perl
# 第6回 コード例2: NotificationObserver - 通知を受け取るObserver実装
use v5.36;
use Moo;
use namespace::clean;

# Subject::Role とObserver::Role を定義
package Subject::Role {
    use Moo::Role;
    use namespace::clean;
    has 'observers' => (is => 'rw', default => sub { [] });
    sub attach($self, $o) { push $self->observers->@*, $o }

    sub detach($self, $o) {
        $self->observers([grep { $_ != $o } $self->observers->@*]);
    }
    sub notify($self, $event, @args) { $_->update($self, $event, @args) for $self->observers->@* }
}

package Observer::Role {
    use Moo::Role;
    use namespace::clean;
    requires 'update';
}

# Message
package Message {
    use Moo;
    use namespace::clean;
    has 'sender'    => (is => 'ro', required => 1);
    has 'recipient' => (is => 'ro', required => 1);
    has 'body'      => (is => 'ro', required => 1);
    has 'timestamp' => (is => 'ro', default  => sub {time});
}

# Observer機能付きMessageBox
package ObservableMessageBox {
    use Moo;
    with 'Subject::Role';
    use namespace::clean;

    has 'owner'    => (is => 'ro', required => 1);
    has 'messages' => (is => 'rw', default  => sub { [] });

    sub receive($self, $msg) {
        push $self->messages->@*, $msg;
        $self->notify('new_message', $msg);    # 通知を発火！
    }

    sub count($self)   { scalar $self->messages->@* }
    sub get_all($self) { $self->messages->@* }
}

# コンソール通知Observer
package ConsoleNotifier {
    use Moo;
    with 'Observer::Role';
    use namespace::clean;

    has 'name' => (is => 'ro', default => 'Notifier');

    sub update($self, $subject, $event, @args) {
        if ($event eq 'new_message') {
            my ($msg) = @args;
            say "[", $self->name, "] 新着メッセージ: ", $msg->sender, " -> ", $msg->body;
        }
    }
}

# ログ記録Observer
package LogObserver {
    use Moo;
    with 'Observer::Role';
    use namespace::clean;

    has 'log' => (is => 'rw', default => sub { [] });

    sub update($self, $subject, $event, @args) {
        push $self->log->@*, {time => time, event => $event, args => \@args};
    }

    sub get_log($self) { $self->log->@* }
}

# デモ
sub demo {
    say "=== 第6回: Observerパターン導入 ===\n";

    my $box = ObservableMessageBox->new(owner => 'Bob');

    # Observerを登録
    my $console = ConsoleNotifier->new(name => 'Desktop');
    my $logger  = LogObserver->new;

    $box->attach($console);
    $box->attach($logger);

    say "メッセージ送信:";
    $box->receive(Message->new(sender => 'Alice',   recipient => 'Bob', body => 'Hello!'));
    $box->receive(Message->new(sender => 'Charlie', recipient => 'Bob', body => 'Hi there!'));

    say "\nログを確認: ", scalar($logger->get_log), " 件のイベント記録";

    say "\n改善点:";
    say "- ポーリング不要 → メッセージ到着時に即通知";
    say "- 複数のObserverを登録可能";
    say "- MessageBoxはObserverの詳細を知らない（疎結合）";
}

demo() unless caller;

1;
