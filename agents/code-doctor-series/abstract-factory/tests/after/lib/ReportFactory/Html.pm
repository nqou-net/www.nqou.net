package ReportFactory::Html {
    use v5.36;
    use Moo;
    with 'Role::ReportFactory';
    use Report::Html::Title;
    use Report::Html::Table;
    use Report::Html::Footer;

    sub create_title($self)  { Report::Html::Title->new }
    sub create_table($self)  { Report::Html::Table->new }
    sub create_footer($self) { Report::Html::Footer->new }
}

1;
