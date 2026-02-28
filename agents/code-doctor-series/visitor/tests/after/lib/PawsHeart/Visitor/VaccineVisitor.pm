package PawsHeart::Visitor::VaccineVisitor;
use v5.36;

sub new ($class) {
    return bless {}, $class;
}

sub visit_dog ($self, $dog) {
    return {
        animal   => $dog->name,
        vaccines => [
            { name => '狂犬病', interval => '1年' },
            { name => '混合ワクチン', interval => '1年' },
        ],
    };
}

sub visit_cat ($self, $cat) {
    return {
        animal   => $cat->name,
        vaccines => [
            { name => '3種混合', interval => '1年' },
        ],
    };
}

sub visit_bird ($self, $bird) {
    return {
        animal   => $bird->name,
        vaccines => [],
        note     => '定期的な糞便検査を推奨',
    };
}

sub visit_reptile ($self, $reptile) {
    return {
        animal   => $reptile->name,
        vaccines => [],
        note     => '寄生虫検査を半年に1回推奨',
    };
}

1;
