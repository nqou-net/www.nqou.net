use strict;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

package WorldGenerator {
    use Moo;

    sub generate_zone ($self, $biome) {
        my $terrain  = $self->_create_terrain($biome);
        my $creature = $self->_create_creature($biome);
        my $weather  = $self->_create_weather($biome);

        return {
            terrain  => $terrain,
            creature => $creature,
            weather  => $weather,
        };
    }

    sub generate_transition ($self, $from, $to) {
        my $terrain  = $self->_create_terrain($from);
        my $creature = $self->_create_creature($to);    # BUG!
        my $weather  = $self->_create_weather($from);

        return {
            terrain  => $terrain,
            creature => $creature,
            weather  => $weather,
        };
    }

    sub _create_terrain ($self, $type) {
        if ($type eq 'forest') {
            return { name => '古代樹の森', ground => '苔むした腐葉土', obstacle => '巨木の根' };
        }
        elsif ($type eq 'desert') {
            return { name => '灼熱の砂漠', ground => '流砂', obstacle => 'サボテンの壁' };
        }
        elsif ($type eq 'ocean') {
            return { name => '深淵の海底', ground => '珊瑚礁', obstacle => '海溝の裂け目' };
        }
        else { die "Unknown biome: $type" }
    }

    sub _create_creature ($self, $type) {
        if ($type eq 'forest') {
            return { name => 'エルフの弓兵', hp => 80, attack => '精霊の矢' };
        }
        elsif ($type eq 'desert') {
            return { name => 'サンドワーム', hp => 200, attack => '地中突進' };
        }
        elsif ($type eq 'ocean') {
            return { name => 'クラーケン', hp => 300, attack => '触手の嵐' };
        }
        else { die "Unknown biome: $type" }
    }

    sub _create_weather ($self, $type) {
        if ($type eq 'forest') {
            return { name => '精霊の霧', visibility => 0.6, damage => 0 };
        }
        elsif ($type eq 'desert') {
            return { name => '砂嵐', visibility => 0.2, damage => 5 };
        }
        elsif ($type eq 'ocean') {
            return { name => '大渦潮', visibility => 0.4, damage => 10 };
        }
        else { die "Unknown biome: $type" }
    }
}

1;
