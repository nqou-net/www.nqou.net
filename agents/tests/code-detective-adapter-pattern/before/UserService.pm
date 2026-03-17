package UserService;
use Moo;

sub get_user_info {
    my ($self, $id) = @_;
    return { id => $id, name => "User $id", email => "user${id}\@example.com" };
}

1;
