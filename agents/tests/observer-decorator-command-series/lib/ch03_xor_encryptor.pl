#!/usr/bin/env perl
# 第3回 コード例2: XorEncryptorDecorator - Decoratorパターンで暗号化を分離
use v5.36;
use Moo;
use namespace::clean;

# Encryptor::Role を定義
package Encryptor::Role {
    use Moo::Role;
    use namespace::clean;

    requires 'encrypt';
    requires 'decrypt';

    has 'wrapped' => (is => 'ro', predicate => 'has_wrapped');

    sub process_encrypt($self, $text) {
        my $result = $self->encrypt($text);
        return $self->has_wrapped ? $self->wrapped->process_encrypt($result) : $result;
    }

    sub process_decrypt($self, $text) {
        my $result = $self->has_wrapped ? $self->wrapped->process_decrypt($text) : $text;
        return $self->decrypt($result);
    }
}

# XOR暗号化Decorator
package XorEncryptor {
    use Moo;
    with 'Encryptor::Role';
    use namespace::clean;

    has 'key' => (is => 'ro', default => 42);

    sub encrypt($self, $text) {
        return join '', map { chr(ord($_) ^ $self->key) } split //, $text;
    }

    sub decrypt($self, $text) {
        return $self->encrypt($text);    # XORは対称暗号
    }
}

# NullEncryptor（何もしない）
package NullEncryptor {
    use Moo;
    with 'Encryptor::Role';
    use namespace::clean;

    sub encrypt($self, $text) {$text}
    sub decrypt($self, $text) {$text}
}

# 改善版MessageBox
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

    has 'owner'     => (is => 'ro', required => 1);
    has 'messages'  => (is => 'rw', default  => sub { [] });
    has 'encryptor' => (is => 'ro', default  => sub { NullEncryptor->new });

    sub receive($self, $message) {

        # 暗号化はEncryptorに委譲
        my $encrypted_body = $self->encryptor->process_encrypt($message->body);
        my $stored         = Message->new(
            sender    => $message->sender,
            recipient => $message->recipient,
            body      => $encrypted_body,
            timestamp => $message->timestamp
        );
        push $self->messages->@*, $stored;
    }

    sub get_all($self) {
        my @decrypted;
        for my $msg ($self->messages->@*) {
            my $decrypted_body = $self->encryptor->process_decrypt($msg->body);
            push @decrypted,
                Message->new(
                sender    => $msg->sender,
                recipient => $msg->recipient,
                body      => $decrypted_body,
                timestamp => $msg->timestamp
                );
        }
        return @decrypted;
    }

    sub count($self) { scalar $self->messages->@* }
}

# デモ
sub demo {
    say "=== 第3回: Decoratorパターン導入 ===\n";

    # XOR暗号化器を使用
    my $xor = XorEncryptor->new(key => 42);
    my $box = MessageBox->new(owner => 'Bob', encryptor => $xor);

    my $msg = Message->new(sender => 'Alice', recipient => 'Bob', body => 'SECRET MESSAGE');
    $box->receive($msg);

    say "送信内容: SECRET MESSAGE";
    say "保存時（暗号化）: ", $box->messages->[0]->body;
    say "取得時（復号後）: ", ($box->get_all)[0]->body;

    say "\n改善点:";
    say "- MessageBoxは暗号化ロジックを知らない";
    say "- Encryptorを差し替えるだけで別の暗号方式に対応";
    say "- 開放閉鎖の原則（OCP）を達成";
}

demo() unless caller;

1;
