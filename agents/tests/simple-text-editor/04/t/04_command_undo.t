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

my $editor = Editor->new;
my $insert = InsertCommand->new(
    editor   => $editor,
    position => 0,
    string   => 'Hello',
);
$insert->execute;
is $editor->text, 'Hello', 'insert execute works';
$insert->undo;
is $editor->text, '', 'insert undo removes text';

$editor->text('Hello World');
my $delete = DeleteCommand->new(
    editor   => $editor,
    position => 5,
    length   => 6,
);
$delete->execute;
is $editor->text, 'Hello', 'delete execute works';
$delete->undo;
is $editor->text, 'Hello World', 'delete undo restores text';

my $history_editor = Editor->new;
my @history;
for my $value (['A', 0], ['B', 1], ['C', 2]) {
    my ($string, $pos) = @$value;
    my $cmd = InsertCommand->new(
        editor   => $history_editor,
        position => $pos,
        string   => $string,
    );
    $cmd->execute;
    push @history, $cmd;
}
is $history_editor->text, 'ABC', 'history executes commands';

while (my $cmd = pop @history) {
    $cmd->undo;
}

is $history_editor->text, '', 'undo history returns to empty';

is scalar @warnings, 0, 'no warnings';

done_testing;
