#!/usr/bin/env perl
# form-validation-01.pl
# ユーザー登録バリデーション（基本版）
# Perl v5.36+, 外部依存なし

use v5.36;
use utf8;
use warnings;
binmode STDOUT, ':utf8';

sub validate_user ($input) {
    my %errors;

    # 名前の必須チェック
    my $name = $input->{name} // '';
    if ($name eq '') {
        $errors{name} = '名前を入力してください';
    }

    # メールアドレスの必須チェック
    my $email = $input->{email} // '';
    if ($email eq '') {
        $errors{email} = 'メールアドレスを入力してください';
    }
    # メールアドレスの形式チェック（必須チェックを通過した場合のみ）
    elsif ($email !~ /\A[^@\s]+\@[^@\s]+\.[^@\s]+\z/) {
        $errors{email} = 'メールアドレスの形式が正しくありません';
    }

    # 結果を返す
    if (%errors) {
        return { ok => 0, errors => \%errors };
    }

    return { ok => 1, data => { name => $name, email => $email } };
}

# === 実行例 ===
my @test_cases = (
    { name => '山田太郎', email => 'yamada@example.com' },
    { name => '',         email => '' },
    { name => '山田太郎', email => 'invalid-email' },
    {},
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
