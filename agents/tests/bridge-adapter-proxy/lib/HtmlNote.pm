package HtmlNote;

# 第5回: Bridgeで出力とスタイルを分離
# HtmlNote.pm - HTML形式の出力

use v5.36;
use warnings;
use Moo;

extends 'NoteAbstraction';

sub render($self, $whisky) {
    my $title  = $self->_get_title($whisky);
    my $basic  = $self->_get_basic($whisky);
    my $notes  = $self->_get_notes($whisky);
    my $rating = $self->_get_rating($whisky);

    my $output = "<article>\n";
    $output .= "  <h2>$title</h2>\n";
    $output .= "  <p class=\"basic\">$basic</p>\n" if $basic;

    if ($notes) {
        $notes =~ s/\n/<br>\n    /g;
        $output .= "  <div class=\"notes\">\n    $notes\n  </div>\n";
    }

    $output .= "  <p class=\"rating\">$rating</p>\n" if $rating;
    $output .= "</article>";

    return $output;
}

1;
