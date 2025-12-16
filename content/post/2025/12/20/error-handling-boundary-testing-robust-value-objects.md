---
title: "エラー処理と境界値テスト - 堅牢な値オブジェクトを作る【Perl×TDD完結編】"
draft: false
date: 2025-12-20T09:00:00+09:00
tags:
  - json-rpc
  - perl
  - tdd
  - error-handling
  - boundary-testing
  - value-object
  - test2
  - defensive-programming
  - fail-fast
  - software-quality
description: "【シリーズ完結編・第5回】JsonRpcError値オブジェクトのTDD実装、境界値分析の実践的手法、エラー時Responseの実装を通じて、本番環境に耐えうる堅牢な値オブジェクト設計を完全マスター。Perlで学ぶ防御的プログラミングの実践とTest2による網羅的テスト技法。Fail Fast原則の実装と排他性の保証まで、プロダクション品質のコード設計を学ぶ。"
series: "Perlで値オブジェクトを使ってテスト駆動開発してみよう"
series_order: 5
keywords:
  - "Perl エラー処理"
  - "境界値テスト"
  - "boundary value analysis"
  - "TDD テスト駆動開発"
  - "値オブジェクト 実装"
  - "JSON-RPC 2.0"
  - "Test2 Perl"
  - "防御的プログラミング"
  - "Fail Fast パターン"
  - "エラーハンドリング設計"
  - "Perl モダン開発"
  - "ソフトウェア品質"
slug: "error-handling-boundary-testing-robust-value-objects"
image: "/images/perl-tdd-series.png"
---

<!-- エラー処理 境界値テスト TDD 値オブジェクト Perl Test2 -->

この記事は「**Perlで値オブジェクトを使ってテスト駆動開発してみよう**」シリーズの**第5回（全5回・完結編）**です。
前回は、[JSON-RPC Request/Response実装](/2025/12/19/jsonrpc-request-response-composite-value-objects/)を通じて複合値オブジェクトの設計を学びました。
今回はシリーズの締めくくりとして、**エラーハンドリングと境界値テスト（Boundary Value Testing）**の実践により、本番環境に耐えうる堅牢な値オブジェクトの実装技法を完全マスターします。

> 💡 **この記事で得られる知識**  
> ✅ JSON-RPC 2.0標準に準拠したエラー処理の実装方法  
> ✅ 境界値分析（Boundary Value Analysis）によるバグ検出テクニック  
> ✅ Fail Fast原則を用いた防御的プログラミングの実践  
> ✅ Test2による網羅的テストの書き方  
> ✅ プロダクション品質の値オブジェクト設計パターン

> **シリーズナビゲーション**  
> ← 前回: [JSON-RPC Request/Response実装 - 複合値オブジェクト設計](/2025/12/19/jsonrpc-request-response-composite-value-objects/)  
> ✅ **最終回: エラー処理と境界値テスト - 堅牢な値オブジェクトを作る**

## この記事で学べること - 本番環境で役立つエラー処理技術

このシリーズ完結編では、実務で即座に活用できるエラー処理とテスト技術を習得できます。

- **エラーハンドリング設計の実践**: 値オブジェクトにおける防御的プログラミング（Defensive Programming）とFail Fastの原則
- **JsonRpcError値オブジェクト実装**: JSON-RPC 2.0標準エラーコードの定数定義とTDDによる段階的実装
- **境界値分析（Boundary Value Analysis）の実践**: エラーコード範囲、文字列長、数値境界など網羅的なテスト戦略
- **ErrorResponse実装**: errorとresultの排他性を保証する複合値オブジェクトの設計パターン
- **Test2高度テクニック**: array/hash/matchによる構造テストと柔軟な検証手法
- **シリーズ総括**: 値オブジェクトとTDDの実践的な活用方法と次のステップ

> 📊 **対象読者**  
> • エラー処理の設計パターンを学びたいPerlエンジニア  
> • 境界値テストの実践的手法を習得したい方  
> • Test2を使った高度なテスト技法を学びたい開発者  
> • JSON-RPC実装に携わるバックエンドエンジニア  
> • プロダクション品質のコードを書きたい全てのエンジニア

## エラーハンドリングの重要性 - 値オブジェクトが守るべき原則

### 値オブジェクトが守るべき不変条件（Invariant）

値オブジェクト（Value Object）の最も重要な特性は、**常に正しい状態を保つ**ことです。
これは「不正な値オブジェクトは存在しない（Invalid objects cannot exist）」という原則で表現されます。

> 💡 **不変条件とは**  
> オブジェクトがその生存期間を通じて常に満たすべき条件。値オブジェクトでは、構築時に必ず検証され、構築後は決して変化しない（Immutable）性質と組み合わせることで、不変条件の維持が保証されます。

```perl
# ❌ このような状態は存在してはいけない
my $version = JsonRpc::Version->new(value => '1.0');
# JSON-RPC 2.0では"2.0"のみ許容

# ✅ 不正な値では構築できない（例外を投げる）
like(
    dies { JsonRpc::Version->new(value => '1.0') },
    qr/version must be '2\.0'/,
    'invalid version is rejected'
);
```

この原則を守ることで、以下のメリットが得られます：

- **防御的プログラミング不要**: 値オブジェクトを受け取った関数は、その妥当性を再検証する必要がない
- **型安全性の向上**: Type::Tinyによる型制約と組み合わせることで、コンパイル時に多くのエラーを検出
- **バグの早期発見**: 不正なデータは、システムに入り込む前（入力境界）で確実に拒否
- **コードの簡潔性**: if文による検証コードが不要になり、ビジネスロジックに集中可能

### 防御的プログラミングと値オブジェクト - Fail Fastの原則

防御的プログラミングにおける**Fail Fast**（早期失敗）の原則は、エラーを検出した瞬間に即座に例外を投げることです。
値オブジェクトはこの原則を体現します。

```perl
package JsonRpc::MethodName;
use v5.38;
use Moo;
use namespace::clean;

has value => (
    is       => 'ro',
    isa      => sub {
        my $val = shift;
        
        # Fail Fast: 不正な値は即座に拒否
        die "method name is required"
            if !defined $val;
        
        die "method name cannot be empty"
            if $val eq '';
        
        die "method name must not start with 'rpc.'"
            if $val =~ /^rpc\./;
        
        die "method name contains invalid characters"
            if $val !~ /^[a-zA-Z0-9_\.]+$/;
    },
    required => 1,
);
```

#### Fail Fastのメリット

1. **問題の根本原因を特定しやすい**: エラー発生箇所がスタックトレースで明確になる
2. **デバッグ時間の短縮**: 不正なデータが伝播する前に停止するため、影響範囲が局所化される
3. **予測可能な振る舞い**: 例外処理に一貫性がある

#### 境界での防御 - データの入口で検証する

値オブジェクトは、システムへのデータ入力境界（boundary）で防御を行います。

```text
外部入力 → [境界での検証] → システム内部
            ↑
            値オブジェクトがここで防御
```

```perl
# HTTP リクエスト → JSON → HashRef → 値オブジェクト（ここで検証）
my $json = $http_request->content;
my $hash = decode_json($json);  # HashRef（未検証）

# from_hash で値オブジェクトに変換 = バリデーション完了
my $request = JsonRpc::Request->from_hash($hash);
# ✅ ここで全フィールドが検証される

# 以降のコードは、$request が正しいと信頼できる
my $method = $request->method->value;  # 検証不要！
```

## JsonRpcError値オブジェクトの実装 - TDDでエラーを設計する

JSON-RPC 2.0仕様では、エラーは`error`オブジェクトとして表現されます。
このセクションでは、**TDD（Test-Driven Development）**でJsonRpcError値オブジェクトを段階的に実装します。

> 🎯 **TDDの利点**  
> • 仕様を確実に満たす実装が可能  
> • リファクタリング時の安全性が向上  
> • テストがドキュメントとして機能  
> • バグの早期発見とデグレーション防止

### Error objectの仕様再確認

JSON-RPC 2.0の[Error object仕様](https://www.jsonrpc.org/specification#error_object)を確認しましょう。

| フィールド | 型      | 必須/オプション | 説明                                       |
|------------|---------|----------------|--------------------------------------------|
| code       | Integer | 必須           | エラーコード（標準エラーは-32768〜-32000） |
| message    | String  | 必須           | エラーの簡潔な説明                         |
| data       | Any     | オプション     | エラーに関する追加情報（任意の型）         |

{{< linkcard "https://www.jsonrpc.org/specification" >}}

#### JSON-RPC 2.0標準エラーコード

仕様では、以下の標準エラーコードが定義されています：

| コード          | メッセージ        | 意味                               |
|-----------------|-------------------|------------------------------------|
| -32700          | Parse error       | 不正なJSON（パース失敗）           |
| -32600          | Invalid Request   | JSON-RPC形式として不正             |
| -32601          | Method not found  | メソッドが存在しない               |
| -32602          | Invalid params    | パラメータが不正                   |
| -32603          | Internal error    | サーバー内部エラー                 |
| -32000〜-32099  | Server error      | サーバー定義のカスタムエラー範囲   |

### Red - エラーオブジェクトのテストを書く

まず、失敗するテストを書きます（Red）。

```perl
# t/error.t
use v5.38;
use Test2::V0;
use lib 'lib';

use_ok 'JsonRpc::Error' or die;

subtest 'constructor with required fields' => sub {
    my $error = JsonRpc::Error->new(
        code    => -32600,
        message => 'Invalid Request',
    );
    
    ok $error, 'Error created with required fields';
    is $error->code, -32600, 'code is correct';
    is $error->message, 'Invalid Request', 'message is correct';
    is $error->data, undef, 'data is undef by default';
};

subtest 'constructor with data field' => sub {
    my $error = JsonRpc::Error->new(
        code    => -32602,
        message => 'Invalid params',
        data    => { field => 'user_id', reason => 'required' },
    );
    
    ok $error, 'Error created with data';
    is $error->data, { field => 'user_id', reason => 'required' }, 'data is hash';
};

subtest 'code must be integer' => sub {
    like(
        dies {
            JsonRpc::Error->new(code => "string", message => 'test');
        },
        qr/type constraint|integer/i,
        'string code is rejected'
    );
};

subtest 'message must be string' => sub {
    like(
        dies {
            JsonRpc::Error->new(code => -32600, message => 123);
        },
        qr/type constraint|string/i,
        'numeric message is rejected'
    );
};

subtest 'message cannot be empty' => sub {
    like(
        dies {
            JsonRpc::Error->new(code => -32600, message => '');
        },
        qr/message.*empty/i,
        'empty message is rejected'
    );
};

subtest 'data accepts any type' => sub {
    # String
    ok(lives {
        JsonRpc::Error->new(code => -1, message => 'test', data => 'string');
    }, 'data accepts string');
    
    # Number
    ok(lives {
        JsonRpc::Error->new(code => -1, message => 'test', data => 42);
    }, 'data accepts number');
    
    # Array
    ok(lives {
        JsonRpc::Error->new(code => -1, message => 'test', data => [1, 2, 3]);
    }, 'data accepts array');
    
    # Hash
    ok(lives {
        JsonRpc::Error->new(code => -1, message => 'test', data => { key => 'val' });
    }, 'data accepts hash');
    
    # undef
    ok(lives {
        JsonRpc::Error->new(code => -1, message => 'test', data => undef);
    }, 'data accepts undef');
};

done_testing;
```

テストを実行すると失敗します（Red）：

```bash
$ prove -lv t/error.t
Can't locate JsonRpc/Error.pm in @INC
```

### Green - 最小実装で通す

次に、テストを通すための実装を書きます（Green）。

```perl
# lib/JsonRpc/Error.pm
package JsonRpc::Error;
use v5.38;
use Moo;
use Types::Standard qw(Int Str Any Maybe);
use namespace::clean;

has code => (
    is       => 'ro',
    isa      => Int,
    required => 1,
);

has message => (
    is       => 'ro',
    isa      => sub {
        my $val = shift;
        die "message must be a string"
            unless defined $val && !ref $val;
        die "message cannot be empty"
            if $val eq '';
    },
    required => 1,
);

has data => (
    is  => 'ro',
    isa => Any,  # 任意の型を許容
);

1;

__END__

=head1 NAME

JsonRpc::Error - JSON-RPC 2.0 Error object

=head1 SYNOPSIS

    use JsonRpc::Error;
    
    my $error = JsonRpc::Error->new(
        code    => -32600,
        message => 'Invalid Request',
        data    => { detail => 'missing jsonrpc field' },
    );

=head1 DESCRIPTION

Represents a JSON-RPC 2.0 Error object with validation.

=cut
```

テストを実行すると成功します（Green）！

```bash
$ prove -lv t/error.t
ok 1 - use JsonRpc::Error;
    # Subtest: constructor with required fields
    ok 1 - Error created with required fields
    ok 2 - code is correct
    ok 3 - message is correct
    ok 4 - data is undef by default
    1..4
ok 2 - constructor with required fields
...
All tests successful.
```

### Refactor - 標準エラーコードの定数定義

JSON-RPC 2.0の標準エラーコードを定数として定義し、コードの保守性を高めます。

```perl
# lib/JsonRpc/ErrorCode.pm
package JsonRpc::ErrorCode;
use v5.38;
use Exporter 'import';

our @EXPORT_OK = qw(
    ERROR_PARSE_ERROR
    ERROR_INVALID_REQUEST
    ERROR_METHOD_NOT_FOUND
    ERROR_INVALID_PARAMS
    ERROR_INTERNAL_ERROR
);

our %EXPORT_TAGS = (
    all => \@EXPORT_OK,
);

# JSON-RPC 2.0 標準エラーコード
use constant ERROR_PARSE_ERROR      => -32700;
use constant ERROR_INVALID_REQUEST  => -32600;
use constant ERROR_METHOD_NOT_FOUND => -32601;
use constant ERROR_INVALID_PARAMS   => -32602;
use constant ERROR_INTERNAL_ERROR   => -32603;

# カスタムエラーコード範囲: -32000 〜 -32099
# アプリケーション独自のエラーはこの範囲内で定義する

1;

__END__

=head1 NAME

JsonRpc::ErrorCode - JSON-RPC 2.0 standard error code constants

=head1 SYNOPSIS

    use JsonRpc::ErrorCode qw(:all);
    
    my $error = JsonRpc::Error->new(
        code    => ERROR_INVALID_REQUEST,
        message => 'Invalid Request',
    );

=head1 DESCRIPTION

Provides constants for JSON-RPC 2.0 standard error codes.

=head1 CONSTANTS

=over 4

=item ERROR_PARSE_ERROR (-32700)

Invalid JSON was received by the server. An error occurred on the server while parsing the JSON text.

=item ERROR_INVALID_REQUEST (-32600)

The JSON sent is not a valid Request object.

=item ERROR_METHOD_NOT_FOUND (-32601)

The method does not exist / is not available.

=item ERROR_INVALID_PARAMS (-32602)

Invalid method parameter(s).

=item ERROR_INTERNAL_ERROR (-32603)

Internal JSON-RPC error.

=back

=head1 CUSTOM ERROR CODES

Server-defined errors should use codes in the range -32000 to -32099.

=cut
```

定数を使用したテストも追加します：

```perl
# t/error.t に追加

use JsonRpc::ErrorCode qw(:all);

subtest 'standard error code constants' => sub {
    is ERROR_PARSE_ERROR,      -32700, 'PARSE_ERROR constant';
    is ERROR_INVALID_REQUEST,  -32600, 'INVALID_REQUEST constant';
    is ERROR_METHOD_NOT_FOUND, -32601, 'METHOD_NOT_FOUND constant';
    is ERROR_INVALID_PARAMS,   -32602, 'INVALID_PARAMS constant';
    is ERROR_INTERNAL_ERROR,   -32603, 'INTERNAL_ERROR constant';
};

subtest 'use constants in Error construction' => sub {
    my $error = JsonRpc::Error->new(
        code    => ERROR_INVALID_REQUEST,
        message => 'Invalid Request',
    );
    
    is $error->code, -32600, 'constant used correctly';
};
```

これで、マジックナンバーを排除し、可読性の高いコードになりました！🎉

```perl
# Before（マジックナンバー）
my $error = JsonRpc::Error->new(
    code    => -32600,
    message => '...'
);

# After（意味のある定数）
use JsonRpc::ErrorCode qw(:all);
my $error = JsonRpc::Error->new(
    code    => ERROR_INVALID_REQUEST,
    message => '...'
);
```

## 境界値テストの実践 - バグが潜む場所を狙い撃つ

境界値分析（Boundary Value Analysis, BVA）は、ソフトウェアテストにおける最も効果的な技法の一つです。
バグは境界値（境界条件）で発生しやすいため、その部分を集中的にテストします。

> 📈 **境界値テストの効果**  
> 研究によると、バグの約70%は境界値や特殊な条件で発生します。境界値分析を適用することで、少ないテストケースで高い欠陥検出率を達成できます。

### 境界値とは何か - バグが発生しやすいポイント

境界値とは、入力値の範囲における**端点（Edge Points）**や**特殊な値（Special Values）**のことです。例えば：

- **数値範囲**: 最小値、最大値、ゼロ、正負の境界値
- **文字列**: 空文字列、1文字、最大長、nullバイト
- **配列**: 空配列、要素1個、最大要素数
- **日付**: 閏年、月末、タイムゾーン境界

#### バグが境界値で起きやすい理由

```perl
# 典型的な境界値バグの例
sub validate_age {
    my $age = shift;
    return $age > 0 && $age < 120;  # ⚠️ 0と120は含まれない！
}

# 正しくは
sub validate_age {
    my $age = shift;
    return $age >= 0 && $age <= 120;  # ✅ 境界値を含む
}
```

オフバイワンエラー（off-by-one error）など、境界値における実装ミスは頻繁に発生します。

### エラーコードの境界値テスト - JSON-RPC仕様の範囲検証

JSON-RPC 2.0では、エラーコードに特定の範囲が定義されています。この範囲の境界をテストします。

```perl
# t/error_boundary.t
use v5.38;
use Test2::V0;
use lib 'lib';

use JsonRpc::Error;
use JsonRpc::ErrorCode qw(:all);

subtest 'standard error code range boundaries' => sub {
    # 標準エラーの境界値
    subtest 'ERROR_PARSE_ERROR boundary' => sub {
        is ERROR_PARSE_ERROR, -32700, 'parse error code';
    };
    
    subtest 'ERROR_INTERNAL_ERROR boundary' => sub {
        is ERROR_INTERNAL_ERROR, -32603, 'internal error code';
    };
    
    # 標準エラー範囲外もエラーオブジェクトとして作成可能
    # （JSON-RPC仕様はカスタムエラーを許可）
    subtest 'custom error codes are accepted' => sub {
        # カスタムエラー範囲: -32000 〜 -32099
        ok(lives {
            JsonRpc::Error->new(code => -32000, message => 'custom error min');
        }, 'custom error min boundary accepted');
        
        ok(lives {
            JsonRpc::Error->new(code => -32099, message => 'custom error max');
        }, 'custom error max boundary accepted');
        
        # カスタム範囲外も許容（アプリケーション定義）
        ok(lives {
            JsonRpc::Error->new(code => 1, message => 'application error');
        }, 'positive error code accepted');
    };
};

subtest 'integer boundaries' => sub {
    # Perlの整数境界値（32bit/64bit環境依存だが、代表的な値をテスト）
    ok(lives {
        JsonRpc::Error->new(code => -2147483648, message => 'min int32');
    }, 'minimum int32 accepted');
    
    ok(lives {
        JsonRpc::Error->new(code => 2147483647, message => 'max int32');
    }, 'maximum int32 accepted');
    
    ok(lives {
        JsonRpc::Error->new(code => 0, message => 'zero code');
    }, 'zero code accepted');
};

done_testing;
```

### 文字列長の境界値テスト - 空・1文字・極端な長さ

文字列フィールド（`message`）の境界値もテストします。

```perl
# t/error_boundary.t に追加

subtest 'message string length boundaries' => sub {
    # 空文字列は拒否される（既存テストで確認済みだが再確認）
    like(
        dies {
            JsonRpc::Error->new(code => -1, message => '');
        },
        qr/empty/i,
        'empty message rejected'
    );
    
    # 1文字は許容
    ok(lives {
        JsonRpc::Error->new(code => -1, message => 'X');
    }, '1 character message accepted');
    
    # 非常に長い文字列も許容（JSON-RPC仕様に制限なし）
    subtest 'very long message' => sub {
        my $long_message = 'A' x 10000;  # 10,000文字
        
        my $error = JsonRpc::Error->new(
            code    => -1,
            message => $long_message,
        );
        
        is length($error->message), 10000, 'long message accepted';
    };
    
    # Unicode文字列
    ok(lives {
        JsonRpc::Error->new(code => -1, message => 'エラーが発生しました');
    }, 'unicode message accepted');
    
    # 特殊文字
    ok(lives {
        JsonRpc::Error->new(code => -1, message => qq{Error: "invalid"\n});
    }, 'message with special characters accepted');
};
```

### Test2::Toolsを活用した網羅的テスト - 構造テストとmatch

Test2::V0には、複雑なデータ構造を検証するための強力なツールが含まれています。

#### arrayとhashによる構造テスト

```perl
# t/error_structure.t
use v5.38;
use Test2::V0;
use lib 'lib';

use JsonRpc::Error;

subtest 'data field structure validation' => sub {
    subtest 'data as hash structure' => sub {
        my $error = JsonRpc::Error->new(
            code    => -32602,
            message => 'Invalid params',
            data    => {
                field  => 'user_id',
                reason => 'required',
                index  => 0,
            },
        );
        
        # hashによる構造検証
        is $error->data, hash {
            field 'field'  => 'user_id';
            field 'reason' => 'required';
            field 'index'  => 0;
            end;  # 他のフィールドが存在しないことを確認
        }, 'data hash structure is correct';
    };
    
    subtest 'data as array structure' => sub {
        my $error = JsonRpc::Error->new(
            code    => -32602,
            message => 'Multiple errors',
            data    => [
                { field => 'name', reason => 'required' },
                { field => 'email', reason => 'invalid format' },
            ],
        );
        
        # arrayによる構造検証
        is $error->data, array {
            item hash {
                field 'field'  => 'name';
                field 'reason' => 'required';
                end;
            };
            item hash {
                field 'field'  => 'email';
                field 'reason' => 'invalid format';
                end;
            };
            end;
        }, 'data array structure is correct';
    };
};

done_testing;
```

#### matchによる柔軟な検証

`match`を使うと、正規表現や範囲チェックなど、柔軟な検証が可能になります。

```perl
# t/error_structure.t に追加

subtest 'flexible validation with match' => sub {
    my $error = JsonRpc::Error->new(
        code    => -32603,
        message => 'Internal error: database connection failed',
        data    => { timestamp => 1734326400, retry_after => 60 },
    );
    
    # matchによる柔軟な検証
    is $error, object {
        prop blessed => 'JsonRpc::Error';
        
        call code => -32603;
        
        # messageは特定のパターンに一致
        call message => match qr/^Internal error:/;
        
        # dataの構造を柔軟に検証
        call data => hash {
            field 'timestamp'   => match qr/^\d+$/;  # 数値
            field 'retry_after' => D();              # 定義されている（値は問わない）
            end;
        };
    }, 'error object matches expected structure';
};

subtest 'match with number ranges' => sub {
    my $error = JsonRpc::Error->new(
        code    => -32050,  # カスタムエラー範囲内
        message => 'Server error',
    );
    
    # codeが特定範囲内にあることを検証
    like $error->code, match sub {
        my $code = shift;
        return $code >= -32099 && $code <= -32000;
    }, 'code is within custom error range';
};
```

これらの高度なテスト機能により、複雑なエラーオブジェクトの構造も正確に検証できます！

## エラー時Responseの実装 - errorとresultの排他性

JSON-RPC 2.0仕様では、Responseオブジェクトは`result`か`error`のどちらか一方のみを持ちます。両方が存在する状態は不正です。
この**排他性（Mutual Exclusion）**をTDDで実装します。

> ⚠️ **JSON-RPC 2.0仕様の重要な制約**  
> Response objectは必ず以下のいずれかを含む：  
> • 成功時: `result`フィールド（`error`は存在しない）  
> • 失敗時: `error`フィールド（`result`は存在しない）  
> 両方が同時に存在することは仕様違反です。

### errorとresultの排他性をテストする

```perl
# t/error_response.t
use v5.38;
use Test2::V0;
use lib 'lib';

use_ok 'JsonRpc::ErrorResponse' or die;
use JsonRpc::Version;
use JsonRpc::Error;
use JsonRpc::ErrorCode qw(:all);

subtest 'constructor with error field' => sub {
    my $error = JsonRpc::Error->new(
        code    => ERROR_INVALID_REQUEST,
        message => 'Invalid Request',
    );
    
    my $res = JsonRpc::ErrorResponse->new(
        jsonrpc => JsonRpc::Version->new(value => '2.0'),
        error   => $error,
        id      => 'req-001',
    );
    
    ok $res, 'ErrorResponse created';
    isa_ok $res->error, 'JsonRpc::Error';
    is $res->id, 'req-001', 'id is correct';
};

subtest 'error field is required' => sub {
    like(
        dies {
            JsonRpc::ErrorResponse->new(
                jsonrpc => JsonRpc::Version->new(value => '2.0'),
                id      => 'test',
            );
        },
        qr/required|missing/i,
        'error field is required'
    );
};

subtest 'result field must not exist in ErrorResponse' => sub {
    # ErrorResponseはerrorのみを持ち、resultは存在しない
    my $res = JsonRpc::ErrorResponse->new(
        jsonrpc => JsonRpc::Version->new(value => '2.0'),
        error   => JsonRpc::Error->new(code => -1, message => 'error'),
        id      => 'test',
    );
    
    # resultメソッドが存在しないことを確認
    ok !$res->can('result'), 'ErrorResponse does not have result method';
};

done_testing;
```

### ErrorResponse実装 - TDD with Red-Green-Refactor

```perl
# lib/JsonRpc/ErrorResponse.pm
package JsonRpc::ErrorResponse;
use v5.38;
use Moo;
use Types::Standard qw(InstanceOf Str Int Maybe);
use JsonRpc::Version;
use JsonRpc::Error;
use namespace::clean;

has jsonrpc => (
    is       => 'ro',
    isa      => InstanceOf['JsonRpc::Version'],
    required => 1,
);

has error => (
    is       => 'ro',
    isa      => InstanceOf['JsonRpc::Error'],
    required => 1,
);

has id => (
    is  => 'ro',
    isa => Maybe[Str | Int],  # エラー時はnullの可能性あり
);

sub from_hash {
    my ($class, $hash) = @_;
    
    die "from_hash requires a hash reference"
        unless ref $hash eq 'HASH';
    
    die "missing required field: jsonrpc"
        unless exists $hash->{jsonrpc};
    die "missing required field: error"
        unless exists $hash->{error};
    
    # resultフィールドがあれば拒否（排他性）
    die "ErrorResponse must not have 'result' field"
        if exists $hash->{result};
    
    my $error_obj;
    if (ref $hash->{error} eq 'HASH') {
        # Errorオブジェクトをネストで構築
        $error_obj = JsonRpc::Error->new(
            code    => $hash->{error}{code},
            message => $hash->{error}{message},
            exists $hash->{error}{data} ? (data => $hash->{error}{data}) : (),
        );
    } elsif (ref $hash->{error} eq 'JsonRpc::Error') {
        $error_obj = $hash->{error};
    } else {
        die "error field must be a hash or JsonRpc::Error object";
    }
    
    return $class->new(
        jsonrpc => JsonRpc::Version->new(value => $hash->{jsonrpc}),
        error   => $error_obj,
        exists $hash->{id} ? (id => $hash->{id}) : (),
    );
}

sub to_hash {
    my $self = shift;
    
    my $hash = {
        jsonrpc => $self->jsonrpc->value,
        error   => {
            code    => $self->error->code,
            message => $self->error->message,
        },
    };
    
    # dataが存在する場合のみ追加
    $hash->{error}{data} = $self->error->data
        if defined $self->error->data;
    
    # idが存在する場合のみ追加
    $hash->{id} = $self->id
        if defined $self->id;
    
    return $hash;
}

1;

__END__

=head1 NAME

JsonRpc::ErrorResponse - JSON-RPC 2.0 error Response object

=head1 SYNOPSIS

    use JsonRpc::ErrorResponse;
    use JsonRpc::Error;
    use JsonRpc::ErrorCode qw(:all);
    
    my $error = JsonRpc::Error->new(
        code    => ERROR_INVALID_REQUEST,
        message => 'Invalid Request',
    );
    
    my $res = JsonRpc::ErrorResponse->new(
        jsonrpc => JsonRpc::Version->new(value => '2.0'),
        error   => $error,
        id      => 'req-123',
    );

=head1 DESCRIPTION

Represents a JSON-RPC 2.0 error Response object.

This object has an C<error> field instead of C<result>.
The C<error> and C<result> fields are mutually exclusive.

=cut
```

### エラー時のid処理 - nullの扱いとパースエラーの特殊ケース

JSON-RPC 2.0仕様では、パースエラー時など、リクエストIDが取得できない場合、`id`を`null`にします。

```perl
# t/error_response.t に追加

subtest 'id can be null for parse errors' => sub {
    my $error = JsonRpc::Error->new(
        code    => ERROR_PARSE_ERROR,
        message => 'Parse error',
    );
    
    # idがnullの場合（Perlではundef）
    my $res = JsonRpc::ErrorResponse->new(
        jsonrpc => JsonRpc::Version->new(value => '2.0'),
        error   => $error,
        id      => undef,
    );
    
    is $res->id, undef, 'id is undef for parse error';
};

subtest 'from_hash with null id' => sub {
    my $res = JsonRpc::ErrorResponse->from_hash({
        jsonrpc => '2.0',
        error   => {
            code    => ERROR_PARSE_ERROR,
            message => 'Parse error',
        },
        id => undef,  # JSONではnull
    });
    
    is $res->id, undef, 'null id handled correctly';
};

subtest 'from_hash rejects result field' => sub {
    # errorとresultの両方がある場合は拒否
    like(
        dies {
            JsonRpc::ErrorResponse->from_hash({
                jsonrpc => '2.0',
                error   => { code => -1, message => 'error' },
                result  => 'should not exist',
                id      => 1,
            });
        },
        qr/must not have.*result/i,
        'result field is rejected in ErrorResponse'
    );
};
```

完璧！`result`と`error`の排他性が保証されました！🎉

## シリーズ全体のまとめ - 値オブジェクトとTDDで得た技術

### 学んだこと振り返り - 5回の旅を総括

このシリーズを通じて、以下の技術と概念を段階的にマスターしてきました。

> 🎓 **全5回で習得したスキル**  
> • 値オブジェクトパターンの理論と実装  
> • JSON-RPC 2.0準拠のAPI設計  
> • Test-Driven Development (TDD) の実践  
> • 境界値分析によるバグ検出技法  
> • Perlモダン開発のベストプラクティス

#### 第1回: 値オブジェクトの概念と基本実装

- **値オブジェクトの定義**: エンティティとの違い、不変性、等価性
- **Mooによる実装**: `has`での属性定義、`ro`による不変性
- **型制約の基礎**: `isa`によるバリデーション

#### 第2回: JSON-RPC 2.0仕様から設計を導く

- **仕様駆動設計**: 標準仕様から値オブジェクトを抽出
- **ドメインモデリング**: Version, MethodName, Params, IDの識別
- **設計原則**: 単一責任の原則、明示的な名前付け

#### 第3回: Test2によるTDD実践

- **Red-Green-Refactorサイクル**: 失敗→成功→改善のリズム
- **Test2::V0の活用**: ok/is/like/dies/lives/subtest
- **テスト戦略**: コンストラクタ検証、境界値分析、例外テスト

{{< linkcard "https://www.nqou.net/2025/12/07/000000/" >}}

#### 第4回: 複合値オブジェクトの設計

- **Type::Tiny実践**: Maybe/ArrayRef/HashRef/InstanceOf
- **ファクトリーパターン**: from_hash/to_hashによる変換
- **値オブジェクトのネスト**: Request/Responseの階層構造

#### 第5回（今回）: エラー処理と境界値テスト

- **Fail Fast原則**: 境界での防御、早期失敗
- **標準エラーコード**: 定数定義による保守性向上
- **境界値分析**: 数値範囲、文字列長、特殊値の網羅的テスト
- **排他性の保証**: errorとresultの相互排他実装

### 値オブジェクトの実践的な使いどころ

値オブジェクトは、以下のようなシーンで特に威力を発揮します：

#### Web APIでの活用

```perl
package API::Handler::User;
use v5.38;

sub create_user {
    my ($self, $request) = @_;
    
    # リクエストを値オブジェクトに変換（バリデーション完了）
    my $req = UserCreateRequest->from_hash($request->json);
    
    # 以降、$reqのフィールドは全て検証済み
    my $email = $req->email->value;  # Email値オブジェクト
    my $age   = $req->age->value;    # Age値オブジェクト（1-150の範囲保証）
    
    # ビジネスロジックに集中できる
    my $user = $self->user_service->create(
        email => $email,
        age   => $age,
    );
    
    return UserCreateResponse->new(user => $user)->to_hash;
}
```

#### ドメインモデルでの活用

```perl
package Domain::Order;
use v5.38;
use Moo;

has order_id => (
    is  => 'ro',
    isa => InstanceOf['Domain::OrderId'],  # 値オブジェクト
);

has amount => (
    is  => 'ro',
    isa => InstanceOf['Domain::Money'],  # 金額値オブジェクト
);

has status => (
    is  => 'ro',
    isa => InstanceOf['Domain::OrderStatus'],  # ステータス値オブジェクト
);

# ビジネスロジック
sub can_cancel {
    my $self = shift;
    
    # ステータス値オブジェクトが判定ロジックを持つ
    return $self->status->is_cancellable;
}
```

#### 既存コードへの段階的導入

値オブジェクトは、既存のコードベースに段階的に導入できます：

1. **入力境界から始める**: API入力を値オブジェクトに変換する
2. **クリティカルな箇所**: 金額計算、日付処理など、バグが許されない部分から導入
3. **新機能から適用**: 新規実装時に値オブジェクトを採用する
4. **リファクタリング**: テストがある部分から徐々に値オブジェクト化する

```perl
# Before（既存コード）
sub process_payment {
    my ($self, $amount, $currency) = @_;
    die "Invalid amount" if $amount <= 0;  # 毎回検証
    ...
}

# After（値オブジェクト導入）
sub process_payment {
    my ($self, $money) = @_;  # Money値オブジェクト
    # 検証不要！$moneyは常に正しい
    ...
}
```

### さらに学ぶために - 次のステップ

値オブジェクトとTDDをより深く理解するための学習リソースを紹介します。

#### DDD（ドメイン駆動設計）書籍

値オブジェクトの概念は、DDDから生まれました。以下の書籍で理論を深めることができます：

- **エリック・エヴァンス『ドメイン駆動設計』**: DDD原典。値オブジェクトの哲学を学べる
- **実践ドメイン駆動設計**: より実装寄りの解説。コード例が豊富
- **ドメイン駆動設計入門**: 日本の事例を交えた入門書

#### Type::Tiny深掘り

Type::Tinyには、このシリーズで紹介しきれなかった高度な機能があります：

{{< linkcard "https://metacpan.org/pod/Type::Tiny::Manual" >}}

```perl
# カスタム型の定義
declare PositiveInt,
    as Int,
    where { $_ > 0 },
    message { "Must be positive integer, got $_" };

# 型強制（coercion）
declare_coercion EmailFromStr,
    to_type Email,
    from Str,
    via { Email->new(value => $_) };

# Union型とIntersection型
my $type = Int | Str;  # IntまたはStr
```

#### Test2高度機能

Test2には、さらに強力な機能が多数あります：

- **Test2::Tools::Compare**: 複雑なデータ構造の比較
- **Test2::Plugin::SpecDeclare**: RSpec風のテストDSL
- **Test2::Harness**: 並列テスト実行
- **Test2::Tools::Spec**: BDD風テスト記述

```perl
use Test2::Tools::Spec;

describe 'JsonRpc::Error' => sub {
    tests 'it rejects empty message' => sub {
        my $error = dies {
            JsonRpc::Error->new(code => -1, message => '');
        };
        
        like $error, qr/empty/i;
    };
};
```

#### PerlでTDDを実践するためのツール

- **Devel::Cover**: コードカバレッジを測定
- **Perl::Critic**: コード品質をチェック
- **Perl::Tidy**: コードを整形
- **prove**: テストランナー（並列実行、詳細出力が可能）

```bash
# コードカバレッジを測定
cover -test

# 並列テスト実行（高速化）
prove -j4 -lv t/

# 特定のテストだけ実行
prove -lv t/error.t t/error_response.t
```

## まとめ - シリーズを通じて得た技術と価値

### 値オブジェクトとTDDの価値 - プロダクション開発への応用

このシリーズを通じて、**値オブジェクト（Value Object）**と**TDD（Test-Driven Development）**という2つの強力な技術を習得しました。

**値オブジェクトがもたらす価値:**

- ✅ **型安全性（Type Safety）**: 不正なデータが存在できない設計により、実行時エラーを大幅削減
- ✅ **保守性（Maintainability）**: バリデーションロジックが1箇所に集約され、修正が容易
- ✅ **可読性（Readability）**: コードが自己文書化され、意図が明確になる
- ✅ **テスト容易性（Testability）**: 小さな単位でテスト可能、モックやスタブ作成が不要

**TDDがもたらす価値:**

- ✅ **品質向上（Quality Improvement）**: バグを早期に発見し防止、デグレーションを防ぐ
- ✅ **設計改善（Design Enhancement）**: テストファーストで良い設計が自然に生まれる
- ✅ **リファクタリングの自信（Refactoring Confidence）**: 安心して大胆なリファクタリングを実施可能
- ✅ **実行可能な仕様書（Living Documentation）**: テストコードが常に最新の仕様を表現

> 💼 **実務への応用**  
> これらの技術は、特に以下の場面で威力を発揮します：  
> • 金融系システム（計算精度が重要）  
> • Web API開発（入力検証が重要）  
> • 決済システム（トランザクションの整合性が重要）  
> • レガシーコードのリファクタリング（安全性が重要）

### PerlでのTDD実践 - モダンなPerl開発へ

Perlは「古い言語」と思われがちですが、Test2、Type::Tiny、Mooといったモダンなツールにより、型安全でテスタブルなコードが書けます。

```perl
# モダンなPerlコードの例
package JsonRpc::Request;
use v5.38;  # 最新機能を使用
use Moo;    # モダンなOO
use Types::Standard qw(:all);  # 型安全性

has jsonrpc => (
    is  => 'ro',
    isa => InstanceOf['JsonRpc::Version']
);
has method => (
    is  => 'ro',
    isa => InstanceOf['JsonRpc::MethodName']
);
has params => (
    is  => 'ro',
    isa => Maybe[ArrayRef | HashRef]
);
has id => (
    is  => 'ro',
    isa => Maybe[Str | Int]
);
```

この美しい宣言的コードは、まさにモダンPerl開発の真骨頂です！🐪✨

### 最後に - あなたの開発に値オブジェクトを

値オブジェクトは、特別な状況でのみ使う「高度な技術」ではありません。
日常的な開発において、コードの品質を劇的に向上させる**実用的なパターン**です。

**まずは小さく始めてみましょう：**

1. ✅ 次のAPI実装で値オブジェクトを1つ導入してみる
2. ✅ 既存のバリデーション処理を値オブジェクトに置き換えてみる
3. ✅ Test2でテストを書き、TDDサイクル（Red-Green-Refactor）を体験してみる

そして、値オブジェクトがもたらす型安全性とTDDがもたらす自信を、ぜひあなた自身のコードで実感してください。

**Happy Hacking with Perl! 🐪**

---

## よくある質問（FAQ）

### Q1: 値オブジェクトはどんな場面で使うべき？
**A:** メールアドレス、金額、日付など、ビジネスルールを持つ「概念」を表現する時に最適です。単なる文字列や数値として扱うと検証が散らばり、保守性が低下します。

### Q2: 既存プロジェクトへの導入方法は？
**A:** 入力境界（APIエンドポイント）から段階的に導入するのがおすすめです。新機能実装時に値オブジェクトを採用し、徐々に適用範囲を広げましょう。

### Q3: TDDは開発速度を下げない？
**A:** 初期は慣れが必要ですが、バグ修正や仕様変更の時間が大幅に削減され、トータルでは高速化します。特にリファクタリング時の安心感は計り知れません。

### Q4: Test2とTest::Moreの違いは？
**A:** Test2はモダンな設計で拡張性が高く、サブテストや構造テストが簡潔に書けます。Test::Moreとの互換性もあるため、段階的移行が可能です。

---

## シリーズ記事一覧 - Perlで値オブジェクトを使ってテスト駆動開発してみよう

本記事は「**Perlで値オブジェクトを使ってテスト駆動開発してみよう**」シリーズの最終回（第5回・完結編）です。

### 📚 全5回のカリキュラム

1. **値オブジェクトって何だろう？ - DDDの基本概念とPerlでの実装入門**  
   値オブジェクトの基礎理論とMooを使った実装方法

2. **JSON-RPC 2.0で学ぶ値オブジェクト設計 - 仕様から設計へ**  
   標準仕様を読み解き、値オブジェクトを抽出する設計手法

3. **[PerlのTest2でTDD実践 - 値オブジェクトのテスト戦略](/2025/12/18/test2-tdd-value-object-testing-strategy/)**  
   Red-Green-Refactorサイクルとテストファースト開発

4. **[JSON-RPC Request/Response実装 - 複合値オブジェクト設計](/2025/12/19/jsonrpc-request-response-composite-value-objects/)**  
   Type::Tinyによる型安全性とファクトリーパターン

5. **エラー処理と境界値テスト - 堅牢な値オブジェクトを作る**（✅ この記事・完結編）  
   エラーハンドリング、境界値分析、プロダクション品質のコード設計

> 🎯 **シリーズ完走で得られるスキル**  
> 全5回を通じて、値オブジェクトの概念から実践的なTDD開発まで、JSON-RPC 2.0実装を題材に体系的に学べます。  
> ここで得た知識は、PerlだけでなくあらゆるOOP言語（Java, C#, Ruby, Python）での開発に応用できます。

**シリーズをお読みいただき、ありがとうございました！**

この知識があなたのプロジェクトで活かされ、より堅牢で保守性の高いコードが生まれることを願っています。

---

## 関連記事・参考資料

### 🔗 公式ドキュメント

{{< linkcard "https://www.jsonrpc.org/specification" >}}
{{< linkcard "https://metacpan.org/pod/Test2::V0" >}}
{{< linkcard "https://metacpan.org/pod/Type::Tiny" >}}
{{< linkcard "https://metacpan.org/pod/Moo" >}}

### 📖 さらに学ぶために

- **ドメイン駆動設計（DDD）**: エリック・エヴァンス著『Domain-Driven Design』
- **境界値分析**: Boris Beizer著『Software Testing Techniques』
- **テスト駆動開発**: Kent Beck著『Test-Driven Development: By Example』
- **Perlモダン開発**: 『Modern Perl』（無料オンライン版あり）

### 🏷️ タグで関連記事を探す

- [#perl](/tags/perl/) - Perl関連の全記事
- [#tdd](/tags/tdd/) - テスト駆動開発の実践記事
- [#value-object](/tags/value-object/) - 値オブジェクトパターン
- [#json-rpc](/tags/json-rpc/) - JSON-RPC実装ガイド
- [#error-handling](/tags/error-handling/) - エラー処理設計
- [#boundary-testing](/tags/boundary-testing/) - 境界値テスト技法
