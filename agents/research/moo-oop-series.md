# Mooで覚えるオブジェクト指向プログラミング連載（全12回） 調査ドキュメント

## 概要

Perl/Mooを使ったオブジェクト指向プログラミング連載（全12回）のための調査・情報収集結果をまとめたドキュメントです。

- **調査日**: 2024-12-29
- **調査者**: GitHub Copilot (investigative-research agent)
- **目的**: 初心者向けMoo/OOP連載記事の構成と内容を決定するための情報収集

---

## 1. Perl/Moo関連の調査

### 1.1 Mooの基本情報

#### 公式ドキュメント

| 情報源 | URL | 信頼性 |
|--------|-----|--------|
| Moo (MetaCPAN) | https://metacpan.org/pod/Moo | ★★★★★ (公式) |
| Moo (Mojolicious Docs) | https://docs.mojolicious.org/Moo | ★★★★★ (公式ミラー) |
| Perl Maven: Moo | https://perlmaven.com/moo | ★★★★☆ (良質なチュートリアル) |
| Minimum Viable Perl | https://mvp.kablamo.org/oo/ | ★★★★☆ (実践的ガイド) |
| How to Moo (Kablamo) | http://kablamo.org/slides-intro-to-moo/ | ★★★★☆ (スライド形式) |

#### Mooの主な特徴

- **軽量**: Mooseの約1/3のコード量、起動が高速
- **Pure Perl**: XSモジュール不要で移植性が高い
- **Moose互換**: 必要に応じてMooseにアップグレード可能
- **最小限の依存**: 依存モジュールが少ない

#### Mooの基本構文

```perl
package MyApp;
use Moo;

# 属性の定義
has name => (is => 'rw');
has age  => (is => 'ro', required => 1);

# メソッドの定義
sub greet {
    my $self = shift;
    return "Hello, " . $self->name;
}

1;
```

### 1.2 hasの属性オプション

| オプション | 説明 | 使用例 |
|-----------|------|--------|
| `is` | アクセサの種類（ro/rw/rwp/lazy） | `is => 'rw'` |
| `isa` | 型制約（コードリファレンス） | `isa => sub { die unless $_[0] > 0 }` |
| `required` | 必須属性 | `required => 1` |
| `default` | デフォルト値 | `default => 'unknown'` または `default => sub { [] }` |
| `builder` | ビルダーメソッド名 | `builder => '_build_name'` |
| `lazy` | 遅延評価 | `lazy => 1` |
| `trigger` | 値変更時のコールバック | `trigger => sub { print "changed!\n" }` |
| `coerce` | 型変換 | `coerce => sub { uc $_[0] }` |
| `handles` | 委譲 | `handles => [qw(start stop)]` |

#### 参考URL
- https://metacpan.org/pod/Moo
- https://perlmaven.com/moo-and-required-attributes
- https://mvp.kablamo.org/oo/attributes/

### 1.3 継承（extends）

```perl
package Employee;
use Moo;
extends 'Person';

has employee_id => (is => 'rw', required => 1);

sub print {
    my $self = shift;
    print "Employee: " . $self->employee_id . "\n";
    $self->SUPER::print;  # 親クラスのメソッド呼び出し
}
```

#### 参考URL
- https://perlmaven.com/inheritance-and-method-modifiers-in-moo

### 1.4 Role（Moo::Role）

Roleはインターフェースやトレイトに似た概念で、「継承」ではなく「合成」によってコードを再利用する仕組みです。

```perl
# Role定義
package Shape;
use Moo::Role;

requires 'draw';  # 実装を要求

sub description {
    my $self = shift;
    return "I am a shape";
}

# Roleを使うクラス
package Circle;
use Moo;
with 'Shape';

sub draw {
    print "Drawing a circle\n";
}
```

#### 参考URL
- https://metacpan.org/pod/Moo::Role
- https://mvp.kablamo.org/oo/roles/
- https://theweeklychallenge.org/blog/design-pattern-factory/

### 1.5 委譲（handles）

```perl
package Car;
use Moo;

has engine => (
    is      => 'ro',
    default => sub { Engine->new(horsepower => 200) },
    handles => [qw(start horsepower)]
);

# $car->start は $car->engine->start を呼び出す
```

#### 参考URL
- https://stackoverflow.com/questions/43328512/attribute-delegation-in-perl-moose-or-moo
- https://manpages.debian.org/testing/libmoose-perl/Moose::Manual::Delegation.3pm

### 1.6 メソッドモディファイア（around, before, after）

```perl
package Brontosaurus;
use Moo;
extends 'Dinosaur';

# 前処理
before eat => sub {
    my ($self, $food) = @_;
    die "bad params" if $food eq 'meat';
};

# 後処理
after eat => sub {
    my ($self, $food) = @_;
    $self->log->warning("ate $food");
};

# ラッパー
around eat => sub {
    my ($orig, $self, $food) = @_;
    uc $orig->($self, $food);  # 結果を大文字に
};
```

#### 参考URL
- https://perlmaven.com/inheritance-and-method-modifiers-in-moo
- https://mvp.kablamo.org/oo/modifiers/

### 1.7 コンストラクタ（BUILDARGS, BUILD）

```perl
package Person;
use Moo;

has name => (is => 'ro');
has age  => (is => 'ro');

# 引数の前処理
sub BUILDARGS {
    my ($class, @args) = @_;
    if (@args == 2) {
        return { name => $args[0], age => $args[1] };
    }
    return $class->SUPER::BUILDARGS(@args);
}

# オブジェクト構築後の処理
sub BUILD {
    my ($self) = @_;
    die "Age must be positive" if $self->age && $self->age < 0;
}

# 使用例
my $person1 = Person->new(name => "Alice", age => 20);
my $person2 = Person->new("Bob", 18);  # 位置引数もOK
```

#### 参考URL
- https://manpages.debian.org/bullseye/libmoose-perl/Moose::Cookbook::Basics::Person_BUILDARGSAndBUILD.3pm.en.html

### 1.8 MooとMooseの違い

| 特徴 | Moo | Moose |
|------|-----|-------|
| 起動速度 | 高速 | 遅い（初期化が重い） |
| 依存 | Pure Perl、最小限 | XS、多数の依存 |
| メタオブジェクト | なし（Moose読込時のみ） | あり |
| 型システム | 最小限（カスタム） | 高度 |
| MooseX拡張 | 使用不可 | 使用可 |
| 相互運用 | Mooseにアップグレード可 | Mooと連携可 |
| 用途 | スクリプト、軽量プロジェクト | 大規模アプリ、フレームワーク |

#### 参考URL
- https://metacpan.org/pod/Moo
- https://en.wikipedia.org/wiki/Moose_(Perl)

---

## 2. オブジェクト指向の概念

### 2.1 クラスとオブジェクト

- **クラス**: オブジェクトの「設計図」。属性と振る舞いを定義
- **オブジェクト（インスタンス）**: クラスから生成された実体

#### 参考URL
- https://www.designgurus.io/blog/object-oriented-programming-oop
- https://perldoc.perl.org/perlootut

### 2.2 属性（プロパティ）とメソッド

- **属性**: オブジェクトが持つデータ（状態）
- **メソッド**: オブジェクトが持つ機能（振る舞い）

### 2.3 カプセル化

データを隠蔽し、アクセサメソッドを通じてのみアクセスさせる仕組み。

- **ro（読み取り専用）**: ゲッターのみ
- **rw（読み書き可能）**: ゲッターとセッター両方

```perl
has secret => (is => 'ro');  # 読み取り専用
has name   => (is => 'rw');  # 読み書き可能
```

#### 参考URL
- https://stackify.com/oop-concept-for-beginners-what-is-encapsulation/
- https://www.coursera.org/in/articles/encapsulation-in-oop

### 2.4 継承

親クラスの属性やメソッドを子クラスが引き継ぐ仕組み。コードの再利用に役立つ。

```perl
package Employee;
use Moo;
extends 'Person';  # Personを継承
```

### 2.5 委譲

あるオブジェクトのメソッド呼び出しを、別のオブジェクトに転送する仕組み。継承よりも柔軟。

```perl
has engine => (
    is      => 'ro',
    handles => [qw(start stop)],
);
```

### 2.6 多態性（ポリモーフィズム）

異なるクラスのオブジェクトを、共通のインターフェースで扱える性質。

```perl
# 異なるクラスでも同じメソッド名で異なる動作
$circle->draw;     # "Drawing a circle"
$rectangle->draw;  # "Drawing a rectangle"
```

#### 参考URL
- https://www.programiz.com/java-programming/polymorphism
- https://www.geeksforgeeks.org/java/interfaces-and-polymorphism-in-java/

### 2.7 Role（合成）

継承の代わりに「合成」でコードを再利用する仕組み。多重継承の問題を回避できる。

#### 参考URL
- https://mvp.kablamo.org/oo/roles/

---

## 3. 掲示板（BBS）の設計

### 3.1 最小限のチャット機能

```perl
package Message;
use Moo;

has author => (is => 'ro', required => 1);
has body   => (is => 'ro', required => 1);
```

### 3.2 掲示板に必要な属性

```perl
package Post;
use Moo;

has id        => (is => 'ro', required => 1);
has title     => (is => 'rw', required => 1);
has body      => (is => 'rw', required => 1);
has author    => (is => 'ro', required => 1);
has posted_at => (is => 'ro', builder => '_build_posted_at');
has replies   => (is => 'rw', default => sub { [] });

sub _build_posted_at {
    return time();
}
```

### 3.3 スレッド/レス構造

```perl
package Thread;
use Moo;

has id       => (is => 'ro', required => 1);
has title    => (is => 'rw', required => 1);
has posts    => (is => 'rw', default => sub { [] });
has author   => (is => 'ro', required => 1);

sub add_post {
    my ($self, $post) = @_;
    push @{$self->posts}, $post;
}
```

### 3.4 ユーザー管理

```perl
package User;
use Moo;

has id       => (is => 'ro', required => 1);
has name     => (is => 'rw', required => 1);
has email    => (is => 'rw');
has password => (is => 'ro', required => 1);
```

#### 参考URL
- https://www.linuxjournal.com/article/3193
- https://www.linuxjournal.com/article/3252

---

## 4. スパゲティコードからOOPへの変遷

### 4.1 手続き型プログラミングの問題点

- グローバル変数への依存
- コードの重複
- 関数の責任が不明確
- テストが困難
- 変更に弱い（1箇所の変更が他に影響）

### 4.2 なぜOOPが必要なのか

- **保守性**: コードをモジュール化し、変更の影響を局所化
- **再利用性**: 継承やRoleでコードを再利用
- **テスト容易性**: カプセル化により単体テストが容易に
- **可読性**: オブジェクト単位でコードを整理

### 4.3 リファクタリングのステップ

1. **エンティティの特定**: プログラムが扱う「もの」を見つける
2. **クラスの定義**: エンティティごとにクラスを作成
3. **属性の抽出**: 関連するデータを属性として定義
4. **メソッドの移動**: 関連する処理をメソッドとして移動
5. **関係性の構築**: 継承・合成・委譲を適用
6. **テスト**: リファクタリング後の動作確認

#### 参考URL
- https://bugfree.ai/knowledge-hub/refactor-procedural-design-into-oop
- https://refraction.dev/blog/refactoring-object-oriented-programming-techniques

---

## 5. 初心者向け教育コンテンツの書き方

### 5.1 段階的な概念導入の順序

1. **クラスとオブジェクト**: 基本概念
2. **属性とメソッド**: データと振る舞い
3. **カプセル化**: アクセス制御（ro/rw）
4. **継承**: コードの再利用
5. **多態性**: 共通インターフェース
6. **Role/合成**: 柔軟な再利用

### 5.2 実践的なコード例の重要性

- 各概念につき1つのコード例
- 動かして確認できるコード
- 段階的に複雑さを増す

#### 参考URL
- https://www.geeksforgeeks.org/blogs/best-practices-of-object-oriented-programming-oop/
- https://blog.skillitall.com/computer-programming-intermediate/best-practices-for-object-oriented-programming/

---

## 6. 連載構成の推奨

### 制約の確認

- 毎回コード例は2つまで
- 新しい概念は1記事あたり1つまで
- トーン: 初心者向けで優しい語り口
- テーマ: 掲示板（BBS）をスパゲティコード→OOPで再設計

### 推奨する12回の構成

| 回 | タイトル案 | 新しい概念 | 掲示板の進捗 |
|----|-----------|-----------|-------------|
| 1 | blessを忘れてMooを使う（公開済） | Mooの基本、package/has/sub | 導入 |
| 2 | コードを読み解く | オブジェクト、クラス、プロパティ、メソッドの詳細 | なし |
| 3 | 掲示板を作ろう（スパゲティ版） | 手続き型の問題点の紹介 | 最小チャット（手続き型） |
| 4 | メッセージをオブジェクトにする | クラスとオブジェクト | Messageクラス作成 |
| 5 | 読み取り専用と読み書き | カプセル化（ro/rw） | 属性のアクセス制御 |
| 6 | 必須項目とデフォルト値 | required, default, builder | 投稿日時の自動設定 |
| 7 | 掲示板に機能を追加する | メソッドの作成 | 投稿一覧表示 |
| 8 | スレッドを管理する | 継承（extends） | Threadクラス作成 |
| 9 | ユーザーを追加する | 委譲（handles） | Userクラスと委譲 |
| 10 | 共通機能をRoleにまとめる | Role（Moo::Role） | Timestampable Role |
| 11 | 管理者と一般ユーザー | 多態性 | AdminUser継承 |
| 12 | まとめと発展 | 総復習、次のステップ | 完成形の掲示板 |

### 各回の詳細

#### 第2回: コードを読み解く
- 第1回のコードを1行ずつ解説
- `package`の意味
- `has`の詳細
- `sub`とメソッドの関係
- `$self`の役割

#### 第3回: 掲示板を作ろう（スパゲティ版）
- 変数だけで作る最小チャット
- グローバル変数の問題点
- コードの重複
- なぜOOPが必要か

#### 第4回: メッセージをオブジェクトにする
- Messageクラスの作成
- new()でインスタンス生成
- アクセサでデータ取得

#### 第5回: 読み取り専用と読み書き
- `is => 'ro'`と`is => 'rw'`
- なぜ読み取り専用が必要か
- データの保護

#### 第6回: 必須項目とデフォルト値
- `required => 1`
- `default`
- `builder`メソッド
- 投稿日時の自動設定

#### 第7回: 掲示板に機能を追加する
- メソッドの追加
- 投稿一覧を表示するメソッド
- 投稿数を返すメソッド

#### 第8回: スレッドを管理する
- `extends`で継承
- Threadクラス
- 親クラスのメソッド呼び出し

#### 第9回: ユーザーを追加する
- Userクラス
- `handles`で委譲
- オブジェクトの関連付け

#### 第10回: 共通機能をRoleにまとめる
- Moo::Role
- `with`でRoleを適用
- Timestampable Roleの例

#### 第11回: 管理者と一般ユーザー
- AdminUserクラス
- 多態性の実演
- 同じメソッド名で異なる動作

#### 第12回: まとめと発展
- 12回の総復習
- BBSの完成形
- 次のステップ（Moose、テスト、Webフレームワーク）

---

## 7. 参考リンク一覧

### 公式ドキュメント

- Moo (MetaCPAN): https://metacpan.org/pod/Moo
- Moo::Role (MetaCPAN): https://metacpan.org/pod/Moo::Role
- perlootut: https://perldoc.perl.org/perlootut
- Moose Manual: https://metacpan.org/pod/Moose::Manual

### チュートリアル

- Perl Maven Moo: https://perlmaven.com/moo
- Minimum Viable Perl: https://mvp.kablamo.org/oo/
- How to Moo (Kablamo): http://kablamo.org/slides-intro-to-moo/
- Perl Beginners' Site OOP: https://perl-begin.org/topics/object-oriented/

### OOP一般

- GeeksforGeeks OOP Best Practices: https://www.geeksforgeeks.org/blogs/best-practices-of-object-oriented-programming-oop/
- Design Gurus OOP: https://www.designgurus.io/blog/object-oriented-programming-oop
- Encapsulation Guide: https://stackify.com/oop-concept-for-beginners-what-is-encapsulation/

### 掲示板設計

- Linux Journal BBS Part 1: https://www.linuxjournal.com/article/3193
- Linux Journal BBS Part 2: https://www.linuxjournal.com/article/3252

### デザインパターン

- Design Patterns in Modern Perl: https://github.com/manwar/design-patterns
- Factory Pattern (Weekly Challenge): https://theweeklychallenge.org/blog/design-pattern-factory/

---

## 8. 内部リンク候補（関連記事）

以下のタグで関連記事を検索することを推奨します：

- `perl`
- `programming`
- `object-oriented`（新規タグとして追加を推奨）
- `moo`（新規タグとして追加を推奨）

---

## 9. 次のアクション

1. **アウトライン作成**: 各回の詳細なアウトラインをsearch-engine-optimizationエージェントに依頼
2. **コード例の準備**: 各回で使用するコード例を事前に作成・テスト
3. **記事執筆**: perl-mongerエージェントに各回の記事作成を依頼
4. **SEO最適化**: タイトル・メタディスクリプションの最適化

---

## 更新履歴

- 2024-12-29: 初版作成（GitHub Copilot investigative-research agent）
