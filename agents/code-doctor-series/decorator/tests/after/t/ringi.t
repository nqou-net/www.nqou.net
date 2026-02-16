use v5.36;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";

use RingiProcessor::Factory;

subtest '10万未満の稟議（係長決裁＋ログ記録のみ）' => sub {
    my $processor = RingiProcessor::Factory->build_processor(50_000);
    my $result    = $processor->process(
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

subtest '30万円の稟議（部長決裁＋メール＋ログ）' => sub {
    my $processor = RingiProcessor::Factory->build_processor(300_000);
    my $result    = $processor->process(
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

subtest '80万円の稟議（部長＋役員＋メール＋ログ）' => sub {
    my $processor = RingiProcessor::Factory->build_processor(800_000);
    my $result    = $processor->process(
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

subtest '200万円の稟議（全承認ステップ＋監査＋経理CC）' => sub {
    my $processor = RingiProcessor::Factory->build_processor(2_000_000);
    my $result    = $processor->process(
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
    ok grep(/\[AUDIT\]/,        @$result), '監査証跡あり';
};

subtest 'Decoratorの動的組み合わせ（手動組み立て）' => sub {

    # 付箋を自由に貼り替える: BasicApproval + AuditTrail のみ
    use RingiProcessor::BasicApproval;
    use RingiProcessor::WithAuditTrail;

    my $processor = RingiProcessor::WithAuditTrail->new(inner => RingiProcessor::BasicApproval->new(),);

    my $result = $processor->process(
        {
            kingaku  => 10_000,
            bumon    => '総務',
            kian_sha => 'テスト',
        }
    );

    ok grep(/\[AUDIT\]/, @$result), '監査証跡あり（手動追加）';
    ok !grep(/\[LOG\]/,  @$result), 'ログ記録なし（巻かなかった）';
    ok !grep(/部長承認/,     @$result), '部長承認なし';
    ok !grep(/メール通知/,    @$result), 'メール通知なし';
};

done_testing;
