package WhiskySourceRole;

# 第3回: Adapterでデータソースを統一
# WhiskySourceRole.pm - 統一インターフェース（Role）

use v5.36;
use warnings;
use Moo::Role;

# 統一インターフェース: すべてのAdapter が実装するメソッド
requires 'get_whisky';     # id を指定して1つ取得
requires 'get_all';        # 全件取得
requires 'source_name';    # データソース名

# 共通のデータ構造を返す
# $whisky = {
#     id     => 文字列,
#     name   => 銘柄名,
#     region => 産地,
#     age    => 熟成年数,
#     abv    => アルコール度数,
#     nose   => 香りのノート,
#     palate => 味わいのノート,
#     finish => 余韻のノート,
#     rating => 評価（100点満点）,
# }

1;

__END__

=head1 NAME

WhiskySourceRole - ウイスキーデータソースの統一インターフェース

=head1 SYNOPSIS

    package MyAdapter;
    use Moo;
    with 'WhiskySourceRole';
    
    sub get_whisky($self, $id) { ... }
    sub get_all($self) { ... }
    sub source_name($self) { 'MySource' }

=head1 DESCRIPTION

Adapterパターンにおける統一インターフェースを定義するRole。
CSV、JSON、外部APIなど、異なるデータソースはこのRoleを
実装することで、同じインターフェースで扱えるようになる。

=cut
