#!/usr/bin/env perl
# t/01_basic_validation.t
# 第1回：基本バリデーションのテスト
# Perl v5.36+

use v5.36;
use utf8;
use Test::More;

# テスト対象関数
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

# テストケース
subtest 'すべて正常なデータ' => sub {
    my $result = validate_user({ name => '山田太郎', email => 'yamada@example.com' });
    is $result->{ok}, 1, '検証成功';
    is $result->{data}{name}, '山田太郎', '名前が正しい';
    is $result->{data}{email}, 'yamada@example.com', 'メールが正しい';
};

subtest '名前が空' => sub {
    my $result = validate_user({ name => '', email => 'yamada@example.com' });
    is $result->{ok}, 0, '検証失敗';
    like $result->{errors}{name}, qr/名前/, '名前エラーがある';
};

subtest 'メールアドレスが空' => sub {
    my $result = validate_user({ name => '山田太郎', email => '' });
    is $result->{ok}, 0, '検証失敗';
    like $result->{errors}{email}, qr/メールアドレス/, 'メールエラーがある';
};

subtest 'メールアドレスの形式が不正' => sub {
    my $result = validate_user({ name => '山田太郎', email => 'invalid-email' });
    is $result->{ok}, 0, '検証失敗';
    like $result->{errors}{email}, qr/形式/, 'メール形式エラーがある';
};

subtest '名前とメールアドレスが両方空' => sub {
    my $result = validate_user({ name => '', email => '' });
    is $result->{ok}, 0, '検証失敗';
    ok exists $result->{errors}{name}, '名前エラーがある';
    ok exists $result->{errors}{email}, 'メールエラーがある';
};

subtest 'フィールドが未定義' => sub {
    my $result = validate_user({});
    is $result->{ok}, 0, '検証失敗';
    ok exists $result->{errors}{name}, '名前エラーがある';
    ok exists $result->{errors}{email}, 'メールエラーがある';
};

done_testing;
