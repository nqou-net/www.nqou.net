---
title: "【アウトライン案】JSON-RPC 2.0のレスポンスを値オブジェクトで完成させる - 排他性と型安全性の実現"
draft: true
tags:
- perl
- json-rpc
- value-object
- polymorphism
- type-safety
description: "第3回記事のアウトライン案3パターン（案A/B/C）- JSON-RPC 2.0のResponseオブジェクトを値オブジェクトで実装し、resultとerrorの排他性を実現する方法を、異なる切り口で提案します。"
---

# JSON-RPC 2.0のレスポンスを値オブジェクトで完成させる - アウトライン案

## 背景情報

- **シリーズ**: 全3回の第3回（最終回）
- **前提読者**: 第1回・第2回で値オブジェクトとRequest/Errorオブジェクトの実装を学んだ人
- **目的**: JSON-RPC 2.0仕様のResponse objectの排他性（resultとerrorの同時存在禁止）を値オブジェクトで表現し、Request/Response/Errorすべてを完成させる
- **文字数**: 約6,000〜7,000文字（コード例含む）
- **参考資料**: 
  - https://www.jsonrpc.org/specification （Response object部分）
  - 最新のポリモーフィズムと型安全性のベストプラクティス（2024-2025）

---

## 案A：排他性駆動アプローチ - 仕様の制約を型で表現する

### 要約

JSON-RPC 2.0仕様の「Response objectはresultとerrorを同時に持ってはならない（MUST NOT）」という排他性制約を、SuccessResponseとErrorResponseという2つの独立した値オブジェクトで表現。共通インターフェースを通じてポリモーフィズムを実現し、型システムで制約を強制する設計アプローチ。仕様の制約を「実行時チェック」ではなく「型設計」で解決する方法を体験する。

### 見出し構造

#### ## はじめに - シリーズの総括と最終回の位置づけ

- 第1回・第2回の復習：値オブジェクトの基本とRequest/Errorの実装
- 今回のゴール：Responseオブジェクトの完成とフルサイクル実装
- なぜResponseが最も難しいのか：排他性制約の実現

#### ## Response objectの仕様を精読する

- 仕様書の該当セクションの引用（Response object部分）
- 成功レスポンスの構造：`jsonrpc`, `result`, `id`
- エラーレスポンスの構造：`jsonrpc`, `error`, `id`
- **重要な排他性制約**：「MUST NOT contain both result and error」の意味と影響
- 排他性を守らない場合の問題：クライアント側の混乱、仕様違反、相互運用性の喪失

#### ## 排他性をどう実装するか - 3つのアプローチの比較

- **アプローチ1：単一クラス + フラグ**（アンチパターン）
  - `has_result`/`has_error`フラグで判定
  - 問題点：実行時チェック、型安全性なし、エラーの可能性を排除できない
- **アプローチ2：単一クラス + バリデーション**（従来型）
  - コンストラクタでresultとerrorの同時存在を検証
  - 問題点：実行時エラー、コンパイル時の安全性なし、テストの負荷増
- **アプローチ3：別々のクラス + 共通インターフェース**（推奨）
  - SuccessResponseとErrorResponseを完全に独立させる
  - 利点：型レベルで排他性を保証、コンパイル時の安全性、明確な意図表明
  - 本記事で採用するアプローチ

#### ## SuccessResponse 値オブジェクトの設計

- **必須フィールド**：`jsonrpc`, `result`, `id`
- Class::Tiny::Immutableによる実装
  - `jsonrpc`："2.0"固定（JsonRpcVersionオブジェクトを再利用）
  - `result`：Any型（成功時の戻り値、JSON化可能な任意の値）
  - `id`：RequestIdオブジェクト（nullの場合は通知への応答なので作成不可）
- コンストラクタバリデーション
  - `id`が未定義の場合はdieする（通知には応答しない仕様）
  - `result`は任意の値を許可（undef/null も含む）
- テストケース：
  - 正常系：様々な型のresult（文字列、数値、配列、ハッシュ、null）
  - 異常系：idがundefinedの場合のエラー
  - JSONシリアライゼーションの検証

#### ## ErrorResponse 値オブジェクトの設計

- **必須フィールド**：`jsonrpc`, `error`, `id`
- Class::Tiny::Immutableによる実装
  - `jsonrpc`："2.0"固定
  - `error`：JsonRpcErrorオブジェクト（第2回で実装済み）
  - `id`：RequestIdオブジェクトまたはnull（Parse errorの場合はidを取得できないためnull）
- コンストラクタバリデーション
  - `error`はJsonRpcErrorオブジェクトであることを検証
  - `id`はnullを許可（Parse error等のケース）
- テストケース：
  - 正常系：標準エラー、カスタムエラー、idがnullのケース
  - 異常系：errorが不正な型の場合
  - JSONシリアライゼーションの検証

#### ## 共通インターフェースとポリモーフィズムの実装

- **Roleパターンの導入**（Perlにおける疑似インターフェース）
  - JsonRpc::Responseロールの定義
  - 共通メソッド：`to_json()`, `jsonrpc()`, `id()`
  - 型判定メソッド：`is_success()`, `is_error()`
- **SuccessResponseとErrorResponseでのRole適用**
  - `with 'JsonRpc::Response'` による共通インターフェースの実装
  - 各クラス固有のメソッド実装
- **型安全なディスパッチ**
  - クライアント側でのポリモーフィックな処理
  - パターンマッチング風の処理（Perlでの実現方法）
- テストケース：
  - 共通インターフェースの動作確認
  - is_success()/is_error()による型判定
  - ポリモーフィックな処理の動作確認

#### ## Request → Response フルサイクル実装

- **ファクトリパターン**：ResponseFactoryの実装
  - `create_success(result => $value, id => $request_id)`
  - `create_error(error => $error_obj, id => $request_id)`
  - 引数に応じて適切な型のResponseを生成
- **Request処理の実装例**
  - JsonRpcRequestを受け取る
  - メソッドディスパッチ
  - 成功時はSuccessResponseを生成
  - 失敗時はErrorResponseを生成
- **完全なコード例**：リクエスト受信から応答生成まで
  - リクエストのパース（第2回の復習）
  - メソッド実行
  - レスポンス生成
  - JSONシリアライゼーション
- テストケース：
  - 正常なリクエスト → SuccessResponse
  - 不正なリクエスト → ErrorResponse（Invalid Request）
  - 存在しないメソッド → ErrorResponse（Method not found）
  - 通知（idなし）→ レスポンスなし

#### ## 型安全性がもたらす利点

- **コンパイル時の安全性**（Perlでの限界と対策）
  - 型チェックの実行時実施
  - Test::Moreによる包括的なテスト
  - 型ヒント的なドキュメント
- **保守性の向上**
  - 意図の明確化：SuccessResponseとErrorResponseの完全な分離
  - バグの早期発見：型の不一致は即座に検出
  - リファクタリングの安全性：変更の影響範囲が明確
- **ドメインロジックの表現力**
  - 仕様の制約を型で表現
  - ビジネスルールの可視化
  - コードが仕様書になる
- **2024-2025年のトレンド反映**
  - Result型パターンの採用（関数型プログラミングの影響）
  - ポリモーフィズムによる安全な分岐処理
  - 型による設計（Type-Driven Development）の実践

#### ## まとめ：3回シリーズの総括

- **第1回の振り返り**：値オブジェクトの基礎と不変性の重要性
- **第2回の振り返り**：RequestとErrorオブジェクトの実装
- **第3回の達成**：Responseオブジェクトと排他性の実現
- **完成した全体像**：JSON-RPC 2.0の完全な値オブジェクト実装
- **学んだ設計原則**
  - 仕様の制約を型で表現する
  - 不変性による安全性と予測可能性
  - 小さな値オブジェクトの組み合わせで複雑さを管理
  - テスト駆動開発による品質保証

#### ## さらなる学習への導線

- **実務への応用**
  - JSON-RPC 2.0サーバー/クライアントの完全実装
  - 他のRPCプロトコルへの応用（gRPC、GraphQL等）
  - マイクロサービスでの活用
- **設計パターンの深化**
  - ドメイン駆動設計（DDD）の探求
  - 関数型プログラミングのパターン（Result型、Maybe型等）
  - 型駆動開発（Type-Driven Development）
- **Perlの進化**
  - Corinna（次世代オブジェクトシステム）への移行
  - 最新のCPANモジュール動向
- **推奨リソース**
  - OpenRPC仕様（JSON-RPC APIの文書化）
  - Model Context Protocol（JSON-RPCの最新活用例）
  - Martin Fowlerの設計パターン書籍
  - Curtis "Ovid" Poeのブログ

### 推奨タグ

1. **perl** - 実装言語
2. **json-rpc** - 題材となる仕様
3. **value-object** - 設計パターンの核心
4. **polymorphism** - ポリモーフィズムによる型安全性
5. **type-safety** - この記事の重要テーマ

### コード例の構成

1. **アンチパターン例**：単一クラスで排他性を実装した場合の問題
2. **JsonRpc::Response.pm**：共通インターフェース（Role）の定義
3. **JsonRpc::SuccessResponse.pm**：成功レスポンスの値オブジェクト
4. **JsonRpc::ErrorResponse.pm**：エラーレスポンスの値オブジェクト
5. **JsonRpc::ResponseFactory.pm**：レスポンス生成ファクトリ
6. **JsonRpc::Server.pm**：簡易サーバー実装（Request → Response）
7. **t/success_response.t**：SuccessResponseのテストスイート
8. **t/error_response.t**：ErrorResponseのテストスイート
9. **t/response_polymorphism.t**：ポリモーフィズムのテスト
10. **t/full_cycle.t**：Request → Responseフルサイクルのテスト
11. **examples/complete_jsonrpc_example.pl**：完全な動作例

### シリーズのまとめ構成

**学習の旅の振り返り**：
- 第1回：値オブジェクトとは何か（概念理解）
- 第2回：RequestとErrorの実装（基礎固め）
- 第3回：Responseと排他性の実現（応用と完成）

**実装の成果物**：
- 完全なJSON-RPC 2.0値オブジェクトライブラリ
- 包括的なテストスイート
- GitHubリポジトリとして公開可能な品質

**次のステップ提案**：
- JSON-RPC 2.0サーバーの本格実装
- OpenRPCによるAPI文書化
- 他の設計パターンの探求

---

## 案B：ポリモーフィズム実践アプローチ - 型による設計を体験する

### 要約

ポリモーフィズム（多態性）を最大限に活用し、SuccessResponseとErrorResponseを異なる型として扱いながらも、共通インターフェースを通じて統一的に処理する方法を実践的に学ぶ。Perlの動的型付けという制約の中で、いかに型安全性を実現するかという挑戦を、具体的なコード例とテストで体験するハンズオン形式。

### 見出し構造

#### ## シリーズ最終回：型で表現する排他性

- これまでの復習：値オブジェクト、Request、Errorの実装
- 今回の挑戦：「resultとerrorは同時に存在できない」を型で表現
- ポリモーフィズムとは何か：一つのインターフェース、多様な実装

#### ## 排他性問題の本質を理解する

- **問題の定式化**
  - JSON-RPC 2.0仕様："Response MUST NOT contain both result and error"
  - 従来の実装：単一クラス + if/elseによる分岐
  - 課題：実行時までエラーを検出できない、意図が不明確
- **型による解決の発想**
  - 2つの異なる型を定義：SuccessResponse vs ErrorResponse
  - 型レベルで排他性を保証：両方を同時に持つことが構造的に不可能
  - コンパイラ（インタプリタ）の助けを借りる
- **Perlでの実現可能性**
  - 動的型付け言語の限界
  - Roleパターンとダックタイピング
  - テストによる型安全性の補完

#### ## SuccessResponse - 成功を表現する型

- **設計方針**：成功だけを表現、エラー情報は一切持たない
- **実装**（段階的構築）
  - ステップ1：最小限の実装（jsonrpc, result, idのみ）
  - ステップ2：バリデーション追加（idの必須性）
  - ステップ3：JSONシリアライゼーション対応
  - ステップ4：型判定メソッド追加（is_success, is_error）
- **コード例**：
```perl
package JsonRpc::SuccessResponse;
use Class::Tiny::Immutable qw(jsonrpc result id);

sub BUILD {
    my ($self) = @_;
    die "jsonrpc must be '2.0'" unless $self->jsonrpc eq '2.0';
    die "id is required for success response" unless defined $self->id;
}

sub is_success { 1 }
sub is_error   { 0 }

sub to_json {
    my ($self) = @_;
    return {
        jsonrpc => $self->jsonrpc,
        result  => $self->result,
        id      => $self->id,
    };
}

1;
```
- **テストケース**：
  - 様々なresult値（スカラー、配列、ハッシュ、null）
  - 型判定メソッドの動作確認
  - JSONシリアライゼーションの正確性

#### ## ErrorResponse - エラーを表現する型

- **設計方針**：エラーだけを表現、result情報は一切持たない
- **実装**（段階的構築）
  - ステップ1：最小限の実装（jsonrpc, error, idのみ）
  - ステップ2：error型の検証（JsonRpcErrorオブジェクト）
  - ステップ3：idのnull許可（Parse error対応）
  - ステップ4：型判定メソッド追加
- **コード例**：
```perl
package JsonRpc::ErrorResponse;
use Class::Tiny::Immutable qw(jsonrpc error id);

sub BUILD {
    my ($self) = @_;
    die "jsonrpc must be '2.0'" unless $self->jsonrpc eq '2.0';
    die "error must be JsonRpc::Error" 
        unless ref($self->error) eq 'JsonRpc::Error';
    # idはnullを許可（Parse errorの場合等）
}

sub is_success { 0 }
sub is_error   { 1 }

sub to_json {
    my ($self) = @_;
    return {
        jsonrpc => $self->jsonrpc,
        error   => $self->error->to_json,
        id      => $self->id,
    };
}

1;
```
- **テストケース**：
  - 様々なエラーコード（標準エラー、カスタムエラー）
  - idがnullの場合の動作
  - error型の検証動作

#### ## 共通インターフェースの設計 - Roleパターン

- **Roleパターンとは**
  - インターフェース的な役割を果たすモジュール
  - 複数のクラスに共通の振る舞いを要求
  - Perlでの実現：Role::Tiny または Moo/Mooseのrole機能
- **JsonRpc::Responseロールの定義**
```perl
package JsonRpc::Response;
use Role::Tiny;

requires qw(jsonrpc id to_json is_success is_error);

1;
```
- **SuccessResponse/ErrorResponseでのRole適用**
```perl
package JsonRpc::SuccessResponse;
use Role::Tiny::With;
with 'JsonRpc::Response';
# ... 既存の実装 ...
```
- **利点**：
  - 共通インターフェースの強制
  - ドキュメントとしての役割
  - リファクタリングの安全性向上

#### ## ポリモーフィックな処理の実装

- **統一的な扱い**：型に関わらず共通の処理
```perl
sub handle_response {
    my ($response) = @_;
    
    # 共通インターフェースを通じて処理
    say "JSON-RPC Version: " . $response->jsonrpc;
    say "Request ID: " . $response->id;
    
    # 型に応じた処理（ダックタイピング）
    if ($response->is_success) {
        say "Success! Result: " . Dumper($response->result);
    } elsif ($response->is_error) {
        say "Error: " . $response->error->message;
    }
}
```
- **パターンマッチング風の処理**（Perlでの実現）
```perl
sub process_response {
    my ($response) = @_;
    
    return match_response(
        $response,
        success => sub {
            my $res = shift;
            return "Got result: " . $res->result;
        },
        error => sub {
            my $res = shift;
            return "Got error: " . $res->error->message;
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
- **テストケース**：
  - 両方の型での共通処理の動作確認
  - 型判定による分岐処理の検証
  - パターンマッチング風処理のテスト

#### ## ResponseFactory - 適切な型を生成する

- **ファクトリパターンの役割**
  - 適切な型のResponseを生成
  - 生成ロジックの一元化
  - クライアントコードの簡素化
- **実装**：
```perl
package JsonRpc::ResponseFactory;

sub create_success {
    my ($class, %args) = @_;
    return JsonRpc::SuccessResponse->new(
        jsonrpc => '2.0',
        result  => $args{result},
        id      => $args{id},
    );
}

sub create_error {
    my ($class, %args) = @_;
    return JsonRpc::ErrorResponse->new(
        jsonrpc => '2.0',
        error   => $args{error},
        id      => $args{id},
    );
}

# 便利メソッド：標準エラーの生成
sub create_parse_error {
    my ($class, $message) = @_;
    return $class->create_error(
        error => JsonRpc::Error->parse_error($message),
        id    => undef,  # Parse errorの場合はnull
    );
}

sub create_method_not_found {
    my ($class, $method_name, $id) = @_;
    return $class->create_error(
        error => JsonRpc::Error->method_not_found($method_name),
        id    => $id,
    );
}

1;
```
- **テストケース**：
  - 各ファクトリメソッドの動作確認
  - 生成されたオブジェクトの型検証
  - 標準エラー生成の利便性確認

#### ## Request → Response フルサイクル実装

- **簡易JSON-RPCサーバーの実装**
```perl
package JsonRpc::Server;
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
    return undef if $request->is_notification;
    
    my $method_name = $request->method;
    
    # メソッドが存在しない
    unless (exists $self->{methods}{$method_name}) {
        return JsonRpc::ResponseFactory->create_method_not_found(
            $method_name, 
            $request->id
        );
    }
    
    # メソッド実行
    my $handler = $self->{methods}{$method_name};
    eval {
        my $result = $handler->($request->params);
        return JsonRpc::ResponseFactory->create_success(
            result => $result,
            id     => $request->id,
        );
    };
    
    # エラーが発生した場合
    if ($@) {
        return JsonRpc::ResponseFactory->create_error(
            error => JsonRpc::Error->internal_error($@),
            id    => $request->id,
        );
    }
}

1;
```
- **使用例**：
```perl
my $server = JsonRpc::Server->new;

$server->register_method('sum', sub {
    my ($params) = @_;
    return $params->[0] + $params->[1];
});

my $request = JsonRpc::Request->new(
    jsonrpc => '2.0',
    method  => 'sum',
    params  => [1, 2],
    id      => 1,
);

my $response = $server->handle_request($request);

if ($response->is_success) {
    say "Result: " . $response->result;  # "Result: 3"
}
```
- **テストケース**：
  - 成功ケース：メソッド実行 → SuccessResponse
  - エラーケース：存在しないメソッド → ErrorResponse
  - 通知ケース：応答なし
  - 例外ケース：メソッド内エラー → Internal error

#### ## 動的型付け言語における型安全性の実現

- **Perlの制約と対策**
  - コンパイル時の型チェックなし → テストで補完
  - 実行時の型検証 → BUILD/バリデーション
  - 型ヒント的なドキュメント → PODドキュメント
- **テスト戦略**
  - 型判定メソッドの包括的テスト
  - 不正な型での構築を拒否するテスト
  - ポリモーフィックな処理の動作確認
- **2024-2025年のベストプラクティス**
  - Result型パターンの採用（Rust、Haskellの影響）
  - 型による設計（Type-Driven Development）
  - 関数型プログラミングパターンの活用

#### ## まとめ：ポリモーフィズムで実現する型安全性

- **達成したこと**
  - 排他性を型レベルで保証
  - ポリモーフィックな処理の実現
  - Request → Responseフルサイクルの完成
- **学んだ設計パターン**
  - 値オブジェクトパターン
  - Roleパターン（インターフェース）
  - ファクトリパターン
  - ポリモーフィズム
- **動的型付け言語での型安全性**
  - テスト駆動開発の重要性
  - 実行時バリデーション
  - 明確なインターフェース設計

#### ## シリーズ総括と次のステップ

- **3回シリーズで学んだこと**
  - 値オブジェクトの基礎（第1回）
  - RequestとErrorの実装（第2回）
  - Responseと排他性の実現（第3回）
- **完成した成果物**
  - JSON-RPC 2.0完全実装
  - 包括的なテストスイート
  - 実務で使える設計パターン
- **さらなる学習へ**
  - ドメイン駆動設計（DDD）の探求
  - 関数型プログラミングの学習
  - 型システムの深い理解
  - 他の言語での実装（TypeScript、Rust等）
- **推奨リソース**
  - OpenRPC仕様
  - Model Context Protocol
  - 関数型プログラミング入門書
  - Corinna（Perlの次世代OOP）

### 推奨タグ

1. **perl** - 実装言語
2. **json-rpc** - 題材
3. **value-object** - 設計パターン
4. **polymorphism** - 記事の核心テーマ
5. **type-safety** - 実現する目標

### コード例の構成

1. **段階的実装**：各ステップを明確に示す
2. **テストファースト**：実装の前に必ずテストを示す
3. **ビフォーアフター**：アンチパターン → 改善版の対比
4. **動作例**：実際に動くコード例を豊富に提供
5. **完成版リポジトリ**：GitHubで公開可能な品質

**コードファイル数**: 12-15個（テストと実装のペア）

---

## 案C：実務応用アプローチ - JSON-RPC 2.0の完全実装を目指す

### 要約

3回シリーズの集大成として、実務で使える完全なJSON-RPC 2.0ライブラリを構築。Response objectの排他性実現に留まらず、バッチリクエスト対応、トランスポート層の抽象化、エラーハンドリング戦略、パフォーマンス最適化まで含めた、プロダクション品質の実装を目指す実践的アプローチ。2024-2025年の最新トレンド（Model Context Protocol等）も反映。

### 見出し構造

#### ## シリーズ最終回：実務で使えるJSON-RPC 2.0ライブラリの完成

- 第1回・第2回の復習と今回のスコープ
- プロダクション品質とは何か
- 本記事で実装する機能一覧
- 実務適用シナリオ（マイクロサービス、AI/LLM統合等）

#### ## Response objectの排他性を完璧に実装する

- **仕様の再確認**：MUST NOT contain both result and error
- **SuccessResponseの完全実装**
  - 必須フィールドとバリデーション
  - JSONシリアライゼーション/デシリアライゼーション
  - TO_JSONメソッドのオーバーライド（JSON::PPとの統合）
- **ErrorResponseの完全実装**
  - JsonRpc::Errorオブジェクトとの統合
  - idがnullのケース（Parse error等）
  - スタックトレース処理（開発環境のみ）
- **共通インターフェースの定義**
  - JsonRpc::Responseロール
  - 型判定メソッド：is_success, is_error
  - 共通メソッド：to_json, from_json
- **テスト戦略**
  - プロパティベーステスト（Test::QuickCheck）
  - 境界値テスト
  - ラウンドトリップテスト（JSON → オブジェクト → JSON）

#### ## バッチリクエスト対応

- **仕様の理解**
  - バッチリクエストの構造（JSON配列）
  - 各リクエストは独立して処理
  - 通知は応答なし
  - 応答は配列で返す
- **BatchRequest値オブジェクトの実装**
```perl
package JsonRpc::BatchRequest;
use Class::Tiny::Immutable qw(requests);

sub BUILD {
    my ($self) = @_;
    die "requests must be an array" unless ref($self->requests) eq 'ARRAY';
    die "batch must not be empty" unless @{$self->requests} > 0;
    
    # 各要素がJsonRpc::Requestであることを検証
    for my $req (@{$self->requests}) {
        die "Invalid request in batch" 
            unless $req->isa('JsonRpc::Request');
    }
}

1;
```
- **BatchResponse値オブジェクトの実装**
  - 応答の配列を保持
  - 通知には応答しない（配列から除外）
  - 全てが通知の場合は空配列
- **サーバー側の処理**
  - 並列処理の可能性（Future::AsyncAwait等）
  - エラーハンドリング（一部失敗時の挙動）
- **テストケース**
  - 通常のリクエスト混在
  - 全て通知の場合
  - 一部エラーの場合

#### ## トランスポート層の抽象化

- **トランスポート非依存の設計**
  - コアロジックとトランスポートの分離
  - アダプターパターンの適用
- **HTTP/HTTPSトランスポート**
```perl
package JsonRpc::Transport::HTTP;

sub send_request {
    my ($self, $request) = @_;
    my $json = encode_json($request->to_json);
    
    my $response = $self->{ua}->post(
        $self->{endpoint},
        'Content-Type' => 'application/json',
        Content => $json,
    );
    
    return decode_json($response->content);
}

1;
```
- **WebSocketトランスポート**（簡易実装例）
  - 双方向通信対応
  - 通知の活用
- **カスタムトランスポートの追加方法**
  - インターフェース定義
  - 実装例

#### ## エラーハンドリング戦略

- **標準エラーの完全実装**
  - Parse error (-32700)
  - Invalid Request (-32600)
  - Method not found (-32601)
  - Invalid params (-32602)
  - Internal error (-32603)
- **カスタムエラーの設計**
  - アプリケーション固有エラー（正の整数）
  - エラーレジストリパターン
  - エラーコードのドキュメント化
- **エラー情報の詳細化**
  - `data`フィールドの活用
  - 構造化されたエラー情報
  - セキュリティ考慮（機密情報の除外）
- **2024-2025年のベストプラクティス**
  - エラーコードの標準化
  - 多言語対応（i18n）
  - ログとモニタリングの統合

#### ## パフォーマンス最適化

- **JSONシリアライゼーションの最適化**
  - JSON::XS / Cpanel::JSON::XS の活用
  - ベンチマーク比較
- **キャッシング戦略**
  - レスポンスのキャッシュ（冪等なメソッド）
  - メタデータのキャッシュ
- **バッチリクエストの並列処理**
  - Future::AsyncAwaitの活用
  - リソース競合の回避
- **メモリ使用の最適化**
  - 不変オブジェクトの共有
  - 深いコピーの回避

#### ## OpenRPCによるAPI文書化

- **OpenRPC仕様の紹介**
  - JSON-RPC APIの機械可読な記述
  - ドキュメント生成
  - クライアントコード生成
- **メタデータの定義**
```yaml
openrpc: 1.2.6
info:
  title: My JSON-RPC API
  version: 1.0.0
methods:
  - name: sum
    params:
      - name: numbers
        schema:
          type: array
          items:
            type: number
    result:
      name: total
      schema:
        type: number
```
- **自動ドキュメント生成**
  - OpenRPC Document生成
  - Swagger UI的なインタラクティブドキュメント
- **スキーマバリデーション**
  - paramsのバリデーション
  - resultのバリデーション

#### ## Model Context Protocol (MCP) との統合

- **MCPとは**
  - AI/LLM統合のための標準プロトコル
  - JSON-RPC 2.0をベース
  - 2024年の最新トレンド
- **MCPでのJSON-RPC活用例**
  - リソース管理
  - ツール呼び出し
  - プロンプト管理
- **本実装のMCP適用**
  - 標準準拠による互換性
  - 拡張ポイント
- **参考資料**：
  - https://modelcontextprotocol.io/
  - MCP仕様とJSON-RPC 2.0の関係

#### ## テスト戦略の総合

- **ユニットテスト**
  - 各値オブジェクトの徹底的なテスト
  - Test::Moreによる網羅的なカバレッジ
- **統合テスト**
  - Request → Responseフルサイクル
  - バッチリクエスト処理
  - トランスポート層の統合
- **プロパティベーステスト**
  - ランダムデータでの検証
  - 不変性の保証
- **パフォーマンステスト**
  - ベンチマーク
  - メモリプロファイリング
- **テストカバレッジ**
  - Devel::Cover による測定
  - 80%以上のカバレッジ目標

#### ## デプロイと運用

- **CPANモジュールとしての公開**
  - モジュール構造の整理
  - ドキュメント（POD）の充実
  - META.json/META.ymlの作成
- **GitHubリポジトリの整備**
  - README.md
  - CONTRIBUTING.md
  - LICENSE
  - GitHub Actions（CI/CD）
- **バージョニング戦略**
  - セマンティックバージョニング
  - 変更履歴の管理
- **モニタリングとロギング**
  - リクエスト/レスポンスのログ
  - エラートラッキング
  - メトリクス収集

#### ## 実務適用シナリオ

- **マイクロサービスアーキテクチャ**
  - サービス間通信にJSON-RPCを活用
  - RESTとの使い分け
  - メリット：軽量、シンプル、型安全
- **AI/LLM統合（MCP）**
  - LLMへのツール提供
  - リソース管理
  - プロンプト管理
- **内部API**
  - フロントエンド ↔ バックエンド通信
  - バッチ処理の効率化
- **レガシーシステム統合**
  - 既存システムとの橋渡し
  - プロトコル変換

#### ## シリーズ総括：3回で学んだ全て

- **第1回：基礎**
  - 値オブジェクトとは何か
  - 不変性の重要性
  - 等価性とカプセル化
- **第2回：基本実装**
  - RequestとErrorの実装
  - TDDの実践
  - 仕様駆動開発
- **第3回：完成と応用**
  - Responseと排他性の実現
  - バッチリクエスト対応
  - 実務適用
- **設計原則の体得**
  - 単一責任の原則
  - 開放閉鎖の原則
  - 依存性逆転の原則
- **完成した成果物の価値**
  - プロダクション品質
  - 再利用可能
  - 保守性の高さ

#### ## さらなる探求へ

- **他の言語での実装**
  - TypeScript（型システムの恩恵）
  - Rust（Result型、パターンマッチング）
  - Go（並行処理）
- **関連プロトコル**
  - gRPC
  - GraphQL
  - WebSocket
- **設計パターンの深化**
  - ドメイン駆動設計（DDD）
  - 関数型プログラミング
  - イベントソーシング
- **推奨書籍とリソース**
  - "Domain-Driven Design" by Eric Evans
  - "Patterns of Enterprise Application Architecture" by Martin Fowler
  - OpenRPC公式ドキュメント
  - MCP公式仕様
  - Perlコミュニティの最新動向（blogs.perl.org等）

### 推奨タグ

1. **perl** - 実装言語
2. **json-rpc** - プロトコル
3. **value-object** - 設計パターン
4. **production-ready** - プロダクション品質
5. **microservices** - 適用領域

### コード例の構成

1. **完全な実装**：全モジュールの完成版コード
2. **テストスイート**：包括的なテストケース
3. **使用例**：実際のユースケース
4. **ベンチマーク結果**：パフォーマンス測定
5. **デプロイメント例**：実運用への展開方法
6. **OpenRPC定義**：API文書化の例
7. **MCP統合例**：最新トレンドの実装

**コードファイル数**: 20-25個（完全なライブラリ構成）

**リポジトリ構造**：
```
json-rpc-perl/
├── lib/
│   └── JsonRpc/
│       ├── Request.pm
│       ├── Response.pm
│       ├── SuccessResponse.pm
│       ├── ErrorResponse.pm
│       ├── Error.pm
│       ├── BatchRequest.pm
│       ├── BatchResponse.pm
│       ├── Server.pm
│       ├── Client.pm
│       └── Transport/
│           ├── HTTP.pm
│           └── WebSocket.pm
├── t/
│   ├── 01_request.t
│   ├── 02_error.t
│   ├── 03_success_response.t
│   ├── 04_error_response.t
│   ├── 05_batch.t
│   ├── 06_server.t
│   └── 99_integration.t
├── examples/
│   ├── simple_server.pl
│   ├── simple_client.pl
│   └── batch_example.pl
├── README.md
├── CONTRIBUTING.md
└── META.json
```

---

## 3案の比較と推奨

### 案Aの特徴（排他性駆動アプローチ）

**強み**:
- 排他性という仕様の核心に焦点
- 型による制約表現の明確化
- 仕様書の制約を設計に直接反映
- シンプルで理解しやすい

**読者層**: 仕様駆動開発に関心がある人、型安全性を学びたい人、初中級者

**独自性**: 「MUST NOT contain both」を型レベルで解決する発想の転換

**文字数**: 約6,000〜6,500文字

---

### 案Bの特徴（ポリモーフィズム実践アプローチ）

**強み**:
- ポリモーフィズムの実践的な体験
- 段階的な実装プロセス
- Request → Responseフルサイクルの完成
- ハンズオン形式で挫折しにくい

**読者層**: 実際に手を動かして学びたい人、ポリモーフィズムを実践したい人、中級者

**独自性**: 動的型付け言語での型安全性実現という挑戦を明示

**文字数**: 約6,500〜7,000文字

---

### 案Cの特徴（実務応用アプローチ）

**強み**:
- プロダクション品質の実装
- バッチリクエスト、トランスポート抽象化等の実践的機能
- 2024-2025年の最新トレンド反映（MCP等）
- 実務で即使える成果物

**読者層**: 実務で使いたい人、上級者、最新技術に関心がある人

**独自性**: シリーズの総まとめとして実務レベルの完成度を目指す

**文字数**: 約7,000〜8,000文字（やや長め）

---

## 推奨案：案B（ポリモーフィズム実践アプローチ）

### 推奨理由

1. **シリーズの一貫性**
   - 第1回：概念理解
   - 第2回：TDD実践
   - 第3回：ポリモーフィズム実践
   - という段階的な学習曲線に最適

2. **実装と理論のバランス**
   - 排他性という理論的課題（案A）
   - 実務的な完全実装（案C）
   - その中間としてポリモーフィズムという実践的テーマが最適

3. **ハンズオン形式の効果**
   - 読者が実際に手を動かして学べる
   - 段階的構築で理解を深められる
   - Request → Responseフルサイクルの達成感

4. **文字数の適切性**
   - 6,500〜7,000文字で要求範囲内
   - 案Cは少し詰め込みすぎ
   - 案Aは少し物足りない可能性

5. **シリーズの総括として適切**
   - ポリモーフィズムは第1回・第2回の集大成
   - 値オブジェクト、TDD、型安全性の統合
   - 実務への橋渡しとなる内容

### 代替案の活用

- **案Aの要素を導入部に統合**
  - 「排他性問題の本質を理解する」セクションで案Aの視点を取り入れる
  - 3つのアプローチ比較で設計の選択肢を示す

- **案Cの要素を発展編として言及**
  - 「さらなる学習へ」セクションでバッチリクエスト、MCP等を紹介
  - 次の学習ステップとして実務応用を提示

### 記事構成の最終調整案

1. **導入**（10%）: シリーズの総括と排他性問題の提示
2. **理論**（15%）: 排他性をどう実装するか（案Aの要素）
3. **実装**（50%）: SuccessResponse/ErrorResponseの段階的構築（案Bの核心）
4. **統合**（15%）: Request → Responseフルサイクル
5. **総括**（10%）: シリーズまとめと次のステップ（案Cの要素）

---

## 付録：2024-2025年の最新トレンド

### JSON-RPC 2.0の現代的な活用

1. **Model Context Protocol (MCP)**
   - AI/LLM統合の標準プロトコル
   - JSON-RPC 2.0をメッセージング基盤として採用
   - Anthropic, OpenAI等が支持
   - 参考：https://modelcontextprotocol.io/

2. **マイクロサービスでの採用増**
   - RESTの代替としての再評価
   - 軽量で明確なセマンティクス
   - 型安全なクライアント生成が容易

3. **OpenRPC仕様の成熟**
   - JSON-RPC APIの機械可読な記述標準
   - ドキュメント自動生成
   - クライアントコード生成
   - 参考：https://spec.open-rpc.org/

### ポリモーフィズムと型安全性のトレンド

1. **Result型パターンの普及**
   - Rust, Haskell, Swiftの影響
   - Success/Errorを明示的に型で表現
   - `Result<T, E>` パターンの適用

2. **型駆動開発（Type-Driven Development）**
   - 型を設計の出発点とする
   - 制約を型で表現
   - コンパイラによる検証

3. **関数型プログラミングパターンの主流化**
   - 不変性の重視
   - Maybe/Option型
   - パターンマッチング

### Perlエコシステムの動向

1. **Corinna（次世代OOP）**
   - Perl 7（実質Perl 5.40+）で導入予定
   - クラスベースのOOP
   - ネイティブな不変性サポート

2. **モダンなCPANモジュール**
   - Moo/Mooseの継続的改善
   - Type::Tiny v2の強化
   - 関数型プログラミングライブラリ（Future::AsyncAwait等）

3. **開発ツールの進化**
   - Perlの静的解析ツール
   - LSP（Language Server Protocol）対応エディタ

---

## 結論

**推奨案**: 案B（ポリモーフィズム実践アプローチ）をベースに、案Aの排他性理論と案Cの実務要素を部分的に統合した構成が、シリーズ第3回（最終回）として最適です。

読者は、ポリモーフィズムの実践を通じて、JSON-RPC 2.0のResponseオブジェクトを値オブジェクトとして実装し、排他性を型レベルで保証する設計を体験できます。また、Request → Responseのフルサイクル実装により、シリーズ全体を通じた学習の集大成として、完全なJSON-RPC 2.0値オブジェクトライブラリを完成させることができます。

シリーズの総括として、値オブジェクト、TDD、型安全性、ポリモーフィズムという設計原則を統合し、実務で活用できる知識と技術を読者に提供します。
