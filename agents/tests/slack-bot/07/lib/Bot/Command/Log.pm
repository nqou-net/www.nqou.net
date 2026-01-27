package Bot::Command::Log;
use Moo;
with 'Bot::Command::Role';

sub match {
    my ($self, $text) = @_;
    if ($text =~ m{^/log\s+(\w+)(?:\s+(--lines\s+(\d+))?)?}) { # 正規表現修正
        return { level => $1, lines => $3 // 10 };
    }
    return undef;
}

sub execute {
    my ($self, $args) = @_;
    return "📋 $args->{level} ログを直近 $args->{lines} 行取得しました...";
}

sub description { "/log <level> [--lines N] : ログを取得します" }

1;
