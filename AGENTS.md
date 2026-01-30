# AGENTS.md — エージェント作業指針

Hugo製技術ブログ `www.nqou.net` 用。補助文書として機能。

---

## 最優先ルール

- **不明点は「わからない」と正直に回答**
- 正確性と透明性を常に優先

---

## コミュニケーション

- 日本語で応答
- 技術用語・コードは英語可

---

## プロジェクト構造

| ディレクトリ | 用途 |
|---|---|
| `content/post/` | 記事ソース（投稿先） |
| `content/warehouse/` | 調査ドキュメント |
| `agents/structure/` | 連載構造案 |
| `layouts/`, `partials/`, `shortcodes/` | テーマ・レイアウト |
| `static/` | 静的アセット |
| `resources/` | Hugo出力 |
| `docs/` | **生成物（編集禁止）** |
| `.github/agents/*.agent.md` | 専門家エージェント定義 |

---

## クイックスタート

```bash
hugo server -D -F   # -D: ドラフト表示, -F: 未来日表示
```

---

## コンテンツ作成

### フロントマター（YAML `---`）

- 必須キー: `title`, `draft`, `tags`, `description`, `image`
- ドラフト中は `draft: true`
- タグ: 英語小文字・ハイフン形式（例: `object-oriented`）

### 記法

- 見出し: ATX形式（`##` 以上）、H1はtitleに委譲
- 強調: `**太字**` は使用せず、「」で括って表現する（例: 「重要」）
- 外部参照: `{{< linkcard "URL" >}}` ショートコード優先
- コードブロック: 言語タグ必須
- 画像: 意味のある `alt` 必須
- 生HTML埋め込み禁止
- **Mermaid**: クラス図等でクラス名に特殊文字（`::`など）が含まれる場合はバッククォートで括る（例: `` class `Package::Name` ``）

---

## 品質レビュー基準

### 技術的正確性
- SOLID原則（SRP/OCP）違反の適切な指摘
- 破綻パターンの「なぜダメか」の具体的説明
- コード動作検証: テストコードによる動作確認と警告（Warning）の不在確認

### 構造整合性
- `content/warehouse/` 調査ドキュメント反映
- `agents/structure/` ストーリー構成遵守
- **流れ**: 動く → 破綻 → パターン導入 → 完成

### 表現スタイル
- 教科書的導入を回避
- 遊び心ある表現（括弧書き補足、軽いツッコミ）
- 具体的問題提起

---

## テスト

- 自動ユニットテストなし（プロダクトコードではないため）
- コード検証:
  - 記事内のコード例を抽出し、一時的なテストコードを作成して動作検証を行うことを強く推奨
  - 検証に使用したテストコードは `agents/tests/<slug>/` 配下に保存
  - 警告（Warning）が出ないことを確認する（言語組み込み関数との衝突などに注意）
- リンク検証: リンクチェッカー使用

---

## PR規約

- ブランチ名: `feature/write-hugo-article`, `fix/images-optimization`
- PRタイトル: `[post] 説明` / `[site] 説明`
- 提出前: `draft: true` 維持

---

## セキュリティ

- リポジトリにシークレット禁止（GitHub Secrets使用）
- フロントマター/コンテンツに資格情報埋め込み禁止

---

## 禁止事項

- 環境セットアップ・システムインストールの自動実行
- `docs/` の直接編集
- 生HTML埋め込み
- シークレットのコミット

---

## ワークフロー参照

詳細は [WORKFLOWS.md](WORKFLOWS.md) 参照。

| 項目 | リンク |
|---|---|
| シリーズ記事一覧 | [SERIES.md](SERIES.md) |
| シリーズ記事ワークフロー | [WORKFLOWS.md#シリーズ記事連載記事のワークフロー](WORKFLOWS.md#シリーズ記事連載記事のワークフロー) |
| 単体記事ワークフロー | [WORKFLOWS.md#単体記事のワークフロー](WORKFLOWS.md#単体記事のワークフロー) |
| プロンプトテンプレート | [WORKFLOWS.md#プロンプトテンプレート](WORKFLOWS.md#プロンプトテンプレート) |
| 品質基準 | [WORKFLOWS.md#検証と品質ゲート](WORKFLOWS.md#検証と品質ゲート) |

---

## Browser Automation

Use `agent-browser` for web automation. Run `agent-browser --help` for all commands.

Core workflow:
1. `agent-browser open <url>` - Navigate to page
2. `agent-browser snapshot -i` - Get interactive elements with refs (@e1, @e2)
3. `agent-browser click @e1` / `fill @e2 "text"` - Interact using refs
4. Re-snapshot after page changes

## 付記

変更・追補は `.github/agents/*.agent.md` の各エージェント定義を参照して調整。
