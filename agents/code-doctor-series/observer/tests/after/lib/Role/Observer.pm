package Role::Observer;
use v5.36;

# インターフェースとしての役割
sub update ($self, $subject) {
    die "Subclass must implement 'update' method";
}

1;
