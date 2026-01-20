package LeafHeading;
use v5.36;
use Moo;

with 'Heading';

has 'level' => (
    is       => 'ro',
    required => 1,
);

has 'text' => (
    is       => 'ro',
    required => 1,
);

sub render ($self, $indent = 0, $format = 'markdown') {
    if ($format eq 'markdown') {
        return $self->_render_markdown($indent);
    } elsif ($format eq 'html') {
        return $self->_render_html($indent);
    } elsif ($format eq 'json') {
        return $self->_to_hash;
    }
    die "Unknown format: $format";
}

sub _render_markdown ($self, $indent) {
    my $spaces = '  ' x $indent;
    return $spaces . '- ' . $self->text;
}

sub _render_html ($self, $indent) {
    my $spaces = '  ' x $indent;
    return "$spaces<li>" . $self->text . "</li>";
}

sub _to_hash ($self) {
    return {
        level => $self->level,
        text  => $self->text,
    };
}

1;
