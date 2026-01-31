#!/usr/bin/env perl
use v5.34;
use feature qw(signatures);
no warnings qw(experimental::signatures);
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";

# ASCIIアート・フォントレンダラー テストスイート

subtest '01: simple_art.pl - ハードコード版' => sub {

    # スクリプトが実行可能か確認
    my $output = `perl $FindBin::Bin/../lib/01_simple_art.pl 2>&1`;
    ok($? == 0, 'スクリプトが正常に実行される');
    like($output, qr/HELLO/, '出力にHELLOが含まれる');
    like($output, qr/完成/,    '完了メッセージが表示される');
};

subtest '02: memory_explosion.pl - メモリ問題' => sub {
    my $output = `perl $FindBin::Bin/../lib/02_memory_explosion.pl 2>&1`;
    ok($? == 0, 'スクリプトが正常に実行される');
    like($output, qr/問題発覚/, '問題の説明が表示される');
    like($output, qr/複製/,   'メモリ無駄使いの説明が表示される');
};

subtest '03: Flyweightパターン' => sub {
    require Glyph;
    require GlyphFactory;

    my $factory = GlyphFactory->new;

    # 同じ文字で同じオブジェクトが返ることを確認
    my $glyph1 = $factory->get_glyph('A');
    my $glyph2 = $factory->get_glyph('A');
    is($glyph1, $glyph2, '同じ文字で同じオブジェクトが返る');

    # 異なる文字で異なるオブジェクト
    my $glyph3 = $factory->get_glyph('B');
    isnt($glyph1, $glyph3, '異なる文字で異なるオブジェクト');

    # プールサイズの確認
    is($factory->pool_size, 2, 'プールサイズが正しい');

    # スクリプト実行
    my $output = `perl $FindBin::Bin/../lib/03_flyweight_solution.pl 2>&1`;
    ok($? == 0, 'Flyweight版スクリプトが正常に実行される');
    like($output, qr/改善効果/, '改善効果の説明が表示される');
};

subtest '04: scattered_config.pl - 設定問題' => sub {
    my $output = `perl $FindBin::Bin/../lib/04_scattered_config.pl 2>&1`;
    ok($? == 0, 'スクリプトが正常に実行される');
    like($output, qr/問題発覚/, '問題の説明が表示される');
    like($output, qr/DRY/,  'DRY原則への言及がある');
};

subtest '05: Singletonパターン' => sub {
    require FontManager;

    # インスタンスをリセット
    FontManager->reset_instance;

    # 同じインスタンスが返ることを確認
    my $manager1 = FontManager->instance;
    my $manager2 = FontManager->instance;
    is($manager1, $manager2, '同じインスタンスが返る');

    # 設定変更が反映されることを確認
    $manager1->font_path('/test/path');
    is($manager2->font_path, '/test/path', '設定変更が反映される');

    # リセット後に新しいインスタンス
    FontManager->reset_instance;
    my $manager3 = FontManager->instance;
    isnt($manager1, $manager3, 'リセット後は新しいインスタンス');

    # スクリプト実行
    my $output = `perl $FindBin::Bin/../lib/05_singleton_solution.pl 2>&1`;
    ok($? == 0, 'Singleton版スクリプトが正常に実行される');
    like($output, qr/改善効果/, '改善効果の説明が表示される');
};

subtest '06: eager_loading.pl - 遅延ロード問題' => sub {
    my $output = `perl $FindBin::Bin/../lib/06_eager_loading.pl 2>&1`;
    ok($? == 0, 'スクリプトが正常に実行される');
    like($output, qr/問題発覚/, '問題の説明が表示される');
    like($output, qr/36種類/, '全文字ロードの問題が説明される');
};

subtest '07: Proxyパターン' => sub {
    require RealFont;
    require FontProxy;

    # Proxyは最初ロード済みでない
    my $proxy = FontProxy->new(char => 'A');
    ok(!$proxy->is_loaded, '最初はロード済みでない');

    # アクセス時にロードされる
    my $art = $proxy->get_art;
    ok($proxy->is_loaded, 'アクセス後はロード済み');
    ok(length($art) > 0,  'アートデータが取得できる');

    # スクリプト実行
    my $output = `perl $FindBin::Bin/../lib/07_proxy_solution.pl 2>&1`;
    ok($? == 0, 'Proxy版スクリプトが正常に実行される');
    like($output, qr/改善効果/, '改善効果の説明が表示される');
};

subtest '08: 完成版' => sub {
    my $output = `perl $FindBin::Bin/../lib/08_complete.pl 2>&1`;
    ok($? == 0, '完成版スクリプトが正常に実行される');
    like($output, qr/Singleton/, 'Singletonパターンの解説');
    like($output, qr/Flyweight/, 'Flyweightパターンの解説');
    like($output, qr/Proxy/,     'Proxyパターンの解説');
    like($output, qr/完成/,        '完成メッセージ');
};

done_testing;
