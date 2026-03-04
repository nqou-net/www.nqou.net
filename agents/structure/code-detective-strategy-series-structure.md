---
date: 2026-03-04T09:00:00+09:00
description: コード探偵ロックの事件簿 第1話「巨大すぎる神（God Class）の暴走とStrategyパターンによる解決」の構造案
title: '連載構造案 - コード探偵ロックの事件簿【Strategy】'
---

# 連載構造案：コード探偵ロックの事件簿【Strategy】統合版

## 前提情報

- **シリーズ名**: コード探偵ロックの事件簿
- **テーマ**: レガシーコード・アンチパターンの解決 × GoFデザインパターン
- **技術スタック**: Perl (Mooを利用)
- **今回のアンチパターン**: God Class（神オブジェクト）、巨大な if - elsif の壁
- **今回の解決策**: Strategy パターン
- **形式**: 統合版（1つの完結した記事）

## 登場人物

- **ロック**: 主人公。ホームズ気取りのコード探偵。Perlの泥臭いレガシーコード愛好家。
- **ワトソン君（依頼人）**: 今回の語り手。とあるWebサービスの保守を前任者から押し付けられた**女性技術者**。5000行のスクリプトに心を壊されかけている。

## ストーリー構成（探偵メタファー）

### I. 依頼（事務所への来客）
- **状況**: 依頼人（ワトソン君）が「レガシー・コード・インベスティゲーション（LCI）」を訪問する。
- **描写**: 排熱とエナジードリンクのにおいが充満する荒れた事務所。ロックのオーバーな出迎え。
- **主訴**: 「何でもかんでも1つの関数で処理する5000行のスクリプトがある。新しいデータ形式を追加したいが、どこを触ってもバグる」

### II. 現場検証（コードの指紋）
- **Beforeコード提示**: `sub process_everything` という名前の巨大なメソッド。引数のタイプ（`$type eq 'csv'`, `$type eq 'json'` etc.）によって、DB接続からバリデーション、出力フォーマットの生成、メール送信まで、すべての処理が巨大な `if - elsif` で分岐している。
- **ロックの推理**: 「典型的な『神オブジェクト（God Class）』のにおいだね。彼は全知全能になろうとして、自重で押し潰されたのさ」

### III. 推理披露（鮮やかなリファクタリング）
- **解説と処置**: ロックがキーボードを叩き始める。
- **解決へのアプローチ（Strategyパターンの適用）**:
  1. 「神を分割するんだ」。処理の共通インターフェース（Role）を定義。
  2. `CsvProcessor`, `JsonProcessor` などの振る舞い（Strategy）を別々のクラスとして独立させる。
  3. メインルーチン（Context）からは `if` 文を消し去り、適切なStrategyオブジェクトに処理を委譲（Delegate）する形に書き換える。
- **ワトソン君の驚き**: 「あの巨大な分岐の壁が消えた…！？ 新しい形式を追加するときは、ただ新しいクラスを作るだけで済むのか！」

### IV. 解決（事件の終わり）
- **結果**: コードは人間が読めるサイズに見事に分割され、単体テストも書けるようになった。
- **ロックの締め言葉**: 「すべての不吉な \`if\` 構文を排除して残ったものが、この『Strategy』という真実なんだよ、ワトソン君。さあ、報酬のバーボン（の代わりのエナジードリンク）をいただこうか」

### V. 探偵の調査報告書
- **表**: God Class（容疑） -> Strategyパターン（真実） -> 責務の分離・拡張性の向上（証拠）
- **推理のステップ**:
  1. 分岐の抽出とインターフェース定義（Moo::Role）
  2. 具象Strategy群の実装
  3. ContextへのStrategy注入（あるいは動的生成）による `if` の排除
- **ロックからのメッセージ**: 次なる「におい」への期待と、探偵のキザな台詞。

## 実装計画 (Code Design)

### Before (レガシーな神様)
```perl
package GodProcessor;
use Moo;

sub process_everything {
    my ($self, $type, $data) = @_;
    if ($type eq 'user_csv') {
        # ... バリデーション ...
        # ... CSV生成 ...
        # ... 保存 ...
    } elsif ($type eq 'product_json') {
        # ... 全く違うバリデーション ...
        # ... JSON生成 ...
        # ... API送信 ...
    } elsif ($type eq 'order_xml') {
        # ...
    } else {
        die "Unknown type";
    }
}
1;
```

### After (Strategyパターン適用)

Roleの定義:
```perl
package Processor::Role;
use Moo::Role;
requires 'process';
1;
```

Strategy実装:
```perl
package Processor::UserCsv;
use Moo;
with 'Processor::Role';
sub process { ... }
1;
```

Contextの簡略化:
```perl
package DataProcessor;
use Moo;

# 実行時に適切なStrategyを注入して処理を委譲
sub execute {
    my ($self, $strategy, $data) = @_;
    $strategy->process($data);
}
1;
```

## メタデータ・構成情報
- **slug**: `code-detective-strategy-god-class` (想定)
- **カテゴリ**: [Design Patterns, Perl]
- **タグ**: [perl, moo, strategy, refactoring, code-detective]
