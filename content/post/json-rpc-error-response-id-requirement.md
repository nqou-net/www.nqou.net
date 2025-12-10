---
title: "JSON-RPC 2.0のエラーレスポンスには必ずIDが必要 - 8年越しに気づいた仕様の深い意図"
draft: true
tags:
  - json-rpc
  - api-design
  - error-handling
  - perl
  - batch-request
  - protocol-design
description: "JSON-RPC 2.0エラーレスポンスのID必須仕様を徹底解説。バッチリクエスト対応やクライアント実装の注意点、Parse errorとMethod not foundの違いまで。Perl/JavaScriptの実装例とベストプラクティスも紹介。"
---

## イントロダクション

2016年、私はPerlでJSON-RPC 2.0の仕様に準拠したライブラリ `JSON::RPC::Spec` を書きました。当時は仕様書を読み込んだつもりでしたが、8年の時を経て、重大な勘違いをしていたことに気づきました。

それは「**エラーレスポンスでもIDフィールドは必須である**」という仕様です。私はずっと「エラーが発生した場合は、IDフィールドを省略するか、単に `null` を返せばいい」と誤解していました。

しかし仕様書を改めて読み直すと、エラーレスポンスにも **必ず `id` フィールドが存在しなければならない**（値は `null` でも構わない）ことが明記されていたのです。

この記事では、なぜこの仕様になっているのか、その設計思想の深い意図と、実装時に注意すべきポイントについて解説します。

### この記事で分かること

- JSON-RPC 2.0におけるエラーレスポンスの正しい構造
- エラー時でもIDが必須である理由とその設計思想
- バッチリクエストとの関係性
- 実装時の落とし穴と注意点
- 他のプロトコル（REST、gRPC、GraphQL）との比較

## JSON-RPC 2.0のエラーレスポンス仕様の基本

### エラーレスポンスの構造

JSON-RPC 2.0の仕様によると、エラーレスポンスは以下の構造を持つ必要があります。

~~~json
{
  "jsonrpc": "2.0",
  "error": {
    "code": -32600,
    "message": "Invalid Request"
  },
  "id": null
}
~~~

ここで重要なのは、**`id` フィールドが常に存在する**という点です。仕様書には以下のように記載されています。

> **id**  
> This member is REQUIRED.  
> It MUST be the same as the value of the id member in the Request Object.  
> If there was an error in detecting the id in the Request object (e.g. Parse error / Invalid Request), it MUST be Null.

つまり、`id` フィールドは必須（REQUIRED）であり、リクエストから ID を取得できた場合はその値を、取得できなかった場合は `null` を設定しなければなりません。

### 私が誤解していたこと

私が8年間誤解していたのは、「エラーが発生した場合、`id` フィールドを省略できる」という点でした。具体的には、以下のようなレスポンスを返していました。

~~~json
{
  "jsonrpc": "2.0",
  "error": {
    "code": -32601,
    "message": "Method not found"
  }
}
~~~

しかし、これは仕様違反です。正しくは、以下のように **必ず `id` フィールドを含める** 必要があります。

~~~json
{
  "jsonrpc": "2.0",
  "error": {
    "code": -32601,
    "message": "Method not found"
  },
  "id": 123
}
~~~

この違いは些細に見えるかもしれませんが、後述するように、バッチリクエストやクライアント実装において重要な意味を持ちます。

## なぜエラー時でもIDが必要なのか

### バッチリクエストとの関係性

JSON-RPC 2.0では、複数のリクエストを配列にまとめて送信する「バッチリクエスト」がサポートされています。

~~~json
[
  {"jsonrpc": "2.0", "method": "sum", "params": [1,2,4], "id": "1"},
  {"jsonrpc": "2.0", "method": "notify_hello", "params": [7]},
  {"jsonrpc": "2.0", "method": "subtract", "params": [42,23], "id": "2"},
  {"jsonrpc": "2.0", "method": "foo.get", "params": {"name": "myself"}, "id": "5"},
  {"jsonrpc": "2.0", "method": "get_data", "id": "9"}
]
~~~

このバッチリクエストに対して、サーバーは以下のようなバッチレスポンスを返します。

~~~json
[
  {"jsonrpc": "2.0", "result": 7, "id": "1"},
  {"jsonrpc": "2.0", "result": 19, "id": "2"},
  {"jsonrpc": "2.0", "error": {"code": -32601, "message": "Method not found"}, "id": "5"},
  {"jsonrpc": "2.0", "result": ["hello", 5], "id": "9"}
]
~~~

この例では、`id: "5"` のリクエストがエラーになっていますが、**エラーレスポンスにも `id` が含まれている**ことに注目してください。

もし `id` がなければ、クライアントはどのリクエストがエラーになったのか判別できません。バッチリクエストでは、レスポンスの順序がリクエストと同じである保証がないため、`id` による紐付けが不可欠なのです。

### クライアント側の実装負担を軽減する設計思想

エラーレスポンスにも必ず `id` を含めることで、クライアント側の実装が大幅にシンプルになります。

もし「エラー時は `id` がない場合がある」という仕様だった場合、クライアントは以下のような分岐処理を書く必要があります。

~~~javascript
// 悪い例：idがない場合を考慮する必要がある
response.forEach(res => {
  if (res.id) {
    // idがある場合の処理
    const request = findRequestById(res.id);
    if (res.error) {
      request.reject(res.error);
    } else {
      request.resolve(res.result);
    }
  } else {
    // idがない場合...どうする？
    // 全てのリクエストにエラーを返す？最初のリクエスト？
  }
});
~~~

しかし、「エラーレスポンスにも必ず `id` がある」という仕様により、クライアントは以下のようにシンプルに書けます。

~~~javascript
// 良い例：idが必ず存在することを前提にできる
response.forEach(res => {
  const request = findRequestById(res.id);
  if (!request) {
    // id が null の場合はグローバルエラー
    handleGlobalError(res.error);
    return;
  }
  
  if (res.error) {
    request.reject(res.error);
  } else {
    request.resolve(res.result);
  }
});
~~~

### 仕様が「可能な限りIDを保持する」と表現している意図

仕様書では、Parse error や Invalid Request のように **リクエストから ID を取得できない場合にのみ `null` を返す**と明記されています。

これは「**可能な限り、リクエストとレスポンスの紐付けを維持する**」という設計思想を示しています。

たとえば、以下のようなケースを考えてみましょう。

- **Parse error（-32700）**: JSON自体が壊れているため、IDを取得できない → `id: null`
- **Invalid Request（-32600）**: JSONは正しいが、JSON-RPCの構造が不正（`jsonrpc` フィールドがないなど）でIDが取得できない → `id: null`
- **Method not found（-32601）**: リクエストの構造は正しく、IDも取得できる → **`id: <リクエストのID>`**

つまり、「メソッドが見つからない」「パラメータが不正」といった**アプリケーションレベルのエラー**では、リクエストの ID は正しく取得できているはずなので、それをレスポンスに含めるべきなのです。

この設計は、「**エラーハンドリングもリクエスト/レスポンスの一部である**」という一貫性のある考え方に基づいています。私はこの思想に深く共感しました。

## 実装における落とし穴と注意点

### パースエラーとその他のエラーの区別

実装時に最も注意すべきは、**Parse error と他のエラーを明確に区別する**ことです。

~~~perl
# Perlでの実装例（JSON::RPC::Specから抜粋）
sub handle_request {
    my ($self, $json_text) = @_;
    
    # 1. まずJSONのパースを試みる
    my $request;
    eval {
        $request = decode_json($json_text);
    };
    
    if ($@) {
        # Parse error: IDを取得できないので null を返す
        return encode_json({
            jsonrpc => "2.0",
            error   => {
                code    => -32700,
                message => "Parse error"
            },
            id => undef  # Perlでは undef が JSON の null になる
        });
    }
    
    # 2. リクエストのバリデーション
    unless (ref $request eq 'HASH' && $request->{jsonrpc} eq '2.0') {
        # Invalid Request: IDの取得を試みる
        my $id = ref $request eq 'HASH' ? $request->{id} : undef;
        return encode_json({
            jsonrpc => "2.0",
            error   => {
                code    => -32600,
                message => "Invalid Request"
            },
            id => $id  # 取得できたIDを返す（なければ null）
        });
    }
    
    # 3. メソッドの実行
    my $id = $request->{id};
    unless ($self->has_method($request->{method})) {
        # Method not found: IDは確実に取得できている
        return encode_json({
            jsonrpc => "2.0",
            error   => {
                code    => -32601,
                message => "Method not found"
            },
            id => $id  # 必ずリクエストのIDを返す
        });
    }
    
    # ...残りの処理
}
~~~

### IDの型とバリデーション

JSON-RPC 2.0の仕様では、`id` の値は **文字列、数値、または NULL** でなければならず、オブジェクトや配列は許可されていません。

~~~javascript
// 正しいID
{"jsonrpc": "2.0", "method": "test", "id": 123}        // 数値
{"jsonrpc": "2.0", "method": "test", "id": "abc"}      // 文字列
{"jsonrpc": "2.0", "method": "test", "id": null}       // null

// 不正なID
{"jsonrpc": "2.0", "method": "test", "id": {"key": 1}} // オブジェクト（NG）
{"jsonrpc": "2.0", "method": "test", "id": [1, 2, 3]}  // 配列（NG）
~~~

実装時には、この型チェックも忘れずに行いましょう。

### エラーコードの使い分け

JSON-RPC 2.0で予約されているエラーコードは以下の通りです。

| コード | メッセージ | 意味 | ID の値 |
|--------|-----------|------|----------|
| -32700 | Parse error | 不正なJSON | `null` |
| -32600 | Invalid Request | JSON-RPC構造が不正 | 取得できれば設定、できなければ `null` |
| -32601 | Method not found | メソッドが存在しない | リクエストの `id` |
| -32602 | Invalid params | パラメータが不正 | リクエストの `id` |
| -32603 | Internal error | サーバー内部エラー | リクエストの `id` |

-32000 から -32099 はサーバー定義のエラーコードとして予約されており、アプリケーション固有のエラーに使用できます。

重要なのは、**-32601 以降のエラーでは、必ずリクエストの `id` を返す**という点です。

## 他のプロトコルとの比較

### RESTful APIのエラーハンドリング

RESTful APIでは、エラーはHTTPステータスコードとレスポンスボディで表現されます。

~~~http
HTTP/1.1 404 Not Found
Content-Type: application/json

{
  "error": "Resource not found",
  "message": "The requested user does not exist"
}
~~~

RESTでは、リクエストとレスポンスがHTTPのリクエスト/レスポンスサイクルで1対1に対応しているため、JSON-RPCのような `id` による紐付けは不要です。

ただし、バッチリクエストのような複数操作の同時実行は、標準的にはサポートされていません。

### gRPCとの比較

gRPCでは、エラーはステータスコードとメタデータで表現されます。

~~~protobuf
// エラーレスポンスの例
rpc GetUser(GetUserRequest) returns (GetUserResponse) {}

// エラー時
status: INVALID_ARGUMENT
message: "User ID must be positive"
~~~

gRPCでは、ストリーミングRPCの場合を除き、各リクエストは独立したRPC呼び出しとして扱われるため、JSON-RPCのような明示的な `id` フィールドは不要です。

ただし、双方向ストリーミングの場合は、メッセージの順序やタイミングを管理する必要があり、実装の複雑さが増します。

### GraphQLのエラーモデル

GraphQLでは、エラーは `errors` 配列に格納され、部分的な成功も表現できます。

~~~json
{
  "data": {
    "user": null
  },
  "errors": [
    {
      "message": "User not found",
      "locations": [{"line": 2, "column": 3}],
      "path": ["user"]
    }
  ]
}
~~~

GraphQLは単一エンドポイントで複数のクエリを扱えますが、JSON-RPCのバッチリクエストとは異なり、クエリ全体が1つのリクエストとして扱われます。

**JSON-RPCの利点**は、シンプルさと可読性です。`id` による明示的な紐付けは、デバッグやログ解析を容易にします。

## まとめ

### 仕様の「行間」を読むことの重要性

今回、8年越しに気づいた「エラーレスポンスにも `id` が必須」という仕様は、単なる形式的なルールではなく、以下のような深い設計思想に基づいていました。

1. **バッチリクエストでの確実な紐付け**を可能にする
2. **クライアント実装をシンプルにする**（`id` の有無を気にしなくて済む）
3. **可能な限りリクエストとレスポンスの対応関係を維持する**

仕様書を読む際は、「なぜこの仕様になっているのか」という背景や意図を理解することが重要です。表面的な理解だけでは、今回の私のように、8年間も誤った実装を続けてしまう可能性があります。

### 8年越しの気づきから得た教訓

この経験から、私は以下の教訓を得ました。

- **仕様書は定期的に読み直す** - 技術は日々進化しますが、基礎となる仕様の理解も深化します
- **実装は仕様に忠実であるべき** - 「これくらい大丈夫だろう」という妥協は、将来的な問題を生む
- **テストケースで仕様を検証する** - 今回、`JSON::RPC::Spec` のテストを見直したことで問題に気づけました
- **オープンソースの責任** - CPANに公開したライブラリは、多くの人が使う可能性があります。間違った実装を修正し、アップデートすることは開発者の責務です

修正版の `JSON::RPC::Spec` は既にCPANで公開済みです。もし皆さんがJSON-RPC 2.0の実装を書く際は、ぜひこの記事の内容を参考にしてください。

{{< linkcard "https://metacpan.org/pod/JSON::RPC::Spec" >}}

仕様の「行間」にある設計思想を理解することで、より堅牢で保守性の高いコードが書けるようになります。私のように8年も気づかないよりは、この記事を読んで今すぐ理解していただければ幸いです。
