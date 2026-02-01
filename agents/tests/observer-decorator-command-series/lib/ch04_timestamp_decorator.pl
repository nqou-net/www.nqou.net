#!/usr/bin/env perl
# 第4回 コード例2: TimestampDecorator - さらにDecoratorを追加
use v5.36;
use Moo;
use MIME::Base64 qw(encode_base64 decode_base64);
use namespace::clean;

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

package NullEncryptor {
    use Moo;
    with 'Encryptor::Role';
    use namespace::clean;
    sub encrypt($self, $text) {$text}
    sub decrypt($self, $text) {$text}
}

package XorEncryptor {
    use Moo;
    with 'Encryptor::Role';
    use namespace::clean;
    has 'key' => (is => 'ro', default => 42);

    sub encrypt($self, $text) {
        join '', map { chr(ord($_) ^ $self->key) } split //, $text;
    }
    sub decrypt($self, $text) { $self->encrypt($text) }
}

package Base64Encryptor {
    use Moo;
    with 'Encryptor::Role';
    use MIME::Base64 qw(encode_base64 decode_base64);
    use namespace::clean;
    sub encrypt($self, $text) { encode_base64($text, '') }
    sub decrypt($self, $text) { decode_base64($text) }
}

# タイムスタンプ付加Decorator
package TimestampEncryptor {
    use Moo;
    with 'Encryptor::Role';
    use namespace::clean;

    has 'separator' => (is => 'ro', default => '|');

    sub encrypt($self, $text) {
        return time . $self->separator . $text;
    }

    sub decrypt($self, $text) {
        my ($timestamp, $body) = split /\Q@{[$self->separator]}\E/, $text, 2;
        return $body // $text;
    }

    sub extract_timestamp($self, $text) {
        my ($timestamp) = split /\Q@{[$self->separator]}\E/, $text, 2;
        return $timestamp;
    }
}

# デモ
sub demo {
    say "=== 第4回: 複数Decoratorを重ねる（タイムスタンプ） ===\n";

    my $original = "SECRET MESSAGE";

    # 3層のDecorator: Timestamp → Base64 → XOR
    my $chain = TimestampEncryptor->new(
        wrapped => Base64Encryptor->new(
            wrapped => XorEncryptor->new(key => 42)
        )
    );

    my $encrypted = $chain->process_encrypt($original);
    say "暗号化: $encrypted";

    my $decrypted = $chain->process_decrypt($encrypted);
    say "復号化: $decrypted";

    say "\nレイヤー構成:";
    say "  1. Timestamp: 先頭にタイムスタンプを付加";
    say "  2. Base64: バイナリ安全なエンコード";
    say "  3. XOR: 実際の暗号化";
}

demo() unless caller;

1;
