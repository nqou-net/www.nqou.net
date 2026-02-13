package LegacyInventoryTool;
use v5.36;

sub new($class) {
    return bless {
        _db => {
            'item_001' => { name => 'Sword', stock => 10 },
            'item_002' => { name => 'Shield', stock => 5 },
        }
    }, $class;
}

# 20年物のメインロジック。コマンドライン引数($argv)に強く依存している。
# elsifの連打が血管の動脈硬化を引き起こしている状態。
sub run($self, $argv) {
    my $cmd = $argv->[0] // '';

    if ($cmd eq 'get_stock') {
        my $id = $argv->[1];
        if (!$id) { return "ERROR: NO_ID"; }
        my $item = $self->{_db}{$id};
        if (!$item) { return "ERROR: NOT_FOUND"; }
        # CLI用のテキスト形式で返す
        return "STOCK:$id:" . $item->{stock};
    }
    elsif ($cmd eq 'update_stock') {
        my $id = $argv->[1];
        my $val = $argv->[2];
        if (!$id || !defined $val) { return "ERROR: INVALID_ARGS"; }
        if (!$self->{_db}{$id}) { return "ERROR: NOT_FOUND"; }
        $self->{_db}{$id}{stock} = $val;
        return "SUCCESS:UPDATED:$id";
    }
    # ... ここにさらに500行のelsifが続いていると想像してください ...
    else {
        return "ERROR: UNKNOWN_COMMAND";
    }
}

1;
