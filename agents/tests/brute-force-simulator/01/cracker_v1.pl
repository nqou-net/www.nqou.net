use v5.36;
use lib 'lib';
use PasswordLock;

my $lock = PasswordLock->new;
say "クラッキングを開始します...";

for my $i (0 .. 9) {
    for my $j (0 .. 9) {
        for my $k (0 .. 9) {
            my $attempt = "$i$j$k";
            if ($lock->unlock($attempt)) {
                say "解除成功！ パスワードは [ $attempt ] です！";
                exit;
            }
        }
    }
}
say "パスワードが見つかりませんでした...";
