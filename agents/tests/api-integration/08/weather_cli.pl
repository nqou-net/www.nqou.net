#!/usr/bin/env perl
# weather_cli.pl - 天気予報アグリゲーター（完成版）
use v5.36;
use Try::Tiny;

# ===================================================
# 天気サービスの共通インターフェース（Role）
# ===================================================
package WeatherAdapter::Role {
    use v5.36;
    use Moo::Role;

    requires 'get_weather';
    requires 'name';
}

# ===================================================
# OpenWeatherMap用Adapter
# ===================================================
package WeatherAdapter::OpenWeatherMap {
    use v5.36;
    use Moo;
    use Try::Tiny;

    has name => (is => 'ro', default => 'OpenWeatherMap');

    with 'WeatherAdapter::Role';

    sub _get_raw_data ($self, $city) {
        # 実際の実装ではHTTP::Tinyでリクエストを送信
        my %mock_data = (
            'Tokyo'    => { name => 'Tokyo',    main => { temp => 25.5, humidity => 60 }, weather => [{ description => '晴れ' }] },
            'Osaka'    => { name => 'Osaka',    main => { temp => 27.2, humidity => 65 }, weather => [{ description => '曇り' }] },
            'Nagoya'   => { name => 'Nagoya',   main => { temp => 26.8, humidity => 62 }, weather => [{ description => '晴れ' }] },
            'Kyoto'    => { name => 'Kyoto',    main => { temp => 28.1, humidity => 58 }, weather => [{ description => '晴れ' }] },
            'Yokohama' => { name => 'Yokohama', main => { temp => 24.9, humidity => 68 }, weather => [{ description => '曇り' }] },
        );
        return $mock_data{$city};
    }

    sub get_weather ($self, $city) {
        try {
            my $data = $self->_get_raw_data($city);
            return unless $data;
            return {
                city        => $data->{name},
                temperature => $data->{main}{temp},
                humidity    => $data->{main}{humidity},
                condition   => $data->{weather}[0]{description},
                source      => $self->name,
            };
        }
        catch {
            warn "[$self->{name}] $city: $_";
            return;
        };
    }
}

# ===================================================
# WeatherStack用Adapter
# ===================================================
package WeatherAdapter::WeatherStack {
    use v5.36;
    use Moo;
    use Try::Tiny;

    has name => (is => 'ro', default => 'WeatherStack');

    with 'WeatherAdapter::Role';

    sub _get_raw_data ($self, $city) {
        my %mock_data = (
            'Tokyo'    => { location => { name => 'Tokyo' },    current => { temperature => 26, humidity => 58, weather_descriptions => ['Sunny'] } },
            'Sapporo'  => { location => { name => 'Sapporo' },  current => { temperature => 19, humidity => 68, weather_descriptions => ['Rain'] } },
            'Sendai'   => { location => { name => 'Sendai' },   current => { temperature => 22, humidity => 65, weather_descriptions => ['Cloudy'] } },
            'Fukuoka'  => { location => { name => 'Fukuoka' },  current => { temperature => 29, humidity => 70, weather_descriptions => ['Sunny'] } },
            'Hiroshima'=> { location => { name => 'Hiroshima'},current => { temperature => 28, humidity => 62, weather_descriptions => ['Clear'] } },
        );
        return $mock_data{$city};
    }

    sub get_weather ($self, $city) {
        try {
            my $data = $self->_get_raw_data($city);
            return unless $data;
            return {
                city        => $data->{location}{name},
                temperature => $data->{current}{temperature},
                humidity    => $data->{current}{humidity},
                condition   => $data->{current}{weather_descriptions}[0],
                source      => $self->name,
            };
        }
        catch {
            warn "[$self->{name}] $city: $_";
            return;
        };
    }
}

# ===================================================
# Facade: 統合インターフェース（キャッシュ＆エラーハンドリング付き）
# ===================================================
package WeatherFacade {
    use v5.36;
    use Moo;

    has adapters        => (is => 'ro', required => 1);
    has cache_ttl       => (is => 'ro', default => 300);
    has max_cache_size  => (is => 'ro', default => 100);
    has use_default     => (is => 'ro', default => 1);
    has default_message => (is => 'ro', default => '情報を取得できませんでした');

    has _cache       => (is => 'ro', default => sub { {} });
    has _cache_order => (is => 'ro', default => sub { [] });
    has _stats       => (is => 'ro', default => sub { { hits => 0, misses => 0, api_calls => 0 } });

    # デフォルト天気データ
    sub _default_weather ($self, $city) {
        return {
            city        => $city,
            temperature => undef,
            humidity    => undef,
            condition   => $self->default_message,
            source      => 'default',
            is_default  => 1,
            from_cache  => 0,
        };
    }

    # キャッシュから取得
    sub _get_from_cache ($self, $city) {
        return unless exists $self->_cache->{$city};

        my $cached = $self->_cache->{$city};
        my $age = time() - $cached->{cached_at};

        if ($age >= $self->cache_ttl) {
            $self->_remove_from_cache($city);
            return;
        }

        # LRU順序を更新
        $self->_cache_order->@* = grep { $_ ne $city } $self->_cache_order->@*;
        push $self->_cache_order->@*, $city;

        return $cached->{data};
    }

    # キャッシュに保存
    sub _set_to_cache ($self, $city, $data) {
        while (scalar($self->_cache_order->@*) >= $self->max_cache_size) {
            my $oldest = shift $self->_cache_order->@*;
            delete $self->_cache->{$oldest};
        }

        $self->_cache->{$city} = {
            data      => $data,
            cached_at => time(),
        };
        push $self->_cache_order->@*, $city;
    }

    # キャッシュから削除
    sub _remove_from_cache ($self, $city) {
        delete $self->_cache->{$city};
        $self->_cache_order->@* = grep { $_ ne $city } $self->_cache_order->@*;
    }

    # 天気情報を取得（メインAPI）
    sub get_weather ($self, $city) {
        # 1. キャッシュをチェック
        if (my $cached = $self->_get_from_cache($city)) {
            $self->_stats->{hits}++;
            return { $cached->%*, from_cache => 1, is_default => 0 };
        }

        $self->_stats->{misses}++;

        # 2. APIから取得（フォールバック付き）
        for my $adapter ($self->adapters->@*) {
            $self->_stats->{api_calls}++;
            my $weather = $adapter->get_weather($city);
            if ($weather) {
                $self->_set_to_cache($city, $weather);
                return { $weather->%*, from_cache => 0, is_default => 0 };
            }
        }

        # 3. すべて失敗 → デフォルト値
        if ($self->use_default) {
            return $self->_default_weather($city);
        }
        return;
    }

    # 統計情報
    sub stats ($self) {
        my $total = $self->_stats->{hits} + $self->_stats->{misses};
        my $hit_rate = $total > 0 ? ($self->_stats->{hits} / $total * 100) : 0;
        return {
            cache_hits   => $self->_stats->{hits},
            cache_misses => $self->_stats->{misses},
            hit_rate     => sprintf("%.1f%%", $hit_rate),
            api_calls    => $self->_stats->{api_calls},
            cache_size   => scalar($self->_cache_order->@*),
        };
    }

    # キャッシュクリア
    sub clear_cache ($self) {
        $self->_cache->%* = ();
        $self->_cache_order->@* = ();
    }
}

# ===================================================
# メイン処理
# ===================================================
package main {
    use v5.36;

    say "=" x 50;
    say "  天気予報アグリゲーター（完成版）";
    say "=" x 50;
    say "";

    # Facadeを初期化
    my $weather = WeatherFacade->new(
        adapters => [
            WeatherAdapter::OpenWeatherMap->new,
            WeatherAdapter::WeatherStack->new,
        ],
        cache_ttl      => 300,   # 5分
        max_cache_size => 50,
        use_default    => 1,
    );

    # 複数都市の天気を取得
    my @cities = qw(Tokyo Osaka Sapporo Nagoya Fukuoka Sendai Unknown);

    say "[天気情報]";
    say "-" x 50;

    for my $city (@cities) {
        my $data = $weather->get_weather($city);

        my $temp = defined $data->{temperature} 
            ? sprintf("%.1f℃", $data->{temperature})
            : "---";

        my $status = "";
        if ($data->{is_default}) {
            $status = "[デフォルト]";
        }
        elsif ($data->{from_cache}) {
            $status = "[キャッシュ]";
        }
        else {
            $status = "[via $data->{source}]";
        }

        printf "%-10s: %-20s %8s %s\n",
            $data->{city}, $data->{condition}, $temp, $status;
    }

    say "";
    say "[2回目の取得（キャッシュから）]";
    say "-" x 50;

    for my $city (qw(Tokyo Osaka Sapporo)) {
        my $data = $weather->get_weather($city);
        my $status = $data->{from_cache} ? "キャッシュから" : "APIから";
        say "$city: $status";
    }

    say "";
    say "[統計情報]";
    say "-" x 50;

    my $stats = $weather->stats;
    say "キャッシュヒット: $stats->{cache_hits}";
    say "キャッシュミス:   $stats->{cache_misses}";
    say "ヒット率:         $stats->{hit_rate}";
    say "API呼び出し回数:  $stats->{api_calls}";
    say "キャッシュサイズ: $stats->{cache_size}";
}
