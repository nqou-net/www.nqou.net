# .github/agents

このディレクトリはリポジトリ内でAIエージェントが参照・利用する設定、プロンプトテンプレート、出力例を格納します。

目的:
- エージェント向けの運用ガイド、プロンプトテンプレート、期待される出力例を中央管理します。

主要ファイル:
- `agent-config.yml` — 許可・禁止事項の定義。
- `prompts/` — 記事作成や編集のためのプロンプトテンプレート。
  - `generate_post.md` — 単一エージェントによる記事生成テンプレート
  - `collaborative_writing.md` — 協力型記事作成ワークフローテンプレート
- `examples/` — 各プロンプトに対する期待出力の例。
  - `sample_output.md` — 基本的な記事出力例
  - `collaborative_output.md` — 協力型ワークフローの出力例
- `.gitignore` — 一時ファイルやログの除外設定。

必須ルール（要遵守）:
- 自動生成された記事は必ず `draft: true` にすること（公開はユーザーの判断）。
- リポジトリ内の `docs/`（ビルド出力）を編集してはいけません。
- `hugo` や `daiku` 等のビルドコマンドはエージェントから実行してはいけません。
- シークレットや認証情報はここに置かない（絶対にコミットしない）。
- エージェントの出力やログは原則コミットしない。どうしても必要な場合は `agent-config.yml` で明記すること。

プロンプトを追加する際の推奨手順:
1. `prompts/` にテンプレートを追加する（使い方の説明を含める）。
2. `examples/` に期待出力サンプルを追加する。
3. README に短い説明を追加する（必要なら）。

## カスタムエージェント一覧

### 技術専門家エージェント

- **perl-specialist.agent.md** — Perlの専門家。技術的に正確なPerl記事の原稿を作成。
- **ruby-specialist.agent.md** — Rubyの専門家。技術的に正確なRuby記事の原稿を作成。
- **whisky-mania.agent.md** — ウイスキーの専門家。テイスティングノートや蒸留所情報に詳しい。

### 編集・執筆エージェント

- **blog-writer.agent.md** — プロの編集者。専門家の原稿を読みやすいブログ記事に編集。
- **readme-specialist.agent.md** — READMEファイルの作成・改善を担当。
- **agents-specialist.agent.md** — AGENTS.mdファイルの作成・改善を担当。

## 協力型記事作成ワークフロー

### 概要

専門家エージェント（perl-specialist、ruby-specialist等）とblog-writerエージェントが協力して、
高品質なブログ記事を作成するワークフローです。

### ワークフローの流れ

1. **専門家による原稿作成**
   - 技術専門家エージェントが、技術的に正確で詳細な原稿を作成
   - 専門用語を遠慮なく使い、コード例を豊富に含める
   - Front matterは不要（blog-writerが後で追加）

2. **blog-writerによる編集**
   - 専門家の原稿を受け取り、読みやすく魅力的なブログ記事に編集
   - 技術的内容は変更せず、構成と表現を改善
   - 導入部、まとめ、適切な見出し構造を追加
   - Front matter（title、description、tags、draft: true）を作成

### 使用方法

詳細は以下を参照してください：
- **テンプレート**: `prompts/collaborative_writing.md`
- **出力例**: `examples/collaborative_output.md`

### 例：Perl記事の作成

```
ステップ1: perl-specialistに依頼
「CPANモジュールのインストール方法について、初心者向けの記事原稿を書いてください」

ステップ2: blog-writerに依頼
「以下のPerl記事原稿を、親しみやすく読みやすいブログ記事に編集してください」
+ perl-specialistの原稿を渡す
```

運用担当者へ:
- ここで定義したルールはリポジトリ運用上の必須ポリシーです。エージェントが守っていることを確認してください。
