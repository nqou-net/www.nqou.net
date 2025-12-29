# 調査ドキュメント: Mooで覚えるオブジェクト指向プログラミング シリーズ（全12回）

## 調査概要

- **調査目的**: Perl初心者向けのオブジェクト指向プログラミング入門シリーズ（全12回）の作成準備
- **実施日**: 2025-12-29
- **対象読者**: プログラムといえばスパゲティコードだと思っている初心者
- **目標**: オブジェクト指向プログラミングを感覚的に理解できるようになること

---

## 1. Perl/Mooに関する調査

### 1.1 Mooの最新バージョンと安定性

| 項目 | 内容 |
|------|------|
| 最新安定版 | 2.005005（2025年12月時点） |
| 対応Perl | Perl 5.40.0含む最新版まで対応 |
| 開発状況 | 積極的にメンテナンスされている |
| 特徴 | 軽量、XS不要、純Perl、高速起動 |

**信頼性評価**: ★★★★★（CPANで長期間メンテナンス、Mooseとの互換性確保）

**参考URL**:
- https://metacpan.org/pod/Moo - 公式ドキュメント
- https://github.com/moose/Moo - GitHubリポジトリ
- https://perlmaven.com/moo - Perl Maven チュートリアル

### 1.2 Mooの主要機能

#### 属性定義（has）

```perl
has 'name' => (
    is       => 'rw',      # rw: 読み書き可能, ro: 読み取り専用
    required => 1,         # 必須属性
    default  => sub { 'default_value' },  # デフォルト値
    lazy     => 1,         # 遅延評価
    builder  => '_build_name',  # ビルダーメソッド
    trigger  => sub { ... },    # 値変更時のトリガー
    coerce   => sub { ... },    # 型強制
);
```

#### 継承（extends）

```perl
package Cat;
use Moo;
extends 'Animal';  # Animalクラスを継承
```

#### ロール（with）

```perl
package Dog;
use Moo;
with 'Eats';       # Eatsロールを適用
with 'Barks';      # 複数ロール可能
```

#### メソッド修飾子（before, after, around）

```perl
before 'speak' => sub { print "Before speaking...\n"; };
after  'speak' => sub { print "After speaking.\n"; };
around 'speak' => sub {
    my ($orig, $self, @args) = @_;
    print "Around: before\n";
    my $result = $self->$orig(@args);
    print "Around: after\n";
    return $result;
};
```

#### コンストラクタ/デストラクタ（BUILD, DEMOLISH）

```perl
sub BUILD {
    my ($self, $args) = @_;
    # オブジェクト生成後の初期化処理
}

sub DEMOLISH {
    my ($self) = @_;
    # オブジェクト破棄時のクリーンアップ
}
```

#### 委譲（handles）

```perl
has logger => (
    is      => 'ro',
    handles => ['info', 'error'],  # loggerのメソッドを委譲
);
# $self->info(...) は $self->logger->info(...) と同等
```

**参考URL**:
- https://metacpan.org/pod/Moo - 公式ドキュメント
- https://perlmaven.com/inheritance-and-method-modifiers-in-moo - 継承とメソッド修飾子
- https://metacpan.org/pod/Moo::Role - ロールのドキュメント
- http://kablamo.org/slides-intro-to-moo/ - How to Moo（スライド）

### 1.3 Moo vs Moose vs Mouse 比較

| 機能 | Moose | Moo | Mouse |
|------|-------|-----|-------|
| 起動速度 | 遅い | 速い | 最速 |
| 依存モジュール | 多い | 少ない | 最少 |
| XS依存 | あり | なし | オプション |
| メタプログラミング（MOP） | あり | なし | なし |
| 継承・ロール | あり | あり | あり |
| 型システム | 充実 | 最小/拡張可 | 最小 |
| 属性バリデーション | あり | あり | あり |
| MooseX拡張 | 多数 | 一部互換 | なし |
| Mooseへの移行 | - | 容易 | 容易 |
| 推奨用途 | 大規模アプリ | 中小規模 | CLIツール |

**選択指針**:
- **Moose**: 高度な機能、メタプログラミング、拡張性が必要な大規模アプリ
- **Moo**: 高速起動、最小依存、将来的なMoose移行の可能性がある場合（**本シリーズで採用**）
- **Mouse**: 起動時間が最重要、CLIツール、ワンライナー

**信頼性評価**: ★★★★★（多くの比較記事・ドキュメントで一貫した評価）

**参考URL**:
- https://en.wikipedia.org/wiki/Moose_(Perl) - Moose Wikipedia
- https://metacpan.org/pod/Mouse - Mouse ドキュメント
- https://islandinthenet.com/revisiting-perl-object-oriented-programming-oop-in-2025/ - 2025年のPerl OOP

---

## 2. オブジェクト指向プログラミングの基礎概念

### 2.1 初心者が理解すべき概念の順序（推奨）

1. **オブジェクト指向の全体像**
   - 「モノ」としての捉え方
   - 手続き型との違い
   - メリット（拡張性、保守性、再利用性）

2. **クラスとオブジェクト（インスタンス）**
   - クラス = 設計図
   - オブジェクト = 実体
   - プロパティ = 属性（データ）
   - メソッド = 機能（処理）

3. **カプセル化**
   - データと処理を一まとまりに
   - 外部からの不正アクセス防止
   - アクセサ（getter/setter）

4. **継承**
   - 既存クラスの機能を引き継ぐ
   - 「is-a」関係
   - コードの再利用

5. **ポリモーフィズム（多態性）**
   - 同じメソッド名で異なる動作
   - インターフェースの統一
   - 柔軟な処理の実現

6. **委譲とロール（Moo特有）**
   - 「has-a」関係
   - 継承の代替手段
   - 横断的な機能の共有

### 2.2 「なぜオブジェクト指向が必要か」の説明アプローチ

#### スパゲティコードの問題点

- 何をしているか分からないコードが増える
- 変更箇所が複数に分散し、「どこを直せばいいか分からない」
- バグが発生しやすく、修正に時間がかかる
- 新しい機能追加が困難
- 複数人での開発が困難

#### オブジェクト指向のメリット

1. **管理や修正がしやすい**
   - 役割ごとにコードが整理される
   - 一部修正で全体に反映

2. **再利用性が高い**
   - 継承や組み合わせで機能追加
   - コピペの削減

3. **大規模開発に強い**
   - 分担しやすい設計
   - テスト・バグ修正が容易

4. **現実世界に近い設計**
   - 直感的なモデリング

**参考URL**:
- https://engineer-job.com/2025/06/04/初心者でもわかる！オブジェクト指向の基本と用語を図解で解説/
- https://saiseich.com/infra_program/whats_object_program/
- https://programmer-beginner-blog.com/object/
- https://techgym.jp/column/object-orient/

---

## 3. 掲示板（BBS）実装に関する調査

### 3.1 シンプルなチャット機能の要件

#### 最小構成（MVP）

- メッセージの投稿
- メッセージの表示（時系列）
- 投稿者名の表示

#### 拡張要件

- スレッド機能（話題ごとの分類）
- ユーザー認証
- 返信機能
- 編集・削除機能
- いいね・リアクション

### 3.2 掲示板に必要な基本オブジェクト

#### Message（投稿）クラス

```perl
package BBS::Message;
use Moo;

has id        => (is => 'ro');
has content   => (is => 'rw', required => 1);
has author    => (is => 'ro', required => 1);
has timestamp => (is => 'ro', default => sub { time });
```

#### Thread（スレッド）クラス

```perl
package BBS::Thread;
use Moo;

has id       => (is => 'ro');
has title    => (is => 'rw', required => 1);
has messages => (is => 'ro', default => sub { [] });

sub add_message {
    my ($self, $message) = @_;
    push @{$self->messages}, $message;
}
```

#### User（ユーザー）クラス

```perl
package BBS::User;
use Moo;
use Crypt::Argon2 qw(argon2id_verify);

has id            => (is => 'ro');
has name          => (is => 'rw', required => 1);
has email         => (is => 'rw');
has password_hash => (is => 'ro');  # ハッシュ化されたパスワードを保存

sub authenticate {
    my ($self, $input_password) = @_;
    # Argon2によるセキュアなパスワード検証
    return argon2id_verify($self->password_hash, $input_password);
}
# 注意: 実際のアプリケーションでは、パスワードは必ずハッシュ化して保存してください
# パスワードのハッシュ化例: argon2id_pass($password, $salt, ...)
```

#### Board（掲示板）クラス

```perl
package BBS::Board;
use Moo;

has name    => (is => 'rw', required => 1);
has threads => (is => 'ro', default => sub { [] });

sub create_thread {
    my ($self, $title) = @_;
    my $thread = BBS::Thread->new(title => $title);
    push @{$self->threads}, $thread;
    return $thread;
}
```

### 3.3 スパゲティコードからオブジェクト指向への変換パターン

#### Before（スパゲティコード例）

```perl
# グローバル変数で管理
my @messages;
my %users;

sub post_message {
    my ($user_name, $content) = @_;
    my $timestamp = time;
    push @messages, {
        user => $user_name,
        content => $content,
        time => $timestamp,
    };
    # ユーザー存在チェック
    if (!exists $users{$user_name}) {
        $users{$user_name} = { name => $user_name, post_count => 0 };
    }
    $users{$user_name}->{post_count}++;
    # 表示処理も混在
    print "Posted: $content\n";
}

sub show_messages {
    for my $msg (@messages) {
        print "[$msg->{time}] $msg->{user}: $msg->{content}\n";
    }
}
```

**問題点**:
- グローバル変数への依存
- 複数の責任が混在（投稿、ユーザー管理、表示）
- テストが困難
- 拡張が困難

#### After（オブジェクト指向）

```perl
# クラスで責任分離
my $board = BBS::Board->new(name => 'My BBS');
my $user  = BBS::User->new(name => 'nqounet');
my $thread = $board->create_thread(title => '雑談スレッド');

my $message = BBS::Message->new(
    content => 'Hello, World!',
    author  => $user,
);
$thread->add_message($message);

# 表示は別の責任として分離
for my $msg (@{$thread->messages}) {
    printf "[%s] %s: %s\n",
        $msg->timestamp,
        $msg->author->name,
        $msg->content;
}
```

**改善点**:
- 各クラスが単一の責任を持つ
- テストが容易
- 機能拡張が容易
- 再利用可能

### 3.4 属性を増やして多機能化する拡張パターン

#### 段階的な属性追加

**Step 1**: 基本属性のみ
```perl
has content => (is => 'rw');
```

**Step 2**: バリデーション追加
```perl
has content => (
    is  => 'rw',
    isa => sub { die "Empty!" unless length $_[0] },
);
```

**Step 3**: 関連オブジェクト追加
```perl
has replies => (
    is      => 'ro',
    default => sub { [] },
);
```

**Step 4**: 派生属性（lazy）
```perl
has reply_count => (
    is      => 'ro',
    lazy    => 1,
    builder => sub { scalar @{shift->replies} },
);
```

---

## 4. 教育的アプローチ

### 4.1 初心者向けの段階的な概念導入の順序

#### 第1回〜第4回: 基礎固め

1. **導入・用語理解**（第1回 - 公開済み）
   - blessは忘れる
   - Mooを使ってみる
   - 用語を覚える

2. **コードの解説**（第2回）
   - 第1回のコード詳細解説
   - package, use Moo, has, sub の意味
   - オブジェクトの生成と使用

3. **プロパティを深堀り**（第3回）
   - is => 'rw' vs 'ro'
   - required, default
   - なぜプロパティが必要か

4. **メソッドを深堀り**（第4回）
   - $self の意味
   - 引数の受け取り方
   - 戻り値

#### 第5回〜第8回: 実践的な機能

5. **チャットアプリを作ろう**（第5回）
   - Messageクラスの設計
   - スパゲティコードとの比較
   - 責任の分離

6. **継承を学ぶ**（第6回）
   - extends の使い方
   - 親クラスの機能を引き継ぐ
   - オーバーライド

7. **ロールを学ぶ**（第7回）
   - with の使い方
   - 継承との違い
   - 横断的な機能の共有

8. **委譲を学ぶ**（第8回）
   - handles の使い方
   - 「has-a」関係
   - 継承 vs 委譲

#### 第9回〜第12回: 応用と発展

9. **掲示板に機能を追加しよう**（第9回）
   - Thread, User クラスの追加
   - クラス間の関係性

10. **メソッド修飾子**（第10回）
    - before, after, around
    - ログ出力やバリデーション

11. **BUILD と DEMOLISH**（第11回）
    - 初期化処理
    - 後片付け処理

12. **まとめと次のステップ**（第12回）
    - シリーズの振り返り
    - より高度なトピック紹介
    - Moose, 新しいclass構文

### 4.2 コード例の適切な複雑さレベル

#### 原則

- **1概念につき1サンプル**: 複数の新概念を同時に導入しない
- **動くコード**: 必ず実行可能なコードを提供
- **段階的な複雑化**: 前回のコードを拡張する形で進める
- **現実的な例**: 抽象的な例（Animal, Dog）より掲示板の例を優先

#### 複雑さの目安

- 第1回〜第4回: 10〜20行程度
- 第5回〜第8回: 20〜40行程度
- 第9回〜第12回: 40〜60行程度（複数ファイルに分割も可）

### 4.3 「あー、こういうことだったのか」と理解できる瞬間の作り方

#### パターン1: Before/After比較

```
【Before】グローバル変数を使った実装
    ↓ 問題点を提示
【After】オブジェクト指向での実装
    ↓ どう改善されたかを説明
```

#### パターン2: 機能追加の体験

```
【現状】投稿機能だけのチャット
    ↓ 「返信機能を追加したい」
【スパゲティ】既存コードを大幅修正が必要
【OOP】新しいクラス/メソッドを追加するだけ
```

#### パターン3: リアルな失敗体験

```
【やりたいこと】ユーザー名を変更したい
【スパゲティ】全箇所を検索・置換
【OOP】Userオブジェクトのnameを変更するだけ
```

---

## 5. 全12回シリーズ構成案

### 構成案A: 概念優先アプローチ

| 回 | タイトル | 主要トピック |
|----|----------|--------------|
| 1 | blessは忘れよう | Moo導入、用語 |
| 2 | コードを読み解こう | package, has, sub |
| 3 | プロパティを理解しよう | is, required, default |
| 4 | メソッドを理解しよう | $self, 引数, 戻り値 |
| 5 | カプセル化とは | アクセス制御, 責任分離 |
| 6 | 継承とは | extends, オーバーライド |
| 7 | ロールとは | with, Moo::Role |
| 8 | 委譲とは | handles, has-a |
| 9 | ポリモーフィズムとは | 多態性の実装 |
| 10 | メソッド修飾子 | before, after, around |
| 11 | オブジェクトのライフサイクル | BUILD, DEMOLISH |
| 12 | まとめと次のステップ | 振り返り, 発展 |

### 構成案B: 実装優先アプローチ（推奨）

| 回 | タイトル | 主要トピック |
|----|----------|--------------|
| 1 | blessは忘れよう | Moo導入、用語（公開済み） |
| 2 | 最初のコードを理解しよう | package, has, sub 解説 |
| 3 | チャットを作ろう（前編） | Messageクラス設計 |
| 4 | チャットを作ろう（後編） | メソッド追加, 動作確認 |
| 5 | スパゲティコードとの比較 | Before/After, 問題点 |
| 6 | ユーザー機能を追加しよう | Userクラス, 継承 |
| 7 | スレッド機能を追加しよう | Threadクラス, 集約 |
| 8 | 共通機能をロールにしよう | Moo::Role, with |
| 9 | 委譲で責任を分離しよう | handles |
| 10 | 処理を拡張しよう | before, after, around |
| 11 | 初期化と後始末 | BUILD, DEMOLISH |
| 12 | 多機能掲示板の完成 | 総合演習, 振り返り |

### 構成案C: 問題解決アプローチ

| 回 | タイトル | 主要トピック |
|----|----------|--------------|
| 1 | blessは忘れよう | Moo導入（公開済み） |
| 2 | なぜスパゲティになるのか | 問題提起, Before例 |
| 3 | 最初のオブジェクト | Messageクラス |
| 4 | データを守る | プロパティ, is |
| 5 | 機能を追加したい | メソッド, $self |
| 6 | 同じコードを書きたくない | 継承, extends |
| 7 | 横断的な機能を追加したい | ロール, with |
| 8 | 別のオブジェクトに任せたい | 委譲, handles |
| 9 | 処理の前後に何かしたい | 修飾子 |
| 10 | 生成時に何かしたい | BUILD |
| 11 | 掲示板を完成させよう | 総合演習 |
| 12 | 次のステップへ | Moose, 新class構文 |

---

## 6. 参考文献・リソース

### 公式ドキュメント

| リソース | URL | 信頼性 |
|----------|-----|--------|
| Moo (MetaCPAN) | https://metacpan.org/pod/Moo | ★★★★★ |
| Moo::Role | https://metacpan.org/pod/Moo::Role | ★★★★★ |
| Role::Tiny | https://metacpan.org/pod/Role::Tiny | ★★★★★ |
| perlootut | https://perldoc.perl.org/perlootut | ★★★★★ |
| perlobj | https://perldoc.jp/pod/perlobj | ★★★★★ |

### チュートリアル・記事

| リソース | URL | 信頼性 |
|----------|-----|--------|
| Perl Maven - Moo | https://perlmaven.com/moo | ★★★★☆ |
| How to Moo (Kablamo) | http://kablamo.org/slides-intro-to-moo/ | ★★★★☆ |
| Perl Beginners' Site | https://perl-begin.org/topics/object-oriented/ | ★★★★☆ |
| Perlゼミ OOP入門 | https://perlzemi.com/blog/20221004090015.html | ★★★★☆ |
| Revisiting Perl OOP 2025 | https://islandinthenet.com/revisiting-perl-object-oriented-programming-oop-in-2025/ | ★★★☆☆ |

### 関連する既存記事（同サイト内）

- **第1回記事（公開済み）**: 2021/10/31 - blessは忘れる、Moo導入、用語
  - タグ: perl, programming
  - URL: https://www.nqou.net/2021/10/31/191008/

### 書籍

| 書籍名 | ASIN/ISBN | 備考 |
|--------|-----------|------|
| 初めてのPerl 第8版 | B0D1JPHYPS | 基礎から学べる定番書 |
| Perl Hacks | 0596526741 | 実践的なテクニック集 |
| Modern Perl | 0985632151 | モダンなPerl開発 |

---

## 7. 次のステップ

1. **構成案の選択**: 構成案B（実装優先アプローチ）を推奨
2. **第2回のアウトライン作成**: 第1回のコード解説
3. **サンプルコードの準備**: 各回で使用するコード例
4. **図表の設計**: クラス図、シーケンス図（Mermaid記法）
5. **内部リンクの準備**: 関連記事へのリンク（タグ: perl, programming）

---

## 付記

- 本調査は2025年12月29日時点の情報に基づいています
- Perl 5.38以降の新しいclass構文は実験的機能のため、本シリーズでは扱わず、最終回で紹介程度に留める
- 各回の記事作成時は、最新のMooドキュメントを確認することを推奨
