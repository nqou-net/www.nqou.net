package Goblin;
use v5.36;
use parent 'Monster';
use Time::HiRes qw(usleep);

sub new ($class, %args) {

    # Heavy initialization simulation
    # Imagine loading 3D models, textures, parsing JSON configs, etc.
    # usleep(50000); # 50ms per goblin
    # For demonstration, we just do some "heavy" calculation loop
    my $heavy = 0;

    # Increase loop to make it noticeable (e.g. 100,000 iterations)
    for (1 .. 50000) { $heavy += $_ }

    my $self = $class->SUPER::new(%args, heavy_data => $heavy);
    $self;
}

# clone method is inherited from Monster, which is fast!

1;
