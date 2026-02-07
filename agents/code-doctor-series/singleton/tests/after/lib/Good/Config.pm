package Good::Config;
use v5.36;

# 良い実装: state変数を使ったシングルトン
sub new ($class) {

    # state変数: 一度だけ初期化され、値を保持し続ける（Perl 5.10+）
    state $instance;

    # すでにインスタンスがあればそれを返す
    return $instance if defined $instance;

    # 初回のみ生成
    my $config_data = {
        database  => 'mysql://prod-db:3306/app',
        timeout   => 60,
        debug     => 0,
        loaded_at => time(),
    };

    $instance = bless $config_data, $class;
    return $instance;
}

1;
