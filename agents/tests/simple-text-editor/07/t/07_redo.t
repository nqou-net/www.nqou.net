use v5.36;
use Test::More;

BEGIN {
    eval { require Moo; 1 } or plan skip_all => q{Moo not installed};
}
use FindBin;
use lib "$FindBin::Bin/../lib";

require 'TextEditor.pm';

my @warnings;
local $SIG{__WARN__} = sub { push @warnings, @_ };

my $editor  = Editor->new;
my $history = History->new;

$history->execute_command(InsertCommand->new(
    editor   => $editor,
    position => 0,
    string   => 'Hello',
));
$history->execute_command(InsertCommand->new(
    editor   => $editor,
    position => 5,
    string   => ' World',
));

is $editor->text, 'Hello World', 'execute commands add text';

$history->undo;
is $editor->text, 'Hello', 'undo removes last insert';

$history->redo;
is $editor->text, 'Hello World', 'redo restores insert';

$history->undo;
$history->execute_command(InsertCommand->new(
    editor   => $editor,
    position => 5,
    string   => '!',
));

is scalar $history->redo_stack->@*, 0, 'redo stack cleared after new command';

is scalar @warnings, 0, 'no warnings';

done_testing;
