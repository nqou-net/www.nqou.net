package GlyphFactory;
use v5.34;
use feature qw(signatures);
no warnings qw(experimental::signatures);
use warnings;
use Moo;
use Glyph;

# Flyweightパターン: ファクトリーでオブジェクトを共有管理

# 既に作成したGlyphオブジェクトを保持するプール
has _pool => (
    is      => 'ro',
    default => sub { {} },
);

# フォントデータ
has _font_data => (
    is      => 'ro',
    default => sub {
        return {
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
        };
    },
);

# Glyphを取得（既に存在すれば再利用、なければ新規作成）
sub get_glyph($self, $char) {
    my $key = uc $char;

    # プールに既にあれば再利用
    if (exists $self->_pool->{$key}) {
        return $self->_pool->{$key};
    }

    # 新規作成してプールに保存
    my $art   = $self->_font_data->{$key} // "  ?\n  ?\n  ?\n  ?\n  ?";
    my $glyph = Glyph->new(char => $key, art => $art);
    $self->_pool->{$key} = $glyph;

    return $glyph;
}

# プールの状態を取得
sub pool_size($self) {
    return scalar keys $self->_pool->%*;
}

sub pool_keys($self) {
    return sort keys $self->_pool->%*;
}

1;
