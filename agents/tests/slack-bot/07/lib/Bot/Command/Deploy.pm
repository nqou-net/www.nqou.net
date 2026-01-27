package Bot::Command::Deploy;
use Moo;
with 'Bot::Command::Role';

sub required_role { 'admin' }

sub match {
    my ($self, $text) = @_;
    if ($text =~ m{^/deploy\s+(\w+)(?:\s+(--force))?}) {
        return { target => $1, force => $2 };
    }
    return undef;
}

sub execute {
    my ($self, $args) = @_;
    my $target = $args->{target};
    my $force  = $args->{force} ? "(強制)" : "";
    
    return "🚀 $target 環境へのデプロイを開始しました$force...";
}

sub description { "/deploy <env> [--force] : 指定環境へデプロイします" }

1;
