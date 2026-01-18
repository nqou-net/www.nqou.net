package LogDecorator;
use Moo;
use experimental qw(signatures);

# 包み込む対象（wrapped）を持つ
has wrapped => (
    is       => 'ro',
    does     => 'LogProcessor', # LogProcessorの役割を持つものしか受け取らない
    required => 1,
    handles  => [qw(next_log)], # デフォルトでは、呼び出しをそのまま中身に委譲する
);

# 自分自身もLogProcessorとして振る舞う
# handlesでnext_logが生成された後に適用する
with 'LogProcessor';

1;
