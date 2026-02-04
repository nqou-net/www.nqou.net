package Bad::Config;
use v5.36;

# 悪い実装: インスタンス化のたびに設定を読み込み直す
sub new ($class) {
    # シミュレーション: 設定ファイル読み込み（重い処理）
    my $config_data = {
        database => 'mysql://localhost:3306/app',
        timeout  => 30,
        debug    => 1,
        # 実際はここでファイルIOが発生する想定
        loaded_at => time(),
    };
    
    return bless $config_data, $class;
}

sub get ($self, $key) {
    return $self->{$key};
}

1;
