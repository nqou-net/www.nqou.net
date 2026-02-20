package Strategy::PastData;
use v5.36;
use Moo;
with 'PredictionStrategy';

has weight_cache => (is => 'rw', default => sub { {} });

sub predict ($self, $race_data) {
    my $score = 0;
    for my $result ($race_data->{past_results}->@*) {
        my $w = $self->weight_cache->{$result->{course}} //= 1.0;
        $score += $result->{finish} * $w;
    }
    return $score / scalar($race_data->{past_results}->@*);
}

1;
