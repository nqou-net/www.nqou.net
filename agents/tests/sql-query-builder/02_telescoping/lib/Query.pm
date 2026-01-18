package Query;
use v5.36;
use Moo;

has table         => (is => 'ro', required => 1);
has where_column  => (is => 'ro');
has where_value   => (is => 'ro');
has order_column  => (is => 'ro');
has order_dir     => (is => 'ro', default => 'ASC');
has limit_count   => (is => 'ro');
has offset_count  => (is => 'ro');

sub to_sql ($self) {
    my $sql = "SELECT * FROM " . $self->table;
    
    if ($self->where_column && defined $self->where_value) {
        $sql .= " WHERE " . $self->where_column . " = '" . $self->where_value . "'";
    }
    
    if ($self->order_column) {
        $sql .= " ORDER BY " . $self->order_column . " " . $self->order_dir;
    }
    
    if ($self->limit_count) {
        $sql .= " LIMIT " . $self->limit_count;
        if ($self->offset_count) {
            $sql .= " OFFSET " . $self->offset_count;
        }
    }
    
    return $sql;
}

1;
