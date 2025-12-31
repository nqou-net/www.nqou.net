---
title: '連載構造案 - Discord / Slack ボットを作ってみよう（全12回）'
draft: true
description: シリーズ記事「Discord / Slack ボットを作ってみよう」の連載構造案3つ（案A/B/C）。Webhook、API、イベント駆動、デザインパターンを段階的に学ぶ。
---

# 連載構造案：Discord / Slack ボットを作ってみよう

**調査結果**: `content/warehouse/discord-slack-bot-series-research.md` に基づく

---

## 前提情報

| 項目 | 内容 |
|------|------|
| **テーマ** | Discord / Slack ボット |
| **学習内容** | Webhook、API、イベント駆動の考え方。特定のキーワードに反応して返信したり、リマインダーを投げたりする |
| **ゴール** | 自然に覚えるデザインパターン |
| **技術スタック** | Perl |
| **想定読者** | Perl入学式卒業程度、前シリーズ「Mooで覚えるオブジェクト指向プログラミング」第12回を読了 |
| **制約** | 各回コード例2つまで、新しい概念1つまで |

---

## 案A: 「Webhookファースト」アプローチ

### 特徴・アプローチ

最もシンプルなWebhookから始め、徐々にREST API、イベント駆動、WebSocketへと複雑性を上げていく構成です。「まず動かす」を最優先にし、成功体験を積み重ねながら概念を習得します。

**メリット**:
- 最小構成で動作確認でき、達成感が早い
- Webhook → API → WebSocketと技術的難易度が段階的に上昇
- Slackの設定が容易で入門に最適

**デメリット**:
- デザインパターンの導入が後半に偏る
- 前半がシンプルすぎて物足りなさを感じる読者もいるかもしれない

### 前シリーズ（Moo OOP）の知識活用

| 回 | 活用するMooの知識 |
|---|------------------|
| 2 | クラス定義（`has`/`sub`）で送信関数をカプセル化 |
| 6 | `Moo::Role`でObservableロールを定義 |
| 8-10 | 継承（`extends`）でパターンを実装 |

### 連載構造

| 回 | タイトル | 新しい概念 | ストーリー | コード例1 | コード例2 | 推奨タグ |
|---|---------|-----------|-----------|----------|----------|---------|
| 1 | 第1回-Perl×Slack Bot入門 - 5分で動くWebhook | Incoming Webhook | 開発チームのSlackに「朝の挨拶Bot」を作る。LWP::UserAgentでWebhookにPOST | `LWP::UserAgent->new->post($url, ...)` | `encode_json({ text => 'おはよう!' })` | perl, slack, webhook |
| 2 | 第2回-Discord Webhookへ横展開しよう | Discord Webhook | SlackBotをDiscordにも対応。Mooクラスで送信処理を共通化 | `Webhook->new(url => $url)->send($msg)` | Slack/Discordの差異を吸収するクラス設計 | perl, discord, webhook |
| 3 | 第3回-REST APIでメッセージ履歴を取得する | REST API（GET） | 過去のメッセージを取得して分析。Slack Web APIの`conversations.history` | `$ua->get($api_url)->result->json` | 認証ヘッダー（Bearer Token）の設定 | perl, slack, rest-api |
| 4 | 第4回-メッセージを送信・編集・削除する | REST API（POST/PATCH） | 投稿したメッセージを後から編集・削除。chat.postMessage/update/delete | `chat.postMessage`でメッセージ送信 | `chat.update`でメッセージ編集 | perl, slack, rest-api |
| 5 | 第5回-イベントループ入門 - 待ち受けの技術 | イベントループ | 「待ち受けて反応する」という考え方。Mojo::IOLoopの基本 | `Mojo::IOLoop->recurring(60 => sub {...})` | 定期実行するリマインダーBot | perl, event-driven, mojo |
| 6 | 第6回-Observerパターンで複数ハンドラーに通知 | Observerパターン | 複数のハンドラーにイベントを通知。Moo::Roleでイベント発行者を定義 | `Subject`クラス（attach/detach/notify） | `Observer`ロール（update） | perl, observer, design-patterns |
| 7 | 第7回-WebSocket入門 - Discord Gateway接続 | WebSocket接続 | Discord Gatewayに接続してリアルタイムでメッセージを受信 | `$ua->websocket($gateway => sub {...})` | `$ws->on(message => sub {...})` | perl, websocket, discord |
| 8 | 第8回-Dispatcherパターンでハンドラー振り分け | Dispatcherパターン | 受信したメッセージを適切なハンドラーに振り分ける | `Dispatcher->new->register('hello' => $handler)` | `$dispatcher->dispatch($event)` | perl, dispatcher, design-patterns |
| 9 | 第9回-Commandパターンでボットコマンド整理 | Commandパターン | `/remind`や`/help`などのコマンドをオブジェクト化 | `Command`基底クラス（execute） | `RemindCommand extends Command` | perl, command, design-patterns |
| 10 | 第10回-Strategyパターンで応答を動的に切り替え | Strategyパターン | 時間帯やユーザーによって応答パターンを動的に変更 | `ResponseStrategy`ロール（respond） | `MorningStrategy`/`NightStrategy` | perl, strategy, design-patterns |
| 11 | 第11回-レート制限対応とエラーハンドリング | エラーハンドリング | Discord APIのレート制限に対応。リトライとバックオフ | `X-RateLimit-Remaining`ヘッダー解析 | エクスポネンシャルバックオフの実装 | perl, rate-limit, error-handling |
| 12 | 第12回-完成！デザインパターン総まとめ | 設計の振り返り | 全体を振り返り、学んだデザインパターンを整理。次のステップへ | 完成したBotの構成図（mermaid） | パターン適用前後のコード比較 | perl, bot, design-patterns |

---

## 案B: 「デザインパターン中心」アプローチ

### 特徴・アプローチ

各回で1つのデザインパターンを主役に据え、Bot開発はそのパターンを実装する題材として使う構成です。「デザインパターンを自然に覚える」というゴールに最も直接的にアプローチします。

**メリット**:
- デザインパターンの習得が確実
- パターンの適用場面が明確で、後から応用しやすい
- 前シリーズ（Moo OOP）で学んだ知識を活かしやすい

**デメリット**:
- パターンに合わせてストーリーを組むため、やや人工的な展開になる可能性
- Bot開発の全体像が見えにくい序盤

### 前シリーズ（Moo OOP）の知識活用

| 回 | 活用するMooの知識 |
|---|------------------|
| 2-7 | 各パターンでクラス設計、継承、ロールを活用 |
| 10 | Decoratorで継承とコンポジションの使い分け |
| 全回 | `has`による属性定義、型制約 |

### 連載構造

| 回 | タイトル | 新しい概念 | ストーリー | コード例1 | コード例2 | 推奨タグ |
|---|---------|-----------|-----------|----------|----------|---------|
| 1 | 第1回-Botの世界へようこそ - 最小構成で動かす | Webhook基礎 | まずは動くものを作る。Slack Incoming Webhookで「Hello Bot!」 | `LWP::UserAgent->new->post(...)` | `encode_json({ text => 'Hello!' })` | perl, slack, webhook |
| 2 | 第2回-Singletonパターン - Bot設定を一元管理 | Singletonパターン | Bot設定（トークン、チャンネル）を一箇所で管理。環境変数から読み込み | `Config->instance->token` | `$ENV{BOT_TOKEN}`からの読み込み | perl, singleton, design-patterns |
| 3 | 第3回-Factoryパターン - メッセージを生産する | Factoryパターン | 様々な種類のメッセージ（テキスト、リッチ、添付ファイル）を生成 | `MessageFactory->create('rich', ...)` | `TextMessage`/`RichMessage`クラス | perl, factory, design-patterns |
| 4 | 第4回-Observerパターン - イベントを複数に通知 | Observerパターン | メッセージ受信時に複数のハンドラーへ通知 | `EventEmitter`クラス（on/emit） | Observer登録と`notify`呼び出し | perl, observer, design-patterns |
| 5 | 第5回-Strategyパターン - 応答方法を切り替える | Strategyパターン | ユーザーの設定に応じて応答パターンを変更 | `ResponseStrategy`ロール | `FormalStrategy`/`CasualStrategy` | perl, strategy, design-patterns |
| 6 | 第6回-Commandパターン - コマンドをオブジェクト化 | Commandパターン | `/help`、`/remind`などをCommandオブジェクトとして実装 | `Command`基底クラス（execute） | `HelpCommand`/`RemindCommand` | perl, command, design-patterns |
| 7 | 第7回-Dispatcherパターン - メッセージを振り分ける | Dispatcherパターン | 受信メッセージを適切なCommandに振り分ける | `Dispatcher->dispatch($event)` | ルーティングテーブルの定義 | perl, dispatcher, design-patterns |
| 8 | 第8回-イベントループ入門 - 待ち受けの技術 | イベントループ | Mojo::IOLoopで非同期処理。定期リマインダーの実装 | `Mojo::IOLoop->recurring(...)` | タイマーイベント処理 | perl, event-loop, mojo |
| 9 | 第9回-WebSocket接続 - リアルタイム通信 | WebSocket | Discord Gatewayへ接続、Heartbeat処理 | `$ua->websocket($gateway => ...)` | Gateway接続とHeartbeat送信 | perl, websocket, discord |
| 10 | 第10回-Decoratorパターン - 機能を後付けする | Decoratorパターン | メッセージにタイムスタンプ追加、ログ出力などを動的に付与 | `MessageDecorator`基底クラス | `TimestampDecorator`/`LogDecorator` | perl, decorator, design-patterns |
| 11 | 第11回-エラーハンドリングとリトライ戦略 | レート制限対応 | APIレート制限、ネットワークエラーへの対処 | `try/catch`とリトライロジック | エクスポネンシャルバックオフ | perl, error-handling, rate-limit |
| 12 | 第12回-これがデザインパターンだ！総まとめ | 総まとめ | 学んだパターンの関係性を整理、応用への道筋 | 完成Botのクラス図（mermaid） | パターンカタログと使い分け | perl, design-patterns, bot |

---

## 案C: 「実用Bot開発」アプローチ

### 特徴・アプローチ

「チームで使えるリマインダーBot」を最終成果物として設定し、各回でその機能を1つずつ実装していく構成です。実用的なゴールを意識しながら、必要に応じてデザインパターンを導入します。

**メリット**:
- 明確なゴール（実用的なBot）があり、モチベーションを維持しやすい
- 実際の開発で直面する課題を順に解決していく流れが自然
- 完成したBotをそのまま使える

**デメリット**:
- 機能実装に偏り、デザインパターンの説明が浅くなる可能性
- リマインダー以外のユースケースへの応用が見えにくい

### 前シリーズ（Moo OOP）の知識活用

| 回 | 活用するMooの知識 |
|---|------------------|
| 4-5 | クラス設計でデータ永続化を抽象化 |
| 7-8 | ロールとStrategyパターンでプラットフォーム抽象化 |
| 11 | 継承でWeb UIコントローラーを設計 |

### 連載構造

| 回 | タイトル | 新しい概念 | ストーリー | コード例1 | コード例2 | 推奨タグ |
|---|---------|-----------|-----------|----------|----------|---------|
| 1 | 第1回-リマインダーBotを作ろう - Webhook入門 | Webhook入門 | チームで使うリマインダーBotの構想。まずは手動でメッセージを送る | `LWP::UserAgent->post($webhook_url, ...)` | 設定ファイル（config.yaml）の読み込み | perl, slack, webhook |
| 2 | 第2回-定期実行 - 毎朝の挨拶を自動化する | イベントループ | cronではなくPerl内でスケジュール実行。Mojo::IOLoop::recurring | `Mojo::IOLoop->recurring(3600 => ...)` | 時刻判定と条件分岐 | perl, event-loop, scheduler |
| 3 | 第3回-Slack Events APIでコマンドを受け付ける | Events API | `/remind 10分後 会議開始`のようなコマンドを受け付ける | `Mojolicious::Lite`でエンドポイント作成 | リクエスト署名の検証 | perl, slack, events-api |
| 4 | 第4回-Commandパターンでコマンドを解析する | Commandパターン | 受け取ったコマンド文字列を解析してオブジェクト化 | `RemindCommand`クラス（parse/execute） | コマンド引数のパースロジック | perl, command, design-patterns |
| 5 | 第5回-リマインダーを保存する - データ永続化 | ファイル/DB保存 | 設定したリマインダーをファイルに保存・読み込み | `encode_json`/`decode_json`でファイル保存 | `Reminder`クラスとシリアライズ | perl, persistence, json |
| 6 | 第6回-時間になったら通知 - スケジューラー実装 | タイマー管理 | 保存されたリマインダーを監視し、時刻になったら通知 | `Mojo::IOLoop->timer($delay => ...)` | リマインダー発火と削除ロジック | perl, scheduler, timer |
| 7 | 第7回-Observerパターンで複数ユーザーに通知 | Observerパターン | ユーザーごとにリマインダーを管理、複数人への同時通知 | `UserReminder`クラス | 通知先リストへの一斉送信 | perl, observer, design-patterns |
| 8 | 第8回-Strategyパターンで Discord対応する | Strategyパターン | 同じリマインダーをSlack/Discord両方に対応させる | `NotificationStrategy`ロール | `SlackNotifier`/`DiscordNotifier` | perl, strategy, design-patterns |
| 9 | 第9回-Discord Gateway接続 - リアルタイム機能 | WebSocket | Discord上でもリアルタイムにコマンドを受け付ける | `$ua->websocket($gateway => ...)` | メッセージイベントの処理 | perl, websocket, discord |
| 10 | 第10回-エラーに強いBotにする | エラーハンドリング | ネットワーク切断、API制限への対応 | 再接続ロジック（try/catch） | レート制限への対応 | perl, error-handling, resilience |
| 11 | 第11回-設定画面を作る - Mojolicious Web UI | Mojolicious Web UI | ブラウザからリマインダーを設定できるWeb画面 | `Mojolicious::Lite`で画面作成 | テンプレートとフォーム処理 | perl, mojolicious, web-ui |
| 12 | 第12回-完成！リマインダーBotの運用と発展 | 総まとめ | リマインダーBotの完成形、テスト方法、今後の発展 | 完成Botの構成図（mermaid） | デプロイと運用のTips | perl, bot, deployment |

---

## 推薦案：案A「Webhookファースト」アプローチ

### 推薦理由

#### 1. ペルソナとの適合性

- **想定読者**は「Perl入学式卒業程度」「前シリーズ（Moo OOP）読了」
- 案Aは最もシンプルなWebhookから始まり、成功体験を積み重ねられる
- 「まず動かす」体験が、Bot開発へのモチベーションを高める

#### 2. 学習曲線の最適化

- Webhook（HTTPリクエスト）→ REST API → イベントループ → WebSocket と段階的に複雑化
- 各ステップで前回の知識を活用できる構成
- デザインパターンは後半にまとめて導入し、必要性を実感した上で学べる

#### 3. 調査結果との整合性

- 調査で「Slack Webhookで開始 → Discord Webhookへ横展開」を推奨
- 案Aはこの推奨に最も忠実

#### 4. 検索意図への適合

- 「Perl Slack Bot」「Perl Discord Bot」で検索するユーザーは、まず動くものを求めている
- 案Aは第1回で動くBotが完成し、検索ニーズに応える
- タイトルに「入門」「Webhook」などのキーワードを含め、SEOにも配慮

#### 5. 前シリーズとの連携

- 第2回以降でMooクラス設計を活用
- 第6回以降でMoo::Roleを使ったデザインパターン実装
- OOPの知識を「実践で使う」経験ができる

### 代替案の選択指針

- **案B**: デザインパターンの習得を最優先したい場合、前シリーズ（Moo OOP）の延長として学びたい読者向け
- **案C**: 具体的な成果物（リマインダーBot）を作りたい場合、実用性を重視する読者向け

---

## 各案の差別化ポイント

| 観点 | 案A: Webhookファースト | 案B: デザインパターン中心 | 案C: 実用Bot開発 |
|------|----------------------|------------------------|-----------------|
| **主眼** | 技術スタック習得 | デザインパターン習得 | 機能実装・実用性 |
| **動機付け** | 「動くもの」への喜び | 「美しい設計」への理解 | 「使えるBot」の完成 |
| **パターン導入** | 後半集中（第6-10回） | 全体に分散（第2-10回） | 必要に応じて（第4,7,8回） |
| **難易度曲線** | 緩やか→急上昇 | 一定ペース | 緩やか→やや急 |
| **応用性** | 高（汎用的な技術習得） | 高（パターン知識） | 中（リマインダー特化） |
| **完成物** | 汎用Botフレームワーク | パターン集付きBot | 実用リマインダーBot |

---

## 難易度一覧

### 案A: Webhookファースト

| 回 | 難易度 | 前提知識 |
|---|-------|---------|
| 1-2 | ★☆☆☆☆ | HTTPの基本 |
| 3-4 | ★★☆☆☆ | REST APIの概念 |
| 5-6 | ★★★☆☆ | イベント駆動の基礎 |
| 7-8 | ★★★★☆ | WebSocket、非同期処理 |
| 9-11 | ★★★★☆ | OOP、デザインパターン |
| 12 | ★★★☆☆ | 振り返り |

### 案B: デザインパターン中心

| 回 | 難易度 | 前提知識 |
|---|-------|---------|
| 1 | ★☆☆☆☆ | HTTPの基本 |
| 2-7 | ★★★☆☆ | OOP、クラス設計 |
| 8-9 | ★★★★☆ | 非同期処理、WebSocket |
| 10-11 | ★★★★☆ | パターン応用 |
| 12 | ★★★☆☆ | 振り返り |

### 案C: 実用Bot開発

| 回 | 難易度 | 前提知識 |
|---|-------|---------|
| 1-2 | ★★☆☆☆ | HTTPの基本、イベントループ |
| 3-4 | ★★★☆☆ | Webサーバー、OOP |
| 5-6 | ★★☆☆☆ | ファイルI/O |
| 7-8 | ★★★☆☆ | デザインパターン |
| 9-10 | ★★★★☆ | WebSocket、エラー処理 |
| 11-12 | ★★★☆☆ | Webアプリ |

---

## 内部リンク候補

調査結果で特定された関連記事へのリンク候補：

### 前シリーズとの連携

| 参照先 | 内部リンク | 参照タイミング |
|-------|-----------|--------------|
| Mooで覚えるOOP 第1回 | `/2021/10/31/191008/` | 第1回導入部 |
| Mooで覚えるOOP 第2回 | `/2025/12/30/163810/` | クラス設計時 |
| Mooで覚えるOOP 第12回（型チェック） | `/2025/12/30/163820/` | 第1回導入部（前提） |

### 技術関連

| 参照先 | 内部リンク | 参照タイミング |
|-------|-----------|--------------|
| Perl WebSocket入門 | `/2025/12/14/183305/` | 第7回（WebSocket） |
| Perlでの非同期処理 | `/2025/12/17/000000/` | 第5回（イベントループ） |
| イベント駆動入門 | `/2025/12/29/185252/` | 第5-6回 |
| Mojolicious入門 | `/2025/12/04/000000/` | 第3回以降 |

### 関連シリーズ

| 参照先 | 内部リンク | 参照タイミング |
|-------|-----------|--------------|
| ディスパッチャー第1回 | `/2025/12/30/164001/` | 第8回（Dispatcher） |
| これがデザインパターンだ！ | `/2025/12/30/164012/` | 第12回（まとめ） |

---

## 付記

- 各タイトルは「第N回-」で始める形式（前シリーズと統一）
- 推奨タグは3つ程度、英語小文字・ハイフン形式
- 全12回を通じて、Botが徐々に高機能化していくストーリー
- 前シリーズ（Moo OOP）で学んだ概念（クラス、継承、ロール）を自然に活用

---

## 改善履歴

### 第1版

**作成日**: 2025年12月31日
**担当**: perl-monger エージェント

初版作成。調査結果に基づき3つのアプローチを提案。

### 第2版

**作成日**: 2025年12月31日
**担当**: perl-monger エージェント

**改善内容**:

1. **SEO改善**: 案Aの第1回タイトルを「Perl×Slack Bot入門」に変更し、検索キーワードを強化
2. **コード例の具体化**: 各回のコード例をより具体的なスニペット形式に変更
3. **前シリーズ連携の明示**: 各案に「前シリーズ（Moo OOP）の知識活用」表を追加
4. **タイトルの統一感**: 各回のタイトルを「第N回-○○ - △△」形式に統一
5. **推薦理由の補強**: 「前シリーズとの連携」を推薦理由に追加

**残課題**:
- 各案の差別化をより明確にする
- 難易度の段階性を再確認

### 第3版（最終版）

**作成日**: 2025年12月31日
**担当**: perl-monger エージェント

**改善内容**:

1. **差別化ポイント表の追加**: 各案の独自性を比較表で明示
2. **難易度一覧の追加**: 各回の難易度を★で表示し、前提知識を明記
3. **内部リンク候補の追加**: 調査結果で特定された関連記事へのリンク候補を整理
4. **品質基準の確認**: 1記事1概念、段階的難易度、前シリーズ連携を全案で確認

**最終確認チェックリスト**（連載構造案の品質基準に基づく確認）:

- [x] 全案に「特徴・アプローチ」（メリット・デメリット）が記載されている
- [x] 全案に「連載構造表」（回数、タイトル、新概念、ストーリー、コード例、タグ）が記載されている
- [x] 各案の差別化ポイントが明示されている
- [x] 推薦案とその理由が記載されている
- [x] 1記事1概念の原則が守られている
- [x] 段階的難易度が設計されている
- [x] 前シリーズとの連携が明記されている
- [x] 調査結果への参照が記載されている

---
