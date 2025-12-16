---
title: "JSON-RPC 2.0仕様から学ぶ値オブジェクト設計【Perl実装】仕様書の読み方とTDD"
draft: true
tags:
  - json-rpc
  - value-object
  - perl
  - api-design
  - tdd
description: "JSON-RPC 2.0仕様書から値オブジェクトを設計する実践ガイド。RFC 2119(MUST/SHOULD/MAY)の読み解き方、不変性の担保、バリデーション実装、Perlコード例とTest2によるTDD検証まで完全解説。仕様書駆動設計の教科書的チュートリアル。"
---

この記事は「**Perlで値オブジェクトを使ってテスト駆動開発してみよう**」シリーズの第2回です。

前回は値オブジェクトの基本概念を学んだ。今回は**実際のプロトコル仕様書から値オブジェクトを設計するプロセス**を学んでいきます。題材として、シンプルで明確な仕様を持つ**JSON-RPC 2.0**を取り上げる。

{{< linkcard "https://www.nqou.net/2025/12/16/value-object-introduction-with-perl/" >}}

## JSON-RPCとは何か

**JSON-RPC**は、JSONフォーマットでエンコードされた軽量なリモートプロシージャコール（RPC）プロトコルである。WebSocketやHTTP上で動作し、クライアントとサーバー間でメソッド呼び出しを行うための標準的な方式を提供する。

### JSON-RPC 2.0の歴史と位置づけ

JSON-RPCの歴史は2005年にさかのぼる。初期のバージョンは仕様が曖昧だったが、2010年に公開された**JSON-RPC 2.0**で大幅に改善された。現在では、多くのプログラミング言語で実装され、広く採用されている。

私自身も過去にPerlでJSON-RPCライブラリを実装した経験があります。

{{< linkcard "https://www.nqou.net/2014/08/09/101454/" >}}

### REST APIとの比較

| 観点 | JSON-RPC 2.0 | REST API |
|------|--------------|----------|
| 設計思想 | メソッド呼び出し | リソース指向 |
| エンドポイント | 通常1つ | リソースごとに複数 |
| メッセージ形式 | 厳密に定義 | 自由度が高い |
| 仕様の明確さ | 非常に明確 | API設計者次第 |
| バージョン管理 | メソッド名で管理 | URLやヘッダーで管理 |

REST APIは「リソース」という概念を中心に設計されるのに対し、JSON-RPCは「メソッド呼び出し」という従来のRPC思想に基づいている。JSON-RPCの方がプログラミング言語のメソッド呼び出しに近い感覚で扱える。

### 主な採用事例

**Ethereum**
- ブロックチェーンノードとの通信（Ethereum JSON-RPC API）

**Visual Studio Code**
- Language Server Protocol（LSP）の実装
- エディタと言語サーバー間の通信基盤

**Bitcoin Core**
- ビットコインノードとのインターフェース

**OpenStack**
- クラウド基盤の内部通信

特に、Language Server ProtocolではJSON-RPC 2.0が標準プロトコルとして採用されており、現代のエディタ開発において重要な役割を果たしている。

## なぜ値オブジェクトの題材として最適なのか

JSON-RPC 2.0は、値オブジェクト設計の学習に最適な以下の特徴を持っている。

### 1. 明確な仕様

JSON-RPC 2.0の仕様は非常にシンプルで、わずか数ページで完全に定義されている。

**MUST**（必須）、**SHOULD**（推奨）、**MAY**（任意）といったRFC 2119準拠のキーワードで要件が明確に記述されており、仕様書を読み解く訓練にも最適である。

{{< linkcard "https://www.jsonrpc.org/specification" >}}

### 2. 固定された構造

Request objectとResponse objectの構造が厳密に定義されており、不正な形式のメッセージは明確に拒否される。

この「**不正なデータは存在させない**」という思想は、値オブジェクトの設計思想と完全に一致します。

### 3. 不変性との親和性

JSON-RPCのメッセージは一度作成されたら変更されません。リクエストは送信され、レスポンスは返される。

この性質は、値オブジェクトの**不変性（Immutability）**という特性と自然に調和します。

### 4. 厳密なバリデーションルール

仕様には、各フィールドの型、必須/オプション、値の制約が明確に定義されている。

これらをそのまま値オブジェクトのバリデーションルールとして実装できます。

## JSON-RPC 2.0仕様の構造分析

それでは、JSON-RPC 2.0の仕様を詳しく見ていきましょう。仕様書を読み解きながら、値オブジェクトとして実装すべき要素を抽出していく。

### Request objectの必須/オプション要素

JSON-RPCのリクエストは、以下の構造を持つJSONオブジェクトです。

```json
{
  "jsonrpc": "2.0",
  "method": "sum",
  "params": [42, 23],
  "id": 1
}
```

仕様書から各フィールドの制約を抽出すると、以下のようになります。

### jsonrpc（必須フィールド）

- **制約**: 文字列 `"2.0"` でなければならない（**MUST**）
- **意図**: プロトコルバージョンの明示的な指定
- **設計への影響**: 固定値の値オブジェクトとして実装すべき

仕様書には以下のように記述されている。

> A String specifying the version of the JSON-RPC protocol. **MUST** be exactly "2.0".

この**MUST**というキーワードが重要です。RFC 2119では、MUSTは「絶対的な要件」を意味し、違反すると仕様非準拠となります。

### method（必須フィールド）

- **制約**: 呼び出すメソッド名を含む文字列（**MUST**）
- **追加制約**: `rpc.` で始まるメソッド名はシステム用に予約されている
- **設計への影響**: 文字列型の値オブジェクトとして、予約語チェックを含めるべき

> A String containing the name of the method to be invoked. Method names that begin with the word rpc followed by a period character (U+002E or ASCII 46) are reserved for rpc-internal methods and extensions and **MUST NOT** be used for anything else.

ここでも**MUST NOT**が使われており、この制約を破ることは許されない。

### params（オプションフィールド）

- **制約**: 構造化された値（配列またはオブジェクト）（**MAY**）
- **省略可能**: 存在しない場合もある
- **設計への影響**: `Option<Params>` のような型で表現すべき

> A Structured value that holds the parameter values to be used during the invocation of the method. This member **MAY** be omitted.

**MAY**は「任意」を意味する。パラメータが必要ないメソッド呼び出しも存在するため、このフィールドは省略可能である。

### id（オプションフィールド）

- **制約**: 文字列、数値、またはNULL（**SHOULD**）
- **追加制約**: NULLを含んではならない（通知を除く）
- **設計への影響**: 通知（Notification）とリクエストで型を分けるべき

> An identifier established by the Client that **MUST** contain a String, Number, or NULL value if included. If it is not included it is assumed to be a notification.

IDが含まれない場合は「通知（Notification）」とみなされ、サーバーからのレスポンスは期待されない。

## Response object（成功時/エラー時）

レスポンスには、成功時とエラー時で異なる構造があります。

### 成功時のResponse

```json
{
  "jsonrpc": "2.0",
  "result": 65,
  "id": 1
}
```

**jsonrpc**
- `"2.0"` 固定（**MUST**）

**result**
- メソッド実行の結果（**REQUIRED**）

**id**
- リクエストのIDと同じ値（**REQUIRED**）

**error**
- 存在してはならない（**MUST NOT**）

### エラー時のResponse

```json
{
  "jsonrpc": "2.0",
  "error": {
    "code": -32600,
    "message": "Invalid Request"
  },
  "id": null
}
```

**jsonrpc**
- `"2.0"` 固定（**MUST**）

**error**
- エラーオブジェクト（**REQUIRED**）

**id**
- リクエストのIDまたはNULL（**REQUIRED**）

**result**
- 存在してはならない（**MUST NOT**）

### 重要な排他性の制約

仕様書には以下のように記述されている。

> Either the result member or error member **MUST** be included, but both members **MUST NOT** be included.

`result`と`error`は**排他的**です。両方が存在することは許されない。

これは、値オブジェクト設計において**型で表現すべき重要な制約**です。

## Error objectと標準エラーコード

エラーオブジェクトは、以下の構造を持つ。

```json
{
  "code": -32600,
  "message": "Invalid Request",
  "data": "Additional error information"
}
```

### code（必須フィールド）

**制約**
- エラーの種類を示す整数（**MUST**）

**範囲**
- -32768 〜 -32000 は予約済み

仕様で定義された標準エラーコードは以下の通りです。

| コード | メッセージ | 意味 |
|--------|-----------|------|
| -32700 | Parse error | 無効なJSONを受信 |
| -32600 | Invalid Request | JSONはパースできたが、リクエストオブジェクトとして無効 |
| -32601 | Method not found | 指定されたメソッドが存在しない |
| -32602 | Invalid params | メソッドパラメータが無効 |
| -32603 | Internal error | サーバー内部エラー |

これらのエラーコードも、列挙型（enum）として値オブジェクト化できます。

### message（必須フィールド）

**制約**
- エラーの短い説明を含む文字列（**MUST**）

**推奨**
- 標準エラーコードには対応するメッセージを使用すべき（**SHOULD**）

### data（オプションフィールド）

**制約**
- エラーに関する追加情報（**MAY**）

**型**
- プリミティブ値または構造化された値

## 値オブジェクトとしての設計方針

仕様を理解したところで、値オブジェクトとして設計する方針を考えていこう。

### どの要素を値オブジェクト化するか

JSON-RPC 2.0の仕様から、以下の値オブジェクトを抽出できます。

1. **JsonRpcVersion**: プロトコルバージョン（常に `"2.0"`）
2. **MethodName**: メソッド名（`rpc.` 予約語チェック付き）
3. **RequestId**: リクエストID（文字列、数値、またはNULL）
4. **Request**: リクエストオブジェクト全体
5. **Response**: レスポンスオブジェクト全体（成功/エラーの排他性）
6. **Error**: エラーオブジェクト
7. **ErrorCode**: 標準エラーコード

この中で、最もシンプルなのは**JsonRpcVersion**です。常に固定値 `"2.0"` を持つため、値オブジェクトの入門として最適です。

### 不変性をどう担保するか

値オブジェクトの不変性は、Mooの`is => 'ro'`（read-only）を使って実現します。

```perl
has jsonrpc => (
    is       => 'ro',  # 読み取り専用 = 不変
    default  => '2.0',
    required => 1,
);
```

**コンストラクタでの完全初期化**

不変性を保証するには、オブジェクト生成時にすべての属性を初期化する必要があります。

Mooでは、`required => 1`または`default`を使って、すべてのフィールドが必ず値を持つことを保証できます。

```perl
# すべてのフィールドが初期化されている
my $request = JsonRpcRequest->new(
    jsonrpc => '2.0',
    method  => 'sum',
    params  => [42, 23],
    id      => 1,
);

# 後から変更できない（コンパイルエラー）
# $request->method('multiply');  # エラー！
```

### バリデーションルールの抽出

仕様書から制約を読み取る際は、**RFC 2119のキーワード**に注目します。

### MUST / MUST NOT（絶対的要件）

- **MUST**: 絶対に満たさなければならない
- **MUST NOT**: 絶対にしてはならない

これらの制約は、コンストラクタまたは`isa`でバリデーションエラーとして実装します。

```perl
has jsonrpc => (
    is  => 'ro',
    isa => sub {
        die "jsonrpc MUST be '2.0'" unless $_[0] eq '2.0';
    },
);
```

### SHOULD / SHOULD NOT（推奨）

**SHOULD**
- 特別な理由がない限り従うべき

**SHOULD NOT**
- 特別な理由がない限り避けるべき

これらは警告（warning）として実装することもできるが、値オブジェクトではMUSTと同様に扱うことが多い。

### MAY（任意）

**MAY**
- してもしなくてもよい

これらは`Option`型やデフォルト値で表現します。

```perl
has params => (
    is        => 'ro',
    predicate => 'has_params',  # 存在チェック用メソッド
);
```

## 最初の値オブジェクト設計: JsonRpcVersion

それでは、最もシンプルな値オブジェクト`JsonRpcVersion`を実装してみましょう。

### 常に "2.0" という制約を型で表現

JSON-RPC 2.0では、`jsonrpc`フィールドは常に文字列`"2.0"`でなければならない。

この制約を値オブジェクトとして実装することで、以下のメリットが得られる。

1. **型安全性**: 不正な値を持つインスタンスを作れない
2. **ドキュメント性**: コードが仕様を表現している
3. **バグの早期発見**: コンパイル時または実行時に即座にエラーが検出される

一見すると、固定値を値オブジェクトにすることは過剰に思えるかもしれない。しかし、以下のような場合を考えてみてください。

```perl
# 悪い例: 文字列を直接使う
sub send_request {
    my ($method, $params, $id) = @_;
    my $request = {
        jsonrpc => '2.0',  # ここでタイポしたら？
        method  => $method,
        params  => $params,
        id      => $id,
    };
    # ...
}

# タイポの例
my $request = { jsonrpc => '2.1' };  # バグだが、気づきにくい
```

値オブジェクトを使えば、このようなタイポやバグを防げる。

```perl
# 良い例: 値オブジェクトを使う
my $version = JsonRpcVersion->new();  # 常に "2.0"
my $request = {
    jsonrpc => $version->value,
    # ...
};
```

### シンプルな値オブジェクトの実装例

それでは、完全な実装とテストコードを見ていきましょう。

**実装: lib/JsonRpc/Version.pm**

```perl
package JsonRpc::Version;
use v5.38;
use Moo;
use namespace::clean;

# プロトコルバージョン（常に "2.0"）
has value => (
    is      => 'ro',
    default => '2.0',
    isa     => sub {
        die "JSON-RPC version MUST be '2.0', got '$_[0]'"
            unless defined $_[0] && $_[0] eq '2.0';
    },
);

# 値による等価性
sub equals {
    my ($self, $other) = @_;
    return 0 unless $other->isa(__PACKAGE__);
    return $self->value eq $other->value;
}

# 文字列化
sub to_string {
    my $self = shift;
    return $self->value;
}

1;

__END__

=head1 NAME

JsonRpc::Version - JSON-RPC protocol version value object

=head1 SYNOPSIS

    use JsonRpc::Version;
    
    # Create version object (always "2.0")
    my $version = JsonRpc::Version->new();
    say $version->value;  # "2.0"
    
    # Attempting to create with invalid version fails
    eval {
        my $invalid = JsonRpc::Version->new(value => '1.0');
    };
    say $@ if $@;  # Error: JSON-RPC version MUST be '2.0'

=head1 DESCRIPTION

This module implements a value object for JSON-RPC 2.0 protocol version.
According to the JSON-RPC 2.0 specification, the version MUST be exactly "2.0".

This value object ensures:

=over 4

=item * Immutability - version cannot be changed after creation

=item * Validity - only "2.0" is accepted

=item * Type safety - prevents typos and invalid versions

=back

=head1 METHODS

=head2 value

Returns the protocol version string (always "2.0").

=head2 equals($other)

Compares this version with another Version object for equality.

=head2 to_string

Returns the string representation of the version.

=head1 SPECIFICATION

L<https://www.jsonrpc.org/specification>

=cut
```

**テストコード: t/jsonrpc/version.t**

```perl
use Test2::V0;
use lib 'lib';
use JsonRpc::Version;

subtest 'default construction creates valid version' => sub {
    my $version = JsonRpc::Version->new();
    
    ok $version, 'version object created';
    is $version->value, '2.0', 'version is "2.0"';
    is $version->to_string, '2.0', 'to_string returns "2.0"';
};

subtest 'explicit version "2.0" is accepted' => sub {
    my $version = JsonRpc::Version->new(value => '2.0');
    
    ok $version, 'version object created with explicit value';
    is $version->value, '2.0', 'version is "2.0"';
};

subtest 'invalid versions are rejected' => sub {
    subtest 'version "1.0" is rejected' => sub {
        like(
            dies { JsonRpc::Version->new(value => '1.0') },
            qr/JSON-RPC version MUST be '2\.0'/,
            'version 1.0 throws error'
        );
    };
    
    subtest 'version "2.1" is rejected' => sub {
        like(
            dies { JsonRpc::Version->new(value => '2.1') },
            qr/JSON-RPC version MUST be '2\.0'/,
            'version 2.1 throws error'
        );
    };
    
    subtest 'empty string is rejected' => sub {
        like(
            dies { JsonRpc::Version->new(value => '') },
            qr/JSON-RPC version MUST be '2\.0'/,
            'empty string throws error'
        );
    };
    
    subtest 'undef is rejected' => sub {
        like(
            dies { JsonRpc::Version->new(value => undef) },
            qr/JSON-RPC version MUST be '2\.0'/,
            'undef throws error'
        );
    };
};

subtest 'immutability' => sub {
    my $version = JsonRpc::Version->new();
    
    like(
        dies { $version->value('3.0') },
        qr/Usage:/,
        'cannot modify version (read-only)'
    );
};

subtest 'equality comparison' => sub {
    my $version1 = JsonRpc::Version->new();
    my $version2 = JsonRpc::Version->new();
    
    ok $version1->equals($version2), 
        'two version objects are equal';
    
    # 同じ値なので等価
    ok $version1->equals($version1), 
        'version equals itself';
};

subtest 'value object characteristics' => sub {
    my $v1 = JsonRpc::Version->new();
    my $v2 = JsonRpc::Version->new();
    
    # 値による等価性
    ok $v1->equals($v2), 'equality by value';
    
    # 不変性
    is $v1->value, '2.0', 'immutable value preserved';
    
    # 型安全性
    ok $v1->isa('JsonRpc::Version'), 'correct type';
};

done_testing;
```

### コードのポイント解説

**1. デフォルト値の活用**

```perl
has value => (
    is      => 'ro',
    default => '2.0',  # デフォルト値を指定
    # ...
);
```

`default`を指定することで、`JsonRpc::Version->new()`のように引数なしで呼び出しても、常に`"2.0"`が設定される。

**2. バリデーションの厳密性**

```perl
isa => sub {
    die "JSON-RPC version MUST be '2.0', got '$_[0]'"
        unless defined $_[0] && $_[0] eq '2.0';
},
```

`defined`チェックを含めることで、`undef`も明示的に拒否している。エラーメッセージには実際に渡された値も含めることで、デバッグしやすくしている。

**3. PODドキュメント**

実装の最後に`__END__`以降でPODドキュメントを記述している。値オブジェクトの目的、使い方、仕様へのリンクを含めることで、保守性が向上します。

**4. テストの網羅性**

テストでは、正常系だけでなく、考えられる異常系をすべてカバーしている。

**正常系**
- デフォルト構築、明示的な`"2.0"`の指定

**異常系**
- `"1.0"`, `"2.1"`, 空文字列, `undef`

**特性の検証**
- 不変性、等価性、型安全性

### テストの実行

```bash
$ prove -lv t/jsonrpc/version.t
t/jsonrpc/version.t .. 
    # Subtest: default construction creates valid version
    ok 1 - version object created
    ok 2 - version is "2.0"
    ok 3 - to_string returns "2.0"
    1..3
ok 1 - default construction creates valid version
    # Subtest: explicit version "2.0" is accepted
    ok 1 - version object created with explicit value
    ok 2 - version is "2.0"
    1..2
ok 2 - explicit version "2.0" is accepted
    # Subtest: invalid versions are rejected
        # Subtest: version "1.0" is rejected
        ok 1 - version 1.0 throws error
        1..1
    ok 1 - version "1.0" is rejected
    # ... (以下略)
ok 3 - invalid versions are rejected
ok 4 - immutability
ok 5 - equality comparison
ok 6 - value object characteristics
1..6
ok
All tests successful.
```

## まとめと次回予告

### 本記事で学んだこと

この記事では、JSON-RPC 2.0の仕様から値オブジェクトを設計するプロセスを学んだ。

1. **仕様書の読み方**: MUST/SHOULD/MAYのキーワードで制約を抽出
2. **制約の型表現**: 仕様の制約を値オブジェクトのバリデーションとして実装
3. **シンプルな値オブジェクト**: `JsonRpcVersion`を完全に実装
4. **テスト駆動**: 正常系・異常系を含む網羅的なテストの書き方

特に重要なのは、**仕様書が値オブジェクト設計の最良のガイド**であるという点です。

RFC 2119準拠の仕様書は、そのまま実装の要求仕様として読み解ける。

### 値オブジェクト設計のプロセス

今回実践したプロセスをまとめると、以下のようになります。

```
1. 仕様書を読む
   ↓
2. MUST/SHOULD/MAYで制約を抽出
   ↓
3. 制約を型とバリデーションルールに変換
   ↓
4. 不変性と値による等価性を実装
   ↓
5. 網羅的なテストで検証
```

このプロセスは、JSON-RPC以外のあらゆる仕様から値オブジェクトを設計する際にも応用できます。

### 次回予告：Test2によるTDD実践

次回は「**Test2でTDDを実践しよう - 値オブジェクトのテスト戦略**」と題して、テスト駆動開発（TDD）の実践的なワークフローを学びます。

- **Red-Green-Refactorサイクル**の実践
- `MethodName`値オブジェクトのTDD実装
- テストファーストで設計する方法
- Test2の高度な機能（モック、テストデータビルダー）

お楽しみに！

## 参考リンク

- {{< linkcard "https://www.jsonrpc.org/specification" >}}
- {{< linkcard "https://www.rfc-editor.org/rfc/rfc2119" >}}
- {{< linkcard "https://metacpan.org/pod/Moo" >}}
- {{< linkcard "https://metacpan.org/pod/Test2::V0" >}}

## シリーズ記事

1. [値オブジェクトって何だろう？ - DDDの基本概念とPerlでの実装入門](/2025/12/16/value-object-introduction-with-perl/)
2. **JSON-RPC 2.0で学ぶ値オブジェクト設計 - 仕様から設計へ**（この記事）
3. Test2でTDDを実践しよう - 値オブジェクトのテスト戦略（次回）
4. JSON-RPC Request/Response値オブジェクトの実装 - 複合的な値オブジェクト
5. エラー処理と境界値テスト - 堅牢な値オブジェクトを作る
