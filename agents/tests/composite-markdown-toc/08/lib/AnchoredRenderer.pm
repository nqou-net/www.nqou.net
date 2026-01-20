package AnchoredRenderer;
use v5.36;
use Moo;

has 'root' => (
    is       => 'ro',
    required => 1,
);

sub render ($self) {
    my @lines;
    for my $child ($self->root->children->@*) {
        push @lines, $self->_render_node($child, 0);
    }
    return join("\n", @lines);
}

sub _render_node ($self, $node, $indent) {
    my $spaces = '  ' x $indent;
    my $anchor = $self->_text_to_anchor($node->text);
    my $link   = "[$node->{text}]($anchor)";
    
    my @lines = ($spaces . '- ' . $link);
    
    if ($node->can('children') && $node->children->@*) {
        for my $child ($node->children->@*) {
            push @lines, $self->_render_node($child, $indent + 1);
        }
    }
    
    return join("\n", @lines);
}

sub _text_to_anchor ($self, $text) {
    my $anchor = lc($text);
    $anchor =~ s/\s+/-/g;
    $anchor =~ s/[^\w\-\p{Han}\p{Hiragana}\p{Katakana}]//g;
    $anchor =~ s/-+/-/g;
    $anchor =~ s/^-|-$//g;
    return "#$anchor";
}

1;
