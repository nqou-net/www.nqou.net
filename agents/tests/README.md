# シリーズ記事テスト状況一覧

最終更新: 2026-01-20 (Compositeパターン追加)

## 概要

全24シリーズのコード検証（テスト）状況を一覧化したレポートです。
テストディレクトリ（`agents/tests/`）の有無により、各シリーズのコード検証完了状況を確認できます。

---

## 統計サマリー

| 状況 | シリーズ数 | 割合 |
|------|-----------|------|
| ✅ テスト済み | 11 | 45.8% |
| ❌ 未テスト | 13 | 54.2% |
| **合計** | **24** | **100%** |

---

## デザインパターンシリーズ（20シリーズ）

### テスト済み（9シリーズ）

| パターン名 | シリーズタイトル | テストディレクトリ | 目次記事 |
|-----------|----------------|------------------|---------|
| Builder | PerlとMooで作るSQLクエリビルダー | [sql-query-builder](file:///Users/nobu/local/src/github.com/nqou-net/www.nqou.net-main/agents/tests/sql-query-builder) | [目次](/2026/01/20/002657/) |
| Chain of Responsibility | 架空ECサイトで学ぶ決済審査システム | [payment-verification](file:///Users/nobu/local/src/github.com/nqou-net/www.nqou.net-main/agents/tests/payment-verification) | [目次](/2026/01/10/221432/) |
| Composite | PerlとMooで学ぶComposite - Markdown目次生成ツリー構造 | [composite-markdown-toc](file:///Users/nobu/local/src/github.com/nqou-net/www.nqou.net-main/agents/tests/composite-markdown-toc) | [目次](/2026/01/20/003414/) |
| Decorator | PerlとMooで学ぶDecorator - ログ解析パイプライン実装 | [decorator-pattern-log-pipeline](file:///Users/nobu/local/src/github.com/nqou-net/www.nqou.net-main/agents/tests/decorator-pattern-log-pipeline) | [目次](/2026/01/19/211737/) |
| Facade (Factory Method) | PerlとMooでレポートジェネレーターを作ってみよう | [report-generator](file:///Users/nobu/local/src/github.com/nqou-net/www.nqou.net-main/agents/tests/report-generator) | [目次](/2026/01/12/230702/) |
| Memento | Mooを使ってゲームのセーブ機能を作ってみよう | [moo-game-save](file:///Users/nobu/local/src/github.com/nqou-net/www.nqou.net-main/agents/tests/moo-game-save) | [目次](/2026/01/13/233736/) |
| Observer | Perlでハニーポット侵入レーダーを作ろう | [honeypot-intrusion-radar](file:///Users/nobu/local/src/github.com/nqou-net/www.nqou.net-main/agents/tests/honeypot-intrusion-radar) | [目次](/2026/01/18/061505/) |
| Observer | Perlでローグライク通知システムを作ろう | [roguelike-notification-system](file:///Users/nobu/local/src/github.com/nqou-net/www.nqou.net-main/agents/tests/roguelike-notification-system) | [目次](/2026/01/16/004330/) |
| Proxy | Mooで作るゴーストギャラリー・ビューワ | [ghost-gallery-viewer](file:///Users/nobu/local/src/github.com/nqou-net/www.nqou.net-main/agents/tests/ghost-gallery-viewer) | [目次](/2026/01/17/231118/) |
| State | Mooを使って自動販売機シミュレーターを作ってみよう | [vending-machine-simulator](file:///Users/nobu/local/src/github.com/nqou-net/www.nqou.net-main/agents/tests/vending-machine-simulator) | [目次](/2026/01/10/001853/) |
| Strategy | Mooを使ってデータエクスポーターを作ってみよう | [data-exporter](file:///Users/nobu/local/src/github.com/nqou-net/www.nqou.net-main/agents/tests/data-exporter) | [目次](/2026/01/09/005530/) |
| Template Method | PerlとMooでWebスクレイパーを作ってみよう | [web-scraper](file:///Users/nobu/local/src/github.com/nqou-net/www.nqou.net-main/agents/tests/web-scraper) | [目次](/2026/01/19/002047/) |

### 未テスト（8シリーズ）

| パターン名 | シリーズタイトル | 回数 | 目次記事 |
|-----------|----------------|------|---------|
| Adapter | 天気情報ツールで覚えるPerl | 全7回 | [目次](/2026/01/07/223826/) |
| Command | Mooで作る簡易テキストエディタ | 全10回 | [目次](/2026/01/08/154030/) |
| Factory Method | PerlとMooでAPIレスポンスシミュレーターを作ってみよう | 全8回 | [目次](/2026/01/17/132411/) |
| Iterator | 本棚アプリで覚える集合体の巡回 | 全5回 | [目次](/2026/01/08/003843/) |
| Prototype | PerlとMooでモンスター軍団を量産してみよう | 全6回 | [目次](/2026/01/17/004454/) |
| Proxy | Perlで作るブルートフォース攻撃シミュレータ | 全5回 | [目次](/2026/01/14/004249/) |
| Singleton | 設定ファイルマネージャーを作ってみよう | 全8回 | [目次](/2026/01/08/033715/) |

---

## 実践アプリケーション開発シリーズ（5シリーズ）

### テスト済み（0シリーズ）

なし

### 未テスト（5シリーズ）

| カテゴリ | シリーズタイトル | 回数 | 目次記事 |
|---------|----------------|------|---------|
| Perl/Moo基礎 | Mooで覚えるオブジェクト指向プログラミング | 全12回 | [目次](/2026/01/02/233311/) |
| TDD | Perlで値オブジェクトを使ってテスト駆動開発してみよう | 全5回 | [目次](/2025/12/27/234517/) |
| CLIアプリ | シンプルなTodo CLIアプリ | 全10回 | [目次](/2026/01/04/011453/) |
| Webアプリ | Mooを使ってディスパッチャーを作ってみよう | 全12回 | [目次](/2026/01/03/002116/) |
| Webアプリ | URL短縮サポーター | 全12回 | [目次](/2026/01/04/210500/) |

---

## 推奨アクション

### 優先度：高

以下のシリーズは最近執筆されたものや、レビュー対象として言及されたものです：

1. **Factory Method** - PerlとMooでAPIレスポンスシミュレーターを作ってみよう（会話履歴で言及）
2. **Proxy** - Perlで作るブルートフォース攻撃シミュレータ（未テスト）
3. **Chain of Responsibility** - 架空ECサイトで学ぶ決済審査システム（構造案あり）

### テスト実施方法

各シリーズのテストを実施する場合は、以下のワークフローを使用してください：

```bash
/series-article-review
```

このワークフローは以下を自動実施します：
- コード抽出（`agents/tests/<slug>/<回番号>/` に保存）
- テストコード作成・実行
- 検証結果の記録（`walkthrough.md`）

---

## 備考

### テストディレクトリの命名規則

`agents/tests/` 内のディレクトリ名は、シリーズのslug（短縮名）を使用：
- `sql-query-builder` ← BuilderパターンのSQLクエリビルダー
- `decorator-pattern-log-pipeline` ← Decoratorパターンのログ解析パイプライン
- `web-scraper` ← Template MethodパターンのWebスクレイパー
- `honeypot-intrusion-radar` ← Observerパターンのハニーポット

### テスト済みシリーズの特徴

最近作成されたシリーズ（2026-01-19近辺）がテスト済みとなっており、
これはワークフロー改善により、執筆段階でテストを組み込む体制が整ってきたことを示しています。
