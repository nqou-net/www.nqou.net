package FontProxy;
use v5.34;
use feature qw(signatures);
no warnings qw(experimental::signatures);
use warnings;
use Moo;
use RealFont;

# Proxyパターン: フォントへのアクセスを制御し、遅延ロードを実現

has char       => (is => 'ro', required => 1);
has _real_font => (is => 'rw');

# RealFontへの参照を遅延生成
sub _get_real_font($self) {
    unless ($self->_real_font) {
        $self->_real_font(RealFont->new(char => $self->char));
    }
    return $self->_real_font;
}

# RealFontの操作を委譲（実際のデータアクセス時にロード）
sub get_art($self) {
    return $self->_get_real_font->get_art;
}

sub get_lines($self) {
    return $self->_get_real_font->get_lines;
}

sub is_loaded($self) {
    return $self->_real_font && $self->_real_font->is_loaded;
}

1;
