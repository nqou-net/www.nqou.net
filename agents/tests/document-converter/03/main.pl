#!/usr/bin/env perl
# 言語: perl
# バージョン: 5.36以上
# 依存: Moo

use v5.36;

# === Element（基底クラス） ===
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

# === Paragraph ===
package Paragraph {
    use Moo;
    use experimental qw(signatures);
    extends 'Element';

    sub type ($self) {
        return 'paragraph';
    }
}

# === Heading ===
package Heading {
    use Moo;
    use experimental qw(signatures);
    extends 'Element';

    has level => (
        is      => 'ro',
        default => 1,
    );

    sub type ($self) {
        return 'heading';
    }
}

# === CodeBlock ===
package CodeBlock {
    use Moo;
    use experimental qw(signatures);
    extends 'Element';

    has language => (
        is      => 'ro',
        default => '',
    );

    sub type ($self) {
        return 'code_block';
    }
}

# === Parser ===
package Parser {
    use Moo;
    use experimental qw(signatures);

    sub parse ($self, $text) {
        my @elements;
        my @lines = split /\n/, $text;
        
        my $in_code_block = 0;
        my $code_content = '';
        my $code_lang = '';
        
        for my $line (@lines) {
            if ($line =~ /^```(\w*)/) {
                if ($in_code_block) {
                    push @elements, CodeBlock->new(
                        content  => $code_content,
                        language => $code_lang,
                    );
                    $code_content = '';
                    $code_lang = '';
                    $in_code_block = 0;
                } else {
                    $code_lang = $1 // '';
                    $in_code_block = 1;
                }
                next;
            }
            
            if ($in_code_block) {
                $code_content .= $line . "\n";
                next;
            }
            
            next if $line =~ /^\s*$/;
            
            if ($line =~ /^(#+)\s+(.+)/) {
                my $level = length($1);
                my $content = $2;
                push @elements, Heading->new(
                    content => $content,
                    level   => $level,
                );
                next;
            }
            
            push @elements, Paragraph->new(content => $line);
        }
        
        return @elements;
    }
}

# === 変換関数（if/else地獄） ===
package main {
    use experimental qw(signatures);

    sub to_html ($element) {
        my $type = $element->type;
        
        if ($type eq 'heading') {
            my $level = $element->level;
            return "<h$level>" . $element->content . "</h$level>";
        }
        elsif ($type eq 'paragraph') {
            return "<p>" . $element->content . "</p>";
        }
        elsif ($type eq 'code_block') {
            my $lang = $element->language;
            if ($lang) {
                return "<pre><code class=\"language-$lang\">" 
                       . $element->content 
                       . "</code></pre>";
            }
            return "<pre><code>" . $element->content . "</code></pre>";
        }
        else {
            return $element->content;
        }
    }

    sub to_text ($element) {
        my $type = $element->type;
        
        if ($type eq 'heading') {
            my $level = $element->level;
            my $prefix = "=" x (7 - $level);
            return "$prefix " . $element->content;
        }
        elsif ($type eq 'paragraph') {
            return $element->content;
        }
        elsif ($type eq 'code_block') {
            return "---\n" . $element->content . "---";
        }
        else {
            return $element->content;
        }
    }

    my $markdown = <<'MARKDOWN';
# タイトル

これは段落です。

```perl
my $x = 1;
```
MARKDOWN

    my $parser = Parser->new();
    my @elements = $parser->parse($markdown);

    say "=== HTML出力 ===";
    for my $elem (@elements) {
        say to_html($elem);
    }

    say "\n=== テキスト出力 ===";
    for my $elem (@elements) {
        say to_text($elem);
    }
}
