package OldWeatherAPI {
    use v5.36;
    use utf8;
    use Moo;

    sub fetch_weather_info ($self, $location) {
        my %data = (
            '東京' => '晴れ/25度',
            '大阪' => '曇り/23度',
            '名古屋' => '晴れ/26度',
        );
        return $data{$location} // '情報なし';
    }
}

1;
