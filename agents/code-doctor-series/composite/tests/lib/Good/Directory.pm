package Good::Directory;
use v5.36;
use Role::Tiny::With;
with 'Good::Component';

sub new ($class, %args) {
    bless {name => $args{name}, children => []}, $class;
}

sub name ($self) { $self->{name} }

sub add ($self, $component) {

    # Type check could be here, but we trust the interface in this simplified example
    push @{$self->{children}}, $component;
}

sub backup ($self, $path) {
    my $my_path = "$path/" . $self->name;
    my @logs;

    # 自身の処理
    push @logs, "Creating directory " . $self->name . " at $path";

    # 子要素への委譲 (再帰)
    # FileもDirectoryも同じ 'backup' メソッドを持っているので
    # 条件分岐が不要になる (ここがCompositeの肝)
    foreach my $child (@{$self->{children}}) {
        push @logs, @{$child->backup($my_path)};
    }

    return \@logs;
}

1;
