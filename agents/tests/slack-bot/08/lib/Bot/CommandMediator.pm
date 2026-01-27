package Bot::CommandMediator;
use Moo;
use Types::Standard qw(ArrayRef Object);
use Try::Tiny;
use Sys::SigAction qw( set_sig_handler );

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
            
            if ($cmd->can('required_role') && $cmd->required_role ne $user_role) {
                return "⛔ 権限が不足しています（必要権限: " . $cmd->required_role . "）";
            }

            my $result_msg;
            try {
                my $timeout = 2; # Shortened for test
                eval {
                    local $SIG{ALRM} = sub { die "Timeout\n" };
                    alarm $timeout;
                    $result_msg = $cmd->execute($args);
                    alarm 0;
                };
                if ($@) { die $@ };

                $self->notify_observers({
                    type         => 'success',
                    command_name => ref($cmd),
                    user         => $user_name,
                    message      => $result_msg,
                });
            }
            catch {
                my $error = $_;
                if ($error =~ /Timeout/) {
                    $result_msg = "⏱️ 処理がタイムアウトしました";
                    $error = "Timeout";
                } else {
                    $result_msg = "💥 エラーが発生しました: $error";
                }
                
                $self->notify_observers({
                    type    => 'error',
                    command => ref($cmd),
                    error   => $error,
                    user    => $user_name,
                });
            };
            
            return $result_msg;
        }
    }
    return "不明なコマンドです。";
}
1;
