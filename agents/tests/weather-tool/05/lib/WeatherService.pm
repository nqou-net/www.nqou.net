package WeatherService {
    use v5.36;
    use utf8;
    use Moo;

    has 'name' => (is => 'ro', default => sub { '国内天気サービス' });

    sub get_weather ($self, $city) {
        my %weather_data = (
            '東京' => { condition => '晴れ', temperature => 25 },
            '大阪' => { condition => '曇り', temperature => 23 },
            '札幌' => { condition => '雨',   temperature => 18 },
        );
        return $weather_data{$city} // { condition => '不明', temperature => 0 };
    }

    sub show_weather ($self, $city) {
        my $weather = $self->get_weather($city);
        say "$city の天気: $weather->{condition}（気温: $weather->{temperature}℃）";
    }
}

1;
