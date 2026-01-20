#!/usr/bin/env perl
# form-validation-03.pl
# ユーザー登録バリデーション（Chain of Responsibilityパターン版）
# Perl v5.36+, Moo

use v5.36;
use utf8;
use warnings;
use Moo;
binmode STDOUT, ':utf8';

# ===== 基底Validatorクラス =====
package Validator {
    use Moo;

    has next_handler => (
        is        => 'rw',
        predicate => 'has_next_handler',
    );

    has field_name => (
        is       => 'ro',
        required => 1,
    );

    has error_message => (
        is       => 'ro',
        required => 1,
    );

    sub set_next ($self, $handler) {
        $self->next_handler($handler);
        return $handler;
    }

    sub validate ($self, $input, $errors) {
        my $value = $input->{$self->field_name} // '';

        if (!$self->_do_validate($value, $input)) {
            # 同じフィールドにエラーがなければ追加
            $errors->{$self->field_name} //= $self->error_message;
        }

        if ($self->has_next_handler) {
            return $self->next_handler->validate($input, $errors);
        }

        return $errors;
    }

    sub _do_validate ($self, $value, $input) {
        die "サブクラスで_do_validateを実装してください";
    }
};

# ===== 具体的なバリデータ =====

# 必須チェック
package RequiredValidator {
    use Moo;
    extends 'Validator';

    sub _do_validate ($self, $value, $input) {
        return $value ne '';
    }
};

# メールアドレス形式チェック
package EmailValidator {
    use Moo;
    extends 'Validator';

    sub _do_validate ($self, $value, $input) {
        return 1 if $value eq '';
        return $value =~ /\A[^@\s]+\@[^@\s]+\.[^@\s]+\z/;
    }
};

# 文字列長チェック
package LengthValidator {
    use Moo;
    extends 'Validator';

    has min_length => (is => 'ro', default => 0);
    has max_length => (is => 'ro');

    sub _do_validate ($self, $value, $input) {
        return 1 if $value eq '';
        my $len = length($value);
        return 0 if $len < $self->min_length;
        return 0 if defined $self->max_length && $len > $self->max_length;
        return 1;
    }
};

# パスワード強度チェック
package PasswordStrengthValidator {
    use Moo;
    extends 'Validator';

    sub _do_validate ($self, $value, $input) {
        return 1 if $value eq '';
        return 0 unless $value =~ /[A-Z]/;
        return 0 unless $value =~ /[a-z]/;
        return 0 unless $value =~ /[0-9]/;
        return 1;
    }
};

# 確認一致チェック
package ConfirmValidator {
    use Moo;
    extends 'Validator';

    has confirm_field => (is => 'ro', required => 1);

    sub _do_validate ($self, $value, $input) {
        my $original = $input->{$self->confirm_field} // '';
        return 1 if $original eq '';  # 元のフィールドが空ならスキップ
        return $value eq $original;
    }
};

# 真偽値チェック（利用規約同意など）
package BooleanValidator {
    use Moo;
    extends 'Validator';

    sub _do_validate ($self, $value, $input) {
        return $value ? 1 : 0;
    }
};

# 数値範囲チェック
package RangeValidator {
    use Moo;
    extends 'Validator';

    has min_value => (is => 'ro');
    has max_value => (is => 'ro');

    sub _do_validate ($self, $value, $input) {
        return 1 if !defined $value || $value eq '';
        return 0 unless $value =~ /\A[0-9]+\z/;
        return 0 if defined $self->min_value && $value < $self->min_value;
        return 0 if defined $self->max_value && $value > $self->max_value;
        return 1;
    }
};

# ===== チェーン構築 =====
package main;

sub build_user_registration_chain () {
    my $name_required = RequiredValidator->new(
        field_name    => 'name',
        error_message => '名前を入力してください',
    );

    my $email_required = RequiredValidator->new(
        field_name    => 'email',
        error_message => 'メールアドレスを入力してください',
    );

    my $email_format = EmailValidator->new(
        field_name    => 'email',
        error_message => 'メールアドレスの形式が正しくありません',
    );

    my $password_required = RequiredValidator->new(
        field_name    => 'password',
        error_message => 'パスワードを入力してください',
    );

    my $password_length = LengthValidator->new(
        field_name    => 'password',
        error_message => 'パスワードは8文字以上で入力してください',
        min_length    => 8,
    );

    my $password_strength = PasswordStrengthValidator->new(
        field_name    => 'password',
        error_message => 'パスワードには大文字・小文字・数字を含めてください',
    );

    my $password_confirm = ConfirmValidator->new(
        field_name    => 'password_confirm',
        error_message => 'パスワードが一致しません',
        confirm_field => 'password',
    );

    my $agreed_terms = BooleanValidator->new(
        field_name    => 'agreed_terms',
        error_message => '利用規約に同意してください',
    );

    my $age_range = RangeValidator->new(
        field_name    => 'age',
        error_message => '18歳以上の方のみ登録できます',
        min_value     => 18,
    );

    # チェーンを構築
    $name_required
        ->set_next($email_required)
        ->set_next($email_format)
        ->set_next($password_required)
        ->set_next($password_length)
        ->set_next($password_strength)
        ->set_next($password_confirm)
        ->set_next($agreed_terms)
        ->set_next($age_range);

    return $name_required;
}

sub validate_user ($input) {
    my $chain = build_user_registration_chain();
    my $errors = {};

    $chain->validate($input, $errors);

    if (%$errors) {
        return { ok => 0, errors => $errors };
    }

    return { ok => 1, data => $input };
}

# ===== 実行例 =====
my @test_cases = (
    # テスト1: すべて正常
    {
        name             => '山田太郎',
        email            => 'yamada@example.com',
        password         => 'Password123',
        password_confirm => 'Password123',
        agreed_terms     => 1,
        age              => 25,
    },
    # テスト2: 複数のエラー
    {
        name             => '',
        email            => 'invalid',
        password         => 'weak',
        password_confirm => 'mismatch',
        agreed_terms     => 0,
        age              => 15,
    },
    # テスト3: パスワード強度不足
    {
        name             => '鈴木花子',
        email            => 'suzuki@example.com',
        password         => 'password123',
        password_confirm => 'password123',
        agreed_terms     => 1,
        age              => 30,
    },
    # テスト4: 確認パスワード不一致
    {
        name             => '佐藤次郎',
        email            => 'sato@example.com',
        password         => 'Password123',
        password_confirm => 'Password456',
        agreed_terms     => 1,
        age              => 22,
    },
);

for my $i (0 .. $#test_cases) {
    say "=== テスト" . ($i + 1) . " ===";
    my $result = validate_user($test_cases[$i]);

    if ($result->{ok}) {
        say "検証成功: $result->{data}{name} ($result->{data}{email})";
    }
    else {
        say "検証失敗:";
        for my $field (sort keys $result->{errors}->%*) {
            say "  - $field: $result->{errors}{$field}";
        }
    }
    say "";
}
