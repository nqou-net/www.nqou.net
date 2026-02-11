package DocumentTemplate::Prototype;
use v5.36;
use Moo;
use Storable qw(dclone);

has type       => (is => 'ro', required => 1);
has department => (is => 'ro', default  => '開発部');
has author     => (is => 'ro', default  => '未設定');
has date       => (is => 'ro', default  => '2025-01-01');
has version    => (is => 'ro', default  => '1.0');
has metadata => (
    is      => 'ro',
    default => sub {
        {
            company      => '株式会社テックソリューション',
            division     => '開発部',
            fiscal_year  => '2025',
            confidential => 1,
        }
    }
);
has sections => (is => 'ro', default => sub { [] });

sub clone($self, %overrides) {
    my $data = dclone(
        {
            type       => $self->type,
            department => $self->department,
            author     => $self->author,
            date       => $self->date,
            version    => $self->version,
            metadata   => $self->metadata,
            sections   => $self->sections,
        }
    );

    for my $key (keys %overrides) {
        if (ref $data->{$key} eq 'HASH' && ref $overrides{$key} eq 'HASH') {
            $data->{$key} = {$data->{$key}->%*, $overrides{$key}->%*};
        }
        else {
            $data->{$key} = $overrides{$key};
        }
    }

    return (ref $self)->new($data->%*);
}

1;

# === プロトタイプレジストリ ===
package DocumentTemplate::Registry;
use v5.36;
use Moo;

has _prototypes => (is => 'ro', default => sub { {} });

sub register($self, $name, $prototype) {
    $self->_prototypes->{$name} = $prototype;
    return $self;
}

sub create($self, $name, %overrides) {
    my $proto = $self->_prototypes->{$name} // die "未登録のテンプレート: $name";
    return $proto->clone(%overrides);
}

sub list_types($self) {
    return sort keys $self->_prototypes->%*;
}

# デフォルトレジストリの構築
sub build_default($class) {
    my $registry = $class->new;

    $registry->register(
        '議事録' => DocumentTemplate::Prototype->new(
            type     => '議事録',
            sections => [{title => '出席者', content => ''}, {title => '議題', content => ''}, {title => '決定事項', content => ''}, {title => '次回予定', content => ''},],
        )
    );

    $registry->register(
        '日報' => DocumentTemplate::Prototype->new(
            type     => '日報',
            sections =>
                [{title => '本日の作業', content => ''}, {title => '進捗状況', content => ''}, {title => '課題・問題', content => ''}, {title => '明日の予定', content => ''},],
        )
    );

    $registry->register(
        '障害報告書' => DocumentTemplate::Prototype->new(
            type     => '障害報告書',
            sections => [
                {title => '障害概要',  content => ''},
                {title => '影響範囲',  content => ''},
                {title => '原因分析',  content => ''},
                {title => '対応内容',  content => ''},
                {title => '再発防止策', content => ''},
            ],
        )
    );

    $registry->register(
        '週報' => DocumentTemplate::Prototype->new(
            type     => '週報',
            sections => [{title => '今週の実績', content => ''}, {title => '来週の計画', content => ''}, {title => '課題・リスク', content => ''},],
        )
    );

    return $registry;
}

1;
