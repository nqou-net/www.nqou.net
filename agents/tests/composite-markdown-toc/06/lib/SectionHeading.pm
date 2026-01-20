package SectionHeading;
use v5.36;
use Moo;
use JSON::PP;

with 'Heading';

has 'level' => (
    is       => 'ro',
    required => 1,
);

has 'text' => (
    is       => 'ro',
    required => 1,
);

has 'children' => (
    is      => 'ro',
    default => sub { [] },
);

sub add_child ($self, $child) {
    push $self->children->@*, $child;
    return $self;
}

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
    my @lines = ($spaces . '- ' . $self->text);
    
    for my $child ($self->children->@*) {
        push @lines, $child->render($indent + 1, 'markdown');
    }
    
    return join("\n", @lines);
}

sub _render_html ($self, $indent) {
    my $spaces = '  ' x $indent;
    my @lines;
    
    push @lines, "$spaces<li>" . $self->text;
    
    if ($self->children->@*) {
        push @lines, "$spaces  <ul>";
        for my $child ($self->children->@*) {
            push @lines, $child->render($indent + 2, 'html');
        }
        push @lines, "$spaces  </ul>";
    }
    
    push @lines, "$spaces</li>";
    
    return join("\n", @lines);
}

sub _to_hash ($self) {
    return {
        level    => $self->level,
        text     => $self->text,
        children => [map { $_->render(0, 'json') } $self->children->@*],
    };
}

1;
