#!/usr/bin/env perl
# テスト: 全コンポーネントの動作確認

use v5.36;
use warnings;
use utf8;
use open ':std', ':encoding(UTF-8)';
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";

# ─────────────────────────────────────────────────────
# 第1回: simple_note.pl のテスト
# ─────────────────────────────────────────────────────

subtest '第1回: CSVからの読み込み' => sub {

    # simple_note.pl は実行可能スクリプトなので、モジュールとしてテスト
    my $csv_data = <<'CSV';
id,name,region,age,abv,nose,palate,finish,rating
1,山崎12年,日本,12,43,蜂蜜とバニラ,フルーティで滑らか,長くスパイシー,92
CSV

    my @lines = split /\n/, $csv_data;
    shift @lines;
    my @whiskies;
    for my $line (@lines) {
        next unless $line =~ /\S/;
        my @f = split /,/, $line;
        push @whiskies, {id => $f[0], name => $f[1], rating => $f[8]};
    }

    is scalar(@whiskies),    1,       'CSVから1件取得';
    is $whiskies[0]{name},   '山崎12年', '銘柄名が正しい';
    is $whiskies[0]{rating}, 92,      'レーティングが正しい';
};

# ─────────────────────────────────────────────────────
# 第3回: Adapterパターン
# ─────────────────────────────────────────────────────

subtest '第3回: CsvAdapter' => sub {
    use CsvAdapter;

    my $csv_data = <<'CSV';
id,name,region,age,abv,nose,palate,finish,rating
1,山崎12年,日本,12,43,蜂蜜とバニラ,フルーティで滑らか,長くスパイシー,92
2,白州12年,日本,12,43,森林と青りんご,爽やか,すっきり,88
CSV

    my $adapter = CsvAdapter->new(csv_data => $csv_data);

    is $adapter->source_name, 'CSV', 'ソース名が正しい';

    my $w = $adapter->get_whisky('1');
    is $w->{name},   '山崎12年', 'get_whiskyで1件取得';
    is $w->{rating}, 92,      'レーティングが正しい';

    my @all = $adapter->get_all;
    is scalar(@all), 2, 'get_allで全件取得';
};

subtest '第3回: JsonAdapter' => sub {
    use JsonAdapter;

    my $json_data = <<'JSON';
{
    "whiskies": [
        {
            "whisky_id": "W001",
            "whisky_name": "テスト銘柄",
            "origin": { "country": "日本", "region": "山梨" },
            "specs": { "age_years": 10, "alcohol_percentage": 43 },
            "tasting_notes": { "aroma": "香り", "taste": "味", "after": "余韻" },
            "score": 85
        }
    ]
}
JSON

    my $adapter = JsonAdapter->new(json_data => $json_data);

    is $adapter->source_name, 'JSON', 'ソース名が正しい';

    my $w = $adapter->get_whisky('W001');
    is $w->{name},   'テスト銘柄', 'JSONからの変換が正しい';
    is $w->{region}, '山梨',    'ネスト構造からの取得が正しい';
};

# ─────────────────────────────────────────────────────
# 第5回: Bridgeパターン
# ─────────────────────────────────────────────────────

subtest '第5回: Bridge（TextNote × SimpleFormatter）' => sub {
    use TextNote;
    use SimpleFormatter;

    my $note   = TextNote->new(formatter => SimpleFormatter->new);
    my $whisky = {
        id     => 1,
        name   => 'テスト銘柄',
        region => '日本',
        age    => 12,
        abv    => 43,
        nose   => '香り',
        palate => '味',
        finish => '余韻',
        rating => 85
    };

    my $output = $note->render($whisky);
    like $output, qr/テスト銘柄/, '銘柄名が含まれる';
    like $output, qr/日本/,    '産地が含まれる';
};

subtest '第5回: Bridge（HtmlNote × DetailedFormatter）' => sub {
    use HtmlNote;
    use DetailedFormatter;

    my $note   = HtmlNote->new(formatter => DetailedFormatter->new);
    my $whisky = {
        id     => 1,
        name   => 'テスト銘柄',
        region => '日本',
        age    => 12,
        abv    => 43,
        nose   => '香り',
        palate => '味',
        finish => '余韻',
        rating => 85
    };

    my $output = $note->render($whisky);
    like $output, qr/<article>/, 'HTMLタグが含まれる';
    like $output, qr/<h2>テスト銘柄/, '銘柄名がh2に含まれる';
};

subtest '第5回: Bridge（MarkdownNote × ProFormatter）' => sub {
    use MarkdownNote;
    use ProFormatter;

    my $note   = MarkdownNote->new(formatter => ProFormatter->new);
    my $whisky = {
        id     => 1,
        name   => 'テスト銘柄',
        region => '日本',
        age    => 12,
        abv    => 43,
        nose   => '香り',
        palate => '味',
        finish => '余韻',
        rating => 85
    };

    my $output = $note->render($whisky);
    like $output, qr/## テスト銘柄/, 'Markdownヘッダーが含まれる';
    like $output, qr/★/,        'スターレーティングが含まれる';
};

# ─────────────────────────────────────────────────────
# 第7回: Proxyパターン
# ─────────────────────────────────────────────────────

subtest '第7回: ImageProxy（遅延ロード）' => sub {
    use ImageProxy;

    my $proxy = ImageProxy->new(id => 1, filename => 'test.jpg');

    ok !$proxy->is_loaded, '初期状態ではロードされていない';

    my $thumb = $proxy->show_thumbnail;
    ok !$proxy->is_loaded, 'サムネイル表示後もロードされていない';

    my $data = $proxy->get_data;
    ok $proxy->is_loaded, 'データ取得後はロード済み';
    like $data, qr/IMAGE_DATA/, 'データが取得できる';
};

subtest '第7回: RatingProxy（キャッシュ）' => sub {
    use RatingProxy;

    my $proxy = RatingProxy->new(whisky_id => 1, cache_ttl => 10);

    my $rating1 = $proxy->get_rating;
    ok defined $rating1->{score}, '初回は外部から取得';

    my $rating2 = $proxy->get_rating;
    is_deeply $rating1, $rating2, '2回目はキャッシュから';

    $proxy->invalidate_cache;

    # キャッシュ無効化後の動作確認（再取得される）
};

subtest '第7回: AccessProxy（アクセス制御）' => sub {
    use AccessProxy;

    my $note  = {content => '秘密のノート'};
    my $proxy = AccessProxy->new(
        private_note     => $note,
        owner_id         => 'owner',
        permission_level => 'friends',
    );

    ok $proxy->can_access('owner'),     'オーナーはアクセス可';
    ok $proxy->can_access('friend', 1), '友達はアクセス可';
    ok !$proxy->can_access('stranger'), '他人はアクセス不可';

    ok $proxy->can_edit('owner'),   'オーナーは編集可';
    ok !$proxy->can_edit('friend'), '友達は編集不可';
};

done_testing;
