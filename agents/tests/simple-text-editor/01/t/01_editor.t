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
is $editor->text, 'Hello', 'insert adds text';

$editor->insert(5, ' World');
is $editor->text, 'Hello World', 'insert appends text';

$editor->delete(5, 6);
is $editor->text, 'Hello', 'delete removes text';

is scalar @warnings, 0, 'no warnings';

done_testing;
