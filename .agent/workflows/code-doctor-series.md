---
description: コードドクターシリーズ記事を作成するワークフロー（パターン名のみで自動生成対応）
---

# Code Doctor Series: Master Workflow

> **Character Settings**: [code-doctor-characters.md](../../agents/knowledge/code-doctor-characters.md)
> **Narrative Skill**: [code-doctor-narrative](../../agents/skills/code-doctor-narrative/SKILL.md)

## 概要

このワークフローは、複数の専門サブエージェント（ワークフロー）を連携させ、高品質な「コードドクター」シリーズ記事を作成します。

---

## Process Overview

1.  **Phase 1: Profile & Diagnosis** (`/code-doctor-1-profile`)
    -   患者プロファイルと技術的症状（カルテ）の作成。
2.  **Phase 2: Plot Architecture** (`/code-doctor-2-plot`)
    -   物語の起承転結とコメディ要素の設計。
3.  **Phase 3: Surgical Implementation** (`/code-doctor-3-code`)
    -   Before/Afterコードの実装と検証。
4.  **Phase 4: Narrative Writing** (`/code-doctor-4-write`)
    -   記事本文の執筆。
5.  **Phase 5: Medical Board Review** (`/code-doctor-5-review`)
    -   キャラクター一貫性と品質の最終チェック。

---

## Execution Guide

ユーザー入力（パターン名など）に基づき、各フェーズを順番に実行してください。

### Step 1: Initialize
ユーザー入力から `Design Pattern` と `Theme` を抽出します。

### Step 2: Chain Execution
各サブワークフローを呼び出し、その出力を次のステップの入力として使用します。

**Workflow Chain:**
`User Input` -> [Phase 1: Profile] -> `Patient/Chart` -> [Phase 2: Plot] -> `Detailed Plot` -> [Phase 3: Code] -> `Impl Files` -> [Phase 4: Write] -> `Draft.md` -> [Phase 5: Review] -> `Final.md`

---

## Manual Override (Pro Tips)

- 特定のフェーズだけやり直したい場合は、直接サブワークフローを呼び出してください。
  - 例: 「プロットはいいけどコードが変」→ `/code-doctor-3-code`
  - 例: 「口調だけ直したい」→ `/code-doctor-5-review`

---

## Prompt Example

エージェントに対して一括で指示する場合のプロンプト例：

```markdown
@/.agent/workflows/code-doctor-series.md

# Request
Observerパターンについて、コードドクターシリーズの記事を書いてください。

# Specifics
- テーマ: 気象観測データ（あえて古典的な例で）
- 患者: 「基本に忠実すぎて応用が利かない」新人エンジニア
- 症状: 全てのディスプレイ要素をハードコードして更新している
```
