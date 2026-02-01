package ShopState;
use v5.36;
use warnings;
use utf8;
use Moo;

# 第7回: 新しいモードの追加（ショップモード）
# adventure.plで定義されているGameStateRoleを使用

# NOTE: ShopStateを使う前にadventure.plをrequireすること
# require 'adventure.pl';

has shop_items => (
    is      => 'ro',
    default => sub {
        {
            '回復薬' => 10,
            '強化薬' => 20,
            '護符'  => 50,
        }
    },
);

sub name($self) {'ショップ'}

sub on_enter($self, $game) {
    return "店主「いらっしゃい！何をお求めかな？」\n" . "【買う [アイテム名]】【売る [アイテム名]】【一覧】【戻る】";
}

sub process_command($self, $game, $cmd) {
    my $ctx = $game->context;

    if ($cmd eq '一覧') {
        my @list;
        my $items = $self->shop_items;
        for my $item (sort keys %$items) {
            push @list, sprintf('%s: %dゴールド', $item, $items->{$item});
        }
        return {
            handled => 1,
            message => "店の品物:\n  " . join("\n  ", @list) . "\n所持金: " . ($ctx->{gold} // 0) . "ゴールド"
        };
    }
    elsif ($cmd =~ /^買う\s+(.+)$/) {
        my $item  = $1;
        my $price = $self->shop_items->{$item};

        if (!$price) {
            return {handled => 1, message => 'その商品はない。'};
        }

        $ctx->{gold} //= 0;
        if ($ctx->{gold} < $price) {
            return {handled => 1, message => 'ゴールドが足りない。'};
        }

        $ctx->{gold} -= $price;
        push @{$ctx->{inventory}}, $item;
        return {
            handled => 1,
            message => "${item}を購入した。残り: $ctx->{gold}ゴールド"
        };
    }
    elsif ($cmd =~ /^売る\s+(.+)$/) {
        my $item = $1;
        my $inv  = $ctx->{inventory};

        my $idx = -1;
        for my $i (0 .. $#$inv) {
            if ($inv->[$i] eq $item) {
                $idx = $i;
                last;
            }
        }

        if ($idx < 0) {
            return {handled => 1, message => 'そのアイテムは持っていない。'};
        }

        my $price      = $self->shop_items->{$item} // 5;
        my $sell_price = int($price / 2);

        splice(@$inv, $idx, 1);
        $ctx->{gold} = ($ctx->{gold} // 0) + $sell_price;

        return {
            handled => 1,
            message => "${item}を${sell_price}ゴールドで売った。所持金: $ctx->{gold}ゴールド"
        };
    }
    elsif ($cmd eq '戻る') {
        $game->change_state(ExplorationState->new);
        return {handled => 1, message => 'ショップを出た。'};
    }
    elsif ($cmd eq 'ヘルプ') {
        return {handled => 1, message => 'ショップ: 買う [アイテム], 売る [アイテム], 一覧, 戻る'};
    }

    return {handled => 1, message => 'そのコマンドは分からない。「ヘルプ」で確認しよう。'};
}

1;
