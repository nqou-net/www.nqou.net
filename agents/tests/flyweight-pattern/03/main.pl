#!/usr/bin/env perl
use v5.36;
use Devel::Size qw(total_size);

package BulletType {
    use Moo;

    has shape => (is => 'ro', required => 1);
    has color => (is => 'ro', required => 1);
    has size  => (is => 'ro', required => 1);
    has char  => (is => 'ro', required => 1);

    sub render($self, $x, $y) {
        my $char = $self->char;
        print "$char";
    }

    sub describe($self) {
        my $shape = $self->shape;
        my $color = $self->color;
        return "[$color $shape]";
    }
}

package BulletFactory {
    use Moo;

    has _cache => (is => 'ro', default => sub { {} });

    has _definitions => (
        is      => 'ro',
        default => sub {
            {
                red_circle   => { shape => 'circle', color => 'red',    size => 8,  char => '●' },
                blue_star    => { shape => 'star',   color => 'blue',   size => 12, char => '★' },
                green_laser  => { shape => 'laser',  color => 'green',  size => 4,  char => '|' },
                yellow_arrow => { shape => 'arrow',  color => 'yellow', size => 6,  char => '→' },
                purple_wave  => { shape => 'wave',   color => 'purple', size => 10, char => '〜' },
            }
        },
    );

    sub get($self, $type_key) {
        my $cache = $self->_cache;
        my $defs  = $self->_definitions;

        $cache->{$type_key} //= do {
            my $def = $defs->{$type_key}
                or die "Unknown bullet type: $type_key";
            BulletType->new(%$def);
        };

        return $cache->{$type_key};
    }

    sub cache_count($self) {
        return scalar(keys %{$self->_cache});
    }

    sub list_cached($self) {
        return keys %{$self->_cache};
    }
}

# メイン処理
my $factory = BulletFactory->new;
my @type_keys = qw(red_circle blue_star green_laser yellow_arrow purple_wave);

# 1000発の弾を生成
my @bullets;
for my $i (0 .. 999) {
    my $type_key = $type_keys[$i % 5];
    push @bullets, {
        type => $factory->get($type_key),
        x    => $i % 50,
        y    => int($i / 50),
        vx   => 0,
        vy   => 1,
    };
}

say "=== 弾幕シューティングエンジン ===";
say "弾の総数: " . scalar(@bullets);
say "BulletTypeオブジェクト数: " . $factory->cache_count;
say "キャッシュ内容: " . join(", ", $factory->list_cached);
say "";

# メモリ使用量
my $size = total_size(\@bullets);
say "メモリ使用量: " . sprintf("%.1f", $size / 1024) . "KB";
