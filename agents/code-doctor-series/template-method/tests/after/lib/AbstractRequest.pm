package AbstractRequest;
use v5.36;
use Carp qw(croak);

# 申請処理の骨格（テンプレートメソッド）
# すべての申請はこのフローに従う

sub new ($class, %args) {
    my $self = bless {
        applicant   => $args{applicant} // croak("申請者は必須です"),
        status      => 'pending',
        approved_by => [],
        %args,
    }, $class;
    return $self;
}

# === テンプレートメソッド ===
# このメソッドが処理の骨格。サブクラスは各ステップをオーバーライドする。
sub process ($self) {
    $self->validate_input();
    $self->check_budget();
    $self->route_approval();

    # フック: 上長コメントが必要な申請だけオーバーライド
    if ($self->requires_manager_comment()) {
        $self->request_manager_comment();
    }

    $self->send_notification();
    $self->archive_record();

    return $self->{status};
}

# === 抽象メソッド（サブクラスで必ず実装） ===

sub validate_input ($self) {
    croak ref($self) . "::validate_input() が実装されていません";
}

sub route_approval ($self) {
    croak ref($self) . "::route_approval() が実装されていません";
}

# === フックメソッド（デフォルト実装あり、必要ならオーバーライド） ===

sub requires_manager_comment ($self) { return 0 }

sub request_manager_comment ($self) {

    # デフォルト: 何もしない（必要な申請だけオーバーライド）
    return 1;
}

# === 共通実装（全申請で同じ処理） ===

sub check_budget ($self) {

    # サブクラスで必要に応じてオーバーライド
    return 1;
}

sub send_notification ($self) {
    my $approvers = join(', ', $self->{approved_by}->@*);
    my $type      = $self->request_type_name();
    _send_email(
        to      => $self->{applicant},
        subject => "${type}が承認されました",
        body    => "承認者: $approvers",
    );
    return 1;
}

sub archive_record ($self) {
    my $timestamp = localtime();
    my $type      = $self->request_type_name();
    my $summary   = $self->summary_for_log();
    _append_to_log("[$timestamp] $type $self->{applicant}: $summary ($self->{status})");
    return 1;
}

# サブクラスでオーバーライドして申請種別名を返す
sub request_type_name ($self) { return ref($self) }

# サブクラスでオーバーライドしてログ用サマリーを返す
sub summary_for_log ($self) { return '' }

# --- ユーティリティ ---
sub _send_email    (%args) { return 1 }
sub _append_to_log ($msg)  { return 1 }

1;
