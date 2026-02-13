package InventoryAdapter;
use v5.36;

# ドクターによる処方: Adapter Pattern
# 既存のLegacyInventoryToolには1ミリも触れず、新しいWebAPI用の口(JSON interface)を作る。

sub new($class, $legacy_tool) {
    return bless {
        legacy => $legacy_tool
    }, $class;
}

# Web APIが期待するメソッド名
sub fetch_stock($self, $item_id) {
    my $result = $self->{legacy}->run(['get_stock', $item_id]);
    
    if ($result =~ /^STOCK:(.+):(\d+)$/) {
        return { id => $1, stock => int($2), status => 'ok' };
    }
    return { status => 'error', message => $result };
}

sub change_stock($self, $item_id, $new_val) {
    my $result = $self->{legacy}->run(['update_stock', $item_id, $new_val]);

    if ($result =~ /^SUCCESS:UPDATED:(.+)$/) {
        return { id => $1, status => 'ok' };
    }
    return { status => 'error', message => $result };
}

1;
