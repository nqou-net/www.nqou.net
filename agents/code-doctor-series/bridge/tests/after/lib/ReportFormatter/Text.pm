package ReportFormatter::Text;
use v5.36;
use parent 'ReportFormatter';

sub render_header ($self, $title) {
    return "=== $title ===\n";
}

sub render_row ($self, $label, $value) {
    return sprintf("%-12s %s\n", "$label:", $value);
}

sub render_footer ($self) {
    return "";
}

1;
