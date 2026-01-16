---
description: 記事執筆リクエストに対して全ステップを順次自動実行する
---
# PromptCraftsman Orchestrator Workflow

## When to Use

ユーザーが記事執筆リクエストを入力し、全3ステップを順次自動実行したいとき。
または `/orchestrator` で明示的に呼び出されたとき。

## Procedure

1. Step1を実行する
   - アーティファクトディレクトリに 01_interview.md を作成する
   - ユーザーの回答が完了するまで待機する
2. Step2を実行する
   - アーティファクトディレクトリから 01_interview.md を参照する
   - アーティファクトディレクトリに 02_prompt_spec.md を作成する
3. Step3を実行する
   - アーティファクトディレクトリから 02_prompt_spec.md を参照する
   - アーティファクトディレクトリに PROMPT.md を作成する
4. すべての成果物をリポジトリにコピーするか提案する（RULES.md の成果物管理に従う）
5. 完了を報告する

## Output

- システムアーティファクトディレクトリ（絶対パス）
  - 01_interview.md（中間成果物）
  - 02_prompt_spec.md（中間成果物）
  - PROMPT.md（最終成果物）
