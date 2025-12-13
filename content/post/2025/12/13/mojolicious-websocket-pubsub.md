---
date: 2025-12-13T03:16:00+09:00
description: Perl の Mojolicious フレームワークを使って WebSocket と Pub/Sub パターンを実装する入門記事です。基本的なチャットアプリの実装を通じて、リアルタイム通信の仕組みを学びます。
draft: true
epoch: 1734055560
hidden: false
image: /favicon.png
iso8601: 2025-12-13T03:16:00+09:00
license: ~
math: ~
tags:
  - perl
  - mojolicious
  - websocket
  - pub-sub
  - real-time
title: Mojoliciousで書くWebSocket入門

---

[@nqounet](https://x.com/nqounet)です。

リアルタイムな双方向通信を実現するWebSocketと、その上で動作するPub/Subパターンについて、Perlの人気フレームワーク「Mojolicious」を使って解説します。チャットアプリの実装を通じて、これらの技術を実践的に学んでいきましょう。

## WebSocketとは何か

WebSocketは、クライアントとサーバー間で**双方向のリアルタイム通信**を可能にするプロトコルです。従来のHTTP通信との違いを理解することが、WebSocketを活用する第一歩です。

### 従来のHTTP通信の課題

通常のHTTPでは、クライアント（ブラウザ）からリクエストを送って初めて、サーバーがレスポンスを返します。サーバー側から能動的にデータを送ることはできません。

```
クライアント → [リクエスト] → サーバー
クライアント ← [レスポンス] ← サーバー
```

チャットアプリのように「他のユーザーが投稿したメッセージをリアルタイムで受け取りたい」場合、従来は以下のような方法が使われていました：

- **ポーリング**: 定期的にサーバーへリクエストを送り、新しいデータがあるか確認する
- **ロングポーリング**: リクエストを送り、サーバー側で新しいデータが来るまで待機してからレスポンスを返す

これらの方法は、無駄な通信が多かったり、実装が複雑になったりといった問題がありました。

### WebSocketの特徴

WebSocketでは、最初にHTTPで接続を確立した後、そのコネクションを**WebSocketプロトコルにアップグレード**します。一度接続が確立されると：

- クライアントからサーバーへ、いつでもメッセージを送れる
- サーバーからクライアントへ、いつでもメッセージを送れる
- 接続は維持され続けるため、オーバーヘッドが少ない

```
クライアント ←→ [双方向通信] ←→ サーバー
```

これにより、リアルタイムなチャット、オンラインゲーム、株価表示、協調編集ツールなど、様々なアプリケーションが実現できます。

## Pub/Subパターンの説明

WebSocketで複数のクライアント間でメッセージをやり取りする際に活躍するのが、**Pub/Sub（Publish/Subscribe）パターン**です。

### Pub/Subの基本概念

Pub/Subは、メッセージの**送信者（Publisher）**と**受信者（Subscriber）**を疎結合にするデザインパターンです。

- **Publisher（発行者）**: メッセージを特定の「トピック」や「チャンネル」に発行する
- **Subscriber（購読者）**: 興味のあるトピックやチャンネルを購読し、メッセージを受け取る
- **Broker（仲介者）**: PublisherとSubscriberの間でメッセージを仲介する

```
Publisher → [メッセージ] → Broker → [配信] → Subscriber A
                                   → [配信] → Subscriber B
                                   → [配信] → Subscriber C
```

### チャットアプリでの具体例

例えば、チャットアプリでは：

1. ユーザーAが「general」チャンネルに参加（Subscribe）
2. ユーザーBも「general」チャンネルに参加（Subscribe）
3. ユーザーAがメッセージを投稿（Publish）
4. Brokerが「general」チャンネルを購読している全ユーザー（A, B）にメッセージを配信

このパターンの利点は：

- **疎結合**: Publisherは誰が受信するか知る必要がない
- **スケーラビリティ**: 新しいSubscriberを追加しても既存のコードを変更する必要がない
- **柔軟性**: ユーザーは興味のあるチャンネルだけを購読できる

## Mojoliciousの紹介

Mojoliciousは、Perlで書かれた**フルスタックWebフレームワーク**です。WebSocketのサポートが標準で組み込まれており、リアルタイムWebアプリケーションの開発に最適です。

### Mojoliciousの特徴

- **軽量**: 依存モジュールが少なく、インストールが簡単
- **非同期対応**: イベント駆動の非同期I/Oをサポート
- **WebSocket標準サポート**: 追加モジュール不要でWebSocketを使える
- **Mojolicious::Lite**: 小規模アプリ向けの簡潔な記法

### インストール

cpanmを使ってインストールできます：

```bash
cpanm Mojolicious
```

または、システムのパッケージマネージャーを使うこともできます：

```bash
# Debian/Ubuntu
apt-get install libmojolicious-perl

# macOS (Homebrew)
brew install perl
cpanm Mojolicious
```

## 簡単なWebSocketサンプル

まずは、基本的なWebSocket通信を実装してみましょう。Mojolicious::Liteを使えば、驚くほど簡潔に書けます。

### エコーサーバーの実装

クライアントから受け取ったメッセージをそのまま返す、シンプルなエコーサーバーです。

```perl
#!/usr/bin/env perl
use Mojolicious::Lite -signatures;

# WebSocketルートの定義
websocket '/echo' => sub ($c) {
  # 接続確立時のログ
  $c->app->log->debug('WebSocket connection opened');
  
  # メッセージ受信時の処理
  $c->on(message => sub ($c, $msg) {
    $c->app->log->debug("Received: $msg");
    $c->send("Echo: $msg");  # メッセージをそのまま返す
  });
  
  # 接続終了時の処理
  $c->on(finish => sub ($c, $code, $reason) {
    $c->app->log->debug("WebSocket connection closed: $code");
  });
};

# HTMLページの提供
get '/' => sub ($c) {
  $c->render(inline => <<'HTML');
<!DOCTYPE html>
<html>
<head>
  <title>WebSocket Echo Demo</title>
  <meta charset="UTF-8">
</head>
<body>
  <h1>WebSocket Echo Demo</h1>
  <input type="text" id="message" placeholder="メッセージを入力">
  <button onclick="sendMessage()">送信</button>
  <div id="output"></div>
  
  <script>
    const ws = new WebSocket('ws://localhost:3000/echo');
    const output = document.getElementById('output');
    
    ws.onopen = () => {
      output.innerHTML += '<p>接続しました</p>';
    };
    
    ws.onmessage = (event) => {
      output.innerHTML += '<p>受信: ' + event.data + '</p>';
    };
    
    ws.onclose = () => {
      output.innerHTML += '<p>切断しました</p>';
    };
    
    function sendMessage() {
      const msg = document.getElementById('message').value;
      ws.send(msg);
      output.innerHTML += '<p>送信: ' + msg + '</p>';
      document.getElementById('message').value = '';
    }
  </script>
</body>
</html>
HTML
};

app->start;
```

### 実行方法

ファイルを`echo.pl`として保存し、実行します：

```bash
chmod +x echo.pl
./echo.pl daemon
```

ブラウザで`http://localhost:3000/`にアクセスすると、WebSocketエコーアプリが動作します。

### コードの解説

- `websocket '/echo' => sub { ... }`: WebSocketエンドポイントの定義
- `$c->on(message => ...)`: メッセージ受信時のコールバック
- `$c->send(...)`: クライアントへメッセージを送信
- `$c->on(finish => ...)`: 接続終了時のコールバック

クライアント側（JavaScript）では：

- `new WebSocket('ws://...')`: WebSocket接続の確立
- `ws.send(...)`: サーバーへメッセージ送信
- `ws.onmessage`: サーバーからのメッセージ受信

## Pub/Subを使ったチャットアプリの実装

それでは、Pub/Subパターンを使った本格的なチャットアプリを実装しましょう。

### チャットアプリの完全実装

```perl
#!/usr/bin/env perl
use Mojolicious::Lite -signatures;
use Mojo::JSON qw(decode_json encode_json);

# 接続中のクライアントを管理するハッシュ
my %clients;

# WebSocketエンドポイント
websocket '/chat' => sub ($c) {
  my $id = sprintf '%s', $c->tx;  # 接続ごとのユニークID
  
  # クライアントを登録
  $clients{$id} = $c->tx;
  $c->app->log->info("Client $id connected. Total clients: " . scalar(keys %clients));
  
  # 参加通知をブロードキャスト
  broadcast({
    type => 'join',
    id   => $id,
    count => scalar(keys %clients),
    timestamp => time,
  });
  
  # メッセージ受信時の処理
  $c->on(message => sub ($c, $msg) {
    my $data;
    eval { $data = decode_json($msg) };
    if ($@) {
      $c->app->log->error("Invalid JSON: $@");
      return;
    }
    
    # メッセージの種類に応じて処理
    if ($data->{type} eq 'message') {
      # チャットメッセージをブロードキャスト
      broadcast({
        type => 'message',
        id   => $id,
        text => $data->{text},
        timestamp => time,
      });
    }
  });
  
  # 接続終了時の処理
  $c->on(finish => sub ($c, $code, $reason) {
    delete $clients{$id};
    $c->app->log->info("Client $id disconnected. Total clients: " . scalar(keys %clients));
    
    # 退出通知をブロードキャスト
    broadcast({
      type => 'leave',
      id   => $id,
      count => scalar(keys %clients),
      timestamp => time,
    });
  });
};

# 全クライアントにメッセージをブロードキャストする関数
sub broadcast {
  my $msg = shift;
  my $json = encode_json($msg);
  
  for my $tx (values %clients) {
    $tx->send($json);
  }
}

# チャット画面を提供
get '/' => sub ($c) {
  $c->render(inline => <<'HTML');
<!DOCTYPE html>
<html>
<head>
  <title>Mojolicious Chat</title>
  <meta charset="UTF-8">
  <style>
    body {
      font-family: Arial, sans-serif;
      max-width: 800px;
      margin: 50px auto;
      padding: 20px;
    }
    #messages {
      border: 1px solid #ccc;
      height: 400px;
      overflow-y: scroll;
      padding: 10px;
      margin-bottom: 10px;
      background: #f9f9f9;
    }
    .message {
      margin: 5px 0;
      padding: 8px;
      border-radius: 4px;
      background: white;
    }
    .system {
      background: #e3f2fd;
      color: #1976d2;
      font-style: italic;
    }
    #input-area {
      display: flex;
      gap: 10px;
    }
    #message-input {
      flex: 1;
      padding: 10px;
      font-size: 16px;
      border: 1px solid #ccc;
      border-radius: 4px;
    }
    #send-button {
      padding: 10px 20px;
      font-size: 16px;
      background: #4CAF50;
      color: white;
      border: none;
      border-radius: 4px;
      cursor: pointer;
    }
    #send-button:hover {
      background: #45a049;
    }
    #status {
      margin-bottom: 10px;
      padding: 10px;
      border-radius: 4px;
      text-align: center;
    }
    .connected { background: #c8e6c9; color: #2e7d32; }
    .disconnected { background: #ffcdd2; color: #c62828; }
  </style>
</head>
<body>
  <h1>Mojolicious WebSocket Chat</h1>
  <div id="status" class="disconnected">接続中...</div>
  <div id="messages"></div>
  <div id="input-area">
    <input type="text" id="message-input" placeholder="メッセージを入力" disabled>
    <button id="send-button" onclick="sendMessage()" disabled>送信</button>
  </div>
  
  <script>
    const messagesDiv = document.getElementById('messages');
    const statusDiv = document.getElementById('status');
    const messageInput = document.getElementById('message-input');
    const sendButton = document.getElementById('send-button');
    
    // WebSocket接続
    const ws = new WebSocket('ws://' + location.host + '/chat');
    
    ws.onopen = () => {
      statusDiv.textContent = '接続しました';
      statusDiv.className = 'connected';
      messageInput.disabled = false;
      sendButton.disabled = false;
      messageInput.focus();
    };
    
    ws.onmessage = (event) => {
      const data = JSON.parse(event.data);
      const msgDiv = document.createElement('div');
      msgDiv.className = 'message';
      
      const time = new Date(data.timestamp * 1000).toLocaleTimeString();
      
      if (data.type === 'message') {
        msgDiv.textContent = `[${time}] ${data.id}: ${data.text}`;
      } else if (data.type === 'join') {
        msgDiv.className = 'message system';
        msgDiv.textContent = `[${time}] ${data.id} が参加しました（接続数: ${data.count}）`;
      } else if (data.type === 'leave') {
        msgDiv.className = 'message system';
        msgDiv.textContent = `[${time}] ${data.id} が退出しました（接続数: ${data.count}）`;
      }
      
      messagesDiv.appendChild(msgDiv);
      messagesDiv.scrollTop = messagesDiv.scrollHeight;
    };
    
    ws.onclose = () => {
      statusDiv.textContent = '切断されました';
      statusDiv.className = 'disconnected';
      messageInput.disabled = true;
      sendButton.disabled = true;
    };
    
    ws.onerror = (error) => {
      console.error('WebSocket error:', error);
    };
    
    function sendMessage() {
      const text = messageInput.value.trim();
      if (!text) return;
      
      ws.send(JSON.stringify({
        type: 'message',
        text: text
      }));
      
      messageInput.value = '';
      messageInput.focus();
    }
    
    // Enterキーで送信
    messageInput.addEventListener('keypress', (e) => {
      if (e.key === 'Enter') {
        sendMessage();
      }
    });
  </script>
</body>
</html>
HTML
};

app->start;
```

### 実行とテスト

ファイルを`chat.pl`として保存し、実行します：

```bash
chmod +x chat.pl
./chat.pl daemon
```

複数のブラウザタブで`http://localhost:3000/`を開くと、タブ間でメッセージがリアルタイムに共有されることを確認できます。

### Pub/Subの実装ポイント

このチャットアプリでは、以下のようにPub/Subパターンを実装しています：

1. **Subscribe（購読）**: WebSocket接続時に`%clients`ハッシュへクライアントを登録
2. **Publish（発行）**: メッセージ受信時に`broadcast()`関数を呼び出し
3. **Broker（仲介）**: `broadcast()`関数が全購読者にメッセージを配信
4. **Unsubscribe（購読解除）**: 接続終了時に`%clients`から削除

```perl
# Subscribe: クライアントを登録
$clients{$id} = $c->tx;

# Publish: メッセージを発行
broadcast({ type => 'message', text => $data->{text} });

# Broker: 全クライアントに配信
sub broadcast {
  my $msg = shift;
  my $json = encode_json($msg);
  for my $tx (values %clients) {
    $tx->send($json);
  }
}

# Unsubscribe: クライアントを削除
delete $clients{$id};
```

## 応用例・注意点

### チャンネル機能の追加

実際のチャットアプリでは、複数のチャンネル（部屋）を持つことが一般的です。これもPub/Subパターンで簡単に実装できます：

```perl
my %channels;  # { channel_name => { client_id => $tx } }

websocket '/chat' => sub ($c) {
  my $id = sprintf '%s', $c->tx;
  
  $c->on(message => sub ($c, $msg) {
    my $data = decode_json($msg);
    
    if ($data->{type} eq 'join_channel') {
      # チャンネルに参加（Subscribe）
      $channels{$data->{channel}}{$id} = $c->tx;
    }
    elsif ($data->{type} eq 'leave_channel') {
      # チャンネルから退出（Unsubscribe）
      delete $channels{$data->{channel}}{$id};
    }
    elsif ($data->{type} eq 'message') {
      # 特定チャンネルへメッセージ送信（Publish）
      broadcast_to_channel($data->{channel}, {
        type => 'message',
        text => $data->{text},
        id   => $id,
      });
    }
  });
};

sub broadcast_to_channel {
  my ($channel, $msg) = @_;
  my $json = encode_json($msg);
  
  # 指定チャンネルの購読者だけに配信
  for my $tx (values %{$channels{$channel} // {}}) {
    $tx->send($json);
  }
}
```

### セキュリティとパフォーマンスの注意点

WebSocketアプリを本番環境で運用する際の重要なポイント：

#### 認証・認可

WebSocket接続でも、適切な認証が必要です：

```perl
websocket '/chat' => sub ($c) {
  # セッションチェック
  unless ($c->session('user_id')) {
    $c->render(text => 'Unauthorized', status => 401);
    return;
  }
  
  my $user_id = $c->session('user_id');
  # ... 以降の処理
};
```

#### メッセージサイズの制限

大量データの送信を防ぐため、メッセージサイズを制限します：

```perl
# 最大メッセージサイズを設定（デフォルトは2^20バイト）
$c->on(message => sub ($c, $msg) {
  if (length($msg) > 1024) {  # 1KB制限
    $c->finish(1008, 'Message too large');
    return;
  }
  # ... 処理
});
```

#### レート制限

メッセージの送信頻度を制限し、スパムを防ぎます：

```perl
my %rate_limit;  # { client_id => [ timestamps ] }

$c->on(message => sub ($c, $msg) {
  my $id = sprintf '%s', $c->tx;
  my $now = time;
  
  # 直近10秒間の送信履歴を保持
  $rate_limit{$id} = [
    grep { $_ > $now - 10 } @{$rate_limit{$id} // []}
  ];
  
  # 10秒間に5回以上送信していたら拒否
  if (@{$rate_limit{$id}} >= 5) {
    $c->send(encode_json({ error => 'Rate limit exceeded' }));
    return;
  }
  
  push @{$rate_limit{$id}}, $now;
  # ... 処理
});
```

#### エラーハンドリング

接続エラーやメッセージのパースエラーを適切に処理します：

```perl
$c->on(message => sub ($c, $msg) {
  my $data;
  eval {
    $data = decode_json($msg);
  };
  if ($@) {
    $c->send(encode_json({ error => 'Invalid JSON format' }));
    return;
  }
  
  # データのバリデーション
  unless ($data->{type} && $data->{text}) {
    $c->send(encode_json({ error => 'Missing required fields' }));
    return;
  }
  
  # ... 処理
});
```

#### スケーリング

単一サーバーでは限界があります。複数サーバーでスケールする場合は、RedisなどのPub/Subブローカーを使用します：

```perl
use Mojo::Redis;

my $redis = Mojo::Redis->new('redis://localhost:6379');
my $pubsub = $redis->pubsub;

# Redisチャンネルを購読
$pubsub->listen('chat' => sub {
  my ($pubsub, $message) = @_;
  # 全WebSocketクライアントへブロードキャスト
  broadcast(decode_json($message));
});

# メッセージをRedisに発行
$c->on(message => sub ($c, $msg) {
  $redis->publish('chat', $msg);
});
```

この構成により、複数のMojoliciousサーバー間でメッセージを共有できます。

### デバッグとモニタリング

WebSocketアプリのデバッグには、以下のテクニックが役立ちます：

```perl
# 詳細なログ出力
$c->app->log->level('debug');

# WebSocket接続の状態を確認
$c->on(message => sub ($c, $msg) {
  $c->app->log->debug("State: " . $c->tx->is_websocket);
  $c->app->log->debug("Message: $msg");
});

# 接続数のモニタリング
get '/stats' => sub ($c) {
  $c->render(json => {
    active_connections => scalar(keys %clients),
    uptime => time - $^T,
  });
};
```

ブラウザの開発者ツールでもWebSocket通信を確認できます：

- Chromeの場合: DevTools → Network → WS（WebSocket）タブ
- メッセージの送受信履歴、ペイロード、タイムスタンプなどが確認可能

## まとめ

この記事では、WebSocketとPub/Subパターンについて、Mojoliciousを使った実装を通じて学びました。

### 重要なポイント

- **WebSocket**は、サーバーとクライアント間の双方向リアルタイム通信を実現するプロトコル
- **Pub/Subパターン**は、メッセージの送信者と受信者を疎結合にし、スケーラブルなアプリケーションを構築できる
- **Mojolicious**は、WebSocketのサポートが標準で組み込まれており、簡潔に実装できる
- 本番環境では、認証・認可、レート制限、エラーハンドリング、スケーリング戦略が重要

### 次のステップ

基本を理解したら、以下のような拡張にチャレンジしてみましょう：

- プライベートメッセージ機能の実装
- ユーザー名や絵文字のサポート
- メッセージの永続化（データベース保存）
- Redisを使ったマルチサーバー対応
- リアクション機能や既読機能の追加

WebSocketとPub/Subパターンは、現代のWebアプリケーション開発における重要な技術です。Mojoliciousを使えば、これらを簡単に実装できるので、ぜひ実際にアプリケーションを作ってみてください。

Happy coding!
