package Report::Pdf::Table {
    use v5.36;
    use Moo;
    with 'Role::ReportTable';

    sub render($self, $rows) {
        my $cols = scalar $rows->[0]->@*;
        my $spec = join('|', map { "c" } 1..$cols);
        my $out  = "\\begin{tabular}{|${spec}|}\n";
        for my $row ($rows->@*) {
            $out .= join(' & ', $row->@*) . " \\\\\n";
        }
        $out .= "\\end{tabular}\n\n";
        return $out;
    }
}

1;
