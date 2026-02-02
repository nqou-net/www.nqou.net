package DBManager_Before;
use strict;
use warnings;

sub new {
    my $class = shift;

    # 毎回新しいインスタンス（接続）を作成してしまう
    my $self = {
        connection_id => int(rand(10000)),
        status        => 'connected',
    };
    return bless $self, $class;
}

sub query {
    my ($self, $sql) = @_;
    return "Result for '$sql' from Connection #" . $self->{connection_id};
}

1;
