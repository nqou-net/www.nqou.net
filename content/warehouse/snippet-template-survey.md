---
title: "スニペット・テンプレート管理ソフト調査"
draft: false
tags:
  - snippet
  - template
  - text-expander
  - productivity
description: "エディタ内でのスニペットや、システム全体でのテンプレート入力（テキスト展開）を実現する代表的なツール・手法を整理。VS Code Snippets、Espanso、JetBrains Live Templatesなどの比較と選び方ガイド。"
---

# スニペット・テンプレート管理ソフト調査

## 調査概要

- **調査日**: 2025年12月30日
- **調査目的**: エディタ内でのスニペットや、システム全体でのテンプレート入力（テキスト展開）を実現する代表的なツール・手法を整理
- **想定ユースケース**: コード編集でのプレースホルダ付きテンプレート、複数アプリで使えるスニペット、プロジェクト雛形の生成など

## ユースケース別の要件

### コード編集
- プレースホルダとタブストップによる入力補完
- タブ移動（`$1`, `$2`, `$0`など）
- 言語ごとのスコープ設定
- チーム内での共有機能
- 変数と変換（transformations）のサポート

### 文書・メール定型
- クロスアプリケーション対応
- 短縮キー・トリガー設定
- マクロや条件分岐
- 日時・クリップボード変数の挿入

### プロジェクト生成
- テンプレート変数の置換
- 対話的な入力
- ファイル・ディレクトリ構造の生成
- カスタムスクリプトの実行

### チーム共有
- バージョン管理対応
- アクセス制御
- クラウド同期（オプション）

## 主要ツールの詳細調査

### Visual Studio Code Snippets

**概要**
- VS Code組み込みのスニペット機能
- JSON形式で定義
- TextMate snippetシンタックスベース（interpolated shell code と `\u` は非サポート）

**主要機能**
- **Tabstops**: `$1`, `$2`, `$0`で入力位置を制御
- **Placeholders**: `${1:defaultValue}`でデフォルト値付き入力欄
- **Choice**: `${1|one,two,three|}`で選択肢を提示
- **Variables**: `TM_FILENAME`, `CURRENT_YEAR`, `CLIPBOARD`など豊富な定義済み変数
- **Variable transforms**: 正規表現による変数の変換
- **File template snippets**: `isFileTemplate`でファイル全体のテンプレート化

**スコープ設定**
- 言語別スニペットファイル（例: `javascript.json`）
- グローバルスニペット（`.code-snippets`）
- プロジェクト固有スニペット（`.vscode`フォルダ内）
- `scope`プロパティで複数言語対応

**共有方法**
- Marketplace経由で拡張機能として配布
- プロジェクト内`.vscode`フォルダで共有
- GitHubなどで管理

**参考リンク**
- {{< linkcard "https://code.visualstudio.com/docs/editor/userdefinedsnippets" >}}

### Espanso

**概要**
- オープンソース（GPL-3.0）のクロスプラットフォーム・テキストエクスパンダ
- Rust製で高速・信頼性が高い
- プライバシー優先（100%ローカル、トラッキングなし）
- バージョン: v2.3.0（2024年10月12日リリース）

**主要機能**
- クロスプラットフォーム対応（Windows、macOS、Linux）
- ほぼすべてのアプリケーションで動作
- 絵文字サポート 😄
- 画像の挿入
- 強力な検索バー 🔎
- 日付展開サポート
- カスタムスクリプト実行
- シェルコマンドサポート
- アプリ固有の設定
- フォーム機能（対話的入力）
- パッケージマネージャー内蔵（espanso hub）
- ファイルベースの設定（YAML）
- 正規表現トリガー対応
- 実験的Waylandサポート

**設定例**
```yaml
matches:
  - trigger: ":hello"
    replace: "Hi There!"
  - triggers: [":test1", ":test2"]
    replace: "These both expand to the same thing"
```

**チーム共有**
- 設定ファイルをGitで管理
- espanso hub経由でパッケージ共有

**参考リンク**
- {{< linkcard "https://github.com/espanso/espanso" >}}
- {{< linkcard "https://espanso.org/" >}}

### JetBrains Live Templates

**概要**
- IntelliJ IDEA系IDEに組み込み
- コンテキスト依存の高度なテンプレート

**テンプレートの種類**
1. **Simple templates**: 固定テキストの挿入
   - `psfs` → `public static final String`
   - `main` / `psvm` → `public static void main(String[] args){ }`
   - `sout` → `System.out.println();`

2. **Parameterized templates**: 変数入力
   - `for` → `for (int i = 0; i < ; i++) { }`
   - `ifn` → `if (var == null) { }`

3. **Surround templates**: 選択範囲を囲む
   - 例: タグで囲む

**特徴**
- 式や定義済み変数のサポート
- 言語ごとのスコープ設定
- テンプレート変数の自動計算
- ダイアレクト（方言）指定可能

**参考リンク**
- {{< linkcard "https://www.jetbrains.com/help/idea/using-live-templates.html" >}}

### Vim/Neovim スニペットプラグイン

**UltiSnips**
- プレースホルダ対応
- Pythonによる動的生成
- 強力なカスタマイズ性

**LuaSnip**
- Luaベースの軽量スニペット
- Neovim向け最適化
- 高速動作

**snipMate**
- シンプルな実装
- TextMate互換

### Emacs: yasnippet

- Elispによる動的処理
- 強力なテンプレート機能
- Emacsエコシステムに統合

### テキストエクスパンダ（クロスアプリ対応）

#### TextExpander（商用）
- macOS / Windows対応
- クロスアプリケーション対応
- 日時・クリップボード・変数など豊富な機能
- チーム共有プランあり
- 有料（サブスクリプション）

#### aText / Typinator（macOS）
- ローカルで安価に使える
- macOS専用
- 基本的なテキスト展開機能

#### AutoHotkey（Windows）
- キーボードマクロとスニペット
- 強力な自動化機能
- スクリプト言語による高度なカスタマイズ

#### Alfred / Keyboard Maestro（macOS）
- Alfred: スニペット機能（有料Powerpack）
- Keyboard Maestro: 複雑なマクロ/テンプレート化
- アプリ間ワークフロー自動化

### スニペット管理アプリ

#### SnippetsLab（macOS）
- コードスニペットの保存・検索・管理
- タグ付け・整理機能
- 展開は外部ツールと組み合わせ

#### Boostnote
- マークダウン対応
- クロスプラットフォーム
- オープンソース

### スニペット共有サービス

- **GitHub Gist**: 公開・非公開スニペット共有
- **Snippet Store**: スニペット専用ストレージ

### プロジェクトテンプレート・スキャフォールディング

#### Cookiecutter（Python）
- Pythonプロジェクトのテンプレート生成
- Jinja2テンプレートエンジン使用
- 豊富なテンプレート集

#### Yeoman（JavaScript）
- Node.jsプロジェクトのジェネレータ
- プラグインエコシステム
- 対話的プロジェクト生成

#### Plop.js
- 軽量コードジェネレータ
- カスタマイズ容易
- プロジェクト内マイクロジェネレータ

#### Hugo archetypes
- Hugo専用のコンテンツテンプレート
- Markdownファイル生成
- フロントマター自動設定

### AIベース補完（参考）

#### GitHub Copilot
- コード文脈からの補完
- 自然言語からのコード生成
- 固定スニペットとは異なるアプローチ

#### TabNine
- AI駆動のコード補完
- マルチ言語対応
- ローカル＋クラウドモデル

## 比較・選び方ガイド

### エディタ内完結
- **VS Code**: `VS Code Snippets` + Marketplace拡張
- **JetBrains**: `Live Templates`
- **Vim/Neovim**: `UltiSnips` / `LuaSnip`
- **Emacs**: `yasnippet`

### クロスアプリケーション
- **無料・OSS**: `Espanso`（推奨）
- **有料・高機能**: `TextExpander`
- **macOS**: `Alfred` / `Keyboard Maestro`
- **Windows**: `AutoHotkey`

### プロジェクト雛形生成
- **Python**: `Cookiecutter`
- **JavaScript/Node.js**: `Yeoman` / `Plop.js`
- **Hugo**: `Hugo archetypes`
- **汎用**: プロジェクト固有のテンプレートスクリプト

### チーム共有
- クラウド同期: `TextExpander`（有料）
- Git管理: `Espanso` / エディタスニペット
- Marketplace: `VS Code Snippets`

## 技術的な考慮事項

### セキュリティ
- スニペットに秘密情報（APIキー、パスワード等）を含めない
- スクリプト実行を使う場合は任意コード実行のリスクに注意
- 環境変数や外部ファイル参照を活用

### バージョン管理
- スニペット定義ファイルをGitで管理
- チーム内でのルール統一
- 変更履歴の追跡

### スコープ設定
- 言語ごとのスニペット分離
- プロジェクト固有とグローバルの使い分け
- 誤展開防止のためのトリガー設計

### パフォーマンス
- 大量のスニペット登録時の検索速度
- メモリ使用量
- 起動時間への影響

## 推奨構成

### 個人開発者（コード中心）
1. メインエディタのスニペット機能（VS Code / JetBrains / Vim）
2. Emmet（HTML/CSS高速展開）
3. 必要に応じてEspanso（クロスアプリ）

### チーム開発
1. プロジェクト固有スニペット（`.vscode`など）
2. Git管理による共有
3. プロジェクトテンプレート（Cookiecutter / Yeoman）

### 文書作成・業務効率化
1. Espanso（無料・クロスプラットフォーム）
2. 必要に応じてTextExpander（有料・高機能）

### macOS特化
1. Alfred（スニペット + ワークフロー）
2. Keyboard Maestro（複雑な自動化）

## 最新トレンド（2025年時点）

### AIとの統合
- GitHub Copilotなどとスニペットの使い分け
- 定型的なパターン: スニペット
- 文脈依存・複雑なロジック: AI補完

### クロスプラットフォーム対応
- Espansoの台頭（Rust製、高速、OSS）
- Wayland対応の進展（Linux）

### チーム共有の重要性
- スニペットのコード化（Infrastructure as Code的アプローチ）
- CI/CDパイプラインとの統合

## 参考資料

### 公式ドキュメント
- VS Code Snippets: https://code.visualstudio.com/docs/editor/userdefinedsnippets
- Espanso: https://espanso.org/docs/
- JetBrains Live Templates: https://www.jetbrains.com/help/idea/using-live-templates.html

### コミュニティ
- Espanso Hub: https://hub.espanso.org/
- VS Code Marketplace: https://marketplace.visualstudio.com/vscode

---

**作成日**: 2025年12月30日  
**調査者**: GitHub Copilot（AI Assistant）  
**調査方法**: 公式ドキュメント、GitHubリポジトリ、技術ブログの調査  
**信頼度**: 高（公式情報源ベース）
