package ImageInterface;
use v5.36;

# 画像インターフェース（Subjectロール）
# RealImageとImageProxyの共通インターフェース

sub new($class, @args) {
    die "ImageInterface is abstract";
}

sub get_thumbnail($self) {
    die "get_thumbnail must be implemented";
}

sub display($self) {
    die "display must be implemented";
}

1;
