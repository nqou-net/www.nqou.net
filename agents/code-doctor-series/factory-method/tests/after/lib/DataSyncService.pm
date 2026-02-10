package DataSyncService;
use v5.36;
use Moo;
use SyncClientFactory;

has factory => (
    is      => 'ro',
    default => sub { SyncClientFactory->new },
);

sub sync_data($self, $target, $data) {
    my $client = $self->factory->create($target);
    $client->sync($data);
}

1;
