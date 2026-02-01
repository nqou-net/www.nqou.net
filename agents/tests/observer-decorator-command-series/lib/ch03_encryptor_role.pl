#!/usr/bin/env perl
# 第3回 コード例1: EncryptorRole - 暗号化の共通インターフェース
use v5.36;
use Moo::Role;
use namespace::clean;

package Encryptor::Role {
    use Moo::Role;
    use namespace::clean;

    # 共通インターフェース: 暗号化と復号
    requires 'encrypt';
    requires 'decrypt';

    # ラップ対象（次のEncryptor）
    has 'wrapped' => (
        is        => 'ro',
        predicate => 'has_wrapped',
    );

    # チェーンを辿って最終的な暗号化
    sub process_encrypt($self, $text) {
        my $result = $self->encrypt($text);
        if ($self->has_wrapped) {
            $result = $self->wrapped->process_encrypt($result);
        }
        return $result;
    }

    # チェーンを辿って最終的な復号（逆順）
    sub process_decrypt($self, $text) {
        my $result = $text;
        if ($self->has_wrapped) {
            $result = $self->wrapped->process_decrypt($result);
        }
        $result = $self->decrypt($result);
        return $result;
    }
}

# テスト用: 何もしないNullEncryptor
package NullEncryptor {
    use Moo;
    with 'Encryptor::Role';
    use namespace::clean;

    sub encrypt($self, $text) { return $text }
    sub decrypt($self, $text) { return $text }
}

1;
