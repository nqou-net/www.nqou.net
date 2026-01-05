---
title: '第3回-データを加工しよう - レポート生成ツールを作ってみよう'
draft: true
tags:
  - perl
  - moo
  - data-processing
  - aggregation
  - oop-class
description: 読み込んだデータを集計・整形するDataProcessorクラスをMooで作成。配列操作とデータ変換の実装方法を解説します。
image: /favicon.png
---

[@nqounet](https://x.com/nqounet)です。

「レポート生成ツールを作ってみよう」シリーズの第3回です。

前回は、CSVファイルからデータを読み込む `DataReader` クラスを作成しました。まだ読んでいない方は、先にこちらをご覧ください。

(前回のリンク)

今回は、読み込んだデータを加工する `DataProcessor` クラスを作成します。

## 今回のゴール

今回は、データを集計・整形する仕組みを作ります。平均点の計算や、点数による並べ替えなど、生データに付加価値を与える処理を追加します。

新しい概念は「データ変換」です。読み込んだデータをそのまま使うのではなく、加工してから次の処理に渡す仕組みを作ります。

## DataProcessorクラスの作成

データを加工する `DataProcessor` クラスを作成します。

**言語・バージョン**: Perl v5.36以降  
**外部依存**: Moo

```perl
package DataProcessor {
    use Moo;
    use v5.36;
    use List::Util qw(sum);

    sub process($self, $data) {
        # 点数で降順にソート
        my @sorted = sort { $b->{score} <=> $a->{score} } @$data;

        # 平均点を計算
        my $total = sum(map { $_->{score} } @sorted);
        my $average = $total / scalar(@sorted);

        return {
            records => \@sorted,
            average => $average,
            count   => scalar(@sorted),
        };
    }
}
```

このクラスの特徴は以下のとおりです。

- `process` メソッドでデータを受け取り、加工結果を返す
- 点数の高い順に並べ替える
- 平均点と件数を計算して、まとめて返す
- `List::Util` の `sum` を使って合計を計算する

## 完成コード

前回のスクリプトに `DataProcessor` クラスを追加します。

**言語・バージョン**: Perl v5.36以降  
**外部依存**: Moo, List::Util（コアモジュール）

```perl
#!/usr/bin/env perl
use v5.36;
use Moo;
use List::Util qw(sum);

# DataReaderクラス
package DataReader {
    use Moo;
    use v5.36;

    has file_path => (is => 'ro', required => 1);

    sub read($self) {
        open my $fh, '<', $self->file_path
            or die "Cannot open file: $!";

        my $header_line = <$fh>;
        chomp $header_line;
        my @headers = split /,/, $header_line;

        my @data;
        while (my $line = <$fh>) {
            chomp $line;
            my @values = split /,/, $line;
            my %row;
            for my $i (0 .. $#headers) {
                $row{$headers[$i]} = $values[$i];
            }
            push @data, \%row;
        }

        close $fh;
        return \@data;
    }
}

# DataProcessorクラス
package DataProcessor {
    use Moo;
    use v5.36;
    use List::Util qw(sum);

    sub process($self, $data) {
        # 点数で降順にソート
        my @sorted = sort { $b->{score} <=> $a->{score} } @$data;

        # 平均点を計算
        my $total = sum(map { $_->{score} } @sorted);
        my $average = $total / scalar(@sorted);

        return {
            records => \@sorted,
            average => $average,
            count   => scalar(@sorted),
        };
    }
}

# メイン処理
package main;

my $reader = DataReader->new(file_path => 'data.csv');
my $raw_data = $reader->read;

my $processor = DataProcessor->new;
my $processed = $processor->process($raw_data);

# レポートを表示
say '=== 成績レポート ===';
say '';

for my $row (@{$processed->{records}}) {
    say "$row->{name}: $row->{score}点";
}

say '';
say sprintf("平均点: %.1f点", $processed->{average});
say "受験者数: $processed->{count}名";
say '';
say '=== レポート終了 ===';
```

**実行方法**:
```bash
perl report.pl
```

**出力例**:
```
=== 成績レポート ===

鈴木花子: 92点
田中太郎: 85点
佐藤一郎: 78点

平均点: 85.0点
受験者数: 3名

=== レポート終了 ===
```

前回と比べて、以下の点が改善されました。

- 点数の高い順に並べ替えられている
- 平均点と受験者数が表示されている

## まとめ

- 読み込んだデータを加工する `DataProcessor` クラスを作成した
- Perlの `sort` でデータを並べ替えた
- `List::Util` の `sum` と `map` を組み合わせて平均点を計算した

## 次回予告

次回は、レポートをテキスト形式で出力する `ReportWriter` クラスを作成します。画面への出力を専門に行うクラスを作ることで、出力形式の変更が容易になります。お楽しみに。

(次回のリンク)
