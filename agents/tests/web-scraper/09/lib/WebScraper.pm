package WebScraper;
# 言語: perl
# バージョン: 5.36以上
# 依存: Moo, Mojo::DOM

use v5.36;
use Moo;
use experimental qw(signatures);
use Mojo::DOM;

has url => (
    is       => 'ro',
    required => 1,
);

has output_file => (
    is      => 'ro',
    default => sub { undef },
);

# 処理の骨格（Template Method）
sub scrape ($self) {
    my $dom = $self->_fetch_html();       # 1. 取得
    my @data = $self->extract_data($dom); # 2. 抽出
    $self->validate_data(@data);          # 3. 検証
    $self->save_data(@data);              # 4. 保存
    return @data;
}

# 共通処理
sub _fetch_html ($self) {
    my $url = $self->url;
    my $html;
    
    if (-f $url) {
        $html = do {
            open my $fh, '<', $url or die "Cannot open $url: $!";
            local $/;
            <$fh>;
        };
    } else {
        die "取得失敗: ファイルが見つかりません: $url";
    }
    
    return Mojo::DOM->new($html);
}

# 抽象メソッド（サブクラスで必須）
sub extract_data ($self, $dom) {
    die "extract_data must be implemented by subclass";
}

# フックメソッド（オプション）
sub validate_data ($self, @data) {
    return 1;  # デフォルトは何もしない
}

# フックメソッド（デフォルト実装あり）
sub save_data ($self, @data) {
    if ($self->output_file) {
        open my $fh, '>', $self->output_file
            or die "Cannot open file: $!";
        for my $item (@data) {
            if (ref $item eq 'HASH') {
                print $fh join(", ", map { "$_: $item->{$_}" } keys %$item) . "\n";
            } else {
                print $fh "$item\n";
            }
        }
        close $fh;
        say "結果を " . $self->output_file . " に保存しました";
    } else {
        for my $item (@data) {
            if (ref $item eq 'HASH') {
                say join(", ", map { "$_: $item->{$_}" } keys %$item);
            } else {
                say $item;
            }
        }
    }
}

1;
