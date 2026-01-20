use v5.36;
use Test::More;

subtest 'cracker_poly.pl brute mode' => sub {
    my $output = `perl cracker_poly.pl --mode=brute 2>&1`;
    my $exit_code = $? >> 8;
    
    like($output, qr/モード: ブルートフォース攻撃/, 'Brute mode message appears');
    like($output, qr/攻撃を開始します/, 'Start message appears');
    like($output, qr/解除成功！ パスワードは \[ 777 \] です！/, 'Success message with correct password');
    is($exit_code, 0, 'Script exits successfully');
};

subtest 'cracker_poly.pl dict mode' => sub {
    my $output = `perl cracker_poly.pl --mode=dict 2>&1`;
    my $exit_code = $? >> 8;
    
    like($output, qr/モード: 辞書攻撃/, 'Dict mode message appears');
    like($output, qr/攻撃を開始します/, 'Start message appears');
    like($output, qr/解除成功！ パスワードは \[ 777 \] です！/, 'Success message with correct password');
    is($exit_code, 0, 'Script exits successfully');
};

subtest 'cracker_poly.pl default mode' => sub {
    my $output = `perl cracker_poly.pl 2>&1`;
    
    like($output, qr/モード: ブルートフォース攻撃/, 'Default mode is brute');
};

done_testing();
