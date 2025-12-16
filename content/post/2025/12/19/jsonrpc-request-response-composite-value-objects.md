---
title: "JSON-RPC Request/Response実装 - 複合値オブジェクト設計【Perl×TDD】"
draft: false
tags:
  - json-rpc
  - perl
  - tdd
  - type-tiny
  - value-object
  - moo
description: "PerlでJSON-RPC 2.0のRequest/Responseを複合値オブジェクトとして実装。Type::TinyのMaybe型とInstanceOf、from_hashファクトリーメソッドによる実践的なTDD開発手法を解説。"
series: "Perlで値オブジェクトを使ってテスト駆動開発してみよう"
series_order: 4
---

この記事は「**Perlで値オブジェクトを使ってテスト駆動開発してみよう**」シリーズの**第4回（全5回）**である。前回は、[Test2によるTDD実践とMethodName値オブジェクト](/2025/12/18/test2-tdd-value-object-testing-strategy/)の実装を通じて、Red-Green-Refactorサイクルを体験した。今回は、**複数の値オブジェクトを組み合わせた複合的な値オブジェクト**として、JSON-RPC 2.0のRequestとResponseを完全実装する。

> **シリーズナビゲーション**  
> ← 前回: [PerlのTest2でTDD実践 - 値オブジェクトのテスト戦略](/2025/12/18/test2-tdd-value-object-testing-strategy/)  
> → 次回: エラー処理と境界値テスト - 堅牢な値オブジェクトを作る（公開予定）

## この記事で学べること

- **複合値オブジェクトの設計**: 単純な値オブジェクトを組み合わせた設計パターン
- **Type::Tinyの実践活用**: Maybe、ArrayRef、HashRef、InstanceOfなどの型制約
- **TDDで進める複雑な実装**: 必須/オプションフィールドのテスト戦略
- **ファクトリーメソッドパターン**: from_hashによるJSON→オブジェクト変換の実装
- **JSON-RPC 2.0仕様の実装**: Request/Responseオブジェクトの完全実装

## 複合値オブジェクトとは - JSON-RPCを題材に理解する

### 単純な値オブジェクトと複合値オブジェクトの違い

これまで実装してきたのは**単純な値オブジェクト**である。これらは、単一のプリミティブ型（文字列や数値）をラップしたものである。

```perl
# 単純な値オブジェクト - 文字列をラップ
package JsonRpc::MethodName;
use Moo;

has value => (
    is  => 'ro',
    isa => sub { ... },  # 文字列のバリデーション
);
```

一方、**複合値オブジェクト**（Composite Value Object）は、複数のフィールドを持ち、それぞれが独自の値オブジェクトや型制約を持つ。JSON-RPC 2.0のRequest/Responseオブジェクトは、この複合値オブジェクトの典型例である。

```perl
# 複合的な値オブジェクト - 複数フィールドと値オブジェクトを組み合わせ
package JsonRpc::Request;
use Moo;

has jsonrpc => (is => 'ro', isa => InstanceOf['JsonRpc::Version']);
has method  => (is => 'ro', isa => InstanceOf['JsonRpc::MethodName']);
has params  => (is => 'ro', isa => Maybe[ArrayRef|HashRef]);  # オプション
has id      => (is => 'ro', isa => Maybe[Str|Int]);            # オプション
```

### 値オブジェクトのネスト構造

JSON-RPC Requestオブジェクトは以下のような階層構造を持つ。

```text
JsonRpc::Request
├── jsonrpc: JsonRpc::Version (値オブジェクト)
├── method:  JsonRpc::MethodName (値オブジェクト)
├── params:  ArrayRef | HashRef | undef (オプション)
└── id:      Str | Int | undef (オプション)
```

このように、**値オブジェクトが他の値オブジェクトを含む**構造を、複合値オブジェクトと呼ぶ。JSON-RPCの実装において、この構造は以下のメリットをもたらす。

- **責任の分離**: 各値オブジェクトが独自のバリデーションを担当
- **再利用性**: JsonRpc::VersionやMethodNameは他のコンテキストでも使える
- **型安全性**: Type::Tinyによる厳密な型チェック
- **保守性**: 変更箇所が局所化され、影響範囲が限定される

## Type::Tinyによる型制約の実践 - Perlに型安全性をもたらす

Type::Tinyは、Perlに強力な型システムを導入するモジュールであり、JSON-RPC Request/Responseのような複合値オブジェクトの実装には不可欠なツールである。TDD開発において、Type::Tinyの型制約は「実行可能な仕様書」として機能する。

### Type::Tinyの基本型

```perl
use Types::Standard qw(
    Str Int Num Bool
    ArrayRef HashRef Maybe
    InstanceOf Enum Any
);

# 基本型
has name => (is => 'ro', isa => Str);           # 文字列
has age  => (is => 'ro', isa => Int);           # 整数
has rate => (is => 'ro', isa => Num);           # 数値（小数含む）
has flag => (is => 'ro', isa => Bool);          # 真偽値

# 参照型
has items  => (is => 'ro', isa => ArrayRef);        # 配列リファレンス
has config => (is => 'ro', isa => HashRef);         # ハッシュリファレンス

# 型パラメータ付き
has numbers => (is => 'ro', isa => ArrayRef[Int]);  # 整数の配列
has mapping => (is => 'ro', isa => HashRef[Str]);   # 文字列のハッシュ

# オブジェクト型
has version => (is => 'ro', isa => InstanceOf['JsonRpc::Version']);

# オプショナル（Maybe）
has optional_name => (is => 'ro', isa => Maybe[Str]);  # Str または undef
```

### Type::Tinyのインストール

```bash
# CPANからインストール
cpanm Type::Tiny

# または cpan コマンド
cpan Type::Tiny
```

基本的な使い方は以下のとおりである。

```perl
use Types::Standard qw(:all);

# 基本的な使い方
my $check_int = Int->check(42);        # true
my $check_str = Str->check("hello");   # true
my $check_arr = ArrayRef->check([]);   # true

# バリデーション（例外発生）
Int->assert_valid(42);          # OK
Int->assert_valid("string");    # 例外: Value "string" did not pass type constraint "Int"
```

### JSON-RPC 2.0仕様に必要な型定義

JSON-RPC 2.0の仕様に基づいて、カスタム型制約を定義していく。これにより、JSON-RPC固有のバリデーションルールを型システムで表現できる。

```perl
package JsonRpc::Types;
use v5.38;
use Type::Library -base;
use Types::Standard qw(:all);

use Type::Utils -all;

# JsonRpcParams型 - ArrayRef または HashRef
declare "JsonRpcParams",
    as ArrayRef | HashRef;

# JsonRpcId型 - Str, Int, Null のいずれか（ただしNull以外）
declare "JsonRpcId",
    as Str | Int;

# JsonRpcVersion型 - "2.0" という文字列のみ
declare "JsonRpcVersion",
    as Str,
    where { $_ eq '2.0' },
    message { "JSON-RPC version must be '2.0', got '$_'" };

1;

__END__

=head1 NAME

JsonRpc::Types - Type constraints for JSON-RPC 2.0

=head1 SYNOPSIS

    use JsonRpc::Types qw(JsonRpcParams JsonRpcId JsonRpcVersion);
    
    has params => (is => 'ro', isa => Maybe[JsonRpcParams]);
    has id     => (is => 'ro', isa => Maybe[JsonRpcId]);

=head1 DESCRIPTION

This module provides custom type constraints for JSON-RPC 2.0 implementation.

=cut
```

このように、Type::Libraryを使用して独自の型を定義できる。

### Maybe型でオプショナルフィールドを表現する - JSON-RPC仕様の実装

JSON-RPC 2.0仕様では、`params`と`id`はオプショナルフィールドである。PerlでこれをType::Tinyの`Maybe`型で厳密に表現する。

```perl
use Types::Standard qw(Maybe Str Int ArrayRef HashRef);

# Maybe[型] は「型 または undef」を意味する
has params => (
    is  => 'ro',
    isa => Maybe[ArrayRef | HashRef],
);

has id => (
    is  => 'ro',
    isa => Maybe[Str | Int],
);

# 使用例
my $req1 = Request->new(
    jsonrpc => $version,
    method  => $method,
    params  => [1, 2, 3],   # ArrayRef - OK
    id      => "req-123",   # Str - OK
);

my $req2 = Request->new(
    jsonrpc => $version,
    method  => $method,
    params  => undef,       # Maybe[...] なので undef OK
    id      => undef,       # Maybe[...] なので undef OK
);

my $req3 = Request->new(
    jsonrpc => $version,
    method  => $method,
    # params と id は省略可能（自動的に undef）
);
```

## JsonRpc::Request値オブジェクトのTDD実装

それでは、TDDでJSON-RPC 2.0のRequest値オブジェクトを実装していく。前回学んだRed-Green-Refactorサイクルを適用し、複合値オブジェクトならではのテスト戦略を実践する。

### JSON-RPC 2.0 Request仕様の確認

まず、[JSON-RPC 2.0仕様書](https://www.jsonrpc.org/specification)を確認する。Request objectは以下のフィールドを持つ。

| フィールド | 型 | 必須/オプション | 説明 |
|-----------|-----|----------------|------|
| jsonrpc | String | 必須 | "2.0" 固定 |
| method | String | 必須 | 呼び出すメソッド名 |
| params | Array or Object | オプション | メソッドのパラメータ |
| id | String, Number, Null | オプション | リクエストID（通知の場合は省略） |

{{< linkcard "https://www.jsonrpc.org/specification" >}}

### Red - 失敗するテストを書く

まず、Requestのテストを書く。

```perl
# t/request.t
use v5.38;
use Test2::V0;
use lib 'lib';

use_ok 'JsonRpc::Request' or die;
use JsonRpc::Version;
use JsonRpc::MethodName;

subtest 'constructor with required fields only' => sub {
    my $req = JsonRpc::Request->new(
        jsonrpc => JsonRpc::Version->new(value => '2.0'),
        method  => JsonRpc::MethodName->new(value => 'getUser'),
    );
    
    ok $req, 'Request created with required fields';
    isa_ok $req->jsonrpc, 'JsonRpc::Version';
    isa_ok $req->method,  'JsonRpc::MethodName';
    is $req->params, undef, 'params is undef by default';
    is $req->id,     undef, 'id is undef by default';
};

subtest 'constructor with all fields' => sub {
    my $req = JsonRpc::Request->new(
        jsonrpc => JsonRpc::Version->new(value => '2.0'),
        method  => JsonRpc::MethodName->new(value => 'createUser'),
        params  => { name => 'Alice', age => 30 },
        id      => 'req-001',
    );
    
    ok $req, 'Request created with all fields';
    is $req->params, { name => 'Alice', age => 30 }, 'params is hash';
    is $req->id, 'req-001', 'id is string';
};

subtest 'constructor rejects invalid jsonrpc' => sub {
    like(
        dies {
            JsonRpc::Request->new(
                jsonrpc => "not a Version object",
                method  => JsonRpc::MethodName->new(value => 'test'),
            );
        },
        qr/type constraint|isa/i,
        'rejects non-Version jsonrpc'
    );
};

subtest 'constructor rejects invalid method' => sub {
    like(
        dies {
            JsonRpc::Request->new(
                jsonrpc => JsonRpc::Version->new(value => '2.0'),
                method  => "not a MethodName object",
            );
        },
        qr/type constraint|isa/i,
        'rejects non-MethodName method'
    );
};

subtest 'params accepts array or hash or undef' => sub {
    my $version = JsonRpc::Version->new(value => '2.0');
    my $method  = JsonRpc::MethodName->new(value => 'test');
    
    # ArrayRef
    ok(lives {
        JsonRpc::Request->new(
            jsonrpc => $version,
            method  => $method,
            params  => [1, 2, 3],
        );
    }, 'params accepts ArrayRef');
    
    # HashRef
    ok(lives {
        JsonRpc::Request->new(
            jsonrpc => $version,
            method  => $method,
            params  => { key => 'value' },
        );
    }, 'params accepts HashRef');
    
    # undef
    ok(lives {
        JsonRpc::Request->new(
            jsonrpc => $version,
            method  => $method,
            params  => undef,
        );
    }, 'params accepts undef');
    
    # String は拒否
    like(dies {
        JsonRpc::Request->new(
            jsonrpc => $version,
            method  => $method,
            params  => "string",
        );
    }, qr/type constraint/i, 'params rejects string');
};

subtest 'id accepts string, int, or undef' => sub {
    my $version = JsonRpc::Version->new(value => '2.0');
    my $method  = JsonRpc::MethodName->new(value => 'test');
    
    ok(lives {
        JsonRpc::Request->new(jsonrpc => $version, method => $method, id => 'str-id');
    }, 'id accepts string');
    
    ok(lives {
        JsonRpc::Request->new(jsonrpc => $version, method => $method, id => 123);
    }, 'id accepts integer');
    
    ok(lives {
        JsonRpc::Request->new(jsonrpc => $version, method => $method, id => undef);
    }, 'id accepts undef');
    
    like(dies {
        JsonRpc::Request->new(jsonrpc => $version, method => $method, id => []);
    }, qr/type constraint/i, 'id rejects array reference');
};

done_testing;
```

テストを実行すると、当然失敗する（Red）。

```bash
$ prove -lv t/request.t
Can't locate JsonRpc/Request.pm in @INC
```

### Green - 最小実装で通す

次に、テストを通すための実装を書く。

```perl
# lib/JsonRpc/Request.pm
package JsonRpc::Request;
use v5.38;
use Moo;
use Types::Standard qw(InstanceOf Maybe ArrayRef HashRef Str Int);
use namespace::clean;

has jsonrpc => (
    is       => 'ro',
    isa      => InstanceOf['JsonRpc::Version'],
    required => 1,
);

has method => (
    is       => 'ro',
    isa      => InstanceOf['JsonRpc::MethodName'],
    required => 1,
);

has params => (
    is  => 'ro',
    isa => Maybe[ArrayRef | HashRef],
);

has id => (
    is  => 'ro',
    isa => Maybe[Str | Int],
);

1;

__END__

=head1 NAME

JsonRpc::Request - JSON-RPC 2.0 Request object

=head1 SYNOPSIS

    use JsonRpc::Request;
    use JsonRpc::Version;
    use JsonRpc::MethodName;
    
    my $req = JsonRpc::Request->new(
        jsonrpc => JsonRpc::Version->new(value => '2.0'),
        method  => JsonRpc::MethodName->new(value => 'getUser'),
        params  => { user_id => 42 },
        id      => 'req-123',
    );

=head1 DESCRIPTION

Represents a JSON-RPC 2.0 Request object with validation.

=cut
```

テストを再実行すると、すべて成功する（Green）！

```bash
$ prove -lv t/request.t
ok 1 - use JsonRpc::Request;
    # Subtest: constructor with required fields only
    ok 1 - Request created with required fields
    ok 2 - An object of class 'JsonRpc::Version'
    ok 3 - An object of class 'JsonRpc::MethodName'
    ok 4 - params is undef by default
    ok 5 - id is undef by default
    1..5
ok 2 - constructor with required fields only
...
All tests successful.
```

### Refactor - from_hashファクトリーメソッドの追加

実際のJSON-RPCアプリケーションでは、JSONをデコードした結果（ハッシュリファレンス）から直接Requestオブジェクトを生成する必要がある。ファクトリーメソッドパターンを適用し、`from_hash`メソッドを追加する。

```perl
# lib/JsonRpc/Request.pm
package JsonRpc::Request;
use v5.38;
use Moo;
use Types::Standard qw(InstanceOf Maybe ArrayRef HashRef Str Int Dict);
use JsonRpc::Version;
use JsonRpc::MethodName;
use namespace::clean;

has jsonrpc => (
    is       => 'ro',
    isa      => InstanceOf['JsonRpc::Version'],
    required => 1,
);

has method => (
    is       => 'ro',
    isa      => InstanceOf['JsonRpc::MethodName'],
    required => 1,
);

has params => (
    is  => 'ro',
    isa => Maybe[ArrayRef | HashRef],
);

has id => (
    is  => 'ro',
    isa => Maybe[Str | Int],
);

# ファクトリーメソッド: HashRef から Request を生成
sub from_hash {
    my ($class, $hash) = @_;
    
    die "from_hash requires a hash reference"
        unless ref $hash eq 'HASH';
    
    # 必須フィールドの存在チェック
    die "missing required field: jsonrpc"
        unless exists $hash->{jsonrpc};
    die "missing required field: method"
        unless exists $hash->{method};
    
    return $class->new(
        jsonrpc => JsonRpc::Version->new(value => $hash->{jsonrpc}),
        method  => JsonRpc::MethodName->new(value => $hash->{method}),
        exists $hash->{params} ? (params => $hash->{params}) : (),
        exists $hash->{id}     ? (id     => $hash->{id})     : (),
    );
}

# JSON文字列への変換
sub to_hash {
    my $self = shift;
    
    my $hash = {
        jsonrpc => $self->jsonrpc->value,
        method  => $self->method->value,
    };
    
    $hash->{params} = $self->params if defined $self->params;
    $hash->{id}     = $self->id     if defined $self->id;
    
    return $hash;
}

1;

__END__

=head1 METHODS

=head2 from_hash

Creates a Request object from a hash reference (typically from decoded JSON).

    my $req = JsonRpc::Request->from_hash({
        jsonrpc => '2.0',
        method  => 'getUser',
        params  => { user_id => 42 },
        id      => 'req-123',
    });

=head2 to_hash

Converts the Request object back to a hash reference suitable for JSON encoding.

    my $hash = $req->to_hash;
    # { jsonrpc => '2.0', method => 'getUser', ... }

=cut
```

### from_hashのテスト追加

```perl
# t/request.t に追加

subtest 'from_hash factory method' => sub {
    subtest 'creates request from hash' => sub {
        my $req = JsonRpc::Request->from_hash({
            jsonrpc => '2.0',
            method  => 'getUser',
            params  => { user_id => 42 },
            id      => 'req-001',
        });
        
        ok $req, 'Request created from hash';
        is $req->jsonrpc->value, '2.0', 'jsonrpc is correct';
        is $req->method->value, 'getUser', 'method is correct';
        is $req->params, { user_id => 42 }, 'params is correct';
        is $req->id, 'req-001', 'id is correct';
    };
    
    subtest 'from_hash with minimal fields' => sub {
        my $req = JsonRpc::Request->from_hash({
            jsonrpc => '2.0',
            method  => 'notify',
        });
        
        ok $req, 'Request created with minimal fields';
        is $req->params, undef, 'params defaults to undef';
        is $req->id, undef, 'id defaults to undef';
    };
    
    subtest 'from_hash rejects missing required fields' => sub {
        like(dies {
            JsonRpc::Request->from_hash({ method => 'test' });
        }, qr/missing.*jsonrpc/i, 'missing jsonrpc rejected');
        
        like(dies {
            JsonRpc::Request->from_hash({ jsonrpc => '2.0' });
        }, qr/missing.*method/i, 'missing method rejected');
    };
    
    subtest 'from_hash rejects non-hash' => sub {
        like(dies {
            JsonRpc::Request->from_hash("not a hash");
        }, qr/hash reference/i, 'string rejected');
        
        like(dies {
            JsonRpc::Request->from_hash([]);
        }, qr/hash reference/i, 'array rejected');
    };
};

subtest 'to_hash converts back to hash' => sub {
    my $req = JsonRpc::Request->from_hash({
        jsonrpc => '2.0',
        method  => 'createUser',
        params  => { name => 'Bob' },
        id      => 123,
    });
    
    my $hash = $req->to_hash;
    
    is $hash, {
        jsonrpc => '2.0',
        method  => 'createUser',
        params  => { name => 'Bob' },
        id      => 123,
    }, 'to_hash produces correct hash';
};
```

これで、JSON文字列から直接Requestオブジェクトを生成できるようになった！

```perl
use JSON::MaybeXS qw(decode_json encode_json);

# JSON文字列 → Request オブジェクト
my $json = '{"jsonrpc":"2.0","method":"getUser","id":1}';
my $hash = decode_json($json);
my $req  = JsonRpc::Request->from_hash($hash);

# Request オブジェクト → JSON文字列
my $output_hash = $req->to_hash;
my $output_json = encode_json($output_hash);
```

## JsonRpc::Response値オブジェクトのTDD実装

次に、JSON-RPC 2.0のResponse値オブジェクトを実装する。JSON-RPC仕様では「成功時のResponse」と「エラー時のResponse」の2種類があるが、今回は成功時のResponseのみを実装する（エラーResponseは次回の記事で扱う）。

### JSON-RPC 2.0 Response仕様の確認

JSON-RPC 2.0仕様における成功時のResponse objectは以下のフィールドを持つ。

| フィールド | 型 | 必須/オプション | 説明 |
|-----------|-----|----------------|------|
| jsonrpc | String | 必須 | "2.0" 固定 |
| result | Any | 必須 | メソッドの実行結果（任意の型） |
| id | String, Number, Null | 必須 | リクエストと対応するID |

### Red - Responseのテストを書く

```perl
# t/response.t
use v5.38;
use Test2::V0;
use lib 'lib';

use_ok 'JsonRpc::Response' or die;
use JsonRpc::Version;

subtest 'constructor with all required fields' => sub {
    my $res = JsonRpc::Response->new(
        jsonrpc => JsonRpc::Version->new(value => '2.0'),
        result  => { name => 'Alice', age => 30 },
        id      => 'req-001',
    );
    
    ok $res, 'Response created';
    isa_ok $res->jsonrpc, 'JsonRpc::Version';
    is $res->result, { name => 'Alice', age => 30 }, 'result is hash';
    is $res->id, 'req-001', 'id is string';
};

subtest 'result accepts any type' => sub {
    my $version = JsonRpc::Version->new(value => '2.0');
    
    # 文字列
    ok(lives {
        JsonRpc::Response->new(jsonrpc => $version, result => 'success', id => 1);
    }, 'result accepts string');
    
    # 数値
    ok(lives {
        JsonRpc::Response->new(jsonrpc => $version, result => 42, id => 2);
    }, 'result accepts number');
    
    # 配列
    ok(lives {
        JsonRpc::Response->new(jsonrpc => $version, result => [1, 2, 3], id => 3);
    }, 'result accepts array');
    
    # ハッシュ
    ok(lives {
        JsonRpc::Response->new(jsonrpc => $version, result => { ok => 1 }, id => 4);
    }, 'result accepts hash');
    
    # null/undef
    ok(lives {
        JsonRpc::Response->new(jsonrpc => $version, result => undef, id => 5);
    }, 'result accepts undef');
};

subtest 'id is required' => sub {
    like(dies {
        JsonRpc::Response->new(
            jsonrpc => JsonRpc::Version->new(value => '2.0'),
            result  => 'ok',
        );
    }, qr/required|missing/i, 'id is required');
};

subtest 'from_hash factory method' => sub {
    my $res = JsonRpc::Response->from_hash({
        jsonrpc => '2.0',
        result  => { status => 'ok' },
        id      => 'test-id',
    });
    
    ok $res, 'Response created from hash';
    is $res->result, { status => 'ok' }, 'result is correct';
    is $res->id, 'test-id', 'id is correct';
};

subtest 'to_hash converts back to hash' => sub {
    my $res = JsonRpc::Response->from_hash({
        jsonrpc => '2.0',
        result  => [1, 2, 3],
        id      => 999,
    });
    
    is $res->to_hash, {
        jsonrpc => '2.0',
        result  => [1, 2, 3],
        id      => 999,
    }, 'to_hash produces correct hash';
};

done_testing;
```

### Green - Response実装

```perl
# lib/JsonRpc/Response.pm
package JsonRpc::Response;
use v5.38;
use Moo;
use Types::Standard qw(InstanceOf Any Str Int);
use JsonRpc::Version;
use namespace::clean;

has jsonrpc => (
    is       => 'ro',
    isa      => InstanceOf['JsonRpc::Version'],
    required => 1,
);

has result => (
    is       => 'ro',
    isa      => Any,  # 任意の型を許容
    required => 1,
);

has id => (
    is       => 'ro',
    isa      => Str | Int,
    required => 1,
);

sub from_hash {
    my ($class, $hash) = @_;
    
    die "from_hash requires a hash reference"
        unless ref $hash eq 'HASH';
    
    die "missing required field: jsonrpc"
        unless exists $hash->{jsonrpc};
    die "missing required field: result"
        unless exists $hash->{result};
    die "missing required field: id"
        unless exists $hash->{id};
    
    return $class->new(
        jsonrpc => JsonRpc::Version->new(value => $hash->{jsonrpc}),
        result  => $hash->{result},
        id      => $hash->{id},
    );
}

sub to_hash {
    my $self = shift;
    
    return {
        jsonrpc => $self->jsonrpc->value,
        result  => $self->result,
        id      => $self->id,
    };
}

1;

__END__

=head1 NAME

JsonRpc::Response - JSON-RPC 2.0 successful Response object

=head1 SYNOPSIS

    use JsonRpc::Response;
    
    my $res = JsonRpc::Response->new(
        jsonrpc => JsonRpc::Version->new(value => '2.0'),
        result  => { user => { id => 42, name => 'Alice' } },
        id      => 'req-123',
    );
    
    # From hash
    my $res2 = JsonRpc::Response->from_hash({
        jsonrpc => '2.0',
        result  => [1, 2, 3],
        id      => 999,
    });

=head1 DESCRIPTION

Represents a JSON-RPC 2.0 successful Response object.

The C<result> field can be any value (string, number, array, hash, null).

=cut
```

テスト実行で成功（Green）を確認！

## 複合値オブジェクトのファクトリーパターン - 生成方法の比較

JSON-RPCのような複合値オブジェクトの生成には、いくつかのデザインパターンが適用できる。それぞれの特徴とユースケースを見ていこう。

### コンストラクタによる直接生成

最も基本的な方法は、`new`による直接生成である。

```perl
my $req = JsonRpc::Request->new(
    jsonrpc => JsonRpc::Version->new(value => '2.0'),
    method  => JsonRpc::MethodName->new(value => 'getUser'),
    params  => { user_id => 42 },
    id      => 'req-001',
);
```

この方法は明示的だが、冗長になりがちである。

### ファクトリーメソッドパターン

`from_hash`のようなファクトリーメソッドを提供することで生成を簡潔にできる。

```perl
# JSON文字列 → Hash → Request
use JSON::MaybeXS qw(decode_json);

my $json_str = '{"jsonrpc":"2.0","method":"getUser","id":1}';
my $hash = decode_json($json_str);
my $req = JsonRpc::Request->from_hash($hash);  # 簡潔！
```

### ビルダーパターン（応用）

より複雑な生成ロジックが必要な場合はビルダーパターンも検討できる。

```perl
package JsonRpc::RequestBuilder;
use v5.38;
use Moo;

has _jsonrpc => (is => 'rw');
has _method  => (is => 'rw');
has _params  => (is => 'rw');
has _id      => (is => 'rw');

sub jsonrpc {
    my ($self, $value) = @_;
    $self->_jsonrpc(JsonRpc::Version->new(value => $value));
    return $self;
}

sub method {
    my ($self, $value) = @_;
    $self->_method(JsonRpc::MethodName->new(value => $value));
    return $self;
}

sub params {
    my ($self, $value) = @_;
    $self->_params($value);
    return $self;
}

sub id {
    my ($self, $value) = @_;
    $self->_id($value);
    return $self;
}

sub build {
    my $self = shift;
    
    return JsonRpc::Request->new(
        jsonrpc => $self->_jsonrpc,
        method  => $self->_method,
        defined $self->_params ? (params => $self->_params) : (),
        defined $self->_id     ? (id     => $self->_id)     : (),
    );
}

1;
```

使用例：

```perl
use JsonRpc::RequestBuilder;

my $req = JsonRpc::RequestBuilder->new
    ->jsonrpc('2.0')
    ->method('getUser')
    ->params({ user_id => 42 })
    ->id('req-001')
    ->build;
```

流れるようなインターフェース（Fluent Interface）で読みやすくなる。

## 実践例 - JSON-RPC 2.0通信の完全シミュレーション

これまで実装したRequest/Response値オブジェクトを使用して、実際のJSON-RPC 2.0通信をエンドツーエンドでシミュレートする。この例では、クライアント→サーバー→クライアントの完全な往復通信を再現する。

```perl
#!/usr/bin/env perl
use v5.38;
use JSON::MaybeXS qw(encode_json decode_json);
use lib 'lib';
use JsonRpc::Request;
use JsonRpc::Response;

# クライアント側: リクエスト作成
my $request = JsonRpc::Request->from_hash({
    jsonrpc => '2.0',
    method  => 'createUser',
    params  => { name => 'Alice', email => 'alice@example.com' },
    id      => 'req-001',
});

# JSON文字列にエンコード
my $request_json = encode_json($request->to_hash);
say "Request JSON: $request_json";

# サーバー側: リクエスト処理
my $received_hash = decode_json($request_json);
my $received_req  = JsonRpc::Request->from_hash($received_hash);

say "\nServer received:";
say "  Method: " . $received_req->method->value;
say "  Params: " . encode_json($received_req->params);

# ビジネスロジック実行（ダミー）
my $user_id = 42;
my $result = {
    id    => $user_id,
    name  => $received_req->params->{name},
    email => $received_req->params->{email},
};

# レスポンス作成
my $response = JsonRpc::Response->new(
    jsonrpc => $received_req->jsonrpc,
    result  => $result,
    id      => $received_req->id,
);

# JSON文字列にエンコード
my $response_json = encode_json($response->to_hash);
say "\nResponse JSON: $response_json";

# クライアント側: レスポンス受信
my $received_res_hash = decode_json($response_json);
my $received_res = JsonRpc::Response->from_hash($received_res_hash);

say "\nClient received:";
say "  User ID: " . $received_res->result->{id};
say "  Name: " . $received_res->result->{name};
```

実行結果：

```text
Request JSON: {"id":"req-001","jsonrpc":"2.0","method":"createUser","params":{"email":"alice@example.com","name":"Alice"}}

Server received:
  Method: createUser
  Params: {"email":"alice@example.com","name":"Alice"}

Response JSON: {"id":"req-001","jsonrpc":"2.0","result":{"email":"alice@example.com","id":42,"name":"Alice"}}

Client received:
  User ID: 42
  Name: Alice
```

すべてのデータが値オブジェクトによって検証され、JSON-RPC 2.0仕様に準拠した型安全な通信が実現できている！

## 複合値オブジェクトのメリット再確認 - JSON-RPC実装から学ぶ

ここまでのJSON-RPC Request/Response実装を通じて、複合値オブジェクトがもたらす具体的なメリットが明確になった。

### 型安全性

```perl
# これはコンパイル時（ロード時）にエラー
my $req = JsonRpc::Request->new(
    jsonrpc => "2.0",  # NG: Version オブジェクトが必要
    method  => "test",
);
# Value "2.0" did not pass type constraint "InstanceOf['JsonRpc::Version']"
```

不正なデータは、システムに入り込む前に確実に拒否される。

### 自己文書化

```perl
# コードを見れば構造が明確
has jsonrpc => (is => 'ro', isa => InstanceOf['JsonRpc::Version']);
has method  => (is => 'ro', isa => InstanceOf['JsonRpc::MethodName']);
has params  => (is => 'ro', isa => Maybe[ArrayRef | HashRef]);
has id      => (is => 'ro', isa => Maybe[Str | Int]);
```

型定義がそのまま仕様書になっている。

### リファクタリングの安全性

値オブジェクトを変更しても、テストが失敗すればすぐに気づける。

```perl
# MethodName の検証ルールを変更
# → Request のテストが失敗する
# → すぐに影響範囲がわかる
```

### テストの容易さ

```perl
# モックオブジェクトも簡単
my $mock_version = JsonRpc::Version->new(value => '2.0');
my $mock_method  = JsonRpc::MethodName->new(value => 'test');

my $req = JsonRpc::Request->new(
    jsonrpc => $mock_version,
    method  => $mock_method,
);
```

## まとめと次回予告

### この記事で学んだこと - JSON-RPC実装で習得した技術

今回は、JSON-RPC 2.0のRequest/Responseという**複合値オブジェクト**の実装を通じて、以下の技術を習得した。

**複合値オブジェクトの設計:**
- 単純な値オブジェクトを組み合わせた階層構造
- 必須フィールドとオプショナルフィールドの扱い
- 値オブジェクトのネスト構造の設計

**Type::Tinyの実践活用:**
- `Maybe`型によるオプショナルフィールドの表現
- `ArrayRef | HashRef`による選択的な型制約
- `InstanceOf`による値オブジェクト同士の組み合わせ
- `Any`型による柔軟な結果の受け入れ

**ファクトリーメソッドパターン:**
- `from_hash`による簡潔なオブジェクト生成
- JSONデコード結果からの直接変換
- `to_hash`による双方向変換の実現

**TDDでの実装プロセス:**
- 複合的な値オブジェクトのテスト戦略
- 必須/オプションフィールドのテストパターン
- Red-Green-Refactorサイクルの実践

### 複合値オブジェクトの実装指針 - ベストプラクティス

JSON-RPCのような複合値オブジェクトを実装する際は、以下のベストプラクティスを意識すると良い。

1. **小さな値オブジェクトから始める**: Version, MethodNameのような単純な値オブジェクトを先に実装（ボトムアップアプローチ）
2. **型制約を明確にする**: Type::TinyのMaybe/InstanceOfで厳密に型を定義し、実行可能な仕様書とする
3. **ファクトリーメソッドを提供する**: from_hashでJSON→オブジェクト変換の利便性を向上
4. **テストファーストで進める**: TDDのRed-Green-Refactorサイクルで段階的に実装
5. **双方向変換を実装**: to_hashで元のハッシュ形式に戻せるようにし、JSONエンコードを可能にする
6. **仕様への忠実性**: JSON-RPC 2.0仕様のような標準仕様には厳密に準拠する

### 次回予告 - エラー処理と境界値テスト（シリーズ完結編）

次回は「**エラー処理と境界値テスト - 堅牢な値オブジェクトを作る**」として、**シリーズの完結編（第5回）**をお届けする。

**次回の学習内容:**
- **JSON-RPC Error Responseの実装**: エラーオブジェクトの値オブジェクト化
- **エラーコードと例外の設計**: Perlにおける例外処理とType::Tinyの統合
- **境界値分析の実践**: JSONサイズ制限、数値範囲、文字列長などの境界値テスト
- **プロパティベーステストの導入**: Test::QuickCheckによるランダムテスト
- **実践的なエラーハンドリング戦略**: JSON-RPC仕様に準拠したエラー処理

今回実装したRequestとResponseに、JSON-RPC Error Response値オブジェクトとエラー処理を加えることで、**完全なJSON-RPC 2.0実装**が完成する。さらに、境界値テストやproperty-based testingにより、より堅牢で本番環境に耐えうる値オブジェクトの実装技法を学ぶ。

> **次回記事**  
> → エラー処理と境界値テスト - 堅牢な値オブジェクトを作る（公開予定）

## 参考リンク

{{< linkcard "https://metacpan.org/pod/Type::Tiny" >}}
{{< linkcard "https://metacpan.org/pod/Types::Standard" >}}
{{< linkcard "https://metacpan.org/pod/Moo" >}}
{{< linkcard "https://www.jsonrpc.org/specification" >}}

## シリーズ記事一覧

本記事は「**Perlで値オブジェクトを使ってテスト駆動開発してみよう**」シリーズの第4回です。

1. 値オブジェクトって何だろう？ - DDDの基本概念とPerlでの実装入門
2. JSON-RPC 2.0で学ぶ値オブジェクト設計 - 仕様から設計へ
3. [PerlのTest2でTDD実践 - 値オブジェクトのテスト戦略](/2025/12/18/test2-tdd-value-object-testing-strategy/)
4. **JSON-RPC Request/Response実装 - 複合値オブジェクト設計【Perl×TDD】**（この記事）
5. エラー処理と境界値テスト - 堅牢な値オブジェクトを作る（次回・シリーズ完結編）

各記事は独立して読めますが、順番に読むことでPerlにおけるTDD開発と値オブジェクト設計の全体像が理解できます。
