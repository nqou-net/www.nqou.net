package DataExporter::XML;
use v5.36;
use parent 'DataExporter';

# フックメソッドのオーバーライド: XML宣言をヘッダーに
sub _header ($self, $rows) {
    return qq{<?xml version="1.0" encoding="UTF-8"?>\n<records>\n};
}

sub _format ($self, $rows) {
    my $output = '';

    for my $row ($rows->@*) {
        $output .= "  <record>\n";
        for my $key (sort keys $row->%*) {
            my $v = $row->{$key};
            $v =~ s/&/&amp;/g;
            $v =~ s/</&lt;/g;
            $v =~ s/>/&gt;/g;
            $output .= "    <$key>$v</$key>\n";
        }
        $output .= "  </record>\n";
    }

    return $output;
}

# フックメソッドのオーバーライド: 閉じタグをフッターに
sub _footer ($self, $rows) {
    return "</records>\n";
}

1;
