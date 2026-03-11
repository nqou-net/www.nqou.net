package After::OrderContext;
use Moo;
use Types::Standard qw(Int Str Optional);

# 常に一緒にいるデータ群（Data Clumps）をクラスにまとめる
has user_id       => (is => 'ro', isa => Int, required => 1);
has shop_id       => (is => 'ro', isa => Int, required => 1);
has item_id       => (is => 'ro', isa => Int, required => 1);
has amount        => (is => 'ro', isa => Int, required => 1);
has campaign_code => (is => 'ro', isa => Optional[Str]);
has auth_token    => (is => 'ro', isa => Str, required => 1);

1;
