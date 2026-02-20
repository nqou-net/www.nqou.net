package Strategy::PaddockScore;
use v5.36;
use Moo;
with 'PredictionStrategy';

sub predict ($self, $race_data) {
    my $visual = $race_data->{paddock_visual} // 50;
    return $visual / 100;
}

1;
