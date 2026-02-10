package Report::Markdown::Title {
    use v5.36;
    use Moo;
    with 'Role::ReportTitle';

    sub render($self, $text) {
        return "# $text\n\n";
    }
}

1;
