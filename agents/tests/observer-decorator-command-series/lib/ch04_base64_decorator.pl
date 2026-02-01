#!/usr/bin/env perl
# 第4回 コード例1: Base64Decorator - 複数のDecoratorを重ねる
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

# Base64エンコードDecorator
package Base64Encryptor {
    use Moo;
    with 'Encryptor::Role';
    use MIME::Base64 qw(encode_base64 decode_base64);
    use namespace::clean;

    sub encrypt($self, $text) {
        return encode_base64($text, '');    # 改行なし
    }

    sub decrypt($self, $text) {
        return decode_base64($text);
    }
}

# デモ
sub demo {
    say "=== 第4回: 複数Decoratorを重ねる（Base64） ===\n";

    my $original = "SECRET MESSAGE";

    # XOR単体
    my $xor_only      = XorEncryptor->new(key => 42);
    my $xor_encrypted = $xor_only->process_encrypt($original);
    say "XOR単体: $xor_encrypted";

    # XOR → Base64 の順で暗号化
    my $base64           = Base64Encryptor->new(wrapped => XorEncryptor->new(key => 42));
    my $double_encrypted = $base64->process_encrypt($original);
    say "XOR → Base64: $double_encrypted";

    # 復号
    my $decrypted = $base64->process_decrypt($double_encrypted);
    say "復号結果: $decrypted";

    say "\n利点:";
    say "- XOR後のバイナリデータをBase64で安全にテキスト化";
    say "- レイヤーを追加しても既存コードに影響なし";
}

demo() unless caller;

1;
