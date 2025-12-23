---
title: "【2025年版】Perl Getopt::Long使い方大全：よくある問題と解決策20選"
draft: true
tags:
- perl
- getopt-long
- command-line
- cli-tools
- best-practices
description: "Perlでコマンドラインツールを作る際の必須モジュールGetopt::Longの使い方を逆引き形式で解説。よくあるエラーと解決策、実務で使えるコードパターン20選を網羅した決定版ガイド。"
---

## Getopt::Longとは：Perlで本格的なCLIツールを作る

Perlでコマンドラインツールを作るなら、Getopt::Longは避けて通れません。このモジュールは、`--verbose`や`--output=file.txt`のような長いオプション名に対応した、強力なコマンドライン引数解析ツールです。

最高なのは、**Perl 5に標準搭載**されているため、追加インストール不要ですぐに使える点です。CPANモジュールのインストールで悩む必要はありません！

### なぜGetopt::Longを使うべきか

シンプルなスクリプトなら`@ARGV`を直接処理すればいいじゃないか、と思うかもしれません。しかし、Getopt::Longを使うメリットは計り知れません：

- **長いオプション名のサポート**: `--help`, `--output=result.txt`など、読みやすく分かりやすい
- **型指定とバリデーション**: 文字列、整数、浮動小数点、配列、ハッシュを自動的に処理
- **エイリアス対応**: `--verbose`と`-v`を同時にサポート
- **否定可能なオプション**: `--color`と`--nocolor`を自動生成
- **複数値の受け取り**: 配列やハッシュで複数の値を簡単に管理

これらの機能を自前で実装すると、バグの温床になります。Getopt::Longを使えば、堅牢で保守性の高いコードが書けるのです。

### Getopt::Std との違いと選択基準

Perlには`Getopt::Std`という別のオプション解析モジュールもあります。簡単に比較してみましょう：

| 機能 | Getopt::Std | Getopt::Long |
|------|-------------|--------------|
| 短いオプション (`-v`) | ✅ | ✅ |
| 長いオプション (`--verbose`) | ❌ | ✅ |
| オプション値の型指定 | 限定的 | ✅ 豊富 |
| バンドリング (`-abc`) | ✅ | ✅（要設定） |
| エイリアス | ❌ | ✅ |
| 配列・ハッシュ | ❌ | ✅ |
| コールバック関数 | ❌ | ✅ |
| 新規コードでの推奨度 | ❌ | ✅ |

**結論**: 2-3個の単純なオプションしか使わないレガシーコード保守以外では、**Getopt::Longを選ぶべき**です。特に新規プロジェクトでは迷わずGetopt::Longを使いましょう。

## クイックスタート：5分で動かす最初の一歩

理論はこのくらいにして、実際にコードを動かしてみましょう。まずは最小限の例からスタートです。

### 最小限のコード例

```perl
#!/usr/bin/env perl
# Perl 5.38+
use strict;
use warnings;
use Getopt::Long;

my $verbose = 0;
my $output = '';

GetOptions(
    'verbose' => \$verbose,
    'output=s' => \$output,
) or die("Error in command line arguments\n");

print "Verbose mode ON\n" if $verbose;
print "Output file: $output\n" if $output;
print "Processing...\n";
```

このコードを`hello.pl`として保存してください。

### 実行して確認

さあ、実行してみましょう：

```bash
# 基本的な実行
$ perl hello.pl
Processing...

# verboseフラグを有効化
$ perl hello.pl --verbose
Verbose mode ON
Processing...

# outputオプションを指定
$ perl hello.pl --output=result.txt
Output file: result.txt
Processing...

# 両方を指定
$ perl hello.pl --verbose --output=data.txt
Verbose mode ON
Output file: data.txt
Processing...
```

わずか数行のコードで、プロフェッショナルなコマンドラインインターフェースが完成しました！

**重要ポイント**:
- `GetOptions()`の第一引数は**オプション名の定義**
- `verbose`は真偽値フラグ（指定されれば1、なければ0）
- `output=s`の`=s`は「文字列の値を必須とする」という意味
- リファレンス（`\$verbose`）を渡すことで、変数が直接更新される

## 基本パターン：これだけ覚えれば8割カバー

Getopt::Longの威力を発揮する基本パターンを5つ紹介します。これらをマスターすれば、日常的なCLIツール開発の8割はカバーできます。

### パターン1：真偽値フラグの受け取り方

最もシンプルなパターンです。フラグが指定されれば`1`、なければ`0`（または初期値）になります。

```perl
use Getopt::Long;

my $verbose = 0;
my $debug = 0;
my $force = 0;

GetOptions(
    'verbose' => \$verbose,
    'debug'   => \$debug,
    'force'   => \$force,
) or die("Error in command line arguments\n");

print "Verbose: $verbose\n";
print "Debug: $debug\n";
print "Force: $force\n";
```

**実行例**:
```bash
$ perl script.pl --verbose --debug
Verbose: 1
Debug: 1
Force: 0
```

**増分カウンタ**: `+`を使うと、複数回指定された回数をカウントできます：

```perl
my $verbosity = 0;
GetOptions('verbose+' => \$verbosity);

# perl script.pl -v -v -v
# $verbosity は 3 になる
```

### パターン2：文字列オプションの受け取り方

ファイル名やURLなど、文字列の値を受け取る最も一般的なパターンです。

```perl
use Getopt::Long;

my $input = '';
my $output = '';
my $format = 'text';  # デフォルト値

GetOptions(
    'input=s'  => \$input,
    'output=s' => \$output,
    'format=s' => \$format,
) or die("Error in command line arguments\n");

die "Error: --input is required\n" unless $input;

print "Input: $input\n";
print "Output: $output\n" if $output;
print "Format: $format\n";
```

**実行例**:
```bash
$ perl script.pl --input=data.txt --output=result.txt --format=json
Input: data.txt
Output: result.txt
Format: json
```

**ポイント**:
- `=s`の`s`は「string（文字列）」の意味
- `=`は「値が必須」を示す
- オプション値は`--option=value`または`--option value`の両方の形式で指定可能

### パターン3：数値（整数・浮動小数点）の受け取り方

数値を扱う場合、型指定により自動的に検証が行われます。

```perl
use Getopt::Long;

my $count = 10;      # デフォルト値
my $ratio = 1.0;     # デフォルト値
my $timeout = 30;

GetOptions(
    'count=i'   => \$count,      # i = integer（整数）
    'ratio=f'   => \$ratio,      # f = float（浮動小数点）
    'timeout=i' => \$timeout,
) or die("Error in command line arguments\n");

print "Count: $count\n";
print "Ratio: $ratio\n";
print "Timeout: $timeout\n";
```

**実行例**:
```bash
$ perl script.pl --count=100 --ratio=0.75 --timeout=60
Count: 100
Ratio: 0.75
Timeout: 60

# 不正な値を指定するとエラー
$ perl script.pl --count=abc
Value "abc" invalid for option count (number expected)
Error in command line arguments
```

**自動バリデーション**が行われるのが素晴らしい点です！

### パターン4：複数の値を配列で受け取る

複数のファイルやタグを受け取る場合、配列が便利です。

```perl
use Getopt::Long;

my @input_files;
my @tags;
my @exclude;

GetOptions(
    'input=s@'   => \@input_files,  # s@ = 文字列の配列
    'tag=s@'     => \@tags,
    'exclude=s@' => \@exclude,
) or die("Error in command line arguments\n");

print "Input files: " . join(', ', @input_files) . "\n" if @input_files;
print "Tags: " . join(', ', @tags) . "\n" if @tags;
print "Exclude: " . join(', ', @exclude) . "\n" if @exclude;
```

**実行例**:
```bash
$ perl script.pl --input=file1.txt --input=file2.txt --tag=perl --tag=cli
Input files: file1.txt, file2.txt
Tags: perl, cli
```

**重要**: `=s@`の`@`を忘れないでください。`=s`だけだと最後の値しか保存されません！

### パターン5：キー=値形式をハッシュで受け取る

設定オプションをキー=値のペアで受け取る高度なパターンです。

```perl
use Getopt::Long;

my %config;

GetOptions(
    'config=s%' => \%config,  # s% = 文字列のハッシュ
) or die("Error in command line arguments\n");

print "Configuration:\n";
for my $key (sort keys %config) {
    print "  $key = $config{$key}\n";
}
```

**実行例**:
```bash
$ perl script.pl --config host=localhost --config port=8080 --config debug=1
Configuration:
  debug = 1
  host = localhost
  port = 8080
```

設定ファイルを使わずに、コマンドラインから柔軟に設定を渡せるのは便利ですね！

## よくある問題と解決策

ここからは、Getopt::Longを使う際に初心者が必ず直面する問題と、その解決策を紹介します。

### Q1：「Error in command line arguments」エラーが出る

**症状**:
```bash
$ perl script.pl --unknown-option
Unknown option: unknown-option
Error in command line arguments
```

**原因**:
- 定義されていないオプションを指定した
- オプション名のスペルミス
- 型指定が合わない値を渡した（例：整数オプションに文字列）

**解決策**:

```perl
# エラー内容を詳しく表示
use Getopt::Long qw(:config pass_through);
GetOptions(...);

# または、未知のオプションを許可（非推奨）
use Getopt::Long qw(:config pass_through);
```

**推奨パターン**: ヘルプメッセージを表示して終了

```perl
GetOptions(...) or do {
    print STDERR "Error: Invalid command line arguments\n";
    print STDERR "Use --help for usage information\n";
    exit 1;
};
```

### Q2：オプションを指定しても変数が更新されない

**症状**:
```perl
my $verbose;
GetOptions('verbose' => \$verbose);
print "Verbose: $verbose\n";  # 常に空白が表示される
```

**原因**: 変数の初期化を忘れている

**解決策**: **必ずデフォルト値で初期化**

```perl
my $verbose = 0;  # ✅ これが正解
GetOptions('verbose' => \$verbose);
```

オプションが指定されなかった場合、変数は`undef`のままになります。`if ($verbose)`のような条件式で警告が出る原因になります。

### Q3：数値を指定したのに文字列として扱われる

**症状**:
```perl
my $count;
GetOptions('count=s' => \$count);  # 's' は文字列！
print $count + 10;  # 数値として扱いたい
```

**原因**: 型指定が間違っている

**解決策**: **正しい型指定を使う**

```perl
my $count = 0;
GetOptions('count=i' => \$count);  # ✅ 'i' は整数
print $count + 10;  # 正しく数値計算される
```

型指定の一覧：
- `=s` → 文字列（string）
- `=i` → 整数（integer）
- `=f` → 浮動小数点（float）

### Q4：`--verbose`と`-v`両方で使えるようにしたい

**解決策**: **エイリアス（別名）を使う**

```perl
GetOptions(
    'verbose|v' => \$verbose,  # --verbose または -v
    'help|h|?' => \$help,      # --help, -h, -? すべて有効
    'output|o=s' => \$output,  # --output または -o
);
```

パイプ（`|`）で複数の名前を区切るだけです。簡単ですね！

**実行例**:
```bash
$ perl script.pl -v          # OK
$ perl script.pl --verbose   # OK
$ perl script.pl -h          # OK
$ perl script.pl --help      # OK
```

### Q5：複数回同じオプションを指定できるようにしたい

**解決策**: **配列で受け取る**

```perl
my @include_dirs;
GetOptions('include=s@' => \@include_dirs);

# 実行: perl script.pl -I./lib -I./local/lib -I/usr/lib
```

または、**カウンタとして使う**:

```perl
my $debug_level = 0;
GetOptions('debug+' => \$debug_level);

# 実行: perl script.pl -d -d -d
# 結果: $debug_level = 3
```

### Q6：オプション以外の引数（ファイル名など）を取得したい

**重要**: `GetOptions()`は処理したオプションを`@ARGV`から**削除**します。残った要素が、オプション以外の引数です。

```perl
use Getopt::Long;

my $verbose = 0;
GetOptions('verbose' => \$verbose);

# 実行: perl script.pl --verbose file1.txt file2.txt
# @ARGV には ('file1.txt', 'file2.txt') が残る

die "Error: No input files specified\n" unless @ARGV;

for my $file (@ARGV) {
    print "Processing: $file\n";
    # ファイル処理
}
```

これは非常に重要なポイントです。`@ARGV`の扱いを理解していないと、引数が消えたように見えて混乱します。

### Q7：`--help`でヘルプメッセージを表示したい

**解決策**: **Pod::Usageと組み合わせる**

```perl
use Getopt::Long;
use Pod::Usage;

my $help = 0;
my $man = 0;

GetOptions(
    'help|h|?' => \$help,
    'man'      => \$man,
) or pod2usage(2);

pod2usage(1) if $help;
pod2usage(-exitval => 0, -verbose => 2) if $man;

__END__

=head1 NAME

mytool - Example command line tool

=head1 SYNOPSIS

mytool [options] [files]

 Options:
   -h, --help     Show brief help
   --man          Show full manual

=head1 DESCRIPTION

This tool does something useful.

=cut
```

**実行例**:
```bash
$ perl script.pl --help
# 簡潔なヘルプメッセージが表示される

$ perl script.pl --man
# 完全なマニュアルが表示される
```

Pod::Usageを使えば、ドキュメントとヘルプメッセージを一元管理できます。DRY原則の完璧な実践です！

### Q8：設定ファイルとコマンドラインの優先順位を制御したい

**推奨パターン**: コマンドラインオプションを最優先にする

```perl
use Getopt::Long;

# 1. デフォルト値
my $output = 'default.txt';
my $verbose = 0;

# 2. 設定ファイルから読み込み（存在すれば上書き）
my $config_file = "$ENV{HOME}/.mytoolrc";
if (-f $config_file) {
    open my $fh, '<', $config_file or die $!;
    while (<$fh>) {
        chomp;
        next if /^\s*#/ or /^\s*$/;  # コメントと空行をスキップ
        if (/^output\s*=\s*(.+)$/) {
            $output = $1;
        }
        elsif (/^verbose\s*=\s*(\d+)$/) {
            $verbose = $1;
        }
    }
    close $fh;
}

# 3. コマンドラインオプション（最優先）
GetOptions(
    'output=s' => \$output,
    'verbose+' => \$verbose,
    'config=s' => \$config_file,
);

print "Output: $output\n";
print "Verbose: $verbose\n";
```

優先順位は：**デフォルト値 < 設定ファイル < コマンドラインオプション**

## 【落とし穴編】初心者が必ず躓く7つのポイント

ここでは、初心者が必ず一度は踏む地雷を列挙します。事前に知っておけば回避できます！

### 落とし穴1：GetOptionsの戻り値をチェックしない

**❌ 悪い例**:
```perl
GetOptions('output=s' => \$output);
# エラーが起きても処理が続行される！
```

**✅ 良い例**:
```perl
GetOptions('output=s' => \$output)
    or die("Error in command line arguments\n");
```

オプション解析に失敗した場合、`GetOptions()`は偽値を返します。これをチェックしないと、不正な状態でプログラムが動き続けます。

### 落とし穴2：変数の初期化を忘れる

**❌ 悪い例**:
```perl
my $verbose;  # undef のまま
GetOptions('verbose' => \$verbose);

if ($verbose) {  # 警告が出る可能性
    print "Verbose mode\n";
}
```

**✅ 良い例**:
```perl
my $verbose = 0;  # 明示的にデフォルト値を設定
GetOptions('verbose' => \$verbose);

if ($verbose) {
    print "Verbose mode\n";
}
```

### 落とし穴3：型指定を間違える

**❌ 悪い例**:
```perl
my $count = 0;
GetOptions('count=s' => \$count);  # 文字列として受け取る
$count += 10;  # 数値演算で警告
```

**✅ 良い例**:
```perl
my $count = 0;
GetOptions('count=i' => \$count);  # 整数として受け取る
$count += 10;  # 正しく動作
```

型指定のまとめ：

| 型 | 指定子 | 用途 |
|----|--------|------|
| 文字列 | `=s` | ファイル名、URL、一般的な文字列 |
| 整数 | `=i` | カウント、ポート番号、ID |
| 浮動小数点 | `=f` | 比率、パーセンテージ、小数値 |
| 真偽値 | （なし） | フラグ、スイッチ |

### 落とし穴4：長いオプションに`-`を1つしか使わない

**要注意**: 長いオプションには**必ず`--`（ダブルダッシュ）を使う**

```bash
$ perl script.pl --verbose   # ✅ 正しい
$ perl script.pl -verbose    # ❌ -v -e -r -b -o -s -e と解釈される可能性
```

1文字オプションは`-`、複数文字オプションは`--`が慣例です。

### 落とし穴5：複数値の受け取りで`@`を忘れる

**❌ 悪い例**:
```perl
my @tags;
GetOptions('tag=s' => \@tags);
# 実行: --tag perl --tag cli
# 結果: @tags = ('cli')  最後の値しか残らない！
```

**✅ 良い例**:
```perl
my @tags;
GetOptions('tag=s@' => \@tags);  # @ を付ける
# 実行: --tag perl --tag cli
# 結果: @tags = ('perl', 'cli')  すべての値が保存される
```

配列で受け取る場合は**必ず`@`を付ける**ことを忘れずに！

### 落とし穴6：@ARGVの扱いを理解していない

`GetOptions()`は処理したオプションを`@ARGV`から**削除**します。これを理解していないと混乱します。

```perl
use Getopt::Long;

# 実行前: @ARGV = ('--verbose', 'file1.txt', '--output=out.txt', 'file2.txt')

my $verbose = 0;
my $output = '';
GetOptions(
    'verbose' => \$verbose,
    'output=s' => \$output,
);

# 実行後: @ARGV = ('file1.txt', 'file2.txt')
# オプションは削除され、ファイル名だけが残る

for my $file (@ARGV) {
    print "Processing: $file\n";
}
```

これは**仕様**です。バグではありません。

### 落とし穴7：バンドリングの設定を忘れる

UNIX系のコマンドでは`-abc`を`-a -b -c`として解釈する「バンドリング」がよく使われますが、Getopt::Longでは**デフォルトで無効**です。

**有効にする方法**:

```perl
use Getopt::Long qw(:config bundling);

my ($a, $b, $c);
GetOptions(
    'a' => \$a,
    'b' => \$b,
    'c' => \$c,
);

# これで -abc が -a -b -c として解釈される
```

または、個別に設定：

```perl
use Getopt::Long;
Getopt::Long::Configure('bundling');
```

## 実務で使える実装パターン集

ここからは、実際のプロジェクトで使える実践的なパターンを紹介します。

### パターン6：ヘルプとバージョン表示の標準実装

プロフェッショナルなツールには、`--help`と`--version`は必須です。

```perl
#!/usr/bin/env perl
# Perl 5.38+
use strict;
use warnings;
use Getopt::Long;
use Pod::Usage;

our $VERSION = '1.2.3';

my $help = 0;
my $version = 0;
my $man = 0;

GetOptions(
    'help|h|?'  => \$help,
    'version|V' => \$version,
    'man'       => \$man,
) or pod2usage(2);

if ($version) {
    print "$0 version $VERSION\n";
    exit 0;
}

pod2usage(1) if $help;
pod2usage(-exitval => 0, -verbose => 2) if $man;

# メインの処理
print "Running main process...\n";

__END__

=head1 NAME

mytool - Professional command line tool example

=head1 SYNOPSIS

mytool [options]

 Options:
   -h, --help     Show brief help message
   --man          Show full manual
   -V, --version  Show version information

=head1 DESCRIPTION

This tool demonstrates best practices for command line tools.

=cut
```

**実行例**:
```bash
$ perl mytool.pl --version
mytool.pl version 1.2.3

$ perl mytool.pl --help
# 簡潔なヘルプが表示される

$ perl mytool.pl --man
# 完全なマニュアルページが表示される
```

### パターン7：設定ファイルとの連携

大規模なツールでは、設定ファイルとコマンドラインオプションを組み合わせます。

```perl
use Getopt::Long;
use File::Spec;

# デフォルト設定
my %config = (
    verbose => 0,
    output  => 'output.txt',
    format  => 'text',
);

# 設定ファイルの候補
my @config_files = (
    File::Spec->catfile($ENV{HOME}, '.mytoolrc'),
    '/etc/mytool.conf',
    'mytool.conf',
);

# 設定ファイルを読み込む
for my $file (@config_files) {
    next unless -f $file;
    load_config($file, \%config);
    last;
}

# コマンドラインオプション（最優先）
GetOptions(
    'verbose|v' => \$config{verbose},
    'output|o=s' => \$config{output},
    'format|f=s' => \$config{format},
    'config|c=s' => sub {
        my ($name, $value) = @_;
        load_config($value, \%config);
    },
) or die("Error in command line arguments\n");

print "Configuration:\n";
print "  Verbose: $config{verbose}\n";
print "  Output: $config{output}\n";
print "  Format: $config{format}\n";

sub load_config {
    my ($file, $config) = @_;
    open my $fh, '<', $file or die "Cannot open $file: $!\n";
    while (<$fh>) {
        chomp;
        s/#.*//;  # コメント削除
        next if /^\s*$/;  # 空行スキップ
        if (/^\s*(\w+)\s*=\s*(.+?)\s*$/) {
            $config->{$1} = $2;
        }
    }
    close $fh;
}
```

### パターン8：サブコマンドの実装（Git風）

`git add`、`git commit`のようなサブコマンド形式を実装できます。

```perl
#!/usr/bin/env perl
# Perl 5.38+
use strict;
use warnings;
use Getopt::Long qw(:config pass_through);

my $subcommand = shift @ARGV or die "Error: No subcommand specified\n";

if ($subcommand eq 'add') {
    cmd_add();
}
elsif ($subcommand eq 'list') {
    cmd_list();
}
elsif ($subcommand eq 'delete') {
    cmd_delete();
}
else {
    die "Error: Unknown subcommand: $subcommand\n";
}

sub cmd_add {
    my ($name, $force, $verbose);
    GetOptions(
        'name|n=s' => \$name,
        'force|f'  => \$force,
        'verbose|v' => \$verbose,
    ) or die("Error in add command arguments\n");
    
    die "Error: --name is required\n" unless $name;
    
    print "Adding: $name\n";
    print "Force mode enabled\n" if $force;
}

sub cmd_list {
    my ($format, $verbose);
    GetOptions(
        'format=s' => \$format,
        'verbose|v' => \$verbose,
    ) or die("Error in list command arguments\n");
    
    $format ||= 'text';
    print "Listing items (format: $format)\n";
}

sub cmd_delete {
    my ($id, $force);
    GetOptions(
        'id=i' => \$id,
        'force|f' => \$force,
    ) or die("Error in delete command arguments\n");
    
    die "Error: --id is required\n" unless defined $id;
    
    print "Deleting ID: $id\n";
    print "WARNING: Force delete!\n" if $force;
}
```

**実行例**:
```bash
$ perl tool.pl add --name=item1 --force
Adding: item1
Force mode enabled

$ perl tool.pl list --format=json
Listing items (format: json)

$ perl tool.pl delete --id=42 --force
Deleting ID: 42
WARNING: Force delete!
```

### パターン9：デバッグレベルの段階的制御

デバッグ出力のレベルを制御する実用的なパターンです。

```perl
use Getopt::Long;

my $debug_level = 0;

GetOptions(
    'debug|d+' => \$debug_level,  # 複数回指定でレベル上昇
) or die("Error in command line arguments\n");

debug(1, "Starting process...");
debug(2, "Detailed initialization...");
debug(3, "Very verbose debug info...");

sub debug {
    my ($level, $message) = @_;
    return if $debug_level < $level;
    print STDERR "[DEBUG:$level] $message\n";
}
```

**実行例**:
```bash
$ perl script.pl
# 何も出力されない

$ perl script.pl -d
[DEBUG:1] Starting process...

$ perl script.pl -dd
[DEBUG:1] Starting process...
[DEBUG:2] Detailed initialization...

$ perl script.pl -ddd
[DEBUG:1] Starting process...
[DEBUG:2] Detailed initialization...
[DEBUG:3] Very verbose debug info...
```

`-d`、`-dd`、`-ddd`と増やすことで、詳細度をコントロールできます。

### パターン10：否定可能なオプション（--color/--nocolor）

多くのUNIXツールは、`--color`と`--no-color`のような否定形をサポートしています。

```perl
use Getopt::Long;

my $color = 1;  # デフォルトで有効

GetOptions(
    'color!' => \$color,  # ! で否定可能
) or die("Error in command line arguments\n");

if ($color) {
    print "\e[32mGreen text\e[0m\n";
} else {
    print "Plain text\n";
}
```

**実行例**:
```bash
$ perl script.pl
Green text  # カラー出力

$ perl script.pl --color
Green text  # 明示的にカラー有効

$ perl script.pl --nocolor
Plain text  # カラー無効
```

`!`を付けるだけで、`--option`と`--nooption`の両方が自動生成されます。素晴らしい！

## 高度なテクニック

さらに一歩踏み込んだ、上級者向けのテクニックを紹介します。

### コールバック関数でカスタム処理

オプションが指定されたときに、カスタム関数を実行できます。

```perl
use Getopt::Long;

my $verbose = 0;
my @log_messages;

GetOptions(
    'verbose|v' => sub {
        $verbose = 1;
        push @log_messages, "Verbose mode enabled at " . scalar(localtime);
    },
    'output|o=s' => sub {
        my ($name, $value) = @_;
        push @log_messages, "Output set to: $value";
        
        # カスタムバリデーション
        if ($value !~ /\.txt$/) {
            warn "Warning: Output file should have .txt extension\n";
        }
    },
    'debug|d+' => sub {
        my ($name, $value) = @_;
        print STDERR "Debug level increased to $value\n";
    },
) or die("Error in command line arguments\n");

print "Log:\n";
print "  $_\n" for @log_messages;
```

コールバックを使えば、複雑なバリデーションやロギングが可能になります。

### バンドリング設定（-abc形式）

UNIX風の`-abc`形式を有効にします。

```perl
use Getopt::Long qw(:config bundling);

my ($all, $verbose, $recursive, $force);

GetOptions(
    'a|all'       => \$all,
    'v|verbose'   => \$verbose,
    'r|recursive' => \$recursive,
    'f|force'     => \$force,
) or die("Error in command line arguments\n");

print "All: $all\n" if $all;
print "Verbose: $verbose\n" if $verbose;
print "Recursive: $recursive\n" if $recursive;
print "Force: $force\n" if $force;
```

**実行例**:
```bash
$ perl script.pl -avrf
All: 1
Verbose: 1
Recursive: 1
Force: 1
```

`-avrf`が`-a -v -r -f`として解釈されます。

### 大文字小文字の区別設定

デフォルトでは、大文字小文字を区別しません。厳密に区別したい場合：

```perl
use Getopt::Long qw(:config no_ignore_case);

GetOptions(
    'Verbose' => \$verbose,    # 大文字のV
    'verbose' => \$verbose_v,  # 小文字のv
);
```

通常は区別しない方が親切です。

## ベストプラクティスとアンチパターン

長年の経験から得られた、推奨パターンと避けるべきパターンを紹介します。

### ✅ こうすべき：推奨パターン5選

**1. 常にGetOptionsの戻り値をチェック**

```perl
GetOptions(...) or die("Error in command line arguments\n");
```

**2. すべてのオプション変数に初期値を設定**

```perl
my $verbose = 0;          # ✅
my $output = 'out.txt';   # ✅
my @files = ();           # ✅
```

**3. ハッシュリファレンスで整理（多数のオプション）**

```perl
my %opt = (
    verbose => 0,
    output => 'default.txt',
);

GetOptions(\%opt,
    'verbose|v',
    'output|o=s',
    'count|c=i',
);
```

**4. Pod::Usageでヘルプを統合**

```perl
use Pod::Usage;
GetOptions(...) or pod2usage(2);
pod2usage(1) if $opt{help};
```

**5. 設定ファイル < コマンドライン の優先順位**

```perl
# 1. デフォルト
my $value = 'default';

# 2. 設定ファイル
load_config() if $config_file;

# 3. コマンドライン（最優先）
GetOptions('value=s' => \$value);
```

### ❌ 避けるべき：アンチパターン5選

**1. エラーチェックを省略**

```perl
# ❌ 悪い
GetOptions('output=s' => \$output);
```

**2. 変数を初期化しない**

```perl
# ❌ 悪い
my $verbose;  # undef のまま
```

**3. 型指定を省略または間違える**

```perl
# ❌ 悪い
GetOptions('count' => \$count);  # 文字列として扱われる
```

**4. ハードコードされたパスや値**

```perl
# ❌ 悪い
my $output = '/tmp/output.txt';  # 柔軟性がない

# ✅ 良い
my $output = $ENV{TMPDIR} || '/tmp';
GetOptions('output=s' => \$output);
```

**5. グローバル変数を使う**

```perl
# ❌ 悪い
our $VERBOSE;
GetOptions('verbose' => \$VERBOSE);

# ✅ 良い
my $verbose = 0;
GetOptions('verbose' => \$verbose);
```

## 完全サンプルコード：実務レベルのCLIツール

これまでの知識を総動員した、実務で使えるレベルの完全なサンプルです。

### 全機能を盛り込んだ完成版

```perl
#!/usr/bin/env perl
# Perl 5.38+
# 依存: なし（標準モジュールのみ）
use strict;
use warnings;
use Getopt::Long qw(:config bundling no_ignore_case);
use Pod::Usage;
use File::Basename;

our $VERSION = '2.0.0';

# デフォルト設定
my %config = (
    verbose     => 0,
    debug       => 0,
    output      => 'output.txt',
    format      => 'text',
    color       => 1,
    input_files => [],
    tags        => [],
    options     => {},
);

# コマンドラインオプション解析
GetOptions(
    'help|h|?'      => \my $help,
    'man'           => \my $man,
    'version|V'     => \my $version,
    'verbose|v+'    => \$config{verbose},
    'debug|d'       => \$config{debug},
    'quiet|q'       => \my $quiet,
    'output|o=s'    => \$config{output},
    'format|f=s'    => \$config{format},
    'color!'        => \$config{color},
    'input|i=s@'    => $config{input_files},
    'tag|t=s@'      => $config{tags},
    'option|O=s%'   => $config{options},
) or pod2usage(2);

# ヘルプとバージョン
if ($version) {
    print basename($0) . " version $VERSION\n";
    exit 0;
}

pod2usage(1) if $help;
pod2usage(-exitval => 0, -verbose => 2) if $man;

# quietモードの処理
$config{verbose} = 0 if $quiet;

# 入力ファイルの検証
unless (@{$config{input_files}}) {
    die "Error: No input files specified. Use --input or -i\n";
}

# フォーマットの検証
unless ($config{format} =~ /^(text|json|xml|csv)$/i) {
    die "Error: Invalid format '$config{format}'. " .
        "Must be one of: text, json, xml, csv\n";
}

# メイン処理
main(\%config);

sub main {
    my $config = shift;
    
    debug(1, "Starting processing with configuration:");
    debug(1, "  Output: $config->{output}");
    debug(1, "  Format: $config->{format}");
    debug(1, "  Color: " . ($config->{color} ? 'enabled' : 'disabled'));
    
    if (@{$config->{tags}}) {
        debug(2, "  Tags: " . join(', ', @{$config->{tags}}));
    }
    
    if (%{$config->{options}}) {
        debug(2, "  Options:");
        for my $key (sort keys %{$config->{options}}) {
            debug(2, "    $key = $config->{options}{$key}");
        }
    }
    
    # ファイル処理
    for my $file (@{$config->{input_files}}) {
        process_file($file, $config);
    }
    
    info("Processing complete. Output: $config->{output}");
}

sub process_file {
    my ($file, $config) = @_;
    
    debug(1, "Processing file: $file");
    
    unless (-f $file) {
        warn "Warning: File not found: $file\n";
        return;
    }
    
    # 実際のファイル処理をここに実装
    info("Processed: $file");
}

sub debug {
    my ($level, $message) = @_;
    return unless $config{debug} || $config{verbose} >= $level;
    
    my $prefix = $config{color} ? "\e[36m[DEBUG]\e[0m" : "[DEBUG]";
    print STDERR "$prefix $message\n";
}

sub info {
    my $message = shift;
    return if $config{verbose} == 0;
    
    my $prefix = $config{color} ? "\e[32m[INFO]\e[0m" : "[INFO]";
    print "$prefix $message\n";
}

sub error {
    my $message = shift;
    my $prefix = $config{color} ? "\e[31m[ERROR]\e[0m" : "[ERROR]";
    print STDERR "$prefix $message\n";
}

__END__

=head1 NAME

mytool - Professional command line tool with Getopt::Long

=head1 SYNOPSIS

mytool [options] --input FILE [--input FILE2 ...]

 Options:
   -h, -?, --help           Show brief help message
   --man                    Show full documentation
   -V, --version            Show version information
   
   -v, --verbose            Verbose output (can be repeated: -vv, -vvv)
   -d, --debug              Enable debug mode
   -q, --quiet              Suppress all output except errors
   
   -i, --input FILE         Input file (required, can be repeated)
   -o, --output FILE        Output file (default: output.txt)
   -f, --format FORMAT      Output format: text|json|xml|csv (default: text)
   
   --color, --nocolor       Enable/disable colored output (default: enabled)
   -t, --tag TAG            Add tag (can be repeated)
   -O, --option KEY=VALUE   Set option (can be repeated)

=head1 DESCRIPTION

B<mytool> is a demonstration of best practices for building
professional command line tools with Getopt::Long.

This tool showcases:

=over 4

=item * Proper option handling with type validation

=item * Multiple input files support

=item * Configurable output formats

=item * Debug and verbose modes

=item * Color output control

=item * Tag and option management

=back

=head1 EXAMPLES

 # Basic usage
 mytool -i input.txt

 # Multiple inputs with verbose output
 mytool -vv -i file1.txt -i file2.txt -o result.txt

 # JSON format with tags
 mytool -i data.txt -f json -t perl -t cli

 # Set custom options
 mytool -i data.txt -O debug=1 -O timeout=30

 # Disable color output
 mytool -i data.txt --nocolor

 # Very verbose debug mode
 mytool -vvv -d -i data.txt

=head1 OPTIONS

=over 4

=item B<-h, -?, --help>

Print a brief help message and exit.

=item B<--man>

Print the full manual page and exit.

=item B<-V, --version>

Print version information and exit.

=item B<-v, --verbose>

Enable verbose output. Can be repeated to increase verbosity level.

=item B<-d, --debug>

Enable debug mode with detailed diagnostic messages.

=item B<-q, --quiet>

Suppress all output except errors.

=item B<-i FILE, --input=FILE>

Specify input file. Required. Can be specified multiple times.

=item B<-o FILE, --output=FILE>

Specify output file. Default is 'output.txt'.

=item B<-f FORMAT, --format=FORMAT>

Specify output format. Valid values: text, json, xml, csv.
Default is 'text'.

=item B<--color, --nocolor>

Enable or disable colored output. Color is enabled by default.

=item B<-t TAG, --tag=TAG>

Add a tag. Can be specified multiple times.

=item B<-O KEY=VALUE, --option KEY=VALUE>

Set a custom option. Can be specified multiple times.

=back

=head1 EXIT STATUS

=over 4

=item 0

Success

=item 1

General error

=item 2

Command line argument error

=back

=head1 AUTHOR

Your Name <your.email@example.com>

=head1 LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
```

### コードの解説とポイント

このサンプルの重要ポイント：

1. **bundling設定**: `-vvv`のような連続したオプションをサポート
2. **エラーハンドリング**: すべての入力を検証
3. **柔軟な出力**: カラー出力のON/OFF切り替え
4. **複数入力**: 配列で複数ファイルを受け取る
5. **ハッシュオプション**: カスタムオプションをキー=値で受け取る
6. **完全なPOD**: ヘルプとマニュアルを統合
7. **デバッグレベル**: `-v`、`-vv`、`-vvv`で段階的な詳細度

**実行例**:

```bash
# 基本的な使用
$ perl mytool.pl -i data.txt
[INFO] Processed: data.txt
[INFO] Processing complete. Output: output.txt

# 詳細な出力
$ perl mytool.pl -vv -i file1.txt -i file2.txt -f json
[DEBUG] Starting processing with configuration:
[DEBUG]   Output: output.txt
[DEBUG]   Format: json
[DEBUG]   Color: enabled
[DEBUG] Processing file: file1.txt
[INFO] Processed: file1.txt
[DEBUG] Processing file: file2.txt
[INFO] Processed: file2.txt
[INFO] Processing complete. Output: output.txt

# タグとオプション
$ perl mytool.pl -i data.txt -t perl -t cli -O timeout=60 -O debug=1
```

## トラブルシューティング

問題が発生したときの診断方法を紹介します。

### デバッグ方法

**1. オプション解析の内容を確認**

```perl
use Data::Dumper;
$Data::Dumper::Sortkeys = 1;

my %opt;
GetOptions(\%opt, ...) or die;

print Dumper(\%opt);  # すべてのオプションを表示
print Dumper(\@ARGV);  # 残った引数を表示
```

**2. 詳細なエラーメッセージ**

```perl
use Getopt::Long qw(:config auto_help);
Getopt::Long::Configure('debug');  # デバッグモード有効化

GetOptions(...);
```

**3. 段階的なテスト**

```bash
# 一つずつオプションを追加してテスト
$ perl script.pl --verbose
$ perl script.pl --verbose --output=test.txt
$ perl script.pl --verbose --output=test.txt --format=json
```

### よくあるエラーメッセージと対処法

**エラー1**: `Unknown option: xxx`

```
原因: 定義されていないオプションを指定
対処: オプション名のスペルを確認、または GetOptions に追加
```

**エラー2**: `Value "abc" invalid for option count (number expected)`

```
原因: 整数型オプションに文字列を指定
対処: 正しい数値を指定、または型指定を =s に変更
```

**エラー3**: `Option xxx requires an argument`

```
原因: 値が必須のオプション（=s, =i など）で値を省略
対処: --option=value の形式で値を指定
```

**エラー4**: `Use of uninitialized value`

```
原因: 変数の初期化を忘れた
対処: my $var = 0; のように初期値を設定
```

**デバッグ用ワンライナー**:

```bash
# オプション解析だけをテスト
$ perl -MGetopt::Long -MData::Dumper -e '
my %o; 
GetOptions(\%o, "verbose", "output=s") or die; 
print Dumper(\%o), Dumper(\@ARGV)
' -- --verbose --output=test.txt file1.txt file2.txt
```

## まとめ：Getopt::Longをマスターして生産性向上

Getopt::Longは、Perlでコマンドラインツールを作る際の強力な武器です。この記事で紹介した内容をまとめます：

**基本パターン（必須）**:
- ✅ 真偽値フラグ、文字列、整数、配列、ハッシュの受け取り
- ✅ エラーチェック（`GetOptions() or die`）
- ✅ 変数の初期化

**実践パターン（推奨）**:
- ✅ Pod::Usageでヘルプ統合
- ✅ 設定ファイルとの連携
- ✅ サブコマンド対応

**落とし穴（要注意）**:
- ❌ GetOptionsの戻り値をチェックしない
- ❌ 変数の初期化を忘れる
- ❌ 型指定を間違える
- ❌ 配列受け取りで`@`を忘れる

**次のステップ**:

1. 自分の小さなスクリプトにGetopt::Longを導入
2. Pod::Usageでヘルプを追加
3. 設定ファイルとの連携を実装
4. サブコマンド対応で本格的なツールへ

Getopt::Longをマスターすれば、Perlでのコマンドラインツール開発が驚くほど快適になります。この記事が、あなたの生産性向上の一助となれば幸いです。

Happy Perl hacking! 🐪

## 参考資料

### 公式ドキュメント

{{< linkcard "https://perldoc.perl.org/Getopt::Long" >}}

{{< linkcard "https://metacpan.org/pod/Getopt::Long" >}}

{{< linkcard "https://metacpan.org/dist/Getopt-Long" >}}

### チュートリアル

{{< linkcard "https://perlmaven.com/how-to-process-command-line-arguments-in-perl" >}}

{{< linkcard "https://perlmaven.com/advanced-usage-of-getopt-long-accepting-command-line-arguments" >}}

{{< linkcard "https://www.perl.com/pub/2007/07/12/options-and-configuration.html/" >}}

### 日本語リソース

{{< linkcard "https://perlzemi.com/blog/20100514127696.html" >}}

{{< linkcard "https://jp-seemore.com/sys/20063/" >}}

{{< linkcard "https://perl-users.jp/articles/advent-calendar/2011/casual/21" >}}

{{< linkcard "https://gihyo.jp/dev/serial/01/perl-hackers-hub/004503" >}}
