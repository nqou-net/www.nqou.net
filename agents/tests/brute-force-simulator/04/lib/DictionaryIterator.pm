package DictionaryIterator;
use Moo;
use experimental qw(signatures);

has dict_file => (
    is       => 'ro',
    required => 1,
);

has _fh => (
    is  => 'rw',
);

sub BUILD ($self, $args) {
    open my $fh, '<', $self->dict_file or die "辞書ファイルが開けません: $!";
    $self->_fh($fh);
}

sub next ($self) {
    my $fh = $self->_fh;
    my $line = <$fh>;

    return undef unless defined $line;

    chomp $line;
    return $line;
}

sub DEMOLISH ($self, $in_global_destruction) {
    close $self->_fh if $self->_fh;
}

1;
