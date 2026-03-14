#!/usr/bin/env perl
use v5.36;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";

# ============================================
# After コードのテスト
# ============================================
require 'after.pl';

subtest 'After: Proxy - レポート生成' => sub {
    my $real = UserProfile->new(
        name       => '佐藤花子',
        email      => 'sato@example.com',
        department => '営業部',
        role       => 'user',
    );

    my $proxy = UserProfile::Proxy->new(real_subject => $real);
    my $generator = UserReportGenerator->new;
    my $report = $generator->generate($proxy);

    like($report, qr/佐藤花子/, 'Proxy経由でレポートに名前が含まれる');
    like($report, qr/sato\@example\.com/, 'Proxy経由でレポートにメールが含まれる');
    like($report, qr/営業部/, 'Proxy経由でレポートに部署が含まれる');
    like($report, qr/user/, 'Proxy経由でレポートに役職が含まれる');
};

subtest 'After: Proxy - 管理者検索' => sub {
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

    my $proxy_admin = UserProfile::Proxy->new(real_subject => $admin);
    my $proxy_user  = UserProfile::Proxy->new(real_subject => $user);

    my $generator = UserReportGenerator->new;
    my @admins = $generator->find_admins($proxy_admin, $proxy_user);

    is(scalar @admins, 1, '管理者は1人');
    is($admins[0], '管理者A', '管理者の名前が正しい');
};

subtest 'After: Proxy - アクセスログ機能' => sub {
    my $real = UserProfile->new(
        name       => 'テストユーザー',
        email      => 'test@example.com',
        department => 'テスト部',
        role       => 'user',
    );

    my $proxy = UserProfile::Proxy->new(real_subject => $real);

    # 最初はアクセスなし
    is($proxy->access_count, 0, '初期状態ではアクセス回数は0');

    # name にアクセス
    my $name = $proxy->name;
    is($name, 'テストユーザー', 'Proxy経由で正しい名前が取得できる');
    is($proxy->access_count, 1, 'nameアクセス後は1回');

    # email にアクセス
    my $email = $proxy->email;
    is($email, 'test@example.com', 'Proxy経由で正しいメールが取得できる');
    is($proxy->access_count, 2, 'emailアクセス後は2回');

    # アクセスログの内容を確認
    my @log = $proxy->get_access_log;
    is($log[0]->{field}, 'name', 'ログの1件目はname');
    is($log[1]->{field}, 'email', 'ログの2件目はemail');
};

subtest 'After: Proxy - キャッシュ機能' => sub {
    my $real = UserProfile->new(
        name       => 'キャッシュテスト',
        email      => 'cache@example.com',
        department => 'テスト部',
        role       => 'admin',
    );

    my $proxy = UserProfile::Proxy->new(real_subject => $real);

    # 同じフィールドに2回アクセスしてもRealSubjectへのアクセスは1回
    my $name1 = $proxy->name;
    my $name2 = $proxy->name;

    is($name1, $name2, 'キャッシュされた値は同じ');
    is($name1, 'キャッシュテスト', '正しい値がキャッシュされている');
};

subtest 'After: RealSubject を直接使ってもインターフェースは同じ' => sub {
    my $real = UserProfile->new(
        name       => '直接アクセス',
        email      => 'direct@example.com',
        department => '直接部',
        role       => 'user',
    );

    my $generator = UserReportGenerator->new;

    # Proxy なしでも同じレポートが生成できる
    my $report = $generator->generate($real);
    like($report, qr/直接アクセス/, 'RealSubject でも同じインターフェースで動作');
};

done_testing;
