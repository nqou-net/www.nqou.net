#!/usr/bin/env perl
use v5.36;
use warnings;

# --- 症状: 部分-全体表現不統一症 ---
# ファイルとフォルダを別々のものとして扱っているため、
# 利用側（クライアント）で型チェックと分岐が必要になっている。

# ファイルクラス（葉）
package MyFile {
    use Moo;
    has name => (is => 'ro', required => 1);
}

# フォルダクラス（枝）
package MyFolder {
    use Moo;
    has name => (is => 'ro', required => 1);
    has items => (is => 'rw', default => sub { [] });

    sub add {
        my ($self, $item) = @_;
        push @{$self->items}, $item;
    }
}

package main;

# ファイルシステムの構築
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

# 複雑な再帰処理（ここが問題！）
sub print_structure {
    my ($item, $level) = @_;
    $level //= 0;
    my $indent = "  " x $level;

    # 型によって処理を分岐させている
    if ($item->isa('MyFile')) {
        say "$indent- " . $item->name;
    }
    elsif ($item->isa('MyFolder')) {
        say "$indent+ " . $item->name;
        
        # フォルダなら中身をループして再帰呼び出し
        foreach my $child (@{$item->items}) {
            print_structure($child, $level + 1);
        }
    }
    else {
        warn "Unknown item type";
    }
}

say "--- Before: if文による分岐 ---";
print_structure($root);
