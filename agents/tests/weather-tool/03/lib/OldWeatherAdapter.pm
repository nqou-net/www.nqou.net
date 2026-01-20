package OldWeatherAdapter {
    use v5.36;
    use utf8;
    use Moo;

    # 委譲先: OldWeatherAPIのインスタンス
    has 'old_api' => (
        is       => 'ro',
        required => 1,
    );

    # WeatherServiceと同じインターフェース
    sub get_weather ($self, $city) {
        # OldWeatherAPIのメソッドを呼び出し（委譲）
        my $info = $self->old_api->fetch_weather_info($city);

        # 戻り値の変換
        if ($info eq '情報なし') {
            return { condition => '不明', temperature => 0 };
        }

        my ($condition, $temp_str) = split '/', $info;
        $temp_str =~ s/度$//;

        return {
            condition   => $condition,
            temperature => int($temp_str),
        };
    }

    sub show_weather ($self, $city) {
        my $weather = $self->get_weather($city);
        say "$city の天気: $weather->{condition}（気温: $weather->{temperature}℃）";
    }
}

1;
