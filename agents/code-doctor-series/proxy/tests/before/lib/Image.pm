package Image;
use v5.36;

# 画像クラス - 直接ファイルを読み込んでしまう問題のあるコード
sub new($class, $filepath) {
    my $self = bless {
        filepath => $filepath,
        data     => undef,
    }, $class;
    
    # コンストラクタで即座にファイル読み込み（重い処理）
    # TODO: サムネイル用に最適化したいけど時間がない
    $self->_load_file();
    
    return $self;
}

sub _load_file($self) {
    # 実際のファイル読み込みをシミュレート
    # 本番では巨大な画像データを読み込む
    say "Loading full image: $self->{filepath}";
    $self->{data} = "FULL_IMAGE_DATA_OF_$self->{filepath}";
    
    # FIXME: ログ出力、ここにも書いてある...
    $self->_log_access();
}

sub _log_access($self) {
    # アクセスログ（これが各所にコピペされている）
    say "[LOG] Accessed: $self->{filepath}";
}

sub get_thumbnail($self) {
    # サムネイルが欲しいだけなのにフルサイズを返してしまう
    # どうせloadしてるんだから...という発想
    return substr($self->{data}, 0, 20) . "...";
}

sub display($self) {
    return $self->{data};
}

1;
