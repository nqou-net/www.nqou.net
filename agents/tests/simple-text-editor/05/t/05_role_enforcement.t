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
$insert->undo;
is $editor->text, '', 'command role still executes and undoes';

$editor->text('Hello World');
my $delete = DeleteCommand->new(
    editor   => $editor,
    position => 5,
    length   => 6,
);
$delete->execute;
$delete->undo;
is $editor->text, 'Hello World', 'delete undo restores text';

my $error = eval q{
    package BrokenCommand;
    use Moo;
    with 'Command::Role';

    has editor => (is => 'ro', required => 1);

    sub execute ($self) {
        return;
    }
    1;
} // '';

like $@, qr/missing undo/i, 'missing undo method triggers compile-time error';

is scalar @warnings, 0, 'no warnings';

done_testing;
