# AGENTS.md — エージェント作業指針

Hugo製技術ブログ `www.nqou.net` の運用・開発を行うAIエージェントのためのガイドライン。

## 1. コアマニュフェスト (Core Mandates)

- **正直さ**: 不明点は推測せず「わからない」と正直に回答し、正確性を最優先する。
- **言語**: ユーザーとの対話は「日本語」で行う。
- **セキュリティ**: APIキーやパスワード等の機密情報をリポジトリに含めない。
- **直接編集禁止**: `docs/` ディレクトリはHugoの生成物であるため、直接編集しない。

## 2. プロジェクト環境 (Capabilities)

- **SSOT (Single Source of Truth)**: 知見や設定は `agents/knowledge/` に集約する。
- **コンテンツ**: 記事は `content/post/`、調査情報は `content/warehouse/` で管理する。
- **ローカルプレビュー**: `hugo server -D -F` で確認可能。

## 3. 関連リソース (Progressive Disclosure)

詳細な手順や規約については、以下のファイルを参照すること。

- **コンテンツ作成規約**: [agents/knowledge/CONTENT_CREATION.md](agents/knowledge/CONTENT_CREATION.md)
- **開発・運用ルール**: [agents/knowledge/DEVELOPMENT.md](agents/knowledge/DEVELOPMENT.md)
- **ワークフロー**: [WORKFLOWS.md](WORKFLOWS.md)
- **役割定義**: `.github/agents/*.agent.md`
