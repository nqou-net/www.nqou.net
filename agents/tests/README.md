# シリーズ記事テスト状況

このディレクトリには、シリーズ記事のコード検証用テストが格納されています。

最終更新: 2026-01-20

## テスト状況一覧

### デザインパターン学習シリーズ（21シリーズ）

| パターン名 | シリーズタイトル | テスト済み |
|-----------|----------------|:----------:|
| Abstract Factory | Perlで作る注文フローの国別キット | ❌ |
| Adapter | 天気情報ツールで覚えるPerl | ✅ |
| Builder | PerlとMooで作るSQLクエリビルダー | ✅ |
| Chain of Responsibility | 架空ECサイトで学ぶ決済審査システム | ✅ |
| Chain of Responsibility | ユーザー登録バリデーションを学ぶ | ✅ |
| Command | Mooで作る簡易テキストエディタ | ✅ |
| Composite | PerlとMooで学ぶComposite - Markdown目次生成ツリー構造 | ✅ |
| Decorator | PerlとMooで学ぶDecorator - ログ解析パイプライン実装 | ✅ |
| Facade | PerlとMooでレポートジェネレーターを作ってみよう | ✅ |
| Factory Method | PerlとMooでAPIレスポンスシミュレーターを作ってみよう | ✅ |
| Iterator | 本棚アプリで覚える集合体の巡回 | ✅ |
| Memento | Mooを使ってゲームのセーブ機能を作ってみよう | ✅ |
| Observer | Perlでローグライク通知システムを作ろう | ✅ |
| Observer | Perlでハニーポット侵入レーダーを作ろう | ✅ |
| Prototype | PerlとMooでモンスター軍団を量産してみよう | ✅ |
| Proxy | Perlで作るブルートフォース攻撃シミュレータ | ❌ |
| Proxy | Mooで作るゴーストギャラリー・ビューワ | ✅ |
| Singleton | 設定ファイルマネージャーを作ってみよう | ✅ |
| State | Mooを使って自動販売機シミュレーターを作ってみよう | ✅ |
| Strategy | Mooを使ってデータエクスポーターを作ってみよう | ✅ |
| Template Method | PerlとMooでWebスクレイパーを作ってみよう | ✅ |

### 実践アプリケーション開発シリーズ（5シリーズ）

| カテゴリ | シリーズタイトル | テスト済み |
|---------|----------------|:----------:|
| Perl/Moo基礎 | Mooで覚えるオブジェクト指向プログラミング | ❌ |
| TDD | Perlで値オブジェクトを使ってテスト駆動開発してみよう | ❌ |
| CLIアプリ | シンプルなTodo CLIアプリ | ❌ |
| Webアプリ | Mooを使ってディスパッチャーを作ってみよう | ❌ |
| Webアプリ | URL短縮サポーター | ❌ |

## 統計

| カテゴリ | 総数 | テスト済み | 未テスト |
|---------|:----:|:----------:|:--------:|
| デザインパターン | 21 | 19 | 2 |
| 実践アプリ | 5 | 0 | 5 |
| **合計** | **26** | **19** | **7** |

## テストディレクトリ一覧

```
agents/tests/
├── api-response-simulator/       # Factory Method パターン
├── composite-markdown-toc/       # Composite パターン
├── config-file-manager/          # Singleton パターン
├── data-exporter/                # Strategy パターン
├── decorator-pattern-log-pipeline/ # Decorator パターン
├── ghost-gallery-viewer/         # Proxy パターン
├── honeypot-intrusion-radar/     # Observer パターン
├── iterator-pattern/             # Iterator パターン
├── mass-producing-monsters/      # Prototype パターン
├── moo-game-save/                # Memento パターン
├── payment-verification/         # Chain of Responsibility パターン
├── report-generator/             # Facade パターン
├── roguelike-notification-system/ # Observer パターン
├── simple-text-editor/           # Command パターン
├── sql-query-builder/            # Builder パターン
├── user-registration-validation/ # Chain of Responsibility パターン
├── vending-machine-simulator/    # State パターン
├── weather-tool/                 # Adapter パターン
└── web-scraper/                  # Template Method パターン
```
