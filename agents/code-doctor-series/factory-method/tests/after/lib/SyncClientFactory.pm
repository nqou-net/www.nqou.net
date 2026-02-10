package SyncClientFactory;
use v5.36;
use Moo;

# 設定マッピング（環境変数から取得）
my $configs = {
    salesforce => sub {
        return {
            api_key  => $ENV{SF_API_KEY}  // 'demo_key',
            endpoint => $ENV{SF_ENDPOINT} // 'https://api.salesforce.com',
        };
    },
    kintone => sub {
        return {
            token  => $ENV{KINTONE_TOKEN}  // 'demo_token',
            app_id => $ENV{KINTONE_APP_ID} // '123',
        };
    },
    slack => sub {
        return {webhook_url => $ENV{SLACK_WEBHOOK} // 'https://hooks.slack.com/demo',};
    },
};

sub create($self, $target) {

    # 設定を取得（未知のターゲットを早期に検出）
    my $config_fn = $configs->{$target}
        or die "Unknown target: $target";

    # クラス名を動的に決定
    my $class = 'SyncClient::' . ucfirst($target);

    # クラスをロード
    my $file = $class =~ s{::}{/}gr . '.pm';
    require $file;

    # インスタンスを生成
    return $class->new($config_fn->()->%*);
}

1;
