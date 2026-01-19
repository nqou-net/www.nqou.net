package WebScraper;
# 言語: perl
# バージョン: 5.36以上
# 依存: Moo, Mojo::UserAgent（Mojoliciousに含まれる）

use Moo;
use experimental qw(signatures);
use Mojo::UserAgent;

has url => (
    is       => 'ro',
    required => 1,
);

# 保存先ファイル名（デフォルトは結果を画面出力）
has output_file => (
    is      => 'ro',
    default => sub { undef },
);

sub scrape ($self) {
    my $dom = $self->_fetch_html();
    my @data = $self->extract_data($dom);
    $self->save_data(@data);
    return @data;
}

sub _fetch_html ($self) {
    my $ua = Mojo::UserAgent->new;
    my $res = $ua->get($self->url)->result;
    
    if ($res->is_success) {
        return $res->dom;
    }
    die "取得失敗: " . $res->message;
}

# 抽象メソッド: サブクラスで必ず実装
sub extract_data ($self, $dom) {
    die "extract_data must be implemented by subclass";
}

# フックメソッド: デフォルト実装を用意
sub save_data ($self, @data) {
    if ($self->output_file) {
        # ファイルに保存
        open my $fh, '>', $self->output_file
            or die "Cannot open file: $!";
        for my $item (@data) {
            if (ref $item eq 'HASH') {
                # ハッシュの場合はJSON風に出力
                print $fh join(", ", map { "$_: $item->{$_}" } keys %$item) . "\n";
            } else {
                print $fh "$item\n";
            }
        }
        close $fh;
        say "結果を " . $self->output_file . " に保存しました";
    } else {
        # 画面に出力
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
