package Bot::CommandMediator;
use Moo;
use Types::Standard qw(ArrayRef Object);

has commands => (
    is => 'ro',
    isa => ArrayRef[Object],
    default => sub { [] },
);

sub register_command {
    my ($self, $command) = @_;
    push @{$self->commands}, $command;
}

sub dispatch {
    my ($self, $text, $user_role) = @_;
    
    for my $cmd (@{$self->commands}) {
        if (my $args = $cmd->match($text)) {
            # 権限チェック一元化
            if ($cmd->can('required_role') && $cmd->required_role ne $user_role) {
                return "⛔ 権限が不足しています（必要権限: " . $cmd->required_role . "）";
            }
            return $cmd->execute($args);
        }
    }
    return "不明なコマンドです。";
}
1;
