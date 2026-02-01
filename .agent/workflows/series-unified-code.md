---
description: "連載構造案から統合記事を作成する汎用ワークフロー（Phase 2: コード実装）"
---

# Phase 2: コード実装（汎用）

> 前: `/series-unified-prepare` | 次: `/series-unified-write`
> 知見ベース: [workflow-insights.md](../../agents/knowledge/workflow-insights.md)

---

## Step 0: 知見の読み込み

// turbo
1. 知見ファイルの確認:
   ```bash
   grep -A 20 "series-unified-code" agents/knowledge/workflow-insights.md 2>/dev/null
   ```
2. 関連する知見を抽出し、今回のコード実装に活かす
3. 特に「失敗パターン」に注目（UTF-8問題、パッケージ依存関係など）

---

## 前提条件

以下の情報がPhase 1で決定済み：

- 構造案ファイルパス
- 採用案
- テストディレクトリパス

---

## Step 1: テストディレクトリ作成

構造案のスラッグに基づきディレクトリを作成：

// turbo
```bash
# {SLUG} を構造案のスラッグに置き換え
mkdir -p agents/tests/{SLUG}/lib
mkdir -p agents/tests/{SLUG}/t
```

---

## Step 2: コード例の抽出

構造案の「連載構造表」から、各回のコード例を抽出：

| 回 | コード例1（問題版） | コード例2（改善版） |
|----|---------------------|---------------------|
| 1 | （構造案から抽出） | （構造案から抽出） |
| 2 | ... | ... |
| N | ... | ... |

---

## Step 3: 全コード例の実装

構造案のストーリーに従い、各コード例を実装：

### 実装ルール

1. **動く→破綻→パターン導入→完成** のストーリーに沿う
2. **コード例1（問題版）**: 問題を体感できる設計
3. **コード例2（改善版）**: パターン導入による改善
4. 各ファイルは単体で実行可能にする

### ファイル配置

```
agents/tests/{SLUG}/
├── lib/
│   ├── example1_problem.pl
│   ├── example1_solution.pl
│   ├── example2_problem.pl
│   └── ...
└── t/
    ├── 01_example1.t
    └── ...
```

---

## Step 4: テストファイル作成

各コード例に対応するテストを作成：

```perl
#!/usr/bin/env perl
use v5.36;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";

subtest 'コード例1 - 問題版' => sub {
    require 'example1_problem.pl';
    # テストコード
};

subtest 'コード例2 - 改善版' => sub {
    require 'example1_solution.pl';
    # テストコード
};

done_testing;
```

---

## Step 5: テスト実行

すべてのテストを実行：

// turbo
```bash
cd agents/tests/{SLUG} && prove -l t/
```

### チェックリスト

- [ ] すべてのテストがpass
- [ ] 警告が出ていない
- [ ] コード例1→コード例2への遷移が自然
- [ ] パターン/改善の効果が明確

---

## Step 6: コード動作確認

実際にコードを実行して動作を確認：

1. 各回のコード例1を実行し、「問題」を確認
2. 各回のコード例2を実行し、「改善」を確認
3. 最終統合版の完全動作を確認

```bash
# 例: 個別実行
perl agents/tests/{SLUG}/lib/example1_problem.pl
perl agents/tests/{SLUG}/lib/example1_solution.pl
```

---

## 完了後

→ `/series-unified-write` へ進む

---

## 注意事項

- コードは原稿作成前に全て動作確認
- テストは記事のコード例と一致させる
- 依存モジュールは冒頭でインストール確認

---

## Step 7: 知見の記録

今回のコード実装で得た気づきを `agents/knowledge/workflow-insights.md` に追記:

```markdown
## YYYY-MM-DD: <コンテンツ名>

### ワークフロー: series-unified-code

### 知見タイプ: <成功/失敗/発見/フィードバック/改善>

**コンテキスト**: <状況の説明>

**知見**: <学んだこと>

**適用場面**: <今後どんな場面で活用できるか>
```

### 記録すべき典型例

- UTF-8/エンコーディング問題
- パッケージ依存関係の解決方法
- テスト作成のベストプラクティス
- デバッグ中に発見したコツ

> [!NOTE]
> 知見がない場合はこのステップをスキップ可能

