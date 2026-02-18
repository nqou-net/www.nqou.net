#!/usr/bin/env perl
# v5.34互換テストランナー — 記事コードはv5.36前提だが、テスト環境用に互換シムを挟む
use strict;
use warnings;
use File::Temp qw(tempdir);
use File::Copy;
use File::Find;
use File::Path qw(make_path);
use File::Basename;

my $target_dir = shift @ARGV or die "Usage: $0 <before|after dir>\n";
die "Directory '$target_dir' not found" unless -d $target_dir;

my $tmpdir = tempdir(CLEANUP => 1);

# コピーして use v5.36 を v5.34互換に変換
find(
    sub {
        return unless -f $_;
        my $rel = $File::Find::name;
        $rel =~ s{^\Q$target_dir\E/?}{};
        my $dest = "$tmpdir/$rel";
        make_path(dirname($dest));

        open my $in,  '<', $_    or die "Cannot read $_: $!";
        open my $out, '>', $dest or die "Cannot write $dest: $!";
        while (<$in>) {
            if (/^use v5\.36;/) {
                print $out "use v5.34;\nuse feature 'signatures';\nno warnings 'experimental::signatures';\nuse utf8;\n";
            }
            else {
                print $out $_;
            }
        }
        close $in;
        close $out;
        chmod 0644, $dest;
    },
    $target_dir
);

chdir $tmpdir or die "Cannot chdir to $tmpdir: $!";
exec("prove", "-v", "t/");
