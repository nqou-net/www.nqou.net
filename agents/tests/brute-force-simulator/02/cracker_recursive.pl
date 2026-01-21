use v5.36;
use lib 'lib';
use PasswordLock;

my $target_length = 4;
my $lock = PasswordLock->new;

sub brute_force ($current_string) {
    if (length($current_string) == $target_length) {
        if ($lock->unlock($current_string)) {
            say "解除成功！ パスワードは [ $current_string ] です！";
            exit;
        }
        return;
    }

    for my $i (0 .. 9) {
        brute_force($current_string . $i);
    }
}

say "クラッキングを開始します（長さ: $target_length）...";
brute_force("");
say "見つかりませんでした。";
