package Bot::CommandMediator;
use Moo;
use Types::Standard qw(ArrayRef Object);

has commands  => ( is => 'ro', isa => ArrayRef[Object], default => sub { [] } );
has observers => ( is => 'ro', isa => ArrayRef[Object], default => sub { [] } );

sub register_command {
    my ($self, $command) = @_;
    push @{$self->commands}, $command;
}

sub add_observer {
    my ($self, $observer) = @_;
    push @{$self->observers}, $observer;
}

sub notify_observers {
    my ($self, $event) = @_;
    $_->update($event) for @{$self->observers};
}

sub dispatch {
    my ($self, $text, $user_role, $user_name) = @_;
    
    for my $cmd (@{$self->commands}) {
        if (my $args = $cmd->match($text)) {
            
            # Auth check (simplified for this step, inheriting from prev)
            if ($cmd->can('required_role') && $cmd->required_role ne $user_role) {
                return "⛔ 権限が不足しています（必要権限: " . $cmd->required_role . "）";
            }
            
            my $result_msg = $cmd->execute($args);
            
            $self->notify_observers({
                type         => 'command_executed',
                command_name => ref($cmd),
                user         => $user_name,
                message      => $result_msg,
                args         => $args,
            });
            
            return $result_msg;
        }
    }
    return "不明なコマンドです。";
}
1;
