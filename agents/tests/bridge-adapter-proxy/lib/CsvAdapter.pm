package CsvAdapter;

# 第3回: Adapterでデータソースを統一
# CsvAdapter.pm - CSVデータのAdapter

use v5.36;
use warnings;
use Moo;

with 'WhiskySourceRole';

has csv_data => (
    is       => 'ro',
    required => 1,
);

has '_cache' => (
    is      => 'lazy',
    builder => '_build_cache',
);

sub _build_cache($self) {
    my @whiskies;
    my @lines = split /\n/, $self->csv_data;
    shift @lines;    # ヘッダー除去

    for my $line (@lines) {
        next unless $line =~ /\S/;
        my @f = split /,/, $line;
        push @whiskies,
            {
            id     => $f[0],
            name   => $f[1],
            region => $f[2],
            age    => $f[3],
            abv    => $f[4],
            nose   => $f[5],
            palate => $f[6],
            finish => $f[7],
            rating => $f[8],
            };
    }

    return {map { $_->{id} => $_ } @whiskies};
}

sub get_whisky($self, $id) {
    return $self->_cache->{$id};
}

sub get_all($self) {
    return values $self->_cache->%*;
}

sub source_name($self) {'CSV'}

1;

__END__

=head1 NAME

CsvAdapter - CSVデータを統一インターフェースで提供するAdapter

=head1 SYNOPSIS

    my $adapter = CsvAdapter->new(csv_data => $csv_string);
    my $whisky = $adapter->get_whisky('1');
    my @all = $adapter->get_all();

=cut
