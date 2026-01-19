package LogDecorator;
use Moo;
use experimental qw(signatures);

# 包み込む対象（wrapped）を持つ
has wrapped => (
    is       => 'ro',
    does     => 'LogProcessor',
    required => 1,
);

# デフォルトでは、呼び出しをそのまま中身に委譲する
sub next_log ($self) {
    return $self->wrapped->next_log;
}

# 自分自身もLogProcessorとして振る舞う（next_log定義後にwith）
with 'LogProcessor';

1;
