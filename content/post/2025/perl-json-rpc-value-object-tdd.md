---
title: "PerlでJSON-RPC 2.0を実装 — 値オブジェクトとTDDで学ぶ実践チュートリアル"
draft: true
tags:
- perl
- value-object
- test-driven-development
- moo
- test2
- json-rpc
- tutorial
description: "値オブジェクトパターンを使ってJSON-RPC 2.0をPerlで実装します。TDD（テスト駆動開発）のサイクルを通じて、保守性の高いコードの書き方を実践的に学べるチュートリアルです。"
---

[@nqounet](https://x.com/nqounet)です。

「なぜこのコードは1,000ドルなのに、こっちは10ドルなのか？」  
そんな疑問を持ったことはありませんか？実は、値オブジェクトという設計パターンを知っているかどうかで、コードの品質は大きく変わります。

本記事では、Perlを使ってJSON-RPC 2.0プロトコルを実装しながら、値オブジェクトとTDD（テスト駆動開発）の実践方法を学びます。プリミティブ型（文字列や数値）をそのまま使うのではなく、意味のある「オブジェクト」として扱うことで、バグを減らし、保守しやすいコードを書く方法を体験できます。

## はじめに

### 値オブジェクトとは何か

値オブジェクト（Value Object）は、ドメイン駆動設計（DDD）における重要なパターンの一つです。例を見てみましょう：

```perl
# ❌ プリミティブ執着（アンチパターン）
my $amount = 1000;  # これは円？ドル？ユーロ？
my $email = "invalid";  # バリデーションは？

# ✅ 値オブジェクトを使った実装
my $amount = Money->new(value => 1000, currency => 'JPY');
my $email = Email->new(address => 'user@example.com');  # 構築時に検証
```

値オブジェクトを使うと：
- **型安全性**: `Money`と`String`を間違えて使えない
- **バリデーション**: 不正な値を持つオブジェクトが存在しない
- **明確な意図**: コードを読むだけでビジネス概念が理解できる

### 本記事で学べること

このチュートリアルを通じて、以下のスキルを身につけられます：

1. **TDDの実践**: Red（失敗するテスト） → Green（最小実装） → Refactor（改善）のサイクル
2. **値オブジェクトの設計**: 不変性、等価性、自己検証の3原則
3. **Perlのモダンな書き方**: Moo、Type::Tiny、Test2::Suiteの活用

想定読者は、基本的なPerlプログラミングができる方で、値オブジェクトやTDDについては初心者でも大丈夫です。

## 環境準備

### 必要なバージョンとモジュール

本チュートリアルでは、以下の環境を使用します：

- **Perl**: 5.20以降（5.38推奨）
- **必須モジュール**: Moo、Test2::Suite、Type::Tiny

### インストール手順

cpanmを使ってモジュールをインストールします：

```bash
# cpanm がない場合はインストール
curl -L https://cpanmin.us | perl - --sudo App::cpanminus

# 必要なモジュールをインストール
cpanm Moo Type::Tiny Test2::Suite
```

インストールが完了したら、動作確認してみましょう：

```perl
# check_env.pl
use strict;
use warnings;
use feature 'say';

eval { require Moo; };
say $@ ? "❌ Moo not found" : "✅ Moo OK";

eval { require Type::Tiny; };
say $@ ? "❌ Type::Tiny not found" : "✅ Type::Tiny OK";

eval { require Test2::V0; };
say $@ ? "❌ Test2::Suite not found" : "✅ Test2::Suite OK";
```

すべて✅が表示されれば準備完了です！

## 値オブジェクトの基本概念

値オブジェクトには3つの重要な特徴があります。

### 1. 不変性（Immutability）

一度作成したら、内容を変更できません：

```perl
my $version = JsonRpc::Version->new('2.0');
# $version->set('3.0');  # このようなメソッドは存在しない

# 変更が必要なら新しいオブジェクトを作る
my $new_version = JsonRpc::Version->new('3.0');
```

### 2. 等価性（Equality）

同じ値を持つオブジェクトは等しいとみなされます：

```perl
my $v1 = JsonRpc::Version->new('2.0');
my $v2 = JsonRpc::Version->new('2.0');

# オブジェクトは別だが、値が同じなら等しい
say $v1->equals($v2) ? "同じバージョン" : "異なるバージョン";  # => 同じバージョン
```

### 3. 自己検証（Self-Validation）

無効な値を持つオブジェクトは作成できません：

```perl
# ✅ 正しいバージョン
my $valid = JsonRpc::Version->new('2.0');

# ❌ 不正なバージョン → 例外が発生
my $invalid = JsonRpc::Version->new('1.0');  # die: Invalid version
```

### プリミティブ執着のアンチパターン

文字列や数値をそのまま使うと、こんな問題が起きます：

```perl
# ❌ 問題のあるコード
sub process_request {
    my ($version, $method, $id) = @_;
    
    # バージョンチェックが散在
    die "Invalid version" unless $version eq '2.0';
    
    # メソッド名の検証がない
    # idの型チェックもない
    
    return {
        jsonrpc => $version,  # タイポの危険性
        result  => do_something($method),
        id      => $id,
    };
}
```

値オブジェクトで解決すると：

```perl
# ✅ 値オブジェクトで解決
sub process_request {
    my ($request) = @_;  # JsonRpc::Request オブジェクト
    
    # バリデーションは構築時に完了済み
    # タイポの心配もない
    
    return JsonRpc::Response::Success->new(
        id     => $request->id,
        result => do_something($request->method),
    );
}
```

## 最初の値オブジェクトを作る（TDDサイクル1）

それでは、TDDの実践に入りましょう！最初に作るのは`JsonRpc::Version`です。

### Red: テストファーストで要件を定義

まず、失敗するテストを書きます。これが「仕様」になります：

```perl
# t/001_version.t
use Test2::V0;

# テスト対象をロード（まだ存在しない）
use JsonRpc::Version;

subtest 'バージョン2.0を受け入れる' => sub {
    my $version = JsonRpc::Version->new('2.0');
    ok $version, 'オブジェクトが作成できる';
    is $version->value, '2.0', '値が正しい';
};

subtest '不正なバージョンを拒否する' => sub {
    like(
        dies { JsonRpc::Version->new('1.0') },
        qr/Invalid version/,
        '1.0は拒否される'
    );
    
    like(
        dies { JsonRpc::Version->new('3.0') },
        qr/Invalid version/,
        '3.0も拒否される'
    );
};

subtest '等価性の判定' => sub {
    my $v1 = JsonRpc::Version->new('2.0');
    my $v2 = JsonRpc::Version->new('2.0');
    
    ok $v1->equals($v2), '同じ値なら等しい';
    isnt $v1, $v2, 'オブジェクトは別物';
};

done_testing;
```

このテストを実行すると、当然失敗します（Redステップ）：

```bash
prove -lv t/001_version.t
# Can't locate JsonRpc/Version.pm ...
```

### Green: 最小限の実装

テストが通る最小限のコードを書きます：

```perl
# lib/JsonRpc/Version.pm
package JsonRpc::Version;
use strict;
use warnings;
use Moo;
use Types::Standard qw(Str);
use namespace::clean;

# バージョン文字列（読み取り専用）
has value => (
    is       => 'ro',      # 読み取り専用（不変性）
    isa      => Str,       # 文字列型
    required => 1,         # 必須
);

# コンストラクタをオーバーライド
around BUILDARGS => sub {
    my ($orig, $class, @args) = @_;
    
    # 文字列を直接渡せるように
    return { value => $args[0] } if @args == 1 && !ref $args[0];
    return $class->$orig(@args);
};

# バリデーション（構築時に実行）
sub BUILD {
    my $self = shift;
    die "Invalid version: must be '2.0'\n" 
        unless $self->value eq '2.0';
}

# 等価性の判定
sub equals {
    my ($self, $other) = @_;
    return 0 unless $other && $other->isa(__PACKAGE__);
    return $self->value eq $other->value;
}

1;
```

テストを再実行：

```bash
prove -lv t/001_version.t
# All tests successful.
```

✅ Greenステップ完了！

### Refactor: 型制約で改善

Mooの機能をフル活用して、よりエレガントにします：

```perl
# lib/JsonRpc/Version.pm（改善版）
package JsonRpc::Version;
use strict;
use warnings;
use Moo;
use Types::Standard qw(Str);
use Type::Utils qw(declare as where message);
use namespace::clean;

# カスタム型制約を定義
my $JsonRpcVersionStr = declare as Str,
    where   { $_ eq '2.0' },
    message { "Invalid version: must be '2.0', got '$_'" };

has value => (
    is       => 'ro',
    isa      => $JsonRpcVersionStr,  # カスタム型を使用
    required => 1,
    coerce   => 1,
);

around BUILDARGS => sub {
    my ($orig, $class, @args) = @_;
    return { value => $args[0] } if @args == 1 && !ref $args[0];
    return $class->$orig(@args);
};

sub equals {
    my ($self, $other) = @_;
    return 0 unless $other && $other->isa(__PACKAGE__);
    return $self->value eq $other->value;
}

1;
```

これで、バリデーションが型システムに統合され、`BUILD`メソッドが不要になりました！

## JSON-RPC 2.0の構造を理解する

実装を進める前に、JSON-RPC 2.0の仕様を確認しましょう。

### 仕様の概要

JSON-RPC 2.0は、シンプルなリモートプロシージャコール（RPC）プロトコルです：

- **Request**: クライアントからサーバーへのメソッド呼び出し
- **Response**: サーバーからクライアントへの結果（成功/エラー）
- **Notification**: 応答を期待しないRequest

### オブジェクト間の関係

```
┌─────────────────────────────────────┐
│         JsonRpc::Version            │
│            ("2.0")                  │
└─────────────────────────────────────┘
                 △
                 │ 使用
     ┌───────────┴───────────┐
     │                       │
┌────┴─────┐         ┌───────┴────────┐
│ Request  │         │  Notification  │
├──────────┤         ├────────────────┤
│ method   │         │ method         │
│ params   │         │ params         │
│ id       │         └────────────────┘
└────┬─────┘
     │
     │ 返却
     ▼
┌────────────────────────────────────┐
│           Response                 │
├────────────────────────────────────┤
│  Success         │    Error        │
│  ├─ result       │    ├─ error    │
│  └─ id           │    └─ id        │
└────────────────────────────────────┘
```

### Request、Response、Notificationの違い

**Request** (id あり):
```json
{
  "jsonrpc": "2.0",
  "method": "subtract",
  "params": [42, 23],
  "id": 1
}
```

**Notification** (id なし):
```json
{
  "jsonrpc": "2.0",
  "method": "notify",
  "params": ["hello"]
}
```

**Response Success**:
```json
{
  "jsonrpc": "2.0",
  "result": 19,
  "id": 1
}
```

**Response Error**:
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

## リクエストオブジェクトの実装（TDDサイクル2）

次は`JsonRpc::Request`を作ります。

### テストファースト: 要件を明確化

```perl
# t/002_request.t
use Test2::V0;
use JsonRpc::Request;

subtest '正しいRequestの構築' => sub {
    my $req = JsonRpc::Request->new(
        method => 'subtract',
        params => [42, 23],
        id     => 1,
    );
    
    ok $req, 'オブジェクトが作成できる';
    is $req->method, 'subtract', 'メソッド名が正しい';
    is $req->params, [42, 23], 'パラメータが正しい';
    is $req->id, 1, 'IDが正しい';
    isa_ok $req->version, 'JsonRpc::Version', 'バージョンオブジェクト';
};

subtest 'パラメータは省略可能' => sub {
    my $req = JsonRpc::Request->new(
        method => 'ping',
        id     => 2,
    );
    
    is $req->params, undef, 'paramsはundef';
};

subtest 'メソッド名は必須' => sub {
    like(
        dies { JsonRpc::Request->new(id => 1) },
        qr/required/i,
        'methodなしは失敗'
    );
};

subtest 'IDは必須（Notificationと区別）' => sub {
    like(
        dies { JsonRpc::Request->new(method => 'test') },
        qr/required/i,
        'idなしは失敗'
    );
};

subtest 'IDの型（文字列・数値・null）' => sub {
    ok JsonRpc::Request->new(method => 'test', id => 1), '数値ID';
    ok JsonRpc::Request->new(method => 'test', id => 'abc'), '文字列ID';
    ok JsonRpc::Request->new(method => 'test', id => undef), 'null ID';
};

subtest 'ハッシュへの変換' => sub {
    my $req = JsonRpc::Request->new(
        method => 'add',
        params => { a => 1, b => 2 },
        id     => 3,
    );
    
    my $hash = $req->to_hash;
    is $hash, {
        jsonrpc => '2.0',
        method  => 'add',
        params  => { a => 1, b => 2 },
        id      => 3,
    }, 'ハッシュ表現が正しい';
};

done_testing;
```

### 実装: JsonRpc::Request クラス

```perl
# lib/JsonRpc/Request.pm
package JsonRpc::Request;
use strict;
use warnings;
use Moo;
use Types::Standard qw(Str ArrayRef HashRef Maybe Int Defined);
use Type::Utils qw(declare as where union);
use JsonRpc::Version;
use namespace::clean;

# バージョン（自動的に'2.0'）
has version => (
    is      => 'ro',
    isa     => InstanceOf['JsonRpc::Version'],
    default => sub { JsonRpc::Version->new('2.0') },
);

# メソッド名（必須）
has method => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

# パラメータ（配列またはハッシュ、省略可）
my $ParamsType = Maybe[ArrayRef | HashRef];

has params => (
    is  => 'ro',
    isa => $ParamsType,
);

# ID（文字列・数値・null、必須）
my $IdType = Maybe[Str | Int];

has id => (
    is       => 'ro',
    isa      => $IdType,
    required => 1,
);

# ハッシュ表現に変換
sub to_hash {
    my $self = shift;
    
    my %hash = (
        jsonrpc => $self->version->value,
        method  => $self->method,
        id      => $self->id,
    );
    
    $hash{params} = $self->params if defined $self->params;
    
    return \%hash;
}

1;
```

テスト実行：

```bash
prove -lv t/002_request.t
# All tests successful.
```

### 型制約とバリデーションの追加

メソッド名に制約を追加してみましょう：

```perl
# メソッド名は rpc. で始まってはいけない（予約済み）
my $MethodName = declare as Str,
    where   { $_ !~ /^rpc\./ },
    message { "Method name must not start with 'rpc.': got '$_'" };

has method => (
    is       => 'ro',
    isa      => $MethodName,
    required => 1,
);
```

テストを追加：

```perl
subtest 'メソッド名の制約' => sub {
    like(
        dies { JsonRpc::Request->new(method => 'rpc.reserved', id => 1) },
        qr/must not start with/,
        'rpc.始まりは拒否'
    );
};
```

## エラーオブジェクトの実装（TDDサイクル3）

エラー処理は重要です。エラーコードを値オブジェクト化します。

### エラーコードの値オブジェクト化

まずテストから：

```perl
# t/003_error.t
use Test2::V0;
use JsonRpc::Error;

subtest '標準エラーコード' => sub {
    my $error = JsonRpc::Error->new(
        code    => -32600,
        message => 'Invalid Request',
    );
    
    is $error->code, -32600, 'コードが正しい';
    is $error->message, 'Invalid Request', 'メッセージが正しい';
};

subtest 'カスタムエラーコード（-32000〜-32099）' => sub {
    my $error = JsonRpc::Error->new(
        code    => -32000,
        message => 'Server error',
        data    => { detail => 'Database connection failed' },
    );
    
    is $error->code, -32000, 'カスタムコード';
    is $error->data->{detail}, 'Database connection failed', 'data付き';
};

subtest '予約範囲外のコードは拒否' => sub {
    like(
        dies { JsonRpc::Error->new(code => -32768, message => 'test') },
        qr/Invalid error code/,
        '予約範囲外は拒否'
    );
};

subtest '標準エラーの定数' => sub {
    is(JsonRpc::Error::PARSE_ERROR, -32700, 'Parse error');
    is(JsonRpc::Error::INVALID_REQUEST, -32600, 'Invalid Request');
    is(JsonRpc::Error::METHOD_NOT_FOUND, -32601, 'Method not found');
    is(JsonRpc::Error::INVALID_PARAMS, -32602, 'Invalid params');
    is(JsonRpc::Error::INTERNAL_ERROR, -32603, 'Internal error');
};

subtest 'ハッシュへの変換' => sub {
    my $error = JsonRpc::Error->new(
        code    => -32601,
        message => 'Method not found',
    );
    
    is $error->to_hash, {
        code    => -32601,
        message => 'Method not found',
    }, 'ハッシュ表現';
};

done_testing;
```

### JsonRpc::Error クラスの実装

```perl
# lib/JsonRpc/Error.pm
package JsonRpc::Error;
use strict;
use warnings;
use Moo;
use Types::Standard qw(Int Str Any Maybe);
use Type::Utils qw(declare as where message);
use namespace::clean;

# 標準エラーコードの定数
use constant {
    PARSE_ERROR      => -32700,
    INVALID_REQUEST  => -32600,
    METHOD_NOT_FOUND => -32601,
    INVALID_PARAMS   => -32602,
    INTERNAL_ERROR   => -32603,
};

# エラーコードの型制約
my $ErrorCode = declare as Int,
    where {
        # -32768 〜 -32000: 予約済み（標準エラー）
        # -32099 〜 -32000: サーバー定義可能
        ($_ >= -32768 && $_ <= -32000) || ($_ >= -32099 && $_ <= -32000)
    },
    message { "Invalid error code: must be in reserved range, got $_" };

has code => (
    is       => 'ro',
    isa      => $ErrorCode,
    required => 1,
);

has message => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

has data => (
    is  => 'ro',
    isa => Maybe[Any],
);

sub to_hash {
    my $self = shift;
    
    my %hash = (
        code    => $self->code,
        message => $self->message,
    );
    
    $hash{data} = $self->data if defined $self->data;
    
    return \%hash;
}

1;
```

### 標準エラーコードの定数定義

定数をエクスポートできるようにします：

```perl
# 定数のエクスポート機能を追加
use Exporter 'import';
our @EXPORT_OK = qw(
    PARSE_ERROR
    INVALID_REQUEST
    METHOD_NOT_FOUND
    INVALID_PARAMS
    INTERNAL_ERROR
);
our %EXPORT_TAGS = (
    all => \@EXPORT_OK,
);
```

使用例：

```perl
use JsonRpc::Error qw(:all);

my $error = JsonRpc::Error->new(
    code    => METHOD_NOT_FOUND,
    message => 'Method "unknown" not found',
);
```

## レスポンスオブジェクトの実装（TDDサイクル4）

成功とエラーを別クラスにする設計を選びます。

### Success と Error を別クラスにする設計判断

なぜ別クラスにするのか：

1. **型安全性**: 成功時に`error`フィールドにアクセスできない
2. **明確な意図**: コードを読めばどちらか一目瞭然
3. **拡張性**: それぞれ独自のメソッドを持てる

### テストファースト

```perl
# t/004_response.t
use Test2::V0;
use JsonRpc::Response::Success;
use JsonRpc::Response::Error;
use JsonRpc::Error qw(METHOD_NOT_FOUND);

subtest 'Success レスポンス' => sub {
    my $res = JsonRpc::Response::Success->new(
        result => { sum => 42 },
        id     => 1,
    );
    
    is $res->result, { sum => 42 }, '結果が正しい';
    is $res->id, 1, 'IDが正しい';
    
    my $hash = $res->to_hash;
    is $hash, {
        jsonrpc => '2.0',
        result  => { sum => 42 },
        id      => 1,
    }, 'ハッシュ表現';
};

subtest 'Error レスポンス' => sub {
    my $error = JsonRpc::Error->new(
        code    => METHOD_NOT_FOUND,
        message => 'Method not found',
    );
    
    my $res = JsonRpc::Response::Error->new(
        error => $error,
        id    => 1,
    );
    
    isa_ok $res->error, 'JsonRpc::Error', 'エラーオブジェクト';
    is $res->id, 1, 'IDが正しい';
    
    my $hash = $res->to_hash;
    is $hash, {
        jsonrpc => '2.0',
        error   => {
            code    => -32601,
            message => 'Method not found',
        },
        id => 1,
    }, 'ハッシュ表現';
};

subtest 'IDはnullも許可' => sub {
    my $res = JsonRpc::Response::Success->new(
        result => 'ok',
        id     => undef,
    );
    
    is $res->id, undef, 'null ID';
};

done_testing;
```

### JsonRpc::Response::Success の実装

```perl
# lib/JsonRpc/Response/Success.pm
package JsonRpc::Response::Success;
use strict;
use warnings;
use Moo;
use Types::Standard qw(Any Maybe Str Int);
use Type::Utils qw(union);
use JsonRpc::Version;
use namespace::clean;

has version => (
    is      => 'ro',
    isa     => InstanceOf['JsonRpc::Version'],
    default => sub { JsonRpc::Version->new('2.0') },
);

has result => (
    is       => 'ro',
    isa      => Any,
    required => 1,
);

my $IdType = Maybe[Str | Int];

has id => (
    is       => 'ro',
    isa      => $IdType,
    required => 1,
);

sub to_hash {
    my $self = shift;
    return {
        jsonrpc => $self->version->value,
        result  => $self->result,
        id      => $self->id,
    };
}

1;
```

### JsonRpc::Response::Error の実装

```perl
# lib/JsonRpc/Response/Error.pm
package JsonRpc::Response::Error;
use strict;
use warnings;
use Moo;
use Types::Standard qw(Maybe Str Int);
use Type::Utils qw(union);
use JsonRpc::Version;
use JsonRpc::Error;
use namespace::clean;

has version => (
    is      => 'ro',
    isa     => InstanceOf['JsonRpc::Version'],
    default => sub { JsonRpc::Version->new('2.0') },
);

has error => (
    is       => 'ro',
    isa      => InstanceOf['JsonRpc::Error'],
    required => 1,
);

my $IdType = Maybe[Str | Int];

has id => (
    is       => 'ro',
    isa      => $IdType,
    required => 1,
);

sub to_hash {
    my $self = shift;
    return {
        jsonrpc => $self->version->value,
        error   => $self->error->to_hash,
        id      => $self->id,
    };
}

1;
```

### ポリモーフィズムによる統一的な扱い

共通インターフェース（Role）を定義すると、さらに良くなります：

```perl
# lib/JsonRpc/Role/Response.pm
package JsonRpc::Role::Response;
use Moo::Role;

requires 'to_hash';  # このメソッドの実装を要求

1;
```

各レスポンスクラスに適用：

```perl
package JsonRpc::Response::Success;
use Moo;
with 'JsonRpc::Role::Response';  # Roleを適用
# ... 既存のコード ...
```

これで、型に関わらず統一的に扱えます：

```perl
sub send_response {
    my $response = shift;  # Success でも Error でもOK
    
    # Roleを実装していることを確認
    die unless $response->does('JsonRpc::Role::Response');
    
    return encode_json($response->to_hash);
}
```

## 通知オブジェクトの実装（TDDサイクル5）

最後に、Notificationを実装します。

### Request との違いを値オブジェクトで表現

NotificationはRequestと似ていますが、**IDを持たない**点が異なります：

```perl
# t/005_notification.t
use Test2::V0;
use JsonRpc::Notification;

subtest '正しいNotificationの構築' => sub {
    my $notif = JsonRpc::Notification->new(
        method => 'notify_user',
        params => { user_id => 123, message => 'Hello' },
    );
    
    ok $notif, 'オブジェクトが作成できる';
    is $notif->method, 'notify_user', 'メソッド名';
    is $notif->params, { user_id => 123, message => 'Hello' }, 'パラメータ';
    ok !exists $notif->can('id'), 'IDメソッドは存在しない';
};

subtest 'パラメータは省略可能' => sub {
    my $notif = JsonRpc::Notification->new(
        method => 'ping',
    );
    
    is $notif->params, undef, 'paramsなし';
};

subtest 'ハッシュへの変換' => sub {
    my $notif = JsonRpc::Notification->new(
        method => 'update',
        params => [1, 2, 3],
    );
    
    is $notif->to_hash, {
        jsonrpc => '2.0',
        method  => 'update',
        params  => [1, 2, 3],
    }, 'IDフィールドがない';
};

done_testing;
```

### JsonRpc::Notification クラスの実装

```perl
# lib/JsonRpc/Notification.pm
package JsonRpc::Notification;
use strict;
use warnings;
use Moo;
use Types::Standard qw(Str ArrayRef HashRef Maybe);
use Type::Utils qw(union declare as where message);
use JsonRpc::Version;
use namespace::clean;

has version => (
    is      => 'ro',
    isa     => InstanceOf['JsonRpc::Version'],
    default => sub { JsonRpc::Version->new('2.0') },
);

# メソッド名の制約（Requestと同じ）
my $MethodName = declare as Str,
    where   { $_ !~ /^rpc\./ },
    message { "Method name must not start with 'rpc.': got '$_'" };

has method => (
    is       => 'ro',
    isa      => $MethodName,
    required => 1,
);

my $ParamsType = Maybe[ArrayRef | HashRef];

has params => (
    is  => 'ro',
    isa => $ParamsType,
);

sub to_hash {
    my $self = shift;
    
    my %hash = (
        jsonrpc => $self->version->value,
        method  => $self->method,
    );
    
    $hash{params} = $self->params if defined $self->params;
    
    return \%hash;
}

1;
```

## 値オブジェクトの恩恵を実感する

実装が完了したので、値オブジェクトの効果を確認しましょう。

### テストの簡潔さと保守性の比較

**❌ Before（プリミティブ型）**:

```perl
# テストが冗長で、何をテストしているか不明確
sub test_process_request {
    my %request = (
        jsonrpc => '2.0',
        method  => 'subtract',
        params  => [42, 23],
        id      => 1,
    );
    
    # バリデーションを手動で実行
    die unless $request{jsonrpc} eq '2.0';
    die unless exists $request{method};
    die unless exists $request{id};
    
    # 処理...
    my $result = 42 - 23;
    
    # レスポンス構築も手動
    my %response = (
        jsonrpc => '2.0',
        result  => $result,
        id      => $request{id},
    );
    
    # 検証も手動
    die unless $response{jsonrpc} eq '2.0';
    die unless exists $response{result};
    
    return \%response;
}
```

**✅ After（値オブジェクト）**:

```perl
sub process_request {
    my $request = shift;  # JsonRpc::Request（既に検証済み）
    
    # ビジネスロジックに集中できる
    my $result = calculate($request->method, $request->params);
    
    # レスポンスも型安全
    return JsonRpc::Response::Success->new(
        result => $result,
        id     => $request->id,
    );
}

# テストも簡潔
subtest 'リクエスト処理' => sub {
    my $request = JsonRpc::Request->new(
        method => 'subtract',
        params => [42, 23],
        id     => 1,
    );
    
    my $response = process_request($request);
    
    isa_ok $response, 'JsonRpc::Response::Success';
    is $response->result, 19;
};
```

### バリデーションの一元化による安全性

値オブジェクトを使うと：

```perl
# ❌ これはコンパイル時にエラー
my $req = JsonRpc::Request->new(
    method => 'rpc.forbidden',  # rpc. 始まりは禁止
    id     => 1,
);  # → 例外が発生

# ❌ これも実行時に即座にエラー
my $version = JsonRpc::Version->new('1.0');  # → 例外

# ✅ 無効なオブジェクトは存在しない保証
sub safe_process {
    my $request = shift;  # 必ず有効なRequest
    
    # バリデーションチェック不要！
    # $request->method は必ず正しい文字列
    # $request->id は必ず存在
}
```

### ビジネスロジックの明確化

値オブジェクトで「概念」が明確になります：

```perl
# ❌ Before: 何を表すか不明
sub calculate {
    my ($code, $msg, $val) = @_;
    # $code って何？エラーコード？ステータス？
}

# ✅ After: 型名でドメイン概念が明確
sub handle_error {
    my ($error) = @_;  # JsonRpc::Error
    
    # エラーコードの範囲も型で保証済み
    if ($error->code == JsonRpc::Error::METHOD_NOT_FOUND) {
        log_warning($error->message);
    }
}
```

## まとめと次のステップ

お疲れさまでした！このチュートリアルを通じて、以下を学びました：

### 学んだこと

1. **値オブジェクトの3原則**
   - 不変性: 一度作ったら変更できない
   - 等価性: 値が同じなら同じオブジェクト
   - 自己検証: 無効な状態が存在しない

2. **TDDサイクルの実践**
   - Red: テストファーストで要件を定義
   - Green: 最小限の実装で通す
   - Refactor: 設計を改善

3. **Perlのモダンな技術**
   - Moo: 軽量なオブジェクトシステム
   - Type::Tiny: 強力な型制約
   - Test2::Suite: 表現力豊かなテスト

### 値オブジェクトパターンの適用範囲

値オブジェクトは、以下のような場合に特に有効です：

- **識別子**: Email、UserId、OrderNumber
- **金額**: Money、Price、Quantity
- **日時**: DateRange、Timestamp
- **ビジネスルール**: TaxRate、DiscountCode
- **プロトコル**: 今回のJSON-RPC 2.0

逆に、適さない場合：

- 頻繁に変更される状態を持つオブジェクト（エンティティ）
- パフォーマンスが極めて重要な箇所（ただしプロファイリング後に判断）

### より高度な技術への道

さらに学びたい方へのステップ：

**1. Roleの活用**
```perl
# 共通の振る舞いを定義
package JsonRpc::Role::HasVersion;
use Moo::Role;
use JsonRpc::Version;

has version => (
    is      => 'ro',
    default => sub { JsonRpc::Version->new('2.0') },
);
```

**2. カスタム型ライブラリ**
```perl
# lib/JsonRpc/Types.pm
package JsonRpc::Types;
use Type::Library -base;
use Type::Utils qw(declare as where message);

declare "JsonRpcId",
    as Maybe[Str | Int];

declare "MethodName",
    as Str,
    where { $_ !~ /^rpc\./ };

1;
```

**3. JSON変換の統合**
```perl
use JSON::MaybeXS;

# to_json メソッドを追加
sub to_json {
    my $self = shift;
    return encode_json($self->to_hash);
}

# from_json コンストラクタ
sub from_json {
    my ($class, $json) = @_;
    my $data = decode_json($json);
    return $class->new($data);
}
```

### 参考資料とコミュニティリソース

**公式ドキュメント**:
- [JSON-RPC 2.0 Specification](https://www.jsonrpc.org/specification)
- [Moo - Minimalist Object Orientation](https://metacpan.org/pod/Moo)
- [Type::Tiny Manual](https://metacpan.org/pod/Type::Tiny::Manual)
- [Test2::Suite](https://metacpan.org/pod/Test2::Suite)

**書籍**:
- "Domain-Driven Design" by Eric Evans（ドメイン駆動設計）
- "Refactoring" by Martin Fowler（リファクタリング）

**Perlコミュニティ**:
- [CPAN](https://metacpan.org/) - Perlモジュールの宝庫
- [PerlMonks](https://www.perlmonks.org/) - Perl Q&Aコミュニティ
- [blogs.perl.org](http://blogs.perl.org/) - Perl開発者ブログ

値オブジェクトとTDDをマスターすれば、保守性と信頼性の高いコードが書けるようになります。ぜひ、実際のプロジェクトで試してみてください！

Happy Hacking! 🐪✨
