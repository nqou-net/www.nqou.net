#!/usr/bin/env perl
# t/02_complex_validation.t
# 第2回：複雑化したバリデーションのテスト
# Perl v5.36+

use v5.36;
use utf8;
use Test::More;

# テスト対象関数
sub validate_user ($input) {
    my %errors;

    # ===== 名前の検証 =====
    my $name = $input->{name} // '';
    if ($name eq '') {
        $errors{name} = '名前を入力してください';
    }

    # ===== メールアドレスの検証 =====
    my $email = $input->{email} // '';
    if ($email eq '') {
        $errors{email} = 'メールアドレスを入力してください';
    }
    elsif ($email !~ /\A[^@\s]+\@[^@\s]+\.[^@\s]+\z/) {
        $errors{email} = 'メールアドレスの形式が正しくありません';
    }

    # ===== パスワードの検証 =====
    my $password = $input->{password} // '';
    if ($password eq '') {
        $errors{password} = 'パスワードを入力してください';
    }
    else {
        if (length($password) < 8) {
            $errors{password} = 'パスワードは8文字以上で入力してください';
        }
        elsif ($password !~ /[A-Z]/) {
            $errors{password} = 'パスワードには大文字を含めてください';
        }
        elsif ($password !~ /[a-z]/) {
            $errors{password} = 'パスワードには小文字を含めてください';
        }
        elsif ($password !~ /[0-9]/) {
            $errors{password} = 'パスワードには数字を含めてください';
        }
        else {
            my $password_confirm = $input->{password_confirm} // '';
            if ($password_confirm eq '') {
                $errors{password_confirm} = '確認用パスワードを入力してください';
            }
            elsif ($password ne $password_confirm) {
                $errors{password_confirm} = 'パスワードが一致しません';
            }
        }
    }

    # ===== 利用規約の検証 =====
    my $agreed_terms = $input->{agreed_terms} // 0;
    if (!$agreed_terms) {
        $errors{agreed_terms} = '利用規約に同意してください';
    }

    # ===== 年齢の検証 =====
    my $age = $input->{age};
    if (!defined $age || $age eq '') {
        $errors{age} = '年齢を入力してください';
    }
    elsif ($age !~ /\A[0-9]+\z/) {
        $errors{age} = '年齢は数値で入力してください';
    }
    elsif ($age < 18) {
        $errors{age} = '18歳以上の方のみ登録できます';
    }

    if (%errors) {
        return { ok => 0, errors => \%errors };
    }

    return {
        ok   => 1,
        data => {
            name     => $name,
            email    => $email,
            password => $password,
            age      => $age,
        }
    };
}

# テストケース
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

subtest 'パスワードが8文字未満' => sub {
    my $result = validate_user({
        name             => '山田太郎',
        email            => 'yamada@example.com',
        password         => 'Pass1',
        password_confirm => 'Pass1',
        agreed_terms     => 1,
        age              => 25,
    });
    is $result->{ok}, 0, '検証失敗';
    like $result->{errors}{password}, qr/8文字/, 'パスワード長エラー';
};

subtest 'パスワードに大文字がない' => sub {
    my $result = validate_user({
        name             => '山田太郎',
        email            => 'yamada@example.com',
        password         => 'password123',
        password_confirm => 'password123',
        agreed_terms     => 1,
        age              => 25,
    });
    is $result->{ok}, 0, '検証失敗';
    like $result->{errors}{password}, qr/大文字/, 'パスワード大文字エラー';
};

subtest 'パスワードに小文字がない' => sub {
    my $result = validate_user({
        name             => '山田太郎',
        email            => 'yamada@example.com',
        password         => 'PASSWORD123',
        password_confirm => 'PASSWORD123',
        agreed_terms     => 1,
        age              => 25,
    });
    is $result->{ok}, 0, '検証失敗';
    like $result->{errors}{password}, qr/小文字/, 'パスワード小文字エラー';
};

subtest 'パスワードに数字がない' => sub {
    my $result = validate_user({
        name             => '山田太郎',
        email            => 'yamada@example.com',
        password         => 'Passworddd',
        password_confirm => 'Passworddd',
        agreed_terms     => 1,
        age              => 25,
    });
    is $result->{ok}, 0, '検証失敗';
    like $result->{errors}{password}, qr/数字/, 'パスワード数字エラー';
};

subtest '確認パスワードが不一致' => sub {
    my $result = validate_user({
        name             => '山田太郎',
        email            => 'yamada@example.com',
        password         => 'Password123',
        password_confirm => 'Password456',
        agreed_terms     => 1,
        age              => 25,
    });
    is $result->{ok}, 0, '検証失敗';
    like $result->{errors}{password_confirm}, qr/一致/, '確認パスワード不一致エラー';
};

subtest '利用規約に同意していない' => sub {
    my $result = validate_user({
        name             => '山田太郎',
        email            => 'yamada@example.com',
        password         => 'Password123',
        password_confirm => 'Password123',
        agreed_terms     => 0,
        age              => 25,
    });
    is $result->{ok}, 0, '検証失敗';
    like $result->{errors}{agreed_terms}, qr/利用規約/, '利用規約エラー';
};

subtest '年齢が18歳未満' => sub {
    my $result = validate_user({
        name             => '山田太郎',
        email            => 'yamada@example.com',
        password         => 'Password123',
        password_confirm => 'Password123',
        agreed_terms     => 1,
        age              => 15,
    });
    is $result->{ok}, 0, '検証失敗';
    like $result->{errors}{age}, qr/18歳/, '年齢制限エラー';
};

subtest '年齢が数値でない' => sub {
    my $result = validate_user({
        name             => '山田太郎',
        email            => 'yamada@example.com',
        password         => 'Password123',
        password_confirm => 'Password123',
        agreed_terms     => 1,
        age              => 'twenty',
    });
    is $result->{ok}, 0, '検証失敗';
    like $result->{errors}{age}, qr/数値/, '年齢数値エラー';
};

done_testing;
