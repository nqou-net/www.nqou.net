#!/usr/bin/env perl
# 言語: perl
# バージョン: 5.36以上
# 依存: Moo

use v5.36;

# === Element ===
package Element {
    use Moo;
    use experimental qw(signatures);

    has content => (
        is       => 'ro',
        required => 1,
    );

    sub type ($self) {
        return 'element';
    }
}

# === Parser ===
package Parser {
    use Moo;
    use experimental qw(signatures);

    sub parse ($self, $text) {
        my @elements;
        my @lines = split /\n/, $text;
        
        for my $line (@lines) {
            next if $line =~ /^\s*$/;
            push @elements, Element->new(content => $line);
        }
        
        return @elements;
    }
}

# === メイン処理 ===
package main {
    my $markdown = <<'MARKDOWN';
これは最初の段落です。

これは二番目の段落です。
長い文章も一つの段落として扱われます。
MARKDOWN

    my $parser = Parser->new();
    my @elements = $parser->parse($markdown);

    say "パース結果: " . scalar(@elements) . " 個の要素";
    say "-" x 40;

    for my $elem (@elements) {
        say "タイプ: " . $elem->type;
        say "内容: " . $elem->content;
        say "-" x 40;
    }
}
