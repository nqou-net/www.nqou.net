package IPFilteredLogParser;
use Moo;
use strict;
use warnings;
use experimental qw(signatures);
use namespace::clean;

# LogParserを継承
extends 'LogParser';

# 抽出したいIPアドレス
has target_ip => (
    is       => 'ro',
    required => 1,
);

# 親クラスのnext_logをオーバーライド（上書き）
sub next_log ($self) {
    # 親クラスのnext_logを呼び出して、ログがある限りループ
    while (defined(my $log = $self->SUPER::next_log)) {
        # IPが一致したらそれを返す
        if ($log->{ip} eq $self->target_ip) {
            return $log;
        }
        # 一致しない場合はループ継続（次の行を読みに行く）
    }
    # 完全に読み終わったらundef
    return undef;
}

1;
