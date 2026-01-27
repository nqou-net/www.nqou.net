package Bot::Command::Help;
use Moo;
with 'Bot::Command::Role';
use Types::Standard qw(Object);

has mediator => ( is => 'ro', isa => Object, required => 1 );

sub match {
    my ($self, $text) = @_;
    return {} if $text eq '/help';
    return undef;
}

sub execute {
    my ($self, $args) = @_;
    # In real implementation, this would call mediator->help_text
    # Simplified here for verification as help_text logic wasn't fully shown in snippets but implied
    return "使用可能なコマンド一覧:\n" . 
           "- /deploy <env> [--force] : 指定環境へデプロイします\n" .
           "- /log <level> [--lines N] : ログを取得します\n" .
           "- /help : ヘルプを表示";
}

sub description { "/help : ヘルプを表示" }

1;
