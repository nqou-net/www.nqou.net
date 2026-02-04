---
description: コードドクターシリーズ：患者プロファイルとカルテ作成 (Phase 1)
---

# Code Doctor: Profile & Chart Generation

> キャラクター設定: [code-doctor-characters.md](../../agents/knowledge/code-doctor-characters.md)
> スキル: [code-doctor-narrative](../../agents/skills/code-doctor-narrative/SKILL.md)

## 概要

デザインパターンとテーマに基づき、物語の主人公となる「患者」のプロファイルと、技術的な問題を医療メタファーに変換した「カルテ」を作成します。

## Step 1: 入力情報の整理

以下の情報を確認（不足があれば自動生成またはユーザーに確認）:
- **Design Pattern**: 解説するデザインパターン
- **Slug**: デザインパターン名のケバブケース（例: `factory-method`, `singleton`）。以降 `<slug>` として参照。
- **Theme**: 具体的な実装テーマ（例: ゲームの状態管理、ログ出力など）
- **Symptoms** (Optional): 具体的なコードの症状

## Step 2: 患者プロファイルの生成

**Sub-Agent Context**: `CastingDirector`
あなたはドラマのキャスティング担当です。読者が共感できる「人間味のある」患者キャラクターを作成してください。

**生成項目**:
1. **属性**: 年齢、職種（エンジニア歴）、性格
2. **背景**: なぜそのコードを書いたのか（締め切り、仕様変更、知識不足など）
3. **主訴（悩み）**: 「変更がつらい」「バグが直らない」など
4. **一人称**: 私、僕、俺、自分など

## Step 3: 診断カルテの作成（メタファー変換）

**Sub-Agent Context**: `MedicalTranslator`
技術的な問題を医療用語に変換します。

**生成項目**:
1. **症状（Symptoms）**:
   - Technical: 「クラス間の結合度が密すぎる」
   - Medical: 「癒着が激しく、少し動かすだけで出血する状態」
2. **病名（Diagnosis）**: アンチパターン名または症状名の比喩
3. **処方（Prescription）**: デザインパターンの適用

## Output Example

```markdown
# Patient Profile
- Name: 焦り気味のフリーランス (32)
- Role: ソーシャルゲームのサーバーサイド担当
- Personality: 真面目だが、目先のタスクに追われて視野が狭くなりがち。
- First Person: 「僕」

# Medical Chart
- Symptom: 機能追加のたびに巨大なswitch文を修正し、デグレを起こしている。
- Metaphor: 「増殖した腫瘍（switch文）が血管（ロジック）を圧迫している」
- Cure: Strategy Patternによる腫瘍の切除とバイパス手術。
```

## Step 4: 保存

生成されたプロファイルとカルテを以下のパスに保存してください。
`agents/code-doctor-series/<slug>/profile.md`
※ `<slug>` は Step 1 で定義したデザインパターンのケバブケース名です。