package Strategy::JockeyCompat;
use v5.36;
use Moo;
with 'PredictionStrategy';

sub predict ($self, $race_data) {
    my $compat = $race_data->{jockey_score} // 50;
    return $compat / 100;
}

1;
