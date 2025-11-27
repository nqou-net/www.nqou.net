# AGENTS.md

本リポジトリ（https://www.nqou.net/）のAIコーディングエージェント向けガイドです。

## プロジェクト概要

Hugoで構築された個人ブログサイト。Perl、ウイスキー、関西Perlコミュニティ（Kansai.pm）に関する技術記事や日常の記録を870以上の記事として公開しています。

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
│   ├── post/             # ブログ記事（YYYY/MM/DD/HHMMSS.md）
│   └── page/             # 固定ページ（about, archives等）
├── layouts/
│   ├── shortcodes/       # カスタムショートコード
│   └── partials/head/    # カスタムヘッダ
├── assets/               # CSS、画像アセット
├── static/               # 静的ファイル
├── tools/                # Perlビルドスクリプト
├── docs/                 # ビルド出力先（自動生成・編集禁止）
└── .github/              # ワークフロー・指示ファイル
```

## ビルドコマンド（参考情報）

> **注意**: エージェントはビルドコマンドを実行しないでください。ビルドはGitHub Actionsが自動実行します。

```bash
hugo server -D              # 開発サーバー（ドラフト含む）
hugo --minify --gc          # 本番ビルド
perl tools/build.pl && hugo # Perl前処理付きビルド
```

## Dos（やるべきこと）

- `content/post/`配下にMarkdownファイルを作成する
- 新規記事のファイル名は`<epoch秒>.md`形式で作成する
- front matterに必須項目（title, description, tags, draft）を含める
- `draft: true`を新規記事に必ず設定する（公開判断はユーザーのみ）
- Hugoショートコードを適切に使用する
  - `amazon`: Amazon商品リンク（asin, title引数）
  - `x`: X/Twitter埋め込み（user, id引数）
- ブログ記事作成時は`.github/instructions/post.instructions.md`を参照する

## Don'ts（禁止事項）

- `docs/`ディレクトリを編集しない（ビルド出力先）
- `hugo`、`daiku`などのビルドコマンドを実行しない
- `draft: false`に変更しない（ユーザーのみが変更可能）
- 設定ファイル（config/, go.mod等）を無断で変更しない
- 他者の著作物を無断転載しない
- 個人の機微情報や秘密情報を含めない

## コードスタイル

### front matter形式

```yaml
---
comments: true
description: "記事の短い説明（100文字以内）"
draft: true
hidden: false
tags:
  - perl
  - life
title: "記事タイトル"
---
```

**自動設定項目**（build.plが処理）:
- `date`: ISO 8601形式で自動設定
- `iso8601`: 同上

### ファイル命名規則

| 状態 | ファイル名形式 |
|------|---------------|
| 新規作成時 | `content/post/<epoch秒>.md` |
| 公開後（自動リネーム） | `content/post/YYYY/MM/DD/HHMMSS.md` |

### ショートコード

| ショートコード | 用途 | 引数 |
|---------------|------|------|
| `amazon` | Amazon商品リンク | asin, title |
| `gist` | GitHub Gist埋め込み | （Hugo v0.143.0以降は非推奨） |
| `x` | X/Twitter埋め込み | user, id |

## Hugo互換性

Hugo 0.131以降の破壊的変更に注意：

1. `permalinks.toml`には`[page]`セクションが必要
2. Hugo 0.144.0で`:filename`トークンが非推奨 → `:contentbasename`を使用

## Perl依存関係

```bash
cpanm --installdeps .
```

必要なモジュール: Path::Tiny, Time::Moment, YAML
