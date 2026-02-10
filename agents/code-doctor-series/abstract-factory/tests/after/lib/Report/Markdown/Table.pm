package Report::Markdown::Table {
    use v5.36;
    use Moo;
    with 'Role::ReportTable';

    sub render($self, $rows) {
        my $out   = '';
        my $first = 1;
        for my $row ($rows->@*) {
            $out .= "| " . join(' | ', $row->@*) . " |\n";
            if ($first) {
                $out .= "| " . join(' | ', map { "---" } $row->@*) . " |\n";
                $first = 0;
            }
        }
        $out .= "\n";
        return $out;
    }
}

1;
