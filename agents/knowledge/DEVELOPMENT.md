# 開発ガイドライン

## Git / PR運用
- **ブランチ名**: `feature/write-hugo-article`, `fix/images-optimization` 等、意図を明確に。
- **PRタイトル**: `[post] 記事タイトル` / `[site] 修正内容`
- **Draft維持**: 記事作成中はフロントマターの `draft: true` を維持し、完成時に外す（またはPRマージ時）。

## テスト・検証
- **自動テスト**: プロダクトコードではないためCIでの自動テストはない。
- **手動検証 (必須)**:
  - 記事内のコード例は、必ず一時的なテストコードを作成して動作確認を行う。
  - 検証コードは `agents/tests/<slug>/` に保存する。
  - 警告 (Warning) レベルのメッセージも出ないよう修正する。
- **リンク確認**: リンク切れがないか確認する。

## ブラウザ自動化 (Browser Automation)
Web操作が必要な場合は `agent-browser` スキル/ツールを使用する。

- **基本フロー**:
  1. `agent-browser open <url>`
  2. `agent-browser snapshot -i` (インタラクティブ要素のID取得)
  3. `agent-browser click @e1` / `fill @e2 "text"`
  4. ページ遷移後は再度 snapshot を取得
