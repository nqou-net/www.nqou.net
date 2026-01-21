use v5.36;
use lib 'lib';
use PasswordLock;
use BruteForceIterator;

my $target_length = 4;
my $lock = PasswordLock->new;

my $iterator = BruteForceIterator->new(length => $target_length);

say "クラッキングを開始します...";

while (defined(my $attempt = $iterator->next)) {
    if ($lock->unlock($attempt)) {
        say "解除成功！ パスワードは [ $attempt ] です！";
        exit;
    }
}

say "見つかりませんでした。";
