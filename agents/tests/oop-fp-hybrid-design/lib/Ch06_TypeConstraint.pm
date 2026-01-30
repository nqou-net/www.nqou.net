package Ch06_TypeConstraint;
use v5.36;
use Moo;
use Types::Standard qw(Str Int Num ArrayRef HashRef Bool Optional);

# 第6回: 型制約（Types::Standard）
# 型で入力を検証し、実行時エラーを防ぐ

#=====================================================
# 問題版: 型制約なしのコード
#=====================================================

package Ch06_TypeConstraint::OrderItem_NoType {
    use v5.36;
    use Moo;

    has name     => (is => 'ro');    # 型なし - 何でも受け入れる
    has price    => (is => 'ro');    # 負の値や文字列も受け入れる
    has quantity => (is => 'ro');    # 小数も受け入れる

    sub total ($self) {

        # ここで初めてエラーが発生する可能性
        return $self->price * $self->quantity;
    }
}

#=====================================================
# 解決版: Types::Standard で型制約
#=====================================================

package Ch06_TypeConstraint::OrderItem {
    use v5.36;
    use Moo;
    use Types::Standard qw(Str Int Num);

    has name => (
        is       => 'ro',
        isa      => Str,
        required => 1,
    );

    has price => (
        is       => 'ro',
        isa      => Int->where(sub { $_ > 0 }),    # 正の整数
        required => 1,
    );

    has quantity => (
        is       => 'ro',
        isa      => Int->where(sub { $_ > 0 }),    # 正の整数
        required => 1,
    );

    sub total ($self) {
        return $self->price * $self->quantity;
    }
}

#=====================================================
# さらに高度な型: イミュータブルな Order
#=====================================================

package Ch06_TypeConstraint::Order {
    use v5.36;
    use Moo;
    use Types::Standard qw(Str Int Num ArrayRef InstanceOf Optional);

    has customer_name => (
        is       => 'ro',
        isa      => Str->where(sub { length($_) > 0 }),
        required => 1,
    );

    has customer_email => (
        is       => 'ro',
        isa      => Str->where(sub {/^.+@.+\..+$/}),    # 簡易メール形式
        required => 1,
    );

    has items => (
        is      => 'ro',
        isa     => ArrayRef [InstanceOf ['Ch06_TypeConstraint::OrderItem']],
        default => sub { [] },
    );

    has discount_rate => (
        is      => 'ro',
        isa     => Num->where(sub { $_ >= 0 && $_ <= 100 }),    # 0-100%
        default => 0,
    );

    # 計算ロジック（純粋関数的）
    sub subtotal ($self) {
        my $total = 0;
        $total += $_->total for @{$self->items};
        return $total;
    }

    sub discount_amount ($self) {
        return int($self->subtotal * $self->discount_rate / 100);
    }

    sub total ($self) {
        return $self->subtotal - $self->discount_amount;
    }

    # with_* パターン
    sub with_item ($self, $item) {
        my @new_items = (@{$self->items}, $item);
        return Ch06_TypeConstraint::Order->new(
            customer_name  => $self->customer_name,
            customer_email => $self->customer_email,
            items          => \@new_items,
            discount_rate  => $self->discount_rate,
        );
    }

    sub with_discount ($self, $rate) {
        return Ch06_TypeConstraint::Order->new(
            customer_name  => $self->customer_name,
            customer_email => $self->customer_email,
            items          => $self->items,
            discount_rate  => $rate,
        );
    }
}

#=====================================================
# Demo
#=====================================================

package Ch06_TypeConstraint;

sub demonstrate_type_safety {
    say "=== 型制約のデモ ===\n";

    # 正常なケース
    say "--- 正常な注文 ---";
    my $item1 = Ch06_TypeConstraint::OrderItem->new(
        name     => 'Book',
        price    => 1000,
        quantity => 2,
    );

    my $item2 = Ch06_TypeConstraint::OrderItem->new(
        name     => 'Pen',
        price    => 200,
        quantity => 5,
    );

    my $order = Ch06_TypeConstraint::Order->new(
        customer_name  => 'Alice',
        customer_email => 'alice@example.com',
        items          => [$item1, $item2],
        discount_rate  => 10,
    );

    say "顧客: " . $order->customer_name;
    say "小計: ¥" . $order->subtotal;
    say "割引: ¥" . $order->discount_amount;
    say "合計: ¥" . $order->total;

    # エラーケース（型違反）
    say "\n--- 型違反のテスト ---";

    eval {
        my $bad_item = Ch06_TypeConstraint::OrderItem->new(
            name     => 'Invalid',
            price    => -100,        # 負の値は型違反
            quantity =>  1,
        );
    };
    if ($@) {
        say "型エラー捕捉: 負の価格は拒否されました";
    }

    eval {
        my $bad_order = Ch06_TypeConstraint::Order->new(
            customer_name  => '',                    # 空文字は型違反
            customer_email => 'alice@example.com',
        );
    };
    if ($@) {
        say "型エラー捕捉: 空の顧客名は拒否されました";
    }

    eval {
        my $bad_order = Ch06_TypeConstraint::Order->new(
            customer_name  => 'Bob',
            customer_email => 'invalid-email',       # 不正なメール形式
        );
    };
    if ($@) {
        say "型エラー捕捉: 不正なメール形式は拒否されました";
    }

    return $order;
}

1;
