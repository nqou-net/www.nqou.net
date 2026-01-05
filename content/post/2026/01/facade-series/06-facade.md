---
title: '第6回-シンプルに使えるようにしよう - レポート生成ツールを作ってみよう'
draft: true
tags:
  - perl
  - moo
  - facade-class
  - simplification
  - design-patterns
description: ReportGeneratorクラス（Facade）を作成し、複雑な処理を1メソッドで実行。コードがシンプルになる感動を体験しましょう。
image: /favicon.png
---

[@nqounet](https://x.com/nqounet)です。

「レポート生成ツールを作ってみよう」シリーズの第6回です。

前回は、3つのクラスを連携させる際の問題点を確認しました。まだ読んでいない方は、先にこちらをご覧ください。

(前回のリンク)

今回は、これらの問題を解決する `ReportGenerator` クラスを作成します。

## 今回のゴール

今回は、複雑な処理を1つのメソッドにまとめる仕組みを作ります。使う側は内部の詳細を知らなくても、シンプルにレポートを生成できるようになります。

新しい概念は「Facadeクラス」です。Facade（ファサード）とは「建物の正面」という意味で、複雑な内部構造を隠してシンプルな入口を提供するクラスのことです。

## ReportGeneratorクラスの作成

3つのクラスをまとめて使う `ReportGenerator` クラスを作成します。

**言語・バージョン**: Perl v5.36以降  
**外部依存**: Moo

```perl
package ReportGenerator {
    use Moo;
    use v5.36;

    has data_reader    => (is => 'lazy');
    has data_processor => (is => 'lazy');
    has report_writer  => (is => 'lazy');

    has file_path => (is => 'ro', required => 1);
    has title     => (is => 'ro', default => '成績レポート');

    sub _build_data_reader($self) {
        return DataReader->new(file_path => $self->file_path);
    }

    sub _build_data_processor($self) {
        return DataProcessor->new;
    }

    sub _build_report_writer($self) {
        return ReportWriter->new(title => $self->title);
    }

    sub generate($self) {
        my $raw_data  = $self->data_reader->read;
        my $processed = $self->data_processor->process($raw_data);
        my $report    = $self->report_writer->write($processed);
        return $report;
    }
}
```

このクラスの特徴は以下のとおりです。

- `file_path` と `title` だけ指定すれば、内部のクラスは自動的に作成される
- `generate` メソッドを呼ぶだけで、読み込み→加工→出力の全処理が実行される
- 使う側は `DataReader`、`DataProcessor`、`ReportWriter` の存在を知らなくてよい

## 完成コード

`ReportGenerator` クラスを追加した完全なスクリプトを示します。

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
        my @sorted = sort { $b->{score} <=> $a->{score} } @$data;

        my $total = sum(map { $_->{score} } @sorted);
        my $average = $total / scalar(@sorted);

        return {
            records => \@sorted,
            average => $average,
            count   => scalar(@sorted),
        };
    }
}

# ReportWriterクラス
package ReportWriter {
    use Moo;
    use v5.36;

    has title => (is => 'ro', default => '成績レポート');

    sub write($self, $processed_data) {
        my @lines;

        push @lines, "=== " . $self->title . " ===";
        push @lines, '';

        for my $row (@{$processed_data->{records}}) {
            push @lines, "$row->{name}: $row->{score}点";
        }

        push @lines, '';
        push @lines, sprintf("平均点: %.1f点", $processed_data->{average});
        push @lines, "受験者数: $processed_data->{count}名";
        push @lines, '';
        push @lines, '=== レポート終了 ===';

        return join("\n", @lines);
    }
}

# ReportGeneratorクラス（Facade）
package ReportGenerator {
    use Moo;
    use v5.36;

    has data_reader    => (is => 'lazy');
    has data_processor => (is => 'lazy');
    has report_writer  => (is => 'lazy');

    has file_path => (is => 'ro', required => 1);
    has title     => (is => 'ro', default => '成績レポート');

    sub _build_data_reader($self) {
        return DataReader->new(file_path => $self->file_path);
    }

    sub _build_data_processor($self) {
        return DataProcessor->new;
    }

    sub _build_report_writer($self) {
        return ReportWriter->new(title => $self->title);
    }

    sub generate($self) {
        my $raw_data  = $self->data_reader->read;
        my $processed = $self->data_processor->process($raw_data);
        my $report    = $self->report_writer->write($processed);
        return $report;
    }
}

# メイン処理
package main;

my $generator = ReportGenerator->new(
    file_path => 'data.csv',
    title     => '成績レポート',
);
my $report = $generator->generate;

say $report;
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

## Before / After を比較する

### Before（第5回のメイン処理）

```perl
my $reader = DataReader->new(file_path => 'data.csv');
my $raw_data = $reader->read;

my $processor = DataProcessor->new;
my $processed = $processor->process($raw_data);

my $writer = ReportWriter->new(title => '成績レポート');
my $report = $writer->write($processed);

say $report;
```

### After（今回のメイン処理）

```perl
my $generator = ReportGenerator->new(
    file_path => 'data.csv',
    title     => '成績レポート',
);
my $report = $generator->generate;

say $report;
```

コードが大幅にシンプルになりました。前回挙げた問題点がすべて解決されています。

- **呼び出し順序を覚える必要がない**: `generate` を呼ぶだけでよい
- **同じコードを繰り返し書く必要がない**: `ReportGenerator` を再利用できる
- **内部構造を知らなくても使える**: `file_path` と `title` だけ指定すればよい

## まとめ

- 複雑な処理を1メソッドにまとめる `ReportGenerator` クラスを作成した
- 使う側は内部の3つのクラスを意識せずにレポートを生成できるようになった
- コードがシンプルになり、再利用性も向上した

## 次回予告

次回は、今回作成した `ReportGenerator` クラスの設計手法に名前を付けます。実は、これはソフトウェア設計で広く知られているデザインパターンのひとつなのです。お楽しみに。

(次回のリンク)
