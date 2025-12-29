---
title: "Obsidian をプロンプトテンプレート集として活用する方法（調査）"
slug: "obsidian-prompts"
date: 2025-12-23
tags:
  - obsidian
  - prompt-template
  - workflow
description: "Obsidian をプロンプトテンプレート管理基盤として活用するための構成、プラグイン、ワークフロー、外部連携を整理した調査レポート。"
image: /favicon.png
draft: true
---

## タイトル
Obsidian をプロンプトテンプレート集として活用する方法（調査）

作成日: 2025-12-23

目的: Obsidian Vault をプロンプトテンプレートの管理・編集・呼び出し基盤として使うための方法を整理する。用途別のワークフロー、推奨プラグイン、具体設定例、外部連携スクリプトの雛形を含む。

---

## 要約

- シンプル運用: `Templates/Prompts/` にテンプレを保存し、コマンドパレットで開いてコピー。
- 中級運用: Obsidian のコア `Templates` プラグインまたはコミュニティの `Templater` で変数入力や動的テンプレを実現。
- 高度運用: `QuickAdd` でマクロ化、`Dataview` でテンプレ一覧管理、Obsidian URI / CLI 経由で外部LLMへ自動送信。

---

## 推奨フォルダ構成とメタデータ

- フォルダ例:
  - `Templates/Prompts/` — テンプレート本体
  - `Templates/Snippets/` — 共通フレーズや小部品
- ノート先頭にタグと frontmatter を入れる（Dataviewで集約しやすくするため）

Frontmatter 例:

---
title: "コードレビュー依頼テンプレ"
prompt_type: "code-review"
tags: ["prompt-template","code-review"]
variables: ["issue","code"]
---

本文中で `{{variable}}` のように記述しておくと分かりやすい（Templaterで置換する運用が自然）。

---

## 推奨プラグイン（必須ではないが便利）

- Templates (core): 簡単な静的テンプレの挿入
- Templater: JS 実行やユーザー入力プロンプト、動的生成が可能（最重要）
- QuickAdd: テンプレ選択→入力ダイアログ→挿入をワンクリック化
- Dataview: テンプレの一覧やメタで絞り込み表示
- obsidian-uri: URI スキームを利用する（Obsidian 自体の機能）
- obsidian-git: バージョン管理・同期
- Web Clipper / Obsidian AI / Text Generator（必要に応じて）

---

## 具体ワークフロー（レベル別）

1) 最小（手動コピー）
- `Templates/Prompts/` にテンプレを保存
- 開いて内容を選択→コピー→外部のチャットUIに貼り付け

2) 中級（Templater）
- Templater テンプレで変数入力を行い、Vault 内に組み立てる
- 例: 変数 `issue`, `code` をユーザーに順番に尋ねてテンプレを生成

3) 上級（QuickAdd + Templater + クリップボード）
- QuickAdd のマクロでテンプレ選択 → Templater を呼んで変数プロンプト → 結果をクリップボードにコピー
- 結果を即座にチャットへ貼り付け、または Obsidian AI に送る

4) 自動化（外部スクリプト）
- Vault 内のテンプレを CLI で抽出して LLM API に送信
- Obsidian URI で特定テンプレートを開き、別ツールで自動ポスト

---

## Templater の実例

テンプレファイル: `Templates/Prompts/code-review.md`

テンプレ本文例（Templater 形式）:

```
---
title: "コードレビュー依頼"
prompt_type: "code-review"
tags: ["prompt-template","code-review"]
variables: ["issue","code"]
---

<%* 
let issue = await tp.system.prompt("レビュー対象の要点を短く入力してください（例: パフォーマンス改善）");
let code = await tp.system.prompt("コードを貼ってください（複数行可）");
%>

目的: <%= issue %>

対象コード:

```javascript
<%= code %>
```

レビューして欲しい観点:
- バグ
- パフォーマンス
- 可読性
- セキュリティ
```

注意: 上の `<%* ... %>` と `<%= ... %>` は Templater の JS 実行と出力のパターンです。環境によっては細かな構文差があるため、導入後に簡単なサンプルで動作確認してください。

---

## QuickAdd の設定手順（概略）

1. QuickAdd をインストール
2. QuickAdd > Add Choice > Choice Type: "Macro"
3. Macro に以下ステップを追加:
   - "Templater: Insert template" -> `Templates/Prompts/code-review.md`
   - (任意) "Copy to clipboard" プラグインや外部コマンドで出力をクリップボードへ
4. ホットキーを割り当てるとワークフローがワンキーで動く

※ QuickAdd の UI 上でステップを並べる形なので、JSON の直編集は不要。

---

## Dataview でテンプレ一覧を作る例

ノート（例: `Templates/index.md`）に次を貼ると Vault 中のテンプレが一覧化される:

```dataview
table title, prompt_type, file.link as file
from "Templates/Prompts"
where contains(tags, "prompt-template")
sort file.asc
```

---

## Obsidian URI の例

- 特定テンプレを開く:

```
obsidian://open?vault=VaultName&file=Templates%2FPrompts%2Fcode-review.md
```

- 外部スクリプトからノートを開いて手動で実行するワークフローに使える

---

## 外部連携: テンプレを LLM API に送る簡易スクリプト（雛形）

- 前提: API キーは環境変数で管理（例: `OPENAI_API_KEY`）。Vault にキーを保存しない。

例: Bash + `jq` を使う方法（テンプレファイルの先頭から本文を抽出して送信）

```bash
#!/usr/bin/env bash
set -e
TEMPLATE_FILE="Templates/Prompts/code-review.md"
CONTENT=$(sed -n '1,200p' "$TEMPLATE_FILE")
# JSON に安全に埋め込む
JSON_CONTENT=$(jq -Rs . <<< "$CONTENT")

curl -s -X POST https://api.openai.com/v1/chat/completions \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"model":"gpt-4o-mini","messages":[{"role":"user","content":'"$JSON_CONTENT"'}],"max_tokens":800}'
```

注意: 実運用では YAML frontmatter を取り除く処理や、テンプレ内の変数置換（Templaterで事前に展開）を行っておく。

---

## セキュリティと運用上の注意

- API キーやシークレットは Vault に保存しない。OS のキーチェーンや環境変数、Secret manager を使う。
- テンプレに個人情報や機密情報を含めないルールを運用で定める。
- 共有Vaultや公開リポジトリにテンプレを含める場合は機密チェックを自動化する（grep, pre-commit フック等）。

---

## まとめ（推奨構成と初期手順）

推奨（初期）: `Templates/Prompts/` に用途別ノートを作り、Templater で変数処理、QuickAdd でワンクリック挿入→クリップボードコピーの流れを構築する。Dataview で管理・検索性を確保し、外部送信は CLI スクリプトで必要に応じて行う。
