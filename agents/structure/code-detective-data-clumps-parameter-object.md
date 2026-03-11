---
date: 2026-03-13T07:07:05+09:00
description: コード探偵ロックの事件簿「終わらないバケツリレーの悲劇（Data Clumps / Long Parameter List）」の構造案
title: '連載構造案 - コード探偵ロックの事件簿【Parameter Object】'
---

# 連載構造案：コード探偵ロックの事件簿【Parameter Object】統合版

## 前提情報

- **シリーズ名**: コード探偵ロックの事件簿
- **テーマ**: レガシーコード・アンチパターンの解決 × 設計技法
- **技術スタック**: Perl (Mooを利用)
- **今回のアンチパターン**: Long Parameter List（長い引数リスト） / Data Clumps（データの群れ）
- **今回の解決策**: Introduce Parameter Object（引数オブジェクトの導入）
- **形式**: 統合版（1つの完結した記事）

## 登場人物

- **ロック**: 主人公。ホームズ気取りのコード探偵。「手荷物検査のないバケツリレーは、いずれ爆弾を運ぶことになる」と嘯く。
- **ワトソン君（依頼人）**: 今回の語り手。真面目な若手エンジニア。ECサイトの注文処理システムを担当。「権限フラグも」「キャンペーンコードも」と仕様追加の嵐に愚直に応え続けた結果、引数が10個もある関数群が5階層も続く「終わらないバケツリレー」を完成させてしまい、深夜のデバッグ迷宮に迷い込んでいる。

## ストーリー構成（探偵メタファー）

### I. 依頼（終わらないバケツリレー）
- **状況**: 深夜のLCI（レガシー・コード・インベスティゲーション）に、目の下に隈を作ったワトソン君が駆け込んでくる。
- **主訴**: 「バグの原因が全く分かりません！ 注文処理の奥深くで、存在しないユーザーIDエラーが出るんです。呼び出し元の引数は絶対合っているはずなのに……！」
- **ロックの反応**: 「ふむ。君は真面目すぎるがゆえに、荷物をただ隣の人に渡し続けるだけの『終わらないバケツリレー』を構築してしまったようだな」

### II. 現場検証（無実の罪と手荷物検査）
- **Beforeコード提示**: `$user_id`, `$shop_id`, `$auth_token`, `$campaign_code`, etc... と延々と続く関数の引数。これらがAからBへ、BからCへとただ横流しされている。
- **ロックの推理と真相**: ロックが呼び出しの5階層目を見とがめる。「ほら、ここを見たまえ。第3引数の `$user_id` と第4引数の `$shop_id`、どちらも数値型だが……**ここで渡す順番が逆になっている**」
- **ワトソン君の絶望**: 「そんな……引数が10個もあって、しかもただ次の関数に渡すだけだから、コピペした時にズレたんだ……！」
- **ロックの指摘**: 「関数の引数は『その関数が直接使うもの』だけを受け取るべきだ。使わないものをただ運ぶだけのバケツリレーは、途中に関心がなく監視の目がない分、今回のように簡単に中身がすり替わる」

### III. 推理披露（カバンに詰めてラベルを貼れ）
- **解説と処置**: ロックが「Parameter Object（引数オブジェクト）」の導入実演を開始する。
- **解決へのアプローチ**:
  1. 「バラバラの荷物を一つのカバンに詰めなさい」。常に一緒に連れ回されている変数群（Data Clumps）を見つけ出し、`OrderContext`（または `OrderRequest`）という専用のクラス（Mooオブジェクト）を作成する。
  2. 5階層の関数群の引数を、すべてこの `$context` オブジェクト1つに変更する。
  3. 奥深くの関数（実際に値を使う関数）だけが、`$context->user_id` のようにカバンを開けて中身を取り出す。
- **ワトソン君の感嘆**: 「引数が1つになった！ これなら順番を間違えようがないし、新しいパラメータが増えてもカバン（Context）の中身を増やすだけで、途中の関数たちのシグネチャを変更しなくて済む……！」

### IV. 解決（静かなる注文処理）
- **結果**: バグは消え去り、将来の仕様変更（引数追加）にも強い構造に生まれ変わった。
- **ロックの締め言葉**: 「データは群れをなす性質がある。常に一緒にいるデータたちを見つけたら、彼らに『名前（クラス）』を与え、一つのチームとして扱うのだよ」
- **オチ**: ワトソン君が「なるほど！ じゃあこれからは、どんな関数でも引数は全部1つの巨大な `GlobalContext` にまとめちゃえば最強ですね！」と極論に走る。ロックが「……それはただのグローバル変数の再発明だ、ワトソン君。何事も『適切な粒度』というものがある」と呆れる。

### V. 探偵の調査報告書
- **表**: Long Parameter List / Data Clumps（容疑） -> Parameter Object（真実） -> データの凝集性の向上とシグネチャ変更の抑制（証拠）
- **推理のステップ**:
  1. 常に一緒に渡されているパラメータの群れ（Data Clumps）を特定する。
  2. それらのパラメータをプロパティとして持つ新しいクラス（Parameter Object）を作成する。
  3. 元の関数の長い引数リストを、新しいオブジェクト1つに置き換える。
- **ロックからのメッセージ**: 「使わないものを運ばせるな。運ぶなら、名前のついたカバンに入れろ」

## 実装計画

### Before（バケツリレーと順番間違いの悲劇）

```perl
# 呼び出し元
process_order($user_id, $shop_id, $item_id, $amount, $campaign_code, $auth_token);

# 第1階層
sub process_order {
    my ($user_id, $shop_id, $item_id, $amount, $campaign_code, $auth_token) = @_;
    # 自分は使わないが、下層のためにただ引き回す
    validate_order($user_id, $shop_id, $item_id, $amount, $campaign_code, $auth_token);
}

# 第2階層
sub validate_order {
    my ($user_id, $shop_id, $item_id, $amount, $campaign_code, $auth_token) = @_;
    # ... 中略 ...
    # 💥ここで悲劇が起きる！ user_id と shop_id の順番を間違えている！
    calculate_discount($shop_id, $user_id, $item_id, $amount, $campaign_code);
}

# 最終階層（実際に値を使う場所）
sub calculate_discount {
    my ($user_id, $shop_id, $item_id, $amount, $campaign_code) = @_;
    # $user_id に $shop_id が入ってしまっているため、DB検索でエラーになる
    my $user = User->find($user_id); 
    # ...
}
```

### After（Parameter Objectの導入）

```perl
package OrderContext;
use Moo;
use Types::Standard qw(Int Str Optional);

# 常に一緒にいるデータ群（Data Clumps）をクラスにまとめる
has user_id       => (is => 'ro', isa => Int, required => 1);
has shop_id       => (is => 'ro', isa => Int, required => 1);
has item_id       => (is => 'ro', isa => Int, required => 1);
has amount        => (is => 'ro', isa => Int, required => 1);
has campaign_code => (is => 'ro', isa => Optional[Str]);
has auth_token    => (is => 'ro', isa => Str, required => 1);

1;
```

```perl
# 呼び出し元：カバン（Context）に詰めて渡す
# 名前付き引数（ハッシュ）になるため、順番間違いが起きない
my $context = OrderContext->new(
    user_id       => $user_id,
    shop_id       => $shop_id,
    item_id       => $item_id,
    amount        => $amount,
    auth_token    => $auth_token,
    campaign_code => $campaign_code,
);

process_order($context);

# 第1階層、第2階層
# 引数が1つになり、シグネチャがすっきりする
# 将来パラメータが増えても、ここのシグネチャ（引数の数）は変わらない
sub process_order {
    my ($context) = @_;
    validate_order($context);
}

sub validate_order {
    my ($context) = @_;
    calculate_discount($context);
}

# 最終階層
sub calculate_discount {
    my ($context) = @_;
    # 必要な時に、カバンから必要なものだけを取り出す
    my $user = User->find($context->user_id);
    # ...
}
```

## メタデータ・構成情報
- **slug**: `code-detective-data-clumps-parameter-object`
- **カテゴリ**: [tech]
- **タグ**: [design-pattern, perl, moo, parameter-object, data-clumps, long-parameter-list, refactoring, code-detective]
