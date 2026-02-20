package HorsePredictor;
use v5.36;
use Exporter 'import';
our @EXPORT_OK = qw(predict);

# 重み付けキャッシュ（全アルゴリズムで共有）
# NOTE: ここに新しいロジック用の変数も追加していく
my $weight_cache = {};
my @recent_results = ();

my %strategies = (
    past_data => sub ($race_data) {
        # 過去走データ重視
        my $score = 0;
        for my $result ($race_data->{past_results}->@*) {
            my $w = $weight_cache->{$result->{course}} //= 1.0;
            $score += $result->{finish} * $w;
        }
        push @recent_results, $score;
        return $score / scalar($race_data->{past_results}->@*);
    },

    track_condition => sub ($race_data) {
        # 馬場状態重視
        my %track_weights = (good => 1.0, yielding => 0.8, soft => 0.6, heavy => 0.4);
        my $base = $track_weights{ $race_data->{track} } // 0.5;
        # キャッシュに馬場補正値を保存（他のロジックも参照する想定だった）
        $weight_cache->{track_adj} = $base;
        return $base * $race_data->{horse_rating};
    },

    odds_movement => sub ($race_data) {
        # オッズ変動追跡
        my @odds = $race_data->{odds_history}->@*;
        return 0 unless @odds >= 2;
        my $trend = ($odds[-1] - $odds[0]) / $odds[0];
        # 直近結果も加味（共有変数を参照）
        my $bonus = @recent_results ? $recent_results[-1] * 0.1 : 0;
        return (1 - $trend) + $bonus;
    },

    bloodline => sub ($race_data) {
        # 血統指数
        my $sire   = $race_data->{sire_score}   // 50;
        my $dam    = $race_data->{dam_score}     // 50;
        my $score  = ($sire * 0.6 + $dam * 0.4) / 100;
        $weight_cache->{bloodline} = $score;
        return $score;
    },

    jockey_compat => sub ($race_data) {
        # 騎手相性
        my $compat = $race_data->{jockey_score} // 50;
        # キャッシュから血統値を拝借（あれば加算）
        my $bl = $weight_cache->{bloodline} // 0;
        return ($compat / 100) + ($bl * 0.2);
    },

    # 新しく追加 → ここで既存ロジックが壊れ始めた
    paddock_score => sub ($race_data) {
        # パドック映像スコア
        my $visual = $race_data->{paddock_visual} // 50;
        # weight_cache をリセットして自分用に初期化
        # → ★ これが他の全アルゴリズムの計算を汚染する原因
        $weight_cache = { paddock => $visual / 100 };
        push @recent_results, $visual;
        return $visual / 100;
    },
);

sub predict ($race_data, $strategy_name) {
    my $strategy = $strategies{$strategy_name}
        or die "Unknown strategy: $strategy_name";
    return $strategy->($race_data);
}

1;
