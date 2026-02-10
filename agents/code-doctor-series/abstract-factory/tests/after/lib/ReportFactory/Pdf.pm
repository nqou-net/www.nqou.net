package ReportFactory::Pdf {
    use v5.36;
    use Moo;
    with 'Role::ReportFactory';
    use Report::Pdf::Title;
    use Report::Pdf::Table;
    use Report::Pdf::Footer;

    sub create_title($self)  { Report::Pdf::Title->new }
    sub create_table($self)  { Report::Pdf::Table->new }
    sub create_footer($self) { Report::Pdf::Footer->new }
}

1;
