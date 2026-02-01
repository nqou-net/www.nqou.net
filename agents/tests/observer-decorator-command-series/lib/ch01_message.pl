#!/usr/bin/env perl
# 第1回 コード例1: Messageクラス - 基本的なメッセージを表現するクラス
use v5.36;
use Moo;
use namespace::clean;

package Message {
    use Moo;
    use namespace::clean;
    
    has 'sender'    => (is => 'ro', required => 1);
    has 'recipient' => (is => 'ro', required => 1);
    has 'body'      => (is => 'ro', required => 1);
    has 'timestamp' => (is => 'ro', default => sub { time });
    
    sub format($self) {
        return sprintf("[%s] %s -> %s: %s",
            scalar(localtime($self->timestamp)),
            $self->sender,
            $self->recipient,
            $self->body
        );
    }
}

# テスト用エクスポート
sub create_message($sender, $recipient, $body) {
    return Message->new(
        sender    => $sender,
        recipient => $recipient,
        body      => $body
    );
}

1;

__END__

=head1 NAME

ch01_message - 基本的なMessageクラス

=head1 DESCRIPTION

平文でメッセージを送受信するシンプルな仕組みの第一歩。
Messageクラスは送信者、受信者、本文、タイムスタンプを持つ。

=cut
