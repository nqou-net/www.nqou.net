package MarkdownNote;

# 第5回: Bridgeで出力とスタイルを分離
# MarkdownNote.pm - Markdown形式の出力

use v5.36;
use warnings;
use Moo;

extends 'NoteAbstraction';

sub render($self, $whisky) {
    my $title  = $self->_get_title($whisky);
    my $basic  = $self->_get_basic($whisky);
    my $notes  = $self->_get_notes($whisky);
    my $rating = $self->_get_rating($whisky);

    my $output = "## $title\n\n";
    $output .= "$basic\n\n" if $basic;

    if ($notes) {
        $notes =~ s/^/- /gm;
        $output .= "$notes\n\n";
    }

    $output .= "**$rating**\n" if $rating;

    return $output;
}

1;
