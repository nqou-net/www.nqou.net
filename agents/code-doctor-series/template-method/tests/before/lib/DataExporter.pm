package DataExporter;
use v5.36;

sub new ($class, %args) {
    return bless {
        db => $args{db} // die "db is required",
    }, $class;
}

# CSV形式でエクスポート
sub export_csv ($self, $table_name) {
    # データ取得
    my @rows = $self->{db}->fetch_all($table_name);
    die "No data found in $table_name" unless @rows;

    # バリデーション
    for my $row (@rows) {
        for my $key (keys $row->%*) {
            # TODO: なぜかたまにundefが混じる。とりあえず空文字に
            $row->{$key} //= '';
        }
    }

    # CSV変換
    my @headers = sort keys $rows[0]->%*;
    my $output = join(",", @headers) . "\n";
    for my $row (@rows) {
        my @values = map { 
            my $v = $row->{$_};
            $v =~ s/"/""/g;  # ダブルクォートのエスケープ
            qq{"$v"};
        } @headers;
        $output .= join(",", @values) . "\n";
    }

    # ログ出力
    my $count = scalar @rows;
    print "Exported $count rows from $table_name as CSV\n";

    return $output;
}

# JSON形式でエクスポート
# FIXME: export_csvからコピペして作った。時間なかった。
sub export_json ($self, $table_name) {
    # データ取得（export_csvと同じ）
    my @rows = $self->{db}->fetch_all($table_name);
    die "No data found in $table_name" unless @rows;

    # バリデーション（export_csvと同じ…はず）
    for my $row (@rows) {
        for my $key (keys $row->%*) {
            $row->{$key} //= '';
        }
    }

    # JSON変換
    my $output = "[\n";
    my @json_rows;
    for my $row (@rows) {
        my @pairs;
        for my $key (sort keys $row->%*) {
            my $v = $row->{$key};
            $v =~ s/\\/\\\\/g;
            $v =~ s/"/\\"/g;
            push @pairs, qq{    "$key": "$v"};
        }
        push @json_rows, "  {\n" . join(",\n", @pairs) . "\n  }";
    }
    $output .= join(",\n", @json_rows) . "\n]\n";

    # ログ出力（export_csvと同じ）
    my $count = scalar @rows;
    print "Exported $count rows from $table_name as JSON\n";

    return $output;
}

# XML形式でエクスポート
# FIXME: export_jsonからコピペして作った。もう許して。
sub export_xml ($self, $table_name) {
    # データ取得（3回目のコピペ）
    my @rows = $self->{db}->fetch_all($table_name);
    die "No data found in $table_name" unless @rows;

    # バリデーション（3回目のコピペ）
    for my $row (@rows) {
        for my $key (keys $row->%*) {
            $row->{$key} //= '';
        }
    }

    # XML変換
    my $output = qq{<?xml version="1.0" encoding="UTF-8"?>\n};
    $output .= "<records>\n";
    for my $row (@rows) {
        $output .= "  <record>\n";
        for my $key (sort keys $row->%*) {
            my $v = $row->{$key};
            $v =~ s/&/&amp;/g;
            $v =~ s/</&lt;/g;
            $v =~ s/>/&gt;/g;
            $output .= "    <$key>$v</$key>\n";
        }
        $output .= "  </record>\n";
    }
    $output .= "</records>\n";

    # ログ出力（3回目のコピペ）
    my $count = scalar @rows;
    print "Exported $count rows from $table_name as XML\n";

    return $output;
}

1;
