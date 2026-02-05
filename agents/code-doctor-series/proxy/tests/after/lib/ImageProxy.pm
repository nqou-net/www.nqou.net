package ImageProxy;
use v5.36;
use parent 'ImageInterface';
use RealImage;

# 画像プロキシ（Proxy）
# 遅延読み込みとアクセス制御を担当

sub new($class, $filepath) {
    my $self = bless {
        filepath   => $filepath,
        real_image => undef,       # 必要になるまでnull
    }, $class;

    # ここではファイル読み込みをしない！
    $self->_log_access("thumbnail_request");

    return $self;
}

sub _log_access($self, $action) {

    # アクセスログを一元管理
    say "[LOG] $action: $self->{filepath}";
}

sub _ensure_loaded($self) {

    # 遅延読み込み：必要になって初めてRealImageを生成
    unless ($self->{real_image}) {
        $self->_log_access("full_load");
        $self->{real_image} = RealImage->new($self->{filepath});
    }
}

sub get_thumbnail($self) {

    # サムネイルはプレースホルダーを返す
    # 本番では軽量なサムネイル画像パスを返すなど
    return "[Thumbnail: $self->{filepath}]";
}

sub display($self) {

    # フル表示が必要になって初めて実際の画像を読み込む
    $self->_ensure_loaded();
    return $self->{real_image}->display();
}

1;
