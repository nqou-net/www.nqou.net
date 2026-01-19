package WebScraper;
# 言語: perl
# バージョン: 5.36以上
# 依存: Moo, Mojo::DOM
# 注: テスト用にローカルファイル読み込みに対応

use Moo;
use experimental qw(signatures);
use Mojo::DOM;

# スクレイピング対象のURL（またはファイルパス）
has url => (
    is       => 'ro',
    required => 1,
);

# メインの処理メソッド：処理の「骨格」を定義
sub scrape ($self) {
    # 1. HTMLを取得
    my $dom = $self->_fetch_html();
    
    # 2. データを抽出（サブクラスで実装）
    my @data = $self->extract_data($dom);
    
    # 3. データを保存（サブクラスで実装）
    $self->save_data(@data);
    
    return @data;
}

# HTMLを取得する（共通処理）
# テスト用にローカルファイルから読み込み
sub _fetch_html ($self) {
    my $url = $self->url;
    my $html;
    
    if (-f $url) {
        # ローカルファイルの場合
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

# データを抽出する（サブクラスで必ず実装）
sub extract_data ($self, $dom) {
    die "extract_data must be implemented by subclass";
}

# データを保存する（サブクラスで必ず実装）
sub save_data ($self, @data) {
    die "save_data must be implemented by subclass";
}

1;
