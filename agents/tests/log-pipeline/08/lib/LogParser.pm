package LogParser;
use Moo;
use strict;
use warnings;
use experimental qw(signatures);
use namespace::clean;

extends 'LogReader';

# LogProcessorの役割を果たすことを宣言
with 'LogProcessor';

my $LOG_REGEX = qr{^
    (?<ip>[\d\.]+)
    \s-\s-\s
    \[(?<datetime>[^\]]+)\]
    \s"
    (?<method>[A-Z]+)\s
    (?<path>[^\s]+)\s
    [^"]+"
    \s
    (?<status>\d+)
    \s
    (?<size>\d+|-)
}x;

sub next_log ($self) {
    while (defined(my $line = $self->next_line)) {
        if ($line =~ $LOG_REGEX) {
            return { %+ };
        }
        warn "Skipped invalid line: $line\n";
    }
    return undef;
}

1;
