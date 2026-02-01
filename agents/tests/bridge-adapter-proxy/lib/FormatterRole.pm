package FormatterRole;

# 第5回: Bridgeで出力とスタイルを分離
# FormatterRole.pm - 実装側のRole（スタイル）

use v5.36;
use warnings;
use Moo::Role;

# 実装側（Implementor）の統一インターフェース
requires 'format_name';      # スタイル名
requires 'format_title';     # 銘柄名のフォーマット
requires 'format_basic';     # 基本情報のフォーマット（産地、熟成年、度数）
requires 'format_notes';     # テイスティングノートのフォーマット
requires 'format_rating';    # 評価のフォーマット

1;

__END__

=head1 NAME

FormatterRole - テイスティングノートのスタイル（実装側）

=head1 DESCRIPTION

Bridgeパターンにおける「実装側」のRole。
Simple/Detailed/Proなどのスタイルごとに、
どのような情報をどこまで表示するかを定義する。

抽象側（NoteAbstraction）と組み合わせることで、
出力形式×スタイルのすべての組み合わせを実現。

=cut
