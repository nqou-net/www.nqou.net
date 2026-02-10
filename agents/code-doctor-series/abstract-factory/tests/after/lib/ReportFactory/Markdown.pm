package ReportFactory::Markdown {
    use v5.36;
    use Moo;
    with 'Role::ReportFactory';
    use Report::Markdown::Title;
    use Report::Markdown::Table;
    use Report::Markdown::Footer;

    sub create_title($self)  { Report::Markdown::Title->new }
    sub create_table($self)  { Report::Markdown::Table->new }
    sub create_footer($self) { Report::Markdown::Footer->new }
}

1;
