package PredictionEngine;
use v5.36;
use Moo;

has strategies => (
    is      => 'ro',
    default => sub { {} },
);

sub add_strategy ($self, $name, $strategy) {
    die "$name does not implement PredictionStrategy"
        unless $strategy->does('PredictionStrategy');
    $self->strategies->{$name} = $strategy;
    return $self;
}

sub predict ($self, $race_data, $strategy_name) {
    my $strategy = $self->strategies->{$strategy_name}
        or die "Unknown strategy: $strategy_name";
    return $strategy->predict($race_data);
}

sub predict_all ($self, $race_data) {
    my %results;
    for my $name (sort keys $self->strategies->%*) {
        $results{$name} = $self->strategies->{$name}->predict($race_data);
    }
    return \%results;
}

1;
