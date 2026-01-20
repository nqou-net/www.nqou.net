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

my $cmd1 = InsertCommand->new(
    editor   => $editor,
    position => 0,
    string   => 'Hello',
);
$cmd1->execute;
is $editor->text, 'Hello', 'execute inserts text';

my $cmd2 = InsertCommand->new(
    editor   => $editor,
    position => 5,
    string   => ' World',
);
$cmd2->execute;
is $editor->text, 'Hello World', 'second command appends text';

my @history = ($cmd1, $cmd2);
is $history[0]->position, 0, 'history keeps first position';
is $history[1]->string, ' World', 'history keeps second string';

is scalar @warnings, 0, 'no warnings';

done_testing;
