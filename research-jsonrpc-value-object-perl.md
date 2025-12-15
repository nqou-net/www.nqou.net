# 調査レポート：PerlでJSON-RPC 2.0のオブジェクトを値オブジェクトとして定義

**調査日時**: 2025-12-15  
**シリーズタイトル**: PerlでJSON-RPC 2.0のオブジェクトを値オブジェクトとして定義してみた（全3回）  
**調査者**: AI Research Assistant

---

## 目次

1. [JSON-RPC 2.0仕様の調査](#1-json-rpc-20仕様の調査)
2. [値オブジェクト（Value Object）パターン](#2-値オブジェクトvalue-objectパターン)
3. [Perlでの値オブジェクト実装](#3-perlでの値オブジェクト実装)
4. [テスト駆動開発（TDD）とPerl](#4-テスト駆動開発tddとperl)
5. [記事執筆時の推奨リソース](#5-記事執筆時の推奨リソース)

---

## 1. JSON-RPC 2.0仕様の調査

### 1.1 公式仕様書

**最新仕様URL**: https://www.jsonrpc.org/specification  
**正式版日付**: 2013年1月4日

**信頼性**: ★★★★★（公式仕様書）

### 1.2 仕様の重要ポイント

#### 1.2.1 基本原則

- **ステートレス**: 各リクエストは独立して処理される
- **トランスポート非依存**: HTTP、WebSocket、TCP等、任意のトランスポート上で動作可能
- **JSON準拠**: 厳密なJSONデータ型のみを使用
- **バージョン識別**: 必須の `"jsonrpc": "2.0"` メンバーで識別

**参考資料**:
- JSON-RPC 2.0 Specification: https://www.jsonrpc.org/specification
- JSON-RPC - Wikipedia: https://en.wikipedia.org/wiki/JSON-RPC

#### 1.2.2 Requestオブジェクトの定義

**MUST制約**:

| フィールド | 型 | 必須性 | 制約 |
|-----------|-----|--------|------|
| `jsonrpc` | String | MUST | 正確に "2.0" でなければならない |
| `method` | String | MUST | 呼び出すメソッド名 |
| `params` | Object/Array | OPTIONAL | メソッドのパラメータ |
| `id` | String/Number/Null | OPTIONAL | レスポンスとのマッチングに使用。通知の場合は省略 |

**重要な排他性**:
- 通知（Notification）の場合、`id`フィールドは**存在してはならない（MUST NOT）**
- 通知に対してサーバーは**応答してはならない（MUST NOT）**

**参考資料**:
- JSON-RPC Version Differences: https://json-rpc.dev/docs/reference/version-diff
- AUBO Developer Guide: https://developer.aubo-robotics.cn/en/guide_sdk/3_protocol/1_json_rpc_protocol.html

#### 1.2.3 Responseオブジェクトの定義

**成功時のMUST制約**:

| フィールド | 型 | 必須性 | 制約 |
|-----------|-----|--------|------|
| `jsonrpc` | String | MUST | 正確に "2.0" |
| `result` | Any | MUST | メソッドの戻り値 |
| `id` | String/Number/Null | MUST | リクエストの`id`と一致 |

**エラー時のMUST制約**:

| フィールド | 型 | 必須性 | 制約 |
|-----------|-----|--------|------|
| `jsonrpc` | String | MUST | 正確に "2.0" |
| `error` | Object | MUST | エラー情報を含むオブジェクト |
| `id` | String/Number/Null | MUST | リクエストの`id`と一致、取得不可の場合はnull |

**排他性制約**:
- 成功レスポンスには`result`が存在し、`error`は**存在してはならない（MUST NOT）**
- エラーレスポンスには`error`が存在し、`result`は**存在してはならない（MUST NOT）**

**参考資料**:
- JSON-RPC 2.0 Official Spec - JOQL: https://joql.org/json-rpc-intro

#### 1.2.4 Errorオブジェクトの定義

**MUST制約**:

| フィールド | 型 | 必須性 | 制約 |
|-----------|-----|--------|------|
| `code` | Integer | MUST | エラーのタイプを示す数値。省略不可 |
| `message` | String | MUST | エラーの簡潔な説明。省略不可 |
| `data` | Any | OPTIONAL | エラーに関する追加情報 |

**標準エラーコード**:

| コード範囲 | 意味 | 用途 |
|-----------|------|------|
| -32768 ～ -32000 | 予約済み | JSON-RPCコアエラー用 |
| -32099 ～ -32000 | サーバーエラー | 実装定義エラー用 |
| -32700 | Parse error | 無効なJSONを受信 |
| -32600 | Invalid Request | JSONは有効だがJSON-RPCとして無効 |
| -32601 | Method not found | メソッドが存在しない |
| -32602 | Invalid params | 無効なメソッドパラメータ |
| -32603 | Internal error | 内部JSON-RPCエラー |

**MUST NOT制約**:
- `code`と`message`を**省略してはならない（MUST NOT）**
- エラーレスポンスに`result`を**含めてはならない（MUST NOT）**
- 通知に対してエラーを**返してはならない（MUST NOT）**
- 予約済みコード範囲を標準に従わずに**使用してはならない（SHOULD NOT）**

**参考資料**:
- JSON-RPC Error Codes Reference: https://json-rpc.dev/docs/reference/error-codes
- Error Handling and JSON-RPC Errors: https://deepwiki.com/google/a2a-python/5.4-error-handling-and-json-rpc-errors
- Apache Traffic Server JSON RPC errors: https://docs.trafficserver.apache.org/en/latest/developer-guide/jsonrpc/jsonrpc-node-errors.en.html
- JSON RPC 2.0 standard responses - Stack Overflow: https://stackoverflow.com/questions/34912647/json-rpc-2-0-standard-responses

#### 1.2.5 バッチリクエストと通知

**バッチリクエストの仕様**:
- 複数のリクエスト（通知を含む）を単一のJSON配列で送信可能
- 各オブジェクトは標準のJSON-RPC構造に従う
- サーバーは各オブジェクトを独立して処理
- レスポンスは`id`を持つリクエストのみに対して返される配列
- 全てが通知の場合、サーバーは何も返さない

**バッチの例**:
```json
[
  { "jsonrpc": "2.0", "id": 1, "method": "sum", "params": [1,2,3] },
  { "jsonrpc": "2.0", "method": "notify_hello", "params": [7] },
  { "jsonrpc": "2.0", "id": 2, "method": "subtract", "params": [42,23] }
]
```

**レスポンス例** (通知には応答なし):
```json
[
  { "jsonrpc": "2.0", "id": 1, "result": 6 },
  { "jsonrpc": "2.0", "id": 2, "result": 19 }
]
```

**参考資料**:
- JSON-RPC Batch Requests Example: https://json-rpc.dev/learn/examples/batch-requests
- Batching and Notifications - Goa Design: https://goa.design/docs/4-concepts/7-jsonrpc/5-batching-and-notifications/

### 1.3 拡張仕様

**OpenRPC Specification**: https://spec.open-rpc.org/  
JSON-RPC 2.0 APIの機械可読なインターフェース記述形式。APIの文書化と発見を支援。

**信頼性**: ★★★★☆（コミュニティ標準）

---

## 2. 値オブジェクト（Value Object）パターン

### 2.1 値オブジェクトの定義

**定義**: ドメイン駆動設計（DDD）における基本的なビルディングブロック。一意な識別子を持たず、属性のみで定義されるオブジェクト。

**参考資料**:
- Value Object - Martin Fowler: https://martinfowler.com/bliki/ValueObject.html
- Value Object pattern · Microservices Architecture: https://badia-kharroubi.gitbooks.io/microservices-architecture/content/patterns/tactical-patterns/value-object-pattern.html

### 2.2 値オブジェクトの主要特性

#### 2.2.1 アイデンティティの欠如

- **エンティティとの違い**: エンティティは一意のIDを持つが、値オブジェクトは属性のみで識別される
- **等価性**: 全ての属性値が同じであれば、2つの値オブジェクトは等価とみなされる
- **交換可能性**: 同じ属性値を持つインスタンスは自由に交換可能

#### 2.2.2 不変性（Immutability）

- **原則**: 一度作成されたら状態を変更できない
- **利点**:
  - 一貫性の保証
  - 推論の簡素化
  - 意図しない変更によるバグの防止
  - 並行処理の安全性向上
- **変更方法**: 変更が必要な場合は新しいインスタンスを生成

#### 2.2.3 値による等価性

- **比較方法**: インスタンスのリファレンスではなく、属性値で比較
- **実装**: 等価性演算子やハッシュ関数のオーバーライド
- **動的型付け言語**: 属性を直接比較するカスタムメソッドの実装

#### 2.2.4 振る舞いのカプセル化

- **ロジックの内包**: 値オブジェクトはデータに関連する振る舞い（メソッド）を持つことができる
- **例**: Moneyオブジェクトが算術演算や通貨変換のメソッドを提供

#### 2.2.5 自己完結性

- **副作用のない振る舞い**: メソッドは外部状態を変更せず、新しい値オブジェクトを返す

**参考資料**:
- Implementing value objects - .NET | Microsoft Learn: https://learn.microsoft.com/en-us/dotnet/architecture/microservices/microservice-ddd-cqrs-patterns/implement-value-objects
- Value Objects in Domain-Driven Design - GitHub: https://github.com/SAP/curated-resources-for-domain-driven-design/blob/main/knowledgebase/concepts/tactical-concepts/value-objects.md
- Value Objects :: Domain Driven Design & Microservices Guide: https://ddd.acloudfan.com/5.tactical/20.value-objects/

### 2.3 動的型付け言語における値オブジェクト

#### 2.3.1 動的型付け言語特有の課題

- **不変性の強制**: 言語レベルでの強制がないため、規約と実装パターンに依存
- **等価性の実装**: 型チェックなしで全属性を比較する必要がある
- **柔軟性と規律**: 柔軟性がある反面、意図しない変更を防ぐ規律が必要

#### 2.3.2 実装戦略

**Python**:
- `@dataclass(frozen=True)`: 不変データクラス
- `namedtuple`: 軽量な不変オブジェクト

**JavaScript/TypeScript**:
- `Object.freeze()`: オブジェクトの凍結
- TypeScriptの`readonly`プロパティ

**Ruby**:
- `Struct`: 構造体による値オブジェクト
- `==`演算子のオーバーライド

**Perl** (後述):
- Moose/Mooの`is => 'ro'`
- Class::Tiny::Immutable
- immutableモジュール

#### 2.3.3 テスト戦略

- **ユニットテスト**: 値オブジェクトのロジックを徹底的にテスト
- **等価性のテスト**: 属性値による比較の動作確認
- **不変性のテスト**: 変更操作が新インスタンスを生成することの確認
- **規約の遵守**: コンパイル時チェックがないため、テストが特に重要

**参考資料**:
- Exploring Value Objects in Domain-Driven Design: https://zlianhua.github.io/ddd-blog/2024-01-26-ValueObject/
- Value Objects in Depth in Domain-Driven Design - DEV Community: https://dev.to/ruben_alapont/value-objects-in-depth-in-domain-driven-design-2cbj
- Domain-Driven Design Principles: Value Objects in ASP.NET Core - Telerik: https://www.telerik.com/blogs/domain-driven-design-principles-value-objects-aspnet-core
- Domain-driven design in functional programming - Thoughtworks: https://www.thoughtworks.com/insights/blog/architecture/domain-driven-design-in-functional-programming

---

## 3. Perlでの値オブジェクト実装

### 3.1 CPANモジュールの調査

#### 3.1.1 Moose/Moo（推奨レベル: ★★★★★）

**特徴**:
- 最も広く使用されるモダンなPerlオブジェクトシステム
- 不変性のサポート: `is => 'ro'`で読み取り専用属性
- 型制約のサポート
- 強力なコンストラクタロジック

**Mooseの例**:
```perl
package Box;
use Moose;

has 'name'  => (is => 'ro', isa => 'Str', required => 1);
has 'price' => (is => 'ro', isa => 'Num', required => 1);

# オブジェクトは構築後に不変
```

**Mooの特徴**:
- Mooseの軽量版
- ほぼ同じAPI、より少ないオーバーヘッド
- Mooseとの互換性あり

**注意点**:
- `is => 'ro'`は浅い不変性のみ（参照先は変更可能）
- 深い不変性にはConst::Fastや追加の工夫が必要

**参考資料**:
- What Are the Notable Cpan Modules for Perl Developers?: https://dev.to/jordankeurope/what-are-the-notable-cpan-modules-for-perl-developers-2b91

#### 3.1.2 Class::Tiny::Immutable（推奨レベル: ★★★★☆）

**特徴**:
- Class::Tinyのラッパー
- 真の読み取り専用属性を強制
- 軽量でシンプル
- 構築後の変更を禁止

**使用例**:
```perl
package MyClass;
use Class::Tiny::Immutable qw(name age);

my $obj = MyClass->new(name => "Alice", age => 30);
# $obj->name("Bob"); # dies! nameは読み取り専用
```

**ベストプラクティス**:
- 必須属性は構築時に提供
- 遅延評価のデフォルトにはサブルーチンを使用
- アクセサメソッドのみを使用（ハッシュ直接操作を避ける）

**参考資料**:
- Class::Tiny::Immutable - MetaCPAN: https://metacpan.org/pod/Class::Tiny::Immutable
- Attributes - Minimum Viable Perl - Kablamo: https://mvp.kablamo.org/oo/attributes/
- Class::Tiny - Minimalist class construction - MetaCPAN: https://metacpan.org/pod/Class::Tiny

#### 3.1.3 Object::Tiny/Class::Tiny（推奨レベル: ★★★☆☆）

**特徴**:
- 超ミニマリスト
- 読み取り専用属性と簡素なコンストラクタ
- リソース制約のある環境向け

**制限**:
- 不変性は自分で実装
- 型制約なし
- 真の値オブジェクトにはClass::Tiny::Immutableを推奨

#### 3.1.4 Mouse（推奨レベル: ★★★☆☆）

**特徴**:
- Mooseの軽量版（別実装）
- Mooseと似たAPIだが高速
- 不変性サポート

**用途**: Mooseのオーバーヘッドが問題となる場合

#### 3.1.5 immutableモジュール（推奨レベル: ★★★★☆）

**特徴**:
- Perlのネイティブデータ構造の不変版を提供
- 関数型スタイルの操作

**使用例**:
```perl
use immutable::0 ':all';

my $hash  = imap(k1 => 123, k2 => 456);
my $hash2 = $hash->set(k3 => 789);  # 新しい不変ハッシュを返す
# $hash->{k3} = 789; # エラー！
```

**用途**: 関数型プログラミングスタイルの値オブジェクト

**参考資料**:
- immutable - Immutable Data Structures for Perl - MetaCPAN: https://metacpan.org/pod/immutable

#### 3.1.6 Data::Enum（推奨レベル: ★★★☆☆）

**特徴**:
- 高速で不変な列挙型クラスの生成
- シングルトンパターン
- 値の変更を禁止

**使用例**:
```perl
use Data::Enum;

my $Color = Data::Enum->new(qw(red yellow blue green));
my $red   = $Color->new("red");
# $redは不変、"red"に文字列化、シングルトン
```

**参考資料**:
- GitHub - robrwo/perl-Data-Enum: https://github.com/robrwo/perl-Data-Enum

#### 3.1.7 型制約モジュール

**Types::Standard / Type::Tiny**:
- Moo/Mooseと組み合わせて使用
- 強力な型検証
- 値オブジェクトの信頼性向上

### 3.2 実装パターンとベストプラクティス

#### 3.2.1 Corinna（次世代Perlオブジェクトシステム）

**特徴**:
- Perlの将来のオブジェクトシステム
- 設計段階で不変性を重視
- `:reader`属性で読み取り専用
- `clone()`による変更

**例** (将来的な構文):
```perl
class Box {
    has ($height, $width, $depth) :reader :new;
    has $volume :reader = $width * $height * $depth;
}

my $original_box = Box->new(height=>1, width=>2, depth=>3);
my $updated_box  = $original_box->clone(depth=>9);
# $volumeは再計算される（コピーではない）
```

**参考資料**:
- Use Immutable Objects - DEV Community: https://dev.to/ovid/use-immutable-objects-4pbl
- Why Do We Want Immutable Objects? - curtispoe.org: https://curtispoe.org/articles/using-immutable-datetime-objects-with-dbixclass.html

#### 3.2.2 深い不変性の実装

**Mooseでの深い不変性**:
```perl
use Const::Fast;

has 'numbers' => (
    is => 'ro',
    isa => 'ArrayRef[Int]',
    coerce => sub {
        my $ref = shift;
        const my @immutable => @$ref;
        return \@immutable;
    }
);
```

**参考資料**:
- How to make Moose attributes immutable? - Stack Overflow: https://stackoverflow.com/questions/76405261/how-to-make-moose-attributes-immutable

### 3.3 JSON-RPC関連のCPANモジュール

#### 3.3.1 JSON::RPC2（推奨レベル: ★★★★★）

**特徴**:
- トランスポート非依存のJSON-RPC 2.0実装
- サーバーとクライアント両方をサポート
- 柔軟なアーキテクチャ

**使用例**:
```perl
use JSON::RPC2::Server;

my $server = JSON::RPC2::Server->new(
    methods => {
        sum => sub {
            my ($params) = @_;
            return $params->[0] + $params->[1];
        }
    }
);
```

**参考資料**:
- powerman/perl-JSON-RPC2 - GitHub: https://github.com/powerman/perl-JSON-RPC2
- JSON::RPC2 - MetaCPAN: https://metacpan.org/pod/JSON::RPC2

#### 3.3.2 JSON::RPC（レガシー、推奨レベル: ★★☆☆☆）

**特徴**:
- JSON-RPC 1.1 WD対応
- 広く使用されているが古い
- 新規プロジェクトには非推奨

#### 3.3.3 JSONシリアライゼーション

**主要モジュール**:
- `JSON`: 標準的な選択
- `JSON::XS`: C実装、高速
- `Cpanel::JSON::XS`: JSON::XSの改良版
- `JSON::MaybeXS`: 利用可能な最速のJSON実装を自動選択

**使用例**:
```perl
use JSON;

my $json = encode_json({foo => "bar"});
my $data = decode_json($json);
```

**参考資料**:
- Using JSON for Effective Data Interchange in Perl - TheLinuxCode: https://thelinuxcode.com/json-with-perl/
- JSON with Perl - Online Tutorials Library: https://www.tutorialspoint.com/json/json_perl_example.htm
- Perl's JSON Handling Capabilities | Developer Guide: https://offlinetools.org/a/json-formatter/perls-json-handling-capabilities
- JSON with Perl - Great Learning: https://www.mygreatlearning.com/json/tutorials/json-with-perl

### 3.4 ブログ記事とGitHubリポジトリの実例

#### 3.4.1 Curtis "Ovid" Poeのブログ

- **Use Immutable Objects**: https://dev.to/ovid/use-immutable-objects-4pbl
  - Corinna を用いた不変オブジェクトの詳細な解説
  - `clone()`による変更パターン
  
- **Why Do We Want Immutable Objects?**: https://curtispoe.org/articles/using-immutable-datetime-objects-with-dbixclass.html
  - DBIx::Classとの組み合わせ例
  - 不変オブジェクトの利点の実践的説明

**信頼性**: ★★★★★（Perlコミュニティの著名な専門家）

#### 3.4.2 GitHubリポジトリ

- **perl-Data-Enum**: https://github.com/robrwo/perl-Data-Enum
  - 不変な列挙型の実装例
  - シングルトンパターンの応用

- **Perl Examples**: https://github.com/HimanthReddyGurram/Perl
  - 様々なPerlコードスニペット
  - 値オブジェクトに応用可能なパターン

---

## 4. テスト駆動開発（TDD）とPerl

### 4.1 Test::More - 主要なテストフレームワーク

**概要**:
- Perlで最も広く使用されるテストフレームワーク
- TAP（Test Anything Protocol）に準拠
- シンプルで強力なAPI

**参考資料**:
- Test::More - Perldoc: https://perldoc.perl.org/Test::More
- Test::More - MetaCPAN: https://metacpan.org/pod/Test::More

### 4.2 値オブジェクトのテスト戦略

#### 4.2.1 テストプランの定義

**方法1: 事前に固定**
```perl
use Test::More tests => 6;
```

**方法2: 動的（推奨）**
```perl
use Test::More;
# ... テスト実行 ...
done_testing();
```

**参考資料**:
- Test::More - perldoc.perl.org: https://perl.developpez.com/documentations/en/5.8.8/Test/More.html

#### 4.2.2 オブジェクト構築のテスト

```perl
use Test::More;

# モジュールの読み込みテスト
use_ok('My::ValueObject');

# インスタンス化のテスト
my $obj = My::ValueObject->new(attr1 => 'foo', attr2 => 42);
isa_ok($obj, 'My::ValueObject');

# 属性値のテスト
is($obj->attr1, 'foo', 'Attribute attr1 is correct');
is($obj->attr2, 42, 'Attribute attr2 is correct');

done_testing();
```

#### 4.2.3 等価性と不変性のテスト

**is_deeply による深い比較**:
```perl
my $obj1 = My::ValueObject->new(attr1 => 'foo', attr2 => 42);
my $obj2 = My::ValueObject->new(attr1 => 'foo', attr2 => 42);

is_deeply($obj1, $obj2, 'Two value objects with same attributes are deeply equal');
```

**is_deeplyの特徴**:
- 複雑なデータ構造（配列、ハッシュ、ネストしたオブジェクト）を比較
- 値による等価性を検証
- 不一致箇所を診断メッセージで報告

**参考資料**:
- Comparing complex data-structures using is_deeply - Perl Maven: https://perlmaven.com/comparing-complex-data-structures-with-is-deeply
- Understand testing modules with Test::More: https://app.studyraid.com/en/read/15934/558003/testing-modules-with-testmore

#### 4.2.4 無効な構築のテスト

```perl
# エラーが発生することを確認
eval { My::ValueObject->new(attr1 => undef) };
like($@, qr/Missing required attribute/, 'Fails with meaningful error for missing attribute');
```

#### 4.2.5 振る舞いメソッドのテスト

```perl
is($obj->combine, 'foo42', 'combine() returns correct value');

# 数値比較
cmp_ok($obj->calculate, '==', 42, 'calculate() returns expected numeric value');
```

**参考資料**:
- Writing Tests with Test::More - MIK: https://docstore.mik.ua/orelly/perl4/porm/ch14_03.htm
- Test::More is ( value, expected_value, name); - Testing in Perl: https://perlmaven.com/perl-testing/test-more/test-more-is

#### 4.2.6 サブテストによる整理

```perl
subtest 'constructor' => sub {
    my $obj = My::ValueObject->new(attr1 => 'foo');
    isa_ok($obj, 'My::ValueObject');
    is($obj->attr1, 'foo', 'attr1 initialized correctly');
};

subtest 'equality' => sub {
    my $obj1 = My::ValueObject->new(attr1 => 'foo');
    my $obj2 = My::ValueObject->new(attr1 => 'foo');
    is_deeply($obj1, $obj2, 'Objects are equal by value');
};

done_testing();
```

**サブテストの利点**:
- テストの階層化と整理
- 読みやすい出力
- 大規模テストスイートの保守性向上

**参考資料**:
- 2.2.1. Test::More - shlomifish.org: https://www.shlomifish.org/lecture/Perl/Newbies/lecture5/testing/demo/test-more.html

### 4.3 TDDプロセスと値オブジェクト

#### 4.3.1 TDDサイクル

1. **テストを先に書く**: 期待するAPIを定義
2. **実装**: テストをパスさせる最小限のコード
3. **リファクタリング**: コードを改善
4. **繰り返し**: 次の機能へ

**参考資料**:
- In TDD, how do you write tests first when the functions to test are undefined - Stack Overflow: https://stackoverflow.com/questions/66684057/in-tdd-how-do-you-write-tests-first-when-the-functions-to-test-are-undefined

#### 4.3.2 値オブジェクト特有のテストポイント

- **構築の検証**: 全ての必須属性が設定される
- **不変性の検証**: 属性が変更されない
- **等価性の検証**: 値による比較が正しく動作
- **振る舞いの検証**: ドメインロジックが正確

#### 4.3.3 ブラックボックステスト

- **原則**: 公開されたインターフェースのみをテスト
- **利点**: 内部実装を変更してもテストが壊れない
- **値オブジェクトへの適用**: アクセサメソッドを通じてのみ検証

### 4.4 高度なテスト機能

#### 4.4.1 Test2::Suite

- Test::Moreの後継
- より包括的な機能
- プロジェクトの成長に応じて移行を検討

**参考資料**:
- GitHub - Test-More/test-more: https://github.com/Test-More/test-more/

#### 4.4.2 テスト実行

```bash
# 単一のテストファイル
perl my_test.t

# proveツールで実行
prove my_test.t

# ディレクトリ内の全テスト
prove -r t/
```

---

## 5. 記事執筆時の推奨リソース

### 5.1 最重要リソース（必読）

#### 5.1.1 JSON-RPC 2.0仕様

1. **JSON-RPC 2.0 Specification**（公式）
   - URL: https://www.jsonrpc.org/specification
   - 信頼性: ★★★★★
   - 用途: Request、Response、Errorオブジェクトの正確な定義を参照

2. **JSON-RPC Error Codes Reference**
   - URL: https://json-rpc.dev/docs/reference/error-codes
   - 信頼性: ★★★★☆
   - 用途: エラーコードの標準と制約の確認

#### 5.1.2 値オブジェクトパターン

3. **Value Object - Martin Fowler**
   - URL: https://martinfowler.com/bliki/ValueObject.html
   - 信頼性: ★★★★★
   - 用途: 値オブジェクトの概念的理解

4. **Implementing value objects - .NET | Microsoft Learn**
   - URL: https://learn.microsoft.com/en-us/dotnet/architecture/microservices/microservice-ddd-cqrs-patterns/implement-value-objects
   - 信頼性: ★★★★★
   - 用途: 実装パターンの参考（言語は異なるが概念は共通）

#### 5.1.3 Perl実装

5. **Class::Tiny::Immutable - MetaCPAN**
   - URL: https://metacpan.org/pod/Class::Tiny::Immutable
   - 信頼性: ★★★★★
   - 用途: 軽量な不変オブジェクトの実装

6. **JSON::RPC2 - GitHub**
   - URL: https://github.com/powerman/perl-JSON-RPC2
   - 信頼性: ★★★★☆
   - 用途: JSON-RPCの実装例とアーキテクチャ

7. **Use Immutable Objects - Curtis "Ovid" Poe**
   - URL: https://dev.to/ovid/use-immutable-objects-4pbl
   - 信頼性: ★★★★★
   - 用途: Perlにおける不変オブジェクトのベストプラクティス

#### 5.1.4 テスト

8. **Test::More - Perldoc**
   - URL: https://perldoc.perl.org/Test::More
   - 信頼性: ★★★★★
   - 用途: テストの書き方の公式リファレンス

9. **Comparing complex data-structures using is_deeply - Perl Maven**
   - URL: https://perlmaven.com/comparing-complex-data-structures-with-is-deeply
   - 信頼性: ★★★★☆
   - 用途: 値オブジェクトの等価性テスト

### 5.2 補助リソース（推奨）

#### 5.2.1 理論・概念

10. **Value Objects in Domain-Driven Design - GitHub**
    - URL: https://github.com/SAP/curated-resources-for-domain-driven-design/blob/main/knowledgebase/concepts/tactical-concepts/value-objects.md
    - 信頼性: ★★★★☆

11. **Domain-driven design in functional programming - Thoughtworks**
    - URL: https://www.thoughtworks.com/insights/blog/architecture/domain-driven-design-in-functional-programming
    - 信頼性: ★★★★☆

#### 5.2.2 Perl実装詳細

12. **What Are the Notable Cpan Modules for Perl Developers?**
    - URL: https://dev.to/jordankeurope/what-are-the-notable-cpan-modules-for-perl-developers-2b91
    - 信頼性: ★★★☆☆

13. **Attributes - Minimum Viable Perl - Kablamo**
    - URL: https://mvp.kablamo.org/oo/attributes/
    - 信頼性: ★★★★☆

14. **immutable - Immutable Data Structures for Perl**
    - URL: https://metacpan.org/pod/immutable
    - 信頼性: ★★★★☆

#### 5.2.3 JSON処理

15. **Using JSON for Effective Data Interchange in Perl - TheLinuxCode**
    - URL: https://thelinuxcode.com/json-with-perl/
    - 信頼性: ★★★☆☆

### 5.3 記事シリーズの構成案

#### 第1回：JSON-RPC 2.0とは何か？仕様を理解する

**内容**:
- JSON-RPC 2.0の概要と歴史
- Request、Response、Errorオブジェクトの詳細
- MUST/MUST NOT制約の重要性
- バッチリクエストと通知

**参照すべきリソース**:
- JSON-RPC 2.0 Specification (公式)
- JSON-RPC Error Codes Reference
- JSON-RPC Batch Requests Example

#### 第2回：値オブジェクトパターンとPerlでの実装

**内容**:
- DDDにおける値オブジェクトとは
- 不変性、等価性、カプセル化の原則
- Perlでの実装選択肢（Moose、Class::Tiny::Immutable等）
- JSON-RPC 2.0オブジェクトを値オブジェクトとして定義する理由

**参照すべきリソース**:
- Martin Fowlerの値オブジェクト解説
- Class::Tiny::Immutable ドキュメント
- Curtis "Ovid" Poeのブログ記事
- Microsoft Learnの値オブジェクト実装ガイド

#### 第3回：TDDで作るJSON-RPC 2.0値オブジェクト

**内容**:
- Test::Moreによるテスト戦略
- Request、Response、Errorクラスの実装とテスト
- is_deeply による等価性テスト
- 実装の完全なコード例

**参照すべきリソース**:
- Test::More 公式ドキュメント
- Perl Mavenのis_deeplyガイド
- JSON::RPC2の実装例

### 5.4 技術的正確性の担保

#### 5.4.1 仕様準拠の確認

**チェックリスト**:
- [ ] JSON-RPC 2.0公式仕様書の該当セクションを引用
- [ ] MUST/MUST NOT制約を明示
- [ ] 排他性（resultとerrorの相互排他等）を説明
- [ ] 標準エラーコードの範囲を正確に記載

#### 5.4.2 コード例の検証

**検証方法**:
- 全てのコード例を実際に実行してテスト
- CPANモジュールのバージョンを明記
- 依存関係を明確に記載

#### 5.4.3 用語の統一

**推奨用語**:
- "値オブジェクト" (Value Object)
- "不変性" (Immutability)
- "等価性" (Equality)
- "ドメイン駆動設計" (Domain-Driven Design, DDD)
- "テスト駆動開発" (Test-Driven Development, TDD)

### 5.5 コードサンプルの推奨構造

#### 5.5.1 JSON-RPC Requestクラスの例

```perl
package JsonRpc::Request;
use Class::Tiny::Immutable qw(jsonrpc method params id);

sub BUILD {
    my ($self) = @_;
    
    # jsonrpcは必ず"2.0"
    die "jsonrpc must be '2.0'" unless $self->jsonrpc eq '2.0';
    
    # methodは必須
    die "method is required" unless defined $self->method;
}

# 通知かどうかを判定
sub is_notification {
    my ($self) = @_;
    return !defined $self->id;
}

1;
```

#### 5.5.2 テストの例

```perl
use Test::More;
use JsonRpc::Request;

subtest 'valid request' => sub {
    my $req = JsonRpc::Request->new(
        jsonrpc => '2.0',
        method  => 'sum',
        params  => [1, 2, 3],
        id      => 1
    );
    
    isa_ok($req, 'JsonRpc::Request');
    is($req->jsonrpc, '2.0', 'jsonrpc is 2.0');
    is($req->method, 'sum', 'method is sum');
    is_deeply($req->params, [1, 2, 3], 'params are correct');
    is($req->id, 1, 'id is 1');
    ok(!$req->is_notification, 'not a notification');
};

subtest 'notification' => sub {
    my $notif = JsonRpc::Request->new(
        jsonrpc => '2.0',
        method  => 'update'
    );
    
    ok($notif->is_notification, 'is a notification');
};

done_testing();
```

---

## 6. まとめ

### 6.1 調査の要点

1. **JSON-RPC 2.0仕様**:
   - 公式仕様書（2013年1月4日版）が権威ある情報源
   - MUST/MUST NOT制約が厳密に定義
   - Request、Response、Errorオブジェクトの構造は明確
   - 排他性と制約を正確に理解することが重要

2. **値オブジェクトパターン**:
   - Martin Fowlerらの定義が標準的
   - 不変性、等価性、カプセル化が主要特性
   - 動的型付け言語でも実装可能だが規律が必要
   - DDDの文脈で理解することが重要

3. **Perl実装**:
   - 複数の選択肢が存在（Moose、Class::Tiny::Immutable等）
   - Class::Tiny::Immutableが軽量かつ真の不変性を提供
   - JSON::RPC2が最も現代的なJSON-RPC実装
   - Curtis "Ovid" Poeのブログが実践的ガイダンスを提供

4. **TDD戦略**:
   - Test::Moreが標準的なフレームワーク
   - is_deeplyが値オブジェクトのテストに最適
   - サブテストで整理された構造を維持
   - ブラックボックステストを原則とする

### 6.2 記事執筆時の注意点

1. **正確性**:
   - 公式仕様書を引用し、解釈を明確にする
   - MUST/MUST NOT等のキーワードを正確に使用
   - コード例は全て動作検証済みであることを明記

2. **読者への配慮**:
   - 段階的な説明（Why → What → How）
   - 実行可能なコード例を提供
   - 依存関係とバージョンを明記

3. **信頼性**:
   - 一次資料（公式仕様、公式ドキュメント）を優先
   - 二次資料（ブログ、記事）は複数で相互確認
   - 著者の権威と専門性を考慮

### 6.3 追加調査の推奨事項

シリーズ執筆中に必要に応じて以下を調査することを推奨:

- 特定のCPANモジュールの詳細な使用例
- Perlバージョン間の互換性問題
- パフォーマンスベンチマーク（必要な場合）
- 実際のプロダクション使用例

---

**調査完了日**: 2025-12-15  
**次のアクション**: 本レポートを基に記事の執筆を開始
