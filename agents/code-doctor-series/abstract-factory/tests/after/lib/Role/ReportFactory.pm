package Role::ReportFactory {
    use v5.36;
    use Moo::Role;
    requires 'create_title';
    requires 'create_table';
    requires 'create_footer';
}

1;
