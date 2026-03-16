# シリーズマニフェスト: コードドクター

## 概要
「コードドクター」シリーズの記事を執筆するための設定ファイル（プラグイン）です。
汎用執筆ワークフローは、本ファイルを読み込むことで「医療ドラマシリーズ」としての振る舞いを行います。

## 構成コンポーネント

このシリーズは以下の部品（components）を組み合わせて構築されます。

### 1. Personas (キャラクター設定)
*   **主人公**: `.agent/components/personas/protagonist-doctor.md`
*   **助手**: `.agent/components/personas/assistant-nanako.md`
*   **語り部（患者）**: `.agent/components/personas/narrator-patient.md`

### 2. Metaphors (世界観・用語)
*   **メタファー設定**: `.agent/components/metaphors/medical.md`

### 3. Plots (構成)
*   **プロット構造**: `.agent/components/plots/medical-4-acts.md`

### 4. Formats (出力形式)
*   **記事フォーマット**: `.agent/components/formats/hugo-markdown.md`
*   **記事末尾フォーマット**: `.agent/components/formats/footer-medical-chart.md`

## 固有のルール
*   **フロントマター規約**:
    *   `categories: [tech]`（固定）
    *   必須タグ: `design-pattern`, `refactoring`, `code-doctor`, `{pattern名}`
    *   パターン名・アンチパターン名はケバブケースで統一すること。
*   コードの実装は特に指定がなければ **TypeScript**（またはテーマに合致した言語）を使用すること。
