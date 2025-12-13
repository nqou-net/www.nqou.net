---
title: "Mojoliciousで書くWebSocket超入門 — リアルタイム通信の仕組みと実装"
draft: true
tags:
  - perl
  - mojolicious
  - websocket
  - real-time
description: "WebSocketの基本から実装まで、段階的に学ぶ実践ガイド。Mojoliciousを使って最小のサーバーからリアルタイムチャットまで構築します。"
---

[@nqounet](https://x.com/nqounet)です。

Webアプリケーションで「リアルタイム通信」と聞くと、なんだか難しそうなイメージがありませんか？実は、WebSocketを使えば、思っているより簡単にリアルタイム通信が実現できます。

この記事では、WebSocketプロトコルの仕組みを段階的に理解し、Mojoliciousを使って実際に動くコードを書きながら学んでいきます。最終的には、複数のブラウザでメッセージをやり取りできるリアルタイムチャットを作りましょう。

## WebSocketとは — リアルタイム通信の新しい形

WebSocketは、クライアント（ブラウザ）とサーバーの間で双方向通信を実現するプロトコルです。2011年にRFC 6455として標準化され、今では全ての主要ブラウザがサポートしています。

### HTTPとWebSocketの決定的な違い

従来のHTTP通信は「リクエスト→レスポンス」の一往復で完結します。サーバーから能動的にデータを送ることはできません。

```
[ブラウザ] ──リクエスト→ [サーバー]
[ブラウザ] ←レスポンス── [サーバー]
# これで接続終了
```

一方、WebSocketは一度接続を確立すると、その接続を維持したまま双方向にメッセージを送り合えます。

```
[ブラウザ] ←──接続維持──→ [サーバー]
           ←メッセージ→
           ←メッセージ→
           ←メッセージ→
```

この違いにより、サーバー側の変化を即座にブラウザに通知できるようになりました。

### WebSocketが活躍する場面

WebSocketは以下のような用途で威力を発揮します：

- **チャットアプリケーション**: メッセージの即時配信
- **ダッシュボード**: サーバーメトリクスのリアルタイム表示
- **共同編集ツール**: 複数人での同時編集
- **ゲーム**: プレイヤー間のリアルタイム同期
- **通知システム**: プッシュ通知の配信

ポーリング（定期的にHTTPリクエストを送る方法）と比べて、無駄な通信が減り、レイテンシ（遅延）も大幅に改善されます。

## WebSocketの仕組みを理解しよう

実装に入る前に、WebSocketがどのように動作するか理解しておきましょう。

### HTTPからのアップグレード — ハンドシェイク

WebSocket接続は、最初は普通のHTTPリクエストとして始まります。これを「WebSocketハンドシェイク」と呼びます。

クライアントは特別なヘッダーを付けてリクエストを送ります：

```http
GET /websocket HTTP/1.1
Host: example.com
Upgrade: websocket
Connection: Upgrade
Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==
Sec-WebSocket-Version: 13
```

サーバーが対応している場合、ステータスコード101で応答します：

```http
HTTP/1.1 101 Switching Protocols
Upgrade: websocket
Connection: Upgrade
Sec-WebSocket-Accept: s3pPLMBiTxaQ9kYGzzhZRbK+xOo=
```

この瞬間、プロトコルがHTTPからWebSocketに「切り替わり」ます。以降、同じTCP接続上でWebSocketフレームのやり取りが始まります。

### 双方向通信 — メッセージの送受信

ハンドシェイク完了後は、クライアントとサーバーがいつでも自由にメッセージを送信できます。待つ必要はありません。

メッセージは「フレーム」という単位でやり取りされ、テキストデータとバイナリデータの両方に対応しています。この記事では主にテキストメッセージを扱います。

### 接続のライフサイクル

WebSocket接続は以下のライフサイクルを持ちます：

1. **ハンドシェイク**: HTTPからWebSocketへの切り替え
2. **オープン**: 接続確立完了
3. **メッセージ交換**: 双方向通信
4. **クローズ**: どちらかが接続を閉じる

接続が切れたら再接続するロジックを実装することが一般的です。

## 環境準備

### 必要なもの

この記事では以下の環境を前提とします：

- Perl 5.24以上
- Mojolicious 9.0以上
- モダンブラウザ（Chrome、Firefox、Safariなど）

### Mojoliciousのインストール確認

Mojoliciousがインストールされているか確認しましょう：

```bash
perl -MMojolicious -e 'print $Mojolicious::VERSION, "\n"'
```

インストールされていない場合は、cpanmでインストールできます：

```bash
cpanm Mojolicious
```

準備が整ったら、実装を始めましょう！

## Step 1: 最小のWebSocketサーバーを動かす

まずは最もシンプルなWebSocketサーバーを作ります。クライアントが接続すると「Connected!」というメッセージを送信するだけのサーバーです。

### サーバーコード

`minimal.pl` という名前で以下のコードを保存してください：

```perl
#!/usr/bin/env perl
use Mojolicious::Lite -signatures;
use utf8;

# WebSocketルート
websocket '/ws' => sub ($c) {
  $c->app->log->info('WebSocket接続確立');
  
  # 接続確立時
  $c->send('Connected!');
};

app->start;
```

このコードを実行します：

```bash
perl minimal.pl daemon
```

サーバーが起動したら、ブラウザで `http://localhost:3000` を開いてください。

### ブラウザコンソールでテスト

ブラウザの開発者ツールを開き（F12キー）、コンソールタブで以下のJavaScriptを実行します：

```javascript
const ws = new WebSocket('ws://localhost:3000/ws');

ws.onopen = () => {
  console.log('WebSocket接続成功');
};

ws.onmessage = (event) => {
  console.log('受信:', event.data);
};

ws.onerror = (error) => {
  console.error('エラー:', error);
};

ws.onclose = () => {
  console.log('接続クローズ');
};
```

コンソールに「受信: Connected!」と表示されれば成功です！

### 何が起きているか

1. ブラウザが `ws://localhost:3000/ws` に接続
2. Mojoliciousが接続を受け入れ、ハンドシェイク実行
3. 接続確立後、`$c->send('Connected!')` でメッセージ送信
4. ブラウザの `onmessage` ハンドラが受信

たったこれだけでWebSocket通信が動きます。シンプルですね！

## Step 2: エコーサーバーを作る

次は、クライアントから受け取ったメッセージをそのまま返す「エコーサーバー」を作りましょう。これで双方向通信が実現できます。

### サーバー側の実装

`echo_server.pl` を作成します：

```perl
#!/usr/bin/env perl
use Mojolicious::Lite -signatures;
use utf8;

websocket '/ws' => sub ($c) {
  $c->app->log->info('新しい接続');
  
  # メッセージ受信時
  $c->on(message => sub ($c, $msg) {
    $c->app->log->info("受信: $msg");
    $c->send("Echo: $msg");
  });
  
  # 接続終了時
  $c->on(finish => sub ($c, $code, $reason) {
    $c->app->log->info("接続終了: code=$code");
  });
};

app->start;
```

ポイントは `$c->on(message => sub { ... })` です。これでメッセージ受信時のハンドラを登録できます。

### クライアント側の実装

HTMLファイルも用意しましょう。`public/echo.html` として保存します：

```html
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>WebSocketエコーテスト</title>
  <style>
    body {
      font-family: sans-serif;
      max-width: 600px;
      margin: 50px auto;
      padding: 20px;
    }
    #messages {
      border: 1px solid #ccc;
      height: 300px;
      overflow-y: scroll;
      padding: 10px;
      margin: 20px 0;
      background: #f9f9f9;
    }
    .message {
      margin: 5px 0;
      padding: 5px;
    }
    .sent {
      color: blue;
    }
    .received {
      color: green;
    }
    input[type="text"] {
      width: 70%;
      padding: 8px;
    }
    button {
      padding: 8px 16px;
    }
  </style>
</head>
<body>
  <h1>WebSocketエコーテスト</h1>
  
  <div id="status">接続中...</div>
  <div id="messages"></div>
  
  <input type="text" id="input" placeholder="メッセージを入力">
  <button id="send">送信</button>
  
  <script>
    const ws = new WebSocket('ws://localhost:3000/ws');
    const messagesDiv = document.getElementById('messages');
    const statusDiv = document.getElementById('status');
    const inputField = document.getElementById('input');
    const sendButton = document.getElementById('send');
    
    ws.onopen = () => {
      statusDiv.textContent = '接続成功';
      statusDiv.style.color = 'green';
    };
    
    ws.onmessage = (event) => {
      addMessage(event.data, 'received');
    };
    
    ws.onerror = () => {
      statusDiv.textContent = 'エラー発生';
      statusDiv.style.color = 'red';
    };
    
    ws.onclose = () => {
      statusDiv.textContent = '接続終了';
      statusDiv.style.color = 'orange';
    };
    
    sendButton.addEventListener('click', sendMessage);
    inputField.addEventListener('keypress', (e) => {
      if (e.key === 'Enter') sendMessage();
    });
    
    function sendMessage() {
      const message = inputField.value.trim();
      if (message && ws.readyState === WebSocket.OPEN) {
        ws.send(message);
        addMessage(message, 'sent');
        inputField.value = '';
      }
    }
    
    function addMessage(text, className) {
      const div = document.createElement('div');
      div.className = 'message ' + className;
      div.textContent = text;
      messagesDiv.appendChild(div);
      messagesDiv.scrollTop = messagesDiv.scrollHeight;
    }
  </script>
</body>
</html>
```

### 動作確認

サーバーを起動して：

```bash
perl echo_server.pl daemon
```

ブラウザで `http://localhost:3000/echo.html` を開きます。メッセージを入力して送信ボタンを押すと、サーバーからエコーバックされたメッセージが表示されます。

青色が送信、緑色が受信です。自分が送ったメッセージがそのまま返ってくることを確認できます！

## Step 3: リアルタイムチャットを作る

いよいよ本格的なアプリケーションです。複数のクライアントが同時に接続し、メッセージをやり取りできるチャットを実装しましょう。

### 複数クライアントの管理

すべての接続を管理するために、配列でクライアントを保持します。

### ブロードキャスト機能

あるクライアントから受け取ったメッセージを、接続中のすべてのクライアントに送信します。これが「ブロードキャスト」です。

### 入退室通知

誰かが接続・切断したときに、他のユーザーにも通知します。

### 完全なコード

`chat_server.pl` を作成します：

```perl
#!/usr/bin/env perl
use Mojolicious::Lite -signatures;
use utf8;

# 接続中のクライアントを管理
my @clients = ();

# メッセージをすべてのクライアントに送信
sub broadcast ($message) {
  $_->send($message) for @clients;
}

websocket '/chat' => sub ($c) {
  my $id = sprintf "%s:%d", $c->tx->remote_address, int(rand(10000));
  
  $c->app->log->info("[$id] 接続");
  
  # クライアントリストに追加
  push @clients, $c;
  
  # 入室通知
  broadcast("System: $id が入室しました（現在 " . scalar(@clients) . " 人）");
  
  # メッセージ受信
  $c->on(message => sub ($c, $msg) {
    $c->app->log->info("[$id] $msg");
    broadcast("$id: $msg");
  });
  
  # 切断時
  $c->on(finish => sub ($c, $code, $reason) {
    $c->app->log->info("[$id] 切断");
    
    # クライアントリストから削除
    @clients = grep { $_ ne $c } @clients;
    
    # 退室通知
    broadcast("System: $id が退室しました（現在 " . scalar(@clients) . " 人）");
  });
};

app->start;
```

クライアント側のHTML（`public/chat.html`）：

```html
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>WebSocketチャット</title>
  <style>
    * {
      margin: 0;
      padding: 0;
      box-sizing: border-box;
    }
    body {
      font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
      background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
      height: 100vh;
      display: flex;
      justify-content: center;
      align-items: center;
    }
    .container {
      background: white;
      width: 90%;
      max-width: 600px;
      height: 80vh;
      border-radius: 12px;
      box-shadow: 0 10px 40px rgba(0,0,0,0.3);
      display: flex;
      flex-direction: column;
      overflow: hidden;
    }
    .header {
      background: #667eea;
      color: white;
      padding: 20px;
      text-align: center;
    }
    .header h1 {
      font-size: 24px;
      margin-bottom: 5px;
    }
    #status {
      font-size: 14px;
      opacity: 0.9;
    }
    #messages {
      flex: 1;
      overflow-y: auto;
      padding: 20px;
      background: #f5f5f5;
    }
    .message {
      margin-bottom: 12px;
      padding: 10px 14px;
      border-radius: 8px;
      max-width: 80%;
      word-wrap: break-word;
    }
    .user-message {
      background: white;
      border-left: 4px solid #667eea;
    }
    .system-message {
      background: #fff3cd;
      border-left: 4px solid #ffc107;
      font-style: italic;
      color: #856404;
    }
    .input-area {
      display: flex;
      padding: 15px;
      background: white;
      border-top: 1px solid #ddd;
    }
    #input {
      flex: 1;
      padding: 12px;
      border: 2px solid #667eea;
      border-radius: 6px;
      font-size: 14px;
      outline: none;
    }
    #input:focus {
      border-color: #764ba2;
    }
    #send {
      margin-left: 10px;
      padding: 12px 24px;
      background: #667eea;
      color: white;
      border: none;
      border-radius: 6px;
      font-size: 14px;
      cursor: pointer;
      transition: background 0.3s;
    }
    #send:hover {
      background: #764ba2;
    }
    #send:disabled {
      background: #ccc;
      cursor: not-allowed;
    }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>リアルタイムチャット</h1>
      <div id="status">接続中...</div>
    </div>
    
    <div id="messages"></div>
    
    <div class="input-area">
      <input type="text" id="input" placeholder="メッセージを入力..." disabled>
      <button id="send" disabled>送信</button>
    </div>
  </div>
  
  <script>
    const ws = new WebSocket('ws://localhost:3000/chat');
    const messagesDiv = document.getElementById('messages');
    const statusDiv = document.getElementById('status');
    const inputField = document.getElementById('input');
    const sendButton = document.getElementById('send');
    
    ws.onopen = () => {
      statusDiv.textContent = '接続完了 - チャットを楽しもう！';
      inputField.disabled = false;
      sendButton.disabled = false;
      inputField.focus();
    };
    
    ws.onmessage = (event) => {
      const message = event.data;
      const isSystem = message.startsWith('System:');
      addMessage(message, isSystem ? 'system-message' : 'user-message');
    };
    
    ws.onerror = () => {
      statusDiv.textContent = 'エラーが発生しました';
      statusDiv.style.background = '#dc3545';
    };
    
    ws.onclose = () => {
      statusDiv.textContent = '接続が切断されました';
      statusDiv.style.background = '#ffc107';
      inputField.disabled = true;
      sendButton.disabled = true;
    };
    
    sendButton.addEventListener('click', sendMessage);
    inputField.addEventListener('keypress', (e) => {
      if (e.key === 'Enter') sendMessage();
    });
    
    function sendMessage() {
      const message = inputField.value.trim();
      if (message && ws.readyState === WebSocket.OPEN) {
        ws.send(message);
        inputField.value = '';
        inputField.focus();
      }
    }
    
    function addMessage(text, className) {
      const div = document.createElement('div');
      div.className = 'message ' + className;
      div.textContent = text;
      messagesDiv.appendChild(div);
      messagesDiv.scrollTop = messagesDiv.scrollHeight;
    }
  </script>
</body>
</html>
```

### 動作確認

サーバーを起動：

```bash
perl chat_server.pl daemon
```

複数のブラウザタブやウィンドウで `http://localhost:3000/chat.html` を開いてください。どのタブで送信したメッセージも、すべてのタブにリアルタイムで表示されます。

タブを閉じると「退室しました」というシステムメッセージが他のタブに表示されます。これが本物のリアルタイムチャットです！

## 実装のポイント

### UTF-8と日本語の扱い

Perlで日本語を扱う際は、必ずファイルの先頭に `use utf8;` を記述してください。これでソースコード内の文字列がUTF-8として解釈されます。

Mojoliciousは内部的にUTF-8を正しくハンドリングしてくれるため、特別な処理は不要です。

### エラーハンドリング

本番環境では、以下のようなエラーハンドリングを追加しましょう：

```perl
$c->on(message => sub ($c, $msg) {
  eval {
    # メッセージ処理
    broadcast($msg);
  };
  if ($@) {
    $c->app->log->error("エラー: $@");
    $c->send({json => {error => 'メッセージ処理に失敗しました'}});
  }
});
```

### セキュリティ考慮事項

WebSocketを本番環境で使う際は、以下の点に注意してください：

1. **WSS（WebSocket Secure）を使う**: 本番環境では必ず `wss://` を使い、TLS/SSL暗号化を有効にしましょう。

2. **Origin検証**: 接続元のOriginを検証して、許可されたドメインからのみ接続を受け付けます。

```perl
websocket '/chat' => sub ($c) {
  my $origin = $c->req->headers->origin // '';
  unless ($origin =~ /^https:\/\/(www\.)?example\.com$/) {
    return $c->render(text => 'Forbidden', status => 403);
  }
  # 以降の処理...
};
```

3. **認証・認可**: セッションやトークンを使って、認証済みユーザーのみが接続できるようにします。

4. **レート制限**: メッセージの送信頻度を制限し、スパム対策を実施します。

5. **入力検証**: クライアントから受け取ったデータは必ず検証し、サニタイズします。

## よくある質問とトラブルシューティング

**Q: 接続が頻繁に切れてしまいます**

A: プロキシやロードバランサーがタイムアウトを設定している可能性があります。定期的にPingフレームを送ることで接続を維持できます：

```perl
# 30秒ごとにping送信
$c->on(message => sub ($c, $msg) {
  $c->inactivity_timeout(300);  # 5分のタイムアウト
  # メッセージ処理
});
```

**Q: ブラウザで「WebSocket connection failed」と表示されます**

A: 以下を確認してください：
- サーバーが起動しているか
- URLが正しいか（`ws://` か `wss://`）
- ポート番号が正しいか
- ファイアウォールが通信をブロックしていないか

**Q: メモリリークが心配です**

A: `@clients` 配列から切断済みの接続を確実に削除することが重要です。`finish` イベントで必ずクリーンアップを実行しましょう。

**Q: 複数サーバーでスケールさせたい**

A: 単一サーバーの場合、接続はそのサーバー内でしか共有されません。複数サーバーでスケールする場合は、RedisのPub/Subなどを使ってサーバー間でメッセージを中継する必要があります。

## まとめと次のステップ

この記事では、WebSocketの基本から実装まで、段階的に学びました：

1. **WebSocketの仕組み**: HTTPからのアップグレードと双方向通信
2. **最小のサーバー**: 接続確立とメッセージ送信
3. **エコーサーバー**: メッセージの受信と返信
4. **リアルタイムチャット**: 複数クライアントのブロードキャスト

Mojoliciousを使えば、わずか数十行でリアルタイム通信が実現できることを体験していただけたと思います。

### 次に学ぶべきこと

- **JSON形式のメッセージ**: 構造化データのやり取り
- **バイナリデータ**: 画像やファイルの送受信
- **認証と認可**: セキュアな接続の実装
- **スケーラビリティ**: Redis Pub/Subを使った複数サーバー構成
- **フレームワーク**: Socket.ioなどの高レベルライブラリの活用

WebSocketは、現代のWebアプリケーションに欠かせない技術です。ぜひこの記事をきっかけに、リアルタイム通信の世界を楽しんでください！

### 参考リンク

{{< linkcard "https://mojolicious.org/" >}}

{{< linkcard "https://datatracker.ietf.org/doc/html/rfc6455" >}}

{{< linkcard "https://developer.mozilla.org/ja/docs/Web/API/WebSocket" >}}
