package RoastManager;
use v5.36;

sub new($class) {
    bless {
        profile => {
            temp_start  => 180,
            temp_peak   => 220,
            duration    => 720,    # 秒
            fan_speed   => 65,     # %
            bean_type   => 'Ethiopia Yirgacheffe',
        },
    }, $class;
}

sub profile($self) {
    return $self->{profile};
}

sub update_profile($self, %params) {
    # 直接上書き——前の値は永遠に消える
    $self->{profile}{$_} = $params{$_} for keys %params;
}

# バックアップ？ cpで十分でしょ……
sub save_backup($self, $suffix = 'backup') {
    # 本当はYAMLに書き出してcpしてた
    # でもどれがいつの状態かもう分からない……
    my $filename = "roast_profile_${suffix}.yaml";
    # system("cp roast_profile.yaml $filename");
    return $filename;
}

1;
