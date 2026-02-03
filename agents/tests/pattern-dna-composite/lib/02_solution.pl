#!/usr/bin/env perl
use v5.36;
use warnings;

# --- 処方: Compositeパターン ---
# 枝（フォルダ）と葉（ファイル）を同一視する共通インターフェースを導入。
# 再帰構造をクラス内部に隠蔽する。

# 共通インターフェース（Component）
package FileSystemEntry {
    use Moo::Role;
    requires 'print_list';
}

# ファイルクラス（Leaf）
package MyFile {
    use Moo;
    with 'FileSystemEntry';
    
    has name => (is => 'ro', required => 1);

    sub print_list {
        my ($self, $level) = @_;
        $level //= 0;
        my $indent = "  " x $level;
        say "$indent- " . $self->name;
    }
}

# フォルダクラス（Composite）
package MyFolder {
    use Moo;
    with 'FileSystemEntry';
    
    has name => (is => 'ro', required => 1);
    has items => (is => 'rw', default => sub { [] });

    sub add {
        my ($self, $item) = @_;
        # 本当はここで型チェック（FileSystemEntryを実装しているか）推奨
        push @{$self->items}, $item;
    }

    sub print_list {
        my ($self, $level) = @_;
        $level //= 0;
        my $indent = "  " x $level;
        say "$indent+ " . $self->name;

        # 自分自身が「どう再帰するか」を知っている
        foreach my $child (@{$self->items}) {
            $child->print_list($level + 1);
        }
    }
}

package main;

# ファイルシステムの構築（構築部分は変わらない）
my $root = MyFolder->new(name => 'root');
my $bin  = MyFolder->new(name => 'bin');
my $tmp  = MyFolder->new(name => 'tmp');
my $usr  = MyFolder->new(name => 'usr');

$root->add($bin);
$root->add($tmp);
$root->add($usr);

$bin->add(MyFile->new(name => 'vi'));
$bin->add(MyFile->new(name => 'latex'));

$usr->add(MyFile->new(name => 'nobu'));

say "--- After: Compositeパターンによる同一視 ---";
# クライアントコードはこれだけ！条件分岐消滅！
$root->print_list();
