---
description: コードドクターシリーズ：コード実装と検証 (Phase 3)
---

# Code Doctor: Surgical Implementation

> **前提**: Phase 1 & 2 完了。
> **Phase Context**: [phase-3-context.md](../../agents/knowledge/phase-3-context.md)
> **Note**: キャラクター設定は不要。このフェーズではPerl技術実装に集中。

## 概要

物語の中で使用される「患部（Before code）」と「治療後（After code）」のコードを作成し、実際に動作することを確認します。
ファイルパスには、Phase 1, 2 と同様の `<slug>` (ケバブケース) を使用してください。

## Step 1: Bad Code (症状) の実装

**Sub-Agent Context**: `ThePatient` (Simulated)
プロファイルで設定された「患者のスキルレベル」に合わせて、リアリティのある「ダメなコード」を `agents/code-doctor-series/<slug>/tests/before/` に実装します。
**構成**: `lib/`, `t/` を作成し、Perl の標準的なディレクトリ構成にします。
- **わざとらしくしすぎない**: 「初心者がやりがちなミス」や「仕様変更で崩れた設計」を模倣する。
- **コメント**: 苦し紛れのコメント（`// どうして動くかわからないけど触るな`）などがあれば物語性が増す。

## Step 2: Good Code (処方) の実装

**Sub-Agent Context**: `TheDoctor`
デザインパターンを適用した理想的なコードを `agents/code-doctor-series/<slug>/tests/after/` に実装します。
**構成**: `lib/`, `t/` を作成し、Perl の標準的なディレクトリ構成にします。
- **簡潔さ**: ドクターの性格を反映し、無駄のない美しいコードにする。
- **命名**: 適切かつ明確な命名規則。

## Step 3: 検証 (Testing)

作成したコードが実際に動作するか検証します。
（`/series-unified-code` のテスト自動実行ステップを呼び出すか、同様の手順を実行）

## Output Requirements

- `agents/code-doctor-series/<slug>/tests/` 配下に以下のディレクトリを作成して実装されていること。
  - `before/`: 患部（治療前）コード
  - `after/`: 処方（治療後）コード
- 各ディレクトリ内は Perl らしく `lib/`, `t/` を作成して実装すること。
  - `<slug>`: デザインパターン名のケバブケース（例: `factory-method`）
- 作成されたテストが全て Pass していること。
