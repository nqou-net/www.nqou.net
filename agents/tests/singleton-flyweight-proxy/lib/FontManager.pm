package FontManager;
use v5.34;
use feature qw(signatures);
no warnings qw(experimental::signatures);
use warnings;
use Moo;

# Singletonパターン: 設定を一元管理するクラス

# クラス変数としてインスタンスを保持
my $_instance;

# 設定項目
has font_path => (
    is      => 'rw',
    default => '/usr/share/fonts/ascii/standard.fnt',
);

has default_style => (
    is      => 'rw',
    default => 'bold',
);

has char_spacing => (
    is      => 'rw',
    default => 1,
);

has line_height => (
    is      => 'rw',
    default => 1,
);

# Singletonアクセサ: インスタンスを取得
sub instance($class = __PACKAGE__) {
    $_instance //= $class->new;
    return $_instance;
}

# テスト用: インスタンスをリセット
sub reset_instance($class = __PACKAGE__) {
    $_instance = undef;
}

# 設定の概要を表示
sub show_config($self) {
    say "=== FontManager 設定 ===";
    say "  フォントパス: " . $self->font_path;
    say "  デフォルトスタイル: " . $self->default_style;
    say "  文字間隔: " . $self->char_spacing;
    say "  行間: " . $self->line_height;
}

1;
