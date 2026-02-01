package AccessProxy;

# 第7回: Proxyで遅延・キャッシュ・制御
# AccessProxy.pm - アクセス制御Proxy

use v5.36;
use warnings;
use Moo;

has private_note     => (is => 'ro', required => 1);
has owner_id         => (is => 'ro', required => 1);
has permission_level => (is => 'ro', default  => 'private');

# permission_level: 'private', 'friends', 'public'

# アクセス権限をチェック
sub can_access($self, $user_id, $is_friend = 0) {
    my $level = $self->permission_level;

    if ($level eq 'public') {
        return 1;
    }
    elsif ($level eq 'friends') {
        return ($user_id eq $self->owner_id || $is_friend);
    }
    else {    # private
        return ($user_id eq $self->owner_id);
    }
}

# ノートを取得（権限チェック付き）
sub get_note($self, $user_id, $is_friend = 0) {
    if ($self->can_access($user_id, $is_friend)) {
        say "  [Proxy] アクセス許可: user=$user_id level=$self->{permission_level}";
        return $self->private_note;
    }
    else {
        say "  [Proxy] アクセス拒否: user=$user_id level=$self->{permission_level}";
        return {error => 'Access denied', message => 'このノートは非公開です'};
    }
}

# 編集権限チェック（オーナーのみ）
sub can_edit($self, $user_id) {
    return ($user_id eq $self->owner_id);
}

sub edit_note($self, $user_id, $new_data) {
    if ($self->can_edit($user_id)) {
        say "  [Proxy] 編集許可: user=$user_id";

        # 実際の編集処理
        return {success => 1};
    }
    else {
        say "  [Proxy] 編集拒否: user=$user_id (オーナーではない)";
        return {error => 'Permission denied', message => '編集権限がありません'};
    }
}

1;

__END__

=head1 NAME

AccessProxy - 非公開ノートのアクセス制御Proxy

=head1 DESCRIPTION

Proxyパターンで非公開ノートへのアクセス制御を実現。
オーナー/友達/公開の3段階のアクセスレベルに対応。

=cut
