package RecipeComponent;
use v5.36;
use Carp qw(croak);

sub new ($class, %args) {
    croak "name is required" unless $args{name};
    return bless {name => $args{name}}, $class;
}

sub name ($self) { $self->{name} }

# 共通インターフェース: サブクラスでオーバーライド
sub calculate ($self)              { croak ref($self) . "::calculate not implemented" }
sub display   ($self, $indent = 0) { croak ref($self) . "::display not implemented" }

1;
