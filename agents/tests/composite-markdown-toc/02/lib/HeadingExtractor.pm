package HeadingExtractor;
use v5.36;
use Moo;

has 'lines' => (
    is       => 'ro',
    required => 1,
);

has 'headings' => (
    is      => 'lazy',
    builder => '_build_headings',
);

sub _build_headings ($self) {
    my @headings;
    
    for my $line ($self->lines->@*) {
        if ($line =~ /^(#{1,6})\s+(.+)$/) {
            my $level = length($1);
            my $text  = $2;
            push @headings, {
                level => $level,
                text  => $text,
            };
        }
    }
    
    return \@headings;
}

sub heading_count ($self) {
    return scalar $self->headings->@*;
}

1;
