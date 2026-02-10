package ReportGenerator {
    use v5.36;
    use Moo;

    has factory => (is => 'ro', required => 1);

    sub generate($self, $data) {
        my $title  = $self->factory->create_title;
        my $table  = $self->factory->create_table;
        my $footer = $self->factory->create_footer;

        return join('',
            $title->render($data->{title}),
            $table->render($data->{rows}),
            $footer->render(),
        );
    }
}

1;
