use v5.36;
use lib 'lib';
use PasswordLock;
use BruteForceIterator;
use DictionaryIterator;
use Getopt::Long;

my $mode = 'brute';
GetOptions("mode=s" => \$mode);

my $iterator;

if ($mode eq 'brute') {
    say "モード: ブルートフォース攻撃";
    $iterator = BruteForceIterator->new(length => 3);
}
elsif ($mode eq 'dict') {
    say "モード: 辞書攻撃";
    open my $fh, '>', 'passwords.txt';
    print $fh "password\nadmin\n777\n123456\n";
    close $fh;

    $iterator = DictionaryIterator->new(dict_file => 'passwords.txt');
}
else {
    die "不明なモードです: $mode";
}

my $lock = PasswordLock->new;

say "攻撃を開始します...";

while (defined(my $attempt = $iterator->next)) {
    if ($lock->unlock($attempt)) {
        say "解除成功！ パスワードは [ $attempt ] です！";
        exit;
    }
}

say "失敗しました...";
