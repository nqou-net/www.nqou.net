# AGENTS.md — エージェント作業指針

Hugo製技術ブログ `www.nqou.net` の運用・開発を行うAIエージェントのための包括的ガイドライン。

---

## 1. コアマニュフェスト (Core Mandates)

### 行動規範
- **正直さ**: 不明点は推測せず「わからない」と正直に回答する。正確性と透明性を最優先する。
- **言語**: ユーザーとの対話は「日本語」で行う。技術用語、コード、ファイル名は英語で良い。

### セキュリティ
- **シークレット禁止**: リポジトリ内（コード、記事、フロントマター含む）にAPIキーやパスワード等の機密情報を一切含めない。
- **直接編集禁止**: `docs/` ディレクトリはHugoの生成物であるため、直接編集しない。

---

## 2. エージェントシステム (Agent System)

本プロジェクトでは、特定の役割を持つ「専門家エージェント」と、定型作業を自動化する「スキル」を組み合わせて作業を行う。

### 役割定義 (Roles)
- 各エージェントの具体的な振る舞いや専門知識は `.github/agents/*.agent.md` に定義されている。
- タスクに応じて適切なエージェント（例: `reviewer`, `proofreader`, `websearch-nerd`）として振る舞うこと。

### スキル (Skills)
タスク品質の標準化・効率化のための再利用可能な手順書。

- **配置場所**: `.agent/skills/<skill-name>/`
- **構成**: `SKILL.md` (YAMLフロントマター + 手順/チェックリスト)
- **運用**: 
  - 頻出する定型業務はスキル化を提案・実装する。
  - 既存スキルは定期的に見直し改善する。

### ワークフロー (Workflows)
記事作成やプランニングの具体的な手順は [WORKFLOWS.md](WORKFLOWS.md) に集約されている。
- **参照**: `WORKFLOWS.md` および `.agent/workflows/`

---

## 3. プロジェクト環境 (Project Environment)

### ディレクトリ構造

| パス | 説明 |
|---|---|
| `content/post/` | 記事ソース（Markdown）。ここがメインの投稿場所。 |
| `content/warehouse/` | 調査・一次情報の保管場所。 |
| `agents/knowledge/` | **SSOT (Single Source of Truth)**。キャラクター設定、共通知見など。 |
| `agents/structure/` | 連載記事の構造案・設計図。 |
| `agents/tests/` | 記事コード検証用の一時的なテストコード置き場。 |
| `.agent/` | システム設定。スキル(`skills/`)やワークフロー(`workflows/`)を格納。 |
| `.github/agents/` | エージェントのペルソナ・役割定義ファイル。 |
| `layouts/`, `static/` | Hugoテーマ、静的アセット。 |
| `docs/` | **[編集禁止]** GitHub Pages公開用ディレクトリ（Hugo生成物）。 |

### クイックスタート (Hugo)
ローカルでのプレビュー確認:
```bash
hugo server -D -F   # -D: ドラフトを含む, -F: 未来の日付のコンテンツも表示
```

---

## 4. 開発ガイドライン (Development Guidelines)

### Git / PR運用
- **ブランチ名**: `feature/write-hugo-article`, `fix/images-optimization` 等、意図を明確に。
- **PRタイトル**: `[post] 記事タイトル` / `[site] 修正内容`
- **Draft維持**: 記事作成中はフロントマターの `draft: true` を維持し、完成時に外す（またはPRマージ時）。

### テスト・検証
- **自動テスト**: プロダクトコードではないためCIでの自動テストはない。
- **手動検証 (必須)**:
  - 記事内のコード例は、必ず一時的なテストコードを作成して動作確認を行う。
  - 検証コードは `agents/tests/<slug>/` に保存する。
  - 警告 (Warning) レベルのメッセージも出ないよう修正する。
- **リンク確認**: リンク切れがないか確認する。

### ブラウザ自動化 (Browser Automation)
Web操作が必要な場合は `agent-browser` スキル/ツールを使用する。

- **基本フロー**:
  1. `agent-browser open <url>`
  2. `agent-browser snapshot -i` (インタラクティブ要素のID取得)
  3. `agent-browser click @e1` / `fill @e2 "text"`
  4. ページ遷移後は再度 snapshot を取得

---

## 5. コンテンツ作成ガイドライン (Content Creation)

### フロントマター (Front Matter)
記事の先頭にはYAML形式のメタデータを記述する。

- **必須**: `title`, `draft`, `tags`, `description`, `image` (アイキャッチ)
- **タグ**: 英語小文字・ハイフン区切り（例: `object-oriented`, `design-patterns`）

### 記法・スタイル (Markdown & Hugo)
- **見出し**: ATX形式 (`##`, `###`)。H1 (`#`) は使用しない（タイトルはフロントマターで指定）。
- **強調**: `**太字**` の前後は半角スペースを空ける（例: `これは **重要** です`）。
- **リンク**: Hugoショートコード `{{< linkcard "URL" >}}` を優先使用。
- **書籍リンク**: `{{< amazon asin="ASIN" title="タイトル" >}}` を使用。
- **コードブロック**: 言語識別子を必ず指定（例: ` ```go `）。
- **Mermaid**: クラス名等に特殊文字が含まれる場合はバッククォートでエスケープ（例: `` class `Package::Name` ``）。
- **禁止**: 生HTMLの埋め込み。

### 品質基準 (Quality)
詳細は `WORKFLOWS.md` の「品質基準」を参照。
- **技術的正確性**: SOLID原則等の原理原則に基づき、誤りを指摘・修正する。
- **構造**: `agents/structure/` の設計図、`content/warehouse/` の調査結果と整合していること。
- **表現**: 教科書的な退屈さを避け、適度な遊び心やツッコミを入れる（キャラクター設定準拠）。
