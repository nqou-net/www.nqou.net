#!/usr/bin/env perl
# form-validation-02.pl
# ユーザー登録バリデーション（複雑化版）
# Perl v5.36+, 外部依存なし
#
# 注意: このコードは「問題のあるコード」の例です。
# 次回のリファクタリング対象となります。

use v5.36;
use utf8;
use warnings;
binmode STDOUT, ':utf8';

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
        # パスワード強度チェック
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
            # パスワード強度OKの場合のみ確認パスワードをチェック
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

    # 結果を返す
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

# === 実行例 ===
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
    # テスト3: パスワードに大文字がない
    {
        name             => '鈴木花子',
        email            => 'suzuki@example.com',
        password         => 'password123',
        password_confirm => 'password123',
        agreed_terms     => 1,
        age              => 30,
    },
    # テスト4: 確認パスワードが不一致
    {
        name             => '佐藤次郎',
        email            => 'sato@example.com',
        password         => 'Password123',
        password_confirm => 'Password456',
        agreed_terms     => 1,
        age              => 22,
    },
    # テスト5: 年齢が数値でない
    {
        name             => '田中三郎',
        email            => 'tanaka@example.com',
        password         => 'Password123',
        password_confirm => 'Password123',
        agreed_terms     => 1,
        age              => 'twenty',
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
