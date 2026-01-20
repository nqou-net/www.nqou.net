package HierarchicalTOCRenderer;
use v5.36;
use Moo;

# 第4回: 意図的な「失敗」コード - 複雑な条件分岐でHTML生成を試みる

has 'headings' => (
    is       => 'ro',
    required => 1,
);

sub render ($self) {
    my @output;
    my $prev_level = 0;
    
    for my $h ($self->headings->@*) {
        my $level = $h->{level};
        my $text  = $h->{text};
        
        if ($level > $prev_level) {
            for my $i (1 .. ($level - $prev_level)) {
                push @output, "<ul>";
            }
        } elsif ($level < $prev_level) {
            for my $i (1 .. ($prev_level - $level)) {
                push @output, "</li>";
                push @output, "</ul>";
            }
        } else {
            if ($prev_level > 0) {
                push @output, "</li>";
            }
        }
        
        push @output, "<li>$text";
        $prev_level = $level;
    }
    
    for my $i (1 .. $prev_level) {
        push @output, "</li>";
        push @output, "</ul>";
    }
    
    return join("\n", @output);
}

1;
