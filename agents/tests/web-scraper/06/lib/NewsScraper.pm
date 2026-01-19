package NewsScraper;
# 言語: perl
# バージョン: 5.36以上
# 依存: Moo, WebScraper

use Moo;
use experimental qw(signatures);

extends 'WebScraper';

# extract_dataだけ実装すればOK！
sub extract_data ($self, $dom) {
    my @headlines;
    for my $headline ($dom->find('h2.headline')->each) {
        push @headlines, $headline->text;
    }
    return @headlines;
}

# save_dataはオーバーライドせずデフォルトを使用

1;
