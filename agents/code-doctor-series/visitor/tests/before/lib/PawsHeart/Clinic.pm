package PawsHeart::Clinic;
use v5.36;

# 速水のコード: 3年間ちゃんと動いてきた自慢のシステム
# ... でも爬虫類を足そうとしたらどうなる？

sub new ($class) {
    return bless {}, $class;
}

# 診察レポート生成
# TODO: 爬虫類対応... どこに足せばいいんだ？
sub generate_report ($self, $animal) {
    my $ref = ref($animal);

    if ($ref eq 'PawsHeart::Animal::Dog') {
        return sprintf("【診察レポート】犬: %s (%s)\n体重: %skg\n所見: 一般的な犬の健康診断を実施。",
            $animal->name, $animal->breed, $animal->weight);
    }
    elsif ($ref eq 'PawsHeart::Animal::Cat') {
        my $indoor = $animal->is_indoor ? '室内飼い' : '外飼い';
        return sprintf("【診察レポート】猫: %s (%s)\n飼育形態: %s\n所見: 猫特有の腎臓・泌尿器チェックを実施。",
            $animal->name, $animal->breed, $indoor);
    }
    elsif ($ref eq 'PawsHeart::Animal::Bird') {
        my $fly = $animal->can_fly ? '飛行可能' : '飛行不可';
        return sprintf("【診察レポート】鳥: %s (%s)\n飛行能力: %s\n所見: 羽毛と嘴の状態を確認。",
            $animal->name, $animal->species, $fly);
    }
    else {
        die "未対応の動物です: $ref";  # ここに来たらアウト
    }
}

# 予防接種スケジュール計算
# 同じref()チェックが...また出てくる
sub calc_vaccine_schedule ($self, $animal) {
    my $ref = ref($animal);

    if ($ref eq 'PawsHeart::Animal::Dog') {
        return {
            animal => $animal->name,
            vaccines => [
                { name => '狂犬病', interval => '1年' },
                { name => '混合ワクチン', interval => '1年' },
            ],
        };
    }
    elsif ($ref eq 'PawsHeart::Animal::Cat') {
        return {
            animal => $animal->name,
            vaccines => [
                { name => '3種混合', interval => '1年' },
            ],
        };
    }
    elsif ($ref eq 'PawsHeart::Animal::Bird') {
        return {
            animal => $animal->name,
            vaccines => [],  # 鳥は基本的にワクチン不要
            note => '定期的な糞便検査を推奨',
        };
    }
    else {
        die "未対応の動物です: $ref";
    }
}

# 食事指導レポート
# 3つ目の関数にも同じパターン... コピペ感がすごい
sub generate_diet_plan ($self, $animal) {
    my $ref = ref($animal);

    if ($ref eq 'PawsHeart::Animal::Dog') {
        return sprintf("【食事指導】%s: 体重%skgに対し1日%sg のフードを推奨。",
            $animal->name, $animal->weight, $animal->weight * 20);
    }
    elsif ($ref eq 'PawsHeart::Animal::Cat') {
        my $base = $animal->is_indoor ? 60 : 80;  # 室内猫は少なめ
        return sprintf("【食事指導】%s: %s飼いのため1日%sg のフードを推奨。",
            $animal->name, ($animal->is_indoor ? '室内' : '外'), $base);
    }
    elsif ($ref eq 'PawsHeart::Animal::Bird') {
        return sprintf("【食事指導】%s: シード類を中心に、青菜を毎日添えること。",
            $animal->name);
    }
    else {
        die "未対応の動物です: $ref";
    }
}

1;
