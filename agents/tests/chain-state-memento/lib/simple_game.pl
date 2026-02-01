#!/usr/bin/env perl
use v5.36;
use warnings;

# 第1回: 冒険の始まり - シンプルなゲームループ（if/else版）
# 「北に進む」「調べる」などの基本コマンドを処理するシンプルなゲーム

package Game {
    use Moo;

    has location => (is => 'rw', default => '森の入り口');
    has running  => (is => 'rw', default => 1);

    sub describe_location($self) {
        my %descriptions = (
            '森の入り口' => '薄暗い森の入り口に立っている。北に小道が続いている。',
            '小道'    => '木々に囲まれた小道。東に古い小屋が見える。北には泉がある。',
            '古い小屋'  => '朽ちかけた小屋。何か光るものがある。',
            '泉'     => '澄んだ水の泉。ここで休息できそうだ。',
        );
        return $descriptions{$self->location} // '見知らぬ場所にいる。';
    }

    sub process_command($self, $input) {

        # すべてのコマンドをif/elseで判定
        if ($input eq '北') {
            if ($self->location eq '森の入り口') {
                $self->location('小道');
                return '北へ進んだ。';
            }
            elsif ($self->location eq '小道') {
                $self->location('泉');
                return '泉にたどり着いた。';
            }
            else {
                return 'そちらには進めない。';
            }
        }
        elsif ($input eq '東') {
            if ($self->location eq '小道') {
                $self->location('古い小屋');
                return '古い小屋に入った。';
            }
            else {
                return 'そちらには進めない。';
            }
        }
        elsif ($input eq '南') {
            if ($self->location eq '小道') {
                $self->location('森の入り口');
                return '森の入り口に戻った。';
            }
            elsif ($self->location eq '泉') {
                $self->location('小道');
                return '小道に戻った。';
            }
            else {
                return 'そちらには進めない。';
            }
        }
        elsif ($input eq '西') {
            if ($self->location eq '古い小屋') {
                $self->location('小道');
                return '小道に戻った。';
            }
            else {
                return 'そちらには進めない。';
            }
        }
        elsif ($input eq '調べる') {
            if ($self->location eq '古い小屋') {
                return '古びた鍵を見つけた！';
            }
            else {
                return '特に何も見つからない。';
            }
        }
        elsif ($input eq '休む') {
            if ($self->location eq '泉') {
                return '泉の水で体力が回復した。';
            }
            else {
                return 'ここでは休めない。';
            }
        }
        elsif ($input eq 'ヘルプ') {
            return 'コマンド: 北, 南, 東, 西, 調べる, 休む, 終了';
        }
        elsif ($input eq '終了') {
            $self->running(0);
            return 'ゲームを終了します。';
        }
        else {
            return 'そのコマンドは分からない。「ヘルプ」で確認しよう。';
        }
    }

    sub run($self) {
        say '=== タイムトラベル冒険ゲーム ===';
        say '';

        while ($self->running) {
            say '現在地: ' . $self->location;
            say $self->describe_location();
            print '> ';
            my $input = <STDIN>;
            chomp($input);
            my $result = $self->process_command($input);
            say $result;
            say '';
        }
    }
}

# メイン処理（require時はスキップ）
unless (caller) {
    my $game = Game->new;
    $game->run;
}

1;
