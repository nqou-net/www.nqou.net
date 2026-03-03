package ClothCraft::Expression;
use v5.36;
use Carp qw(croak);

# Interpreter パターン: Expression 基底クラス
# すべての式ノードはこのクラスを継承し、interpret() を実装する

sub new ($class, %args) {
    return bless \%args, $class;
}

sub interpret ($self, $context) {
    croak ref($self) . '::interpret() is not implemented';
}

1;
