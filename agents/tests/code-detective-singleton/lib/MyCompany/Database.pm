package MyCompany::Database;
use strict;
use warnings;

my $INSTANCE;

sub get_instance {
    my $class = shift;
    # キャッシュされたインスタンスを返す（Singletonパターンの典型的な実装）
    $INSTANCE ||= bless { data => { 1 => { name => "Alice" }, 2 => { name => "Bob" } } }, $class;
    return $INSTANCE;
}

sub fetch_user_data {
    my ($self, $user_id) = @_;
    return $self->{data}->{$user_id} || { name => "Unknown" };
}

# 【アンチパターン】どこからでも書き換えられるため、状態が漏洩する
sub overwrite_data {
    my ($self, $bad_data) = @_;
    $self->{data} = $bad_data;
}

1;
