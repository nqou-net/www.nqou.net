package PawsHeart::Visitor::DietVisitor;
use v5.36;

sub new ($class) {
    return bless {}, $class;
}

sub visit_dog ($self, $dog) {
    return sprintf("【食事指導】%s: 体重%skgに対し1日%sg のフードを推奨。",
        $dog->name, $dog->weight, $dog->weight * 20);
}

sub visit_cat ($self, $cat) {
    my $base = $cat->is_indoor ? 60 : 80;
    return sprintf("【食事指導】%s: %s飼いのため1日%sg のフードを推奨。",
        $cat->name, ($cat->is_indoor ? '室内' : '外'), $base);
}

sub visit_bird ($self, $bird) {
    return sprintf("【食事指導】%s: シード類を中心に、青菜を毎日添えること。",
        $bird->name);
}

sub visit_reptile ($self, $reptile) {
    return sprintf("【食事指導】%s: 適正温度%s℃を維持し、種に応じた生餌または配合飼料を給餌。",
        $reptile->name, $reptile->temperature);
}

1;
