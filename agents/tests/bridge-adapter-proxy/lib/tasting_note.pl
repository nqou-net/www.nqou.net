#!/usr/bin/env perl
# 第8回: 3つのパターンを統合する
# tasting_note.pl - Adapter × Bridge × Proxy の統合版

use v5.36;
use warnings;
use FindBin;
use lib "$FindBin::Bin";

# Adapterパターン: データソース統一
use CsvAdapter;
use JsonAdapter;

# Bridgeパターン: 出力形式×スタイル
use TextNote;
use HtmlNote;
use MarkdownNote;
use SimpleFormatter;
use DetailedFormatter;
use ProFormatter;

# Proxyパターン: 遅延・キャッシュ・制御
use ImageProxy;
use RatingProxy;
use AccessProxy;

# ─────────────────────────────────────────────────────
# サンプルデータ
# ─────────────────────────────────────────────────────

my $csv_data = <<'CSV';
id,name,region,age,abv,nose,palate,finish,rating
1,山崎12年,日本,12,43,蜂蜜とバニラ,フルーティで滑らか,長くスパイシー,92
2,白州12年,日本,12,43,森林と青りんご,爽やかでスモーキー,すっきりとした余韻,88
CSV

my $json_data = <<'JSON';
{
    "whiskies": [
        {
            "whisky_id": "3",
            "whisky_name": "ラフロイグ10年",
            "origin": { "country": "スコットランド", "region": "アイラ" },
            "specs": { "age_years": 10, "alcohol_percentage": 40 },
            "tasting_notes": {
                "aroma": "強烈なピートとヨード",
                "taste": "スモーキーで塩辛い",
                "after": "力強くドライ"
            },
            "score": 90
        }
    ]
}
JSON

# ─────────────────────────────────────────────────────
# Step 1: Adapter でデータソースを統一
# ─────────────────────────────────────────────────────

say "=" x 60;
say "Step 1: Adapter でデータソースを統一";
say "=" x 60;

my $csv_adapter  = CsvAdapter->new(csv_data => $csv_data);
my $json_adapter = JsonAdapter->new(json_data => $json_data);

# 同じインターフェースで異なるソースからデータ取得
my @all_whiskies;
push @all_whiskies, $csv_adapter->get_all;
push @all_whiskies, $json_adapter->get_all;

say "CSVから " . scalar($csv_adapter->get_all) . " 件取得";
say "JSONから " . scalar($json_adapter->get_all) . " 件取得";
say "合計: " . scalar(@all_whiskies) . " 件のウイスキー\n";

# ─────────────────────────────────────────────────────
# Step 2: Bridge で出力形式×スタイルを組み合わせ
# ─────────────────────────────────────────────────────

say "=" x 60;
say "Step 2: Bridge で出力形式×スタイルを組み合わせ";
say "=" x 60;

# 1つのウイスキーをサンプルに
my $sample = $all_whiskies[0];

# 出力形式×スタイルの組み合わせを作成
my %notes = (
    'Text × Simple'       => TextNote->new(formatter => SimpleFormatter->new),
    'Text × Detailed'     => TextNote->new(formatter => DetailedFormatter->new),
    'HTML × Pro'          => HtmlNote->new(formatter => ProFormatter->new),
    'Markdown × Detailed' => MarkdownNote->new(formatter => DetailedFormatter->new),
);

for my $combo (sort keys %notes) {
    say "\n--- $combo ---";
    say $notes{$combo}->render($sample);
}

# ─────────────────────────────────────────────────────
# Step 3: Proxy で遅延・キャッシュ・制御
# ─────────────────────────────────────────────────────

say "\n" . "=" x 60;
say "Step 3: Proxy で遅延・キャッシュ・制御";
say "=" x 60;

# 3.1 ImageProxy: 遅延ロード
say "\n--- ImageProxy: 遅延ロード ---";
my $img_proxy = ImageProxy->new(id => 1, filename => 'yamazaki12.jpg');
say "画像Proxy作成（まだロードされていない）";
$img_proxy->show_thumbnail;                    # 本物はロードしない
say "実際のデータが必要な時: " . $img_proxy->get_data;    # この時点でロード

# 3.2 RatingProxy: キャッシュ
say "\n--- RatingProxy: キャッシュ ---";
my $rating_proxy = RatingProxy->new(whisky_id => 1, cache_ttl => 5);
my $rating1      = $rating_proxy->get_rating;                          # 外部から取得
say "スコア: $rating1->{score}点 (レビュー数: $rating1->{reviews})";

my $rating2 = $rating_proxy->get_rating;                               # キャッシュから

# 3.3 AccessProxy: アクセス制御
say "\n--- AccessProxy: アクセス制御 ---";
my $private_note = {id => 1, content => '秘密のテイスティングノート', whisky_id => 1};
my $access_proxy = AccessProxy->new(
    private_note     => $private_note,
    owner_id         => 'user001',
    permission_level => 'friends',
);

$access_proxy->get_note('user001');                                    # オーナー: OK
$access_proxy->get_note('user002', 1);                                 # 友達: OK
$access_proxy->get_note('user003');                                    # 他人: NG

# ─────────────────────────────────────────────────────
# 完成: 3パターン統合利用
# ─────────────────────────────────────────────────────

say "\n" . "=" x 60;
say "完成: 3パターン統合の流れ";
say "=" x 60;

say <<'SUMMARY';

┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│   Adapter   │ → │   Bridge    │ → │    Proxy    │
│(データ取得) │    │(出力生成)    │    │(制御・最適化)│
└─────────────┘    └─────────────┘    └─────────────┘
      ↓                 ↓                  ↓
 CSV/JSON/API     Text/HTML/MD ×      遅延ロード
 を統一IF化       Simple/Detail/Pro   キャッシュ/認証

SUMMARY

say "=== 3パターンの役割まとめ ===";
say "Adapter : 異なるデータソースを統一インターフェースで扱う";
say "Bridge  : 出力形式×スタイルの組み合わせ爆発を回避";
say "Proxy   : 本物へのアクセスを制御・最適化";
