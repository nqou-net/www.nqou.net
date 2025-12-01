## 記事生成プロンプトテンプレート

用途: 新規ブログ記事のドラフトを生成するためのテンプレート。

使い方:
- 必要な変数: `title`, `description`, `tags`（配列）、`audience`（読者の想定）
- 生成される Markdown は必ず front matter（YAML）を含め、`draft: true` にすること。

Front matter の例（必ず含める）:

---
title: "{title}"
description: "{description}"
tags: [{tags}]
draft: true
---

本文生成の指示例:
- 読者: `{audience}`
- トーン: 技術的で丁寧（日本語）。
- 構成: イントロ、問題提起、実装／手順、結果、まとめ、参考リンク。
- コードブロックがあれば言語を指定し、簡潔な説明を付ける。

出力要件:
- 生成されたファイルは `content/post/` に置く想定だが、エージェントはファイル作成のみを行う（公開はユーザーが行う）。
- 文章内に個人情報や秘密情報を含めないこと。

例: `title="Hugoでのドラフト運用"`, `description="エージェント向け投稿フロー"`, `tags="hugo,ci,automation"`
