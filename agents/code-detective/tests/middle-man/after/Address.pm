package Address;
use v5.36;
use Moo;

has prefecture => (is => 'ro', required => 1);

sub shipping_zone ($self) {
    my %zone = (
        '東京都'   => 'kanto',
        '神奈川県' => 'kanto',
        '千葉県'   => 'kanto',
        '大阪府'   => 'kansai',
        '京都府'   => 'kansai',
    );
    return $zone{$self->prefecture} // 'other';
}

1;
