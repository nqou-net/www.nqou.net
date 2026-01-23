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

    sub accept ($self, $visitor) {
        die "accept must be implemented by subclass";
    }
}

# === Paragraph ===
package Paragraph {
    use Moo;
    use experimental qw(signatures);
    extends 'Element';

    sub accept ($self, $visitor) {
        return $visitor->visit_paragraph($self);
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

    sub accept ($self, $visitor) {
        return $visitor->visit_heading($self);
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

    sub accept ($self, $visitor) {
        return $visitor->visit_code_block($self);
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

# === HtmlConverter ===
package HtmlConverter {
    use Moo;
    use experimental qw(signatures);

    sub visit_heading ($self, $element) {
        my $level = $element->level;
        return "<h$level>" . $element->content . "</h$level>";
    }

    sub visit_paragraph ($self, $element) {
        return "<p>" . $element->content . "</p>";
    }

    sub visit_code_block ($self, $element) {
        my $lang = $element->language;
        if ($lang) {
            return "<pre><code class=\"language-$lang\">" 
                   . $element->content 
                   . "</code></pre>";
        }
        return "<pre><code>" . $element->content . "</code></pre>";
    }
}

# === TextConverter ===
package TextConverter {
    use Moo;
    use experimental qw(signatures);

    sub visit_heading ($self, $element) {
        my $level = $element->level;
        my $prefix = "=" x (7 - $level);
        return "$prefix " . $element->content;
    }

    sub visit_paragraph ($self, $element) {
        return $element->content;
    }

    sub visit_code_block ($self, $element) {
        my $content = $element->content;
        $content =~ s/\n$//;
        return "---\n" . $content . "\n---";
    }
}

# === WordCounter ===
package WordCounter {
    use Moo;
    use experimental qw(signatures);

    has total_chars => (
        is      => 'rw',
        default => 0,
    );

    sub visit_heading ($self, $element) {
        my $chars = length($element->content);
        $self->total_chars($self->total_chars + $chars);
        return $chars;
    }

    sub visit_paragraph ($self, $element) {
        my $chars = length($element->content);
        $self->total_chars($self->total_chars + $chars);
        return $chars;
    }

    sub visit_code_block ($self, $element) {
        return 0;
    }

    sub get_total ($self) {
        return $self->total_chars;
    }
}

# === LinkExtractor ===
package LinkExtractor {
    use Moo;
    use experimental qw(signatures);

    has links => (
        is      => 'rw',
        default => sub { [] },
    );

    sub visit_heading ($self, $element) {
        $self->_extract_links($element->content);
        return;
    }

    sub visit_paragraph ($self, $element) {
        $self->_extract_links($element->content);
        return;
    }

    sub visit_code_block ($self, $element) {
        return;
    }

    sub _extract_links ($self, $text) {
        while ($text =~ m{(https?://[^\s<>\"]+)}g) {
            push $self->links->@*, $1;
        }
    }

    sub get_links ($self) {
        return $self->links->@*;
    }
}

# === メイン処理 ===
package main {
    my $markdown = <<'MARKDOWN';
# ドキュメント変換ツール

このツールはMarkdownをHTMLに変換できます。
詳細は https://example.com/docs を参照してください。

## 使い方

公式サイト https://example.com からダウンロードできます。

```perl
my $parser = Parser->new();
my @elements = $parser->parse($text);
```

上記のコードで使えます。
MARKDOWN

    my $parser = Parser->new();
    my @elements = $parser->parse($markdown);

    say "=" x 60;
    say "  ドキュメント変換ツール - Visitorパターンのデモ";
    say "=" x 60;

    say "\n【HTML出力】";
    my $html_converter = HtmlConverter->new();
    for my $elem (@elements) {
        say $elem->accept($html_converter);
    }

    say "\n【テキスト出力】";
    my $text_converter = TextConverter->new();
    for my $elem (@elements) {
        say $elem->accept($text_converter);
    }

    say "\n【文字数カウント】";
    my $counter = WordCounter->new();
    for my $elem (@elements) {
        $elem->accept($counter);
    }
    say "総文字数: " . $counter->get_total . " 文字";

    say "\n【リンク抽出】";
    my $extractor = LinkExtractor->new();
    for my $elem (@elements) {
        $elem->accept($extractor);
    }
    for my $link ($extractor->get_links) {
        say "  - $link";
    }

    say "\n" . "=" x 60;
    say "  完了！";
    say "=" x 60;
}
