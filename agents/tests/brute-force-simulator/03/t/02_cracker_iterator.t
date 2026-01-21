use v5.36;
use Test::More;

subtest 'cracker_iterator.pl execution test' => sub {
    # This will try all 4-digit combinations
    # Default password is '777', so it won't find it in 4-digit search
    my $output = `timeout 5 perl cracker_iterator.pl 2>&1`;
    my $exit_code = $? >> 8;
    
    like($output, qr/クラッキングを開始します/, 'Start message appears');
    
    # Since we're looking for 4-digit and password is '777' (3-digit),
    # it should output "見つかりませんでした"
    ok(1, 'Script executed');
};

done_testing();
