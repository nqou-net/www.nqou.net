# 構造案: コード探偵ロックの事件簿【Pipeline】

## メタ情報

| 項目 | 内容 |
|------|------|
| タイトル | コード探偵ロックの事件簿【Pipeline】全員同房の容疑者たち〜神メソッドの取調室〜 |
| パターン | Pipeline（Pipes and Filters） |
| アンチパターン | God Method（巨大な処理メソッド）——バリデーション、変換、整形、出力がすべて一つのメソッドに詰め込まれている |
| slug | pipeline |
| 公開日時 | 2026-04-12T07:07:05+09:00 |
| ファイルパス | content/post/2026/04/12/070705.md |

---

## 語り部プロファイル（依頼人）

| 項目 | 内容 |
|------|------|
| 名前 | 佐々木 遥（ささき はるか） |
| 年齢 | 26歳 |
| 職種 | 社内データ集計ツールの開発者 |
| 一人称 | 私 |
| 性格 | 几帳面だが心配性。仕様変更のたびに既存の処理を壊してしまうことに怯えている |
| 背景 | 社内の売上集計ツールでCSVインポート処理を担当。インポートメソッドが一つの巨大メソッド（約100行）になっており、空行除去、ヘッダースキップ、カラム変換、バリデーション、合計計算がすべて同じメソッド内に混在している。仕様変更（新カラムの追加や計算ロジックの変更）のたびにメソッド全体を読み解く必要があり、修正のたびに別の処理が壊れる |

---

## コード設計

### Beforeコード（アンチパターン: God Method）

`lib/CsvImporter.pm`（Before）

```perl
package CsvImporter;
use Moo;

sub import_csv {
    my ($self, $lines) = @_;

    my @results;
    my $is_header = 1;
    for my $line (@$lines) {
        # 空行スキップ
        next if $line =~ /^\s*$/;

        # ヘッダースキップ
        if ($is_header) {
            $is_header = 0;
            next;
        }

        # カラム分割
        my @cols = split /,/, $line;

        # バリデーション: カラム数チェック
        next unless @cols == 3;

        # カラム変換: 名前のトリム、金額の数値化
        my $name   = $cols[0];
        $name =~ s/^\s+|\s+$//g;
        my $amount = $cols[1];
        $amount =~ s/[^0-9]//g;
        my $date   = $cols[2];
        $date =~ s/^\s+|\s+$//g;

        # バリデーション: 金額が正の数
        next unless $amount > 0;

        push @results, { name => $name, amount => int($amount), date => $date };
    }

    # 合計計算
    my $total = 0;
    $total += $_->{amount} for @results;

    return { records => \@results, total => $total };
}
```

**問題点**:
- 空行除去、ヘッダースキップ、カラム分割、バリデーション、変換、合計計算がすべて一つのメソッドに詰め込まれている
- 一つの処理を修正すると別の処理に影響しうる
- 個別の処理ステップをテストできない
- ステップの追加・削除・順序変更が困難

### Afterコード（Pipeline: Pipes and Filters）

`lib/CsvPipeline.pm`（After）

```perl
package CsvPipeline;
use Moo;

has filters => (is => 'ro', required => 1);

sub execute {
    my ($self, $data) = @_;
    my $result = $data;
    for my $filter (@{ $self->filters }) {
        $result = $filter->process($result);
    }
    return $result;
}
```

各フィルター:

```perl
package Filter::SkipBlankLines;
use Moo;
sub process {
    my ($self, $lines) = @_;
    return [ grep { $_ !~ /^\s*$/ } @$lines ];
}

package Filter::SkipHeader;
use Moo;
sub process {
    my ($self, $lines) = @_;
    return [ @{$lines}[1 .. $#$lines] ];
}

package Filter::ParseColumns;
use Moo;
sub process {
    my ($self, $lines) = @_;
    return [ map { [ split /,/, $_ ] } @$lines ];
}

package Filter::ValidateColumnCount;
use Moo;
has expected => (is => 'ro', default => 3);
sub process {
    my ($self, $rows) = @_;
    return [ grep { scalar @$_ == $self->expected } @$rows ];
}

package Filter::TransformFields;
use Moo;
sub process {
    my ($self, $rows) = @_;
    return [ map {
        my ($name, $amount, $date) = @$_;
        $name   =~ s/^\s+|\s+$//g;
        $amount =~ s/[^0-9]//g;
        $date   =~ s/^\s+|\s+$//g;
        { name => $name, amount => int($amount), date => $date };
    } @$rows ];
}

package Filter::ValidateAmount;
use Moo;
sub process {
    my ($self, $records) = @_;
    return [ grep { $_->{amount} > 0 } @$records ];
}

package Filter::CalculateTotal;
use Moo;
sub process {
    my ($self, $records) = @_;
    my $total = 0;
    $total += $_->{amount} for @$records;
    return { records => $records, total => $total };
}
```

**改善点**:
- 各処理ステップが独立したフィルタークラスとして分離
- フィルターの追加・削除・順序変更が容易
- 各フィルターを個別にテスト可能
- パイプライン全体の構成がコンストラクタで宣言的に表現される

---

## 5幕プロット

### I. 依頼（事務所への来客）

- 場面: 雑居ビルの一室「LCI」。ロックはエナジードリンクの缶を一列に並べて「パイプライン」と名付けている
- 佐々木が「CSVインポートの処理を直すたびに別の処理が壊れるんです」と訪問
- ロック「全員同房の容疑者か。一つの部屋に押し込められた処理たちが、互いに足を引っ張り合っている」
- 佐々木「容疑者って……CSVの処理のことですか？」
- ロック「一つのメソッドに全員閉じ込めれば、誰かが動くたびに誰かが傷つく。証拠を見せたまえ」

### II. 現場検証（コードの指紋）

- ロックが CsvImporter の import_csv メソッドを精読
- 「見たまえ。空行除去、ヘッダースキップ、カラム分割、バリデーション、変換、合計計算——六人の容疑者が全員同じ房に入れられている」
- 佐々木「容疑者って、処理ステップのことですか。でも全部一つの処理なんですが……」
- ロック「だからこそ問題なんだよ。合計計算のロジックを直すつもりで、うっかりバリデーションの行に触れたらどうなる？」
- 佐々木「……別の処理が壊れます」
- 「初歩的なにおいだよ、ワトソン君。**God Method**——一つのメソッドにすべてを詰め込む。全員同房にしておけば管理が楽だと思ったら、全員が共犯者になるだけだ」

### III. 推理披露（鮮やかなリファクタリング）

- ロック「解決策は、容疑者を個別の取調室に分離することだ。**Pipeline パターン**——処理をフィルターのチェーンとして構成する」
- CsvPipeline と各 Filter クラスの実装・解説
- 各フィルターが `process` メソッドだけを持つシンプルな構造を強調
- パイプラインの組み立てが宣言的であることを解説

### IV. 解決（平和なビルド）

- テストを実行。各フィルターの単体テストとパイプライン全体の統合テストが通過
- 佐々木「フィルターを一つ追加するだけで、他の処理に影響しない……！」
- ロック「報酬は、このパイプラインのフィルター数と同じ杯数のエスプレッソでいい」
- 佐々木（心の中）：「七つのフィルターで七杯……さすがに飲みすぎでは」

### V. 報告書（探偵の調査報告書）

- 事件概要表
- 推理のステップ
- ロックからワトソン君へのメッセージ

---

## フロントマター（予定）

```yaml
title: "コード探偵ロックの事件簿【Pipeline】全員同房の容疑者たち〜神メソッドの取調室〜"
date: "2026-04-12T07:07:05+09:00"
draft: false
categories: [tech]
tags:
  - design-pattern
  - perl
  - moo
  - pipeline
  - god-method
  - refactoring
  - code-detective
```
