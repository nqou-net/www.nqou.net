package Strategy::TrackCondition;
use v5.36;
use Moo;
with 'PredictionStrategy';

my %TRACK_WEIGHTS = (good => 1.0, yielding => 0.8, soft => 0.6, heavy => 0.4);

sub predict ($self, $race_data) {
    my $base = $TRACK_WEIGHTS{$race_data->{track}} // 0.5;
    return $base * $race_data->{horse_rating};
}

1;
