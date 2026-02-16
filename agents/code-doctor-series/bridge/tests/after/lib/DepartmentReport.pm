package DepartmentReport;
use v5.36;

# Bridge の Abstraction 側: 部門レポートの基底クラス
# $formatter (Implementation) を has-a で保持する

sub new ($class, %args) {
    die "formatter is required" unless $args{formatter};
    return bless {formatter => $args{formatter},}, $class;
}

sub formatter ($self) { $self->{formatter} }

# サブクラスでオーバーライド: 部門固有のデータ集計
sub aggregate ($self, $data) { die "not implemented" }

# 共通のレポート生成ロジック（Template Method 的）
sub generate ($self, $data) {
    my $metrics = $self->aggregate($data);
    my $title   = $self->title;

    my $output = $self->formatter->render_header($title);
    for my $pair ($metrics->@*) {
        $output .= $self->formatter->render_row($pair->[0], $pair->[1]);
    }
    $output .= $self->formatter->render_footer;

    return $output;
}

# サブクラスでオーバーライド
sub title ($self) { die "not implemented" }

1;
