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
    string   => 'foo foo foo',
));

is $editor->text, 'foo foo foo', 'initial text inserted';

my $macro = MacroCommand->new;
$macro->add_command(InsertCommand->new(
    editor   => $editor,
    position => 0,
    string   => 'bar',
));
$macro->add_command(InsertCommand->new(
    editor   => $editor,
    position => 7,
    string   => 'bar',
));
$macro->add_command(InsertCommand->new(
    editor   => $editor,
    position => 14,
    string   => 'bar',
));

$history->execute_command($macro);
is $editor->text, 'barfoo barfoo barfoo', 'macro executes all commands';

$history->undo;
is $editor->text, 'foo foo foo', 'macro undo restores original';

$history->redo;
is $editor->text, 'barfoo barfoo barfoo', 'macro redo reapplies changes';

is scalar @warnings, 0, 'no warnings';

done_testing;
