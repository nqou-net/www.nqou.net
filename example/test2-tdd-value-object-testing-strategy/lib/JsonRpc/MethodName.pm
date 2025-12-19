package JsonRpc::MethodName;
use v5.38;
use Moo;

has value => (
    is       => 'ro',
    required => 1,
    isa      => sub {
        my $val = shift;
        
        # undef チェック および 空文字列チェック
        die "method name cannot be empty" unless defined $val && length $val;
        
        # 参照型チェック
        die "method name must be string" if ref $val;

        # 予約語チェック
        die "method name is reserved" if index($val, 'rpc.') == 0;
    },
);

1;
