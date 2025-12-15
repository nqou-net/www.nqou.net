---
title: "JSON-RPC 2.0のリクエストとエラーを値オブジェクトで堅牢に実装する"
draft: true
tags:
- perl
- json-rpc
- value-object
- test-driven-development
- design-pattern
- api-design
- validation
description: "JSON-RPC 2.0仕様のRequestとErrorオブジェクトを値オブジェクトで実装する方法を、仕様駆動アプローチで解説。仕様書の制約をテストケースに変換し、堅牢なAPI実装を実現します。"
---

## 仕様書から学ぶ値オブジェクト設計

> **📚 シリーズ記事**: この記事は「Perl値オブジェクト実践シリーズ」の第2回です。
> - 📖 第1回：[Perlで始める値オブジェクト入門](../perl-value-object-intro/)
> - 📖 第2回：[JSON-RPC 2.0のリクエストとエラーを値オブジェクトで堅牢に実装する](../jsonrpc-value-object-outlines/)（この記事）
> - 📖 第3回：[JSON-RPC 2.0 Responseの成功とエラーを型で区別する](../jsonrpc-response-value-object/)

前回の記事では、`EmailAddress`値オブジェクトを通じて、値オブジェクトの基本的な3つの特性(不変性、等価性、自己バリデーション)を学びました。

今回は、実際のAPI仕様である**JSON-RPC 2.0**を題材に、仕様書の制約条件を値オブジェクトのバリデーションとして表現する実践的な手法を学びます。

「仕様書を読む → テストを書く → 実装する」というサイクルを体験することで、仕様理解と実装品質が同時に向上する設計手法を身につけましょう。

## JSON-RPC 2.0とは？シンプルで強力なRPC仕様

JSON-RPC 2.0は、JSONフォーマットを使った軽量なリモートプロシージャコール(RPC)プロトコルです。

{{< linkcard "https://www.jsonrpc.org/specification" >}}

## なぜJSON-RPC 2.0を題材にするのか

JSON-RPC 2.0は値オブジェクト学習の題材として優れています。

**仕様が明確**  
MUST/MUST NOT/SHOULD等の制約が明示的に定義されています。

**適度な複雑さ**  
シンプルすぎず複雑すぎない、学習に最適な規模です。

**実用性**  
Model Context Protocol (MCP)等、実際のプロジェクトで採用されています。

**設計の学び**  
排他性、オプション性、型多様性など、設計上の重要概念が詰まっています。

## JSON-RPC 2.0の基本構造

JSON-RPC 2.0には3つの主要オブジェクトがあります。

**Request object**  
クライアントからサーバーへのメソッド呼び出しを表現します。

**Response object**  
サーバーからクライアントへの成功応答を表現します。

**Error object**  
サーバーからクライアントへのエラー応答を表現します。

今回は**Request object**と**Error object**に焦点を当てます。Response objectは[第3回](../jsonrpc-response-value-object/)で扱います。

## Request objectの仕様を読み解く

まずJSON-RPC 2.0仕様書のRequest objectセクションを見てみましょう。

## 仕様書の記述

> A rpc call is represented by sending a Request object to a Server. The Request object has the following members:
>
> - **jsonrpc**: A String specifying the version of the JSON-RPC protocol. MUST be exactly "2.0".
> - **method**: A String containing the name of the method to be invoked.
> - **params**: A Structured value that holds the parameter values to be used during the invocation of the method. This member MAY be omitted.
> - **id**: An identifier established by the Client. This member is REQUIRED. It MUST contain a String, Number, or NULL value.

この仕様から、以下の制約条件が読み取れます。

| フィールド | 型 | 必須/任意 | 制約 |
|-----------|-----|----------|------|
| jsonrpc | String | **MUST** | 正確に "2.0" でなければならない |
| method | String | **REQUIRED** | メソッド名文字列 |
| params | Structured/Array | **MAY** | 構造化データまたは配列、省略可能 |
| id | String/Number/NULL | **REQUIRED** | 文字列、数値、またはnull |

## Request objectを値オブジェクトに分解する

複雑な構造も、小さな値オブジェクトに分解すればシンプルになります。

Request objectを4つの値オブジェクトに分けましょう。

**JsonRpcVersion**  
"2.0"という固定値を表現します。

**MethodName**  
メソッド名文字列を表現します。

**RequestParams**  
パラメータ(構造化データまたは配列)を表現します。

**RequestId**  
リクエスト識別子(文字列/数値/null)を表現します。

そして、これら4つを組み合わせた**JsonRpcRequest**値オブジェクトを作ります。

## JsonRpcVersion値オブジェクト - 固定値の表現

仕様上の制約は以下の通りです。

- MUST be exactly "2.0"
- 文字列型でなければならない

テストから始めます(TDD)。

```perl
use strict;
use warnings;
use Test::More;

use_ok('JsonRpcVersion');

subtest 'valid version' => sub {
    my $version = JsonRpcVersion->new('2.0');
    isa_ok($version, 'JsonRpcVersion');
    is($version->value, '2.0');
};

subtest 'invalid versions are rejected' => sub {
    eval { JsonRpcVersion->new('1.0') };
    like($@, qr/must be exactly "2.0"/);
    
    eval { JsonRpcVersion->new('2.1') };
    like($@, qr/must be exactly "2.0"/);
    
    eval { JsonRpcVersion->new(2.0) };
    like($@, qr/must be a string/);
    
    eval { JsonRpcVersion->new(undef) };
    like($@, qr/is required/);
};

done_testing();
```

実装は以下の通りです。

```perl
package JsonRpcVersion;
use strict;
use warnings;
use Class::Tiny qw(value);

use constant VALID_VERSION => '2.0';

sub BUILD {
    my ($self) = @_;
    my $value = $self->value;
    
    die "JSON-RPC version is required"
        unless defined $value;
    
    die "JSON-RPC version must be a string"
        if ref($value);
    
    die "JSON-RPC version must be exactly \"2.0\", got \"$value\""
        unless $value eq VALID_VERSION;
}

sub equals {
    my ($self, $other) = @_;
    return 0 unless ref($other) eq ref($self);
    return $self->value eq $other->value;
}

use overload '""' => sub { shift->value };

1;
```

仕様書の「MUST be exactly "2.0"」という制約が、`BUILD`メソッド内のバリデーションとして表現されています。

## MethodName値オブジェクト - メソッド名のバリデーション

仕様上の制約は以下の通りです。

- 文字列でなければならない
- 空文字列は不正(仕様上明示されていないが、実用上必要)
- "rpc."で始まるメソッド名は予約済み(仕様書に記載あり)

テストコードは以下の通りです。

```perl
use strict;
use warnings;
use Test::More;

use_ok('MethodName');

subtest 'valid method names' => sub {
    my @valid = qw(subtract update foobar get_user calculateSum);
    
    for my $name (@valid) {
        my $method = MethodName->new($name);
        isa_ok($method, 'MethodName');
        is($method->value, $name);
    }
};

subtest 'invalid method names are rejected' => sub {
    eval { MethodName->new('') };
    like($@, qr/cannot be empty/);
    
    eval { MethodName->new(undef) };
    like($@, qr/is required/);
    
    eval { MethodName->new('rpc.test') };
    like($@, qr/rpc\. prefix is reserved/);
    
    eval { MethodName->new(123) };
    like($@, qr/must be a string/);
};

done_testing();
```

実装は以下の通りです。

```perl
package MethodName;
use strict;
use warnings;
use Class::Tiny qw(value);

sub BUILD {
    my ($self) = @_;
    my $value = $self->value;
    
    die "Method name is required"
        unless defined $value;
    
    die "Method name must be a string"
        if ref($value);
    
    die "Method name cannot be empty"
        if $value eq '';
    
    die "Method name with 'rpc.' prefix is reserved for system extensions"
        if $value =~ /^rpc\./;
}

sub equals {
    my ($self, $other) = @_;
    return 0 unless ref($other) eq ref($self);
    return $self->value eq $other->value;
}

use overload '""' => sub { shift->value };

1;
```

## RequestId値オブジェクト - 複数型への対応

仕様上の制約は以下の通りです。

- MUST contain a String, Number, or NULL value
- 配列やオブジェクトは不正

テストコードは以下の通りです。

```perl
use strict;
use warnings;
use Test::More;

use_ok('RequestId');

subtest 'valid request IDs' => sub {
    my $id1 = RequestId->new('abc-123');
    is($id1->value, 'abc-123');
    
    my $id2 = RequestId->new(42);
    is($id2->value, 42);
    
    my $id3 = RequestId->new(undef);
    is($id3->value, undef);
};

subtest 'invalid request IDs are rejected' => sub {
    eval { RequestId->new([1, 2, 3]) };
    like($@, qr/must be a String, Number, or NULL/);
    
    eval { RequestId->new({id => 1}) };
    like($@, qr/must be a String, Number, or NULL/);
};

subtest 'equality' => sub {
    my $id1 = RequestId->new('test');
    my $id2 = RequestId->new('test');
    my $id3 = RequestId->new('other');
    
    ok($id1->equals($id2));
    ok(!$id1->equals($id3));
    
    my $num1 = RequestId->new(42);
    my $num2 = RequestId->new(42);
    ok($num1->equals($num2));
};

done_testing();
```

実装は以下の通りです。

```perl
package RequestId;
use strict;
use warnings;
use Class::Tiny qw(value);

sub BUILD {
    my ($self) = @_;
    my $value = $self->value;
    
    return if !defined $value;
    
    my $ref = ref($value);
    die "Request ID must be a String, Number, or NULL (not $ref)"
        if $ref;
}

sub equals {
    my ($self, $other) = @_;
    return 0 unless ref($other) eq ref($self);
    
    my $v1 = $self->value;
    my $v2 = $other->value;
    
    return 1 if !defined $v1 && !defined $v2;
    return 0 if !defined $v1 || !defined $v2;
    return $v1 eq $v2;
}

use overload '""' => sub {
    my $self = shift;
    my $value = $self->value;
    return defined $value ? "$value" : 'null';
};

1;
```

## RequestParams値オブジェクト - 柔軟な構造の扱い

仕様上の制約は以下の通りです。

- MAY be omitted(省略可能)
- Structured value(ハッシュリファレンス)または配列リファレンス

テストコードは以下の通りです。

```perl
use strict;
use warnings;
use Test::More;

use_ok('RequestParams');

subtest 'valid params' => sub {
    my $p1 = RequestParams->new({x => 1, y => 2});
    is_deeply($p1->value, {x => 1, y => 2});
    
    my $p2 = RequestParams->new([42, 23]);
    is_deeply($p2->value, [42, 23]);
    
    my $p3 = RequestParams->new(undef);
    is($p3->value, undef);
};

subtest 'invalid params are rejected' => sub {
    eval { RequestParams->new('string') };
    like($@, qr/must be a hash or array reference/);
    
    eval { RequestParams->new(123) };
    like($@, qr/must be a hash or array reference/);
};

done_testing();
```

実装は以下の通りです。

```perl
package RequestParams;
use strict;
use warnings;
use Class::Tiny qw(value);
use Storable qw(dclone);

sub BUILD {
    my ($self) = @_;
    my $value = $self->value;
    
    return if !defined $value;
    
    my $ref = ref($value);
    die "Request params must be a hash or array reference (not $ref)"
        unless $ref eq 'HASH' || $ref eq 'ARRAY';
    
    $self->{value} = dclone($value);
}

use overload '""' => sub {
    my $self = shift;
    my $value = $self->value;
    return defined $value ? 'params' : 'null';
};

1;
```

`Storable::dclone`を使って深いコピーを作成することで、外部からの変更を防ぎ、不変性を確保しています。

## JsonRpcRequest値オブジェクト - 全体の組み立て

4つの値オブジェクトを組み合わせて、完全なRequest objectを表現します。

テストコードは以下の通りです。

```perl
use strict;
use warnings;
use Test::More;
use JSON::PP qw(decode_json);

use_ok('JsonRpcRequest');
use_ok('JsonRpcVersion');
use_ok('MethodName');
use_ok('RequestParams');
use_ok('RequestId');

subtest 'construct valid request' => sub {
    my $request = JsonRpcRequest->new(
        version => JsonRpcVersion->new('2.0'),
        method  => MethodName->new('subtract'),
        params  => RequestParams->new([42, 23]),
        id      => RequestId->new(1),
    );
    
    isa_ok($request, 'JsonRpcRequest');
    is($request->version->value, '2.0');
    is($request->method->value, 'subtract');
    is_deeply($request->params->value, [42, 23]);
    is($request->id->value, 1);
};

subtest 'to_json serialization' => sub {
    my $request = JsonRpcRequest->new(
        version => JsonRpcVersion->new('2.0'),
        method  => MethodName->new('update'),
        params  => RequestParams->new({user_id => 123}),
        id      => RequestId->new('abc'),
    );
    
    my $json = $request->to_json;
    my $decoded = decode_json($json);
    
    is($decoded->{jsonrpc}, '2.0');
    is($decoded->{method}, 'update');
    is_deeply($decoded->{params}, {user_id => 123});
    is($decoded->{id}, 'abc');
};

subtest 'params can be omitted' => sub {
    my $request = JsonRpcRequest->new(
        version => JsonRpcVersion->new('2.0'),
        method  => MethodName->new('ping'),
        params  => RequestParams->new(undef),
        id      => RequestId->new(999),
    );
    
    my $json = $request->to_json;
    my $decoded = decode_json($json);
    
    ok(!exists $decoded->{params});
};

done_testing();
```

実装は以下の通りです。

```perl
package JsonRpcRequest;
use strict;
use warnings;
use Class::Tiny qw(version method params id);
use JSON::PP qw(encode_json);

sub BUILD {
    my ($self) = @_;
    
    die "version is required and must be a JsonRpcVersion object"
        unless $self->version && ref($self->version) eq 'JsonRpcVersion';
    
    die "method is required and must be a MethodName object"
        unless $self->method && ref($self->method) eq 'MethodName';
    
    die "params must be a RequestParams object"
        unless $self->params && ref($self->params) eq 'RequestParams';
    
    die "id is required and must be a RequestId object"
        unless defined $self->id && ref($self->id) eq 'RequestId';
}

sub to_json {
    my ($self) = @_;
    
    my %data = (
        jsonrpc => $self->version->value,
        method  => $self->method->value,
        id      => $self->id->value,
    );
    
    my $params = $self->params->value;
    $data{params} = $params if defined $params;
    
    return encode_json(\%data);
}

1;
```

## Error objectの仕様を読み解く

次に、Error objectの仕様を見てみましょう。

## 仕様書の記述

> When a rpc call encounters an error, the Response Object contains the error member with a value that is an Object with the following members:
>
> - **code**: A Number that indicates the error type that occurred. This MUST be an integer.
> - **message**: A String providing a short description of the error.
> - **data**: A Primitive or Structured value that contains additional information about the error. This may be omitted.

仕様書では、以下の標準エラーコードが定義されています。

| コード | メッセージ | 意味 |
|-------|----------|------|
| -32700 | Parse error | 不正なJSONを受信 |
| -32600 | Invalid Request | JSONは正しいがRequestオブジェクトが不正 |
| -32601 | Method not found | メソッドが存在しない |
| -32602 | Invalid params | パラメータが不正 |
| -32603 | Internal error | サーバー内部エラー |
| -32000 to -32099 | Server error | サーバー定義のエラー(予約済み) |

**重要**: -32768から-32000までの範囲は予約済みです。カスタムエラーには正の整数を使うことが推奨されます(2024-2025年のベストプラクティス)。

## ErrorCode値オブジェクト - エラーコードの表現

テストコードは以下の通りです。

```perl
use strict;
use warnings;
use Test::More;

use_ok('ErrorCode');

subtest 'standard error codes' => sub {
    my $parse_error = ErrorCode->new(ErrorCode::PARSE_ERROR);
    is($parse_error->value, -32700);
    
    my $invalid_request = ErrorCode->new(ErrorCode::INVALID_REQUEST);
    is($invalid_request->value, -32600);
};

subtest 'custom error codes' => sub {
    my $custom = ErrorCode->new(100);
    is($custom->value, 100);
    
    my $server_error = ErrorCode->new(-32050);
    is($server_error->value, -32050);
};

subtest 'invalid error codes are rejected' => sub {
    eval { ErrorCode->new(3.14) };
    like($@, qr/must be an integer/);
    
    eval { ErrorCode->new('error') };
    like($@, qr/must be an integer/);
    
    eval { ErrorCode->new(undef) };
    like($@, qr/is required/);
};

done_testing();
```

実装は以下の通りです。

```perl
package ErrorCode;
use strict;
use warnings;
use Class::Tiny qw(value);

use constant {
    PARSE_ERROR      => -32700,
    INVALID_REQUEST  => -32600,
    METHOD_NOT_FOUND => -32601,
    INVALID_PARAMS   => -32602,
    INTERNAL_ERROR   => -32603,
};

sub BUILD {
    my ($self) = @_;
    my $value = $self->value;
    
    die "Error code is required"
        unless defined $value;
    
    die "Error code must be an integer"
        unless $value =~ /^-?\d+$/ && $value == int($value);
}

sub is_standard_error {
    my ($self) = @_;
    my $code = $self->value;
    return $code >= -32603 && $code <= -32600 || $code == -32700;
}

sub is_server_error {
    my ($self) = @_;
    my $code = $self->value;
    return $code >= -32099 && $code <= -32000;
}

sub equals {
    my ($self, $other) = @_;
    return 0 unless ref($other) eq ref($self);
    return $self->value == $other->value;
}

use overload '""' => sub { shift->value };

1;
```

## ErrorMessage値オブジェクト - エラーメッセージの制約

テストコードは以下の通りです。

```perl
use strict;
use warnings;
use Test::More;

use_ok('ErrorMessage');

subtest 'valid error messages' => sub {
    my $msg = ErrorMessage->new('Parse error');
    is($msg->value, 'Parse error');
    
    my $long_msg = ErrorMessage->new('Invalid parameters: expected array of numbers');
    ok($long_msg->value);
};

subtest 'invalid error messages are rejected' => sub {
    eval { ErrorMessage->new('') };
    like($@, qr/cannot be empty/);
    
    eval { ErrorMessage->new(undef) };
    like($@, qr/is required/);
};

done_testing();
```

実装は以下の通りです。

```perl
package ErrorMessage;
use strict;
use warnings;
use Class::Tiny qw(value);

sub BUILD {
    my ($self) = @_;
    my $value = $self->value;
    
    die "Error message is required"
        unless defined $value;
    
    die "Error message must be a string"
        if ref($value);
    
    die "Error message cannot be empty"
        if $value eq '';
}

sub equals {
    my ($self, $other) = @_;
    return 0 unless ref($other) eq ref($self);
    return $self->value eq $other->value;
}

use overload '""' => sub { shift->value };

1;
```

## ErrorData値オブジェクト - オプショナルな追加情報

テストコードは以下の通りです。

```perl
use strict;
use warnings;
use Test::More;

use_ok('ErrorData');

subtest 'valid error data' => sub {
    my $d1 = ErrorData->new(undef);
    is($d1->value, undef);
    
    my $d2 = ErrorData->new('Additional details');
    is($d2->value, 'Additional details');
    
    my $d3 = ErrorData->new({field => 'username', reason => 'too short'});
    is_deeply($d3->value, {field => 'username', reason => 'too short'});
    
    my $d4 = ErrorData->new(['error1', 'error2']);
    is_deeply($d4->value, ['error1', 'error2']);
};

done_testing();
```

実装は以下の通りです。

```perl
package ErrorData;
use strict;
use warnings;
use Class::Tiny qw(value);
use Storable qw(dclone);

sub BUILD {
    my ($self) = @_;
    my $value = $self->value;
    
    return if !defined $value;
    
    my $ref = ref($value);
    if ($ref eq 'HASH' || $ref eq 'ARRAY') {
        $self->{value} = dclone($value);
    }
}

use overload '""' => sub {
    my $self = shift;
    my $value = $self->value;
    return defined $value ? 'error_data' : 'null';
};

1;
```

## JsonRpcError値オブジェクト - エラーの完成形

テストコードは以下の通りです。

```perl
use strict;
use warnings;
use Test::More;
use JSON::PP qw(decode_json);

use_ok('JsonRpcError');
use_ok('ErrorCode');
use_ok('ErrorMessage');
use_ok('ErrorData');

subtest 'construct valid error' => sub {
    my $error = JsonRpcError->new(
        code    => ErrorCode->new(ErrorCode::INVALID_REQUEST),
        message => ErrorMessage->new('Invalid Request'),
        data    => ErrorData->new(undef),
    );
    
    isa_ok($error, 'JsonRpcError');
    is($error->code->value, -32600);
    is($error->message->value, 'Invalid Request');
    is($error->data->value, undef);
};

subtest 'error with additional data' => sub {
    my $error = JsonRpcError->new(
        code    => ErrorCode->new(ErrorCode::INVALID_PARAMS),
        message => ErrorMessage->new('Invalid params'),
        data    => ErrorData->new({expected => 'array', got => 'string'}),
    );
    
    is_deeply($error->data->value, {expected => 'array', got => 'string'});
};

subtest 'to_json serialization' => sub {
    my $error = JsonRpcError->new(
        code    => ErrorCode->new(ErrorCode::METHOD_NOT_FOUND),
        message => ErrorMessage->new('Method not found'),
        data    => ErrorData->new(undef),
    );
    
    my $json = $error->to_json;
    my $decoded = decode_json($json);
    
    is($decoded->{code}, -32601);
    is($decoded->{message}, 'Method not found');
    ok(!exists $decoded->{data});
};

subtest 'factory methods for standard errors' => sub {
    my $parse_error = JsonRpcError->parse_error();
    is($parse_error->code->value, -32700);
    is($parse_error->message->value, 'Parse error');
    
    my $invalid_request = JsonRpcError->invalid_request();
    is($invalid_request->code->value, -32600);
};

done_testing();
```

実装は以下の通りです。

```perl
package JsonRpcError;
use strict;
use warnings;
use Class::Tiny qw(code message data);
use JSON::PP qw(encode_json);

sub BUILD {
    my ($self) = @_;
    
    die "code is required and must be an ErrorCode object"
        unless $self->code && ref($self->code) eq 'ErrorCode';
    
    die "message is required and must be an ErrorMessage object"
        unless $self->message && ref($self->message) eq 'ErrorMessage';
    
    die "data must be an ErrorData object"
        unless $self->data && ref($self->data) eq 'ErrorData';
}

sub to_json {
    my ($self) = @_;
    
    my %error = (
        code    => $self->code->value,
        message => $self->message->value,
    );
    
    my $data = $self->data->value;
    $error{data} = $data if defined $data;
    
    return encode_json(\%error);
}

sub parse_error {
    my ($class, $data) = @_;
    return $class->new(
        code    => ErrorCode->new(ErrorCode::PARSE_ERROR),
        message => ErrorMessage->new('Parse error'),
        data    => ErrorData->new($data),
    );
}

sub invalid_request {
    my ($class, $data) = @_;
    return $class->new(
        code    => ErrorCode->new(ErrorCode::INVALID_REQUEST),
        message => ErrorMessage->new('Invalid Request'),
        data    => ErrorData->new($data),
    );
}

sub method_not_found {
    my ($class, $data) = @_;
    return $class->new(
        code    => ErrorCode->new(ErrorCode::METHOD_NOT_FOUND),
        message => ErrorMessage->new('Method not found'),
        data    => ErrorData->new($data),
    );
}

sub invalid_params {
    my ($class, $data) = @_;
    return $class->new(
        code    => ErrorCode->new(ErrorCode::INVALID_PARAMS),
        message => ErrorMessage->new('Invalid params'),
        data    => ErrorData->new($data),
    );
}

sub internal_error {
    my ($class, $data) = @_;
    return $class->new(
        code    => ErrorCode->new(ErrorCode::INTERNAL_ERROR),
        message => ErrorMessage->new('Internal error'),
        data    => ErrorData->new($data),
    );
}

1;
```

ファクトリメソッドを用意することで、標準エラーを簡潔に生成できます。

## 統合テスト - Request/Errorの連携

すべての値オブジェクトを組み合わせた統合テストを書きましょう。

```perl
use strict;
use warnings;
use Test::More;
use JSON::PP qw(decode_json);

# Request objects
use JsonRpcRequest;
use JsonRpcVersion;
use MethodName;
use RequestParams;
use RequestId;

# Error objects
use JsonRpcError;
use ErrorCode;
use ErrorMessage;
use ErrorData;

subtest 'complete request lifecycle' => sub {
    # Create a valid request
    my $request = JsonRpcRequest->new(
        version => JsonRpcVersion->new('2.0'),
        method  => MethodName->new('calculate'),
        params  => RequestParams->new({x => 10, y => 5}),
        id      => RequestId->new('req-001'),
    );
    
    my $json = $request->to_json;
    my $decoded = decode_json($json);
    
    is($decoded->{jsonrpc}, '2.0');
    is($decoded->{method}, 'calculate');
    is($decoded->{id}, 'req-001');
};

subtest 'error response for invalid method' => sub {
    my $error = JsonRpcError->method_not_found({
        requested_method => 'unknown_method'
    });
    
    my $json = $error->to_json;
    my $decoded = decode_json($json);
    
    is($decoded->{code}, -32601);
    is($decoded->{message}, 'Method not found');
    is($decoded->{data}{requested_method}, 'unknown_method');
};

subtest 'notification request (id is null)' => sub {
    my $notification = JsonRpcRequest->new(
        version => JsonRpcVersion->new('2.0'),
        method  => MethodName->new('notify'),
        params  => RequestParams->new(['event occurred']),
        id      => RequestId->new(undef),
    );
    
    my $json = $notification->to_json;
    my $decoded = decode_json($json);
    
    is($decoded->{id}, undef);
};

done_testing();
```

## 実装を通して得られた学び

## 仕様書の制約をテストに変換できる

JSON-RPC 2.0仕様書の「MUST」「MUST NOT」「MAY」といった記述は、そのままテストケースに変換できました。

**MUST be exactly "2.0"**  
`JsonRpcVersion`のバリデーションテストとして実装しました。

**MUST be an integer**  
`ErrorCode`の型チェックテストとして実装しました。

**MAY be omitted**  
`RequestParams`と`ErrorData`のundef許容テストとして実装しました。

## 小さな値オブジェクトの組み合わせで複雑さを管理

Request objectを4つの値オブジェクトに分解することで、以下のメリットが得られました。

各値オブジェクトの責務が明確になります。

テストが書きやすくなります。

再利用可能です(例:`RequestId`は他のコンテキストでも使えます)。

変更に強くなります(`MethodName`のバリデーションルール変更は1箇所で完結します)。

## バリデーションの一元化による保守性向上

バリデーションロジックは各値オブジェクトの`BUILD`メソッドに集約されているため、以下のメリットがあります。

- 重複がありません
- 変更時の影響範囲が明確です
- テストカバレッジが高くなります

## まとめと次回予告

今回の記事では、JSON-RPC 2.0仕様のRequest objectとError objectを値オブジェクトとして実装しました。

## 今回実装した値オブジェクト

**Request関連**

- `JsonRpcVersion`:固定値"2.0"の表現を実装しました
- `MethodName`:メソッド名のバリデーションを実装しました
- `RequestParams`:柔軟なパラメータ構造を実装しました
- `RequestId`:複数型対応の識別子を実装しました
- `JsonRpcRequest`:全体の組み立てを実装しました

**Error関連**

- `ErrorCode`:標準/カスタムエラーコードを実装しました
- `ErrorMessage`:エラーメッセージを実装しました
- `ErrorData`:オプショナルな追加情報を実装しました
- `JsonRpcError`:エラーの完成形(ファクトリメソッド付き)を実装しました

## 仕様駆動アプローチの価値

「仕様書を読む → テストを書く → 実装する」というサイクルにより、以下のメリットが得られました。

- 仕様への深い理解が得られました
- 実装の正しさをテストで保証できました
- 仕様変更にも柔軟に対応できる設計になりました

## 次回予告

次回([第3回](../jsonrpc-response-value-object/))では、JSON-RPC 2.0の**Response object**を実装します。

Response objectには、成功時とエラー時で排他的な構造(`result`と`error`は同時に存在しない)という制約があります。

この排他性を値オブジェクトで表現する手法を学びます。

- `SuccessResponse`値オブジェクト
- `ErrorResponse`値オブジェクト
- 共通インターフェースによるポリモーフィズム
- 型安全性の確保を実装します

**👉 [第3回:JSON-RPC 2.0 Responseの成功とエラーを型で区別する](../jsonrpc-response-value-object/)**

## 関連リソース

**外部リンク**

{{< linkcard "https://www.jsonrpc.org/specification" >}}

{{< linkcard "https://metacpan.org/pod/Class::Tiny" >}}

{{< linkcard "https://metacpan.org/pod/Test::More" >}}

**シリーズ記事**

- [第1回：Perlで始める値オブジェクト入門](../perl-value-object-intro/)
- [企画書：PerlでJSON-RPC 2.0のオブジェクトを値オブジェクトとして定義してみた](../perl-json-rpc-value-object-series-plan/)

今回実装したコードは、実際のJSON-RPCクライアント/サーバー実装の基盤として利用できます。ぜひご自身のプロジェクトで試してみてください！
