#!/usr/bin/env perl
# t/03_chain_of_responsibility.t
# 第3回：Chain of Responsibilityパターンのテスト
# Perl v5.36+, Moo

use v5.36;
use utf8;
use Test::More;
use Moo;

# ===== バリデータ定義（form-validation-03.plより抜粋） =====
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

package RequiredValidator {
    use Moo;
    extends 'Validator';

    sub _do_validate ($self, $value, $input) {
        return $value ne '';
    }
};

package EmailValidator {
    use Moo;
    extends 'Validator';

    sub _do_validate ($self, $value, $input) {
        return 1 if $value eq '';
        return $value =~ /\A[^@\s]+\@[^@\s]+\.[^@\s]+\z/;
    }
};

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

package ConfirmValidator {
    use Moo;
    extends 'Validator';

    has confirm_field => (is => 'ro', required => 1);

    sub _do_validate ($self, $value, $input) {
        my $original = $input->{$self->confirm_field} // '';
        return 1 if $original eq '';
        return $value eq $original;
    }
};

package BooleanValidator {
    use Moo;
    extends 'Validator';

    sub _do_validate ($self, $value, $input) {
        return $value ? 1 : 0;
    }
};

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

package main;

sub build_chain () {
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
    my $chain = build_chain();
    my $errors = {};
    $chain->validate($input, $errors);
    if (%$errors) {
        return { ok => 0, errors => $errors };
    }
    return { ok => 1, data => $input };
}

# ===== テストケース =====

subtest 'すべて正常なデータ' => sub {
    my $result = validate_user({
        name             => '山田太郎',
        email            => 'yamada@example.com',
        password         => 'Password123',
        password_confirm => 'Password123',
        agreed_terms     => 1,
        age              => 25,
    });
    is $result->{ok}, 1, '検証成功';
};

subtest '複数のエラー' => sub {
    my $result = validate_user({
        name             => '',
        email            => 'invalid',
        password         => 'weak',
        password_confirm => 'mismatch',
        agreed_terms     => 0,
        age              => 15,
    });
    is $result->{ok}, 0, '検証失敗';
    ok exists $result->{errors}{name}, '名前エラーがある';
    ok exists $result->{errors}{email}, 'メールエラーがある';
    ok exists $result->{errors}{password}, 'パスワードエラーがある';
    ok exists $result->{errors}{agreed_terms}, '利用規約エラーがある';
    ok exists $result->{errors}{age}, '年齢エラーがある';
};

subtest 'パスワード強度不足' => sub {
    my $result = validate_user({
        name             => '鈴木花子',
        email            => 'suzuki@example.com',
        password         => 'password123',  # 大文字がない
        password_confirm => 'password123',
        agreed_terms     => 1,
        age              => 30,
    });
    is $result->{ok}, 0, '検証失敗';
    like $result->{errors}{password}, qr/大文字|小文字|数字/, 'パスワード強度エラー';
};

subtest '確認パスワード不一致' => sub {
    my $result = validate_user({
        name             => '佐藤次郎',
        email            => 'sato@example.com',
        password         => 'Password123',
        password_confirm => 'Password456',
        agreed_terms     => 1,
        age              => 22,
    });
    is $result->{ok}, 0, '検証失敗';
    like $result->{errors}{password_confirm}, qr/一致/, '確認パスワード不一致エラー';
};

# 個別バリデータのテスト
subtest 'RequiredValidator単体テスト' => sub {
    my $v = RequiredValidator->new(
        field_name    => 'test',
        error_message => 'テストエラー',
    );
    my $errors = {};
    $v->validate({ test => 'value' }, $errors);
    is_deeply $errors, {}, '値があればエラーなし';

    $errors = {};
    $v->validate({ test => '' }, $errors);
    ok exists $errors->{test}, '空値でエラー';
};

subtest 'EmailValidator単体テスト' => sub {
    my $v = EmailValidator->new(
        field_name    => 'email',
        error_message => 'メール形式エラー',
    );
    my $errors = {};
    $v->validate({ email => 'test@example.com' }, $errors);
    is_deeply $errors, {}, '正常なメールならエラーなし';

    $errors = {};
    $v->validate({ email => 'invalid' }, $errors);
    ok exists $errors->{email}, '不正なメールでエラー';
};

subtest 'LengthValidator単体テスト' => sub {
    my $v = LengthValidator->new(
        field_name    => 'pass',
        error_message => '長さエラー',
        min_length    => 8,
    );
    my $errors = {};
    $v->validate({ pass => '12345678' }, $errors);
    is_deeply $errors, {}, '8文字ならエラーなし';

    $errors = {};
    $v->validate({ pass => '1234567' }, $errors);
    ok exists $errors->{pass}, '7文字でエラー';
};

subtest 'チェーン構築テスト' => sub {
    my $chain = build_chain();
    ok $chain->isa('RequiredValidator'), 'チェーン先頭はRequiredValidator';
    ok $chain->has_next_handler, '次のハンドラがある';
};

done_testing;
