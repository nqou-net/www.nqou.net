package RealFont;
use v5.34;
use feature qw(signatures);
no warnings qw(experimental::signatures);
use warnings;
use Moo;
use Time::HiRes qw(time);

# 実際のフォントデータを保持するクラス（重い処理）

has char      => (is => 'ro', required => 1);
has _data     => (is => 'rw');
has _loaded   => (is => 'rw', default => 0);
has load_time => (is => 'rw');

# フォントデータのマスター定義
my %FONT_DATA = (
    A   => " AAA\nA   A\nAAAAA\nA   A\nA   A",
    B   => "BBBB\nB   B\nBBBB\nB   B\nBBBB",
    C   => " CCC\nC\nC\nC\n CCC",
    D   => "DDD\nD  D\nD  D\nD  D\nDDD",
    E   => "EEEEE\nE\nEEE\nE\nEEEEE",
    F   => "FFFFF\nF\nFFF\nF\nF",
    G   => " GGG\nG\nG GG\nG  G\n GGG",
    H   => "H   H\nH   H\nHHHHH\nH   H\nH   H",
    I   => "IIIII\n  I\n  I\n  I\nIIIII",
    J   => "JJJJJ\n   J\n   J\nJ  J\n JJ",
    K   => "K  K\nK K\nKK\nK K\nK  K",
    L   => "L\nL\nL\nL\nLLLLL",
    M   => "M   M\nMM MM\nM M M\nM   M\nM   M",
    N   => "N   N\nNN  N\nN N N\nN  NN\nN   N",
    O   => " OOO\nO   O\nO   O\nO   O\n OOO",
    P   => "PPPP\nP   P\nPPPP\nP\nP",
    Q   => " QQQ\nQ   Q\nQ Q Q\nQ  Q\n QQ Q",
    R   => "RRRR\nR   R\nRRRR\nR R\nR  R",
    S   => " SSS\nS\n SSS\n   S\nSSS",
    T   => "TTTTT\n  T\n  T\n  T\n  T",
    U   => "U   U\nU   U\nU   U\nU   U\n UUU",
    V   => "V   V\nV   V\nV   V\n V V\n  V",
    W   => "W   W\nW   W\nW W W\nWW WW\nW   W",
    X   => "X   X\n X X\n  X\n X X\nX   X",
    Y   => "Y   Y\n Y Y\n  Y\n  Y\n  Y",
    Z   => "ZZZZZ\n   Z\n  Z\n Z\nZZZZZ",
    ' ' => "     \n     \n     \n     \n     ",
);

# 遅延ロード: 実際に必要になったときにロード
sub _load($self) {
    return if $self->_loaded;

    my $start = time();

    # 重いロード処理をシミュレート
    select(undef, undef, undef, 0.01);    # 10ms

    my $data = $FONT_DATA{$self->char} // "  ?\n  ?\n  ?\n  ?\n  ?";
    $self->_data($data);
    $self->_loaded(1);
    $self->load_time(time() - $start);
}

sub get_art($self) {
    $self->_load;
    return $self->_data;
}

sub get_lines($self) {
    return split /\n/, $self->get_art;
}

sub is_loaded($self) {
    return $self->_loaded;
}

1;
