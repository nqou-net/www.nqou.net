use v5.36;
use Test::More;

BEGIN {
    eval { require Moo; 1 } or plan skip_all => q{Moo not installed};
}
use FindBin;
use lib "$FindBin::Bin/../lib";

require 'TextEditor.pm';

sub capture ($code, $input) {
    my $output = '';
    my $error  = '';

    open my $in, '<', \$input or die $!;
    open my $out, '>', \$output or die $!;
    open my $err, '>', \$error or die $!;

    local *STDIN  = $in;
    local *STDOUT = $out;
    local *STDERR = $err;

    $code->();

    return ($output, $error);
}

my @warnings;
local $SIG{__WARN__} = sub { push @warnings, @_ };

my $editor  = Editor->new;
my $history = History->new;

my ($output, $error) = capture(sub { do_insert($editor, $history) }, "100\n");
like $output, qr/エラー: 位置は0〜0の範囲で指定してください/, 'insert validates position';
is $editor->text, '', 'invalid insert leaves text unchanged';

($output, $error) = capture(sub { do_insert($editor, $history) }, "0\nHello\n");
like $output, qr/テキスト: 'Hello'/, 'insert writes text';
is $editor->text, 'Hello', 'valid insert updates editor';

($output, $error) = capture(sub { do_undo($editor, $history) }, "");
like $output, qr/Undo実行/, 'undo reports execution';
is $editor->text, '', 'undo restores empty text';

($output, $error) = capture(sub { do_redo($editor, $history) }, "");
like $output, qr/Redo実行/, 'redo reports execution';
is $editor->text, 'Hello', 'redo restores text';

my $empty_editor  = Editor->new;
my $empty_history = History->new;
($output, $error) = capture(sub { do_delete($empty_editor, $empty_history) }, "");
like $output, qr/エラー: テキストが空です/, 'delete detects empty text';

my ($main_output, $main_error) = capture(sub { main() }, "p\nq\n");
like $main_output, qr/=== 簡易テキストエディタ ===/, 'main prints header';
like $main_output, qr/テキスト: ''/, 'main handles print command';
like $main_output, qr/終了します。/, 'main exits on quit';

is $main_error, '', 'main has no stderr output';
is scalar @warnings, 0, 'no warnings';

done_testing;
