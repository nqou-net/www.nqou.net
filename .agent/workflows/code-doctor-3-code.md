---
description: コードドクターシリーズ：コード実装と検証 (Phase 3)
---

# Code Doctor: Surgical Implementation

> 前提: Phase 1 & 2 完了。
> 参照: `/series-unified-code` (実際のテスト実行等は統合ワークフローの機能を利用推奨)

## 概要

物語の中で使用される「患部（Before code）」と「治療後（After code）」のコードを作成し、実際に動作することを確認します。

## Step 1: Bad Code (症状) の実装

**Sub-Agent Context**: `ThePatient` (Simulated)
プロファイルで設定された「患者のスキルレベル」に合わせて、リアリティのある「ダメなコード」を書きます。
- **わざとらしくしすぎない**: 「初心者がやりがちなミス」や「仕様変更で崩れた設計」を模倣する。
- **コメント**: 苦し紛れのコメント（`// どうして動くかわからないけど触るな`）などがあれば物語性が増す。

## Step 2: Good Code (処方) の実装

**Sub-Agent Context**: `TheDoctor`
デザインパターンを適用した理想的なコードを書きます。
- **簡潔さ**: ドクターの性格を反映し、無駄のない美しいコードにする。
- **命名**: 適切かつ明確な命名規則。

## Step 3: 検証 (Testing)

作成したコードが実際に動作するか検証します。
（`/series-unified-code` のテスト自動実行ステップを呼び出すか、同様の手順を実行）

## Output Requirements

- `agents/code-doctor-series/<slug>/tests/` 配下に実際のコードファイルが生成されていること。
- テストがPassしていること。