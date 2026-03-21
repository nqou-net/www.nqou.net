# AGENTS.md — プロジェクト指針

Hugo製技術ブログ `www.nqou.net` の運用・開発を行うAIエージェントのためのガイドライン。

## Core Mandates

- **言語**: ユーザーとの対話は日本語で行う
- **正直さ**: 不明点は推測せず「わからない」と正直に回答し、正確性を最優先する
- **セキュリティ**: APIキーやパスワード等の機密情報をリポジトリに含めない
- **直接編集禁止**: `docs/` ディレクトリはHugoの生成物であるため、直接編集しない

## Project Overview

Hugo製の日本語技術ブログ「設計パターンを疑え」(https://www.nqou.net/)。デザインパターンをPerl/Mooで解説する記事を中心に、ストーリー駆動の連載シリーズ「コード探偵ロック」を展開。

## Build & Development Commands

タスクランナーは [mise](https://mise.jdx.dev/) を使用。

```bash
mise run server      # 開発サーバー起動 (hugo server -D -F) ※tool_build依存
mise run build       # 本番ビルド (clean → tool_build → hugo --minify)
mise run test        # テストビルド (tool_build → hugo -F --logLevel=debug)
mise run deploy      # デプロイ (build → gh-pages branch に force push)
mise run drafts      # 下書き一覧表示
mise run tool_build  # Perlビルドスクリプト単体実行 (perl tools/build.pl)
mise run clean       # docs/ 削除
```

## Git / Version Control

gitコマンド（`git add`/`git commit` 等）は並列実行しないこと。index.lock競合を防ぐため、必ず逐次実行する。

## Build Pipeline

1. `tools/build.pl` が `content/post/` 配下のMarkdownを前処理（YAMLフロントマター検証・正規化、日付のISO8601変換、epoch生成、デフォルトimage設定、公開時のファイルリネーム）
2. Hugo が `docs/` に静的サイトを生成
3. `tools/gh-pages.sh` が `docs/` を gh-pages ブランチに force push

**重要**: Hugo ビルド前に必ず `mise run tool_build` を実行すること（`server`/`build`/`test` タスクは自動で依存実行する）。

## Architecture

### コンテンツ構造
- 記事: `content/post/YYYY/MM/DD/HHMMSS.md`
- 固定ページ: `content/page/`（about, contact, privacy-policy等）
- パーマリンク: `/:year/:month/:day/:contentbasename/`
- 内部リンク変換: `/content/post/2025/12/24/000000.md` → `/2025/12/24/000000/`

### Hugo設定
- 設定: `config/_default/` にモジュール分割（config.toml, params.toml, markup.toml等）
- テーマ: Hugo Theme Stack v3（Hugoモジュール経由）
- 出力先: `docs/`（**直接編集禁止**）
- Hugo Extended が必要

### カスタムショートコード
- `{{< linkcard "URL" >}}` — リンクカード
- `{{< amazon asin="ASIN" title="タイトル" >}}` — Amazonアフィリエイト
- `{{< gist user id >}}` — Gist埋め込み
- Mermaid図: コードブロック（```mermaid）で使用可能

## Content Conventions

### フロントマター（build.plが自動補完）
- `title`, `date`（ISO8601 +09:00）, `epoch`, `iso8601`
- `draft`（デフォルト true）, `image`（デフォルト /favicon.png）
- `tags`（英小文字ハイフン区切り、最大5個。例: design-pattern, perl, moo）
- `categories`, `description`

### 文体ルール
- 本文: 書き言葉、です・ます調
- 箇条書き: だ・である調、末尾句点なし

### Perl依存ライブラリ
cpanfile に定義: Path::Tiny, Time::Moment, YAML, Moo, Types::Standard 等。

## Knowledge Management

- **SSOT (Single Source of Truth)**: 知見や設定は `agents/knowledge/` に集約する
- **調査情報**: `agents/warehouse/` で管理する
- **連載構造案**: `agents/structure/` で管理する
- **プロンプトテンプレート**: `agents/prompts/` で管理する
- **ワークフロー定義**: `.agent/workflows/` で管理する
- **役割定義**: `.github/agents/*.agent.md` で管理する

## Related Resources (Progressive Disclosure)

詳細な手順や規約については、以下のファイルを参照すること。

- **ワークフロー**: [WORKFLOWS.md](WORKFLOWS.md)
- **役割定義**: `.github/agents/*.agent.md`
