package MockDB;
use v5.36;

sub new ($class, %args) {
    return bless {
        data => $args{data} // {},
    }, $class;
}

sub fetch_all ($self, $table_name) {
    my $rows = $self->{data}{$table_name} // [];
    return map { +{ $_->%* } } $rows->@*;  # deep copy
}

1;
