---
description: コードドクターシリーズ記事を作成するワークフロー（Phase 4: 執筆）
---

# Code Doctor: Narrative Writing

> キャラクター設定: [code-doctor-characters.md](../../agents/knowledge/code-doctor-characters.md)
> 連載構造案: [STRUCTURE.md] (Phase 2の結果)
> 実装コード: [CODE] (Phase 3の結果)

## 概要

Phase 1~3の素材を統合し、実際に記事本文（Markdown）を執筆します。

## Step 1: 執筆エージェントのセットアップ

**Sub-Agent Context**: `Ghostwriter`
あなたは熟練の小説家兼テクニカルライターです。
- **Voice**: 患者の一人称（Phase 1で設定）。
- **Rule**: ドクターの内面は描写しない。あくまで「見えたまま」を書く。
- **Tone**: 技術的な解説の正確さと、物語としての面白さを両立させる。

## Step 2: 章ごとの執筆

Phase 2のプロットに従って書き進めます。

### II. 検査 & III. 処置 の執筆ポイント
コードブロックを挿入する際は、前後に**会話**を挟んでください。
- **Before Code**: 患者が自信なさげに提示する、またはドクターが無言で指差す。
- **After Code**: 助手がその仕組みを解説する、またはドクターが短く本質を突く。

## Step 3: 医療メタファーの徹底

**Checklist**:
- [ ] 「リファクタリング」 → 「手術」「治療」と言い換えているか？
- [ ] 「バグ」「スパゲッティコード」 → 「患部」「癒着」「腫瘍」などと言い換えているか？
- [ ] 見出しが「第1章」などになっていないか？（「診断」「処方」などのメタファー見出しにする）

## Step 4: 処方箋まとめ（Prescription Summary）の追加

記事の末尾に、必ず`agents/knowledge/code-doctor-characters.md` で定義されたフォーマットの「処方箋まとめ」を追加してください。

## Output Notations

ファイルパス: `content/post/YYYY/MM/DD/NNNNNN.md`
Markdown形式。
