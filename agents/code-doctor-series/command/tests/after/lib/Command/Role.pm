package Command::Role;
use v5.36;

# インターフェース（役割）の定義
# すべてのコマンドは execute と undo メソッドを実装する必要がある

sub new ($class, $server) {
    bless {server => $server}, $class;
}

sub execute ($self) {
    die "execute() must be implemented by subclass";
}

sub undo ($self) {
    die "undo() must be implemented by subclass";
}

1;
