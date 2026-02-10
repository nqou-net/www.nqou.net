package DataSyncService;
use v5.36;
use Moo;

# 複数のAPI連携先クライアントを使う
# TODO: 後で整理したい（3ヶ月目）
use SalesforceClient;
use KintoneClient;
use SlackClient;

sub sync_data($self, $target, $data) {
    # 連携先ごとに分岐して処理
    # ※新規連携先追加のたびにここを修正する必要あり（辛い）
    if ($target eq 'salesforce') {
        my $client = SalesforceClient->new(
            api_key  => $ENV{SF_API_KEY}  // 'demo_key',
            endpoint => $ENV{SF_ENDPOINT} // 'https://api.salesforce.com',
        );
        $client->push_records($data);
    }
    elsif ($target eq 'kintone') {
        my $client = KintoneClient->new(
            token  => $ENV{KINTONE_TOKEN}  // 'demo_token',
            app_id => $ENV{KINTONE_APP_ID} // '123',
        );
        $client->upsert($data);
    }
    elsif ($target eq 'slack') {
        my $client = SlackClient->new(
            webhook_url => $ENV{SLACK_WEBHOOK} // 'https://hooks.slack.com/demo',
        );
        $client->post_message($data->{message} // 'データ同期完了');
    }
    else {
        die "Unknown target: $target";
    }
}

1;
