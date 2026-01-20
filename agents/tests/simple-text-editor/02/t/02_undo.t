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
$editor->insert(0, 'Hello');
$editor->insert(5, ' World');
$editor->delete(5, 6);
$editor->undo;
is $editor->text, 'Hello World', 'undo restores previous text once';

my $multi = Editor->new;
$multi->insert(0, 'A');
$multi->insert(1, 'B');
$multi->insert(2, 'C');
$multi->undo;
is $multi->text, 'AB', 'first undo returns to previous state';
$multi->undo;
is $multi->text, 'AB', 'second undo does not return to A (intended limitation)';

is scalar @warnings, 0, 'no warnings';

done_testing;
