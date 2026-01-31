package Glyph;
use v5.34;
use feature qw(signatures);
no warnings qw(experimental::signatures);
use warnings;
use Moo;

# Flyweightパターン: 共有される内部状態(intrinsic state)
has char => (is => 'ro', required => 1);
has art  => (is => 'ro', required => 1);

# 描画メソッド
sub render($self) {
    return $self->art;
}

sub get_lines($self) {
    return split /\n/, $self->art;
}

1;
