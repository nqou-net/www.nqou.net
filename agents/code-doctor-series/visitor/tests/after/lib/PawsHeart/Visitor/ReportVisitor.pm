package PawsHeart::Visitor::ReportVisitor;
use v5.36;

sub new ($class) {
    return bless {}, $class;
}

sub visit_dog ($self, $dog) {
    return sprintf("【診察レポート】犬: %s (%s)\n体重: %skg\n所見: 一般的な犬の健康診断を実施。",
        $dog->name, $dog->breed, $dog->weight);
}

sub visit_cat ($self, $cat) {
    my $indoor = $cat->is_indoor ? '室内飼い' : '外飼い';
    return sprintf("【診察レポート】猫: %s (%s)\n飼育形態: %s\n所見: 猫特有の腎臓・泌尿器チェックを実施。",
        $cat->name, $cat->breed, $indoor);
}

sub visit_bird ($self, $bird) {
    my $fly = $bird->can_fly ? '飛行可能' : '飛行不可';
    return sprintf("【診察レポート】鳥: %s (%s)\n飛行能力: %s\n所見: 羽毛と嘴の状態を確認。",
        $bird->name, $bird->species, $fly);
}

sub visit_reptile ($self, $reptile) {
    return sprintf("【診察レポート】爬虫類: %s (%s)\n適正温度: %s℃\n所見: 鱗の状態と脱皮周期を確認。",
        $reptile->name, $reptile->species, $reptile->temperature);
}

1;
