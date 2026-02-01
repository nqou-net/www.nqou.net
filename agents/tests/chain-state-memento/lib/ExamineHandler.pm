package ExamineHandler;
use v5.36;
use warnings;
use Moo;

with 'CommandHandler';

# 調べるコマンドを処理するハンドラ

my %DISCOVERIES = (
    '古い小屋' => {item => '古びた鍵', message => '古びた鍵を見つけた！'},
    '泉'    => {item => '回復薬',  message => '泉のほとりで回復薬を見つけた！'},
);

sub can_handle($self, $context, $command) {
    return $command eq '調べる';
}

sub handle($self, $context, $command) {
    my $location  = $context->{location};
    my $discovery = $DISCOVERIES{$location};

    if ($discovery) {
        my $inventory = $context->{inventory} //= [];
        my $has_item  = grep { $_ eq $discovery->{item} } @$inventory;

        if (!$has_item) {
            push @$inventory, $discovery->{item};
            return {
                handled => 1,
                message => $discovery->{message},
            };
        }
        return {
            handled => 1,
            message => '他には何もない。',
        };
    }

    return {
        handled => 1,
        message => '特に何も見つからない。',
    };
}

1;
