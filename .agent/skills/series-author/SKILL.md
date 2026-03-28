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

## 実行フロー（Phase 0→4 順次実行）

各Phase終了時に `AskUserQuestion` で次Phase進行の承認を取る。
タイトル案など複数候補がある場合も `AskUserQuestion` で選択式に提示。

| Phase | ワークフロー | 出力 | 進行条件 |
|-------|-------------|------|----------|
| 0 企画 | `phase-0-planning.md` | — | **ユーザー承認必須**（`AskUserQuestion` で承認/差し戻し） |
| 1 設計 | `phase-1-profiling.md` | `agents/structure/<series>-<slug>.md` | 変化点の明記 |
| 2 実装 | `phase-2-coding.md` | `agents/tests/<series>-<slug>/` | **全テストパス（警告不可）** |
| 3 執筆 | `phase-3-writing.md` | `content/post/YYYY/MM/DD/<slug>.md` | 変化点の本文反映 |
| 4 校閲 | `phase-4-review.md` | — | **全チェック項目クリア**（`AskUserQuestion` で最終承認） |

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
