# シリーズマニフェスト: コード探偵ロックの事件簿

## 概要
「コード探偵」シリーズの記事を執筆するための設定ファイル（プラグイン）です。
汎用執筆ワークフローは、本ファイルを読み込むことで「探偵シリーズ」としての振る舞いを行います。

## 構成コンポーネント

このシリーズは以下の部品（components）を組み合わせて構築されます。

### 1. Personas (キャラクター設定)
*   **主人公**: `.agent/components/personas/protagonist-detective.md`
*   **語り部**: `.agent/components/personas/narrator-watson.md`

### 2. Metaphors (世界観・用語)
*   **メタファー設定**: `.agent/components/metaphors/mystery.md`

### 3. Plots (構成)
*   **プロット構造**: `.agent/components/plots/mystery-5-acts.md`

### 4. Formats (出力形式)
*   **記事フォーマット**: `.agent/components/formats/hugo-markdown.md`
*   **記事末尾フォーマット**: `.agent/components/formats/footer-detective-report.md`

## 固有のルール
*   **フロントマター規約**:
    *   `categories: [tech]`（固定。`Design Patterns` や `Perl` をカテゴリに入れない）
    *   必須タグ: `design-pattern`, `perl`, `moo`, `{pattern名}`, `{アンチパターン名}`, `refactoring`, `code-detective`
    *   アンチパターン名はケバブケースで（例: `god-class`, `shotgun-surgery`, `duplicated-code`）
    *   禁止: 日本語タグ、`oop` 等のシリーズ外タグ
*   コードの実装は常に **Perl + Moo** を使用すること。
