# www.nqou.net - コーディングエージェント向けガイド

## プロジェクト概要

本リポジトリは、Hugoで構築された個人ブログサイト（https://www.nqou.net/）です。Perl、ウイスキー、関西Perlコミュニティ（Kansai.pm）に関する技術記事や日常の記録を870以上の記事として公開しています。

## 技術スタック

- **静的サイトジェネレータ**: Hugo Extended（最新版を推奨）
- **テーマ**: [hugo-theme-stack](https://github.com/CaiJimmy/hugo-theme-stack) v3（Go Modulesで管理）
- **ビルドツール**: Perl（Daiku + カスタムスクリプト）
- **言語**: Go 1.17+、Perl 5
- **CI/CD**: GitHub Actions（GitHub Pagesへ自動デプロイ）

## プロジェクト構成

```
.
├── config/_default/      # Hugo設定ファイル（TOML形式）
│   ├── config.toml       # 基本設定（baseurl, publishDir等）
│   ├── params.toml       # サイトパラメータ
│   ├── permalinks.toml   # URL構造定義
│   └── module.toml       # テーマモジュール設定
├── content/
│   ├── post/             # ブログ記事（YYYY/MM/DD/HHMMSS.md形式）
│   └── page/             # 固定ページ（about, archives等）
├── layouts/
│   ├── shortcodes/       # カスタムショートコード（amazon, gist, x）
│   └── partials/head/    # カスタムヘッダ（フォント、広告）
├── assets/               # CSS、画像アセット
├── static/               # 静的ファイル
├── tools/                # Perlビルドスクリプト
│   ├── build.pl          # 記事のfront matter処理・ファイル名変更
│   ├── add_descriptions.py   # description自動生成
│   └── convert_html_to_markdown.pl  # HTML→Markdown変換
├── Daikufile             # Perlビルドタスク定義
├── cpanfile              # Perl依存関係
├── docs/                 # ビルド出力先（編集禁止・自動生成）
└── .github/workflows/    # CI/CDワークフロー
```

## ビルド・開発コマンド（参考情報）

以下はビルドコマンドの参考情報です。**エージェントはこれらのコマンドを実行しないでください。** ビルドはGitHub Actionsが自動で実行します。

```bash
# Hugo開発サーバー起動（ドラフト含む）
hugo server -D

# 本番ビルド
hugo --minify --gc

# Perl前処理付きビルド（推奨）
perl tools/build.pl && hugo --logLevel=info

# Daikuタスク経由
daiku build     # 前処理+Hugoビルド
daiku server    # 開発サーバー
daiku new       # 新規記事作成
daiku drafts    # ドラフト一覧
```

## 重要な注意事項

### エージェントの制限事項
- **`docs/`ディレクトリは編集禁止**: ビルド出力先のため、エージェントは編集しないでください
- **ビルドコマンドは実行禁止**: `hugo`、`daiku`などのビルドコマンドはエージェントは実行しないでください。ビルドはCI/CDが自動で行います

### Hugo互換性（Hugo 0.131+）
Hugo 0.131以降でいくつかの破壊的変更があります：

1. **permalinks.toml形式の変更**: `[page]`セクションが必要
2. **permalinkトークンの変更**: Hugo 0.144.0で`:filename`トークンが非推奨となり、`:contentbasename`を使用する必要がある

### ショートコード
- `amazon`: Amazon商品リンク（asin, title引数）
- `gist`: GitHub Gist埋め込み（Hugo v0.143.0以降は非推奨）
- `x`: X/Twitter埋め込み（user, id引数）

### front matter形式
記事のfront matterは以下の形式を使用：
```yaml
---
comments: true
date: 2024-08-29T23:14:12+09:00
description: "短い説明（100文字以内）"
draft: false
hidden: false
iso8601: 2024-08-29T23:14:12+09:00
tags:
  - perl
  - life
title: "記事タイトル"
---
```

### ファイル命名規則
- 新規記事: `content/post/<epoch秒>.md`
- 公開後: `tools/build.pl`により`YYYY/MM/DD/HHMMSS.md`形式に自動リネーム

## Perl依存関係のインストール

```bash
# cpanmインストール後
cpanm --installdeps .
```

必要なモジュール: Path::Tiny, Time::Moment, YAML

---

# バイブブロギング用アシスタントガイド

以下は、ブログ記事を生成・改善する際のガイドラインです。出力は原則すべて日本語で行います。

## 文体と表記ルール
- 通常文はですます調で書く
- 箇条書きは断言調で句点を付けない
- 見出しは自然な日本語にするが本文はですます調を維持する
- 用語は統一して使う（例：「プロンプト」「再プロンプト」「事実確認」）

## 記事作成ワークフロー
1. **設計**: 目的・読者・構成・制約・検証ポイントの5要素をテンプレ化
2. **生成**: テンプレでMarkdown草稿を生成
3. **評価**: トーン・事実性・カバレッジで評価し差分指示を作成
4. **再プロンプト**: 差分を反映した短い再プロンプトで再生成
5. **仕上げ**: 事実確認・引用チェック・SEO調整を行い公開用YAMLを付与
6. **反復改善**: 追加情報や補完要求に応じて記事を拡張

## YAML front matter

### 含める項目
- comments: true
- description: "<短い説明（100文字以内）>"
- draft: false
- hidden: false
- image: / license: / math: （必要に応じて）
- tags: （1〜3個、小文字で統一）
- title: "<記事タイトル>"

### 含めない項目
- date（build.plが自動設定）
- iso8601（build.plが自動設定）

## タグ付与の方針
- **技術系**: perl, programming, web, javascript, git, docker, linux, windows, macos
- **ブログ/CMS**: wordpress, movabletype, hexo, hugo, markdown
- **ソーシャル**: social（Twitter/Facebook/SNS関連）
- **日常**: life, meals, game, favorites, lifestyle
- **コミュニティ**: yapc, kansaipm
- **AI関連**: ai, copilot, プロンプト設計, ブログ作成

## 品質チェック
記事生成後は以下を確認：
- 事実確認が必要な箇所（検索キーワードまたは参考URLを添える）
- 引用候補の提示
- SEO改善提案（見出し・メタ説明・キーワード）
- 人間レビューで確認すべき点（倫理・法務・オリジナリティ）
- 脚注セクションに「本記事はバイブブロギングで作成しています」を含める

## 禁止事項
- 他者の著作物を無断転載しない
- 個人の機微情報や秘密情報を含めない
- 法令や倫理に抵触する表現を出さない
- ユーザーの明示的許可なくファイルを公開しない
