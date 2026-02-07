package Bad::Config;
use v5.36;

sub new ($class) {

    # シミュレーション: 設定ファイル読み込み（重い処理）
    my $config_data = {
        database  => 'mysql://localhost:3306/app',
        timeout   => 30,
        debug     => 1,
        loaded_at => time(),
    };

    return bless $config_data, $class;
}

1;
