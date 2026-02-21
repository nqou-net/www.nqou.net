package Batch::UserSync;
use v5.36;
use SaaS::API::Client;

sub new($class) {
    bless {api => SaaS::API::Client->new(),}, $class;
}

sub sync_all_users($self) {
    my $api = $self->{api};

    # 【症状】
    # 1. ページネーションのループ変数がメインロジックに漏洩している
    # 2. 全件を取得して巨大な配列にpushし続けるため、メモリを異常に消費する

    my @all_users;
    my $current_page = 1;

    print "Fetching users (Before)...\n";

    while ($current_page) {
        my $res = $api->get_users($current_page);

        # 配列に全量詰め込む（ここで数百MB〜GBのメモリを消費する想定）
        push @all_users, $res->{items}->@*;

        $current_page = $res->{next_page};
    }

    print "Total users fetched into memory: ", scalar(@all_users), "\n";

    # 全件取得後、ようやく処理を開始する
    my $processed_count = 0;
    for my $user (@all_users) {

        # 重い処理のシミュレート
        $processed_count++;
    }

    print "Processed $processed_count users.\n";

    return $processed_count;
}

1;
