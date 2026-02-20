use v5.36;
use Test::More;
use lib 'lib';

use PredictionEngine;
use Strategy::PastData;
use Strategy::TrackCondition;
use Strategy::OddsMovement;
use Strategy::Bloodline;
use Strategy::JockeyCompat;
use Strategy::PaddockScore;

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

# --- エンジンの構築 ---
my $engine = PredictionEngine->new;
$engine->add_strategy(past_data       => Strategy::PastData->new);
$engine->add_strategy(track_condition => Strategy::TrackCondition->new);
$engine->add_strategy(odds_movement   => Strategy::OddsMovement->new);
$engine->add_strategy(bloodline       => Strategy::Bloodline->new);
$engine->add_strategy(jockey_compat   => Strategy::JockeyCompat->new);
$engine->add_strategy(paddock_score   => Strategy::PaddockScore->new);

# --- 各戦略が独立して正しい結果を返す ---
subtest 'each strategy returns consistent results' => sub {
    for my $name (qw(past_data track_condition odds_movement bloodline jockey_compat paddock_score)) {
        my $result = $engine->predict($race_data, $name);
        ok(defined $result, "$name returns a defined value: $result");
    }
};

# --- 核心: paddock_score を実行しても他のアルゴリズムが影響を受けない ---
subtest 'strategies are independent (no shared state corruption)' => sub {

    # 基準値を取得
    my $track_before     = $engine->predict($race_data, 'track_condition');
    my $jockey_before    = $engine->predict($race_data, 'jockey_compat');
    my $bloodline_before = $engine->predict($race_data, 'bloodline');

    # paddock_score を複数回実行
    $engine->predict($race_data, 'paddock_score');
    $engine->predict($race_data, 'paddock_score');
    $engine->predict($race_data, 'paddock_score');

    # 他のアルゴリズムの結果が変わっていないことを確認
    my $track_after     = $engine->predict($race_data, 'track_condition');
    my $jockey_after    = $engine->predict($race_data, 'jockey_compat');
    my $bloodline_after = $engine->predict($race_data, 'bloodline');

    is($track_after,     $track_before,     "track_condition is not affected by paddock_score");
    is($jockey_after,    $jockey_before,    "jockey_compat is not affected by paddock_score");
    is($bloodline_after, $bloodline_before, "bloodline is not affected by paddock_score");
};

# --- predict_all で全戦略を一括実行 ---
subtest 'predict_all returns all results' => sub {
    my $results = $engine->predict_all($race_data);
    is(scalar keys %$results, 6, "all 6 strategies returned results");
    for my $name (sort keys %$results) {
        ok(defined $results->{$name}, "$name: $results->{$name}");
    }
};

# --- 新しい戦略の追加が既存に影響しない ---
subtest 'adding new strategy does not affect existing ones' => sub {
    my $before = $engine->predict_all($race_data);

    # 新しい戦略を動的に追加（7つ目）
    {

        package Strategy::Weather;
        use v5.36;
        use Moo;
        with 'PredictionStrategy';
        sub predict ($self, $race_data) { return 0.75; }
    }
    $engine->add_strategy(weather => Strategy::Weather->new);

    # 既存の6つの結果が変わっていないことを確認
    for my $name (sort keys %$before) {
        my $after = $engine->predict($race_data, $name);
        is($after, $before->{$name}, "$name unchanged after adding weather strategy");
    }

    # 新しい戦略も動作する
    is($engine->predict($race_data, 'weather'), 0.75, "new weather strategy works");
};

done_testing;
