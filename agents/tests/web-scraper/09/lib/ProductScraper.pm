package ProductScraper;
# 言語: perl
# バージョン: 5.36以上
# 依存: Moo, WebScraper

use v5.36;
use Moo;
use experimental qw(signatures);

extends 'WebScraper';

sub extract_data ($self, $dom) {
    my @products;
    
    for my $product ($dom->find('div.product')->each) {
        my $name = $product->at('h2.name')->text;
        my $price = $product->at('span.price')->text;
        my $stock = $product->at('span.stock')->text;
        
        push @products, {
            name  => $name,
            price => $price,
            stock => $stock,
        };
    }
    
    return @products;
}

# 在庫ありの商品だけ表示するカスタム保存処理
sub save_data ($self, @data) {
    say "=== 在庫あり商品一覧 ===";
    my $in_stock = 0;
    for my $product (@data) {
        if ($product->{stock} eq '在庫あり') {
            say "  $product->{name} ... $product->{price}";
            $in_stock++;
        }
    }
    say "（$in_stock 件の商品が在庫あり）";
}

# 商品データの検証
sub validate_data ($self, @data) {
    if (@data == 0) {
        die "エラー: 商品が見つかりませんでした";
    }
    
    for my $product (@data) {
        # 価格が通貨記号（¥, $等）で始まることを確認
        unless ($product->{price} =~ /^\p{Sc}?[\d,]+/) {
            warn "警告: 価格形式が不正です: $product->{name}";
        }
    }
    
    return 1;
}

1;
