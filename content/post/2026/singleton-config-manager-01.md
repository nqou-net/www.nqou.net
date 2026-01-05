---
title: "第1回-設定を管理するクラスを作ろう"
draft: true
tags:
  - perl
  - moo
  - config
  - beginner
description: "Perl/Mooで設定を管理するクラスを作成します。ハードコードされた設定値をクラスで管理する方法を、初心者向けにステップバイステップで解説します。"
---

[@nqounet](https://x.com/nqounet)です。

シリーズ「設定ファイルマネージャーを作ってみよう」の第1回です。

## このシリーズについて

このシリーズでは、アプリケーションの設定を管理する仕組みを、全5回を通してステップバイステップで構築していきます。

シリーズ構成:

- **第1回（今回）**: 設定を管理するクラスを作ろう
- 第2回以降: 設定クラスの機能を拡張し、より実践的な構成へ

初回となる今回は、ハードコードされた設定値をクラスで管理する基本を学びます。

## 前提知識と対象読者

このシリーズは、以下の方を対象としています。

- Perl入学式を卒業したばかりの入門者
- 「Mooで覚えるオブジェクト指向プログラミング」シリーズを読了済み

まだ読んでいない方は、先に以下のシリーズを読むことをおすすめします。

{{< linkcard "/2021/10/31/191008/" >}}

## 技術スタック

このシリーズでは、以下の技術を使用します。

- Perl v5.36以降（signatures対応）
- Mooによるオブジェクト指向プログラミング

## 今回学ぶこと

今回の新しい概念は「設定クラスの基本」です。

アプリケーションを作成する際、データベース接続情報やAPIのURLなど、さまざまな設定値が必要になります。これらの設定値をどのように管理するかは、コードの保守性に大きく影響します。

## 問題のあるコード：ハードコードされた設定

まずは、問題のあるコードを見てみましょう。設定値がスクリプト内に直接書かれている例です。

```perl
#!/usr/bin/env perl
use v5.36;

# データベースに接続する処理
my $db_host = 'localhost';
my $db_port = 3306;
my $db_name = 'myapp';
my $db_user = 'admin';
my $db_pass = 'secret123';

say "Connecting to $db_host:$db_port/$db_name as $db_user";
# 実際のDB接続処理...

# APIにリクエストを送る処理
my $api_url = 'https://api.example.com';
my $api_timeout = 30;

say "Calling API: $api_url (timeout: ${api_timeout}s)";
# 実際のAPI呼び出し処理...

# ログファイルに書き込む処理
my $log_file = '/var/log/myapp.log';
my $debug_mode = 1;

say "Logging to $log_file (debug: $debug_mode)";
# 実際のログ出力処理...
```

このコードには、いくつかの問題があります。

- 設定値がコード全体に散らばっており、一覧性がない
- 設定を変更するたびにコードを修正する必要がある
- 開発環境と本番環境で設定を切り替えにくい
- 同じ設定値を複数の場所で使う場合、重複が発生する

## 改善したコード：Configクラスで設定を管理

次に、設定値をクラスで管理するように改善したコードを見てみましょう。

```perl
#!/usr/bin/env perl
use v5.36;

# === Configクラスの定義 ===
package Config {
    use Moo;

    # データベース設定
    has db_host => (
        is      => 'ro',
        default => sub { 'localhost' },
    );

    has db_port => (
        is      => 'ro',
        default => sub { 3306 },
    );

    has db_name => (
        is      => 'ro',
        default => sub { 'myapp' },
    );

    has db_user => (
        is      => 'ro',
        default => sub { 'admin' },
    );

    has db_pass => (
        is      => 'ro',
        default => sub { 'secret123' },
    );

    # API設定
    has api_url => (
        is      => 'ro',
        default => sub { 'https://api.example.com' },
    );

    has api_timeout => (
        is      => 'ro',
        default => sub { 30 },
    );

    # ログ設定
    has log_file => (
        is      => 'ro',
        default => sub { '/var/log/myapp.log' },
    );

    has debug_mode => (
        is      => 'ro',
        default => sub { 1 },
    );
}

# === メイン処理 ===
package main;

# 設定オブジェクトを作成
my $config = Config->new;

# データベースに接続する処理
say "Connecting to " . $config->db_host . ":" . $config->db_port
    . "/" . $config->db_name . " as " . $config->db_user;
# 実際のDB接続処理...

# APIにリクエストを送る処理
say "Calling API: " . $config->api_url
    . " (timeout: " . $config->api_timeout . "s)";
# 実際のAPI呼び出し処理...

# ログファイルに書き込む処理
say "Logging to " . $config->log_file
    . " (debug: " . $config->debug_mode . ")";
# 実際のログ出力処理...
```

この改善により、以下のメリットが得られます。

- すべての設定値が1つのクラスにまとまっている
- 設定値へのアクセスがメソッド呼び出しで統一される
- 将来的な拡張（バリデーション、外部ファイルからの読み込みなど）がしやすい
- コード内のどこからでも同じ設定オブジェクトを使える

## コード解説

### Configクラスの構造

Configクラスは、Mooを使って定義しています。各設定項目は `has` でプロパティとして定義します。

```perl
has db_host => (
    is      => 'ro',
    default => sub { 'localhost' },
);
```

- `is => 'ro'` : 読み取り専用（read-only）のプロパティにする。設定値は通常変更されないため `ro` が適切である
- `default` : デフォルト値を設定する。サブルーチンリファレンス `sub { ... }` で囲む

### 設定オブジェクトの利用

メイン処理では、まず設定オブジェクトを作成します。

```perl
my $config = Config->new;
```

その後は、メソッド呼び出しで設定値を取得します。

```perl
$config->db_host    # => 'localhost'
$config->api_timeout  # => 30
```

### デフォルト値の上書き

`new` メソッドに引数を渡すことで、デフォルト値を上書きできます。

```perl
# 本番環境向けの設定
my $config = Config->new(
    db_host    => 'production-db.example.com',
    db_pass    => 'prod_password',
    debug_mode => 0,
);
```

これにより、環境に応じた設定の切り替えが可能になります。

## 今回のまとめ

今回は、設定クラスの基本を学びました。

- ハードコードされた設定値の問題点を確認した
- Mooを使ってConfigクラスを定義した
- 設定値をプロパティとして管理する方法を学んだ
- デフォルト値と上書きの仕組みを理解した

次回は、このConfigクラスをさらに発展させていきます。お楽しみに！

## 完成コード

今回の完成コードです。`config_demo.pl` として保存して実行できます。

```perl
#!/usr/bin/env perl
use v5.36;

# === Configクラスの定義 ===
package Config {
    use Moo;

    # データベース設定
    has db_host => (
        is      => 'ro',
        default => sub { 'localhost' },
    );

    has db_port => (
        is      => 'ro',
        default => sub { 3306 },
    );

    has db_name => (
        is      => 'ro',
        default => sub { 'myapp' },
    );

    has db_user => (
        is      => 'ro',
        default => sub { 'admin' },
    );

    has db_pass => (
        is      => 'ro',
        default => sub { 'secret123' },
    );

    # API設定
    has api_url => (
        is      => 'ro',
        default => sub { 'https://api.example.com' },
    );

    has api_timeout => (
        is      => 'ro',
        default => sub { 30 },
    );

    # ログ設定
    has log_file => (
        is      => 'ro',
        default => sub { '/var/log/myapp.log' },
    );

    has debug_mode => (
        is      => 'ro',
        default => sub { 1 },
    );
}

# === メイン処理 ===
package main;

# 設定オブジェクトを作成
my $config = Config->new;

# データベースに接続する処理
say "Connecting to " . $config->db_host . ":" . $config->db_port
    . "/" . $config->db_name . " as " . $config->db_user;

# APIにリクエストを送る処理
say "Calling API: " . $config->api_url
    . " (timeout: " . $config->api_timeout . "s)";

# ログファイルに書き込む処理
say "Logging to " . $config->log_file
    . " (debug: " . $config->debug_mode . ")";

# === デフォルト値を上書きする例 ===
say "\n--- Custom config example ---";

my $prod_config = Config->new(
    db_host    => 'production-db.example.com',
    db_pass    => 'prod_password',
    debug_mode => 0,
);

say "Production DB host: " . $prod_config->db_host;
say "Debug mode: " . $prod_config->debug_mode;
```

このスクリプトを実行するには、まずMooをインストールしてください。

```shell
cpanm Moo
perl config_demo.pl
```

実行結果:

```
Connecting to localhost:3306/myapp as admin
Calling API: https://api.example.com (timeout: 30s)
Logging to /var/log/myapp.log (debug: 1)

--- Custom config example ---
Production DB host: production-db.example.com
Debug mode: 0
```
