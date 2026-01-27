use strict;
use warnings;
use utf8;
use feature qw(say);

# Dummy subroutines for compilation
sub cmd_deploy { "🚀 $_[0] 環境へのデプロイを開始しました" . ($_[1] ? " (強制)" : "") }
sub cmd_log { "📋 $_[0] ログを直近 $_[1] 行取得しました..." }
sub cmd_sql { "📊 クエリ実行: $_[0]" }

sub handle_message {
    my ($text, $user_role) = @_;
    $text =~ s/^\s+|\s+$//g;

    # 1. デプロイ（エイリアス対応、強制オプション、権限チェック）
    if ($text =~ m{^/(?:deploy|d)\s+(\w+)(?:\s+(--force))?}) {
        my ($target, $force) = ($1, $2);
        
        # 権限ロジックの混入
        if ($target eq 'production' && $user_role ne 'admin') {
            return "⛔ 管理者権限が必要です";
        }
        
        # バリデーションロジックの混入
        my @allowed = qw(production staging);
        unless (grep { $_ eq $target } @allowed) {
            return "エラー: 無効な環境です";
        }
        
        return "🚀 $target 環境へのデプロイを開始しました" . ($force ? " (強制)" : "");
    }
    # 2. ログ取得（オプション解析）
    elsif ($text =~ m{^/log\s+(\w+)(?:\s+--lines\s+(\d+))?}) {
        my ($level, $lines) = ($1, $2 // 10);
        return "📋 $level ログを直近 $lines 行取得しました...";
    }
    # 3. SQL実行（セキュリティチェック）
    elsif ($text =~ m{^/sql\s+"(.+)"}) {
        my $query = $1;
        if ($query =~ /DROP|DELETE/i) {
            return "💥 破壊的なクエリは禁止です";
        }
        return "📊 クエリ実行: $query";
    }
    # 4. ユーザー追加
    elsif ($text =~ m{^/user\s+add\s+(\w+)}) {
        # ...実装省略...
    }
    
    return "不明なコマンドです";
}

1;
