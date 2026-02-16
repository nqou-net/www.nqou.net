use v5.36;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";

use Ringi;

subtest '10万未満の稟議（係長決裁のみ）' => sub {
    my $result = Ringi::process_ringi(
        {
            kingaku  => 50_000,
            bumon    => '総務',
            kian_sha => 'ヨリコ',
        }
    );

    like $result->[0], qr/承認開始.*ヨリコ.*50000円/, '承認開始メッセージ';
    like $result->[1], qr/係長承認/,              '係長承認あり';
    ok !grep(/部長承認/,   @$result), '部長承認なし';
    ok !grep(/役員承認/,   @$result), '役員承認なし';
    ok !grep(/メール通知/,  @$result), 'メール通知なし';
    ok grep(/\[LOG\]/, @$result), 'ログ記録あり';
    like $result->[-1], qr/承認完了/, '承認完了';
};

subtest '30万円の稟議（部長決裁）' => sub {
    my $result = Ringi::process_ringi(
        {
            kingaku  => 300_000,
            bumon    => '営業',
            kian_sha => 'タナカ',
        }
    );

    ok grep(/営業部長承認/,        @$result), '営業部長承認あり';
    ok !grep(/役員承認/,         @$result), '役員承認なし';
    ok grep(/メール通知:.*eigyo/, @$result), 'メール通知あり';
    ok grep(/\[LOG\]/,       @$result), 'ログ記録あり';
};

subtest '80万円の稟議（部長＋役員決裁）' => sub {
    my $result = Ringi::process_ringi(
        {
            kingaku  => 800_000,
            bumon    => '開発',
            kian_sha => 'スズキ',
        }
    );

    ok grep(/開発部長承認/,           @$result), '開発部長承認あり';
    ok grep(/役員承認/,             @$result), '役員承認あり';
    ok grep(/メール通知:.*kaihatsu/, @$result), 'メール通知あり';
    ok grep(/\[LOG\]/,          @$result), 'ログ記録あり';
};

subtest '200万円の稟議（全承認ステップ＋経理CC）' => sub {
    my $result = Ringi::process_ringi(
        {
            kingaku  => 2_000_000,
            bumon    => '総務',
            kian_sha => 'ヨリコ',
        }
    );

    ok grep(/総務部長承認/,           @$result), '総務部長承認あり';
    ok grep(/役員承認/,             @$result), '役員承認あり';
    ok grep(/メール通知:.*soumu/,    @$result), 'メール通知あり';
    ok grep(/メール通知.*CC.*keiri/, @$result), '経理CC通知あり';
    ok grep(/\[LOG\]/,          @$result), 'ログ記録あり';
};

done_testing;
