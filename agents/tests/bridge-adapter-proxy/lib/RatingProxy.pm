package RatingProxy;

# 第7回: Proxyで遅延・キャッシュ・制御
# RatingProxy.pm - 評価キャッシュProxy

use v5.36;
use warnings;
use Moo;

has whisky_id     => (is => 'ro', required => 1);
has '_cache'      => (is => 'rw');
has '_cache_time' => (is => 'rw', default => 0);
has cache_ttl     => (is => 'ro', default => 60);    # 60秒キャッシュ

# 外部からレーティングを取得する処理（重い）
sub _fetch_rating($self) {
    my $id = $self->whisky_id;
    say "  [Proxy] 外部APIから評価を取得中: whisky_id=$id";

    # 実際は外部APIへのリクエスト
    sleep 1;    # 重い処理をシミュレート

    # ダミーデータ
    my %ratings = (
        1 => {score => 92, reviews => 150, avg_price => 8000},
        2 => {score => 88, reviews => 200, avg_price => 6500},
        3 => {score => 85, reviews => 120, avg_price => 5000},
    );

    return $ratings{$id} // {score => 0, reviews => 0, avg_price => 0};
}

sub get_rating($self) {
    my $now = time;

    # キャッシュが有効か確認
    if ($self->_cache && ($now - $self->_cache_time) < $self->cache_ttl) {
        say "  [Proxy] キャッシュから評価を返却 (残り" . ($self->cache_ttl - ($now - $self->_cache_time)) . "秒)";
        return $self->_cache;
    }

    # キャッシュがないか期限切れ → 外部から取得
    my $rating = $self->_fetch_rating;
    $self->_cache($rating);
    $self->_cache_time($now);

    return $rating;
}

sub invalidate_cache($self) {
    $self->_cache(undef);
    $self->_cache_time(0);
    say "  [Proxy] キャッシュを無効化しました";
}

1;

__END__

=head1 NAME

RatingProxy - 外部評価データのキャッシュProxy

=head1 DESCRIPTION

Proxyパターンで外部APIからの評価データをキャッシュ。
TTL（Time To Live）期間内は外部APIを呼ばずキャッシュを返す。

=cut
