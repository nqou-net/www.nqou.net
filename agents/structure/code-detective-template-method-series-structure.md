---
date: 2026-03-04T22:28:00+09:00
description: コード探偵ロックの事件簿 第2話「瓜二つの容疑者〜コピペ双子の分離手術〜」の構造案
title: '連載構造案 - コード探偵ロックの事件簿【Template Method】'
---

# 連載構造案：コード探偵ロックの事件簿【Template Method】統合版

## 前提情報

- **シリーズ名**: コード探偵ロックの事件簿
- **テーマ**: レガシーコード・アンチパターンの解決 × GoFデザインパターン
- **技術スタック**: Perl (Mooを利用)
- **今回のアンチパターン**: コピペコード（Duplicated Code）
- **今回の解決策**: Template Method パターン
- **形式**: 統合版（1つの完結した記事）

## 登場人物

- **ロック**: 主人公。ホームズ気取りのコード探偵。
- **アオイ（ワトソン君A / 語り手）**: 双子の姉。ユーザーデータCSVエクスポートを担当するバックエンドエンジニア。しっかり者だが、自分では解決策を思いつけない。
- **ミドリ（ワトソン君B）**: 双子の妹。注文データCSVエクスポートを担当。姉とシンクロしがちで、同じことを同時に言う癖がある。

## ストーリー構成

### I. 依頼（二重の来客）
- **状況**: アオイとミドリが**同時に**LCIのドアを叩く。2人とも「コードのバグ修正が終わらない」という同じ悩みを抱えている。
- **描写**: ロックが2人を見て「ほう、双子か。珍しい依頼人だ」と興味津々。当然のように2人とも「ワトソン君」と呼び始める。
- **コメディ**: 「私はアオイです」「私はミドリです」→ ロック「問題ない。2人ともワトソン君だ」
- **主訴**: アオイ「ユーザーCSVの出力でバグを直したら、別の場所にも同じ修正が必要だったんです」ミドリ「私も！注文CSVの方で同じことが……」

### II. 現場検証（瓜二つの指紋）
- **Beforeコード提示**: 2つのエクスポートモジュール（`UserCsvExporter` と `OrderCsvExporter`）を並べて表示。
- ロックが2つのコードをモニターに並べた瞬間、不敵な笑みを浮かべる。
- 「ほう……依頼人だけでなく、コードまで双子とは。これは興味深い」
- 双子の反応: 「え？ 全然違うコードですよ！」「そうそう、扱うデータが違うし……」
- ロック: 「いいや。骨格は同じだ。彼らは変装しているだけさ。ほら、ここを見たまえ——接続、取得、整形、出力。手順は瓜二つだ」
- **ワトソンの困惑**: アオイ「言われてみれば……でも、それが何か問題なんですか？ 動いてはいるんですが」
- ロック: 「動いている？ ああ、今はね。だが君たちはさっき言ったはずだ——バグを直すたびに、もう片方にも同じ修正が必要だと」

### III. 推理披露（家族の再統合）
- ロックがキーボードを叩き始める。
- **Step 1**: 共通の骨格を抽出して基底クラス（`CsvExporter::Base`）に定義する。`export` メソッドの中で手順（接続→取得→整形→出力）を固定する。
- **Step 2**: 各ステップのうち「差分」だけをサブクラスでオーバーライドする。
- **双子の異なるリアクション**:
  - ミドリ（先走り失敗型）: 「あ、全部のメソッドをサブクラスに移せばいいんですね！」→ ロック「いいや、共通部分は親に残すんだ。差分だけを子に委ねる。それがTemplate Methodだよ」
  - アオイ（遅延理解型）: 「……待って。つまり、バグ修正は親クラスの1箇所だけで済むということ……？」→ ロック「ご名答」
- **コメディ**: 双子が同時に「なるほど！」と声を揃えてしまい、気まずくなる場面

### IV. 解決（2つのテストが通る日）
- テストがすべて通り、コードが統合される。
- アオイ「これで、片方を直してもう片方を忘れる……なんてことはなくなるんですね」
- ミドリ「私たちは双子だけど、コードまで双子にする必要はなかったのね」
- ロックの締め言葉と報酬要求（同じブレンド・焙煎度違いのコーヒー豆2袋）

### V. 探偵の調査報告書
- **表**: コピペコード（容疑） → Template Method パターン（真実） → DRY原則の達成・保守性向上（証拠）
- **推理のステップ**: 共通骨格の抽出 → 基底クラスの定義 → 差分のオーバーライド
- **ロックからのメッセージ**: 「瓜二つに見えるものほど、その違いにこそ価値がある」

## 実装計画

### Before（コピペ双子）

```perl
package UserCsvExporter;
use Moo;

sub export {
    my ($self) = @_;
    # DB接続
    my $dbh = $self->_connect_db();
    # データ取得
    my $rows = $dbh->selectall_arrayref("SELECT name, email FROM users", { Slice => {} });
    # CSV整形
    my @lines;
    push @lines, "name,email";
    for my $row (@$rows) {
        push @lines, sprintf("%s,%s", $row->{name}, $row->{email});
    }
    # ファイル出力
    open my $fh, '>', 'users.csv' or die $!;
    print $fh join("\n", @lines);
    close $fh;
    return 'users.csv';
}
1;

# OrderCsvExporter はほぼ同じ構造で、
# テーブル名・カラム名・ファイル名だけが違う
```

### After（Template Method 適用）

```perl
package CsvExporter::Base;
use Moo;

# Template Method: 骨格を定義し、差分だけをサブクラスに委ねる
sub export {
    my ($self) = @_;
    my $dbh  = $self->_connect_db();
    my $rows = $self->fetch_data($dbh);
    my @lines = ($self->header_line(), map { $self->format_row($_) } @$rows);
    $self->write_file(\@lines);
}

# サブクラスで必ずオーバーライドすること
sub fetch_data    { die "must override" }
sub header_line   { die "must override" }
sub format_row    { die "must override" }
sub output_filename { die "must override" }
1;

package CsvExporter::User;
use Moo;
extends 'CsvExporter::Base';
sub fetch_data { ... }
sub header_line { "name,email" }
sub format_row { sprintf("%s,%s", $_[1]->{name}, $_[1]->{email}) }
sub output_filename { "users.csv" }
1;
```

## メタデータ・構成情報
- **slug**: `code-detective-template-method-duplicated-code`
- **カテゴリ**: [Design Patterns, Perl]
- **タグ**: [perl, moo, template-method, refactoring, code-detective]
