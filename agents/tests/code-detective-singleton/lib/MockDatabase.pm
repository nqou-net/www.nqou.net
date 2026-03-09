package MockDatabase;
use Moo;

has mock_data => (
    is      => 'ro',
    default => sub { {} },
);

sub fetch_user_data {
    my ($self, $user_id) = @_;
    return $self->mock_data->{$user_id} || { name => "Mock User" };
}

1;
