package ImageProxy;

# 第7回: Proxyで遅延・キャッシュ・制御
# ImageProxy.pm - 遅延ロードProxy

use v5.36;
use warnings;
use Moo;

# 本物の画像データ（重い処理）
has real_image => (
    is      => 'lazy',
    builder => '_load_real_image',
);

has id        => (is => 'ro', required => 1);
has filename  => (is => 'ro', required => 1);
has '_loaded' => (is => 'rw', default  => 0);

sub _load_real_image($self) {
    say "  [Proxy] 画像を遅延ロード中: $self->{filename}";
    sleep 1;    # 重い処理をシミュレート
    $self->_loaded(1);
    return "IMAGE_DATA_FOR_$self->{id}";
}

# サムネイル表示（軽い処理）- 本物はロードしない
sub show_thumbnail($self) {
    say "  [Proxy] サムネイル表示: $self->{filename} (本物は未ロード)";
    return "THUMBNAIL_$self->{id}";
}

# 実際のデータが必要な時だけロード
sub get_data($self) {
    return $self->real_image;    # lazyにより初回アクセス時のみロード
}

sub is_loaded($self) {
    return $self->_loaded;
}

1;

__END__

=head1 NAME

ImageProxy - 画像の遅延ロードProxy

=head1 DESCRIPTION

Proxyパターンで画像データの遅延ロードを実現。
サムネイル表示など軽い処理では本物をロードせず、
実際のデータが必要な時に初めてロードする。

=cut
