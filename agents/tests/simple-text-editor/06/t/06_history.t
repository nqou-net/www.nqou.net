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

is $editor->text, 'Hello World', 'execute_command updates editor';

$history->undo;
is $editor->text, 'Hello', 'undo removes last command';

$history->undo;
is $editor->text, '', 'undo returns to empty';

is scalar $history->redo_stack->@*, 2, 'redo_stack stores undone commands';

$history->execute_command(InsertCommand->new(
    editor   => $editor,
    position => 0,
    string   => 'Again',
));

is scalar $history->redo_stack->@*, 0, 'redo_stack cleared on new execute';

is scalar @warnings, 0, 'no warnings';

done_testing;
