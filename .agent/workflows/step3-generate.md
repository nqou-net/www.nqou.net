---
description: 設計書からブログ記事執筆用のプロンプトを生成する
---
# Step3 Generate Workflow

## When to Use

Step2完了後（02_prompt_spec.md が作成されている状態）。
または `/step3-generate` で明示的に呼び出されたとき。

## Procedure

1. アーティファクトディレクトリから 02_prompt_spec.md を読み込み、要件を抽出する
2. プロンプト本体のみを生成する（RULES.md の制約に従う）
3. 品質基準（RULES.md）に照らしてセルフチェックする
4. システムアーティファクトディレクトリに記録する

## Output

- システムアーティファクトディレクトリ（絶対パス）
  - PROMPT.md: プロンプト本体のみ（最終成果物）
