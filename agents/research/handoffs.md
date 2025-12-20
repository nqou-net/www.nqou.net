---
title: "エージェント定義の `handoffs` 項目調査"
draft: true
tags:
- "agent"
- "handoffs"
description: "エージェント定義フロントマターにおける `handoffs` の意味、想定スキーマ、使用例、セキュリティ上の注意点についての調査結果"
---

## 概要

`handoffs` はエージェント間で責務・データ・作業を受け渡す（hand off）ためのメタデータを記述するために使われる想定のフロントマター項目です。本リポジトリ内の既存エージェント定義（`.github/agents/*.agent.md`）を確認したところ、現状は `handoffs` を使った例は含まれていませんでした（該当なし）。

確認したファイル例:
- [/.github/agents/investigative-research.agent.md](.github/agents/investigative-research.agent.md)
- [/.github/agents/github-copilot-otaku.agent.md](.github/agents/github-copilot-otaku.agent.md)


## 想定される用途

- エージェントオーケストレーション：タスクの段階的分割や次のエージェントへの委譲トリガーを記載する
- データパイプライン：出力データの形式や必要フィールド、永続化／一時性を明示する
- セキュリティと同意：どのデータを他エージェントへ渡して良いか（禁則事項）を制約する
- エラー時のフォールバック：失敗時にどのエージェントへ戻す／通知するかを定める


## 推奨スキーマ（YAML 例）

次のような構造を推奨します。用途に合わせて必須/任意を調整してください。

---
handoffs:
  - name: "research-to-outline"
    description: "調査結果をアウトライン作成エージェントへ渡すハンドオフ" 
    from: "investigative-research"
    to: "search-engine-optimization"
    trigger: "completed"           # completed | confidence>0.8 | manual
    data:
      format: "markdown"            # markdown | json | yaml
      required_fields:
        - "summary"
        - "references"
        - "key_findings"
      optional_fields:
        - "raw_notes"
    persist: false                   # true=永続化（ファイル/DB）, false=一時
    retain_for_days: 7               # persist=true の場合の保持日数
    allow_sensitive: false           # 秘匿データを含めて良いか
    verify_schema: true              # 受け取り側でスキーマ検証を行う
---


## 実装上の注意点

- スキーマ検証：`verify_schema: true` を使い、受け取る側が入力をバリデートすること
- 秘密情報の扱い：`allow_sensitive: false` を明示し、フロントマターやコンテンツにシークレットを載せない
- トリガーの実行制御：`trigger` は自動委譲の条件を明確にしておく（例: 成功時、閾値超過時、手動）
- ロギング／監査：ハンドオフのメタ情報（時刻、送信元、送信先、ステータス）を監査ログとして残す設計を検討


## セキュリティとプライバシー

- リポジトリ内にシークレット（APIキー、トークン、認証情報）を入れない（既存ルールに従う）
- ハンドオフで渡すデータは最小限の必要情報に限定する
- 個人情報や機密情報を扱う場合は、受け渡しに暗号化とアクセス制御を適用する


## 運用上の提案（本リポジトリ向け）

- まずは `handoffs` を必須化せず任意項目として導入する
- サンプルのハンドオフ定義を 1-2 個 `.github/agents/*.agent.md` に追記してワークフローを文書化する
- 自動化を行う際は、まずは手動ワークフローで想定のデータフローを検証する


## まとめ

- 本リポジトリ内に `handoffs` の実例は見つかりませんでした
- `handoffs` はエージェント間の責務やデータ受け渡しを明示するための有用なメタ情報として設計可能です
- 上記の推奨スキーマと運用上の注意に従えば、安全に導入できる見込みです


## 参考（実装例）

- 簡単な受け渡しフロー：`investigative-research` が `research-to-outline` を出力 → `search-engine-optimization` が検証して次ステップへ


---

作成日: 2025-12-20
作成者: エージェント調査
