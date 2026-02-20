package Strategy::Bloodline;
use v5.36;
use Moo;
with 'PredictionStrategy';

sub predict ($self, $race_data) {
    my $sire = $race_data->{sire_score} // 50;
    my $dam  = $race_data->{dam_score}  // 50;
    return ($sire * 0.6 + $dam * 0.4) / 100;
}

1;
