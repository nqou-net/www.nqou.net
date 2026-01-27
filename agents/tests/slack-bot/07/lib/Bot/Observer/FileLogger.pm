package Bot::Observer::FileLogger;
use Moo;
with 'Bot::Observer::Role';
use Time::Piece;

sub update {
    my ($self, $event) = @_;
    my $time = localtime->strftime('%Y-%m-%d %H:%M:%S');
    my $log_line = sprintf "[%s] Command: %s, User: %s, Result: %s",
        $time, 
        $event->{command_name} // 'Unknown',
        $event->{user} // 'Unknown',
        $event->{message} // '';
        
    print "[ファイルログ] $log_line\n";
}

1;
