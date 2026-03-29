# OrderFacade — Middle Man の典型例
# 全メソッドが order への委譲のみ。独自ロジックはゼロ。
package OrderFacade;
use v5.36;
use Moo;

has order => (
    is       => 'ro',
    required => 1,
    handles  => [qw(
        shipping_zone
        item_name
        quantity
        unit_price
        total_price
    )],
);

# このクラスには独自のメソッドが一つもない

1;
