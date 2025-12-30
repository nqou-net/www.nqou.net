# デザインパターン調査Issue作成ツール

このディレクトリには、design-patterns-overview.md に記載されている23個のGoFデザインパターンについて、それぞれ詳細な調査を行うためのGitHub Issueを一括作成するスクリプトが含まれています。

## 前提条件

- GitHub CLI (`gh`) がインストールされていること
- GitHub CLI が認証されていること

## 認証の確認

```bash
gh auth status
```

認証されていない場合は、以下のコマンドで認証してください：

```bash
gh auth login
```

## 使用方法

### スクリプトの実行

```bash
cd /home/runner/work/www.nqou.net/www.nqou.net
bash tools/create-design-pattern-issues.sh
```

### 実行可能権限の付与（必要に応じて）

```bash
chmod +x tools/create-design-pattern-issues.sh
./tools/create-design-pattern-issues.sh
```

## 作成されるIssue

スクリプトは以下の23個のIssueを作成します：

### 生成パターン（Creational Patterns）— 5種類
1. Singleton パターンの詳細調査
2. Factory Method パターンの詳細調査
3. Abstract Factory パターンの詳細調査
4. Builder パターンの詳細調査
5. Prototype パターンの詳細調査

### 構造パターン（Structural Patterns）— 7種類
6. Adapter パターンの詳細調査
7. Bridge パターンの詳細調査
8. Composite パターンの詳細調査
9. Decorator パターンの詳細調査
10. Facade パターンの詳細調査
11. Flyweight パターンの詳細調査
12. Proxy パターンの詳細調査

### 振る舞いパターン（Behavioral Patterns）— 11種類
13. Chain of Responsibility パターンの詳細調査
14. Command パターンの詳細調査
15. Interpreter パターンの詳細調査
16. Iterator パターンの詳細調査
17. Mediator パターンの詳細調査
18. Memento パターンの詳細調査
19. Observer パターンの詳細調査
20. State パターンの詳細調査
21. Strategy パターンの詳細調査
22. Template Method パターンの詳細調査
23. Visitor パターンの詳細調査

## Issueの構成

各Issueには以下の情報が含まれます：

- **概要**: パターンの調査目的
- **調査内容**: 
  - パターンの定義と目的
  - 実装方法と具体例（複数のプログラミング言語）
  - メリット・デメリット
  - 利用シーン（フロントエンド、バックエンド、組み込み、クラウドなど）
  - パターン固有の特徴や関連概念
  - モダンな実装方法
  - 参考文献・参考サイト
- **成果物**: `content/warehouse/design-pattern-<パターン名>.md`
- **関連**: 親Issue (#187) と概要ドキュメントへのリンク
- **ラベル**: enhancement, research, design-patterns

## 注意事項

- このスクリプトは一度に23個のIssueを作成します
- 実行前に作成されるIssueの内容を確認してください
- すでに同様のIssueが存在する場合は、スクリプトの実行前に確認してください

## 参考ドキュメント

- [design-patterns-overview.md](../content/warehouse/design-patterns-overview.md): GoFデザインパターンの概要
- [design-patterns-issues-list.md](../content/warehouse/design-patterns-issues-list.md): 作成されるIssueの詳細一覧

## トラブルシューティング

### GitHub CLI が見つからない

```bash
# Ubuntu/Debian
sudo apt install gh

# macOS
brew install gh
```

### 認証エラー

```bash
gh auth login
# 画面の指示に従って認証を完了してください
```

### 権限エラー

リポジトリへの書き込み権限があることを確認してください。

---

作成日: 2025-12-30
