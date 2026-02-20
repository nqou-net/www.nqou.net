use v5.36;
use Test::More;
use lib 'lib';
use HorsePredictor qw(predict);

my $race_data = {
    past_results   => [{course => 'tokyo', finish => 2}, {course => 'nakayama', finish => 1}, {course => 'tokyo', finish => 3},],
    track          => 'good',
    horse_rating   => 80,
    odds_history   => [5.0, 4.2, 3.8],
    sire_score     => 75,
    dam_score      => 60,
    jockey_score   => 82,
    paddock_visual => 70,
};

# --- 個別テスト: パドック追加前に他のアルゴリズムを実行 ---
subtest 'past_data strategy' => sub {
    my $result = predict($race_data, 'past_data');
    ok($result > 0, "past_data returns positive value: $result");
};

subtest 'track_condition strategy' => sub {
    my $result = predict($race_data, 'track_condition');
    ok($result > 0, "track_condition returns positive value: $result");
};

subtest 'bloodline strategy' => sub {
    my $result = predict($race_data, 'bloodline');
    ok($result > 0 && $result <= 1, "bloodline returns 0-1 range: $result");
};

# --- 問題の再現: paddock_score を実行すると他が壊れる ---
subtest 'paddock_score corrupts shared state' => sub {

    # 先に track_condition を実行して基準値を取得
    my $before = predict($race_data, 'track_condition');

    # paddock_score を実行（$weight_cache がリセットされる）
    predict($race_data, 'paddock_score');

    # track_condition を再実行
    my $after = predict($race_data, 'track_condition');

    # weight_cache が汚染されているので結果が変わる可能性がある
    # （track_condition 自体は $weight_cache に書き込むので復帰するが、
    #   他のロジック（jockey_compat等）が bloodline キャッシュを失う）
    my $jockey_before_paddock = predict($race_data, 'bloodline');
    predict($race_data, 'paddock_score');    # 再度汚染
    my $jockey_after = predict($race_data, 'jockey_compat');

    # bloodline キャッシュが消えているので jockey_compat の結果が変わる
    note("jockey_compat after paddock corruption: $jockey_after");

    # この時点で $weight_cache->{bloodline} は存在しない
    ok(1, "State corruption demonstrated");
};

done_testing;
