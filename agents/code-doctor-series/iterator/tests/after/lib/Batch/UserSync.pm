package Batch::UserSync;
use v5.36;
use SaaS::API::Client;

sub new($class) {
    bless {api => SaaS::API::Client->new(),}, $class;
}

sub sync_all_users($self) {
    my $api = $self->{api};

    # 【処方後】
    # Iterator（クロージャ）を使って1件ずつ取得し、処理する。
    # ページネーション管理や配列のpushはすべて Client 内に隠蔽される。

    my $user_iterator   = $api->enumerate_users();
    my $processed_count = 0;

    print "Fetching and processing users (After)...\n";

    # イテレータから1件ずつ取り出すループ
    while (my $user = $user_iterator->()) {

        # ここで1件ずつ重い処理を行う。メモリには常に数件〜100件しか乗らない。
        $processed_count++;
    }

    print "Processed $processed_count users.\n";

    return $processed_count;
}

1;
