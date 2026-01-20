package TOCParser;
use v5.36;
use Moo;
use JSON::PP;
use lib '.';
use SectionHeading;
use LeafHeading;

has 'headings' => (
    is       => 'ro',
    required => 1,
);

has 'root' => (
    is      => 'lazy',
    builder => '_build_root',
);

sub _build_root ($self) {
    my $root = SectionHeading->new(
        level => 0,
        text  => 'ROOT',
    );
    
    my @stack = ($root);
    
    for my $h ($self->headings->@*) {
        my $level = $h->{level};
        my $text  = $h->{text};
        
        while (@stack > 1 && $stack[-1]->level >= $level) {
            pop @stack;
        }
        
        my $parent = $stack[-1];
        
        my $new_heading = SectionHeading->new(
            level => $level,
            text  => $text,
        );
        
        $parent->add_child($new_heading);
        push @stack, $new_heading;
    }
    
    return $root;
}

sub render ($self, $format = 'markdown') {
    if ($format eq 'json') {
        my @data = map { $_->render(0, 'json') } $self->root->children->@*;
        return JSON::PP->new->pretty->encode(\@data);
    }
    
    my @lines;
    
    if ($format eq 'html') {
        push @lines, '<ul>';
    }
    
    for my $child ($self->root->children->@*) {
        push @lines, $child->render($format eq 'html' ? 1 : 0, $format);
    }
    
    if ($format eq 'html') {
        push @lines, '</ul>';
    }
    
    return join("\n", @lines);
}

1;
