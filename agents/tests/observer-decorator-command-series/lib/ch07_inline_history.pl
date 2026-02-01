#!/usr/bin/env perl
# 第7回 コード例1: ベタ書き履歴 - Command導入前の問題を体感
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
}

package MessageBox {
    use Moo;
    use namespace::clean;
    has 'owner'    => (is => 'ro', required => 1);
    has 'messages' => (is => 'rw', default  => sub { [] });
    has 'history'  => (is => 'rw', default  => sub { [] });    # 履歴を追加

    sub receive($self, $msg) {
        push $self->messages->@*, $msg;
        push $self->history->@*, {action => 'receive', msg => $msg, time => time};
    }

    sub delete($self, $index) {
        my $msg = splice $self->messages->@*, $index, 1;
        push $self->history->@*, {action => 'delete', msg => $msg, time => time};
        return $msg;
    }

    sub count($self)   { scalar $self->messages->@* }
    sub get_all($self) { $self->messages->@* }

    # Undoを実装しようとすると...
    sub undo($self) {
        my $last = pop $self->history->@*;
        return unless $last;

        # 問題: アクションごとに異なる処理が必要
        if ($last->{action} eq 'receive') {
            pop $self->messages->@*;
        }
        elsif ($last->{action} eq 'delete') {

            # 問題: 元の位置に戻すのが難しい
            push $self->messages->@*, $last->{msg};
        }

        # 問題: 新しいアクションを追加するたびにこのメソッドを変更必要
    }
}

# デモ
sub demo {
    say "=== 第7回: ベタ書き履歴の問題点 ===\n";

    my $box = MessageBox->new(owner => 'Bob');

    $box->receive(Message->new(sender => 'Alice',   recipient => 'Bob', body => 'Hello!'));
    $box->receive(Message->new(sender => 'Charlie', recipient => 'Bob', body => 'Hi!'));
    say "メッセージ数: ", $box->count;

    $box->delete(0);
    say "削除後: ", $box->count;

    $box->undo;
    say "Undo後: ", $box->count;

    say "\n問題点:";
    say "- undoメソッドがアクション種別を知っている必要がある";
    say "- 新しい操作を追加するたびにundoを修正";
    say "- 履歴データ構造が複雑化";
    say "- テストが困難";
}

demo() unless caller;

1;
