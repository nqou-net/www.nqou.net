package Report::Html::Table {
    use v5.36;
    use Moo;
    with 'Role::ReportTable';

    sub render($self, $rows) {
        my $out = "<table>\n";
        for my $row ($rows->@*) {
            $out .= "<tr>" . join('', map { "<td>$_</td>" } $row->@*) . "</tr>\n";
        }
        $out .= "</table>\n";
        return $out;
    }
}

1;
