#!/usr/bin/env perl
# 第2回 コード例1: 破綻するコード - XOR暗号を追加しようとして既存コードを壊す
use v5.36;
use Moo;
use namespace::clean;

# 問題: 暗号化を追加するには MessageBox クラスを直接変更する必要がある
# これは開放閉鎖の原則（OCP）に違反する

package Message {
    use Moo;
    use namespace::clean;

    has 'sender'    => (is => 'ro', required => 1);
    has 'recipient' => (is => 'ro', required => 1);
    has 'body'      => (is => 'ro', required => 1);            # 平文のまま
    has 'timestamp' => (is => 'ro', default  => sub {time});
}

package MessageBox {
    use Moo;
    use namespace::clean;

    has 'owner'       => (is => 'ro', required => 1);
    has 'messages'    => (is => 'rw', default  => sub { [] });
    has 'use_encrypt' => (is => 'ro', default  => 0);            # 暗号化フラグ追加
    has 'encrypt_key' => (is => 'ro', default  => 42);           # 暗号化キー追加

    sub receive($self, $message) {

        # 問題: 暗号化ロジックがMessageBoxに入り込んでいる
        my $body = $message->body;
        if ($self->use_encrypt) {
            $body = $self->_xor_encrypt($body);
        }

        my $stored_msg = Message->new(
            sender    => $message->sender,
            recipient => $message->recipient,
            body      => $body,
            timestamp => $message->timestamp
        );
        push $self->messages->@*, $stored_msg;
    }

    sub get_all($self) {

        # 問題: 復号ロジックもMessageBoxに必要
        my @decrypted;
        for my $msg ($self->messages->@*) {
            my $body = $msg->body;
            if ($self->use_encrypt) {
                $body = $self->_xor_decrypt($body);
            }
            push @decrypted,
                Message->new(
                sender    => $msg->sender,
                recipient => $msg->recipient,
                body      => $body,
                timestamp => $msg->timestamp
                );
        }
        return @decrypted;
    }

    # 問題: 暗号化メソッドがMessageBoxに混在
    sub _xor_encrypt($self, $text) {
        my $key = $self->encrypt_key;
        return join '', map { chr(ord($_) ^ $key) } split //, $text;
    }

    sub _xor_decrypt($self, $text) {
        return $self->_xor_encrypt($text);    # XORは対称
    }

    sub count($self) { scalar $self->messages->@* }
}

# デモ: 問題点を示す
sub demo {
    say "=== 第2回: 破綻するコード ===\n";

    # 暗号化なしのボックス
    my $plain_box = MessageBox->new(owner => 'Bob', use_encrypt => 0);

    # 暗号化ありのボックス
    my $encrypted_box = MessageBox->new(owner => 'Bob', use_encrypt => 1, encrypt_key => 42);

    my $msg = Message->new(sender => 'Alice', recipient => 'Bob', body => 'SECRET');

    $plain_box->receive($msg);
    $encrypted_box->receive($msg);

    say "平文ボックス: ", ($plain_box->get_all)[0]->body;
    say "暗号化ボックス（内部）: ", $encrypted_box->messages->[0]->body;
    say "暗号化ボックス（復号後）: ", ($encrypted_box->get_all)[0]->body;

    say "\n問題点:";
    say "- MessageBoxクラスが肥大化";
    say "- 暗号化とメールボックス機能が混在";
    say "- 新しい暗号方式を追加するたびにMessageBoxを変更必要";
    say "- テストが複雑化";
}

demo() unless caller;

1;
