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

is $editor->text, 'Hello World', 'commands executed via history';

$history->undo;
is $editor->text, 'Hello', 'undo works';

$history->redo;
is $editor->text, 'Hello World', 'redo works';

my $macro = MacroCommand->new;
$macro->add_command(InsertCommand->new(
    editor   => $editor,
    position => 11,
    string   => '!',
));
$history->execute_command($macro);
is $editor->text, 'Hello World!', 'macro command executes';

$history->undo;
is $editor->text, 'Hello World', 'macro undo works';

is scalar @warnings, 0, 'no warnings';

done_testing;
