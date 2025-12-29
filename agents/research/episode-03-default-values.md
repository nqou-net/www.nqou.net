# 調査報告: 第3回「デフォルト値で投稿日時を自動設定しよう」

## 調査概要

- **調査日**: 2025-12-29
- **調査対象**: Mooシリーズ第3回記事「デフォルト値で投稿日時を自動設定しよう」の執筆のための技術調査
- **調査目的**: Mooのdefault機能、Perlの日時処理、タイムスタンプ実装パターンに関する正確かつ実用的な情報収集

## 記事の位置づけ

### シリーズ情報
- **シリーズ名**: Mooで覚えるオブジェクト指向プログラミング
- **記事番号**: 第3回
- **タイトル**: デフォルト値で投稿日時を自動設定しよう
- **主要テーマ**: デフォルト値（default）

### 前回（第2回）の内容
- Messageクラスの作成
- オブジェクトの生成と利用
- プロパティ（name, text）の定義
- `is => 'ro'` と `is => 'rw'` の違い

### 今回の構成（案Aより）
**大見出し**:
- H2: タイムスタンプの必要性
- H2: defaultで自動的に値を設定する
- H2: サブルーチンリファレンスで動的な値を設定
- H2: 動かしてみよう
- H2: まとめ

**想定コード例**:
1. timestampプロパティに`default => sub { time }`を追加
2. 日時をフォーマットして表示する完全な例

## 調査結果

### 1. Mooのdefault機能

#### 1.1 固定値のdefault

**要点**:
- 固定値をdefaultに指定できる
- オブジェクト生成時に値が指定されない場合、この固定値が使用される
- シンプルで分かりやすい

**コード例**:
```perl
package Person;
use Moo;

has age => (
  is => 'rw',
  default => 0
);

1;
```

**使用例**:
```perl
use Person;

my $joe = Person->new();            # age will be 0
my $clara = Person->new(age => 3);  # age will be 3

print $joe->age;    # 0
print $clara->age;  # 3
```

**参考URL**:
- https://perlmaven.com/moo-attributes-with-default-values

#### 1.2 サブルーチンリファレンスによる動的なdefault

**要点**:
- **重要**: 動的な値（time、乱数など）は必ずコードリファレンス（`sub { ... }`）で指定する
- 裸の値（`default => time`）はクラス読み込み時に一度だけ評価され、全オブジェクトで同じ値になってしまう
- コードリファレンスはオブジェクト生成時（`new`）のたびに実行される
- コードリファレンスの第1引数には`$self`（構築中のオブジェクト）が渡される

**問題のある例**:
```perl
has birthdate => (
  is => 'rw',
  default => time  # BAD: クラス読み込み時に一度だけ評価される
);
```

**正しい例**:
```perl
has birthdate => (
  is => 'rw',
  default => sub { time }  # GOOD: オブジェクト生成のたびに実行される
);
```

**他の属性を参照する例**:
```perl
has something => (
  is      => 'ro',
  default => sub { $_[0]->other_data . " extra" },
);
```

**参考URL**:
- https://perlmaven.com/moo-attributes-with-default-values
- https://metacpan.org/pod/Moo
- https://docs.mojolicious.org/Moo

#### 1.3 defaultとbuilderの違い

**default**:
- **定義場所**: 属性定義の中に直接記述
- **サブクラス化**: 上書きできない（柔軟性が低い）
- **ロール**: 合成時に共有しづらい
- **用途**: シンプルなデフォルト値に適している

**builder**:
- **定義場所**: 名前付きメソッドとして独立
- **サブクラス化**: メソッドを上書きして簡単にカスタマイズ可能
- **ロール**: ロールでbuilderを要求できる（composability）
- **用途**: 複雑な初期化ロジックや、コードの再利用性が必要な場合に適している

**比較表**:

| オプション | ロジックの場所 | サブクラス化 | ロール合成 | lazy対応 | Mooサポート |
|-----------|---------------|------------|-----------|---------|-----------|
| default   | 属性定義内     | No         | No        | Yes     | Yes（coderef/scalar） |
| builder   | 名前付きメソッド | Yes       | Yes       | Yes     | Yes       |

**builderの例**:
```perl
package Message;
use Moo;

has timestamp => (
  is => 'ro',
  builder => '_build_timestamp'
);

sub _build_timestamp {
  my $self = shift;
  return time;
}

1;
```

**参考URL**:
- https://stackoverflow.com/questions/9526347/moose-builder-vs-default
- https://manpages.debian.org/testing/libmoose-perl/Moose::Cookbook::Basics::BinaryTree_BuilderAndLazyBuild.3pm.en.html

#### 1.4 defaultとlazyの組み合わせ

**lazy**:
- 属性値はオブジェクト生成時ではなく、**最初にアクセスされたとき**に計算される
- 計算コストが高い値や、必ずしも使用されない値に有効
- builderまたはdefaultと組み合わせて使用
- Mooでは`is => 'lazy'`という短縮形も使える

**lazyの例**:
```perl
has data => (
  is => 'rw',
  lazy => 1,
  default => sub { expensive_calculation() }
);
```

**Mooの短縮形**:
```perl
has data => (
  is => 'lazy',
  default => sub { expensive_calculation() }
);
```

**利点**:
- 起動時間の短縮
- リソースの効率的な使用
- 必要な時だけ計算

**注意点**:
- Mooでは`lazy_build`はサポートされていない（Mooseのみ）
- 代わりに`is => 'lazy'`を使う

**参考URL**:
- https://stackoverflow.com/questions/9746544/moo-lazy-attributes-and-default-coerce-invocation
- https://mvp.kablamo.org/oo/attributes/
- https://docs.mojolicious.org/Moo

### 2. Perlの日時処理

#### 2.1 time関数の使い方

**要点**:
- Perlの組み込み関数
- エポック時刻（1970年1月1日00:00:00 UTCからの経過秒数）を返す
- 整数値なので比較や計算が容易

**基本的な使い方**:
```perl
my $epoch_time = time();
print "Epoch time: $epoch_time\n";
# 出力例: Epoch time: 1735477200
```

**参考URL**:
- https://www.tutorialspoint.com/perl/perl_date_time.htm

#### 2.2 localtime関数による日時の取得

**要点**:
- エポック時刻を人間が読める形式に変換
- リストコンテキストでは9要素のリストを返す
- スカラーコンテキストでは文字列を返す
- **注意**: `$mon`は0始まり（0=1月）、`$year`は1900年からの年数

**リストコンテキスト**:
```perl
my ($sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst) = localtime(time);
print "$mday, $mon, $year\n"; 

# 注意: $mon は0始まり（0=1月、1=2月...11=12月）
# 注意: $year は1900年からの年数（2025年なら125）
```

**実用的な例**:
```perl
my ($sec, $min, $hour, $mday, $mon, $year) = localtime(time);
$year += 1900;  # 実際の年に変換
$mon += 1;      # 1-12の月に変換
printf "%04d-%02d-%02d %02d:%02d:%02d\n", $year, $mon, $mday, $hour, $min, $sec;
```

**スカラーコンテキスト**:
```perl
my $date_str = localtime();
print "Local date and time: $date_str\n";
# 出力例: Local date and time: Sat Dec 29 15:15:02 2025
```

**参考URL**:
- https://www.tutorialspoint.com/perl/perl_date_time.htm
- https://perldoc.perl.org/functions/localtime

#### 2.3 Time::Pieceモジュール

**要点**:
- Perl 5.8以降でコアモジュール（追加インストール不要）
- オブジェクト指向で扱いやすい
- 組み込みのフォーマット用メソッドが豊富
- 日付の比較や計算が簡単

**基本的な使い方**:
```perl
use Time::Piece;

my $t = localtime;
print "Time is $t\n";   # Stringifies to "Sat Dec 29 15:04:52 2025"
```

**プロパティへのアクセス**:
```perl
print $t->year;   # 2025（4桁の年）
print $t->mon;    # 12（1=1月、12=12月）
print $t->mday;   # 29（月の日）
```

**組み込みフォーマットメソッド**:
```perl
print $t->ymd, "\n";     # "2025-12-29"
print $t->mdy, "\n";     # "12-29-2025"
print $t->dmy, "\n";     # "29-12-2025"
print $t->hms, "\n";     # "15:04:52"
print $t->datetime, "\n";# "2025-12-29T15:04:52" (ISO 8601)
```

**区切り文字のカスタマイズ**:
```perl
print $t->mdy("/"), "\n";   # "12/29/2025"
print $t->dmy("."), "\n";   # "29.12.2025"
```

**曜日・月名**:
```perl
print $t->fullday, "\n";    # "Monday"
print $t->fullmonth, "\n";  # "December"
```

**カスタムフォーマット（strftime）**:
```perl
print $t->strftime('%Y-%m-%d %H:%M:%S'), "\n";    # "2025-12-29 15:04:52"
print $t->strftime('%A, %B %d, %Y'), "\n";        # "Monday, December 29, 2025"
```

**文字列からのパース**:
```perl
my $date = Time::Piece->strptime('2025-12-29', '%Y-%m-%d');
print $date->fullday;        # "Monday"
```

**日付の比較**:
```perl
my $now = localtime;
my $future = Time::Piece->strptime('2026-01-01', '%Y-%m-%d');
if ($future > $now) {
    print "The future is ahead!\n";
}
```

**Time::Pieceメソッド一覧表**:

| メソッド | 出力例 | 説明 |
|---------|--------|------|
| ymd | 2025-12-29 | ISO yyyy-mm-dd |
| mdy("/") | 12/29/2025 | US mm/dd/yyyy |
| dmy(".") | 29.12.2025 | EU dd.mm.yyyy |
| hms | 15:04:52 | 時刻 (hh:mm:ss) |
| fullday | Monday | 曜日名 |
| fullmonth | December | 月名 |
| datetime | 2025-12-29T15:04:52 | ISO 8601 |
| strftime(...) | [カスタム] | 柔軟なフォーマット |

**参考URL**:
- https://perldoc.perl.org/Time::Piece
- https://metacpan.org/pod/Time::Piece
- https://www.perl.com/article/59/2014/1/10/Solve-almost-any-datetime-need-with-Time--Piece/
- https://learnxbyexample.com/perl/time-formatting-parsing/

#### 2.4 POSIX::strftimeによる日時フォーマット

**要点**:
- POSIXモジュールはPerlコアモジュール
- 柔軟なフォーマット指定が可能
- ロケール対応
- POSIX/C標準に準拠

**基本的な使い方**:
```perl
use POSIX qw(strftime);

my $formatted = strftime "%Y-%m-%d %H:%M:%S", localtime();
print "Formatted datetime: $formatted\n";
# 出力例: Formatted datetime: 2025-12-29 15:15:02
```

**GMT/UTCでのフォーマット**:
```perl
my $gmt = strftime "%Y-%m-%d %H:%M:%S", gmtime();
```

**相対時刻の例（昨日）**:
```perl
my $yesterday = strftime "%b %d, %Y", localtime(time-86400); # 86400秒 = 1日
# 出力例: Dec 28, 2025
```

**POSIX::strftimeフォーマットコード完全リファレンス**:

| コード | 意味 | 出力例 | 備考 |
|--------|------|--------|------|
| %a | 曜日名（短縮） | Thu | ロケール依存 |
| %A | 曜日名（完全） | Thursday | ロケール依存 |
| %b | 月名（短縮） | Aug | ロケール依存 |
| %B | 月名（完全） | August | ロケール依存 |
| %c | 日時表現 | Thu Aug 23 14:55:02 2001 | ロケール依存 |
| %C | 世紀（年/100） | 20 | 2001年の場合20 |
| %d | 月の日（01-31） | 23 | ゼロ埋め |
| %D | 日付（%m/%d/%y） | 08/23/01 | 短縮形 |
| %e | 月の日（スペース埋め） | 23 | スペース埋め |
| %F | 日付（%Y-%m-%d） | 2001-08-23 | ISO 8601形式 |
| %g | ISO週ベース年（下2桁） | 01 | |
| %G | ISO週ベース年 | 2001 | |
| %h | %bと同じ | Aug | |
| %H | 時（24時間、00-23） | 14 | ゼロ埋め |
| %I | 時（12時間、01-12） | 02 | ゼロ埋め |
| %j | 年の日（001-366） | 235 | ゼロ埋め |
| %m | 月（01-12） | 08 | ゼロ埋め |
| %M | 分（00-59） | 55 | ゼロ埋め |
| %n | 改行文字 | | リテラル'\n' |
| %p | AM/PM | PM | ロケール依存 |
| %r | 12時間時刻 | 02:55:02 PM | ロケール依存 |
| %R | 時刻（%H:%M） | 14:55 | 短縮形 |
| %S | 秒（00-61） | 02 | うるう秒対応 |
| %t | タブ文字 | | リテラル'\t' |
| %T | 時刻（%H:%M:%S） | 14:55:02 | ISO 8601時刻 |
| %u | ISO曜日（1-7） | 4 | 月曜=1、日曜=7 |
| %U | 週番号（日曜始まり） | 33 | 00-53 |
| %V | ISO週番号 | 34 | 01-53 |
| %w | 曜日（0-6） | 4 | 日曜=0 |
| %W | 週番号（月曜始まり） | 34 | 00-53 |
| %x | ロケール日付 | 08/23/01 | ロケール依存 |
| %X | ロケール時刻 | 14:55:02 | ロケール依存 |
| %y | 年（下2桁） | 01 | 00-99 |
| %Y | 年（4桁） | 2001 | |
| %z | UTCからのオフセット | +0200 | タイムゾーン |
| %Z | タイムゾーン略称 | CDT | ロケール依存 |
| %% | %文字 | % | リテラル |

**よく使うフォーマット例**:
```perl
# ISO 8601形式
strftime "%Y-%m-%d %H:%M:%S", localtime;  # 2025-12-29 15:15:02

# 日本式
strftime "%Y年%m月%d日 %H時%M分%S秒", localtime;  # 2025年12月29日 15時15分02秒

# 米国式
strftime "%m/%d/%Y %I:%M:%S %p", localtime;  # 12/29/2025 03:15:02 PM

# ログファイル用
strftime "%Y%m%d_%H%M%S", localtime;  # 20251229_151502
```

**参考URL**:
- https://pubs.opengroup.org/onlinepubs/9699919799/functions/strftime.html
- https://www.tutorialspoint.com/posix-function-strftime-in-perl
- https://perlmaven.com/simple-timestamp-generation-using-posix-strftime
- https://perldoc.perl.org/POSIX
- https://csg.sph.umich.edu/chen/Perl/cookbook/ch03_09.htm

#### 2.5 初心者向けの日時処理方法

**推奨順序**:

1. **シンプルな用途**: `time` + `localtime`（組み込み関数のみ）
2. **読みやすさ重視**: `Time::Piece`（コアモジュール、インストール不要）
3. **柔軟なフォーマット**: `POSIX::strftime`（コアモジュール）
4. **複雑な日時操作**: `DateTime`（CPANモジュール、インストール必要）

**初心者向けの推奨**: Time::Piece
- Perl 5.8以降で標準搭載
- オブジェクト指向で分かりやすい
- 豊富な組み込みメソッド
- 日付の比較や計算が直感的

**Time::Pieceを使った実用例**:
```perl
use Time::Piece;

# 現在日時の取得
my $now = localtime;

# 見やすい表示
print "今日は", $now->fullday, "です\n";
print "日付: ", $now->ymd, "\n";
print "時刻: ", $now->hms, "\n";

# カスタムフォーマット
print $now->strftime("今日は%Y年%m月%d日です"), "\n";
```

**参考URL**:
- https://www.tutorialspoint.com/perl/perl_date_time.htm
- https://thelinuxcode.com/date-time-perl/
- https://www.geeksforgeeks.org/perl/perl-date-and-time/

### 3. タイムスタンプの実装パターン

#### 3.1 オブジェクト生成時の自動タイムスタンプ

**基本パターン**:
```perl
package Message;
use Moo;

has name => (is => 'ro');
has text => (is => 'ro');
has timestamp => (
  is      => 'ro',
  default => sub { time }
);

1;
```

**使用例**:
```perl
my $msg = Message->new(
  name => '太郎',
  text => 'こんにちは'
);
# timestampは自動的に現在時刻が設定される
```

**Time::Pieceを使った例**:
```perl
package Message;
use Moo;
use Time::Piece;

has name => (is => 'ro');
has text => (is => 'ro');
has timestamp => (
  is      => 'ro',
  default => sub { localtime->datetime }  # ISO 8601形式
);

1;
```

**参考URL**:
- https://perlmaven.com/moo-attributes-with-default-values

#### 3.2 created_at, updated_atパターン

**要点**:
- `created_at`: オブジェクト生成時に設定（読み取り専用）
- `updated_at`: 更新可能（読み書き可能）
- `touch`メソッドで更新タイムスタンプを更新

**基本実装**:
```perl
package MyClass;
use Moo;
use Time::Piece;

has created_at => (
    is      => 'ro',
    default => sub { time },
);

has updated_at => (
    is      => 'rw',
    default => sub { time },
);

sub touch {
    my $self = shift;
    $self->updated_at(time);
}

1;
```

**人間が読める形式での実装**:
```perl
package MyClass;
use Moo;
use Time::Piece;

sub now_string { localtime->strftime('%Y-%m-%d %H:%M:%S') }

has created_at => (
    is      => 'ro',
    default => \&now_string,
);

has updated_at => (
    is      => 'rw',
    default => \&now_string,
);

sub touch {
    my $self = shift;
    $self->updated_at(now_string());
}

1;
```

**DateTimeを使った実装**:
```perl
package Entity;
use Moo;
use DateTime;

has created_at => (
    is => 'ro',
    default => sub { DateTime->now->iso8601 }
);

has updated_at => (
    is => 'rw',
    default => sub { DateTime->now->iso8601 }
);

sub touch {
    my $self = shift;
    $self->updated_at(DateTime->now->iso8601);
}

1;
```

**使用例**:
```perl
my $obj = MyClass->new;
print "作成日時: ", $obj->created_at, "\n";
print "更新日時: ", $obj->updated_at, "\n";

# 何か変更を加える
sleep 2;
$obj->touch;
print "新しい更新日時: ", $obj->updated_at, "\n";
```

**参考URL**:
- https://www.slingacademy.com/article/mongoose-auto-add-createdat-and-updatedat-timestamps/
- https://www.geeksforgeeks.org/perl/perl-date-and-time/
- https://perlmaven.com/datetime

#### 3.3 タイムゾーンの扱い

**要点**:
- `localtime`: ローカルタイムゾーン（サーバーの設定に依存）
- `gmtime`: GMT/UTC（タイムゾーン非依存）
- タイムゾーンを明示的に管理する場合は`DateTime`モジュールを使用

**localtimeとgmtimeの違い**:
```perl
use POSIX qw(strftime);

# ローカル時刻
my $local = strftime "%Y-%m-%d %H:%M:%S %Z", localtime;
print "ローカル: $local\n";  # 例: 2025-12-29 15:15:02 JST

# UTC
my $utc = strftime "%Y-%m-%d %H:%M:%S %Z", gmtime;
print "UTC: $utc\n";  # 例: 2025-12-29 06:15:02 GMT
```

**ベストプラクティス**:
- **保存**: UTCで保存（`gmtime`使用）
- **表示**: ユーザーのタイムゾーンで表示（`localtime`使用）
- **複雑な要件**: `DateTime`モジュールを使用

**Time::Localモジュール**:
- `timelocal`: 日付要素からエポック秒へ変換（ローカル時刻）
- `timegm`: 日付要素からエポック秒へ変換（GMT）

```perl
use Time::Local;

my $time = timelocal($sec, $min, $hour, $mday, $mon, $year);
```

**参考URL**:
- https://www.tutorialspoint.com/perl/perl_date_time.htm
- https://perldoc.perl.org/functions/localtime
- https://perldoc.perl.org/functions/gmtime
- https://perldoc.perl.org/Time::Local
- https://thelinuxcode.com/date-time-perl/

### 4. 第2回からの発展

#### 4.1 Messageクラスへのtimestampプロパティ追加

**第2回のMessageクラス**:
```perl
package Message;
use Moo;
use utf8;

# 名前プロパティ
has name => (
    is => 'ro',
);

# メッセージ本文プロパティ
has text => (
    is => 'ro',
);

1;
```

**第3回での拡張（timestampプロパティ追加）**:
```perl
package Message;
use Moo;
use utf8;

# 名前プロパティ
has name => (
    is => 'ro',
);

# メッセージ本文プロパティ
has text => (
    is => 'ro',
);

# タイムスタンププロパティ（新規追加）
has timestamp => (
    is      => 'ro',
    default => sub { time }
);

1;
```

**使用例**:
```perl
my $msg = Message->new(
    name => '太郎',
    text => 'こんにちは'
);

print $msg->name, ": ", $msg->text, "\n";
print "投稿日時: ", scalar localtime($msg->timestamp), "\n";
```

#### 4.2 既存コードへの影響を最小限にする方法

**ポイント**:
1. 新しいプロパティは`default`を設定する
2. 既存のコードは変更不要（後方互換性維持）
3. `is => 'ro'`で読み取り専用にし、予期せぬ変更を防ぐ

**影響なし**:
```perl
# 第2回のコード（変更不要）
my $msg = Message->new(
    name => '太郎',
    text => 'こんにちは'
);
# timestampは自動的に設定される
```

**明示的に指定も可能**:
```perl
# 特定の時刻を指定したい場合
my $msg = Message->new(
    name => '太郎',
    text => 'こんにちは',
    timestamp => 1735477200  # 特定の時刻
);
```

#### 4.3 後方互換性の考慮

**原則**:
- 既存の使い方を壊さない
- 新機能は追加のみ
- デフォルト値により、既存コードは変更不要

**良い例**（後方互換性あり）:
```perl
# 新プロパティにdefaultを設定
has timestamp => (
    is      => 'ro',
    default => sub { time }
);
```

**悪い例**（後方互換性なし）:
```perl
# requiredを指定すると既存コードがエラーになる
has timestamp => (
    is       => 'ro',
    required => 1  # NG: 既存コードで指定していないとエラー
);
```

**段階的な機能追加の例**:
```perl
package Message;
use Moo;
use utf8;
use Time::Piece;

# 既存のプロパティ
has name => (is => 'ro');
has text => (is => 'ro');

# 第3回で追加（後方互換性あり）
has timestamp => (
    is      => 'ro',
    default => sub { time }
);

# 将来の拡張例（後方互換性あり）
has id => (
    is      => 'ro',
    default => sub { $_[0]->_generate_id }
);

# 表示用のメソッド追加
sub formatted_timestamp {
    my $self = shift;
    return localtime($self->timestamp)->strftime('%Y-%m-%d %H:%M:%S');
}

1;
```

### 5. 内部リンク候補

#### 5.1 第1回へのリンク

**記事パス**: `/2021/10/31/191008/`
**タイトル**: 第1回-Mooで覚えるオブジェクト指向プログラミング
**タグ**: perl, programming

**主な内容**:
- blessについて（忘れよう）
- Mooを使ってみる
- 用語（オブジェクト、クラス、プロパティ、メソッド）

**リンク文例**:
- 「前回の[第1回-Mooで覚えるオブジェクト指向プログラミング](/2021/10/31/191008/)では...」
- 「Mooの基本については[第1回](/2021/10/31/191008/)をご覧ください」

#### 5.2 第2回へのリンク

**記事パス**: `/content/post/1735477200.md`（公開後にパスが変わる可能性あり）
**タイトル**: 第2回【10分で実践】スパゲティコード脱却！Mooでメッセージをオブジェクト化
**タグ**: perl, programming, moo, object-oriented, tutorial, beginner, refactoring

**主な内容**:
- スパゲティコードの課題
- Messageクラスの作り方
- オブジェクトを使った投稿管理
- `is => 'ro'`と`is => 'rw'`の違い

**リンク文例**:
- 「前回の[第2回](/2021/10/31/191008/)では、Messageクラスを作成しました」
- 「Messageクラスの基本については[第2回](/2021/10/31/191008/)をご覧ください」

**注意**: 第2回は現在draft状態のため、公開後にファイル名が変更される可能性があります。タグ検索を利用して関連記事を見つけることを推奨します。

#### 5.3 その他の関連記事

**タグで検索**:
- `perl`: Perl関連の全記事
- `moo`: Moo関連の記事
- `object-oriented`: オブジェクト指向関連の記事
- `tutorial`: チュートリアル記事

## まとめ

### 重要なポイント

1. **defaultの使い方**
   - 固定値: `default => 0`
   - 動的な値: `default => sub { time }`（必ずコードリファレンス）
   - 裸の値（`default => time`）は避ける

2. **日時処理の選択肢**
   - シンプル: `time` + `localtime`
   - 推奨: `Time::Piece`（初心者向け）
   - 柔軟: `POSIX::strftime`
   - 複雑: `DateTime`

3. **タイムスタンプパターン**
   - `timestamp`: 単純なタイムスタンプ
   - `created_at`/`updated_at`: 作成・更新時刻の追跡

4. **後方互換性**
   - `default`を使えば既存コードへの影響なし
   - `required`は既存コードを壊すので注意

### 次のステップ

- 実際にコードを書いて動かしてみる
- Time::Pieceのメソッドを試す
- タイムスタンプのフォーマットをカスタマイズする

### 技術的な注意点

1. **コードリファレンスの重要性**: 動的な値は必ず`sub { ... }`で囲む
2. **タイムゾーンの考慮**: 保存はUTC、表示はローカル
3. **Time::Pieceの利点**: Perlコアモジュールで追加インストール不要
4. **後方互換性の維持**: defaultを使って既存コードを壊さない

## 参考文献

### Moo関連
- https://perlmaven.com/moo-attributes-with-default-values
- https://metacpan.org/pod/Moo
- https://docs.mojolicious.org/Moo
- https://stackoverflow.com/questions/9526347/moose-builder-vs-default
- https://stackoverflow.com/questions/9746544/moo-lazy-attributes-and-default-coerce-invocation

### 日時処理関連
- https://www.tutorialspoint.com/perl/perl_date_time.htm
- https://perldoc.perl.org/Time::Piece
- https://metacpan.org/pod/Time::Piece
- https://www.perl.com/article/59/2014/1/10/Solve-almost-any-datetime-need-with-Time--Piece/
- https://perldoc.perl.org/POSIX
- https://perlmaven.com/simple-timestamp-generation-using-posix-strftime
- https://pubs.opengroup.org/onlinepubs/9699919799/functions/strftime.html

### タイムスタンプパターン
- https://www.slingacademy.com/article/mongoose-auto-add-createdat-and-updatedat-timestamps/
- https://www.geeksforgeeks.org/perl/perl-date-and-time/
- https://perlmaven.com/datetime
- https://thelinuxcode.com/date-time-perl/

### タイムゾーン
- https://perldoc.perl.org/functions/localtime
- https://perldoc.perl.org/functions/gmtime
- https://perldoc.perl.org/Time::Local

---

**調査完了日**: 2025-12-29
**調査者**: investigative-research エージェント
