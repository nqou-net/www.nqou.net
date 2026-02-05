package RealImage;
use v5.36;
use parent 'ImageInterface';

# 実際の画像クラス（RealSubject）
# 重いファイル読み込みを担当

sub new($class, $filepath) {
    my $self = bless {
        filepath => $filepath,
        data     => undef,
    }, $class;

    # 生成時にファイル読み込み
    $self->_load_file();

    return $self;
}

sub _load_file($self) {
    say "Loading full image: $self->{filepath}";
    $self->{data} = "FULL_IMAGE_DATA_OF_$self->{filepath}";
}

sub get_thumbnail($self) {
    return substr($self->{data}, 0, 20) . "...";
}

sub display($self) {
    return $self->{data};
}

1;
