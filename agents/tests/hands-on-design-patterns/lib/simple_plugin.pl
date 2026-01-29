#!/usr/bin/env perl
use v5.36;
use warnings;

# 第5回: プラグインシステム〜コマンドを外部ファイルで追加
# コード例1: simple_plugin.pl（破綻版）
# ディレクトリ内の.pmファイルを単純に読み込む

package Command {
    use Moo::Role;
    requires 'execute';
}

package CommandFactory {
    use Moo;
    has 'registry' => (is => 'ro', default => sub { {} });

    sub register ($self, $name, $class) {
        $self->registry->{$name} = $class;
        return $self;
    }

    sub create ($self, $name) {
        my $class = $self->registry->{$name};
        return undef unless $class;
        return $class->new;
    }
}

# ===== 単純なプラグインローダー =====
package SimplePluginLoader {
    use Moo;
    use File::Spec;

    has 'plugin_dir' => (is => 'ro', required => 1);
    has 'factory'    => (is => 'ro', required => 1);

    sub load_plugins ($self) {
        my $dir = $self->plugin_dir;

        # 問題: 単純にすべての.pmを読み込む
        opendir(my $dh, $dir) or die "Cannot open $dir: $!";
        my @files = grep {/\.pm$/} readdir($dh);
        closedir($dh);

        for my $file (@files) {
            my $path = File::Spec->catfile($dir, $file);

            # 問題点:
            # - プラグインの依存関係を考慮していない
            # - どのコマンド名で登録するか不明
            # - プラグインのメタ情報がない

            require $path;

            # ファイル名からコマンド名を推測（不確実）
            my $cmd_name = $file;
            $cmd_name =~ s/\.pm$//;
            $cmd_name =~ s/Command$//i;
            $cmd_name = lc($cmd_name);

            # クラス名も推測（不確実）
            my $class_name = $file;
            $class_name =~ s/\.pm$//;

            $self->factory->register($cmd_name, $class_name);
        }
    }
}

sub main {
    say "=== Simple Plugin Loader Demo ===";
    say "";
    say "問題点:";
    say "- プラグインファイルからコマンド名を推測（不確実）";
    say "- 依存関係を考慮していない";
    say "- プラグインのバージョン、説明などのメタ情報がない";
    say "- ロード順序を制御できない";
    say "";
    say "→ プラグインにメタデータを持たせる必要がある";
}

main() unless caller;

1;
