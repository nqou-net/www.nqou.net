package ForeignWeatherService {
    use v5.36;
    use utf8;
    use Moo;

    sub retrieve_conditions ($self, $city_code) {
        my %data = (
            'NYC' => ['Sunny',  20],
            'LON' => ['Cloudy', 15],
            'PAR' => ['Rainy',  12],
        );
        return $data{$city_code} // ['Unknown', 0];
    }

    sub city_codes ($self) {
        return {
            'ニューヨーク' => 'NYC',
            'ロンドン'     => 'LON',
            'パリ'         => 'PAR',
        };
    }
}

1;
