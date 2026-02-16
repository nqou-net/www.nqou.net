package ReportFormatter::HTML;
use v5.36;
use parent 'ReportFormatter';

sub render_header ($self, $title) {
    return "<html><body><h1>${title}</h1>\n<table>\n";
}

sub render_row ($self, $label, $value) {
    return "<tr><th>$label</th><td>$value</td></tr>\n";
}

sub render_footer ($self) {
    return "</table>\n</body></html>\n";
}

1;
