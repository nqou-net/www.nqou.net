---
date: 2026-01-25T00:00:36+09:00
draft: false
epoch: 1769266836
image: /favicon.png
iso8601: 2026-01-25T00:00:36+09:00
title: 2パターン組み合わせデザインパターンシリーズ調査
---

# 2パターン組み合わせデザインパターンシリーズ調査

## 調査概要

**調査実施日**: 2026年1月24日  
**調査目的**: 「Perlで学ぶデザインパターンシリーズ」の新連載として、2つのGoFデザインパターンを組み合わせた実践的な記事企画のための包括的調査  
**想定読者**: Perl入学式卒業レベル、Moo による OOP 入門連載を修了した初学者

---

## 1. 既存シリーズで使用済みのパターン・テーマ

### 複数パターン組み合わせシリーズ（既存）

1. **RPG戦闘エンジン**: State + Command + Strategy + Observer（4パターン）
2. **検討中の案**（未完成）:
   - Decorator + Chain of Responsibility（テキスト処理パイプライン）
   - Command + Memento（Undo/Redo履歴システム）
   - Builder + Strategy（占い診断ジェネレーター）

### 避けるべき題材（単一パターンシリーズで使用済み）

- ダンジョン生成（Bridge）
- シューティング（Flyweight）
- モンスター量産（Prototype）
- ローグライク通知（Observer）
- ログ解析（Decorator）
- Webスクレイパー（Template Method）
- テキストエディタ（Command）
- SQLクエリビルダー（Builder）
- 自動販売機（State）
- データエクスポーター（Strategy）
- ゴーストギャラリー（Proxy）

---

## 2. 新しい組み合わせ候補（3～4案）

### 🎯 候補1: **Facade + Adapter**（レガシーAPI統合システム）

#### パターンの組み合わせ理由

- **Facade**: 複雑なサブシステムを統一された簡素なインターフェースで提供
- **Adapter**: 互換性のないインターフェースを期待する形式に変換
- **相乗効果**: 複数の外部API・レガシーシステムを統一インターフェースで扱いながら、各APIの違いを吸収

#### 題材案: 「天気予報APIアグリゲーター」

**概要**:
- 複数の天気予報API（OpenWeatherMap、WeatherStack、気象庁など）を統一的に扱うシステム
- 各APIの仕様の違いをAdapterで吸収し、Facadeでシンプルなインターフェースを提供

**実装ステップ**:
1. **第1回**: Adapterパターンで単一APIをラップ（OpenWeatherMap → 統一形式）
2. **第2回**: 複数のAdapterを作成（WeatherStack、気象庁API）
3. **第3回**: Facadeで統一インターフェースを提供
4. **第4回**: キャッシング、フォールバック、エラーハンドリングの追加

**完成品の価値**:
- 実務で即戦力（APIラッパー作成は実際の開発で頻出）
- 友人に自慢できる: 「天気予報を複数のAPIから取得できるツールを作った」
- 拡張性が高い（新しいAPIを追加しやすい）

**技術的な実装可能性**:
```perl
# Adapterの実装例
package WeatherAdapter::OpenWeatherMap;
use Moo;
use HTTP::Tiny;
use JSON::PP;

has 'api_key' => (is => 'ro', required => 1);
has 'http'    => (is => 'ro', default => sub { HTTP::Tiny->new });

sub get_weather ($self, $city) {
    my $url = "https://api.openweathermap.org/data/2.5/weather?q=$city&appid=" . $self->api_key;
    my $response = $self->http->get($url);
    my $data = decode_json($response->{content});
    
    # 統一形式に変換
    return {
        temperature => $data->{main}{temp} - 273.15,  # Kelvin to Celsius
        description => $data->{weather}[0]{description},
        humidity    => $data->{main}{humidity},
        provider    => 'OpenWeatherMap',
    };
}

# Facadeの実装例
package WeatherFacade;
use Moo;

has 'adapters' => (is => 'ro', default => sub { [] });

sub add_adapter ($self, $adapter) {
    push @{$self->adapters}, $adapter;
    return $self;
}

sub get_weather ($self, $city) {
    for my $adapter (@{$self->adapters}) {
        eval {
            return $adapter->get_weather($city);
        };
        warn "Failed with " . ref($adapter) . ": $@" if $@;
    }
    die "All weather services failed";
}
```

**USP（独自の価値提案）**:
- **実務直結**: レガシー統合は実際の開発で避けて通れない課題
- **ベストプラクティス**: マイクロサービスアーキテクチャの基本パターン
- **Perl特有の強み**: CPAN モジュールの統合に応用可能

**根拠**:
- Web検索: https://codesignal.com/learn/courses/backward-compatibility-in-software-development-1/
- Stack Overflow での採用事例多数
- 大規模プロジェクトで実証済み

**信頼度**: 10/10（実務での採用事例が豊富）

---

### 🎯 候補2: **Flyweight + Composite**（メモリ効率的なMarkdownパーサー）

#### パターンの組み合わせ理由

- **Composite**: ツリー構造でドキュメントの階層を表現（Document → Section → Paragraph → Inline要素）
- **Flyweight**: 重複する要素（Bold、Link、Codeなど）をメモリ効率的に共有
- **相乗効果**: 大規模なドキュメント構造を階層的に扱いながら、メモリ使用量を劇的に削減

#### 題材案: 「超軽量Markdownパーサー＆レンダラー」

**概要**:
- Markdownファイルを解析し、HTML/プレーンテキストに変換
- 同一のスタイル要素（太字、リンク、コードブロック）をFlyweightで共有
- ドキュメント構造をCompositeで階層的に管理

**実装ステップ**:
1. **第1回**: Compositeでドキュメント構造を構築（Document、Paragraph、Text）
2. **第2回**: Flyweightで繰り返し要素を最適化（Bold、Italic、Link）
3. **第3回**: パーサーの実装（Markdown → AST）
4. **第4回**: レンダラーの実装（AST → HTML/Text）

**完成品の価値**:
- 「大規模Markdownファイルでもメモリ消費が少ない」とベンチマーク結果を示せる
- 技術ブログのネタとして最適（Before/After比較）
- CPANモジュールとして公開可能

**技術的な実装可能性**:
```perl
# Flyweight Factoryの実装例
package MarkdownElementFactory;
use Moo;

has 'elements' => (is => 'ro', default => sub { {} });

sub get_bold ($self) {
    return $self->elements->{bold} //= MarkdownElement::Bold->new;
}

sub get_italic ($self) {
    return $self->elements->{italic} //= MarkdownElement::Italic->new;
}

# Compositeの実装例
package MarkdownElement::Paragraph;
use Moo;

has 'children' => (is => 'ro', default => sub { [] });

sub add ($self, $element) {
    push @{$self->children}, $element;
}

sub render ($self) {
    my $content = join '', map { $_->render } @{$self->children};
    return "<p>$content</p>\n";
}
```

**USP（独自の価値提案）**:
- **パフォーマンスの可視化**: メモリ使用量のBefore/Afterを数値で示せる
- **実用性**: 実際に使えるツール（Markdown → HTML変換）
- **教育的価値**: データ構造とメモリ最適化の理解が深まる

**根拠**:
- Boost.Flyweight での実装例: https://www.boost.org/latest/libs/flyweight/doc/examples.html
- テキストエディタで実証済みのパターン

**信頼度**: 9/10（技術的には高度だが、Perlでの実装は工夫が必要）

---

### 🎯 候補3: **Abstract Factory + Prototype**（ゲームのエンティティ生成システム）

#### パターンの組み合わせ理由

- **Abstract Factory**: 関連するオブジェクト群（敵、地形、アイテム）をファミリー単位で生成
- **Prototype**: マスターオブジェクトからのクローンで高速生成
- **相乗効果**: レベルデザインの一貫性を保ちながら、オブジェクト生成のコストを削減

#### 題材案: 「ローグライク風ダンジョン生成エンジン」

**概要**:
- 異なるテーマ（森、洞窟、城）のダンジョンを生成
- 各テーマごとに一貫したエンティティ（敵、罠、宝箱）を提供
- プロトタイプから高速にクローン生成

**実装ステップ**:
1. **第1回**: Prototypeパターンで単一エンティティのクローニング
2. **第2回**: Abstract Factoryでテーマ別ファクトリーを実装
3. **第3回**: ダンジョンジェネレーターの実装
4. **第4回**: ゲームエンジンとの統合（表示、衝突判定）

**完成品の価値**:
- デモが派手（ダンジョンマップの視覚化）
- ゲーム開発の入門として最適
- 「このエンジン、テーマを変えるだけでダンジョンの雰囲気が変わる」

**技術的な実装可能性**:
```perl
# Prototypeの実装例
package Entity::Prototype;
use Moo;
use Storable qw(dclone);

has 'name'   => (is => 'ro');
has 'health' => (is => 'rw');
has 'sprite' => (is => 'ro');

sub clone ($self) {
    return dclone($self);
}

# Abstract Factoryの実装例
package DungeonFactory::Forest;
use Moo;

has 'prototypes' => (
    is      => 'ro',
    default => sub {
        {
            enemy => Entity::Prototype->new(name => 'Wolf', health => 50, sprite => '🐺'),
            trap  => Entity::Prototype->new(name => 'Vine Trap', health => 1, sprite => '🌿'),
            chest => Entity::Prototype->new(name => 'Wooden Chest', health => 10, sprite => '📦'),
        }
    }
);

sub create_enemy ($self) {
    return $self->prototypes->{enemy}->clone;
}

sub create_trap ($self) {
    return $self->prototypes->{trap}->clone;
}
```

**USP（独自の価値提案）**:
- **ゲーム開発の入り口**: 初学者がゲームプログラミングに興味を持つきっかけ
- **拡張性**: 新しいテーマ（火山、氷山など）を簡単に追加可能
- **パフォーマンス**: プロトタイプクローンの速さを体感できる

**注意点**:
- 単一パターンシリーズで「ダンジョン生成（Bridge）」が使用済み → テーマを変える必要がある
  - Bridge版: 描画エンジンとダンジョンロジックの分離
  - この版: エンティティ生成の最適化に焦点

**根拠**:
- SourceMaking: https://sourcemaking.com/design_patterns/abstract_factory
- Game Programming Patterns: https://gameprogrammingpatterns.com/

**信頼度**: 9/10（ゲーム開発での実績多数、ただし重複リスクに注意）

---

### 🎯 候補4: **Iterator + Visitor**（ログファイル分析ツール）

#### パターンの組み合わせ理由

- **Iterator**: ログファイルの各行を順次走査（巨大ファイルでもメモリ効率的）
- **Visitor**: 異なる分析操作（エラー集計、統計、レポート生成）を動的に適用
- **相乗効果**: 構造とアルゴリズムを分離し、新しい分析を簡単に追加

#### 題材案: 「拡張可能なログ分析フレームワーク」

**概要**:
- Webサーバーのアクセスログやアプリケーションログを解析
- Iteratorで1行ずつ読み込み（メモリ効率的）
- Visitorで様々な分析（エラー率、アクセス統計、異常検出）を実行

**実装ステップ**:
1. **第1回**: Iteratorでログファイルを効率的に走査
2. **第2回**: Visitorで基本的な分析（エラーカウント）
3. **第3回**: 複数のVisitor（統計、レポート生成、グラフ化）
4. **第4回**: プラグインアーキテクチャで新しいVisitorを動的に追加

**完成品の価値**:
- 実務で即使える（サーバー管理、障害調査）
- 「新しい分析ロジックをプラグインで追加できる」拡張性
- ベンチマーク結果を示せる（大規模ファイルでの処理速度）

**技術的な実装可能性**:
```perl
# Iteratorの実装例
package LogIterator;
use Moo;
use autodie;

has 'filename' => (is => 'ro', required => 1);
has 'fh'       => (is => 'lazy');

sub _build_fh ($self) {
    open my $fh, '<', $self->filename;
    return $fh;
}

sub next ($self) {
    my $fh = $self->fh;
    return <$fh>;
}

# Visitorの実装例
package LogVisitor::ErrorCounter;
use Moo;

has 'error_count' => (is => 'rw', default => 0);

sub visit ($self, $log_line) {
    if ($log_line =~ /ERROR|FATAL/) {
        $self->error_count($self->error_count + 1);
    }
}

sub report ($self) {
    return "Total errors: " . $self->error_count;
}

# 使用例
my $iterator = LogIterator->new(filename => '/var/log/app.log');
my @visitors = (
    LogVisitor::ErrorCounter->new,
    LogVisitor::TrafficAnalyzer->new,
    LogVisitor::AnomalyDetector->new,
);

while (my $line = $iterator->next) {
    $_->visit($line) for @visitors;
}

say $_->report for @visitors;
```

**USP（独自の価値提案）**:
- **プラグイン的拡張性**: 新しい分析ロジックを既存コードに影響なく追加
- **メモリ効率**: 巨大ログファイル（GB級）でも処理可能
- **実用性**: サーバー運用、セキュリティ監査に直結

**根拠**:
- Stack Overflow: https://stackoverflow.com/questions/28319129/visitor-pattern-vs-iterator-pattern
- 実務での採用例多数

**信頼度**: 9/10（実務向けだが、初学者には若干難易度高め）

---

## 3. 競合記事分析

### 主要な競合サイト

| サイト名 | 特徴 | URL | 言語 |
|---------|------|-----|------|
| **Refactoring Guru** | 視覚的、多言語対応、パターン単体が中心 | https://refactoring.guru/design-patterns | 英語 |
| **GeeksforGeeks** | 網羅的、コード例豊富だが組み合わせは少ない | https://www.geeksforgeeks.org/system-design/ | 英語 |
| **SourceMaking** | 詳細な解説、UML図が充実 | https://sourcemaking.com/design_patterns | 英語 |
| **Qiita** | 日本語、実例ベースだがPerl実装は稀 | https://qiita.com/tags/designpattern | 日本語 |
| **Software Patterns Lexicon** | パターン組み合わせの理論的解説 | https://softwarepatternslexicon.com/ | 英語 |

### 競合の弱点（差別化ポイント）

1. **Perl実装が極めて少ない**
   - ほとんどの記事がJava/C#/Python
   - Mooseを使った実装例がほぼ存在しない
   - **チャンス**: Perl + Mooでの実装を示すだけで差別化

2. **組み合わせの実例が不足**
   - 単一パターンの解説が中心
   - 組み合わせは理論的な説明のみ
   - **チャンス**: 実際に動くコードで組み合わせの威力を示す

3. **初学者向けのストーリー性が弱い**
   - 学術的・教科書的な説明が多い
   - 完成品を作る楽しさが伝わらない
   - **チャンス**: 「楽しく、実践的」な題材で読者を引き込む

4. **ベンチマークやパフォーマンス比較が少ない**
   - 理論的な説明が中心
   - 実際の効果が数値で示されていない
   - **チャンス**: Before/Afterの比較で価値を可視化

---

## 4. 内部リンク調査（/content/post配下）

### 単一パターン記事（既存）

| パターン名 | ファイルパス（推定） | 内部リンク | 関連度 |
|-----------|---------------------|-----------|--------|
| Bridge | agents/warehouse/bridge-pattern.md | 確認必要 | 高（Facade + Adapterとの対比） |
| Flyweight | agents/warehouse/flyweight-pattern.md | 確認必要 | 高（Compositeとの組み合わせ） |
| Composite | agents/warehouse/composite-pattern.md | 確認必要 | 高（Flyweightとの組み合わせ） |
| Proxy | agents/warehouse/proxy-pattern.md | 確認必要 | 中（Decoratorとの対比） |
| Decorator | agents/warehouse/decorator-pattern.md | 確認必要 | 中（Proxyとの対比） |
| Abstract Factory | agents/warehouse/abstract-factory-pattern.md | 確認必要 | 高（Prototypeとの組み合わせ） |
| Prototype | agents/warehouse/prototype-pattern.md | 確認必要 | 高（Abstract Factoryとの組み合わせ） |
| Iterator | 未作成？ | 確認必要 | 中 |
| Visitor | agents/warehouse/visitor-pattern.md | 確認必要 | 中（Iteratorとの組み合わせ） |

### リンク戦略

各組み合わせシリーズの記事から、単一パターンの記事へリンクを張る：

**例**:
```markdown
このシリーズでは**Facade**と**Adapter**を組み合わせます。
各パターンの詳細は以下の記事を参照してください：

- [Facadeパターン入門](/path/to/facade-pattern/)
- [Adapterパターン入門](/path/to/adapter-pattern/)
```

---

## 5. 推奨する組み合わせとその理由

### 🏆 第1位: **Facade + Adapter**（天気予報APIアグリゲーター）

#### 推奨理由

1. **実務直結度**: ★★★★★
   - API統合は実際の開発で頻出
   - レガシーシステム統合のベストプラクティス
   - マイクロサービスアーキテクチャの基本

2. **初学者への適合性**: ★★★★☆
   - HTTPリクエスト、JSONパースなど実践的スキルを習得
   - 段階的に機能追加できる（最初は1つのAPIから）
   - デバッグが容易（外部APIのレスポンスを確認しやすい）

3. **楽しさ・自慢要素**: ★★★★☆
   - 「複数のAPIを統合したツール」は友人に見せて楽しい
   - 天気予報という身近なテーマ
   - 実用性が高い（実際に使える）

4. **Perlとの相性**: ★★★★★
   - HTTP::Tiny、JSON::PP など標準的なCPANモジュールを活用
   - Mooでのオブジェクト指向が自然に書ける
   - CPAN モジュールの統合パターンとして応用可能

5. **差別化度**: ★★★★★
   - Perl + Mooでの実装例が競合にほぼ存在しない
   - レガシー統合という実務テーマ
   - 拡張性の高さを示せる

#### 実装スケジュール案

- **第1回**: Adapterパターン単体（OpenWeatherMap APIをラップ）
- **第2回**: 複数のAdapter実装（WeatherStack、気象庁API）
- **第3回**: Facadeで統一インターフェース提供
- **第4回**: キャッシング、フォールバック、エラーハンドリング（応用編）

#### 想定記事タイトル

- 「Perlで学ぶデザインパターン：Facade + Adapter で複数の天気予報APIを統合する【全4回】」

---

### 🥈 第2位: **Flyweight + Composite**（超軽量Markdownパーサー）

#### 推奨理由

1. **技術的な面白さ**: ★★★★★
   - メモリ最適化という明確な目標
   - パフォーマンスの可視化（Before/After比較）
   - データ構造の理解が深まる

2. **初学者への適合性**: ★★★☆☆
   - 若干難易度が高い（Flyweightの理解が必要）
   - ただし、Markdownという身近な題材
   - 段階的な実装で学習負荷を軽減可能

3. **楽しさ・自慢要素**: ★★★★☆
   - 「メモリ使用量が1/10になった」という数値の説得力
   - ベンチマーク結果をブログで公開できる
   - CPANモジュールとして公開可能

4. **Perlとの相性**: ★★★★☆
   - Perlはテキスト処理が得意
   - Storableでクローニングも容易
   - ただし、メモリ管理はPerl特有の注意が必要

5. **差別化度**: ★★★★☆
   - Flyweight + Compositeの組み合わせ実装は珍しい
   - パフォーマンス改善の数値化で説得力

#### 実装スケジュール案

- **第1回**: Compositeでドキュメント構造を構築
- **第2回**: Flyweightで要素を最適化
- **第3回**: Markdownパーサーの実装
- **第4回**: HTMLレンダラーとベンチマーク

---

### 🥉 第3位: **Iterator + Visitor**（拡張可能なログ分析フレームワーク）

#### 推奨理由

1. **実務直結度**: ★★★★★
   - サーバー運用、障害調査で即戦力
   - セキュリティ監査、トレンド分析にも応用可能
   - プラグインアーキテクチャは汎用的

2. **初学者への適合性**: ★★★☆☆
   - Visitorパターンは理解が難しい
   - ただし、ログ解析という身近な題材
   - 段階的な実装で学習負荷を軽減可能

3. **楽しさ・自慢要素**: ★★★☆☆
   - 実用性は高いが、デモの派手さは控えめ
   - 「巨大ログファイルでもメモリを消費しない」という技術的な魅力
   - プラグイン的拡張性を示せる

4. **Perlとの相性**: ★★★★★
   - Perlはテキスト処理・正規表現が得意
   - ファイルハンドリングも強力
   - CPANにログ解析系モジュールが豊富

5. **差別化度**: ★★★★☆
   - Iterator + Visitorの組み合わせ実装は珍しい
   - プラグインアーキテクチャで拡張性をアピール

#### 注意点

- 単一パターンシリーズで「ログ解析（Decorator）」が使用済み
  - **差別化**: Decorator版は装飾的な機能追加、こちらは走査と分析の分離に焦点

---

## 6. USP（独自の価値提案）まとめ

### なぜ有料で読む価値があるか？

#### 1. **Perl + Moo実装の希少性**
- 競合記事のほとんどがJava/C#/Python
- Mooseを使った実装例が極めて少ない
- **価値**: Perlエンジニアにとって唯一無二のリソース

#### 2. **組み合わせの実践例**
- 単一パターンの解説は無料で溢れている
- 組み合わせの実装は圧倒的に少ない
- **価値**: 実務レベルの設計力が身につく

#### 3. **完成品を作る楽しさ**
- 教科書的な説明ではなく、動くツールを作る
- 友人に自慢できる、実際に使えるツール
- **価値**: 学習のモチベーション維持

#### 4. **ベンチマークとパフォーマンス可視化**
- Before/Afterの数値比較
- メモリ使用量、処理速度の改善を示す
- **価値**: パターンの効果を体感できる

#### 5. **初学者に優しい段階的アプローチ**
- 第1回で基礎、第2回で応用、第3回で統合
- エラーハンドリング、テスト、ベストプラクティスも解説
- **価値**: 挫折せずに学習を完走できる

---

## 7. 技術的な実装可能性の検証

### Perl v5.36以降の機能活用

#### Signatures（関数シグネチャ）
```perl
use v5.36;

sub get_weather ($self, $city, $options = {}) {
    # ...
}
```

#### Postfix Dereference
```perl
for my $adapter ($self->adapters->@*) {
    # ...
}
```

### Mooの活用

#### Role（インターフェース）
```perl
package Role::WeatherProvider;
use Moo::Role;
requires 'get_weather';
```

#### 遅延評価（lazy）
```perl
has 'http' => (
    is      => 'ro',
    lazy    => 1,
    default => sub { HTTP::Tiny->new },
);
```

### CPANモジュールの活用

| 用途 | モジュール | 説明 |
|------|----------|------|
| HTTP通信 | HTTP::Tiny | 軽量HTTPクライアント |
| JSONパース | JSON::PP | Pure Perl実装のJSON |
| クローニング | Storable（dclone） | ディープコピー |
| テスト | Test::More, Test::Deep | ユニットテスト |
| 例外処理 | Try::Tiny | try-catch構文 |

---

## 8. 結論と次のステップ

### 推奨する組み合わせ

**第1候補**: **Facade + Adapter**（天気予報APIアグリゲーター）

**理由**:
- 実務直結度が最も高い
- 初学者にも理解しやすい
- Perlとの相性が抜群
- 差別化が明確（Perl実装がほぼ存在しない）
- 楽しさと実用性のバランスが最適

### 次のステップ

1. **プロトタイプ実装** (1週間)
   - 最小限の機能で動作確認
   - Mooでの実装パターンを確立

2. **記事構成の詳細設計** (3日)
   - 各回のテーマと学習目標を明確化
   - サンプルコードの準備

3. **第1回記事の執筆** (1週間)
   - Adapterパターンの基礎
   - 単一APIのラップ

4. **レビュー＆改善** (2日)
   - 技術的な正確性の確認
   - 初学者への分かりやすさの検証

---

## 9. 参考文献・出典

### 組み合わせパターンの理論
- Software Patterns Lexicon: https://softwarepatternslexicon.com/object-oriented/applying-design-patterns-in-practice/combining-patterns/
- Kind of Technical: https://kindatechnical.com/software-design-patterns/lesson-40-combining-multiple-design-patterns.html

### Facade + Adapter
- CodeSignal: https://codesignal.com/learn/courses/backward-compatibility-in-software-development-1/
- MomentsLog: https://www.momentslog.com/development/design-pattern/adapter-vs-facade-pattern-when-to-use-each

### Flyweight + Composite
- Boost.Flyweight: https://www.boost.org/latest/libs/flyweight/doc/examples.html
- GeeksforGeeks: https://www.geeksforgeeks.org/system-design/flyweight-design-pattern/

### Abstract Factory + Prototype
- SourceMaking: https://sourcemaking.com/design_patterns/abstract_factory
- Java Design Patterns: https://java-design-patterns.com/patterns/abstract-factory/

### Iterator + Visitor
- Stack Overflow: https://stackoverflow.com/questions/28319129/visitor-pattern-vs-iterator-pattern
- Software Engineering SE: https://softwareengineering.stackexchange.com/questions/386077/

### Perlでの実装
- GitHub p5-moose-design-patterns: https://github.com/jmcveigh/p5-moose-design-patterns
- Perl OOP Tutorial: https://perldoc.perl.org/perlootut

### ゲーム・実践的題材
- Game Programming Patterns: https://gameprogrammingpatterns.com/
- Qiita実例: https://qiita.com/Tadataka_Takahashi/items/3e565fdb8f18bb1f70e6

---

**調査完了日**: 2026年1月24日  
**次回更新**: プロトタイプ実装完了後
