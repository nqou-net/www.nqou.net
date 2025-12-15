---
title: "JSON-RPC 2.0 Responseの成功とエラーを型で区別する - 排他的な値オブジェクト設計"
draft: true
tags:
- perl
- json-rpc
- value-object
- polymorphism
- design-pattern
description: "JSON-RPC 2.0のResponseオブジェクトをSuccessResponseとErrorResponseに分離し、resultとerrorの排他性を型レベルで保証する値オブジェクト設計を実践。ポリモーフィズムで実現する型安全性を学びます。"
---

## シリーズ最終回：型で表現する排他性

> **📚 シリーズ記事**: この記事は「Perl値オブジェクト実践シリーズ」の第3回（最終回）です。
> - 📖 第1回：[Perlで始める値オブジェクト入門](../perl-value-object-intro/)
> - 📖 第2回：[JSON-RPC 2.0のリクエストとエラーを値オブジェクトで堅牢に実装する](../jsonrpc-value-object-outlines/)
> - 📖 第3回：**JSON-RPC 2.0 Responseの成功とエラーを型で区別する**（この記事）

前回までの記事で、値オブジェクトの基礎と`JsonRpcRequest`、`JsonRpcError`の実装を学びました。

今回はシリーズ最終回として、JSON-RPC 2.0の**Response object**を実装します。Responseには、成功時とエラー時で排他的な構造（`result`と`error`は同時に存在してはならない）という制約があります。

この排他性を値オブジェクトで表現する手法を学び、Request → Response フルサイクルの実装を完成させましょう。

## Response objectの仕様を確認する

JSON-RPC 2.0仕様書のResponse objectセクションを見てみよう。

{{< linkcard "https://www.jsonrpc.org/specification" >}}

### 仕様の記述

> When a rpc call is made, the Server MUST reply with a Response, except for in the case of Notifications. The Response is expressed as a single JSON Object, with the following members:
>
> - **jsonrpc**: A String specifying the version of the JSON-RPC protocol. MUST be exactly "2.0".
> - **result**: This member is REQUIRED on success. This member MUST NOT exist if there was an error invoking the method.
> - **error**: This member is REQUIRED on error. This member MUST NOT exist if there was no error triggered during invocation.
> - **id**: This member is REQUIRED. It MUST be the same as the value of the id member in the Request Object.

この仕様から、以下の制約条件が読み取れる。

| フィールド | 型 | 必須/任意 | 制約 |
|-----------|-----|----------|------|
| jsonrpc | String | **MUST** | 正確に "2.0" でなければならない |
| result | Any | **条件付き必須** | 成功時のみ必須、エラー時は**存在してはならない** |
| error | Error object | **条件付き必須** | エラー時のみ必須、成功時は**存在してはならない** |
| id | String/Number/NULL | **REQUIRED** | Requestのidと同じ値 |

**重要な排他性制約**：

> **Either the result member or error member MUST be included, but both members MUST NOT be included.**

`result`と`error`は排他的である。両方が同時に存在してはならず、どちらか一方のみが存在しなければならない。

## 排他性をどう実装するか - 3つのアプローチの比較

この排他性制約を実装する方法は複数ある。それぞれの利点と問題点を比較しよう。

### アプローチ1：単一クラス + フラグ（アンチパターン）

```perl
package JsonRpcResponse;
use Class::Tiny qw(jsonrpc result error id has_result has_error);

sub BUILD {
    my ($self) = @_;
    
    # フラグで判定
    if ($self->has_result && $self->has_error) {
        die "Cannot have both result and error";
    }
}
```

**問題点**：

- 実行時までエラーを検出できない
- `has_result`と`has_error`フラグの管理が煩雑
- 型による安全性が得られない
- コードの意図が不明確

### アプローチ2：単一クラス + バリデーション（従来型）

```perl
package JsonRpcResponse;
use Class::Tiny qw(jsonrpc result error id);

sub BUILD {
    my ($self) = @_;
    
    my $has_result = defined $self->result;
    my $has_error  = defined $self->error;
    
    die "Must have either result or error"
        unless $has_result || $has_error;
    
    die "Cannot have both result and error"
        if $has_result && $has_error;
}
```

**問題点**：

- 実行時エラーに依存
- コンパイル時の安全性なし
- 意図が不明確（成功とエラーが同じ型）

### アプローチ3：別々のクラス + 共通インターフェース（推奨）

**SuccessResponse**と**ErrorResponse**を完全に独立させる設計である。

```perl
package JsonRpc::SuccessResponse;
# resultのみを持つ

package JsonRpc::ErrorResponse;
# errorのみを持つ
```

**利点**：

- 型レベルで排他性を保証
- 構造的に`result`と`error`の同時存在が不可能
- 意図が明確（型が設計を表現）
- コンパイル時の安全性向上（Perlの範囲内で）

本記事では**アプローチ3**を採用します。

## SuccessResponse 値オブジェクトの設計

成功レスポンスを表現する値オブジェクトを段階的に実装する。

### 必須フィールドの定義

仕様上、成功レスポンスは以下のフィールドを持つ：

- `jsonrpc`："2.0"固定（`JsonRpcVersion`オブジェクトを再利用）
- `result`：成功時の戻り値（任意の型）
- `id`：`RequestId`オブジェクト

### テストファーストで実装

まずテストを書く。

```perl
use strict;
use warnings;
use Test::More;
use JSON::PP qw(decode_json);

use_ok('JsonRpc::SuccessResponse');
use_ok('JsonRpcVersion');
use_ok('RequestId');

subtest 'construct valid success response' => sub {
    my $response = JsonRpc::SuccessResponse->new(
        version => JsonRpcVersion->new('2.0'),
        result  => { sum => 42 },
        id      => RequestId->new(1),
    );
    
    isa_ok($response, 'JsonRpc::SuccessResponse');
    is($response->version->value, '2.0');
    is_deeply($response->result, { sum => 42 });
    is($response->id->value, 1);
};

subtest 'various result types' => sub {
    # 文字列
    my $r1 = JsonRpc::SuccessResponse->new(
        version => JsonRpcVersion->new('2.0'),
        result  => "success",
        id      => RequestId->new('abc'),
    );
    is($r1->result, "success");
    
    # 数値
    my $r2 = JsonRpc::SuccessResponse->new(
        version => JsonRpcVersion->new('2.0'),
        result  => 42,
        id      => RequestId->new(2),
    );
    is($r2->result, 42);
    
    # 配列
    my $r3 = JsonRpc::SuccessResponse->new(
        version => JsonRpcVersion->new('2.0'),
        result  => [1, 2, 3],
        id      => RequestId->new(3),
    );
    is_deeply($r3->result, [1, 2, 3]);
    
    # null（undef）も許可
    my $r4 = JsonRpc::SuccessResponse->new(
        version => JsonRpcVersion->new('2.0'),
        result  => undef,
        id      => RequestId->new(4),
    );
    is($r4->result, undef);
};

subtest 'id is required' => sub {
    eval {
        JsonRpc::SuccessResponse->new(
            version => JsonRpcVersion->new('2.0'),
            result  => 42,
            id      => RequestId->new(undef),
        );
    };
    like($@, qr/id is required/i, 'id cannot be null for success response');
};

subtest 'to_json serialization' => sub {
    my $response = JsonRpc::SuccessResponse->new(
        version => JsonRpcVersion->new('2.0'),
        result  => { value => 100 },
        id      => RequestId->new('test-id'),
    );
    
    my $json = $response->to_json;
    my $decoded = decode_json($json);
    
    is($decoded->{jsonrpc}, '2.0');
    is_deeply($decoded->{result}, { value => 100 });
    is($decoded->{id}, 'test-id');
    ok(!exists $decoded->{error}, 'error field must not exist');
};

subtest 'type identification' => sub {
    my $response = JsonRpc::SuccessResponse->new(
        version => JsonRpcVersion->new('2.0'),
        result  => 'ok',
        id      => RequestId->new(1),
    );
    
    ok($response->is_success, 'is_success returns true');
    ok(!$response->is_error, 'is_error returns false');
};

done_testing();
```

### 実装

テストをパスする実装を書く。

```perl
package JsonRpc::SuccessResponse;
use strict;
use warnings;
use Class::Tiny qw(version result id);
use JSON::PP qw(encode_json);

sub BUILD {
    my ($self) = @_;
    
    # versionの検証
    die "version is required and must be a JsonRpcVersion object"
        unless $self->version && ref($self->version) eq 'JsonRpcVersion';
    
    # idの検証（nullは許可しない - 通知には応答しないため）
    die "id is required and must be a RequestId object"
        unless defined $self->id && ref($self->id) eq 'RequestId';
    
    die "id cannot be null for success response"
        unless defined $self->id->value;
    
    # resultは任意の値を許可（undef/nullも含む）
    # バリデーションなし
}

sub is_success {
    return 1;
}

sub is_error {
    return 0;
}

sub to_json {
    my ($self) = @_;
    
    my %data = (
        jsonrpc => $self->version->value,
        result  => $self->result,
        id      => $self->id->value,
    );
    
    return encode_json(\%data);
}

1;
```

**設計のポイント**：

- `result`フィールドのみを持ち、`error`フィールドは存在しない
- `id`がnull（undef）の場合はエラー（通知には応答しない仕様）
- `result`は任意の型を許可（nullも含む）
- 型判定メソッド`is_success`/`is_error`を提供

## ErrorResponse 値オブジェクトの設計

エラーレスポンスを表現する値オブジェクトを実装する。

### 必須フィールドの定義

仕様上、エラーレスポンスは以下のフィールドを持つ：

- `jsonrpc`："2.0"固定
- `error`：`JsonRpcError`オブジェクト（第2回で実装済み）
- `id`：`RequestId`オブジェクト（nullを許可）

### テストファーストで実装

```perl
use strict;
use warnings;
use Test::More;
use JSON::PP qw(decode_json);

use_ok('JsonRpc::ErrorResponse');
use_ok('JsonRpcVersion');
use_ok('JsonRpcError');
use_ok('ErrorCode');
use_ok('ErrorMessage');
use_ok('ErrorData');
use_ok('RequestId');

subtest 'construct valid error response' => sub {
    my $error = JsonRpcError->new(
        code    => ErrorCode->new(ErrorCode::INVALID_REQUEST),
        message => ErrorMessage->new('Invalid Request'),
        data    => ErrorData->new(undef),
    );
    
    my $response = JsonRpc::ErrorResponse->new(
        version => JsonRpcVersion->new('2.0'),
        error   => $error,
        id      => RequestId->new(1),
    );
    
    isa_ok($response, 'JsonRpc::ErrorResponse');
    is($response->version->value, '2.0');
    isa_ok($response->error, 'JsonRpcError');
    is($response->id->value, 1);
};

subtest 'id can be null for parse error' => sub {
    my $error = JsonRpcError->parse_error();
    
    my $response = JsonRpc::ErrorResponse->new(
        version => JsonRpcVersion->new('2.0'),
        error   => $error,
        id      => RequestId->new(undef),
    );
    
    is($response->id->value, undef, 'id can be null for parse error');
};

subtest 'various error types' => sub {
    # Method not found
    my $r1 = JsonRpc::ErrorResponse->new(
        version => JsonRpcVersion->new('2.0'),
        error   => JsonRpcError->method_not_found(),
        id      => RequestId->new('req-001'),
    );
    is($r1->error->code->value, -32601);
    
    # Invalid params with data
    my $r2 = JsonRpc::ErrorResponse->new(
        version => JsonRpcVersion->new('2.0'),
        error   => JsonRpcError->invalid_params({ expected => 'array' }),
        id      => RequestId->new(123),
    );
    is_deeply($r2->error->data->value, { expected => 'array' });
};

subtest 'error must be JsonRpcError object' => sub {
    eval {
        JsonRpc::ErrorResponse->new(
            version => JsonRpcVersion->new('2.0'),
            error   => { code => -32600, message => 'Invalid' },
            id      => RequestId->new(1),
        );
    };
    like($@, qr/must be.*JsonRpcError/i);
};

subtest 'to_json serialization' => sub {
    my $error = JsonRpcError->method_not_found({ method => 'unknown' });
    
    my $response = JsonRpc::ErrorResponse->new(
        version => JsonRpcVersion->new('2.0'),
        error   => $error,
        id      => RequestId->new('err-id'),
    );
    
    my $json = $response->to_json;
    my $decoded = decode_json($json);
    
    is($decoded->{jsonrpc}, '2.0');
    is($decoded->{error}{code}, -32601);
    is($decoded->{error}{message}, 'Method not found');
    is($decoded->{id}, 'err-id');
    ok(!exists $decoded->{result}, 'result field must not exist');
};

subtest 'type identification' => sub {
    my $response = JsonRpc::ErrorResponse->new(
        version => JsonRpcVersion->new('2.0'),
        error   => JsonRpcError->internal_error(),
        id      => RequestId->new(1),
    );
    
    ok($response->is_error, 'is_error returns true');
    ok(!$response->is_success, 'is_success returns false');
};

done_testing();
```

### 実装

```perl
package JsonRpc::ErrorResponse;
use strict;
use warnings;
use Class::Tiny qw(version error id);
use JSON::PP qw(encode_json);

sub BUILD {
    my ($self) = @_;
    
    # versionの検証
    die "version is required and must be a JsonRpcVersion object"
        unless $self->version && ref($self->version) eq 'JsonRpcVersion';
    
    # errorの検証
    die "error is required and must be a JsonRpcError object"
        unless $self->error && ref($self->error) eq 'JsonRpcError';
    
    # idの検証（nullを許可 - Parse errorの場合等）
    die "id is required and must be a RequestId object"
        unless defined $self->id && ref($self->id) eq 'RequestId';
}

sub is_success {
    return 0;
}

sub is_error {
    return 1;
}

sub to_json {
    my ($self) = @_;
    
    my %data = (
        jsonrpc => $self->version->value,
        error   => {
            code    => $self->error->code->value,
            message => $self->error->message->value,
        },
        id => $self->id->value,
    );
    
    # errorのdataフィールドがあれば追加
    my $error_data = $self->error->data->value;
    $data{error}{data} = $error_data if defined $error_data;
    
    return encode_json(\%data);
}

1;
```

**設計のポイント**：

- `error`フィールドのみを持ち、`result`フィールドは存在しない
- `id`はnullを許可（Parse errorの場合、idを取得できない）
- `error`は必ず`JsonRpcError`オブジェクト
- 型判定メソッドで`SuccessResponse`と区別可能

## 共通インターフェースとポリモーフィズムの実装

`SuccessResponse`と`ErrorResponse`を統一的に扱うため、共通インターフェースを定義する。

### Roleパターンの導入

Perlでインターフェース的な役割を実現するため、`Role::Tiny`を使う。

```perl
package JsonRpc::Response;
use strict;
use warnings;
use Role::Tiny;

# このRoleを適用するクラスが実装すべきメソッド
requires qw(version id to_json is_success is_error);

1;
```

### SuccessResponseとErrorResponseでのRole適用

```perl
package JsonRpc::SuccessResponse;
use strict;
use warnings;
use Class::Tiny qw(version result id);
use Role::Tiny::With;
use JSON::PP qw(encode_json);

# 共通インターフェースの適用
with 'JsonRpc::Response';

# ... 既存の実装 ...

1;
```

```perl
package JsonRpc::ErrorResponse;
use strict;
use warnings;
use Class::Tiny qw(version error id);
use Role::Tiny::With;
use JSON::PP qw(encode_json);

# 共通インターフェースの適用
with 'JsonRpc::Response';

# ... 既存の実装 ...

1;
```

### ポリモーフィックな処理の実装

共通インターフェースを通じて、型に関わらず統一的に処理できる。

```perl
sub handle_response {
    my ($response) = @_;
    
    # 共通インターフェースを通じた処理
    say "JSON-RPC Version: " . $response->version->value;
    say "Request ID: " . $response->id->value;
    
    # 型に応じた処理
    if ($response->is_success) {
        say "Success! Result: " . Dumper($response->result);
    } elsif ($response->is_error) {
        say "Error " . $response->error->code->value . ": " 
            . $response->error->message->value;
    }
}

# 使用例
my $success = JsonRpc::SuccessResponse->new(...);
my $error = JsonRpc::ErrorResponse->new(...);

handle_response($success);  # 統一的に処理
handle_response($error);    # 統一的に処理
```

### パターンマッチング風の処理

```perl
sub process_response {
    my ($response) = @_;
    
    return match_response(
        $response,
        success => sub {
            my $res = shift;
            return "Got result: " . Dumper($res->result);
        },
        error => sub {
            my $res = shift;
            my $err = $res->error;
            return sprintf(
                "Got error [%d]: %s", 
                $err->code->value,
                $err->message->value
            );
        }
    );
}

sub match_response {
    my ($response, %handlers) = @_;
    return $handlers{success}->($response) if $response->is_success;
    return $handlers{error}->($response)   if $response->is_error;
    die "Unknown response type";
}
```

**テスト**：

```perl
use strict;
use warnings;
use Test::More;

subtest 'polymorphic handling' => sub {
    my $success = JsonRpc::SuccessResponse->new(
        version => JsonRpcVersion->new('2.0'),
        result  => { value => 42 },
        id      => RequestId->new(1),
    );
    
    my $error = JsonRpc::ErrorResponse->new(
        version => JsonRpcVersion->new('2.0'),
        error   => JsonRpcError->internal_error(),
        id      => RequestId->new(2),
    );
    
    # 共通インターフェースでの処理
    for my $response ($success, $error) {
        ok($response->can('version'), 'has version method');
        ok($response->can('id'), 'has id method');
        ok($response->can('to_json'), 'has to_json method');
        ok($response->can('is_success'), 'has is_success method');
        ok($response->can('is_error'), 'has is_error method');
    }
    
    # 型判定
    ok($success->is_success && !$success->is_error);
    ok($error->is_error && !$error->is_success);
};

done_testing();
```

## ResponseFactory - 適切な型を生成する

レスポンス生成を一元化するファクトリパターンを実装する。

### ファクトリの実装

```perl
package JsonRpc::ResponseFactory;
use strict;
use warnings;
use JsonRpc::SuccessResponse;
use JsonRpc::ErrorResponse;
use JsonRpcVersion;

sub create_success {
    my ($class, %args) = @_;
    
    return JsonRpc::SuccessResponse->new(
        version => JsonRpcVersion->new('2.0'),
        result  => $args{result},
        id      => $args{id},
    );
}

sub create_error {
    my ($class, %args) = @_;
    
    return JsonRpc::ErrorResponse->new(
        version => JsonRpcVersion->new('2.0'),
        error   => $args{error},
        id      => $args{id},
    );
}

# 便利メソッド：標準エラーの生成
sub create_parse_error {
    my ($class, $message) = @_;
    
    return $class->create_error(
        error => JsonRpcError->parse_error($message),
        id    => RequestId->new(undef),
    );
}

sub create_method_not_found {
    my ($class, $method_name, $id) = @_;
    
    return $class->create_error(
        error => JsonRpcError->method_not_found($method_name),
        id    => $id,
    );
}

sub create_invalid_params {
    my ($class, $data, $id) = @_;
    
    return $class->create_error(
        error => JsonRpcError->invalid_params($data),
        id    => $id,
    );
}

sub create_internal_error {
    my ($class, $data, $id) = @_;
    
    return $class->create_error(
        error => JsonRpcError->internal_error($data),
        id    => $id,
    );
}

1;
```

### テスト

```perl
use strict;
use warnings;
use Test::More;

use_ok('JsonRpc::ResponseFactory');

subtest 'create_success' => sub {
    my $response = JsonRpc::ResponseFactory->create_success(
        result => { sum => 42 },
        id     => RequestId->new('test-id'),
    );
    
    isa_ok($response, 'JsonRpc::SuccessResponse');
    ok($response->is_success);
    is_deeply($response->result, { sum => 42 });
};

subtest 'create_error' => sub {
    my $error = JsonRpcError->invalid_request();
    my $response = JsonRpc::ResponseFactory->create_error(
        error => $error,
        id    => RequestId->new(1),
    );
    
    isa_ok($response, 'JsonRpc::ErrorResponse');
    ok($response->is_error);
    is($response->error->code->value, -32600);
};

subtest 'convenience methods' => sub {
    my $r1 = JsonRpc::ResponseFactory->create_parse_error('Invalid JSON');
    ok($r1->is_error);
    is($r1->error->code->value, -32700);
    is($r1->id->value, undef);
    
    my $r2 = JsonRpc::ResponseFactory->create_method_not_found(
        'unknown', 
        RequestId->new(2)
    );
    ok($r2->is_error);
    is($r2->error->code->value, -32601);
};

done_testing();
```

## Request → Response フルサイクル実装

すべてを統合した簡易JSON-RPCサーバーを実装する。

### サーバーの実装

```perl
package JsonRpc::Server;
use strict;
use warnings;
use JsonRpc::ResponseFactory;

sub new {
    my ($class) = @_;
    return bless { methods => {} }, $class;
}

sub register_method {
    my ($self, $name, $handler) = @_;
    $self->{methods}{$name} = $handler;
}

sub handle_request {
    my ($self, $request) = @_;
    
    # 通知の場合は応答しない
    return undef if !defined $request->id->value;
    
    my $method_name = $request->method->value;
    
    # メソッドが存在しない
    unless (exists $self->{methods}{$method_name}) {
        return JsonRpc::ResponseFactory->create_method_not_found(
            $method_name, 
            $request->id
        );
    }
    
    # メソッド実行
    my $handler = $self->{methods}{$method_name};
    my $result = eval {
        $handler->($request->params->value);
    };
    
    # エラーが発生した場合
    if ($@) {
        return JsonRpc::ResponseFactory->create_internal_error(
            $@,
            $request->id
        );
    }
    
    # 成功
    return JsonRpc::ResponseFactory->create_success(
        result => $result,
        id     => $request->id,
    );
}

1;
```

### 完全な動作例

```perl
use strict;
use warnings;
use JsonRpc::Server;
use JsonRpcRequest;
use JsonRpcVersion;
use MethodName;
use RequestParams;
use RequestId;

# サーバーのセットアップ
my $server = JsonRpc::Server->new;

# メソッドの登録
$server->register_method('sum', sub {
    my ($params) = @_;
    return $params->[0] + $params->[1];
});

$server->register_method('subtract', sub {
    my ($params) = @_;
    return $params->[0] - $params->[1];
});

$server->register_method('get_user', sub {
    my ($params) = @_;
    return {
        id   => $params->{user_id},
        name => "User $params->{user_id}",
    };
});

# リクエストの処理例
my $request1 = JsonRpcRequest->new(
    version => JsonRpcVersion->new('2.0'),
    method  => MethodName->new('sum'),
    params  => RequestParams->new([1, 2]),
    id      => RequestId->new(1),
);

my $response1 = $server->handle_request($request1);

if ($response1->is_success) {
    say "Result: " . $response1->result;  # "Result: 3"
    say $response1->to_json;
    # {"jsonrpc":"2.0","result":3,"id":1}
}

# エラーケース
my $request2 = JsonRpcRequest->new(
    version => JsonRpcVersion->new('2.0'),
    method  => MethodName->new('unknown_method'),
    params  => RequestParams->new([]),
    id      => RequestId->new(2),
);

my $response2 = $server->handle_request($request2);

if ($response2->is_error) {
    my $err = $response2->error;
    say "Error " . $err->code->value . ": " . $err->message->value;
    # "Error -32601: Method not found"
    say $response2->to_json;
    # {"jsonrpc":"2.0","error":{"code":-32601,"message":"Method not found"},"id":2}
}

# 通知（応答なし）
my $notification = JsonRpcRequest->new(
    version => JsonRpcVersion->new('2.0'),
    method  => MethodName->new('sum'),
    params  => RequestParams->new([10, 20]),
    id      => RequestId->new(undef),
);

my $response3 = $server->handle_request($notification);
say "Response: " . (defined $response3 ? "exists" : "none");
# "Response: none"
```

### 統合テスト

```perl
use strict;
use warnings;
use Test::More;

use JsonRpc::Server;
use JsonRpcRequest;
use JsonRpcVersion;
use MethodName;
use RequestParams;
use RequestId;

my $server = JsonRpc::Server->new;

$server->register_method('multiply', sub {
    my ($params) = @_;
    return $params->[0] * $params->[1];
});

subtest 'successful request cycle' => sub {
    my $request = JsonRpcRequest->new(
        version => JsonRpcVersion->new('2.0'),
        method  => MethodName->new('multiply'),
        params  => RequestParams->new([6, 7]),
        id      => RequestId->new('req-001'),
    );
    
    my $response = $server->handle_request($request);
    
    ok($response->is_success, 'response is success');
    is($response->result, 42, 'result is correct');
    is($response->id->value, 'req-001', 'id matches request');
};

subtest 'method not found' => sub {
    my $request = JsonRpcRequest->new(
        version => JsonRpcVersion->new('2.0'),
        method  => MethodName->new('divide'),
        params  => RequestParams->new([10, 2]),
        id      => RequestId->new('req-002'),
    );
    
    my $response = $server->handle_request($request);
    
    ok($response->is_error, 'response is error');
    is($response->error->code->value, -32601, 'error code is method_not_found');
};

subtest 'notification has no response' => sub {
    my $notification = JsonRpcRequest->new(
        version => JsonRpcVersion->new('2.0'),
        method  => MethodName->new('multiply'),
        params  => RequestParams->new([2, 3]),
        id      => RequestId->new(undef),
    );
    
    my $response = $server->handle_request($notification);
    
    is($response, undef, 'notification returns no response');
};

subtest 'internal error handling' => sub {
    $server->register_method('failing_method', sub {
        die "Something went wrong";
    });
    
    my $request = JsonRpcRequest->new(
        version => JsonRpcVersion->new('2.0'),
        method  => MethodName->new('failing_method'),
        params  => RequestParams->new([]),
        id      => RequestId->new('req-003'),
    );
    
    my $response = $server->handle_request($request);
    
    ok($response->is_error, 'response is error');
    is($response->error->code->value, -32603, 'error code is internal_error');
};

done_testing();
```

## 型安全性がもたらす利点

### 排他性を型で保証

`SuccessResponse`と`ErrorResponse`を分離することで、以下のメリットが得られる。

**構造的な排他性**  
`result`と`error`が同じオブジェクトに同時に存在することが構造的に不可能である。

**意図の明確化**  
型名を見れば、それが成功かエラーかが一目瞭然である。

**バグの早期発見**  
型の不一致は実行時に即座に検出される。

### コードの可読性向上

```perl
# 従来の実装（型が不明確）
sub process {
    my ($response) = @_;
    
    if (exists $response->{result}) {
        # 成功処理
    } elsif (exists $response->{error}) {
        # エラー処理
    }
}

# 値オブジェクトによる実装（型が明確）
sub process {
    my ($response) = @_;
    
    if ($response->is_success) {
        # $response->result が確実に存在
    } elsif ($response->is_error) {
        # $response->error が確実に存在
    }
}
```

### 保守性とリファクタリング安全性

値オブジェクトを使うことで、以下が可能になる。

**一箇所での変更**  
レスポンスの構造変更は該当クラスのみで完結する。

**型による探索**  
`SuccessResponse`を使っている箇所を簡単に検索できる。

**テストの容易さ**  
各型のテストを独立して書ける。

## まとめ：3回シリーズの総括

### 学んだ設計原則

**第1回：値オブジェクトの基礎**  
不変性、等価性、自己バリデーションの重要性を`EmailAddress`クラスで学びました。

**第2回：RequestとErrorの実装**  
JSON-RPC 2.0仕様から制約を読み取り、テスト駆動で値オブジェクトを実装しました。

**第3回：Responseと排他性の実現**  
`SuccessResponse`と`ErrorResponse`を分離し、排他性を型レベルで保証しました。

### 完成した全体像

シリーズを通して、JSON-RPC 2.0の完全な値オブジェクト実装が完成した。

**実装した値オブジェクト一覧**：

- `JsonRpcVersion`：プロトコルバージョン
- `MethodName`：メソッド名
- `RequestParams`：リクエストパラメータ
- `RequestId`：リクエスト識別子
- `JsonRpcRequest`：リクエストオブジェクト
- `ErrorCode`：エラーコード
- `ErrorMessage`：エラーメッセージ
- `ErrorData`：エラー追加情報
- `JsonRpcError`：エラーオブジェクト
- `JsonRpc::SuccessResponse`：成功レスポンス
- `JsonRpc::ErrorResponse`：エラーレスポンス
- `JsonRpc::ResponseFactory`：レスポンスファクトリ
- `JsonRpc::Server`：簡易サーバー

### 設計パターンの体得

**値オブジェクトパターン**  
ドメインの概念を型として表現し、バリデーションを一元化した。

**ファクトリパターン**  
オブジェクト生成ロジックを集約し、クライアントコードを簡素化した。

**Roleパターン**  
共通インターフェースを定義し、ポリモーフィズムを実現した。

**テスト駆動開発（TDD）**  
テストファーストで進めることで、仕様理解と品質保証を両立した。

## さらなる学習への導線

### 実務への応用

**JSON-RPC 2.0サーバー/クライアントの完全実装**  
本シリーズの実装をベースに、プロダクション品質のライブラリを構築できる。

**マイクロサービスでの活用**  
JSON-RPCは軽量で明確なセマンティクスを持つため、サービス間通信に適している。

**Model Context Protocol（MCP）への適用**  
AI/LLM統合の標準プロトコルであるMCPは、JSON-RPC 2.0をベースにしている。

{{< linkcard "https://modelcontextprotocol.io/" >}}

### 設計パターンの深化

**ドメイン駆動設計（DDD）**  
値オブジェクトはDDDの基本的なビルディングブロックである。エンティティ、集約、リポジトリなど、さらなるパターンを学ぼう。

**関数型プログラミングのパターン**  
Result型、Maybe型、パターンマッチングなど、型安全性を高める関数型の概念を探求しよう。

**型駆動開発（Type-Driven Development）**  
型を設計の出発点とし、制約を型で表現する手法をさらに深めよう。

### 他の言語での実装

**TypeScript**  
型システムの恩恵を最大限に受けられる。discriminated unionsで排他性を表現できる。

**Rust**  
Result型とパターンマッチングで、より強力な型安全性を実現できる。

**Go**  
インターフェースと構造体で、シンプルかつ効率的な実装が可能である。

### 推奨リソース

**仕様とプロトコル**

{{< linkcard "https://www.jsonrpc.org/specification" >}}

{{< linkcard "https://spec.open-rpc.org/" >}}

**Perlエコシステム**

{{< linkcard "https://metacpan.org/pod/Class::Tiny" >}}

{{< linkcard "https://metacpan.org/pod/Role::Tiny" >}}

{{< linkcard "https://metacpan.org/pod/Test::More" >}}

**設計思想**

- "Domain-Driven Design" by Eric Evans
- "Patterns of Enterprise Application Architecture" by Martin Fowler
- "Refactoring: Improving the Design of Existing Code" by Martin Fowler

## 最後に

3回にわたるシリーズを通して、値オブジェクトという設計パターンの威力を体験していただけたと思います。

プリミティブ型の呪縛から解放され、ドメインの概念を型として表現することで、コードの可読性、保守性、安全性が飛躍的に向上する。

JSON-RPC 2.0という具体的な仕様を題材にすることで、仕様駆動開発の重要性も実感できたのではないだろうか。

ぜひ、ご自身のプロジェクトで値オブジェクトを活用してみてほしい。最初は手間に感じるかもしれないが、長期的には大きなリターンをもたらすはずである。

型で表現する設計の旅は、ここからが本当のスタートである。Happy coding!
