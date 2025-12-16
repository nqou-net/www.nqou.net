---
title: "PerlのTest2でTDD実践 - 値オブジェクトのテスト戦略とRed-Green-Refactor完全ガイド"
draft: true
tags:
  - perl
  - test2
  - tdd
  - value-object
  - red-green-refactor
description: "PerlのTest2::V0で学ぶTDD実践ガイド。Red-Green-Refactorサイクル、dies/lives例外テスト、subtest構造化、境界値分析を実例付きで解説。MethodName値オブジェクトで体験する本格的なテスト駆動開発。"
---

この記事は「**Perlで値オブジェクトを使ってテスト駆動開発してみよう**」シリーズの第3回である。前回は、[JSON-RPC 2.0仕様から値オブジェクトを設計するプロセス](/2025/12/17/json-rpc-value-object-design/)を学んだ。今回は、**PerlのTest2::V0を使ったテスト駆動開発（TDD）の実践**に焦点を当て、Red-Green-Refactorサイクルを体験しながらMethodName値オブジェクトを段階的に実装する。

## この記事で学べること

- **Test2::V0の基本機能**: ok/is/like/dies/lives/subtestの使い分け
- **TDDの実践サイクル**: Red-Green-Refactorを実際のコードで体験
- **値オブジェクトのテスト戦略**: コンストラクタ検証、不変性、等価性、境界値分析
- **実践的なテストパターン**: 例外テスト、エラーメッセージ検証、サブテスト構造化

{{< linkcard "https://www.nqou.net/2025/12/17/json-rpc-value-object-design/" >}}

## TDDの基本フロー - なぜテストファーストなのか

テスト駆動開発（TDD）は、「テストを先に書く」という一見逆説的なアプローチである。しかし、このアプローチには開発効率と品質を劇的に向上させる力がある。

### なぜテスト駆動開発なのか

従来の開発では「実装 → テスト → バグ発見 → 修正」という流れになりがちである。この場合、以下の問題が起こりやすくなる：

- テストが後回しになって書かれない
- 実装に引きずられて不十分なテストになる
- 設計の問題に気づくのが遅れる

一方、TDDでは「テスト → 実装 → リファクタリング」のサイクルを繰り返す。テストを先に書くことで、以下のメリットが得られる：

- 必要な機能が明確になる
- 設計の問題に早く気づける
- リファクタリングが安心してできる
- テストカバレッジが自然と100%になる

### Red-Green-Refactorサイクル

TDDの核心は、**Red-Green-Refactor**という3つのステップを繰り返すことである。

```perl
# Red (失敗するテストを書く)
subtest 'MethodName rejects empty string' => sub {
    like(
        dies { MethodName->new(value => '') },
        qr/method name cannot be empty/,
        'empty string is rejected'
    );
};

# Green (最小実装で通す)
package MethodName;
use Moo;
has value => (
    is  => 'ro',
    isa => sub { die "method name cannot be empty" if $_[0] eq '' },
);

# Refactor (コードを整理する)
has value => (
    is  => 'ro',
    isa => sub {
        my $val = shift;
        die "method name cannot be empty" if !defined $val || $val eq '';
        die "method name must be string" if ref $val;
    },
);
```

#### Redステップ - 失敗するテストを書く

まず、まだ存在しない機能のテストを書く。このテストは当然**失敗（Red）**する。

```bash
$ prove -lv t/method_name.t
not ok 1 - MethodName rejects empty string
```

失敗することが重要である。これによって「テストが正しく動作している」ことが確認できる。

#### Greenステップ - 最小実装で通す

次に、テストを通すための**最小限のコード**を書く。完璧である必要はない。とにかくテストが**成功（Green）**すればOKである。

```bash
$ prove -lv t/method_name.t
ok 1 - MethodName rejects empty string
```

#### Refactorステップ - リファクタリング

テストが通ったら、コードを**整理**する。重複を除去し、可読性を高め、設計を改善する。このとき、テストが常にGreenであることを確認しながら進める。

テストがあるからこそ、安心してリファクタリングできる。

### 値オブジェクトのTDD戦略

値オブジェクトをTDDで開発する場合、以下の順序がおすすめである。

#### 1. コンストラクタバリデーション優先

まず、不正な値を拒否することから始める。

```perl
# 最初に異常系を固める
subtest 'constructor validation' => sub {
    like(dies { MethodName->new(value => '') }, qr/empty/, 'empty rejected');
    like(dies { MethodName->new(value => undef) }, qr/undef/, 'undef rejected');
    like(dies { MethodName->new(value => []) }, qr/string/, 'array rejected');
};
```

#### 2. 境界値を重視

境界値（空文字列、最大長、最小値など）を徹底的にテストする。

```perl
subtest 'boundary values' => sub {
    ok(lives { MethodName->new(value => 'a') }, 'single char ok');
    ok(lives { MethodName->new(value => 'x' x 255) }, '255 chars ok');
    like(dies { MethodName->new(value => 'x' x 256) }, qr/too long/, '256 chars rejected');
};
```

#### 3. 不変性の確認

値オブジェクトは不変でなければならない。

```perl
subtest 'immutability' => sub {
    my $method = MethodName->new(value => 'getUser');
    like(dies { $method->value('setUser') }, qr/read-only/, 'cannot modify');
};
```

## Test2::V0の基本機能 - アサーションの使い分け完全ガイド

Test2::V0は、Perlの次世代テストフレームワークである。従来のTest::Moreの機能を継承しつつ、より直感的で強力なアサーション機能を提供する。ここでは、値オブジェクトのテストで頻繁に使う機能を実例付きで解説する。

{{< linkcard "https://www.nqou.net/2025/12/07/000000/" >}}

### 基本的なアサーション - ok, is, isnt

#### ok - 真偽値テスト

`ok`は、引数が真であることをテストする。

```perl
use Test2::V0;

ok 1, 'this passes';
ok 'string', 'non-empty string is true';
ok [], 'array reference is true';

ok 0, 'this fails';          # 失敗
ok '', 'empty string fails';  # 失敗
ok undef, 'undef fails';      # 失敗

done_testing;
```

値オブジェクトでは、オブジェクトが正しく生成されたかを確認するのに使う。

```perl
my $method = MethodName->new(value => 'getUser');
ok $method, 'MethodName object created';
ok $method->isa('MethodName'), 'correct type';
```

#### is - 等価性テスト

`is`は、2つの値が等しいことをテストする。文字列比較と数値比較を自動判別する。

```perl
is 42, 42, 'numbers equal';
is 'hello', 'hello', 'strings equal';
is $method->value, 'getUser', 'method name is correct';

# 失敗例
is 42, '42', 'this passes (smart match)';
is 'hello', 'world', 'this fails';
```

#### isnt - 非等価性テスト

`isnt`は、2つの値が等しくないことをテストする。

```perl
isnt 42, 43, 'different numbers';
isnt 'hello', 'world', 'different strings';

my $method1 = MethodName->new(value => 'getUser');
my $method2 = MethodName->new(value => 'setUser');
isnt $method1->value, $method2->value, 'different methods';
```

### パターンマッチング - like, unlike

#### like - 正規表現マッチテスト

`like`は、文字列が正規表現にマッチすることをテストする。

```perl
like 'getUser', qr/^get/, 'starts with get';
like 'setPassword', qr/Password$/, 'ends with Password';
like 'findUserById', qr/^[a-z]+[A-Z]/, 'camelCase pattern';

# エラーメッセージの検証
like(
    dies { MethodName->new(value => '') },
    qr/method name cannot be empty/i,
    'error message matches pattern'
);
```

#### unlike - 正規表現非マッチテスト

`unlike`は、文字列が正規表現にマッチしないことをテストする。

```perl
unlike 'getUser', qr/^rpc\./, 'not a reserved method';
unlike 'findUser', qr/\s/, 'no whitespace';
unlike 'validMethod', qr/[^a-zA-Z0-9_]/, 'no special chars';
```

### 例外テスト - dies, lives

例外のテストはバリデーションの検証に不可欠である。Test2::V0の`dies`と`lives`を使えば、例外の発生有無とメッセージ内容を明確にテストできる。

#### dies - 例外が発生することをテスト

```perl
use Test2::V0;

# 例外が発生することを確認
like(
    dies { MethodName->new(value => '') },
    qr/cannot be empty/,
    'empty string throws exception'
);

# 任意の例外が発生すればOK
ok(dies { die "error" }, 'dies with any exception');

# 例外が発生しなければ失敗
ok(dies { 42 }, 'this test fails');  # 失敗
```

#### lives - 例外が発生しないことをテスト

```perl
# 例外が発生しないことを確認
ok(lives { MethodName->new(value => 'getUser') }, 'valid method name accepted');

# 正常に実行されることを確認
ok(lives { my $x = 42 + 23 }, 'normal code executes');

# 例外が発生すれば失敗
ok(lives { die "error" }, 'this test fails');  # 失敗
```

#### 実践的な例外テスト

```perl
subtest 'constructor validates input' => sub {
    # 空文字列
    like(
        dies { MethodName->new(value => '') },
        qr/method name cannot be empty/,
        'empty string rejected with clear message'
    );
    
    # undef
    like(
        dies { MethodName->new(value => undef) },
        qr/method name cannot be empty/,
        'undef rejected'
    );
    
    # 参照型
    like(
        dies { MethodName->new(value => []) },
        qr/must be string/,
        'array reference rejected'
    );
    
    # 正常系は例外を発生させない
    ok(lives { MethodName->new(value => 'getUser') }, 'valid string accepted');
};
```

## 値オブジェクトのテストパターン - 4つの重要観点

値オブジェクトには共通のテストパターンがある。これらを押さえておくと、どんな値オブジェクトでも効率的にテストを書ける。

### コンストラクタのバリデーションテスト

値オブジェクトのコンストラクタは、正しい値だけを受け入れ、不正な値を確実に拒否しなければならない。

```perl
subtest 'constructor validation' => sub {
    subtest 'valid inputs are accepted' => sub {
        ok(lives { MethodName->new(value => 'getUser') }, 'simple method name');
        ok(lives { MethodName->new(value => 'findUserById') }, 'camelCase method');
        ok(lives { MethodName->new(value => 'create_user') }, 'snake_case method');
        ok(lives { MethodName->new(value => 'x') }, 'single character');
    };
    
    subtest 'invalid inputs are rejected' => sub {
        like(dies { MethodName->new(value => '') }, 
             qr/empty/, 'empty string');
        like(dies { MethodName->new(value => undef) }, 
             qr/empty|undef/, 'undef');
        like(dies { MethodName->new(value => '   ') }, 
             qr/empty|whitespace/, 'whitespace only');
        like(dies { MethodName->new(value => {}) }, 
             qr/string/, 'hash reference');
        like(dies { MethodName->new(value => []) }, 
             qr/string/, 'array reference');
    };
};
```

#### エラーメッセージの確認

エラーメッセージは開発者の重要な手がかりである。明確なメッセージをテストで保証する。

```perl
subtest 'error messages are clear' => sub {
    my $exception = dies { MethodName->new(value => '') };
    
    like($exception, qr/method name/, 'mentions method name');
    like($exception, qr/cannot be empty/, 'explains the problem');
    
    # より具体的なメッセージのテスト
    like(
        dies { MethodName->new(value => 'rpc.internal') },
        qr/reserved.*rpc\./,
        'explains reserved method prefix'
    );
};
```

### 不変性のテスト

値オブジェクトは一度作成されたら変更できない。

```perl
subtest 'immutability' => sub {
    my $method = MethodName->new(value => 'getUser');
    
    # 値を変更しようとするとエラー
    like(
        dies { $method->value('setUser') },
        qr/read-only|Usage/,
        'cannot modify value after creation'
    );
    
    # 元の値は変わっていない
    is $method->value, 'getUser', 'original value preserved';
};
```

#### 変更試行時の挙動確認

```perl
subtest 'modification attempts fail safely' => sub {
    my $method = MethodName->new(value => 'getUser');
    
    # 変更は失敗する
    eval { $method->{value} = 'setUser' };  # ハッシュ直接アクセス
    
    # それでも値は変わらない（Mooの内部保護）
    is $method->value, 'getUser', 'internal hash modification has no effect';
};
```

### 等価性テスト

値オブジェクトは「値による等価性」を持つ。同じ値を持つ2つのオブジェクトは等価とみなされる。

```perl
subtest 'equality by value' => sub {
    my $method1 = MethodName->new(value => 'getUser');
    my $method2 = MethodName->new(value => 'getUser');
    my $method3 = MethodName->new(value => 'setUser');
    
    # 同じ値を持つオブジェクトは等価
    ok $method1->equals($method2), 'same value means equal';
    
    # 自分自身とも等価
    ok $method1->equals($method1), 'object equals itself';
    
    # 異なる値は非等価
    ok !$method1->equals($method3), 'different values are not equal';
    
    # 異なる型は非等価
    ok !$method1->equals("getUser"), 'string is not equal to object';
    ok !$method1->equals(undef), 'undef is not equal to object';
};
```

### 境界値テスト - バグを見つける最強の手法

境界値分析は、バグを見つける最も効果的な手法の一つである。境界値とは、「ちょうど許容される値」と「ちょうど許容されない値」の境界にある値である。Test2を使えば、境界値のテストを網羅的に記述できる。

```perl
subtest 'boundary value analysis' => sub {
    # 文字列長の境界値テスト
    subtest 'string length boundaries' => sub {
        # 最小値
        ok(lives { MethodName->new(value => 'x') }, 
           'length 1 (minimum) is accepted');
        
        # 最大値
        ok(lives { MethodName->new(value => 'x' x 255) }, 
           'length 255 (maximum) is accepted');
        
        # 範囲外
        like(dies { MethodName->new(value => '') }, 
             qr/empty/, 'length 0 is rejected');
        like(dies { MethodName->new(value => 'x' x 256) }, 
             qr/too long/, 'length 256 is rejected');
    };
    
    # 特殊文字の境界値テスト
    subtest 'special character boundaries' => sub {
        # 英数字とアンダースコアは許可
        ok(lives { MethodName->new(value => 'method_123') }, 
           'alphanumeric and underscore ok');
        
        # 予約プレフィックスの境界
        ok(lives { MethodName->new(value => 'rpcMethod') }, 
           'starts with "rpc" but not "rpc." is ok');
        
        like(dies { MethodName->new(value => 'rpc.internal') }, 
             qr/reserved/, '"rpc." prefix is reserved');
    };
};
```

#### 最小値・最大値・範囲外のテスト

```perl
subtest 'min-max-out-of-range test' => sub {
    # 最小値-1（範囲外）
    like(dies { MethodName->new(value => '') }, qr/empty/);
    
    # 最小値（境界）
    ok(lives { MethodName->new(value => 'a') });
    
    # 通常値
    ok(lives { MethodName->new(value => 'getUser') });
    
    # 最大値（境界）
    ok(lives { MethodName->new(value => 'x' x 255) });
    
    # 最大値+1（範囲外）
    like(dies { MethodName->new(value => 'x' x 256) }, qr/too long/);
};
```

## MethodName値オブジェクトの実装 - TDD実践チュートリアル

それでは、実際にRed-Green-Refactorサイクルを回しながら、`MethodName`値オブジェクトを作っていこう。これは、前回の記事で設計したJSON-RPC 2.0のメソッド名を表現する値オブジェクトである。

### Red - 失敗するテストを書く（最初の一歩）

まず、テストファイルを作成する。

```perl
use Test2::V0;
use lib 'lib';

# まだ存在しないモジュール
use_ok 'JsonRpc::MethodName' or die;

subtest 'constructor accepts valid method name' => sub {
    my $method = JsonRpc::MethodName->new(value => 'getUser');
    
    ok $method, 'object created';
    is $method->value, 'getUser', 'value is correct';
};

subtest 'constructor rejects empty string' => sub {
    like(
        dies { JsonRpc::MethodName->new(value => '') },
        qr/method name cannot be empty/i,
        'empty string is rejected'
    );
};

subtest 'constructor rejects undef' => sub {
    like(
        dies { JsonRpc::MethodName->new(value => undef) },
        qr/method name cannot be empty/i,
        'undef is rejected'
    );
};

subtest 'constructor rejects non-string types' => sub {
    like(
        dies { JsonRpc::MethodName->new(value => []) },
        qr/must be.*string/i,
        'array reference is rejected'
    );
    
    like(
        dies { JsonRpc::MethodName->new(value => {}) },
        qr/must be.*string/i,
        'hash reference is rejected'
    );
};

done_testing;
```

テストを実行すると、当然失敗する（Red）。

```bash
$ prove -lv t/method_name.t
t/method_name.t .. 
not ok 1 - use JsonRpc::MethodName;
# Failed test 'use JsonRpc::MethodName;'
# at t/method_name.t line 4.
# Tried to use 'JsonRpc::MethodName'.
# Error:  Can't locate JsonRpc/MethodName.pm in @INC
```

### Green - 最小実装で通す

次に、テストを通すための最小限の実装を書く。

```perl
package JsonRpc::MethodName;
use v5.38;
use Moo;

has value => (
    is       => 'ro',
    required => 1,
    isa      => sub {
        my $val = shift;
        
        # undef チェック
        die "method name cannot be empty" unless defined $val;
        
        # 参照型チェック
        die "method name must be string" if ref $val;
        
        # 空文字列チェック
        die "method name cannot be empty" if $val eq '';
    },
);

1;
```

テストを再実行すると、すべて成功する（Green）！

```bash
$ prove -lv t/method_name.t
t/method_name.t .. 
ok 1 - use JsonRpc::MethodName;
    # Subtest: constructor accepts valid method name
    ok 1 - object created
    ok 2 - value is correct
    1..2
ok 2 - constructor accepts valid method name
    # Subtest: constructor rejects empty string
    ok 1 - empty string is rejected
    1..1
ok 3 - constructor rejects empty string
    # Subtest: constructor rejects undef
    ok 1 - undef is rejected
    1..1
ok 4 - constructor rejects undef
    # Subtest: constructor rejects non-string types
    ok 1 - array reference is rejected
    ok 2 - hash reference is rejected
    1..2
ok 5 - constructor rejects non-string types
1..5
ok
All tests successful.
```

### Refactor - リファクタリング

テストが通ったので、コードを改善する。バリデーションロジックをメソッドに分離し、より読みやすく保守しやすいコードにする。

```perl
package JsonRpc::MethodName;
use v5.38;
use Moo;
use namespace::clean;

has value => (
    is       => 'ro',
    required => 1,
    isa      => sub {
        my $val = shift;
        _validate_method_name($val);
    },
);

# バリデーションロジックを分離
sub _validate_method_name {
    my $val = shift;
    
    # 型チェック
    die "method name must be string, got " . (ref($val) || 'undef')
        if !defined $val || ref $val;
    
    # 空文字列チェック（空白のみも拒否）
    die "method name cannot be empty"
        if $val eq '' || $val =~ /^\s*$/;
    
    # JSON-RPC 2.0仕様: "rpc." プレフィックスは予約済み
    die "method names starting with 'rpc.' are reserved"
        if $val =~ /^rpc\./;
    
    return 1;
}

1;
```

リファクタリング後もテストは成功し続ける。これがTDDの安心感である！

#### 追加機能のテスト

予約語チェックを追加したので、テストも追加する。

```perl
subtest 'reserved method name "rpc." prefix is rejected' => sub {
    like(
        dies { JsonRpc::MethodName->new(value => 'rpc.internal') },
        qr/reserved/i,
        '"rpc." prefix is reserved'
    );
    
    # "rpc" だけならOK
    ok(lives { JsonRpc::MethodName->new(value => 'rpcMethod') },
       '"rpc" without dot is ok');
};
```

#### 完全な実装

```perl
package JsonRpc::MethodName;
use v5.38;
use Moo;
use namespace::clean;

has value => (
    is       => 'ro',
    required => 1,
    isa      => sub {
        my $val = shift;
        _validate_method_name($val);
    },
);

sub _validate_method_name {
    my $val = shift;
    
    die "method name must be string, got " . (ref($val) || 'undef')
        if !defined $val || ref $val;
    
    die "method name cannot be empty"
        if $val eq '' || $val =~ /^\s*$/;
    
    die "method names starting with 'rpc.' are reserved"
        if $val =~ /^rpc\./;
    
    return 1;
}

sub equals {
    my ($self, $other) = @_;
    return 0 unless $other && $other->isa(__PACKAGE__);
    return $self->value eq $other->value;
}

sub to_string {
    my $self = shift;
    return $self->value;
}

1;

__END__

=head1 NAME

JsonRpc::MethodName - JSON-RPC method name value object

=head1 SYNOPSIS

    use JsonRpc::MethodName;
    
    # Create valid method name
    my $method = JsonRpc::MethodName->new(value => 'getUser');
    say $method->value;  # "getUser"
    
    # Invalid names are rejected
    eval {
        my $invalid = JsonRpc::MethodName->new(value => '');
    };
    say $@ if $@;  # Error: method name cannot be empty

=head1 DESCRIPTION

This module implements a value object for JSON-RPC 2.0 method names.
It ensures method names are valid according to the specification.

Validation rules:

=over 4

=item * Must be a string (not undef, not a reference)

=item * Cannot be empty or whitespace-only

=item * Cannot start with "rpc." (reserved prefix)

=item * Is immutable after creation

=back

=head1 METHODS

=head2 value

Returns the method name string.

=head2 equals($other)

Compares this method name with another MethodName object for equality.

=head2 to_string

Returns the string representation of the method name.

=head1 SPECIFICATION

L<https://www.jsonrpc.org/specification>

=cut
```

## サブテストで整理する - テストの可読性と保守性を高める

テストが増えてくると、整理が重要になる。Test2の`subtest`を使うと、テストを論理的にグループ化し、実行結果を階層的に表示できる。これにより、どのテストが失敗したかが一目瞭然になる。

### subtestによるグルーピング

テストをsubtestで整理すると、構造が明確になる。

#### 整理後の例

```perl
use Test2::V0;
use lib 'lib';
use JsonRpc::MethodName;

subtest 'Constructor validation' => sub {
    subtest 'accepts valid method names' => sub {
        ok(lives { JsonRpc::MethodName->new(value => 'getUser') }, 
           'simple method name');
        ok(lives { JsonRpc::MethodName->new(value => 'findUserById') }, 
           'camelCase method name');
        ok(lives { JsonRpc::MethodName->new(value => 'create_user') }, 
           'snake_case method name');
    };
    
    subtest 'rejects invalid inputs' => sub {
        like(dies { JsonRpc::MethodName->new(value => '') }, 
             qr/empty/, 'empty string');
        like(dies { JsonRpc::MethodName->new(value => undef) }, 
             qr/empty/, 'undef');
        like(dies { JsonRpc::MethodName->new(value => '  ') }, 
             qr/empty/, 'whitespace only');
    };
    
    subtest 'rejects reserved prefix' => sub {
        like(dies { JsonRpc::MethodName->new(value => 'rpc.internal') }, 
             qr/reserved/, 'rpc. prefix rejected');
        ok(lives { JsonRpc::MethodName->new(value => 'rpcMethod') }, 
           'rpc without dot is ok');
    };
};

subtest 'Value object characteristics' => sub {
    subtest 'immutability' => sub {
        my $method = JsonRpc::MethodName->new(value => 'getUser');
        
        like(dies { $method->value('setUser') }, 
             qr/read-only|Usage/, 'cannot modify value');
        is $method->value, 'getUser', 'value unchanged';
    };
    
    subtest 'equality by value' => sub {
        my $m1 = JsonRpc::MethodName->new(value => 'getUser');
        my $m2 = JsonRpc::MethodName->new(value => 'getUser');
        my $m3 = JsonRpc::MethodName->new(value => 'setUser');
        
        ok $m1->equals($m2), 'same value equals';
        ok $m1->equals($m1), 'equals itself';
        ok !$m1->equals($m3), 'different value not equal';
    };
    
    subtest 'string representation' => sub {
        my $method = JsonRpc::MethodName->new(value => 'getUser');
        is $method->to_string, 'getUser', 'to_string works';
    };
};

subtest 'Boundary value tests' => sub {
    subtest 'minimum length' => sub {
        ok(lives { JsonRpc::MethodName->new(value => 'a') }, 
           'single character accepted');
        like(dies { JsonRpc::MethodName->new(value => '') }, 
             qr/empty/, 'zero length rejected');
    };
    
    subtest 'special characters' => sub {
        ok(lives { JsonRpc::MethodName->new(value => 'get_user') }, 
           'underscore allowed');
        ok(lives { JsonRpc::MethodName->new(value => 'getUser123') }, 
           'numbers allowed');
    };
};

done_testing;
```

#### 実行結果

```bash
$ prove -lv t/method_name.t
t/method_name.t .. 
    # Subtest: Constructor validation
        # Subtest: accepts valid method names
        ok 1 - simple method name
        ok 2 - camelCase method name
        ok 3 - snake_case method name
        1..3
    ok 1 - accepts valid method names
        # Subtest: rejects invalid inputs
        ok 1 - empty string
        ok 2 - undef
        ok 3 - whitespace only
        1..3
    ok 2 - rejects invalid inputs
        # Subtest: rejects reserved prefix
        ok 1 - rpc. prefix rejected
        ok 2 - rpc without dot is ok
        1..2
    ok 3 - rejects reserved prefix
    1..3
ok 1 - Constructor validation
    # Subtest: Value object characteristics
        # Subtest: immutability
        ok 1 - cannot modify value
        ok 2 - value unchanged
        1..2
    ok 1 - immutability
        # Subtest: equality by value
        ok 1 - same value equals
        ok 2 - equals itself
        ok 3 - different value not equal
        1..3
    ok 2 - equality by value
        # Subtest: string representation
        ok 1 - to_string works
        1..1
    ok 3 - string representation
    1..3
ok 2 - Value object characteristics
    # Subtest: Boundary value tests
        # Subtest: minimum length
        ok 1 - single character accepted
        ok 2 - zero length rejected
        1..2
    ok 1 - minimum length
        # Subtest: special characters
        ok 1 - underscore allowed
        ok 2 - numbers allowed
        1..2
    ok 2 - special characters
    1..2
ok 3 - Boundary value tests
1..3
ok
All tests successful.
```

階層構造が一目瞭然で、どのテストが失敗したかも分かりやすくなる。

### テストの分類と構成

テストを機能別に分離すると、保守性が大きく向上する。

```perl
# コンストラクタのテスト
subtest 'Constructor tests' => sub {
    # ...
};

# バリデーションのテスト
subtest 'Validation tests' => sub {
    # ...
};

# メソッドのテスト
subtest 'Method tests' => sub {
    # ...
};
```

この構造により、新しいテストを追加する場所が明確になり、関連するテストをまとめて実行できる。

## まとめ - Test2とTDDで学んだこと

この記事では、PerlのTest2::V0を使った値オブジェクトのテスト駆動開発を実践した。MethodName値オブジェクトを題材に、Red-Green-Refactorサイクルを体験しながら、実践的なテスト技法を学んだ。

**TDDの実践で得られたもの**:

- **Red-Green-Refactorサイクル**: テストファースト開発の具体的な流れ
- **設計の改善**: テストを先に書くことで気づく設計の問題
- **リファクタリングの安心感**: テストがあるからこそ大胆に改善できる
- **ドキュメントとしての価値**: テストコードが仕様書の役割を果たす

**Test2の機能習得**:

- `ok`, `is`, `isnt` - 基本アサーションの使い分け
- `like`, `unlike` - 正規表現パターンマッチング
- `dies`, `lives` - 例外テストと安全性検証
- `subtest` - テストの階層化と可読性向上

**値オブジェクトのテストパターン**:

- **コンストラクタバリデーション**: 不正な値の確実な拒否
- **不変性の検証**: 値が変更されないことの保証
- **等価性のテスト**: 値による比較の正確性
- **境界値分析**: エッジケースでのバグ発見

TDDを実践することで、設計の改善、品質の向上、開発速度の向上、そしてドキュメントとしての価値が得られる。次回は、これらの技法を複合的な値オブジェクトに適用する。

## 次回予告 - Request/Response値オブジェクトの実装

次回は「**JSON-RPC Request/Response値オブジェクトの実装 - 複合的な値オブジェクト**」として、より複雑な値オブジェクトの設計とTDDを学ぶ。

**次回の学習内容**:

- 複数のフィールドを持つ値オブジェクトの設計
- 排他的制約（id/notification）の型表現
- Test2::Toolsの高度な機能（配列、ハッシュの検証）
- ネストした値オブジェクトのテスト戦略

今回学んだ`MethodName`は、次回のRequest/Responseオブジェクトの構成要素として使われる。TDDの実践経験を積み重ねることで、より堅牢な設計スキルを身につけよう。

## 参考リンク - さらに深く学ぶために

Test2とTDDをさらに深く学びたい方は、以下のリソースを参照してほしい。

{{< linkcard "https://metacpan.org/pod/Test2::V0" >}}
{{< linkcard "https://metacpan.org/pod/Test2::Manual" >}}
{{< linkcard "https://metacpan.org/pod/Test2::Tools::Exception" >}}
{{< linkcard "https://www.nqou.net/2025/12/07/000000/" >}}
{{< linkcard "https://www.nqou.net/2025/12/09/214754/" >}}

## シリーズ記事

1. [値オブジェクトって何だろう？ - DDDの基本概念とPerlでの実装入門](/2025/12/16/value-object-introduction-with-perl/)
2. [JSON-RPC 2.0で学ぶ値オブジェクト設計 - 仕様から設計へ](/2025/12/17/json-rpc-value-object-design/)
3. **Test2でTDDを実践しよう - 値オブジェクトのテスト戦略**（この記事）
4. JSON-RPC Request/Response値オブジェクトの実装 - 複合的な値オブジェクト（次回）
5. エラー処理と境界値テスト - 堅牢な値オブジェクトを作る
