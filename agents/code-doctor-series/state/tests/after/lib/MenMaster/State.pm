package MenMaster::State;
use v5.36;

# 状態の基底クラス（ロール）
# 各状態が「自分に許可された操作」だけを定義する

sub new($class, %args) {
    return bless { context => $args{context} }, $class;
}

sub context($self) { $self->{context} }

sub take_order($self, $, $ = undef) {
    die $self->_error('注文受付');
}

sub start_boiling($self) {
    die $self->_error('茹で開始');
}

sub start_topping($self) {
    die $self->_error('盛り付け');
}

sub serve($self) {
    die $self->_error('提供');
}

sub name($self) {
    my $class = ref $self;
    $class =~ s/.*:://;
    return $class;
}

sub _error($self, $action) {
    return sprintf "%s状態では「%s」はできません\n", $self->name, $action;
}

1;
