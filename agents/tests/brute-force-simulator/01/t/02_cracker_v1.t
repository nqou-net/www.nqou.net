use v5.36;
use Test::More;
use File::Temp qw(tempfile);

subtest 'cracker_v1.pl execution test' => sub {
    my $output = `perl cracker_v1.pl 2>&1`;
    my $exit_code = $? >> 8;
    
    like($output, qr/クラッキングを開始します/, 'Start message appears');
    like($output, qr/解除成功！ パスワードは \[ 777 \] です！/, 'Success message with correct password');
    is($exit_code, 0, 'Script exits successfully');
};

done_testing();
