package Strategy::OddsMovement;
use v5.36;
use Moo;
with 'PredictionStrategy';

sub predict ($self, $race_data) {
    my @odds = $race_data->{odds_history}->@*;
    return 0 unless @odds >= 2;
    my $trend = ($odds[-1] - $odds[0]) / $odds[0];
    return 1 - $trend;
}

1;
