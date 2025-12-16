---
title: "JSON-RPC 2.0 調査ログ"
date: 2025-12-16
draft: false
tags:
  - "json-rpc"
  - "rpc"
description: "JSON-RPC 2.0 の仕様・使用例・運用上の注意点をまとめる"
---

## 目的

JSON-RPC 2.0 の仕様と実運用での使い方（HTTP/WebSocket 等の輸送、エラー処理、バッチ、通知、セキュリティ）を整理する。

## 要点まとめ

- 仕様: 軽量・ステートレスな RPC プロトコルで「transport-agnostic」。メッセージは JSON。公式仕様: https://www.jsonrpc.org/specification
- リクエスト: `jsonrpc` ("2.0"), `method` (String), 任意の `params` (Array or Object), 任意の `id` (String | Number | NULL)。`id` が無ければ通知（Notification）。
- レスポンス: 成功時は `result`、失敗時は `error`（`code`, `message`, 任意の `data`）、`id` はリクエストの `id` と一致（パースエラー等で id が不明な場合は `null`）。
- エラーコード（主な予約）:
  - -32700 Parse error
  - -32600 Invalid Request
  - -32601 Method not found
  - -32602 Invalid params
  - -32603 Internal error
  - -32000〜-32099 Server error (実装定義)
- バッチ: 複数の Request を配列で送信可能。サーバは配列で複数の Response を返す（Notification にはレスポンス無し）。空配列はエラー扱い。

## 典型的な HTTP 使用例

- エンドポイント: 単一の HTTP POST エンドポイント（例: `/rpc`）に対して JSON を送るのが一般的。
- 必須ヘッダ: `Content-Type: application/json`
- 例 — 単一リクエスト:

```json
// Request (POST body)
{"jsonrpc":"2.0","method":"subtract","params":[42,23],"id":1}

// Response (200 OK, body)
{"jsonrpc":"2.0","result":19,"id":1}
```

- 例 — Notification (応答なし):

```json
{"jsonrpc":"2.0","method":"update","params":[1,2,3,4,5]}
```

- 例 — バッチ:

```json
[
  {"jsonrpc":"2.0","method":"sum","params":[1,2,3],"id":"1"},
  {"jsonrpc":"2.0","method":"notify_hello","params":[7]},
  {"jsonrpc":"2.0","method":"subtract","params":[42,23],"id":"2"}
]

// サーバ応答例（順不同可）
[
  {"jsonrpc":"2.0","result":6,"id":"1"},
  {"jsonrpc":"2.0","result":19,"id":"2"}
]
```

## WebSocket / 長時間接続での利用

- JSON-RPC は輸送非依存なので WebSocket と相性が良い（双方向、低レイテンシ）。
- メッセージはテキストフレームに JSON を乗せる。通知/バッチ/リクエストは同じ形式で送受信可能。
- 接続管理、再接続、順序保証（必要なら id を工夫）を実装側でカバーする必要あり。

## セキュリティと運用上の注意点

- 認証/認可: プロトコル自体に認証は含まれない。HTTP ヘッダ（Bearer トークン等）やセッション、TLS を組み合わせる。
- TLS: 常に HTTPS / WSS を使う（認証情報や内部エラー情報流出を防ぐ）。
- CSRF: ブラウザ経由で JSON POST を受ける場合は CSRF トークン／CORS 制限を用いる。`Content-Type: application/json` のみ許可するだけでは十分ではない。
- 入力検証: `params` を厳密に検証し、過大な配列や深いネストによる DoS を防ぐ。
- エラーメッセージ: 内部情報を `error.data` に載せない（ログに残しつつクライアントには簡潔な説明を返す）。
- レート制限・監査: 公開 API ではレート制限、IP/認証情報単位での監査を行う。
- バッチの注意: Notification を混在させると応答が来ない要素があるため、クライアントはレスポンス配列を `id` で照合する必要がある。

## エラーハンドリングの実装方針（推奨）

- 受信 JSON のパース失敗 → -32700（レスポンスの `id` は `null`）
- リクエストオブジェクトの構造不正 → -32600
- 未知メソッド → -32601
- パラメータ検証失敗 → -32602（`data` に検証エラー情報を付けるが詳細は限定）
- サーバ内部例外 → -32603（または -320xx の実装定義）

## ライブラリ・エコシステム（参考）

- 公式仕様: https://www.jsonrpc.org/specification
- 実装例/ガイド: Wikipedia の JSON-RPC ページ（実装リストあり）
- OpenRPC（仕様記述・ドキュメント生成）: https://www.open-rpc.org/
- 各言語のライブラリは多数存在（例: JavaScript の `json-rpc-2.0`、Python の `jsonrpcserver/jsonrpcclient`、Go の `gorilla/rpc/json` など）。選定時はバッチ/notification/transport サポートを確認する。

## Perl 実装サマリ

- 主な CPAN モジュール:
  - `RPC::JSON` — シンプルな JSON‑RPC 実装。クライアント／サーバのユーティリティを提供し、試作や小規模用途に向く。
  - `JSON::RPC::Common` / `JSON::RPC::Client` — 仕様準拠の部品（低レベル）。クライアント実装やカスタムサーバで便利。
  - `RPC::Any` / `RPC::Any::Server::JSONRPC` — 抽象化された RPC フレームワーク。シリアライゼーションやトランスポートを切り替え可能で、拡張性が高い。
  - `Mojolicious::Plugin::JSONRPC` — Mojolicious アプリへ JSON‑RPC エンドポイントを統合するプラグイン（ルーティングと自然に統合可能）。

- 選定指針:
  - 簡易プロトタイプ: `RPC::JSON` または `JSON::RPC::Client` を利用して迅速に立ち上げる。
  - Mojolicious 統合: Web アプリ／WebSocket と組み合わせるなら `Mojolicious::Plugin::JSONRPC` を検討。
  - 柔軟性・将来性: 複数トランスポートや大規模化を見越すなら `RPC::Any` の採用を推奨。

- Perl 向け実装上の注意点:
  - モジュール毎に通知／バッチ／id の扱いに差がある。クライアントとサーバで仕様の相互検証を行うこと。
  - Mojolicious 統合時は `Content-Type` / CORS / TLS 設定とプラグインのエラーハンドリング挙動（`error.code` / `error.data`）を事前に確認する。
  - 非同期処理や重いタスクは `Mojo::IOLoop->subprocess` や Minion 等の外部ワーカーへ切り出し、イベントループをブロックしないようにする。

- 簡単な Mojolicious 統合例（概念）:

```perl
use Mojolicious::Lite;

# 想定: Mojolicious::Plugin::JSONRPC をインストールしている
plugin 'JSONRPC' => { namespace => 'MyApp::RPC' };

app->start;

# 例: MyApp/RPC/Hello.pm にメソッドを置くと JSON-RPC 経由で呼べる
```

参考（CPAN）:
 - https://metacpan.org/pod/RPC::JSON
 - https://metacpan.org/pod/JSON::RPC::Common
 - https://metacpan.org/pod/JSON::RPC::Client
 - https://metacpan.org/pod/RPC::Any
 - https://metacpan.org/pod/RPC::Any::Server::JSONRPC
 - https://metacpan.org/pod/Mojolicious::Plugin::JSONRPC

## まとめと推奨

- JSON-RPC 2.0 はシンプルで柔軟だが、認証・エラーハンドリング・CORS/CSRF といった運用面は自前で対処する必要がある。
- 小〜中規模の内部 API、リアルタイム機能（WebSocket を使うチャットや通知）に特に向く。
- 公開 API として使う場合は REST と比較してドキュメント（OpenRPC など）とエコシステムを整備し、セキュリティ対策を厳格にすることを推奨する。

## 参考リンク

- JSON-RPC 2.0 仕様: https://www.jsonrpc.org/specification
- JSON-RPC historical/documents: https://www.jsonrpc.org/historical
- Wikipedia: https://en.wikipedia.org/wiki/JSON-RPC
- OpenRPC: https://www.open-rpc.org/

---

調査日時: 2025-12-16
調査者: GitHub Copilot (automation)
