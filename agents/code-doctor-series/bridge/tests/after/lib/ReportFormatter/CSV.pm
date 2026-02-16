package ReportFormatter::CSV;
use v5.36;
use parent 'ReportFormatter';

sub render_header ($self, $title) {
    return "";    # CSV ではヘッダ行はデータ行で代用
}

sub render_row ($self, $label, $value) {
    return "$label,$value\n";
}

sub render_footer ($self) {
    return "";
}

1;
