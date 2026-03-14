#!/usr/bin/env perl
use v5.36;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";

# ============================================
# Before コードのテスト
# ============================================
subtest 'Before: Inappropriate Intimacy - レポート生成' => sub {
    require 'before.pl';

    my $profile = UserProfile->new(
        name       => '佐藤花子',
        email      => 'sato@example.com',
        department => '営業部',
        role       => 'user',
    );

    my $generator = UserReportGenerator->new;
    my $report = $generator->generate($profile);

    like($report, qr/佐藤花子/, 'レポートに名前が含まれる');
    like($report, qr/sato\@example\.com/, 'レポートにメールが含まれる');
    like($report, qr/営業部/, 'レポートに部署が含まれる');
    like($report, qr/user/, 'レポートに役職が含まれる');
};

subtest 'Before: Inappropriate Intimacy - 管理者検索' => sub {
    my $admin = UserProfile->new(
        name       => '管理者A',
        email      => 'admin@example.com',
        department => '情報システム部',
        role       => 'admin',
    );

    my $user = UserProfile->new(
        name       => '一般ユーザーB',
        email      => 'user@example.com',
        department => '総務部',
        role       => 'user',
    );

    my $generator = UserReportGenerator->new;
    my @admins = $generator->find_admins($admin, $user);

    is(scalar @admins, 1, '管理者は1人');
    is($admins[0], '管理者A', '管理者の名前が正しい');
};

done_testing;
