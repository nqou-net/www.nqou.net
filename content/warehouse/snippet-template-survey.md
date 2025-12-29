# スニペット／テンプレート管理ソフト調査

## 概要
エディタ内でのスニペットや、システム全体でのテンプレート入力（テキスト展開）を実現する代表的なツール・手法を整理。想定ユースケースは「コード編集でのプレースホルダ付きテンプレート」「複数アプリで使えるスニペット」「プロジェクト雛形の生成」など。

## ユースケース別要件（短縮）
- コード編集: プレースホルダ、タブ移動、言語ごとのスコープ、シェア化
- 文書・メール定型: クロスアプリ、短縮キー、マクロ／条件分岐
- プロジェクト生成: テンプレート置換、対話的入力、ファイル生成
- チーム共有: バージョン管理、アクセス制御

## 代表的なツール（要点）
- Visual Studio Code Snippets
  - 組み込みスニペット機能。プレースホルダ、タブストップ、スニペットファイル（JSON）で定義
  - 拡張で共有やGUI編集が可能
  - 用途: コード編集の定型化

- Emmet
  - HTML/CSSの高速展開に特化。VS Codeなどに組み込み済み
  - 用途: マークアップの短縮展開

- JetBrains Live Templates
  - IntelliJ系のテンプレート。式や定義済み変数、スコープあり
  - 用途: IDE内で高度なテンプレ化

- Vim/Neovim: UltiSnips / LuaSnip / snipMate
  - プレースホルダ、Python等での動的生成（UltiSnips）やLuaでの軽量スニペット（LuaSnip）
  - 用途: Vimエコシステムでの柔軟なスニペット管理

- Emacs: yasnippet
  - 強力なテンプレート、Elispによる動的処理
  - 用途: Emacs内で高度なスニペット

- TextExpander（商用, macOS/Windows）
  - クロスアプリのテキスト展開、日時・クリップボード・スニペット変数など豊富
  - チーム共有プランあり
  - 用途: メール・文書・あらゆるアプリでの定型入力

- aText / Typinator / aText（macOS）
  - ローカルで安価に使えるスニペット展開ツール

- Espanso（OSS, クロスプラットフォーム）
  - オープンソースのテキストエクスパンダ。正規表現トリガー、スクリプト実行、クロスアプリ
  - 用途: 無料で広範囲に使えるテキスト展開

- AutoHotkey（Windows）
  - キーボードマクロ／スニペット、強力な自動化
  - 用途: Windows上での高度なキーボード自動化

- Alfred / Keyboard Maestro（macOS）
  - Alfredはスニペット機能（有料Powerpack）、Keyboard Maestroはより複雑なマクロ/テンプレ化
  - 用途: macOSのアプリ間ワークフロー自動化

- SnippetsLab / Boostnote（スニペット管理アプリ、主にmacOS）
  - コードスニペットの保存・検索・管理に特化（展開は外部ツールと組合せ）

- Snippet sharing / storage
  - GitHub Gist, Snippet Store などでスニペットを共有

- プロジェクトテンプレート／スキャフォールディング
  - Cookiecutter（Python）, Yeoman（JS）, Plop.js（軽量コードジェネレータ）, Hugo archetypes（Hugo用）
  - 用途: プロジェクトや記事テンプレートの生成

- AIベース補完（参考）
  - GitHub Copilot, TabNine などはコードの文脈からテンプレ化を支援するが、固定のスニペット管理とは役割が異なる

## 比較・選び方ガイド（簡潔）
- エディタ内だけで完結したい → `VS Code Snippets` / `JetBrains Live Templates` / `UltiSnips` / `yasnippet`
- OSを横断してどのアプリでも展開したい → `TextExpander`（有料）か `Espanso`（OSS）
- macOS中心で細かいマクロも欲しい → `Keyboard Maestro`
- チームで共有したい → 管理しやすいクラウド付き（TextExpander）またはGitでスニペットを管理
- プロジェクト雛形を作る → `Cookiecutter` / `Yeoman` / `Plop.js` / `Hugo archetypes`

## 実装（運用）上の留意点
- スニペットに秘密情報を含めない（APIキー等）
- チーム共有時はバージョン管理のルールを決める
- 言語ごとのスコープ設定で誤展開を防ぐ
- 置換やスクリプト実行を使う際はセキュリティ（任意コード実行）に注意

## 推奨（短く）
- コード中心: `VS Code Snippets` + 必要なら `Emmet`／`Hugo archetypes`（ブログ）
- クロスアプリ短縮: まず `Espanso` を試し、必要なら `TextExpander` を検討
- Vim/Emacs: 既存エコシステムの `UltiSnips` / `LuaSnip` / `yasnippet`
- チーム用テンプレート（プロジェクト）: `Cookiecutter` または言語に合ったジェネレータ

---
作成日: 2025-12-23
作成者: agents/research 自動生成
