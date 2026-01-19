package NewsScraper;
# 言語: perl
# バージョン: 5.36以上
# 依存: Moo, WebScraper

use v5.36;
use Moo;
use experimental qw(signatures);

extends 'WebScraper';

sub extract_data ($self, $dom) {
    my @headlines;
    for my $headline ($dom->find('h2.headline')->each) {
        push @headlines, $headline->text;
    }
    return @headlines;
}

# 検証処理を追加
sub validate_data ($self, @data) {
    if (@data == 0) {
        die "エラー: ニュースの見出しが1つも見つかりませんでした。\n"
          . "サイトの構造が変わった可能性があります。";
    }
    say "検証OK: " . scalar(@data) . " 件のニュースを取得しました";
    return 1;
}

1;
