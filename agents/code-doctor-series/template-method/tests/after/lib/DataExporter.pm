package DataExporter;
use v5.36;

sub new ($class, %args) {
    return bless {
        db => $args{db} // die "db is required",
    }, $class;
}

# Template Method: エクスポート処理の骨格を定義
sub export ($self, $table_name) {
    my @rows = $self->_fetch_data($table_name);
    $self->_validate(\@rows);
    my $output = $self->_header(\@rows);
    $output   .= $self->_format(\@rows);
    $output   .= $self->_footer(\@rows);
    $self->_log($table_name, scalar @rows);
    return $output;
}

# 共通ステップ: データ取得
sub _fetch_data ($self, $table_name) {
    my @rows = $self->{db}->fetch_all($table_name);
    die "No data found in $table_name" unless @rows;
    return @rows;
}

# 共通ステップ: バリデーション
sub _validate ($self, $rows) {
    for my $row ($rows->@*) {
        for my $key (keys $row->%*) {
            $row->{$key} //= '';
        }
    }
}

# フックメソッド: ヘッダー（デフォルトは空）
sub _header ($self, $rows) { return '' }

# 抽象メソッド: フォーマット変換（サブクラスが実装必須）
sub _format ($self, $rows) {
    die ref($self) . " must implement _format()";
}

# フックメソッド: フッター（デフォルトは空）
sub _footer ($self, $rows) { return '' }

# 共通ステップ: ログ出力
sub _log ($self, $table_name, $count) {
    my $format = ref($self) =~ s/.*:://r;
    print "Exported $count rows from $table_name as $format\n";
}

1;
