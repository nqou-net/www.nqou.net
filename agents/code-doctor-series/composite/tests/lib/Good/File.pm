package Good::File;
use v5.36;
use Role::Tiny::With;
with 'Good::Component';

sub new ($class, %args) {
    bless {name => $args{name}}, $class;
}

sub name ($self) { $self->{name} }

sub backup ($self, $path) {

    # Leafの処理: 自身のバックアップのみ
    return ["Copying file " . $self->name . " to $path"];
}

1;
