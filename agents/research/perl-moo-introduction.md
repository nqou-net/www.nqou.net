# Perl Moo入門記事 調査ドキュメント

## 調査概要

- **調査目的**: PerlのMooモジュールについての入門記事作成のための情報収集
- **調査実施日**: 2025-12-29
- **調査キーワード**: Perl Moo, Perl オブジェクト指向, Moo vs Moose, Perl モダンOOP, Moo has属性, Moo ロール

---

## 1. Mooの基本概念

### Mooとは

Mooは、Perlのモダンで軽量なオブジェクト指向システムです。Mooseの機能の大部分を提供しながら、より高速な起動時間と最小限の依存関係を実現しています。

**主な特徴**:
- 純粋Perlで実装（XS依存なし）
- 軽量・高速な起動
- Mooseとの完全互換性
- 宣言的な構文でクラス定義

### 基本的なクラス定義

```perl
package Person;
use Moo;

has name  => (is => 'rw');      # 読み書き可能な属性
has email => (is => 'rw');      # 別の属性

sub greet {
    my $self = shift;
    print "Hello, my name is " . $self->name . "!\n";
}

1;
```

### オブジェクトの使用

```perl
use Person;

my $user = Person->new(name => 'Alice', email => 'alice@example.com');
$user->greet;          # prints: Hello, my name is Alice!
print $user->email;    # prints: alice@example.com
```

---

## 2. Moo vs Moose 比較

### 比較表

| 項目              | Moo                      | Moose                    |
|-------------------|--------------------------|--------------------------|
| 起動速度          | 非常に高速               | やや遅い                 |
| 依存関係          | 純粋Perl（XSなし）        | XS依存あり               |
| メタプロトコル    | なし                     | あり（Class::MOP）       |
| 型システム        | 基本的（Type::Tiny）     | 豊富で拡張可能           |
| ロール            | Role::Tiny               | 強力なネイティブロール   |
| 拡張              | 少ない（MooX）           | 多数（MooseX::*）        |
| 移行              | Mooseへ容易              | Mooへは難しい            |
| 用途              | CLI、スクリプト、中規模  | 大規模アプリ、フレームワーク |

### どちらを選ぶべきか

- **Moo推奨の場合**:
  - 高速な起動が必要（CLIツール、小規模スクリプト）
  - 最小限の依存関係が求められる
  - 中規模プロジェクト

- **Moose推奨の場合**:
  - 高度なメタプログラミングが必要
  - MooseX拡張エコシステムを活用したい
  - 大規模で複雑なアプリケーション

---

## 3. has属性の詳細

### 基本オプション

```perl
has attribute_name => (
    is       => 'rw',       # 'ro'（読み取り専用）または 'rw'（読み書き可能）
    default  => sub { ... },
    required => 1,
    lazy     => 1,
    trigger  => sub { ... },
);
```

### 各オプションの詳細

#### `is`（アクセサタイプ）
- `ro`: 読み取り専用（コンストラクタでのみ設定可能）
- `rw`: 読み書き可能

```perl
has id   => (is => 'ro');  # 一度設定したら変更不可
has name => (is => 'rw');  # いつでも変更可能
```

#### `default`（デフォルト値）
- スカラー値またはコードリファレンスで指定
- 配列/ハッシュはコードリファレンスで指定（共有を避けるため）

```perl
has age        => (is => 'rw', default => 0);
has created_at => (is => 'ro', default => sub { time });
has children   => (is => 'ro', default => sub { [] });
```

#### `required`（必須属性）
- `1`に設定するとコンストラクタで必須

```perl
has name => (is => 'ro', required => 1);
```

#### `lazy`（遅延評価）
- `1`に設定すると、最初のアクセス時にdefaultが評価される
- 高コストな初期化や、必ずしも使われない属性に有効

```perl
has expensive_data => (
    is      => 'ro',
    lazy    => 1,
    default => sub { compute_expensive_data() },
);
```

#### `trigger`（変更時フック）
- 属性が設定されたときに呼ばれるコードリファレンス
- ロギング、バリデーション、関連状態の更新に使用

```perl
has size => (
    is      => 'rw',
    trigger => sub {
        my ($self, $new_value) = @_;
        print "Size changed to $new_value\n";
    },
);
```

---

## 4. Moo::Role（ロール）

### ロールとは

ロールは、継承を使わずにクラス間で振る舞いを共有する仕組みです。複数のロールを1つのクラスに適用できます。

### ロールの定義

```perl
package MyApp::Role::Logger;
use Moo::Role;

has 'log_prefix' => (
    is      => 'ro',
    default => sub { '[LOG]' },
);

sub log_msg {
    my ($self, $msg) = @_;
    print $self->log_prefix . " $msg\n";
}

1;
```

### ロールの使用

```perl
package MyApp::User;
use Moo;
with 'MyApp::Role::Logger';  # ロールを適用

has 'username' => (is => 'ro');

1;
```

```perl
use MyApp::User;
my $user = MyApp::User->new(username => 'alice');
$user->log_msg('User created');  # prints: [LOG] User created
```

### 複数ロールの適用

```perl
package MyApp::Admin;
use Moo;
with 'MyApp::Role::Logger', 'MyApp::Role::Auditor';

1;
```

### `requires`（必須メソッド）

ロールが消費者に特定のメソッド実装を要求できます。

```perl
package MyApp::Role::Nameable;
use Moo::Role;
requires 'name';  # 消費するクラスはnameを実装必須

sub name_length {
    my $self = shift;
    length $self->name;
}

1;
```

---

## 5. Type::Tinyによる型制約

### 基本的な使い方

```perl
use Moo;
use Types::Standard qw(Str Int Enum ArrayRef InstanceOf);

has name    => (is => 'ro', isa => Str, required => 1);
has gender  => (is => 'ro', isa => Enum[qw(m f)]);
has age     => (is => 'rw', isa => Int->where('$_ >= 0'));
has children=> (
    is      => 'ro',
    isa     => ArrayRef[InstanceOf['Person']],
    default => sub { [] },
);
```

### 主な型制約

| 型              | 説明                         |
|-----------------|------------------------------|
| `Str`           | 文字列                       |
| `Int`           | 整数                         |
| `Num`           | 数値                         |
| `Bool`          | ブール値                     |
| `ArrayRef`      | 配列リファレンス             |
| `HashRef`       | ハッシュリファレンス         |
| `InstanceOf`    | 特定クラスのインスタンス     |
| `Enum`          | 列挙値                       |

### カスタム型制約

```perl
use Type::Tiny;

my $PositiveInt = Type::Tiny->new(
    name       => 'PositiveInt',
    constraint => sub { $_ > 0 },
);

has count => (is => 'rw', isa => $PositiveInt);
```

---

## 6. 継承

```perl
package Employee;
use Moo;
extends 'Person';  # 親クラスを指定

has job_title => (is => 'rw');

1;
```

---

## 参考URL

### 公式ドキュメント（CPAN）

| リソース | URL | 信頼性 |
|----------|-----|--------|
| Moo公式ドキュメント | https://metacpan.org/pod/Moo | ★★★★★ |
| Moo::Role公式ドキュメント | https://metacpan.org/pod/Moo::Role | ★★★★★ |
| Type::Tinyマニュアル | https://metacpan.org/dist/Type-Tiny/view/lib/Type/Tiny/Manual.pod | ★★★★★ |
| Type::Tiny公式サイト | https://typetiny.toby.ink/ | ★★★★★ |
| Moose公式ドキュメント | https://metacpan.org/pod/Moose | ★★★★★ |

### 日本語解説記事

| リソース | URL | 信頼性 |
|----------|-----|--------|
| perlootut日本語訳 | https://perldoc.jp/docs/perl/5.34.0/perlootut.pod | ★★★★☆ |
| Perlオブジェクト指向入門（Perlゼミ） | https://perlzemi.com/blog/20221004090015.html | ★★★★☆ |
| Perl5のオブジェクト指向を理解する | https://perl-users.jp/articles/perl5oo.html | ★★★★☆ |

### 英語チュートリアル

| リソース | URL | 信頼性 |
|----------|-----|--------|
| Perl Maven - OOP with Moo | https://perlmaven.com/oop-with-moo | ★★★★★ |
| Perl Maven - Moo attributes | https://perlmaven.com/moo-attributes-with-default-values | ★★★★☆ |
| Minimum Viable Perl - Roles | https://mvp.kablamo.org/oo/roles/ | ★★★★☆ |
| Object Oriented Perl（perl.org） | https://www.perl.org/about/whitepapers/perl-object-oriented.html | ★★★★★ |

### ブログ・解説記事

| リソース | URL | 信頼性 |
|----------|-----|--------|
| Revisiting Perl OOP in 2025 | https://islandinthenet.com/revisiting-perl-object-oriented-programming-oop-in-2025/ | ★★★☆☆ |

### GitHub

| リソース | URL | 信頼性 |
|----------|-----|--------|
| Moo GitHubリポジトリ | https://github.com/moose/Moo | ★★★★★ |

---

## 書籍情報

### 日本語書籍

| 書籍名 | 著者 | ASIN/ISBN | 備考 |
|--------|------|-----------|------|
| オブジェクト指向Perlマスターコース | ダミアン・コンウェイ | ASIN: 4894713004 / ISBN-13: 978-4894713000 | 定番のPerl OO解説書。bless中心だがOO基礎理解に最適 |
| すぐわかる オブジェクト指向 Perl | 深沢千尋 | ASIN: 4774135046 / ISBN-13: 978-4774135045 | 実践的なOO解説。サンプルコード豊富 |
| プログラミング言語Perlマスターコース | アンドリュー・L・ジョンソン | ASIN: 4894713012 / ISBN-13: 978-4894713017 | Perl全般とOO構文の入門書 |

### 英語書籍

| 書籍名 | 著者 | 備考 |
|--------|------|------|
| Modern Perl 4th Edition | chromatic | Mooseを活用した手法を含む |
| Object-Oriented Perl | Damian Conway | Perl OOの古典的名著（英語） |

**注意**: 2020年以降にMoo/Moose特化の書籍は出版されていません。最新情報はCPANドキュメントやWebリソースで学ぶのが現状の最適解です。

---

## 競合記事の分析

### 既存のMoo入門記事の特徴

1. **Perl Maven（英語）**
   - ステップバイステップで詳細な解説
   - 実行可能なコード例が豊富
   - 属性オプションごとに個別記事あり

2. **Perlゼミ（日本語）**
   - 初心者向けの丁寧な解説
   - blessからMoo/Mooseへの移行パスを説明
   - 日本語で読める貴重なリソース

3. **Minimum Viable Perl**
   - 実践的なコード例
   - ロールの使い方に詳しい
   - 最小限の説明で要点を押さえる

### カバーされている内容

- クラスの基本定義
- 属性（has）の使い方
- 継承（extends）
- ロール（with, Moo::Role）
- Mooseとの比較
- 型制約（Type::Tiny）

### 差別化ポイントの候補

1. **日本語での体系的な解説** - 英語リソースが多いため
2. **実践的なユースケース** - 実際のプロジェクトでの使用例
3. **移行ガイド** - blessからMooへ、MooからMooseへ
4. **パフォーマンス比較** - 起動時間・メモリ使用量の実測
5. **デバッグ・トラブルシューティング** - よくある問題と解決策

---

## 内部リンク調査

### 関連タグ

以下のタグで関連記事を検索可能:

- `perl`
- `oop`
- `object-oriented`
- `moo`
- `moose`

### 既存の関連記事

| タイトル | パス | タグ |
|----------|------|------|
| Moo/Moose - モダンなPerlオブジェクト指向プログラミング | content/post/2025/12/11/000000.md | perl, advent-calendar, moo, moose, oop, object-oriented |

この記事はMoo/Mooseについての包括的な解説記事であり、Moo入門記事との連携が期待できます。

---

## 次のステップ

1. **アウトライン作成**: SEO最適化を考慮したアウトラインの作成
2. **記事執筆**: 初心者にもわかりやすい、実践的なコード例を含む記事
3. **内部リンク設定**: 既存のMoo/Moose記事との相互リンク
4. **図表追加**: クラス図、継承図などのMermaid図を追加
5. **アイキャッチ画像**: 記事に適した画像の生成

---

## 調査メモ

- Mooは2010年にリリースされ、現在も活発にメンテナンスされている
- MooからMooseへの「昇格」は簡単で、Mooseをuseするだけで自動的にMooseクラスになる
- Type::TinyはMoo/Moose両方で使える軽量な型制約ライブラリ
- Role::TinyはMoo::Roleの基盤となるモジュール
- 2025年時点でもPerlのOOPにはMoo/Mooseが推奨されている
