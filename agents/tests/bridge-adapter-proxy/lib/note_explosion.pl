#!/usr/bin/env perl
# 第4回: 出力形式を増やしたい
# note_explosion.pl - 組み合わせ爆発を体験する問題版

use v5.36;
use warnings;
use FindBin;
use lib "$FindBin::Bin";

use CsvAdapter;

# CSVデータ
my $csv_data = <<'CSV';
id,name,region,age,abv,nose,palate,finish,rating
1,山崎12年,日本,12,43,蜂蜜とバニラ,フルーティで滑らか,長くスパイシー,92
CSV

my $adapter  = CsvAdapter->new(csv_data => $csv_data);
my @whiskies = $adapter->get_all;

say "=== 組み合わせ爆発デモ ===\n";
say "出力形式: Text, HTML, Markdown";
say "スタイル: Simple, Detailed, Pro";
say "組み合わせ: 3×3 = 9パターン\n";

# if/elseで9パターンを実装しようとすると...
sub render_note($whisky, $format, $style) {
    if ($format eq 'text') {
        if ($style eq 'simple') {
            return "【$whisky->{name}】$whisky->{rating}点";
        }
        elsif ($style eq 'detailed') {
            return "【$whisky->{name}】\n  産地: $whisky->{region}\n  評価: $whisky->{rating}/100";
        }
        elsif ($style eq 'pro') {
            return
                "=== $whisky->{name} ===\n産地: $whisky->{region} / 熟成: $whisky->{age}年\n香り: $whisky->{nose}\n味わい: $whisky->{palate}\n余韻: $whisky->{finish}\n評価: $whisky->{rating}/100";
        }
    }
    elsif ($format eq 'html') {
        if ($style eq 'simple') {
            return "<p><strong>$whisky->{name}</strong> $whisky->{rating}点</p>";
        }
        elsif ($style eq 'detailed') {
            return "<div><h3>$whisky->{name}</h3><p>産地: $whisky->{region}</p><p>評価: $whisky->{rating}/100</p></div>";
        }
        elsif ($style eq 'pro') {
            return
                "<article><h2>$whisky->{name}</h2><dl><dt>産地</dt><dd>$whisky->{region}</dd><dt>熟成</dt><dd>$whisky->{age}年</dd><dt>香り</dt><dd>$whisky->{nose}</dd><dt>味わい</dt><dd>$whisky->{palate}</dd><dt>余韻</dt><dd>$whisky->{finish}</dd></dl><p class='rating'>$whisky->{rating}/100</p></article>";
        }
    }
    elsif ($format eq 'markdown') {
        if ($style eq 'simple') {
            return "**$whisky->{name}** $whisky->{rating}点";
        }
        elsif ($style eq 'detailed') {
            return "## $whisky->{name}\n- 産地: $whisky->{region}\n- 評価: $whisky->{rating}/100";
        }
        elsif ($style eq 'pro') {
            return
                "## $whisky->{name}\n\n| 項目 | 内容 |\n|------|------|\n| 産地 | $whisky->{region} |\n| 熟成 | $whisky->{age}年 |\n| 香り | $whisky->{nose} |\n| 味わい | $whisky->{palate} |\n| 余韻 | $whisky->{finish} |\n\n**評価: $whisky->{rating}/100**";
        }
    }

    die "未対応の組み合わせ: $format × $style";
}

# 9パターン全部デモ
my $w = $whiskies[0];
for my $format (qw(text html markdown)) {
    for my $style (qw(simple detailed pro)) {
        say "--- $format × $style ---";
        say render_note($w, $format, $style);
        say "";
    }
}

say "=== 問題点 ===";
say "- 9パターンすべてをif/elseで分岐";
say "- 新しい出力形式を追加すると3つのスタイル分の実装が必要";
say "- 新しいスタイルを追加すると3つの形式分の実装が必要";
say "- フォーマット×スタイル×N → 組み合わせ爆発";
say "- コードの重複が多い";
