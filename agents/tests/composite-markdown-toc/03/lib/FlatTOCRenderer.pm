package FlatTOCRenderer;
use v5.36;
use Moo;

has 'headings' => (
    is       => 'ro',
    required => 1,
);

has 'indent_size' => (
    is      => 'ro',
    default => 2,
);

sub render ($self) {
    my @lines;
    
    for my $h ($self->headings->@*) {
        my $indent = ' ' x (($h->{level} - 1) * $self->indent_size);
        my $marker = '- ';
        push @lines, $indent . $marker . $h->{text};
    }
    
    return join("\n", @lines);
}

1;
