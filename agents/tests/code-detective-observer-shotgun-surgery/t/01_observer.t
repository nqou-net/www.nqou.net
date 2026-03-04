#!/usr/bin/env perl
use v5.34;
use warnings;
use utf8;
use Test::More;
my $builder = Test::More->builder;
binmode $builder->output,         ":utf8";
binmode $builder->failure_output, ":utf8";
binmode $builder->todo_output,    ":utf8";
use FindBin;
use lib "$FindBin::Bin/../lib";

subtest 'コード例1 - 問題版 (Shotgun Surgery)' => sub {
    require 'before_shotgun_surgery.pl';

    my $manager = StockManager->new;
    my $result  = $manager->update_stock('Keyboard', 150);

    # 基本動作の確認
    is $result->{message}, 'Stock updated: Keyboard => 150',
        '在庫更新メッセージが正しいこと';

    # 各通知が直書きで呼ばれていること
    is $result->{email}, '[EMAIL] Keyboard is now 150',
        'メール通知が正しいこと';
    is $result->{log}, '[LOG] Keyboard: quantity changed to 150',
        'ログ出力が正しいこと';
    is $result->{dashboard}, '[DASHBOARD] Refreshed: Keyboard (150)',
        'ダッシュボード更新が正しいこと';
};

subtest 'コード例2 - 改善版 (Observer)' => sub {
    require 'after_observer.pl';

    subtest '全Observerを登録した場合' => sub {
        # StockManager パッケージ名が衝突するので、After版の名前空間を利用
        # after_observer.pl で再定義される StockManager を使用
        my $manager = StockManager->new;
        $manager->add_observer(StockObserver::Email->new);
        $manager->add_observer(StockObserver::Logger->new);
        $manager->add_observer(StockObserver::Dashboard->new);

        my $result = $manager->update_stock('Keyboard', 150);

        is $result->{message}, 'Stock updated: Keyboard => 150',
            '在庫更新メッセージが正しいこと';

        my @notifs = @{$result->{notifications}};
        is scalar(@notifs), 3, '3つの通知が発行されること';
        is $notifs[0], '[EMAIL] Keyboard is now 150',
            'メール通知が正しいこと';
        is $notifs[1], '[LOG] Keyboard: quantity changed to 150',
            'ログ出力が正しいこと';
        is $notifs[2], '[DASHBOARD] Refreshed: Keyboard (150)',
            'ダッシュボード更新が正しいこと';
    };

    subtest 'Observerなしの場合' => sub {
        my $manager = StockManager->new;
        my $result  = $manager->update_stock('Mouse', 50);

        is $result->{message}, 'Stock updated: Mouse => 50',
            '在庫更新メッセージが正しいこと';
        is scalar(@{$result->{notifications}}), 0,
            'Observerなしなら通知は0件';
    };

    subtest 'Observerの追加・削除' => sub {
        my $manager = StockManager->new;
        my $email   = StockObserver::Email->new;
        my $logger  = StockObserver::Logger->new;

        $manager->add_observer($email);
        $manager->add_observer($logger);

        my $result1 = $manager->update_stock('Monitor', 30);
        is scalar(@{$result1->{notifications}}), 2,
            '2つのObserverで2件の通知';

        # Observerを削除
        $manager->remove_observer($email);
        my $result2 = $manager->update_stock('Monitor', 25);
        is scalar(@{$result2->{notifications}}), 1,
            'Email削除後は1件の通知';
        is $result2->{notifications}[0], '[LOG] Monitor: quantity changed to 25',
            'Loggerのみ残っていること';
    };

    subtest '不正なObserverの登録はエラーになること' => sub {
        my $manager = StockManager->new;
        eval { $manager->add_observer(bless {}, 'FakeObserver') };
        like $@, qr/Invalid observer/, 'Role未実装のオブジェクトは登録不可';
    };
};

done_testing;
