use v5.36;
use Test::More;
use File::Temp qw(tempfile);
use lib 'lib';

use_ok('DictionaryIterator');

subtest 'DictionaryIterator basic tests' => sub {
    my ($fh, $filename) = tempfile(UNLINK => 1);
    print $fh "password\n";
    print $fh "admin\n";
    print $fh "12345\n";
    close $fh;
    
    my $iter = DictionaryIterator->new(dict_file => $filename);
    isa_ok($iter, 'DictionaryIterator');
    
    is($iter->next, 'password', 'First line is password');
    is($iter->next, 'admin', 'Second line is admin');
    is($iter->next, '12345', 'Third line is 12345');
    is($iter->next, undef, 'Returns undef at end of file');
};

subtest 'DictionaryIterator with empty file' => sub {
    my ($fh, $filename) = tempfile(UNLINK => 1);
    close $fh;
    
    my $iter = DictionaryIterator->new(dict_file => $filename);
    is($iter->next, undef, 'Returns undef for empty file');
};

subtest 'DictionaryIterator file not found' => sub {
    eval {
        my $iter = DictionaryIterator->new(dict_file => '/nonexistent/path/file.txt');
    };
    
    like($@, qr/辞書ファイルが開けません/, 'Dies with appropriate message when file not found');
};

done_testing();
