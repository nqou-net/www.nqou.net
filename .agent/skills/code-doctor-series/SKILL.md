---
name: code-doctor-series
description: デザインパターン名や最小要件から「コードドクター」シリーズ記事を作成する統合スキル。Phase 0〜5 のワークフローを順に実行し、テーマ/患者/症状の選定、プロファイル・プロット設計、Before/Afterコード実装と検証、本文執筆、最終レビューまで完了する。ユーザーが「コードドクター記事を書きたい」「パターン名だけで生成したい」「特定フェーズだけ再実行したい」と依頼したときに使用する。
---

# Code Doctor Series

## 概要

`code-doctor` 連載記事を、段階的なワークフローで破綻なく生成する。  
各フェーズで必要な情報だけを読み込み、指示の希釈化を避ける。

## 事前確認

1. ユーザー入力から `Design Pattern` 名を抽出する。
2. `slug` をケバブケースで決定する（例: `factory-method`）。
3. ユーザーが `theme` / `patient` / `symptoms` を固定指定したか確認する。
4. 既存成果物の有無を確認する。
   - `agents/code-doctor-series/<slug>/`
   - `content/post/YYYY/MM/DD/*.md`

## 実行チェイン

1. Phase 0: Input Design  
   - 読み込む: `.agent/workflows/code-doctor-0-input.md`
   - 生成する: `agents/code-doctor-series/<slug>/input-design.md`
   - 実行内容: テーマ・患者・症状を王道/革新/逆転で3案ずつ作成し、5軸評価で候補を選定する。
   - 停止条件: 選定結果をユーザー確認する。承認が得られるまで Phase 1 に進めない。
2. Phase 1: Profile & Chart  
   - 読み込む: `.agent/workflows/code-doctor-1-profile.md`
   - 生成する: `agents/code-doctor-series/<slug>/profile.md`
   - 実行内容: 患者プロファイルと診断カルテを作成する。
3. Phase 2: Plot Architecture  
   - 読み込む: `.agent/workflows/code-doctor-2-plot.md`
   - 生成する: `agents/code-doctor-series/<slug>/plot.md`
   - 実行内容: 4幕構成と勘違いコメディを設計し、来院/往診の整合性を確認する。
4. Phase 3: Surgical Implementation  
   - 読み込む: `.agent/workflows/code-doctor-3-code.md`
   - 生成する:
     - `agents/code-doctor-series/<slug>/tests/before/`
     - `agents/code-doctor-series/<slug>/tests/after/`
   - 実行内容: Before/Afterコードとテストを実装し、実行可能性を検証する。
5. Phase 4: Narrative Writing  
   - 読み込む:
     - `.agent/workflows/code-doctor-4-write.md`
     - `agents/knowledge/code-doctor-characters.md`
     - `agents/code-doctor-series/<slug>/plot.md`
     - `agents/code-doctor-series/<slug>/tests/`
   - 生成する: `content/post/YYYY/MM/DD/NNNNNN.md`
   - 実行内容: 患者一人称、ドクター短文、助手敬語のルールを厳守して本文を書く。
6. Phase 5: Medical Board Review  
   - 読み込む: `.agent/workflows/code-doctor-5-review.md`
   - 対象: `content/post/YYYY/MM/DD/NNNNNN.md`
   - 実行内容: フロントマター、キャラ一貫性、メタファー強度、技術正確性をチェックする。
   - 停止条件: 不合格項目が1つでもあれば修正し、再レビューする。

## 追加オプション

- 挿絵を生成する場合のみ `.agent/workflows/code-doctor-visual-*.md` を別実行する。
- 特定フェーズだけ再実行する場合は該当ワークフローだけ呼び出す。
  - 例: プロット再生成 → `.agent/workflows/code-doctor-2-plot.md`
  - 例: コード再実装 → `.agent/workflows/code-doctor-3-code.md`

## 品質ゲート

1. Phase 0 承認前に Phase 1 へ進めない。
2. Phase 3 はテストを通す。警告も残さない。
3. Phase 4 は末尾に `## 処方箋まとめ` を必ず付ける。
4. Phase 5 は全チェック項目が通るまで差し戻しと修正を繰り返す。
