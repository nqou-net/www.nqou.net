package Report::Pdf::Title {
    use v5.36;
    use Moo;
    with 'Role::ReportTitle';

    sub render($self, $text) {
        return "\\textbf{\\Large $text}\n\n";
    }
}

1;
