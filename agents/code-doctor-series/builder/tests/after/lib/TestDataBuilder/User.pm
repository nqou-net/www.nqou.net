package TestDataBuilder::User;
use v5.36;
use Moo;
with 'Role::Builder';

has _overrides => (is => 'ro', default => sub { {} });

sub _defaults($self) {
    return {
        id         => 1001,
        name       => 'テスト太郎',
        email      => 'test@example.com',
        age        => 30,
        address    => '東京都渋谷区',
        phone      => '090-1234-5678',
        created_at => '2025-01-01T00:00:00+09:00',
        status     => 'active',
    };
}

sub with_id($self, $id)           { $self->_with(id => $id) }
sub with_name($self, $name)       { $self->_with(name => $name) }
sub with_email($self, $email)     { $self->_with(email => $email) }
sub with_age($self, $age)         { $self->_with(age => $age) }
sub with_status($self, $status)   { $self->_with(status => $status) }
sub with_address($self, $address) { $self->_with(address => $address) }

sub _with($self, $key, $value) {
    return (ref $self)->new(
        _overrides => { $self->_overrides->%*, $key => $value },
    );
}

sub build($self) {
    my $data = $self->_merge_deep($self->_defaults, $self->_overrides);

    # バリデーション: 必須フィールドの存在確認
    for my $required (qw(id name email status)) {
        die "必須フィールド '$required' が未設定です"
            unless defined $data->{$required};
    }

    return $data;
}

1;
