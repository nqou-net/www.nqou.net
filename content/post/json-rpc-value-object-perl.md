---
title: "JSON-RPC 2.0 の各オブジェクトを Perl の値オブジェクトとして定義してみる"
draft: true
tags:
- perl
- json-rpc
- value-object
- tdd
- oop
description: "JSON-RPC 2.0 のリクエストとレスポンスを値オブジェクトでまとめ、PerlでTDDを回す小さな練習"
---

## JSON-RPC 2.0 の構造をざっくり整理

- Request は `{jsonrpc:"2.0", method:"...", params:..., id:?}` の形。params は配列かオブジェクト、id はスカラー。Notification は `id` を省く。
- Response は Success と Error で別オブジェクトにするのが安全
  - Success: `{jsonrpc:"2.0", result:..., id:...}`
  - Error: `{jsonrpc:"2.0", error:{code, message, data?}, id:?}`（処理不能なら `id` は `null`）
- 成功と失敗を別クラスに分けると「必須キーがどちらか」で混乱しないし、型が崩れたときに早期に検知できる。
- バッチは Request の配列。各要素は単体 Request と同じルールで、レスポンスも配列で返す。

## Request/Response を値オブジェクト化する方針

- `jsonrpc` は常に `"2.0"` で固定。コンストラクタで強制。
- `method` は非空文字列。`params` は `ARRAY` か `HASH` か未指定のみ許容。
- `id` はスカラー（undef/文字列/数値）。Ref を弾く。
- Success と Error を別クラスに分け、`result` と `error` を混在させない。
- バッチは「Request の配列を受け取り、各要素を検証して配列のまま保持」するだけの薄いラッパーでよい。

## Perl でシンプルな値オブジェクト例

```perl
package JSON::RPC::Request;
use strict;
use warnings;

sub new {
  my ($class, %args) = @_;
  die "jsonrpc must be 2.0" unless ($args{jsonrpc} // '') eq '2.0';
  die "method required" unless defined $args{method} && $args{method} ne '';
  if (exists $args{id}) {
    die "id must be scalar" if ref $args{id};
  }
  if (exists $args{params}) {
    my $r = ref $args{params};
    die "params must be array or hash" unless $r eq 'ARRAY' || $r eq 'HASH';
  }
  return bless {
    jsonrpc => '2.0',
    method  => $args{method},
    params  => $args{params},
    id      => $args{id},
  }, $class;
}
```

```perl
package JSON::RPC::Response::Success;
use strict;
use warnings;

sub new {
  my ($class, %args) = @_;
  die "jsonrpc must be 2.0" unless ($args{jsonrpc} // '') eq '2.0';
  die "result required" unless exists $args{result};
  die "id must be scalar" if ref $args{id};
  return bless { jsonrpc => '2.0', result => $args{result}, id => $args{id} }, $class;
}
```

```perl
package JSON::RPC::Response::Error;
use strict;
use warnings;

sub new {
  my ($class, %args) = @_;
  die "jsonrpc must be 2.0" unless ($args{jsonrpc} // '') eq '2.0';
  die "code must be int" unless defined $args{code} && $args{code} =~ /^-?\d+$/;
  die "message required" unless defined $args{message} && $args{message} ne '';
  die "id must be scalar" if ref $args{id};
  return bless {
    jsonrpc => '2.0',
    error   => { code => 0 + $args{code}, message => $args{message}, data => $args{data} },
    id      => $args{id},
  }, $class;
}
```

## バリデーションルールの具体例

- `jsonrpc` が `"2.0"` 以外なら即例外。
- `method` は空文字禁止。スペルミスを早期に知る。
- `params` が `ARRAY`/`HASH` 以外なら例外。JSON-RPC の仕様外を弾く。
- `id` はスカラーのみ。配列やハッシュのまま渡すと検証で止まる。
- Error オブジェクトは `code` が整数、`message` が非空文字列。

## バッチ Request の扱い

- 受信した配列を `map { JSON::RPC::Request->new(%$_) } @$batch` のように全要素検証。
- 途中で例外が出たらその要素だけ Error を返す実装にしやすい（各要素が独立しているため）。
- レスポンス配列はリクエスト順を守る。値オブジェクトで id を保持しておくと紐付けが簡単。

## テスト駆動で進めると何が楽か

- ルールが明確なほどテストが短く済む。
- 例外を投げるパターンを列挙するだけで「防御的」なクラスが完成する。

```perl
use strict;
use warnings;
use Test::More;
use JSON::RPC::Request;

ok JSON::RPC::Request->new(jsonrpc => '2.0', method => 'ping', id => 1);
dies_ok { JSON::RPC::Request->new(jsonrpc => '1.0', method => 'ping') } 'jsonrpc mismatch';
dies_ok { JSON::RPC::Request->new(jsonrpc => '2.0', method => '', params => {}) } 'method empty';

done_testing;
```

## さいごに

- 値オブジェクトで構造を固定すれば、JSON-RPC の「薄いけど厳密な」ルールを破りにくい。
- 「必須キーが揃っているか」「型が正しいか」をコンストラクタで閉じ込め、テストで守れば安心して TDD を回せる。
