# AGENTS.md

本リポジトリのAIコーディングエージェント向けガイドです。

サイトURL: https://www.nqou.net

## プロジェクト概要

Hugoで構築された個人ブログサイト。Perl、ウイスキー、関西Perlコミュニティ（Kansai.pm）に関する技術記事や日常の記録を公開しています。

| 項目 | 技術 |
|------|------|
| 静的サイトジェネレータ | Hugo Extended（最新版） |
| テーマ | [hugo-theme-stack](https://github.com/CaiJimmy/hugo-theme-stack) v3 |
| ビルドツール | Perl（Daiku + カスタムスクリプト） |
| 言語 | Go 1.17+、Perl 5 |
| CI/CD | GitHub Actions → GitHub Pages |

## プロジェクト構成

```
.
├── config/_default/      # Hugo設定（TOML形式）
├── content/
│   ├── post/             # ブログ記事
│   └── page/             # 固定ページ（about, archives等）
├── layouts/
│   ├── shortcodes/       # カスタムショートコード
│   └── partials/head/    # カスタムヘッダ
├── assets/               # CSS、画像アセット
├── static/               # 静的ファイル
├── tools/                # Perlビルドスクリプト
├── docs/                 # ビルド出力先（自動生成・編集禁止）
└── .github/
    ├── workflows/        # GitHub Actionsワークフロー
    └── agents/           # AIエージェント関連ファイル（下記参照）

```

## .github/agents の目的と運用ルール

- 目的: リポジトリ内でAIエージェントが参照・利用する設定、プロンプトテンプレート、出力例を格納する専用ディレクトリ。
- 推奨ファイル構成例:
  - README.md             — エージェント向けの簡潔な運用ガイド
  - agent-config.yml      — 許可する操作・禁止事項の設定（例: ビルド実行禁止）
  - prompts/              — 記事作成用プロンプトテンプレート（公開可能なもの）
  - examples/             — プロンプトに対する期待出力の例
  - .gitignore            — logs/ や一時ファイルを除外する設定
- 重要ルール:
  - シークレットや認証情報をこのディレクトリに置かない（絶対にコミットしない）。
  - エージェントはビルドコマンドや外部コマンドを実行してはならない（参照のみ）。
  - 自動生成された記事は draft:true にする、もしくはユーザーが最終レビューするまで公開しない。
  - エージェントの出力・ログは基本的にコミットしない。必要な場合は個別に運用ルールを明記する。
  - agent-config.yml で許可されていない変更（設定ファイルの変更、docs/直編集など）は行わない。
- 運用の注意点:
  - 新しいプロンプトやテンプレートを追加する際は README.md に短い説明を付けること。

## カスタムエージェント

このリポジトリには、特定のタスクに特化したカスタムエージェントが用意されています。

### 技術記事執筆の専門家エージェント

#### perl-specialist (.github/agents/perl-specialist.agent.md)

Perlの専門家として、技術的に正確で詳細な記事原稿を作成します。

- **専門知識**: Perl 5.x、CPANモジュール、モダンPerl、Webフレームワーク
- **主な責務**: 
  - Perl技術記事の原稿作成（正確性・実用性重視）
  - 動作確認済みのコード例提供
  - CPANの活用とベストプラクティスの提示
- **得意分野**: リファレンス、正規表現、CPANエコシステム、モダンPerl、Kansai.pmコミュニティ
- **注意事項**: ビルドコマンド実行禁止、draft必須、技術的詳細を遠慮なく記述

#### ruby-specialist (.github/agents/ruby-specialist.agent.md)

Rubyの専門家として、技術的に正確で詳細な記事原稿を作成します。

- **専門知識**: Ruby 2.x/3.x、Rails/Sinatra、Gem開発、メタプログラミング
- **主な責務**:
  - Ruby技術記事の原稿作成（正確性・実用性重視）
  - 動作確認済みのコード例提供
  - Rubyコミュニティ標準のスタイルガイド準拠
- **得意分野**: ブロック/Proc/Lambda、Mix-in、Enumerable、メタプログラミング、Railsの哲学
- **注意事項**: ビルドコマンド実行禁止、draft必須、技術的詳細を遠慮なく記述

### 編集・構成の専門家エージェント

#### blog-writer (.github/agents/blog-writer.agent.md)

プロの編集者として、専門家の原稿を読みやすく魅力的なブログ記事に編集します。

- **専門スキル**: 記事構成、編集技術、SEO対策、読みやすさ向上、対象読者分析
- **主な責務**:
  - 専門家の原稿を読みやすいブログ記事に編集
  - 導入部・まとめの追加、適切な見出し階層の設定
  - 専門用語への補足説明追加（技術的正確性は維持）
  - Front matterの最適化（title、description、tags）
- **重要原則**: 技術的正確性を絶対に変更しない、専門家の内容を尊重
- **注意事項**: draft必須、ビルドコマンド実行禁止

## 協力型ブログ記事作成ワークフロー

専門家エージェント（perl-specialist、ruby-specialist等）とblog-writerエージェントが協力して、
技術的に正確かつ読みやすいブログ記事を作成するワークフローです。

### ワークフローの流れ

1. **フェーズ1: 専門家による原稿作成**
   - 使用エージェント: `perl-specialist` または `ruby-specialist`
   - 技術的に正確で詳細な原稿を作成
   - コード例は動作確認済み、専門用語は遠慮なく使用
   - バージョン情報や依存関係を明記

2. **フェーズ2: blog-writerによる編集**
   - 使用エージェント: `blog-writer`
   - 専門家の原稿を受け取り、読みやすく構成
   - 導入部・まとめを追加、見出し階層を整理
   - 専門用語に補足説明を追加（技術的内容は変更しない）
   - Front matterを作成（title、description、tags、draft: true）

### 利用方法

詳細なプロンプトテンプレートとサンプル出力は以下を参照してください：

- **プロンプトテンプレート**: `.github/agents/prompts/collaborative_writing.md`
  - フェーズ1（専門家）とフェーズ2（blog-writer）の指示テンプレート
  - 変数の説明と使用例
  
- **出力サンプル**: `.github/agents/examples/collaborative_output.md`
  - 専門家の原稿例（編集前）
  - blog-writerの編集後の記事例
  - 改善ポイントの解説

### 協力体制のメリット

- **技術的正確性**: 専門家が技術内容を保証
- **読みやすさ**: blog-writerが記事構成と表現を最適化
- **効率性**: 役割分担により高品質な記事を効率的に作成
- **一貫性**: 各エージェントの専門性を活かした一貫した品質

## Dos（やるべきこと）

- `content/post/` 配下にMarkdownファイルを作成する
- 新規記事のファイル名は `<epoch秒>.md` 形式で作成する
- front matterには必須項目（title, description, tags, draft）をすべて含める
- 新規記事の `draft` は必ず `true` に設定する（公開判断はユーザーのみ）

## Don'ts（禁止事項）

- `docs/` ディレクトリを編集しない（ビルド出力先）
- `hugo`、`daiku` などのビルドコマンドを実行しない
- `draft: false` に変更しない（ユーザーのみが変更可能）
- 設定ファイル（config/, go.mod等）を無断で変更しない
- 他者の著作物を無断転載しない
- 個人の機微情報や秘密情報を含めない

## ショートコード

| ショートコード | 用途 | 引数 |
|---------------|------|------|
| `amazon` | Amazon商品リンク | asin, title |
| `gist` | GitHub Gist埋め込み | （Hugo v0.143.0以降は非推奨） |
| `linkcard` | ウェブサイトへのリンクカード（OGP自動取得） | url |
| `x` | X/Twitter埋め込み | user, id |

## Hugo互換性

Hugo 0.131以降の破壊的変更に注意：

1. `permalinks.toml` には `[page]` セクションが必要
2. Hugo 0.144.0 で `:filename` トークンが非推奨 → `:contentbasename` を使用

## ビルドコマンド（参考情報）

> **注意**: エージェントはビルドコマンドを実行しないでください。ビルドはGitHub Actionsが自動実行します。

```bash
hugo server -D              # 開発サーバー（ドラフト含む）
hugo --minify --gc          # 本番ビルド
perl tools/build.pl && hugo # Perl前処理付きビルド
```

## Perl依存関係

```bash
cpanm --installdeps .
```

必要なモジュール: Path::Tiny, Time::Moment, YAML
