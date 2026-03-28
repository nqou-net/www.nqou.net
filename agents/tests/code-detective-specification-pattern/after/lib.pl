use strict;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

# === After: Specification Pattern ===
# 各ビジネスルールを独立したSpecificationオブジェクトにカプセル化し、
# and_spec / or_spec / not_spec で合成可能にする。

# --- Order（注文データ: Beforeと同一） ---
package Order {
    use Moo;
    has member_rank       => (is => 'ro', required => 1);
    has total             => (is => 'ro', required => 1);
    has is_campaign_period => (is => 'ro', default => 0);
}

# --- Spec::Base（Specificationの基底クラス） ---
package Spec::Base {
    use Moo;

    sub is_satisfied_by ($self, $order) {
        die "Must override is_satisfied_by";
    }

    sub and_spec ($self, $other) {
        return Spec::And->new(left => $self, right => $other);
    }

    sub or_spec ($self, $other) {
        return Spec::Or->new(left => $self, right => $other);
    }

    sub not_spec ($self) {
        return Spec::Not->new(inner => $self);
    }
}

# --- Spec::And（AND合成） ---
package Spec::And {
    use Moo;
    extends 'Spec::Base';

    has left  => (is => 'ro', required => 1);
    has right => (is => 'ro', required => 1);

    sub is_satisfied_by ($self, $order) {
        return $self->left->is_satisfied_by($order)
            && $self->right->is_satisfied_by($order);
    }
}

# --- Spec::Or（OR合成） ---
package Spec::Or {
    use Moo;
    extends 'Spec::Base';

    has left  => (is => 'ro', required => 1);
    has right => (is => 'ro', required => 1);

    sub is_satisfied_by ($self, $order) {
        return $self->left->is_satisfied_by($order)
            || $self->right->is_satisfied_by($order);
    }
}

# --- Spec::Not（NOT合成） ---
package Spec::Not {
    use Moo;
    extends 'Spec::Base';

    has inner => (is => 'ro', required => 1);

    sub is_satisfied_by ($self, $order) {
        return !$self->inner->is_satisfied_by($order);
    }
}

# --- 具象Specification群 ---
package Spec::GoldMember {
    use Moo;
    extends 'Spec::Base';

    sub is_satisfied_by ($self, $order) {
        return $order->member_rank eq 'gold';
    }
}

package Spec::SilverMember {
    use Moo;
    extends 'Spec::Base';

    sub is_satisfied_by ($self, $order) {
        return $order->member_rank eq 'silver';
    }
}

package Spec::CampaignPeriod {
    use Moo;
    extends 'Spec::Base';

    sub is_satisfied_by ($self, $order) {
        return $order->is_campaign_period;
    }
}

package Spec::MinimumTotal {
    use Moo;
    extends 'Spec::Base';

    has threshold => (is => 'ro', required => 1);

    sub is_satisfied_by ($self, $order) {
        return $order->total >= $self->threshold;
    }
}

# --- DiscountService（リファクタリング後） ---
package DiscountService {
    use Moo;

    has gold_member     => (is => 'ro', default => sub { Spec::GoldMember->new });
    has silver_member   => (is => 'ro', default => sub { Spec::SilverMember->new });
    has campaign_period => (is => 'ro', default => sub { Spec::CampaignPeriod->new });
    has min_5000        => (is => 'ro', default => sub { Spec::MinimumTotal->new(threshold => 5000) });
    has min_10000       => (is => 'ro', default => sub { Spec::MinimumTotal->new(threshold => 10000) });

    sub calculate_discount ($self, $order) {
        my $discount = 0;

        if ($self->gold_member->is_satisfied_by($order)) {
            $discount += $order->total * 0.10;
        }
        if ($self->silver_member->is_satisfied_by($order)) {
            $discount += $order->total * 0.05;
        }

        my $campaign_min_5000 = $self->campaign_period->and_spec($self->min_5000);
        if ($campaign_min_5000->is_satisfied_by($order)) {
            $discount += 500;
        }

        my $combo_spec = $self->gold_member
            ->and_spec($self->campaign_period)
            ->and_spec($self->min_10000);
        if ($combo_spec->is_satisfied_by($order)) {
            $discount += 1000;
        }

        return $discount;
    }

    sub is_free_shipping ($self, $order) {
        my $free_shipping_spec = $self->gold_member->or_spec($self->min_5000);
        return $free_shipping_spec->is_satisfied_by($order);
    }

    sub calculate_points ($self, $order) {
        my $points = int($order->total * 0.01);

        if ($self->gold_member->is_satisfied_by($order)) {
            $points *= 2;
        }
        if ($self->campaign_period->is_satisfied_by($order)) {
            $points += 100;
        }

        return $points;
    }
}

1;
