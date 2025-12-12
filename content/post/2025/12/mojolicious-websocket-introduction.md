---
title: "Mojoliciousで書くWebSocket入門"
draft: true
tags:
  - perl
  - mojolicious
  - websocket
  - event-driven
  - real-time
description: "イベント駆動プログラミングとサーバープッシュの仕組みを、実際に動くシンプルなチャットアプリケーションを通じて理解する"
---

<a href="https://x.com/nqounet">@nqounet</a>です。

MojoliciousはPerlの基本的なモジュールだけで動作するようになっている、全部込みのウェブフレームワークです。
モダンな環境であれば、CPANを使ってモジュールをインストールすることは特に問題ないと思いますが、特別な環境でCPANが使えないような環境でウェブアプリケーションを開発するのであれば、Mojoliciousがあれば、かなり楽になるでしょう。
なんと、WebSocketにも対応しています。

## はじめに

現代のWebアプリケーションでは、リアルタイム性がますます重要になっています。チャット、コラボレーションツール、ゲーム、ダッシュボード、株価情報など、サーバーからクライアントへの即座な情報更新が求められる場面は数多くあります。

Mojoliciousは「全部込み（full stack）」のウェブフレームワークです。これは単に多機能というだけでなく、外部依存が最小限で、WebSocketのようなモダンな機能も標準で利用できることを意味します。特別なCPANモジュールを追加することなく、リアルタイムWebアプリケーションを構築できるのです。

この記事では、WebSocketの基礎から実際のチャットアプリケーションの実装まで、段階的に学んでいきます。

## なぜWebSocketなのか

### HTTPの限界

従来のHTTPは、クライアントがリクエストを送信し、サーバーがレスポンスを返すという「リクエスト/レスポンス」モデルです。この仕組みには以下の制約があります：

- **サーバーからの能動的な通信ができない**: サーバーは、クライアントからのリクエストがない限り、データを送信できません
- **毎回接続が必要**: リクエストごとに接続の確立とヘッダーの送信が必要で、オーバーヘッドが大きい
- **リアルタイム性に欠ける**: 新しい情報を取得するには、クライアントが定期的にリクエストを送る必要がある

### ポーリングとロングポーリングの問題点

リアルタイム性を実現するために、以下の手法が使われてきました：

**ポーリング**: クライアントが一定間隔でサーバーにリクエストを送る方法です。

```javascript
// ポーリングの例（非効率）
setInterval(() => {
  fetch('/api/messages')
    .then(res => res.json())
    .then(data => updateUI(data));
}, 1000); // 1秒ごとにリクエスト
```

問題点：
- 更新がない場合でもリクエストが発生する（無駄なトラフィック）
- リアルタイム性が低い（間隔に依存）
- サーバー負荷が高い

**ロングポーリング**: サーバーが新しいデータができるまでレスポンスを保留する方法です。

問題点：
- 接続が長時間保持されるため、サーバーリソースを消費する
- タイムアウト処理が複雑
- 依然として毎回接続の再確立が必要

### WebSocketが解決する課題

WebSocketは、これらの問題を根本的に解決します：

1. **双方向通信**: クライアントとサーバーの両方が、いつでも自由にメッセージを送信できます
2. **永続的な接続**: 一度確立した接続を維持し続けるため、オーバーヘッドが最小限です
3. **低レイテンシ**: サーバープッシュにより、データが発生した瞬間に送信できます
4. **効率的**: HTTPヘッダーの代わりに軽量なフレームを使用します

### WebSocketプロトコルの仕組み

WebSocket接続は、HTTPからのアップグレードとして確立されます：

1. **ハンドシェイク**: クライアントがHTTPリクエストで接続をアップグレード要求
```http
GET /chat HTTP/1.1
Host: server.example.com
Upgrade: websocket
Connection: Upgrade
Sec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==
Sec-WebSocket-Version: 13
```

2. **サーバーの応答**: アップグレードを承認
```http
HTTP/1.1 101 Switching Protocols
Upgrade: websocket
Connection: Upgrade
Sec-WebSocket-Accept: s3pPLMBiTxaQ9kYGzzhZRbK+xOo=
```

3. **データフレーム**: 接続確立後は、軽量なバイナリフレームでメッセージをやり取りします

Mojoliciousは、このハンドシェイクやフレームの処理を自動的に行ってくれるため、開発者はメッセージの送受信に集中できます。

## イベント駆動プログラミングとは

### 従来の同期処理との違い

従来のブロッキング処理では、処理が完了するまで次の処理に進めません：

```perl
# ブロッキング処理の例
my $data1 = fetch_data_from_api();  # 完了するまで待機
my $data2 = fetch_data_from_db();   # data1の取得後に実行
process($data1, $data2);
```

イベント駆動（ノンブロッキング）処理では、処理の完了を待たずに次の処理を実行できます：

```perl
# ノンブロッキング処理の例
fetch_data_from_api(sub {
  my $data1 = shift;
  # data1が取得できたら実行される
});
fetch_data_from_db(sub {
  my $data2 = shift;
  # data2が取得できたら実行される
});
# 両方の処理を待たずに次に進める
```

### コールバックの概念

コールバックは、「処理が完了したら実行する関数」を渡す仕組みです：

```perl
use Mojo::UserAgent;

my $ua = Mojo::UserAgent->new;

# 非同期でHTTPリクエストを送信
$ua->get('https://api.example.com/data' => sub {
  my ($ua, $tx) = @_;
  
  # レスポンスが返ってきたときに実行される
  if (my $err = $tx->error) {
    warn "エラー: $err->{message}";
  } else {
    my $data = $tx->result->json;
    say "データ取得完了: ", $data->{message};
  }
});

say "リクエスト送信後、すぐに表示される";
```

このコードでは、HTTPリクエストの完了を待たずに、次の行（`say "リクエスト送信後..."`）が実行されます。

### Mojoliciousのイベントループ

Mojoliciousは`Mojo::IOLoop`というイベントループを持っています。これが、非同期処理を管理する中核です：

```perl
use Mojo::IOLoop;

# タイマー：3秒後に実行
Mojo::IOLoop->timer(3 => sub {
  say "3秒経過しました";
});

# 繰り返しタイマー：1秒ごとに実行
my $count = 0;
my $id = Mojo::IOLoop->recurring(1 => sub {
  say "カウント: ", ++$count;
  
  # 5回で停止
  Mojo::IOLoop->remove($id) if $count >= 5;
});

say "イベントループ開始";

# イベントループを開始（スクリプトとして実行する場合）
Mojo::IOLoop->start unless Mojo::IOLoop->is_running;
```

実行結果：
```
イベントループ開始
カウント: 1
カウント: 2
カウント: 3
3秒経過しました
カウント: 4
カウント: 5
```

### 実例：非同期処理の実践

複数のAPIから並行してデータを取得する例：

```perl
use Mojo::UserAgent;
use Mojo::IOLoop;

my $ua = Mojo::UserAgent->new;
my @results;

# 3つのAPIに同時にリクエスト
for my $id (1..3) {
  $ua->get("https://jsonplaceholder.typicode.com/posts/$id" => sub {
    my ($ua, $tx) = @_;
    
    if ($tx->success) {
      my $data = $tx->result->json;
      push @results, $data->{title};
      say "取得完了 ($id): $data->{title}";
    }
    
    # 3つすべて完了したらループを停止
    Mojo::IOLoop->stop if @results == 3;
  });
}

say "3つのリクエストを送信しました";

# 結果を待つ
Mojo::IOLoop->start unless Mojo::IOLoop->is_running;

say "\n全結果:";
say "- $_" for @results;
```

このように、イベント駆動プログラミングにより、複数の処理を効率的に並行実行できます。WebSocketも、このイベント駆動の仕組みの上で動作します。

## ハンズオン：エコーサーバーを作る

まずは、最もシンプルなWebSocketサーバーを作ってみましょう。受信したメッセージをそのまま返す「エコーサーバー」です。

### サーバー側コード（Perl/Mojolicious）

`echo_server.pl`という名前で以下のコードを保存してください：

```perl
#!/usr/bin/env perl
use Mojolicious::Lite -signatures;

# WebSocketルートの定義
websocket '/echo' => sub ($c) {
  # メッセージ受信時の処理
  $c->on(message => sub ($c, $msg) {
    # 受信したメッセージをそのまま送り返す
    $c->send("Echo: $msg");
  });
  
  # 接続完了時の処理
  $c->on(finish => sub ($c, $code, $reason) {
    say "WebSocket接続が閉じられました";
  });
};

# 静的ファイル配信用のルート
get '/' => sub ($c) {
  $c->render(inline => <<'HTML');
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>WebSocket Echo Test</title>
</head>
<body>
  <h1>WebSocket Echo Test</h1>
  <input id="message" type="text" placeholder="メッセージを入力">
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
    
    ws.onerror = (error) => {
      output.innerHTML += '<p>エラー: ' + error + '</p>';
    };
    
    ws.onclose = () => {
      output.innerHTML += '<p>接続が閉じられました</p>';
    };
    
    function sendMessage() {
      const msg = document.getElementById('message').value;
      if (msg) {
        ws.send(msg);
        document.getElementById('message').value = '';
      }
    }
  </script>
</body>
</html>
HTML
};

app->start;
```

### コードの解説

**Perlサーバー側**:
- `websocket '/echo'`: WebSocketエンドポイントを定義
- `$c->on(message => ...)`: メッセージ受信時のコールバック
- `$c->send(...)`: クライアントにメッセージを送信
- `$c->on(finish => ...)`: 接続終了時のコールバック

**JavaScriptクライアント側**:
- `new WebSocket('ws://...')`: WebSocket接続を確立
- `ws.onopen`: 接続確立時のイベント
- `ws.onmessage`: メッセージ受信時のイベント
- `ws.send(msg)`: サーバーにメッセージを送信

### 動作確認

1. サーバーを起動：
```bash
perl echo_server.pl daemon
```

2. ブラウザで `http://localhost:3000` にアクセス

3. テキストボックスにメッセージを入力して「送信」ボタンをクリック

4. サーバーから返されたエコーメッセージが表示されることを確認

これで、WebSocketの基本的な送受信の仕組みを体験できました。次は、より実用的なチャットアプリケーションを作っていきます。

## チャットアプリケーションの実装

エコーサーバーでは1対1の通信でしたが、チャットでは複数のクライアントがメッセージを共有する必要があります。これを「ブロードキャスト」と呼びます。

### 設計方針

**メッセージフロー**:
1. クライアントAがメッセージを送信
2. サーバーが受信
3. サーバーが接続中のすべてのクライアント（A, B, C...）にブロードキャスト
4. すべてのクライアントが同じメッセージを受信

**クライアント管理**:
- 接続中のクライアントをハッシュで管理
- 各クライアントには一意のIDを割り当て
- 切断時にハッシュから削除

### サーバー側実装（Mojolicious）

`chat_server.pl`を作成します：

```perl
#!/usr/bin/env perl
use Mojolicious::Lite -signatures;
use Mojo::JSON qw(encode_json decode_json);

# 接続中のクライアントを管理するハッシュ
my $clients = {};

# WebSocketエンドポイント
websocket '/chat' => sub ($c) {
  # クライアントIDの生成（接続ごとにユニーク）
  my $id = sprintf "%s", $c->tx;
  
  # クライアントを登録
  $clients->{$id} = $c->tx;
  
  say "クライアント接続: $id (合計: " . (scalar keys %$clients) . "人)";
  
  # 入室通知をブロードキャスト
  broadcast({
    type => 'system',
    message => "新しいユーザーが参加しました",
    count => scalar keys %$clients
  });
  
  # メッセージ受信時の処理
  $c->on(message => sub ($c, $msg) {
    say "受信 [$id]: $msg";
    
    # 受信したメッセージをすべてのクライアントにブロードキャスト
    broadcast({
      type => 'message',
      id => $id,
      message => $msg,
      timestamp => time
    });
  });
  
  # 接続終了時の処理
  $c->on(finish => sub ($c, $code, $reason) {
    say "クライアント切断: $id";
    
    # クライアントリストから削除
    delete $clients->{$id};
    
    # 退室通知をブロードキャスト
    broadcast({
      type => 'system',
      message => "ユーザーが退出しました",
      count => scalar keys %$clients
    });
  });
};

# ブロードキャスト関数
sub broadcast {
  my $data = shift;
  my $json = encode_json($data);
  
  # すべての接続中クライアントに送信
  for my $id (keys %$clients) {
    my $tx = $clients->{$id};
    
    # 接続が有効な場合のみ送信
    if ($tx && !$tx->is_finished) {
      $tx->send($json);
    } else {
      # 無効な接続は削除
      delete $clients->{$id};
    }
  }
}

# 静的ファイル配信（クライアント側のHTMLを後述）
get '/' => sub ($c) {
  $c->render(template => 'chat');
};

app->start;

__DATA__
@@ chat.html.ep
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>Mojolicious Chat</title>
  <style>
    body {
      font-family: Arial, sans-serif;
      max-width: 800px;
      margin: 0 auto;
      padding: 20px;
    }
    #messages {
      border: 1px solid #ccc;
      height: 400px;
      overflow-y: auto;
      padding: 10px;
      margin-bottom: 10px;
      background-color: #f9f9f9;
    }
    .message {
      margin: 5px 0;
      padding: 5px;
    }
    .system {
      color: #666;
      font-style: italic;
    }
    .user {
      color: #0066cc;
    }
    #input-area {
      display: flex;
      gap: 10px;
    }
    #messageInput {
      flex: 1;
      padding: 10px;
      font-size: 14px;
    }
    #sendButton {
      padding: 10px 20px;
      font-size: 14px;
      background-color: #0066cc;
      color: white;
      border: none;
      cursor: pointer;
    }
    #sendButton:disabled {
      background-color: #ccc;
      cursor: not-allowed;
    }
    #status {
      margin-bottom: 10px;
      padding: 10px;
      background-color: #e8f4f8;
      border-left: 4px solid #0066cc;
    }
  </style>
</head>
<body>
  <h1>Mojolicious WebSocket Chat</h1>
  <div id="status">接続中...</div>
  <div id="messages"></div>
  <div id="input-area">
    <input type="text" id="messageInput" placeholder="メッセージを入力" disabled>
    <button id="sendButton" disabled>送信</button>
  </div>
  
  <script>
    const messagesDiv = document.getElementById('messages');
    const messageInput = document.getElementById('messageInput');
    const sendButton = document.getElementById('sendButton');
    const statusDiv = document.getElementById('status');
    
    // WebSocket接続の確立
    const ws = new WebSocket('ws://' + window.location.host + '/chat');
    
    // 接続確立時
    ws.onopen = () => {
      statusDiv.textContent = '接続完了。メッセージを送信できます。';
      statusDiv.style.backgroundColor = '#d4edda';
      statusDiv.style.borderColor = '#28a745';
      messageInput.disabled = false;
      sendButton.disabled = false;
      messageInput.focus();
    };
    
    // メッセージ受信時
    ws.onmessage = (event) => {
      const data = JSON.parse(event.data);
      const messageEl = document.createElement('div');
      messageEl.className = 'message';
      
      if (data.type === 'system') {
        messageEl.classList.add('system');
        messageEl.textContent = `[システム] ${data.message} (接続中: ${data.count}人)`;
      } else {
        messageEl.classList.add('user');
        const time = new Date(data.timestamp * 1000).toLocaleTimeString();
        messageEl.textContent = `[${time}] ${data.message}`;
      }
      
      messagesDiv.appendChild(messageEl);
      messagesDiv.scrollTop = messagesDiv.scrollHeight;
    };
    
    // エラー時
    ws.onerror = (error) => {
      statusDiv.textContent = 'エラーが発生しました';
      statusDiv.style.backgroundColor = '#f8d7da';
      statusDiv.style.borderColor = '#dc3545';
    };
    
    // 接続終了時
    ws.onclose = () => {
      statusDiv.textContent = '接続が閉じられました';
      statusDiv.style.backgroundColor = '#f8d7da';
      statusDiv.style.borderColor = '#dc3545';
      messageInput.disabled = true;
      sendButton.disabled = true;
    };
    
    // メッセージ送信関数
    function sendMessage() {
      const msg = messageInput.value.trim();
      if (msg && ws.readyState === WebSocket.OPEN) {
        ws.send(msg);
        messageInput.value = '';
        messageInput.focus();
      }
    }
    
    // イベントリスナー
    sendButton.addEventListener('click', sendMessage);
    messageInput.addEventListener('keypress', (e) => {
      if (e.key === 'Enter') {
        sendMessage();
      }
    });
  </script>
</body>
</html>
```

### コードの詳細解説

**接続管理**:
```perl
my $clients = {};  # グローバルなハッシュで管理
my $id = sprintf "%s", $c->tx;  # トランザクションオブジェクトをIDとして使用
$clients->{$id} = $c->tx;  # 接続を登録
```

**ブロードキャスト処理**:
```perl
sub broadcast {
  my $data = shift;
  my $json = encode_json($data);  # ハッシュをJSONに変換
  
  for my $id (keys %$clients) {
    my $tx = $clients->{$id};
    if ($tx && !$tx->is_finished) {  # 有効な接続のみ
      $tx->send($json);
    }
  }
}
```

**切断処理**:
```perl
$c->on(finish => sub {
  delete $clients->{$id};  # ハッシュから削除
  broadcast({type => 'system', message => '退出'});
});
```

### クライアント側（React + TypeScript版）

より本格的なアプリケーションでは、ReactとTypeScriptを使った実装も考えられます。

プロジェクト構造：
```
chat-client/
├── package.json
├── tsconfig.json
├── vite.config.ts
└── src/
    ├── App.tsx
    ├── hooks/
    │   └── useWebSocket.ts
    └── components/
        ├── ChatMessages.tsx
        └── MessageInput.tsx
```

**useWebSocket.ts（WebSocketフック）**:
```typescript
import { useEffect, useRef, useState } from 'react';

export interface ChatMessage {
  type: 'system' | 'message';
  message: string;
  id?: string;
  timestamp?: number;
  count?: number;
}

export const useWebSocket = (url: string) => {
  const [messages, setMessages] = useState<ChatMessage[]>([]);
  const [isConnected, setIsConnected] = useState(false);
  const wsRef = useRef<WebSocket | null>(null);

  useEffect(() => {
    // WebSocket接続の確立
    const ws = new WebSocket(url);
    wsRef.current = ws;

    ws.onopen = () => {
      console.log('WebSocket接続確立');
      setIsConnected(true);
    };

    ws.onmessage = (event) => {
      const data: ChatMessage = JSON.parse(event.data);
      setMessages((prev) => [...prev, data]);
    };

    ws.onerror = (error) => {
      console.error('WebSocketエラー:', error);
    };

    ws.onclose = () => {
      console.log('WebSocket接続終了');
      setIsConnected(false);
    };

    // クリーンアップ
    return () => {
      ws.close();
    };
  }, [url]);

  const sendMessage = (message: string) => {
    if (wsRef.current?.readyState === WebSocket.OPEN) {
      wsRef.current.send(message);
    }
  };

  return { messages, isConnected, sendMessage };
};
```

**App.tsx（メインコンポーネント）**:
```typescript
import React from 'react';
import { useWebSocket } from './hooks/useWebSocket';
import { ChatMessages } from './components/ChatMessages';
import { MessageInput } from './components/MessageInput';

const App: React.FC = () => {
  const wsUrl = `ws://${window.location.host}/chat`;
  const { messages, isConnected, sendMessage } = useWebSocket(wsUrl);

  return (
    <div className="chat-app">
      <h1>Mojolicious WebSocket Chat</h1>
      <div className="status">
        {isConnected ? (
          <span className="connected">接続中</span>
        ) : (
          <span className="disconnected">切断</span>
        )}
      </div>
      <ChatMessages messages={messages} />
      <MessageInput onSend={sendMessage} disabled={!isConnected} />
    </div>
  );
};

export default App;
```

**ChatMessages.tsx**:
```typescript
import React, { useEffect, useRef } from 'react';
import { ChatMessage } from '../hooks/useWebSocket';

interface Props {
  messages: ChatMessage[];
}

export const ChatMessages: React.FC<Props> = ({ messages }) => {
  const messagesEndRef = useRef<HTMLDivElement>(null);

  // 新しいメッセージが追加されたら自動スクロール
  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [messages]);

  return (
    <div className="messages-container">
      {messages.map((msg, index) => (
        <div
          key={index}
          className={`message ${msg.type === 'system' ? 'system' : 'user'}`}
        >
          {msg.type === 'system' ? (
            <span>[システム] {msg.message} (接続中: {msg.count}人)</span>
          ) : (
            <span>
              [{new Date((msg.timestamp || 0) * 1000).toLocaleTimeString()}] {msg.message}
            </span>
          )}
        </div>
      ))}
      <div ref={messagesEndRef} />
    </div>
  );
};
```

**MessageInput.tsx**:
```typescript
import React, { useState } from 'react';

interface Props {
  onSend: (message: string) => void;
  disabled: boolean;
}

export const MessageInput: React.FC<Props> = ({ onSend, disabled }) => {
  const [inputValue, setInputValue] = useState('');

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    const trimmed = inputValue.trim();
    if (trimmed) {
      onSend(trimmed);
      setInputValue('');
    }
  };

  return (
    <form onSubmit={handleSubmit} className="message-input">
      <input
        type="text"
        value={inputValue}
        onChange={(e) => setInputValue(e.target.value)}
        placeholder="メッセージを入力"
        disabled={disabled}
      />
      <button type="submit" disabled={disabled || !inputValue.trim()}>
        送信
      </button>
    </form>
  );
};
```

### 動作確認：2つのブラウザでチャット

1. サーバーを起動：
```bash
perl chat_server.pl daemon
```

2. ブラウザを2つ開いて、両方で `http://localhost:3000` にアクセス

3. 一方のブラウザでメッセージを送信

4. もう一方のブラウザにも同じメッセージが表示されることを確認

5. 入退室通知も両方に表示されることを確認

これで、リアルタイムなチャットアプリケーションが完成しました。

## 実用的な拡張機能

基本的なチャットができたので、より実用的な機能を追加していきましょう。

### 入退室通知の改善

現在の実装では「新しいユーザー」と表示されるだけですが、ユーザー名を表示できるようにします：

```perl
websocket '/chat' => sub ($c) {
  my $id = sprintf "%s", $c->tx;
  
  # クエリパラメータからユーザー名を取得
  my $username = $c->param('username') || '匿名' . substr($id, 0, 8);
  
  # ユーザー情報を保存
  $clients->{$id} = {
    tx => $c->tx,
    username => $username,
    joined_at => time
  };
  
  say "$username が接続しました";
  
  broadcast({
    type => 'join',
    username => $username,
    count => scalar keys %$clients
  });
  
  $c->on(message => sub ($c, $msg) {
    broadcast({
      type => 'message',
      username => $username,
      message => $msg,
      timestamp => time
    });
  });
  
  $c->on(finish => sub {
    delete $clients->{$id};
    broadcast({
      type => 'leave',
      username => $username,
      count => scalar keys %$clients
    });
  });
};

# broadcast関数も修正
sub broadcast {
  my $data = shift;
  my $json = encode_json($data);
  
  for my $id (keys %$clients) {
    my $client = $clients->{$id};
    my $tx = $client->{tx};
    
    if ($tx && !$tx->is_finished) {
      $tx->send($json);
    } else {
      delete $clients->{$id};
    }
  }
}
```

クライアント側でユーザー名を設定：
```javascript
// 接続時にユーザー名をクエリパラメータで渡す
const username = prompt('ユーザー名を入力してください', 'ゲスト');
const ws = new WebSocket(`ws://${window.location.host}/chat?username=${encodeURIComponent(username)}`);
```

### 接続状態の管理（再接続、heartbeat）

WebSocket接続が切れた場合に自動再接続する機能を実装します：

```typescript
// useWebSocket.ts に追加
export const useWebSocket = (url: string) => {
  const [messages, setMessages] = useState<ChatMessage[]>([]);
  const [isConnected, setIsConnected] = useState(false);
  const wsRef = useRef<WebSocket | null>(null);
  const reconnectTimeoutRef = useRef<number | null>(null);
  const reconnectAttemptsRef = useRef(0);
  const heartbeatIntervalRef = useRef<number | null>(null);

  const connect = () => {
    const ws = new WebSocket(url);
    wsRef.current = ws;

    ws.onopen = () => {
      console.log('WebSocket接続確立');
      setIsConnected(true);
      reconnectAttemptsRef.current = 0;
      
      // ハートビート開始（30秒ごとにpingを送信）
      heartbeatIntervalRef.current = window.setInterval(() => {
        if (ws.readyState === WebSocket.OPEN) {
          ws.send(JSON.stringify({ type: 'ping' }));
        }
      }, 30000);
    };

    ws.onmessage = (event) => {
      const data: ChatMessage = JSON.parse(event.data);
      
      // pongは表示しない
      if (data.type !== 'pong') {
        setMessages((prev) => [...prev, data]);
      }
    };

    ws.onerror = (error) => {
      console.error('WebSocketエラー:', error);
    };

    ws.onclose = () => {
      console.log('WebSocket接続終了');
      setIsConnected(false);
      
      // ハートビート停止
      if (heartbeatIntervalRef.current) {
        clearInterval(heartbeatIntervalRef.current);
      }
      
      // 再接続の試行（最大10回まで、指数バックオフ）
      if (reconnectAttemptsRef.current < 10) {
        const delay = Math.min(1000 * Math.pow(2, reconnectAttemptsRef.current), 30000);
        console.log(`${delay}ms後に再接続を試行します...`);
        
        reconnectTimeoutRef.current = window.setTimeout(() => {
          reconnectAttemptsRef.current++;
          connect();
        }, delay);
      }
    };
  };

  useEffect(() => {
    connect();

    return () => {
      // クリーンアップ
      if (reconnectTimeoutRef.current) {
        clearTimeout(reconnectTimeoutRef.current);
      }
      if (heartbeatIntervalRef.current) {
        clearInterval(heartbeatIntervalRef.current);
      }
      wsRef.current?.close();
    };
  }, [url]);

  const sendMessage = (message: string) => {
    if (wsRef.current?.readyState === WebSocket.OPEN) {
      wsRef.current.send(message);
    }
  };

  return { messages, isConnected, sendMessage };
};
```

サーバー側でpingに応答：
```perl
$c->on(message => sub ($c, $msg) {
  # JSON形式のメッセージをパース
  my $data = eval { decode_json($msg) };
  
  if ($data && $data->{type} eq 'ping') {
    # pingにはpongで応答
    $c->send(encode_json({ type => 'pong' }));
  } else {
    # 通常のメッセージはブロードキャスト
    broadcast({
      type => 'message',
      username => $username,
      message => $msg,
      timestamp => time
    });
  }
});
```

### エラーハンドリング

適切なエラーハンドリングを追加します：

```perl
websocket '/chat' => sub ($c) {
  my $id = sprintf "%s", $c->tx;
  my $username = $c->param('username') || '匿名' . substr($id, 0, 8);
  
  # ユーザー名のバリデーション
  if (length($username) > 20) {
    $c->render(json => { error => 'ユーザー名は20文字以内にしてください' }, status => 400);
    return;
  }
  
  $clients->{$id} = {
    tx => $c->tx,
    username => $username,
    joined_at => time
  };
  
  $c->on(message => sub ($c, $msg) {
    # メッセージ長のチェック
    if (length($msg) > 500) {
      $c->send(encode_json({
        type => 'error',
        message => 'メッセージは500文字以内にしてください'
      }));
      return;
    }
    
    # XSS対策（HTMLエスケープ）
    $msg = Mojo::Util::xml_escape($msg);
    
    broadcast({
      type => 'message',
      username => $username,
      message => $msg,
      timestamp => time
    });
  });
  
  $c->on(finish => sub ($c, $code, $reason) {
    delete $clients->{$id};
    broadcast({
      type => 'leave',
      username => $username,
      count => scalar keys %$clients
    });
  });
};
```

これらの拡張により、より堅牢で実用的なチャットアプリケーションになります。

## パフォーマンスと最適化

### 接続数の限界とC10K問題

「C10K問題」とは、1台のサーバーで同時に1万（10K）のクライアント接続を処理する課題です。

従来のスレッドモデルでは：
- 1接続 = 1スレッド
- スレッドのメモリオーバーヘッド：数MB
- 10,000接続 = 数十GB必要
- コンテキストスイッチのコストも大きい

### Mojoliciousの非同期処理の強み

Mojoliciousは`EV`や`IO::Poll`などのイベントループを使用し、1つのプロセスで数千〜数万の接続を処理できます：

- イベント駆動・ノンブロッキングI/O
- 1接続あたりのメモリオーバーヘッドが小さい（数KB〜数十KB）
- CPUを効率的に使用

実測例（参考値）：
- メモリ: 10,000接続で約500MB-1GB
- CPU: アイドル時は1-2%、メッセージ送信時に増加

### メッセージサイズの考慮

WebSocketでは、メッセージサイズが大きいと以下の問題が発生します：

1. **帯域幅の圧迫**: すべてのクライアントに大きなデータを送ると、ネットワーク帯域を消費
2. **メモリ消費**: サーバー側でメッセージをバッファリングする必要がある
3. **レイテンシの増加**: 大きなメッセージの送受信に時間がかかる

最適化のヒント：

```perl
# メッセージの圧縮
use Compress::Zlib;

$c->on(message => sub ($c, $msg) {
  # 大きなメッセージは圧縮
  if (length($msg) > 1024) {
    $msg = compress($msg);
  }
  
  broadcast({ message => $msg });
});

# バイナリメッセージの使用
$c->send({ binary => $binary_data });

# メッセージの分割送信
for my $chunk (@chunks) {
  $c->send($chunk);
  Mojo::IOLoop->timer(0.1 => sub { }); # 少し間隔を空ける
}
```

### パフォーマンスモニタリング

```perl
use Time::HiRes qw(gettimeofday tv_interval);

sub broadcast {
  my $data = shift;
  my $t0 = [gettimeofday];
  
  my $json = encode_json($data);
  my $sent_count = 0;
  
  for my $id (keys %$clients) {
    my $client = $clients->{$id};
    my $tx = $client->{tx};
    
    if ($tx && !$tx->is_finished) {
      $tx->send($json);
      $sent_count++;
    } else {
      delete $clients->{$id};
    }
  }
  
  my $elapsed = tv_interval($t0);
  say "Broadcast: $sent_count clients in ${elapsed}s";
}
```

これにより、ブロードキャストにかかる時間を計測し、ボトルネックを特定できます。

## （発展編）Kubernetesでの運用

本格的な運用では、Kubernetesでのデプロイが選択肢になります。

### コンテナ化のベストプラクティス

**Dockerfile**:
```dockerfile
FROM perl:5.38-slim

WORKDIR /app

# 必要な依存をインストール
RUN cpanm --notest Mojolicious EV

# アプリケーションコードをコピー
COPY chat_server.pl .

# 非rootユーザーで実行
RUN useradd -m appuser && chown -R appuser:appuser /app
USER appuser

# ポートを公開
EXPOSE 3000

# アプリケーション起動
CMD ["perl", "chat_server.pl", "daemon", "-l", "http://*:3000"]
```

ビルドとテスト：
```bash
docker build -t mojolicious-chat:latest .
docker run -p 3000:3000 mojolicious-chat:latest
```

### WebSocketに必要なKubernetes設定

**Deployment**:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mojolicious-chat
spec:
  replicas: 3
  selector:
    matchLabels:
      app: mojolicious-chat
  template:
    metadata:
      labels:
        app: mojolicious-chat
    spec:
      containers:
      - name: chat
        image: mojolicious-chat:latest
        ports:
        - containerPort: 3000
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /
            port: 3000
          initialDelaySeconds: 10
          periodSeconds: 30
        readinessProbe:
          httpGet:
            path: /
            port: 3000
          initialDelaySeconds: 5
          periodSeconds: 10
```

**Service**:
```yaml
apiVersion: v1
kind: Service
metadata:
  name: mojolicious-chat-service
spec:
  selector:
    app: mojolicious-chat
  ports:
  - protocol: TCP
    port: 80
    targetPort: 3000
  type: ClusterIP
```

**Ingress（WebSocket対応）**:
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: mojolicious-chat-ingress
  annotations:
    nginx.ingress.kubernetes.io/websocket-services: mojolicious-chat-service
    nginx.ingress.kubernetes.io/proxy-read-timeout: "3600"
    nginx.ingress.kubernetes.io/proxy-send-timeout: "3600"
spec:
  rules:
  - host: chat.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: mojolicious-chat-service
            port:
              number: 80
```

重要なアノテーション：
- `websocket-services`: WebSocketを有効化
- `proxy-read-timeout` / `proxy-send-timeout`: WebSocket接続のタイムアウトを長く設定

### 水平スケーリングの課題

WebSocketアプリケーションを複数のPodにスケールする場合、**セッションアフィニティ（スティッキーセッション）**が必要です：

```yaml
apiVersion: v1
kind: Service
metadata:
  name: mojolicious-chat-service
spec:
  selector:
    app: mojolicious-chat
  ports:
  - protocol: TCP
    port: 80
    targetPort: 3000
  sessionAffinity: ClientIP
  sessionAffinityConfig:
    clientIP:
      timeoutSeconds: 3600
```

さらに高度な解決策：
- **Redis Pub/Sub**: Pod間でメッセージを共有
```perl
use Mojo::Redis;

my $redis = Mojo::Redis->new('redis://redis-service:6379');
my $pubsub = $redis->pubsub;

# メッセージをRedisに発行
$pubsub->publish('chat_channel' => $json);

# 他のPodからのメッセージを受信
$pubsub->listen('chat_channel' => sub {
  my ($pubsub, $message) = @_;
  # ローカルクライアントにブロードキャスト
  local_broadcast($message);
});
```

- **Kubernetes Service Mesh**: IstioやLinkerdによる高度なルーティング

これにより、複数のPod間で状態を共有し、真の水平スケーリングが可能になります。

## まとめ

この記事では、MojoliciousでWebSocketを使ったリアルタイムチャットアプリケーションを実装しながら、以下のことを学びました：

### WebSocketとイベント駆動の本質的な理解

- **WebSocketの必要性**: HTTPのリクエスト/レスポンスモデルの限界を超え、双方向通信と低レイテンシを実現
- **イベント駆動プログラミング**: ノンブロッキングI/Oとコールバックにより、効率的な非同期処理が可能
- **Mojo::IOLoop**: Mojoliciousのイベントループが、多数の同時接続を1つのプロセスで処理

### Mojoliciousの実用性

- **ゼロ依存**: 標準的なPerlとMojoliciousだけでWebSocketサーバーを構築できる
- **シンプルなAPI**: `websocket`ルート、`on`イベント、`send`メソッドだけで基本的な機能を実装
- **スケーラビリティ**: イベント駆動アーキテクチャにより、数千〜数万の同時接続に対応

### 実装のポイント

- **接続管理**: ハッシュで接続中のクライアントを管理
- **ブロードキャスト**: すべてのクライアントにメッセージを配信
- **エラーハンドリング**: 切断、再接続、バリデーションの実装
- **Kubernetes対応**: コンテナ化、WebSocket対応Ingress、セッションアフィニティ

### さらなる学習リソース

- **公式ドキュメント**:
  - {{< linkcard "https://docs.mojolicious.org/" >}}
  - {{< linkcard "https://docs.mojolicious.org/Mojolicious/Guides/Cookbook#WebSocket-web-service" >}}

- **WebSocket仕様**:
  - {{< linkcard "https://tools.ietf.org/html/rfc6455" >}}

- **イベント駆動プログラミング**:
  - {{< linkcard "https://docs.mojolicious.org/Mojo/IOLoop" >}}

- **Kubernetes WebSocket**:
  - {{< linkcard "https://kubernetes.github.io/ingress-nginx/user-guide/miscellaneous/#websockets" >}}

WebSocketとイベント駆動プログラミングは、モダンなWebアプリケーション開発において必須のスキルです。Mojoliciousは、これらの技術を手軽に学び、実用的なアプリケーションを構築するための優れたフレームワークです。

ぜひ、このチャットアプリケーションをベースに、独自のリアルタイムアプリケーションを開発してみてください！
