package ReportFormatter;
use v5.36;

# Bridge の Implementation 側: 出力形式のインターフェース（ロール）

sub new ($class, %args) {
    return bless \%args, $class;
}

# サブクラスでオーバーライドする
sub render_header ($self, $title)         { die "not implemented" }
sub render_row    ($self, $label, $value) { die "not implemented" }
sub render_footer ($self)                 { die "not implemented" }

1;
