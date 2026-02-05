package External::ComplexSystem;
use v5.36;

sub new ($class) {
    return bless {}, $class;
}

sub initialize_subsystem ($self) {

    # 実際にはここで重い初期化処理が走る
    # say "Initializing subsystem...";
    return 1;
}

sub set_config_param ($self, $key, $val) {
    $self->{config}{$key} = $val;
}

sub authenticate_user ($self, $user) {
    unless ($user) {
        die "Authentication failed: No user provided";
    }

    # say "User $user authenticated.";
    return "token_123";
}

sub establish_connection ($self, $token) {
    unless ($token eq 'token_123') {
        die "Connection refused: Invalid token";
    }

    # say "Connection established.";
    return 1;
}

sub create_transaction ($self) {
    return bless {id => int(rand(10000))}, 'External::Transaction';
}

package External::Transaction;
use v5.36;

sub add_item ($self, $item) {
    push @{$self->{items}}, $item;
}

sub commit ($self) {
    unless (@{$self->{items}}) {
        die "Transaction empty!";
    }

    # say "Transaction committed: " . join(", ", @{$self->{items}});
    return 1;
}

1;
