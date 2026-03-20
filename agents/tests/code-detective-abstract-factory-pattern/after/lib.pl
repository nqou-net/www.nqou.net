use strict;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

package Terrain {
    use Moo;
    has name     => ( is => 'ro', required => 1 );
    has ground   => ( is => 'ro', required => 1 );
    has obstacle => ( is => 'ro', required => 1 );
}

package Creature {
    use Moo;
    has name   => ( is => 'ro', required => 1 );
    has hp     => ( is => 'ro', required => 1 );
    has attack => ( is => 'ro', required => 1 );
}

package Weather {
    use Moo;
    has name       => ( is => 'ro', required => 1 );
    has visibility => ( is => 'ro', required => 1 );
    has damage     => ( is => 'ro', required => 1 );
}

package BiomeFactory {
    use Moo::Role;
    requires 'create_terrain';
    requires 'create_creature';
    requires 'create_weather';
}

package ForestFactory {
    use Moo;
    with 'BiomeFactory';

    sub create_terrain ($self) {
        Terrain->new(
            name => '古代樹の森', ground => '苔むした腐葉土', obstacle => '巨木の根',
        );
    }
    sub create_creature ($self) {
        Creature->new(
            name => 'エルフの弓兵', hp => 80, attack => '精霊の矢',
        );
    }
    sub create_weather ($self) {
        Weather->new(
            name => '精霊の霧', visibility => 0.6, damage => 0,
        );
    }
}

package DesertFactory {
    use Moo;
    with 'BiomeFactory';

    sub create_terrain ($self) {
        Terrain->new(
            name => '灼熱の砂漠', ground => '流砂', obstacle => 'サボテンの壁',
        );
    }
    sub create_creature ($self) {
        Creature->new(
            name => 'サンドワーム', hp => 200, attack => '地中突進',
        );
    }
    sub create_weather ($self) {
        Weather->new(
            name => '砂嵐', visibility => 0.2, damage => 5,
        );
    }
}

package OceanFactory {
    use Moo;
    with 'BiomeFactory';

    sub create_terrain ($self) {
        Terrain->new(
            name => '深淵の海底', ground => '珊瑚礁', obstacle => '海溝の裂け目',
        );
    }
    sub create_creature ($self) {
        Creature->new(
            name => 'クラーケン', hp => 300, attack => '触手の嵐',
        );
    }
    sub create_weather ($self) {
        Weather->new(
            name => '大渦潮', visibility => 0.4, damage => 10,
        );
    }
}

package VolcanoFactory {
    use Moo;
    with 'BiomeFactory';

    sub create_terrain ($self) {
        Terrain->new(
            name => '溶岩の大地', ground => '黒曜石', obstacle => '噴火口',
        );
    }
    sub create_creature ($self) {
        Creature->new(
            name => 'サラマンダー', hp => 250, attack => '火炎ブレス',
        );
    }
    sub create_weather ($self) {
        Weather->new(
            name => '火山灰の雨', visibility => 0.3, damage => 8,
        );
    }
}

package WorldGenerator {
    use Moo;

    has factory => ( is => 'ro', required => 1 );

    sub generate ($self) {
        return {
            terrain  => $self->factory->create_terrain,
            creature => $self->factory->create_creature,
            weather  => $self->factory->create_weather,
        };
    }
}

1;
