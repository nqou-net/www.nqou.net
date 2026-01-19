package LogReader;
use Moo;
use strict;
use warnings;
use experimental qw(signatures);
use namespace::clean;

has filename => (
    is       => 'ro',
    required => 1,
);

has _fh => (
    is      => 'rw',
    default => undef,
);

sub BUILD ($self, $args) {
    my $filename = $self->filename;
    open my $fh, '<', $filename or die "Cannot open file $filename: $!";
    $self->_fh($fh);
}

sub next_line ($self) {
    my $fh = $self->_fh;
    return undef unless defined $fh;

    my $line = <$fh>;
    unless (defined $line) {
        close $fh;
        $self->_fh(undef);
        return undef;
    }

    chomp $line;
    return $line;
}

1;
