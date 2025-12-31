---
title: "調査ドキュメント: Discord / Slack ボット シリーズ記事作成のための情報収集"
draft: true
description: "シリーズ記事「Discord / Slack ボットを作ってみよう」作成のための調査・情報収集レポート。Perl CPANモジュール、Webhook/API、イベント駆動、デザインパターンの情報を網羅。"
---

# 調査ドキュメント: Discord / Slack ボット シリーズ記事

## 調査目的

シリーズ記事「Discord / Slack ボットを作ってみよう」を作成するための情報収集を行う。

### 前提情報

| 項目 | 内容 |
|------|------|
| **テーマ** | Discord / Slack ボット |
| **学習内容** | Webhook、API、イベント駆動の考え方。特定のキーワードに反応して返信したり、リマインダーを投げたりする |
| **ゴール** | 自然に覚えるデザインパターン |
| **技術スタック** | Perl |
| **想定読者** | Perl入学式卒業程度、前シリーズ「Mooで覚えるオブジェクト指向プログラミング」第12回（型チェックでバグを未然に防ぐ）を読了 |
| **制約** | 各回コード例2つまで、新しい概念1つまで |

### 調査実施日

2025年12月31日

---

## 1. キーワード調査

### 1.1 Discord Bot API / Perl

#### 要点

- PerlでDiscord Botを作成する場合、**Mojo::Discord** がCPANで利用可能な主要モジュール
- 公式SDKはないが、コミュニティによる実装が存在
- Mojoliciousの非同期フレームワークを基盤としており、WebSocket通信をサポート

#### Mojo::Discord の構成

| モジュール | 役割 |
|-----------|------|
| `Mojo::Discord` | メインエントリポイント |
| `Mojo::Discord::REST` | REST API操作 |
| `Mojo::Discord::Gateway` | WebSocketクライアント（リアルタイムイベント） |
| `Mojo::Discord::Auth` | OAuth2認証（部分実装） |
| `Mojo::Discord::User`, `Guild`, `Channels` | 各種オブジェクト抽象化 |

#### 主な依存関係

- `Mojo::UserAgent`, `Mojo::IOLoop`: 非同期HTTP/WebSocket
- `Compress::Zlib`: Zlibメッセージ解凍
- `Mojo::JSON`, `Encode::Guess`: データシリアライズ
- `IO::Socket::SSL`: SSL通信

#### 根拠・出典

- GitHub: https://github.com/vsTerminus/Mojo-Discord
- DeepWiki解説: https://deepwiki.com/vsTerminus/Mojo-Discord/2-getting-started
- Discord Community Resources: https://discord.com/developers/docs/developer-tools/community-resources

#### 信頼度

中〜高（コミュニティメンテナンス、一部機能は未実装）

---

### 1.2 Slack Bot API / Perl

#### 要点

PerlでSlack Botを開発する場合、複数のCPANモジュールが選択可能：

| モジュール | イベントループ | 対応API |
|-----------|---------------|---------|
| `AnyEvent::SlackRTM` | AnyEvent | RTM API（WebSocket） |
| `WebService::Slack::WebApi` | Furl（HTTP） | Web API（REST） |
| `AnyEvent::SlackBot` | AnyEvent | RTM API |
| `Net::Async::Slack` | IO::Async | RTM/Web API |
| `Mojo::SlackRTM` | Mojolicious | RTM API |
| `Slack::RTM::Bot` | LWP | RTM API |

#### Slack APIの動向（2024-2025）

- **RTM API**: 引き続きサポートされているが、新規Botは**Events API**を推奨
- **Events API**: HTTP経由のプッシュ通知、サーバーレス/分散アーキテクチャに適合
- **Web API**: REST形式、`chat.postMessage`などでメッセージ送信

#### サンプルコード（Webhook経由）

```perl
use LWP::UserAgent;
use JSON;

my $token = 'xoxb-...'; # Botトークン
my $channel = '#general';
my $text = 'Hello, Slack!';
my $ua = LWP::UserAgent->new;
my $res = $ua->post(
  'https://slack.com/api/chat.postMessage',
  'Content-Type' => 'application/json; charset=utf-8',
  'Authorization' => "Bearer $token",
  Content => encode_json({ channel => $channel, text => $text })
);
```

#### 根拠・出典

- MetaCPAN AnyEvent::SlackRTM: https://metacpan.org/dist/AnyEvent-SlackRTM
- Net::Async::Slack GitHub: https://github.com/team-at-cpan/Net-Async-Slack
- Slack Events API公式: https://docs.slack.dev/apis/events-api/

#### 信頼度

高（公式ドキュメントおよびCPAN）

---

### 1.3 Webhook（Incoming / Outgoing）

#### 要点

- **Webhook**: 特定イベント発生時に、事前登録されたURLへHTTPリクエストを送る仕組み
- **Incoming Webhook**: 外部サービス → 自分のアプリへの通知
- **Outgoing Webhook**: 自分のアプリ → 外部サービスへの通知

#### APIとの違い

| 項目 | API（プル型） | Webhook（プッシュ型） |
|------|--------------|---------------------|
| 通信方向 | クライアント → サーバー | サーバー → クライアント |
| タイミング | 任意（ポーリング） | イベント発生時（即時） |
| 負荷 | 定期リクエストが必要 | 必要時のみ通信 |
| リアルタイム性 | 低い | 高い |

#### 運用上の注意点

1. **到達保証とリトライ**: 必ず200 OKを返す設計
2. **セキュリティ**: HMAC署名認証、HTTPS必須
3. **冪等性**: 同じ通知が複数回届いても安全に処理
4. **スケーラビリティ**: 非同期・キュー方式

#### 根拠・出典

- Webhookとは（Qiita）: https://qiita.com/HERUESTA/items/8a2a6e8a204e47db5a3b
- Webhook完全ガイド: https://it-notes.stylemap.co.jp/webservice/webhook%E5%AE%8C%E5%85%A8%E3%82%AC%E3%82%A4%E3%83%89/
- Incoming Webhook解説: https://www.issoh.co.jp/tech/details/6596/

#### 信頼度

高

---

### 1.4 イベント駆動プログラミング（Event-driven programming）

#### 要点

- イベント（ユーザー操作、ネットワーク入力など）によってプログラムの流れを制御する手法
- GUIアプリ、Webサーバー、Bot開発で標準的に使用

#### 主要な概念

| 用語 | 説明 |
|------|------|
| **イベント** | マウスクリック、メッセージ受信などの事象 |
| **イベントハンドラー** | イベント発生時に呼び出される関数 |
| **イベントループ** | イベントキューを監視し処理を分配する仕組み |
| **イベントディスパッチャー** | イベントを適切なハンドラーに割り当てる役割 |

#### 代表的なパターン

1. **Observerパターン**: 1つのSubjectが複数のObserverに通知
2. **Pub/Subモデル**: イベントバスを介した疎結合な通信
3. **Commandパターン**: 処理をオブジェクト化して委譲

#### 根拠・出典

- イベント駆動型プログラミング完全ガイド: https://everplay.jp/column/38141
- Pythonでのイベント駆動（Qiita）: https://qiita.com/Tadataka_Takahashi/items/475f6d160e94984156d2

#### 信頼度

高

---

### 1.5 WebSocket（リアルタイム通信）

#### 要点

- クライアントとサーバー間で双方向・リアルタイム通信を実現するプロトコル
- HTTP接続をアップグレードして永続的な接続を確立
- Discord Gateway、Slack RTM APIの基盤技術

#### MojoliciousでのWebSocket実装

```perl
#!/usr/bin/env perl
use Mojolicious::Lite -signatures;

# WebSocketエンドポイント
websocket '/ws' => sub ($c) {
  $c->on(message => sub ($c, $msg) {
    $c->send("Echo: $msg");
  });
  $c->on(finish => sub { warn "Connection closed"; });
};

app->start;
```

#### 主なWebSocketイベント（Mojo::Transaction::WebSocket）

- `message`: メッセージ受信
- `json`: JSONデコードされたメッセージ
- `finish`: 切断
- `binary`: バイナリメッセージ

#### 根拠・出典

- Perl WebSocket入門（自サイト記事）: https://www.nqou.net/2025/12/14/183305/
- Mojo::Transaction::WebSocket日本語解説: https://mojodoc.perlzemi.com/Mojo::Transaction::WebSocket.html
- Mojolicious WebSocket実装例: https://peerdh.com/blogs/programming-insights/implementing-websocket-communication-in-mojolicious-applications

#### 信頼度

高

---

### 1.6 Discord API レート制限

#### 要点

Discord APIには厳格なレート制限があり、遵守しないとBot停止のリスクがある。

#### 主な制限値

| 種別 | 制限値 | 備考 |
|------|--------|------|
| グローバル | 約50リクエスト/秒 | エンドポイントにより変動 |
| メッセージ送信 | 5件/5秒 | チャンネルごと |
| メッセージ削除 | 5件/1秒 | |
| リアクション追加 | 1件/0.25秒 | |
| チャンネル作成 | 2件/10分 | |
| Webhooks | 30件/60秒 | |
| 無効リクエスト | 10,000件/10分超でBAN | |

#### ベストプラクティス

1. HTTPレスポンスヘッダーの`X-RateLimit-*`を解析
2. `Retry-After`で指定された待機時間を遵守
3. エクスポネンシャルバックオフの実装
4. キャッシュ活用でAPI連打を回避
5. シャーディング（2,500ギルド超で必須）

#### 根拠・出典

- Discord公式Rate Limits: https://discord.com/developers/docs/topics/rate-limits
- GitHub discord-api-docs: https://github.com/discord/discord-api-docs/blob/main/docs/topics/rate-limits.md
- Discord日本語ヘルプ: https://support-dev.discord.com/hc/ja/articles/6223003921559

#### 信頼度

高（公式ドキュメント）

---

### 1.7 デザインパターン（Observer、Command、Strategy）

#### 要点

Bot開発で自然に習得できるデザインパターン：

| パターン | 適用場面 | Botでの例 |
|---------|---------|----------|
| **Observer** | イベント通知 | メッセージ受信時に複数ハンドラーへ通知 |
| **Command** | 操作のオブジェクト化 | ボットコマンドのカプセル化 |
| **Strategy** | アルゴリズム切り替え | 応答パターンの動的変更 |
| **Dispatcher** | イベント振り分け | URLやキーワードで処理を分岐 |

#### Perl実装例（Observer）

```perl
package Subject;
sub new { my $class = shift; bless { observers => [] }, $class }
sub attach { my ($self, $obs) = @_; push @{$self->{observers}}, $obs }
sub notify { my $self = shift; $_->update() for @{$self->{observers}} }

package Observer;
sub new { my ($class, $name) = @_; bless { name => $name }, $class }
sub update { my $self = shift; print "$self->{name}: update received\n" }
```

#### 根拠・出典

- Command vs Strategyパターン（Qiita）: https://qiita.com/nozomi2025/items/102511ea70259184632e
- Refactoring Guru Observer: https://refactoring.guru/ja/design-patterns/observer
- 事例で学ぶデザインパターン: https://www.ogis-ri.co.jp/otc/hiroba/technical/DesignPatternsWithExample/chapter06.html

#### 信頼度

高

---

### 1.8 Perl CPANモジュール一覧

#### Discord関連

| モジュール | 説明 | URL |
|-----------|------|-----|
| `Mojo::Discord` | Discord APIラッパー（Mojolicious基盤） | https://github.com/vsTerminus/Mojo-Discord |
| `Discord::Client` | Discord API実装（別実装） | https://metacpan.org/pod/Discord::Client |

#### Slack関連

| モジュール | イベントループ | URL |
|-----------|---------------|-----|
| `AnyEvent::SlackRTM` | AnyEvent | https://metacpan.org/dist/AnyEvent-SlackRTM |
| `WebService::Slack::WebApi` | Furl | https://metacpan.org/pod/WebService::Slack::WebApi |
| `Net::Async::Slack` | IO::Async | https://metacpan.org/pod/Net::Async::Slack |
| `Slack::RTM::Bot` | LWP | https://metacpan.org/pod/Slack::RTM::Bot |

#### 関連基盤モジュール

| モジュール | 用途 |
|-----------|------|
| `Mojolicious` | Webフレームワーク/イベントループ |
| `Mojo::IOLoop` | 非同期イベントループ |
| `Mojo::UserAgent` | HTTPクライアント |
| `AnyEvent` | イベントフレームワーク |
| `IO::Async` | イベントフレームワーク |
| `JSON::XS` / `Mojo::JSON` | JSONパース |
| `LWP::UserAgent` | HTTPクライアント |

---

## 2. 競合記事の分析

### 2.1 日本語での Discord/Slack Bot 記事状況

#### Discord Bot関連

| 記事タイプ | 言語 | 特徴 |
|-----------|------|------|
| 初心者向け完全ガイド | Python | 最も多数、環境構築から運用まで |
| Node.js実装 | JavaScript | discord.js使用、活発な開発 |
| 概念解説 | 言語不問 | Bot作成の考え方、準備手順 |
| **Perl実装** | Perl | **ほぼ皆無（大きな差別化ポイント）** |

#### Slack Bot関連

| 記事タイプ | 言語 | 特徴 |
|-----------|------|------|
| Webhook活用 | 言語不問 | Incoming Webhook中心 |
| Events API | Python/Node.js | モダンな実装 |
| RTM API | 各種言語 | リアルタイム通信 |
| **Perl実装** | Perl | **少数（差別化可能）** |

### 2.2 差別化ポイント

1. **Perl特化**: 日本語でPerlによるBot開発記事はほぼ存在しない
2. **デザインパターン習得**: 単なる実装ではなく、設計思想を学べる構成
3. **段階的学習**: 前シリーズ（Mooで覚えるOOP）との連携
4. **イベント駆動の理解**: Webhookから始めて徐々に複雑化
5. **実用的なユースケース**: リマインダー、キーワード反応など

### 2.3 主要な競合記事

| タイトル | URL | 特徴 |
|---------|-----|------|
| Discord Botを作ろう！完全開発ガイド | https://www.choge-blog.com/hobby/discord-bot-create/ | Python、初心者向け |
| Discord Botを0から作成24時間運用 | https://qiita.com/Naoya_pro/items/d8259d072d1e8f046a93 | Python、実践的 |
| Slack Botの作り方完全ガイド | https://www.choge-blog.com/programming/slack-bot-create/ | Python/Node.js |
| Slackでチャットbotをつくる方法 | https://zenn.dev/karaage0703/articles/fcc3dde4ad090a | 汎用、概念中心 |

---

## 3. 内部リンク調査

### 3.1 関連記事（高関連性）

前シリーズ「Mooで覚えるオブジェクト指向プログラミング」との連携が重要。

| ファイル | タイトル | 内部リンク | 関連ポイント |
|---------|---------|-----------|-------------|
| 2021/10/31/191008.md | 第1回-Mooで覚えるOOP | `/2021/10/31/191008/` | シリーズ起点、前提知識 |
| 2025/12/30/163810.md | 第2回-データとロジックをまとめよう | `/2025/12/30/163810/` | has/sub基礎 |
| 2025/12/30/163820.md | 第12回-型チェックでバグを未然に防ぐ | `/2025/12/30/163820/` | 前シリーズ完結、直接の前提 |
| 2025/12/30/164001.md | 第1回-ディスパッチャー | `/2025/12/30/164001/` | 関連シリーズ |
| 2025/12/30/164012.md | 第12回-これがデザインパターンだ！ | `/2025/12/30/164012/` | デザインパターン紹介 |

### 3.2 関連記事（技術関連）

| ファイル | タイトル | 内部リンク | 関連ポイント |
|---------|---------|-----------|-------------|
| 2025/12/14/183305.md | Perl WebSocket入門 | `/2025/12/14/183305/` | WebSocket実装 |
| 2025/12/17/000000.md | Perlでの非同期処理 | `/2025/12/17/000000/` | IO::Async, Mojo::IOLoop |
| 2025/12/29/185252.md | イベント駆動入門 | `/2025/12/29/185252/` | Mojo::Log, on/emit |
| 2025/12/04/000000.md | Mojolicious入門 | `/2025/12/04/000000/` | Webフレームワーク基礎 |

### 3.3 関連タグ

調査結果に基づく推奨タグ：

- `perl`
- `discord`
- `slack`
- `bot`
- `webhook`
- `event-driven`
- `websocket`
- `moo`
- `design-patterns`
- `observer`
- `command`
- `strategy`

---

## 4. 情報源リスト

### 4.1 公式ドキュメント

| リソース | URL |
|---------|-----|
| Discord Developer Portal | https://discord.com/developers/docs |
| Discord Rate Limits | https://discord.com/developers/docs/topics/rate-limits |
| Slack API | https://api.slack.com/ |
| Slack Events API | https://docs.slack.dev/apis/events-api/ |
| Mojolicious公式 | https://mojolicious.org/ |
| Mojo::EventEmitter | https://docs.mojolicious.org/Mojo/EventEmitter |

### 4.2 CPANリソース

| モジュール | URL |
|-----------|-----|
| Mojo::Discord | https://github.com/vsTerminus/Mojo-Discord |
| AnyEvent::SlackRTM | https://metacpan.org/dist/AnyEvent-SlackRTM |
| Net::Async::Slack | https://metacpan.org/pod/Net::Async::Slack |
| WebService::Slack::WebApi | https://metacpan.org/pod/WebService::Slack::WebApi |

### 4.3 日本語リソース

| リソース | URL |
|---------|-----|
| Mojolicious日本語ドキュメント | https://mojodoc.perlzemi.com/ |
| Mojo::Log日本語解説 | https://mojodoc.perlzemi.com/Mojo::Log.html |
| Webhook図解解説（Qiita） | https://qiita.com/HERUESTA/items/8a2a6e8a204e47db5a3b |
| イベント駆動型プログラミング（Wikipedia） | https://ja.wikipedia.org/wiki/イベント駆動型プログラミング |

### 4.4 参考書籍

| 書籍 | 著者 | 関連分野 |
|------|------|---------|
| Design Patterns: Elements of Reusable Object-Oriented Software | GoF | デザインパターン |
| Mastering Perl | brian d foy | Perl上級 |
| Learning Perl | Randal L. Schwartz他 | Perl基礎 |

---

## 5. 連載構造の提案材料

### 5.1 学習の推奨順序

前シリーズ（Moo OOP）との連携を考慮した学習順序：

```
[前提] Mooで覚えるOOP 第12回（型チェック）
    ↓
[第1回] Webhookで始める簡単Bot
    ↓
[第2回] REST APIでメッセージ送信
    ↓
[第3回] イベント駆動の考え方
    ↓
[第4回] Observerパターン
    ↓
[第5回] WebSocket接続
    ↓
[第6回] メッセージハンドラー
    ↓
[第7回] Commandパターン
    ↓
[第8回] Strategyパターン
    ↓
[第9回] リマインダー機能
    ↓
[第10回] エラー処理とレート制限
    ↓
[第11回] テストと品質
    ↓
[第12回] 完成と次のステップ
```

### 5.2 前シリーズとの連携ポイント

| Moo OOPシリーズ | Bot シリーズでの活用 |
|----------------|---------------------|
| has/subの基本 | ハンドラークラスの定義 |
| 継承（extends） | Botクラスの拡張 |
| ロール（with） | 共通機能の切り出し |
| 委譲（handles） | イベント処理の委譲 |
| 型制約 | コマンド引数の検証 |
| カプセル化 | 内部状態の保護 |

### 5.3 デザインパターン導入タイミング

| 回 | パターン | 導入理由 |
|---|---------|---------|
| 第4回 | Observer | イベント通知の基本として |
| 第6回 | Dispatcher | メッセージの振り分けに |
| 第7回 | Command | ボットコマンドのカプセル化 |
| 第8回 | Strategy | 応答パターンの切り替え |

### 5.4 Discord vs Slack の扱い

#### 推奨アプローチ

1. **Slack Webhookで開始**: 最もシンプル、環境構築が容易
2. **Discord Webhookへ横展開**: 類似概念で理解を深める
3. **Slack Events APIへ発展**: イベント駆動の本格導入
4. **Discord Gateway（WebSocket）**: リアルタイム通信の習得

#### 理由

- Slack Webhookは設定が容易で入門に最適
- 両プラットフォームの概念的類似性を活用
- 段階的に複雑性を上げることで理解を促進

---

## 6. 仮定と不明点

### 6.1 仮定

- 読者はMooでのクラス定義に習熟している
- Perl 5.20以降を使用（サブルーチンシグネチャ可）
- Discord/Slackのアカウント作成・管理はできる
- 基本的なHTTP通信の概念は理解している

### 6.2 不明点・今後の確認事項

1. **Mojo::Discord のメンテナンス状況**: 最終更新日と活発さの確認
2. **Slack RTM APIの将来性**: Events APIへの移行推奨度
3. **読者のBot開発経験レベル**: 完全初心者か経験者か
4. **実行環境の制約**: ローカル実行かクラウドデプロイか

---

## 7. 調査結果サマリー

### 7.1 主要な発見

1. **PerlでのBot開発記事は希少**: 日本語では競合がほぼなく、大きな差別化ポイント
2. **Mojoliciousエコシステムが有効**: Mojo::Discord、Mojo::IOLoopで統一的な実装が可能
3. **Webhookから始めるのが最適**: 最小構成で動作確認ができ、段階的に発展可能
4. **デザインパターンとの相性が良い**: Observer、Command、Strategyが自然に導入できる
5. **前シリーズとの連携が明確**: Moo OOPで学んだ概念がそのまま活用できる

### 7.2 推奨される連載構成

- **全12回構成**: 前シリーズと統一
- **Slack → Discord の順**: Webhookの容易さを活かす
- **イベント駆動を軸に**: 概念理解を優先
- **デザインパターンは段階的に**: 無理なく習得

### 7.3 次のステップ

1. 連載構造案の作成（3案：案A/B/C）
2. 各案のレビューと改善
3. 第1回のアウトライン作成
4. 記事執筆開始

---

**調査完了**: 2025年12月31日
**担当**: investigative-research エージェント
