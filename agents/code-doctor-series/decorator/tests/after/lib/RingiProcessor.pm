package RingiProcessor;
use v5.36;

# Decorator パターンの共通インターフェース（ロール）
# すべての承認処理は process() を持つ

sub new ($class, %args) {
    return bless \%args, $class;
}

sub process ($self, $ringi) {
    die "not implemented";
}

1;
