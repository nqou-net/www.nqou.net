package Query;
use v5.36;
use Moo;

has table => (is => 'ro', required => 1);

sub to_sql ($self) {
    return "SELECT * FROM " . $self->table;
}

1;
