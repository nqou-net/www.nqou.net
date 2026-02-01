#!/usr/bin/env perl
# 第1回 コード例2: MessageBoxクラス - メッセージを格納・取得するメールボックス
use v5.36;
use Moo;
use namespace::clean;

package Message {
    use Moo;
    use namespace::clean;

    has 'sender'    => (is => 'ro', required => 1);
    has 'recipient' => (is => 'ro', required => 1);
    has 'body'      => (is => 'ro', required => 1);
    has 'timestamp' => (is => 'ro', default  => sub {time});

    sub format($self) {
        return sprintf("[%s] %s -> %s: %s", scalar(localtime($self->timestamp)), $self->sender, $self->recipient, $self->body);
    }
}

package MessageBox {
    use Moo;
    use namespace::clean;

    has 'owner'    => (is => 'ro', required => 1);
    has 'messages' => (is => 'rw', default  => sub { [] });

    sub receive($self, $message) {
        push $self->messages->@*, $message;
    }

    sub get_all($self) {
        return $self->messages->@*;
    }

    sub get_unread($self) {
        return $self->messages->@*;    # この段階では全てunread扱い
    }

    sub count($self) {
        return scalar $self->messages->@*;
    }
}

# デモ実行
sub demo {
    say "=== 秘密のメッセンジャー: 第1回 ===\n";

    # アリスとボブのメッセージボックスを作成
    my $alice_box = MessageBox->new(owner => 'Alice');
    my $bob_box   = MessageBox->new(owner => 'Bob');

    # アリスからボブへメッセージを送信
    my $msg1 = Message->new(
        sender    => 'Alice',
        recipient => 'Bob',
        body      => 'こんにちは、ボブ！'
    );
    $bob_box->receive($msg1);

    # ボブからアリスへ返信
    my $msg2 = Message->new(
        sender    => 'Bob',
        recipient => 'Alice',
        body      => 'やあアリス、元気？'
    );
    $alice_box->receive($msg2);

    # メッセージボックスの確認
    say "ボブのメッセージボックス (", $bob_box->count, "件):";
    for my $msg ($bob_box->get_all) {
        say "  ", $msg->format;
    }

    say "\nアリスのメッセージボックス (", $alice_box->count, "件):";
    for my $msg ($alice_box->get_all) {
        say "  ", $msg->format;
    }
}

demo() unless caller;

1;
