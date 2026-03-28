---
name: series-author
description: マニフェストに従い、シリーズ技術記事を生成する統合執筆スキル（Phase 0〜4）
---

# Series Author

マニフェスト（世界観・ペルソナ・プロット定義）を読み込み、技術解説記事を生成する。
全シリーズ共通のワークフロー（`.agent/workflows/phase-{0..4}-*.md`）で実行。

## 入力（必須）

| 項目 | 説明 | 例 |
|------|------|----|
| シリーズ名 | マニフェスト名 | `code-detective`, `code-doctor` |
| テーマ | パターン名 | `Strategy`, `God Class` |
| slug | ケバブケース | `strategy-pattern` |

## 実行フロー（Phase 0-R→0→4 順次実行）

各Phase終了時に `AskUserQuestion` で次Phase進行の承認を取る。
タイトル案など複数候補がある場合も `AskUserQuestion` で選択式に提示。

| Phase | ワークフロー | 出力 | 進行条件 |
|-------|-------------|------|----------|
| 0-R 調査 | `phase-0-research.md` | `agents/warehouse/<slug>.md` | 鮮度判定による再利用/再調査の決定 |
| 0 企画 | `phase-0-planning.md` | — | **ユーザー承認必須**（`AskUserQuestion` で承認/差し戻し） |
| 1 設計 | `phase-1-profiling.md` | `agents/<series>/structure/<slug>.md` | 変化点の明記 |
| 2 実装 | `phase-2-coding.md` | `agents/<series>/tests/<slug>/` | **全テストパス（警告不可）** |
| 3 執筆 | `phase-3-writing.md` | `content/post/YYYY/MM/DD/<slug>.md` | 変化点の本文反映 |
| 4 校閲 | `phase-4-review.md` | — | **全チェック項目クリア**（`AskUserQuestion` で最終承認） |

## テーマ調査（Phase 0-R）

Phase 0 の企画に先立ち、テーマに関するウェブ調査を実行する。

### 調査の実行
- `investigative-research` または `websearch-nerd` サブエージェントに委任
- 調査結果は `agents/warehouse/<slug>.md` に保存

### 既存調査の鮮度判定
既存の `agents/warehouse/<slug>.md` がある場合、フロントマターの `date` と `staleness_category` から再調査の要否を判定する。

| `staleness_category` | 有効期間 | 対象例 |
|---|---|---|
| `stable` | 18ヶ月 | GoFパターン定義、SOLID原則 |
| `moderate` | 9ヶ月 | 言語固有の実装、アンチパターン |
| `volatile` | 3ヶ月 | フレームワーク・ライブラリ固有 |

`staleness_category` 未設定時は `moderate`（9ヶ月）をデフォルトとする。
ユーザーが明示的に再調査を指示した場合は有効期間内でも再調査する。

## 中間ファイルの管理

中間ファイル（構造案・テストコード）は `agents/<series>/` 配下にシリーズ単位で格納する。
シリーズの中間ファイルを一括削除したい場合は `rm -rf agents/<series>/` で対応できる（git履歴で復元可能）。

## 品質ルール（絶対）

### ゲート制約
- Phase 0 未承認（`AskUserQuestion` で承認を得ていない状態）で Phase 1 へ進まない
- テスト未通過コードを記事に掲載しない

### 語り部制約
- 地の文はマニフェスト指定の語り部の一人称のみ。神の視点・主人公の内面描写は禁止

### 反復回避
- 同シリーズ直近3本の構造案/記事を事前確認し、語り口・導入・決め台詞・オチ・比喩の重複を把握
- ペルソナ定義の口癖・定番リアクションは参照情報であり、逐語反復の義務ではない
- 1本ごとに最低3軸を意図的に変更（例: 温度感、導入シーン、問いの立て方、余韻）
- 語り部を「困惑→質問→即納得」の定型装置にしない。職種・経験・切迫度・性格に応じた固有反応を付与
- Phase 1 の変化点が本文・レビューに未反映 → 未完成
- 既存回の焼き直し → 差し戻し修正
