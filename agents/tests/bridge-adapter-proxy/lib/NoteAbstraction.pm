package NoteAbstraction;

# 第5回: Bridgeで出力とスタイルを分離
# NoteAbstraction.pm - 抽象側の基底クラス

use v5.36;
use warnings;
use Moo;

# Implementor（スタイル）への参照
has formatter => (
    is       => 'ro',
    required => 1,

    # FormatterRoleを実装しているオブジェクト
);

# 抽象側のインターフェース（サブクラスで実装）
sub render($self, $whisky) {
    die "render() must be implemented by subclass";
}

# 共通のレンダリングロジックを呼び出すヘルパー
sub _get_title($self, $whisky) {
    return $self->formatter->format_title($whisky);
}

sub _get_basic($self, $whisky) {
    return $self->formatter->format_basic($whisky);
}

sub _get_notes($self, $whisky) {
    return $self->formatter->format_notes($whisky);
}

sub _get_rating($self, $whisky) {
    return $self->formatter->format_rating($whisky);
}

1;

__END__

=head1 NAME

NoteAbstraction - Bridgeパターンの抽象側基底クラス

=head1 DESCRIPTION

出力形式（Text/HTML/Markdown）を担当する抽象側の基底クラス。
Formatterオブジェクト（実装側）を保持し、render()でウイスキー情報を出力形式に変換。

3つの出力形式 + 3つのスタイル = 9パターンを
6クラス（3抽象 + 3実装）で実現。

=cut
