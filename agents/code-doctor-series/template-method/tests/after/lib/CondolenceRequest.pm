package CondolenceRequest;
use v5.36;
use parent 'AbstractRequest';

# 慶弔見舞金申請 — 物語のクライマックスで追加されるサブクラス
# フックメソッド requires_manager_comment() をオーバーライドする唯一の申請

sub new ($class, %args) {
    my $self = $class->SUPER::new(%args);
    $self->{event_type} //= die "慶弔区分は必須です";
    $self->{amount}     //= die "金額は必須です";
    return $self;
}

sub validate_input ($self) {
    my @valid_events = qw(結婚 出産 弔事 傷病);
    die "無効な慶弔区分: $self->{event_type}"
        unless grep { $_ eq $self->{event_type} } @valid_events;
    die "金額は正の数である必要があります"
        unless $self->{amount} > 0;
    return 1;
}

sub route_approval ($self) {

    # 慶弔見舞金は必ず 課長 → 部長 → 人事部長
    push $self->{approved_by}->@*, '課長', '部長', '人事部長';
    $self->{status} = 'approved';
    return 1;
}

# フックメソッドのオーバーライド: 上長コメント必須
sub requires_manager_comment ($self) { return 1 }

sub request_manager_comment ($self) {

    # 上長からの所見コメントを要求する処理
    $self->{manager_comment_required} = 1;
    return 1;
}

sub request_type_name ($self) { return '慶弔見舞金' }

sub summary_for_log ($self) {
    return "$self->{event_type} $self->{amount}円";
}

1;
