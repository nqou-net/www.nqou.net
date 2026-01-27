use strict;
use warnings;
use utf8;
use feature qw(say);

# コマンド実行シミュレーション（コンソールで動作確認）
while (my $line = <STDIN>) {
    chomp $line;
    say handle_message($line);
}

sub handle_message {
    my ($text) = @_;
    $text =~ s/^\s+|\s+$//g;

    if ($text =~ m{^/deploy\s+(\w+)}) {
        my $target = $1;
        return cmd_deploy($target);
    }
    elsif ($text =~ m{^/restart\s+(\w+)}) {
        my $server = $1;
        return cmd_restart($server);
    }
    elsif ($text eq '/status') {
        return cmd_status();
    }
    else {
        return "不明なコマンドです: $text";
    }
}

sub cmd_deploy {
    my $target = shift;
    my @allowed_envs = qw(production staging development);
    unless (grep { $_ eq $target } @allowed_envs) {
        return "⚠️ エラー: 指定可能な環境は @allowed_envs のみです。";
    }
    return "🚀 $target 環境へのデプロイを開始しました...";
}

sub cmd_restart {
    my $server = shift;
    return "🔄 サーバー $server を再起動しています...";
}

sub cmd_status {
    return "✅ 現在のシステム稼働状況: オールグリーン";
}
