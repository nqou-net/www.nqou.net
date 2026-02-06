package Store::Strategy::Factory;
use v5.36;
use Store::Strategy::Summer;
use Store::Strategy::Winter;
use Store::Strategy::Normal;

sub create ($class, $campaign_id) {

    # Returns the appropriate strategy instance
    if (defined $campaign_id && $campaign_id eq 'SUMMER_2026') {
        return Store::Strategy::Summer->new;
    }
    if (defined $campaign_id && $campaign_id eq 'WINTER_2026') {
        return Store::Strategy::Winter->new;
    }
    return Store::Strategy::Normal->new;
}

1;
