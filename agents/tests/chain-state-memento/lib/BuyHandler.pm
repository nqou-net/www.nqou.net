package BuyHandler;
use v5.36;
use warnings;
use utf8;
use Moo;

# 第7回: 買い物ハンドラ（チェーンに追加可能）
# 特定の場所でのみショップモードに遷移

# NOTE: BuyHandlerを使う前にadventure.plをrequireすること

my %SHOP_LOCATIONS = ('古い小屋' => 1);

sub can_handle($self, $game, $cmd) {
    return $cmd eq '買い物' || $cmd eq 'ショップ';
}

sub handle($self, $game, $cmd) {
    my $location = $game->context->{location};

    if ($SHOP_LOCATIONS{$location}) {
        require ShopState;
        $game->change_state(ShopState->new);
        return {handled => 1, message => ''};    # on_enter でメッセージ表示
    }

    return {handled => 1, message => 'ここにはショップがない。'};
}

# CommandHandler互換のメソッド
has next_handler => (is => 'rw', predicate => 'has_next');

sub set_next($self, $h) { $self->next_handler($h); $h }

sub process($self, $game, $cmd) {
    return $self->handle($game, $cmd)                if $self->can_handle($game, $cmd);
    return $self->next_handler->process($game, $cmd) if $self->has_next;
    return {handled => 0, message => 'コマンド不明。'};
}

1;
