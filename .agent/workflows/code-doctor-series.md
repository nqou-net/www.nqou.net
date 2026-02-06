---
description: コードドクターシリーズ記事を作成するワークフロー（パターン名のみで自動生成対応）
---

# Code Doctor Series: Master Workflow

> **Narrative Skill**: [code-doctor-narrative](../../agents/skills/code-doctor-narrative/SKILL.md)

## 概要

このワークフローは、複数の専門サブエージェント（ワークフロー）を連携させ、高品質な「コードドクター」シリーズ記事を作成します。

---

## 設計原則: 多段階プロンプト（Chain of Prompting）

> [!IMPORTANT]
> **指示の希釈化（Instruction Dilution）を回避するため、各フェーズで必要な情報のみを提供します。**

| Phase | 参照コンテキスト | 目的 |
|-------|-----------------|------|
| 1: Profile | `phase-1-context.md` | 患者ペルソナ・医療メタファー設計 |
| 2: Plot | `phase-2-context.md` | 4幕構造・勘違いシーン配置 |
| 3: Code | `phase-3-context.md` | 技術制約・Before/After実装 |
| 4: Write | `code-doctor-characters.md` **（完全版）** | キャラクター発話・執筆ルール |
| 4.5: Visual | スタイルプリセット（水彩調） | ヘッダー+挿絵3枚 ⚡ *Optional* |
| 5: Review | チェックリスト形式 | 品質基準検証 |

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
5.  **Phase 4.5: Visual Enhancement** (`/code-doctor-visual`) ⚡ *Optional*
    -   ヘッダー画像 + 本文挿絵3枚の生成・配置。
    -   **スキップ条件**: `挿絵: なし` 指定時
6.  **Phase 5: Medical Board Review** (`/code-doctor-5-review`)
    -   キャラクター一貫性と品質の最終チェック。

---

## Execution Guide

ユーザー入力（パターン名など）に基づき、各フェーズを順番に実行してください。

### Step 1: Initialize
ユーザー入力から `Design Pattern` と `Theme` を抽出します。

**挿絵オプションの確認**:
- `挿絵: あり` または指定なし → Phase 4.5 を実行
- `挿絵: なし` → Phase 4.5 をスキップ

### Step 2: Chain Execution
各サブワークフローを呼び出し、その出力を次のステップの入力として使用します。

**Workflow Chain (挿絵あり):**
`User Input` -> [Phase 1: Profile] -> `Patient/Chart` -> [Phase 2: Plot] -> `Detailed Plot` -> [Phase 3: Code] -> `Impl Files` -> [Phase 4: Write] -> `Draft.md` -> [Phase 4.5: Visual] -> `Illustrated.md` -> [Phase 5: Review] -> `Final.md`

**Workflow Chain (挿絵なし):**
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
