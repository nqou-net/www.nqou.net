package NewsScraper;
# 言語: perl
# バージョン: 5.36以上
# 依存: Moo, WebScraper

use v5.36;
use Moo;
use experimental qw(signatures);

# WebScraperクラスを継承
extends 'WebScraper';

# extract_dataメソッドをオーバーライド
sub extract_data ($self, $dom) {
    my @headlines;
    
    # h2.headlineから見出しを抽出
    for my $headline ($dom->find('h2.headline')->each) {
        push @headlines, $headline->text;
    }
    
    return @headlines;
}

# save_dataメソッドをオーバーライド
sub save_data ($self, @data) {
    say "=== ニュース見出し一覧 ===";
    for my $headline (@data) {
        say "- $headline";
    }
}

1;
