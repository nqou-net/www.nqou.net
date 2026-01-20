package MarkdownReader;
use v5.36;
use Moo;

has 'filepath' => (
    is       => 'ro',
    required => 1,
);

has 'lines' => (
    is      => 'lazy',
    builder => '_build_lines',
);

sub _build_lines ($self) {
    my @lines;
    open my $fh, '<:utf8', $self->filepath
        or die "Cannot open file: $!";
    while (my $line = <$fh>) {
        chomp $line;
        push @lines, $line;
    }
    close $fh;
    return \@lines;
}

sub line_count ($self) {
    return scalar $self->lines->@*;
}

1;
