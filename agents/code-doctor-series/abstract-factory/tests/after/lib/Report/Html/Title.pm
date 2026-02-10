package Report::Html::Title {
    use v5.36;
    use Moo;
    with 'Role::ReportTitle';

    sub render($self, $text) {
        return "<h1>$text</h1>\n";
    }
}

1;
