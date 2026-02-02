package DBManager_After;
use strict;
use warnings;
use Scalar::Util qw(refaddr);

# 唯一のインスタンスを保持する変数
my $INSTANCE;

sub new {
    my $class = shift;

    # 既存のインスタンスがあればそれを返す
    return $INSTANCE if $INSTANCE;

    # 新規作成（初回のみ）
    my $self = {
        connection_id => int(rand(10000)),
        status        => 'connected',
    };
    $INSTANCE = bless $self, $class;
    return $INSTANCE;
}

# 明示的なアクセスメソッド（推奨）
sub instance {
    my $class = shift;
    return $class->new(@_);
}

sub query {
    my ($self, $sql) = @_;
    return "Result for '$sql' from Connection #" . $self->{connection_id};
}

# テスト用リセットメソッド（通常は公開しない）
sub _reset {
    undef $INSTANCE;
}

1;
