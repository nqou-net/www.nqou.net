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
