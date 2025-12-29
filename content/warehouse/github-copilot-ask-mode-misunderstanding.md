---
title: "GitHub Copilot Chat の Ask/Edit/Agent/Plan モード調査レポート"
slug: "github-copilot-ask-mode-misunderstanding"
date: 2025-12-28
tags:
   - github-copilot
   - ask-mode
   - plan-mode
description: "Ask/Edit/Agent/Plan 各モードの正しい使い分けと、Ask モードのリポジトリ調査能力を中心に整理した調査レポート。"
image: /favicon.png
draft: true
---

## タイトル
GitHub Copilot Chat の Ask/Edit/Agent/Plan モード調査レポート

## 調査目的

GitHub Copilot Chat の Ask/Edit/Agent/Plan モードの理解と使い分けについての記事を作成するための情報収集。特に、Ask モードに対するユーザーの誤解（単なる調べ物ツールではなく、リポジトリ調査にも活用できる）と、Plan モードの優位性（調査から実装までのシームレスな流れ）を明らかにする。

## 実施日

2025年12月28日

## 参照元URL

### メインリファレンス（Zenn記事）

1. **GitHub Copilot Chat の Ask/Edit/Agent モードをコードレベルで理解して使い分ける**
   - URL: https://zenn.dev/openjny/articles/5487004a195051
   - 要点: Ask/Edit/Agentモードの実装詳細、VS Code拡張の package.json での chatAgents 登録、各モードの内部動作をコードレベルで解説

2. **GitHub Copilot Chat の Plan "モード" をコードレベルで理解する**
   - URL: https://zenn.dev/openjny/articles/43e010c65faa9a
   - 要点: Plan モードはカスタムエージェントとして実装されており、intents ベースの他のモードとは設計が異なる。Plan.agent.md による定義、実装前の計画立案に特化

### 公式ドキュメント

3. **GitHub Copilot Chat**
   - URL: https://docs.github.com/copilot/using-github-copilot/copilot-chat
   - 要点: 公式の基本的な使い方、各モードの概要

4. **プロジェクトを探索するための GitHub Copilot の使用**
   - URL: https://docs.github.com/ja/get-started/exploring-projects-on-github/using-github-copilot-to-explore-projects
   - 要点: Askモードでのリポジトリ探索、@workspace メンション機能の活用法

5. **GitHub Copilot のチュートリアル**
   - URL: https://docs.github.com/ja/copilot/tutorials
   - 要点: 実践的な使い方のチュートリアル集

### GitHub公式ブログ

6. **Copilot ask, edit, and agent modes: What they do and when to use them**
   - URL: https://github.blog/ai-and-ml/github-copilot/copilot-ask-edit-and-agent-modes-what-they-do-and-when-to-use-them/
   - 要点: 各モードの使い分けガイドライン、実用例

7. **Agent mode 101: All about GitHub Copilot's powerful mode**
   - URL: https://github.blog/ai-and-ml/github-copilot/agent-mode-101-all-about-github-copilots-powerful-mode/
   - 要点: Agent モードの詳細解説、自律的なタスク実行能力

8. **From idea to PR: A guide to GitHub Copilot's agentic workflows**
   - URL: https://github.blog/ai-and-ml/github-copilot/from-idea-to-pr-a-guide-to-github-copilots-agentic-workflows/
   - 要点: Issue から実装までのワークフロー、Plan モードとの連携

### Microsoft Learn

9. **Ask, Edit, and Agent - In-depth Overview of GitHub Copilot Chat Modes**
   - URL: https://learn.microsoft.com/en-us/shows/visual-studio-code/ask-edit-and-agent-in-depth-overview-of-github-copilot-chat-modes
   - 要点: VS Code における各モードの詳細な動作説明

10. **Use Agent Mode - Visual Studio (Windows)**
    - URL: https://learn.microsoft.com/en-us/visualstudio/ide/copilot-agent-mode?view=visualstudio
    - 要点: Visual Studio でのエージェントモードの使い方

### 日本語コミュニティ記事

11. **VS Code GitHub Copilot Ask・Edit・Agent 完全攻略ガイド**
    - URL: https://note.com/iepyon/n/n15fd85adc473
    - 要点: 実務での使い分け、運用例、コツ

12. **GitHub Copilot Agent/Plan/Edit/Ask の使い分け**
    - URL: https://qiita.com/ELIXIR/items/508b7f1797f7cda8468e
    - 要点: 4つのモードの比較表、選択基準

13. **GitHub Copilot の 3 つのモード（Ask, Edit, Agent）の正しい使い分け**
    - URL: https://zenn.dev/m0t0taka/articles/8a239c4b2d0ebd
    - 要点: 実践的な使い分けのポイント

14. **GitHub Copilotの使い方を解説、vscode対応、ショートカットも紹介**
    - URL: https://www.ai-souken.com/article/how-to-use-github-copilot
    - 要点: 初心者向けの基本的な使い方、@workspace の活用

15. **GitHub Copilot Workspaceとは？プロジェクト管理との違い・連携方法を解説**
    - URL: https://www.ai-souken.com/article/what-is-github-copilot-workspase
    - 要点: Workspace機能との連携、Issue起点の開発支援

16. **ワークスペースのチャットをエキスパートに**
    - URL: https://vscode.dokyumento.jp/docs/copilot/reference/workspace-context
    - 要点: @workspace メンション機能の詳細

## 各モードの特徴と違い

### Ask モード（質問・説明）

**主な用途:**
- 対話形式でのQ&A
- コードの解説、エラーの背景説明
- 技術相談、設計思想の確認
- **リポジトリ全体の理解と調査**（重要な使い方）

**特徴:**
- コード自体は変更しない
- 検索・情報収集に最適
- @workspace メンションでリポジトリ全体を対象に質問可能
- ワークスペース分析機能によりアーキテクチャ解説、依存関係の理解が可能

**実装詳細:**
- intent ベースのアーキテクチャ
- package.json の chatAgents として登録
- 短時間での情報取得に最適化

**向いている場面:**
- 既存コードの理解（オンボーディング）
- エラーや設計方針の相談
- 技術選定やAPI利用法の情報収集
- **プロジェクト構造の把握**
- **ファイル間の結合関係の理解**

**弱み:**
- 実際のリファクタや修正はできない
- 具体的な編集には Edit/Agent が必要

### Edit モード（編集・リファクタ）

**主な用途:**
- 選択範囲やファイル単位の直接書き換え
- バグ修正、関数分割、可読性向上
- ピンポイントな編集

**特徴:**
- diff形式で変更案を提示、承認後に反映
- 一度に扱える範囲はファイル単位か一部コード
- 小～中規模のリファクタに最適

**実装詳細:**
- intent ベースのアーキテクチャ
- ファイルレベルでの編集に特化

**向いている場面:**
- 既存コードの部分修正
- スタイル統一
- 型安全化やコメント追加
- エラーハンドリングの追加

**弱み:**
- 複数ファイル横断の大規模リファクタは非対応
- 設計や実装計画までは踏み込まない

### Agent モード（自律自動実行）

**主な用途:**
- 複数ファイル横断・大規模な自動編集
- 新規ファイル作成、プロジェクト全体の構築
- タスク単位での目的指示

**特徴:**
- タスクを分解し実行計画を立て、自律的にコード生成・編集・検証
- @workspace, @vscode, @terminal など広い操作範囲
- 複雑なワークフロー、設計変更、全体構造の見直しが可能

**実装詳細:**
- intent ベースのアーキテクチャ
- より高度な自動化と自律性
- MCP Server やカスタムエージェントとの連携が可能

**向いている場面:**
- 複数ファイル編集
- 新規ファイル作成
- テストコードの自動生成
- チームやプロジェクト全体の横断的改善
- 設計変更を伴う大規模リファクタ

**弱み:**
- 予想外の変更リスク（事前設計や計画が不十分だとずれる）
- 処理に時間がかかる場合がある
- 必ず人間のレビューが必要

### Plan モード（計画・仕様化支援）

**主な用途:**
- 実装前の仕様策定・段取り化・計画立案
- 要件の整理と実施ステップの文書化

**特徴:**
- **実装はしない、計画まで**
- AIが要件を元にステップ（Markdownドキュメントplan.mdなど）を出力
- 不明点があれば対話型で質問→再設計提案を繰り返し可能
- 調査から実装までのシームレスな流れを実現

**実装詳細:**
- **カスタムエージェントとして実装**（他のモードと異なる）
- package.json で `contributes.chatAgents` に登録
- Plan.agent.md による定義
- intent ベースではなく、より拡張性の高いアーキテクチャ

**向いている場面:**
- 要件や仕様が曖昧な段階
- 大規模実装の計画立案（リファクタリング、新機能追加）
- チーム共有や設計レビュー時の合意形成
- **Ask モードでの調査結果を元に実装計画を立てる**

**弱み:**
- 実装自体はしない、あくまで計画まで
- 生成提案は人間のレビューと修正が必要

## ユーザーの誤解のポイント

### Ask モードは「単なる調べ物ツール」ではない

**よくある誤解:**
- Ask モードは技術的な質問をするだけのツール
- ググるのと同じような使い方

**実際の真価:**
- **リポジトリ全体の調査・分析ツール**として強力
- @workspace メンションにより、プロジェクト全体のコンテキストを把握
- アーキテクチャの理解、ファイル間の関係性の把握
- オンボーディング（新規参加者の立ち上がり支援）に最適
- 設計の妥当性検証、セキュリティ観点での質問も可能

**活用例:**
- 「このリポジトリの目的をREADMEから要約してください」
- 「src/ディレクトリの役割は？」
- 「この機能の実装がどのファイルに分散しているか教えて」
- 「このバグの原因として考えられるファイルを列挙して」

**カスタム指示ファイル（.github/copilot-instructions.md）との組み合わせ:**
- AI応答の品質や一貫性が向上
- プロジェクト固有のコンテキストを事前に提供できる

## Plan モードの優位性

### 調査から実装までのシームレスな流れ

**従来のワークフロー:**
1. Ask モードで調査・質問
2. 自分で設計・計画を立てる
3. Edit/Agent モードで実装

**Plan モードを活用したワークフロー:**
1. **Ask モードで調査・質問**
2. **Plan モードで調査結果を元に実装計画を立てる**
3. **Agent モードで計画に基づいて実装**

### シームレスさの利点

**要件の構造化:**
- 曖昧な要件を明確なステップに分解
- 実装の見落としを防ぐ
- チームメンバーとの認識合わせが容易

**反復的な改善:**
- 対話型で計画を洗練
- 不明点を質問しながら段階的に詳細化
- 実装前にレビュー・合意形成が可能

**GitHub Issue/PR との連携:**
- plan.md を Issue に添付して議論
- PR の説明文として活用
- CI/CD パイプラインとの統合

**技術的背景:**
- カスタムエージェントとしての実装により、より柔軟な計画立案が可能
- intent ベースの制約を受けない拡張性

## 競合記事の分析

### 既存の日本語記事の傾向

**一般的な内容:**
- 各モードの基本的な説明
- 使い分けの比較表
- 初心者向けチュートリアル

**不足している視点:**
- Ask モードのリポジトリ調査能力への言及が少ない
- Plan モードの技術的な実装詳細（カスタムエージェント）
- 調査→計画→実装の一連のワークフロー解説
- 実装レベルでの理解（package.json、intent、カスタムエージェント）

### 差別化ポイント

1. **Ask モードの真価を伝える**
   - 単なるQ&Aツールではなく、リポジトリ調査の主要ツール
   - @workspace の活用法の具体例
   - オンボーディングシナリオの提示

2. **Plan モードの技術的背景**
   - カスタムエージェントとしての実装
   - 他のモード（intent ベース）との設計思想の違い
   - GitHub Universe 2025 での発表背景

3. **シームレスなワークフロー**
   - Ask → Plan → Agent の連携
   - 実践的なユースケースの提示
   - Issue/PR との統合方法

4. **コードレベルの理解**
   - Zenn記事を参考に、内部実装への言及
   - VS Code 拡張としての登録方法
   - なぜそのように設計されているかの考察

## 内部リンク調査

このリポジトリで関連するタグを持つ記事を調査した結果、以下のタグで多くの記事が存在：

### 主要タグ

- **ai**: 約60件以上
- **copilot**: 約60件以上
- **prompt**: 約10件以上
- **programming**: 約20件以上

### 2025年11月の GitHub Copilot 関連記事

1. **GitHub Copilot Coding Agent（エージェントパネル）を使ってみた** (2025-11-26)
   - エージェントパネルの初回体験
   - HTML→Markdown変換タスク
   - 変換プログラムの自動生成

2. **GitHub Copilot エージェントパネルでAGENTS.mdを作成した話** (2025-11-27)
   - AGENTS.md（カスタムエージェント定義）の作成
   - 5つの専門エージェント（Content Strategist, Interview Facilitator, Technical Writer, SEO Optimizer, QA）
   - ワークフローの設計

3. **エージェントパネルから記事を生成してみた** (2025-11-29)
   - エージェントパネルからの直接入力
   - AGENTS.md設定の反映
   - AIの自発的な改善

4. **エージェントガイドラインを作成するプロンプトを試してみた** (2025-11-27)
   - GitHub Blog のプロンプトテンプレート利用
   - コーディングエージェント向けガイドライン生成

5. その他多数のエージェント関連記事

### 内部リンク候補

- エージェントパネル関連の記事群（上記）
- AI/Copilot タグの記事
- prompt タグの記事（プロンプトエンジニアリング）

## 発見・結論

### 主要な発見

1. **Ask モードの過小評価**
   - 多くの記事で「質問ツール」としてのみ紹介
   - リポジトリ調査・分析ツールとしての価値が見落とされている
   - @workspace の強力さが十分に伝わっていない

2. **Plan モードの独自性**
   - カスタムエージェントとして実装されている点が技術的に重要
   - 他のモード（intent ベース）とは設計思想が異なる
   - 調査→計画→実装のワークフローで真価を発揮

3. **モード間の連携**
   - 各モードは独立したツールではなく、連携して使うことで効果的
   - Ask → Plan → Agent の流れが特に強力
   - Issue/PR/CI との統合で開発フロー全体を支援

4. **実装レベルの理解の重要性**
   - Zenn記事のようなコードレベルの解説は希少
   - 内部実装を知ることで、より効果的な使い方が見えてくる
   - package.json、intent、カスタムエージェントの理解

### 記事執筆のポイント

1. **Ask モードの再評価**
   - リポジトリ調査ツールとしての側面を強調
   - 具体的なユースケースの提示
   - @workspace の活用法

2. **Plan モードの深掘り**
   - カスタムエージェントとしての技術的背景
   - 調査→計画→実装のシームレスな流れ
   - GitHub Universe 2025 での発表コンテキスト

3. **実践的なワークフロー**
   - Ask/Plan/Agent の連携例
   - Issue/PR との統合方法
   - チーム開発での活用シナリオ

4. **技術的深度**
   - Zenn記事を参考に、内部実装への言及
   - なぜそのように設計されているか
   - 今後の拡張可能性

## 次のステップ

### アウトライン作成

次の段階として、search-engine-optimization エージェントにアウトライン作成を依頼する。

**アウトライン作成時の重点項目:**

1. **タイトル最適化**
   - 主要キーワード: GitHub Copilot, Ask モード, Plan モード, 使い分け
   - クリックされやすい表現
   - SEO を意識しつつ自然な日本語

2. **meta description**
   - Ask モードの真価（リポジトリ調査）
   - Plan モードの優位性（シームレス）
   - 150-160文字で要約

3. **見出し構造**
   - H2/H3 で論理的に分割
   - Ask モードの誤解を解く → Plan モードの優位性 → 実践ワークフロー
   - コードレベルの理解セクション

4. **内部リンク設計**
   - エージェントパネル関連記事へのリンク
   - AI/Copilot タグの記事
   - 関連するプロンプトエンジニアリング記事

5. **差別化要素**
   - Ask モードのリポジトリ調査能力
   - Plan モードのカスタムエージェント実装
   - 調査→計画→実装のワークフロー
   - コードレベルの理解（Zenn記事参考）

### 記事作成フェーズ

アウトライン承認後、以下の専門家エージェントに執筆を依頼:

- **技術的正確性**: github-copilot-otaku（カスタムエージェント専門家）
- **スタイルと構成**: layout-and-content-harmonization
- **校正**: proofreader
- **SEO最適化**: search-engine-optimization
- **最終チェック**: reviewer

### 追加調査が必要な項目

- GitHub Universe 2025 での Plan モード発表の詳細
- VS Code 拡張の最新バージョンでの実装変更
- カスタムエージェント機能の公式ドキュメント
- @workspace メンションの詳細仕様

## 備考

### 参考にすべきZenn記事の構成

両方のZenn記事（openjny氏）は以下の点で優れている:

- コードレベルでの実装解説
- なぜそうなっているかの考察
- 実際のコード例の提示
- 技術的背景の深掘り

これらの要素を、より一般読者向けにわかりやすく再構成することが重要。

### 想定読者

- GitHub Copilot を既に使っているが、モードの違いを正確に理解していない開発者
- Ask モードを「質問ツール」としてしか使っていない人
- Plan モードの存在を知らない、または使い方がわからない人
- より効果的な Copilot 活用法を探している人
- チーム開発で Copilot を導入しようとしている人

### 記事の目標

読者がこの記事を読んだ後:

1. Ask モードをリポジトリ調査ツールとして活用できる
2. Plan モードの役割と使い方を理解できる
3. Ask → Plan → Agent の連携ワークフローを実践できる
4. 各モードの内部実装への理解が深まる
5. チーム開発での活用イメージが持てる

---

**調査完了日**: 2025年12月28日  
**次回アクション**: search-engine-optimization エージェントへアウトライン作成依頼  
**調査担当**: investigative-research エージェント
