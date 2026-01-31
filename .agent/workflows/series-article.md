---
description: 連載構造案からシリーズ記事を作成するワークフロー
---

# シリーズ記事作成ワークフロー

> 前提: `/planning-v2` で連載構造案が作成済み
> 参照: [PLANNING_STATUS.md](../../PLANNING_STATUS.md)

---

## 概要

このワークフローは planning-v2 で生成された連載構造案（`agents/structure/*.md`）を
使用して、シリーズ記事を作成します。

---

## フェーズ構成

| Phase | コマンド | 内容 | 必須 |
|---|---|---|---|
| 1 | `/series-unified-prepare` | 構造案読み込み・設定 | ● |
| 2 | `/series-unified-code` | コード実装・テスト | ● |
| 3 | `/series-unified-write` | 原稿作成 | ● |
| 4 | `/series-unified-visual` | 挿絵生成 | ○ (オプション) |
| 5 | `/series-unified-review` | レビュー・公開 | ● |

> [!TIP]
> Phase 4（挿絵生成）はオプションです。デフォルトではスキップされ、`/series-unified-visual` で後から実行できます。

---

## Step 0: 前提確認

// turbo
```bash
cat PLANNING_STATUS.md | grep -E "^\|.*✏️ 採用済み" | head -10
```

1. 連載構造案が存在することを確認
2. 構造案のステータスが「✏️ 採用済み」であることを確認
3. 該当がなければ「使用可能な構造案がありません。`/planning-v2` で構造案を作成してください」と案内

---

## Step 1: 出力形式の選択

ユーザーに確認:

| 形式 | 説明 | 推奨 |
|------|------|------|
| **統合版** | 全章を1記事にまとめる | ★ |
| **連載版** | 各回を個別記事として公開 | - |

---

## Step 2-6: Phase実行

選択した形式に応じて各Phaseワークフローを順次実行:

1. `/series-unified-prepare` - 構造案読み込み・設定
2. `/series-unified-code` - コード実装・テスト
3. `/series-unified-write` - 原稿作成
4. `/series-unified-review` - レビュー・公開

> [!NOTE]
> 挿絵が必要な場合は、`/series-unified-visual` を別途実行してください。

---

## Step 7: 連載版の追加作業

連載版を選択した場合の追加作業:

### 7.1 記事分割

1. 統合記事を各回に分割
2. 各回のfrontmatterを設定（date は17秒間隔）
3. ファイル命名: `content/post/YYYY/MM/DD/HHMMSS.md`

### 7.2 記事間リンク追加

各記事に以下を追加:

```markdown
---
## 前回の振り返り
（第2回以降）前回は...について学びました。

---
## 次回予告
（最終回以外）次回は...について解説します。
```

### 7.3 目次記事作成

1. 最終回の17秒後に公開
2. タイトル: 「【目次】シリーズ名（全N回）」
3. linkcard 形式で各回をリンク

---

## 完了

全てのPhaseが完了したら、PLANNING_STATUS.md が自動更新されます。

---

## クイックスタート

1. `/planning-v2` で構造案を作成・採用
2. `/series-article` を実行
3. 形式を選択（統合版/連載版）
4. 各Phaseを順次実行
