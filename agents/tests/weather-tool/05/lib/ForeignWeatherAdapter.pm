package ForeignWeatherAdapter {
    use v5.36;
    use utf8;
    use Moo;

    has 'foreign_service' => (is => 'ro', required => 1);
    has 'name'            => (is => 'ro', default => sub { '海外天気サービス' });

    my %CONDITION_MAP = (
        'Sunny'   => '晴れ',
        'Cloudy'  => '曇り',
        'Rainy'   => '雨',
        'Unknown' => '不明',
    );

    sub get_weather ($self, $city) {
        my $codes = $self->foreign_service->city_codes;
        my $city_code = $codes->{$city};

        unless ($city_code) {
            return { condition => '不明', temperature => 0 };
        }

        my $result = $self->foreign_service->retrieve_conditions($city_code);
        my ($condition_en, $temp) = @$result;
        my $condition_ja = $CONDITION_MAP{$condition_en} // '不明';

        return {
            condition   => $condition_ja,
            temperature => $temp,
        };
    }

    sub show_weather ($self, $city) {
        my $weather = $self->get_weather($city);
        say "$city の天気: $weather->{condition}（気温: $weather->{temperature}℃）";
    }
}

1;
