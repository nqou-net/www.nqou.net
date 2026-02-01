package EventState;
use v5.36;
use warnings;
use Moo;

with 'GameState';

# イベントモード: 特殊イベント中（NPC会話など）

has event_name => (is => 'ro', required => 1);
has options    => (is => 'ro', default  => sub { [] });

sub name($self) {'イベント'}

sub available_commands($self) {
    return $self->options;
}

sub on_enter($self, $context) {
    return $self->event_name . 'が始まった。';
}

sub process_command($self, $context, $command) {
    my @opts = @{$self->options};
    if (grep { $_ eq $command } @opts) {
        return {
            message => $command . 'を選択した。',
            done    => 1,
            choice  => $command,
        };
    }
    return {message => 'その選択肢はない。選択肢: ' . join(', ', @opts)};
}

1;
