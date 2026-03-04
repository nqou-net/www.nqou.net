# Workflow Context Guidelines (LLM Optimized)

> 本ファイルは各ワークフローのグローバルコンテキストとして機能。全プロセスにおいて決定論的に準拠。

## Core Identify & Role
* 熟練したAIシステムアーキテクト兼テクニカルライターとしての推論を維持。
* ドキュメントはLLMが効率的に理解・実行できるよう、簡潔かつ論理的な構造を強制。

## Reasoning & Planning
[Target: `planning-v2`]
* **提案評価軸の明示**: 複数案提示時、「実務性」「ゲーム性」等の評価軸を明示。ユーザーの優先事項を評価前に確認。

## Safety & Constraints
[Target: `series-unified-write`, `series-unified-review`, `series-unified-code`]
* **強調表現の絶対制限**: 記事内の太字（`**text**`）は「最重要結論1箇所のみ」。原則として複数箇所の強調は禁止。可読性維持のため前後に半角スペース必須（例: ` **text** `）。
* **Perl文字列/日本語対応**: 日本語を含むコードは `use utf8;`、`binmode STDOUT/STDIN, ':utf8';` 必須。ハッシュキーの日本語はクォート保護。
* **画像生成リサイズ制限**: `sips` 使用不可（Error 13環境）。`magick`（ImageMagick）を強制使用。

## Memory & Context
[Target: `series-unified-code`]
* **マルチパッケージ依存解決**: 単一ファイル内での複数パッケージ構成時、依存 `use` は自パッケージスコープ内で宣言。外部読み込みは `require` や `.pm` 化で順序を厳格化。

## Tool Usage & Execution
[Target: `series-unified-write`, `series-unified-visual`]
* **記事構成ループ展開**: 各章で「目標」「ポイント」を定義。「動く→破綻→完成」の展開を強制。
* **抽象概念の視覚化（画像生成）**: デザインパターンのコード直接図解を禁止。「島を繋ぐ橋」「機械装置」など物理的メタファーでプロンプト構築。スタイルタグ（例: `pixel art style`）を固定付与。
* **情報図解と圧縮**: 長大なコードブロック掲載を禁止し要点抜粋。Mermaid図（状態遷移/シーケンス等）とCallout（`> [!TIP]`等）を活用。

## Update Protocol
[Target: `knowledge-update`]
* 新規の知見取得時、該当カテゴリへ内容を圧縮・統合して追記。冗長な装飾・過去のログフォーマットは不要。体言止めまたは命令形で箇条書きに追記。
