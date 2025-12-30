---
date: 2025-12-30T18:28:46+09:00
description: エージェント間連携とAGENTS.mdのベストプラクティスについての調査レポート
draft: false
epoch: 1767086926
image: /favicon.png
iso8601: 2025-12-30T18:28:46+09:00
tags:
  - agents
  - agents-md
  - github-copilot
  - custom-agents
  - a2a-protocol
title: '調査レポート: エージェント間連携とAGENTS.mdのベストプラクティス'
---

# 調査レポート: エージェント間連携とAGENTS.mdのベストプラクティス

## 調査概要

**調査目的**: 「エージェント間連携がうまくいくようになってきた」という記事を作成するため、エージェント間連携、AGENTS.md、プロンプトエンジニアリングのベストプラクティスについて調査・情報収集を行う

**調査実施日**: 2025-12-20

**想定読者**:
- GitHub Copilotを使い始めたばかりでまだなにもわかっていない人
- GitHub Copilotに興味があって色々と試してみたい人
- 目標: AGENTS.mdやカスタムエージェントを定義してAIエージェントを活用できるようになる

---

## 1. GitHub Copilot のカスタムエージェントとAGENTS.md

### 1.1 AGENTS.mdの役割と仕様

#### 概要
AGENTS.mdは、AIエージェント向けの「README」として機能する特別なファイルで、リポジトリのルートディレクトリに配置される。人間向けのREADME.mdが人間にプロジェクトを説明するように、AGENTS.mdはAIエージェントにプロジェクトの構造、規約、制約を説明する。

#### 命名規則の標準化
- **推奨名称**: `AGENTS.md`（複数形）
- **根拠**: 60,000以上のオープンソースリポジトリで採用されており、業界標準となっている
- **配置場所**: リポジトリのルートディレクトリ（README.mdやCONTRIBUTING.mdと並列）
- **モノレポ対応**: サブディレクトリにも配置可能で、スコープごとに異なる指示を提供できる

**信頼性**: 高（GitHub公式ドキュメント、agents.mdドメイン、複数の技術ブログで一貫して推奨）

**参考URL**:
- https://agents.md/
- https://github.blog/ai-and-ml/github-copilot/how-to-write-a-great-agents-md-lessons-from-over-2500-repositories/
- https://docs.github.com/en/copilot/reference/custom-agents-configuration

#### AGENTS.mdの基本構造

```markdown
# AGENTS.md

## Agent
**Name:** [エージェント名]
**Persona:** [エージェントの役割]

## Goals
- [達成すべき目標1]
- [達成すべき目標2]

## Constraints
- [絶対にしてはいけないこと]
- [編集禁止のディレクトリやファイル]

## Context
- Stack: [技術スタック]
- Version: [バージョン情報]

## Setup Commands
- Install: `[インストールコマンド]`
- Test: `[テストコマンド]`
- Build: `[ビルドコマンド]`

## Code Style
- [コーディング規約]
- [命名規則]

## Testing Instructions
- [テストの実行方法]
- [テストカバレッジの要件]

## Workflow
- [Gitワークフロー]
- [コミットメッセージの形式]
```

**重要なポイント**:
1. 具体的なコード例を含める（説明だけでなく実例を示す）
2. 境界を明確にする（編集禁止のファイル、実行禁止の操作）
3. バージョンや依存関係を明記する
4. 簡潔で実行可能な指示にする

**参考URL**:
- https://github.blog/ai-and-ml/github-copilot/how-to-write-a-great-agents-md-lessons-from-over-2500-repositories/
- https://build5nines.com/unlock-github-copilots-full-potential-why-every-repo-needs-an-agents-md-file/

### 1.2 カスタムエージェント定義ファイル（.github/agents/*.agent.md）

#### ファイル構造とYAMLフロントマター

カスタムエージェントは `.github/agents/` ディレクトリに `{role}.agent.md` 形式で配置する。

```yaml
---
name: backend-specialist
description: バックエンド実装専門のエージェント。Node.jsとPostgreSQLを担当。
tools: ["read", "edit", "search"]
model: copilot-pro
handoffs:
  - label: 実装を開始する
    agent: implementation
    prompt: テストを合格させるコードを実装してください
    send: false
---

あなたは10年以上の経験を持つバックエンドエンジニアです。
Node.jsとPostgreSQLに深い愛とこだわりを持っています。

## 担当範囲
- `/src/backend/` 配下のファイルのみ編集
- API設計とデータベーススキーマの実装

## 制約
- `/src/frontend/` は編集しない
- テストコードは別のエージェントに任せる
```

#### 主要なフロントマター項目

| 項目 | 説明 | 例 |
|------|------|-----|
| `name` | エージェントの一意な識別子 | `backend-specialist` |
| `description` | エージェントの役割説明 | `バックエンド実装専門のエージェント` |
| `tools` | 利用可能なツールのリスト | `["read", "edit", "search"]` |
| `model` | 使用するモデル（任意） | `copilot-pro` |
| `handoffs` | 他エージェントへの引き継ぎ設定 | 後述 |

**参考URL**:
- https://docs.github.com/ja/copilot/concepts/agents/coding-agent/about-custom-agents
- https://zenn.dev/studypocket/articles/github-copilot-agents-md-best-practices
- https://it-araiguma.com/github-copilot-custom-agents-md-guide/

### 1.3 エージェント間連携のベストプラクティス

#### 連携を成功させる3つのポイント

##### 1. 名前の一致（Name Consistency）

エージェント間で引き継ぎを行う際、`handoffs` で指定する `agent` 名は、参照先エージェントの `name` フィールドと完全に一致させる必要がある。

**良い例**:
```yaml
# tester.agent.md
---
name: tester
handoffs:
  - label: 実装を開始
    agent: implementation  # ← implementation.agent.md の name と一致
---
```

```yaml
# implementation.agent.md
---
name: implementation  # ← tester から参照される名前
---
```

**悪い例**:
```yaml
# tester.agent.md
handoffs:
  - agent: impl  # ← 短縮名を使うと参照できない
```

##### 2. エージェント定義の場所の明示（Location Definition）

エージェントファイルの配置場所を統一し、命名規則を守る。

- **推奨配置**: `.github/agents/{role}.agent.md`
- **命名規則**: `{役割名}.agent.md`（例: `perl-monger.agent.md`, `sql-otaku.agent.md`）

##### 3. ワークフローとしての定義（Workflow Definition）

エージェント間の連携をワークフローとして明確に定義する。

**例: 記事作成ワークフロー**
```
1. investigative-research（調査）
   ↓ handoff
2. search-engine-optimization（アウトライン作成）
   ↓ handoff
3. 各専門家エージェント（記事作成）
   ↓ handoff
4. layout-and-content-harmonization（整形）
   ↓ handoff
5. proofreader（校正）
   ↓ handoff
6. reviewer（最終確認）
```

このワークフローをAGENTS.mdまたは各エージェントの定義に明記する。

**参考URL**:
- https://zenn.dev/studypocket/articles/github-copilot-agents-md-best-practices
- https://blog.serverworks.co.jp/getting-started-custom-agents-github-copilot-agent-mode
- https://blog.wadan.co.jp/ja/tech/github-copilot-agent-mode

---

## 2. プロンプトエンジニアリング基礎

### 2.1 役割付与の効果（Role Prompting）

#### 概要
AIに明確な役割や専門性を付与することで、一貫性のある回答を引き出す手法。

#### 効果
1. **視点の一貫性**: 特定の専門家としての視点で回答
2. **語彙の最適化**: その分野に適した専門用語を使用
3. **深い洞察**: 表面的な回答ではなく、本質的な理解に基づく説明

#### 実践例

**基本形**:
```
あなたは10年以上の経験を持つ[専門分野]の専門家です。
[専門分野]に深い愛とこだわりを持っています。
```

**具体例（perl-mongerより）**:
```
You are "perl-monger", a Perl-obsessed specialist. 
Be enthusiastic and geeky but helpful.
```

**効果の実例**: 
- Rubyについて質問すると、「Perl好きから見て一言」という独自の視点が出現
- 単なる技術比較ではなく、「魔術性」「アプローチの違い」といった本質的な特徴を指摘
- 寛容さも示す（「どちらも愛でる派です :)」）

**参考URL**:
- https://taskhub.jp/useful/prompt-hallucination/
- https://ai-market.jp/howto/chatgpt-hallucination/

### 2.2 ハルシネーション防止

#### プロンプト設計5原則

1. **目的と前提を明示**
   ```
   あなたは中立的な法務アドバイザーです。
   契約書のリスクを解説してください。
   ```

2. **情報範囲の制限**
   ```
   以下の資料のみを根拠に回答してください。
   資料に書かれていない推測は含めないでください。
   ```

3. **出典・根拠を明示させる**
   ```
   必ず公式ソースのURLを併記してください。
   引用する場合は出典を明記してください。
   ```

4. **思考プロセスを可視化**
   ```
   回答の根拠や考え方を段階的に説明してください。
   ```

5. **不明点は"わからない"と答えるよう指示**
   ```
   根拠がない場合は「わからない」と答えてください。
   推測で回答しないでください。
   ```

#### 実践テンプレート

```markdown
あなたは[役割]です。

【優先順位】
1. 正確性
2. 明快さ
3. 簡潔さ

【行動指針】
1. 根拠が不明な情報は推測しない
2. 不明点は必ず質問して明確化
3. 出典はMarkdown形式で明記
4. わからない場合は「わからない」と答える

【出力形式】
- Markdown形式で出力
- 箇条書きで整理
- コード例には言語タグを付与
```

**参考URL**:
- https://ai-keiei.shift-ai.co.jp/hallucination-prompt-measures/
- https://taskhub.jp/useful/prompt-hallucination/
- https://ai-market.jp/howto/chatgpt-hallucination/
- https://engineering.dena.com/blog/2025/12/llm-study-1201/

### 2.3 重要な部分の強調方法

#### 優先順位の明示

```markdown
【優先順位】
1. 正確性
2. 簡潔性
3. 応答速度
```

#### 出力フォーマット指定

```markdown
【出力形式】
- Markdown形式
- コードブロックは言語タグ付き
- 見出しはH2/H3のみ使用
```

#### 良例・悪例の併記

```markdown
### 良い例
\`\`\`typescript
interface User {
  id: string;
  name: string;
}
\`\`\`

### 悪い例
\`\`\`typescript
function getUser(id: any): any {
  // 型安全性が失われる
}
\`\`\`
```

**参考URL**:
- https://m-totsu.com/722/
- https://ai-market.jp/howto/chatgpt-hallucination/

---

## 3. ドメイン特化型AIの重要性

### 3.1 専門性を高めるメリット

研究で示されている効果:

1. **ドメイン内性能の向上**: 特定領域に特化することで、より正確で詳細な回答
2. **ハルシネーションとリスク低減**: 専門知識に絞ることで、誤情報生成の確率が低下
3. **専門知識・語彙のキャプチャ**: ドメイン固有の用語や概念を適切に理解
4. **少量データでの有効性**: 微調整手法により、少ないデータでも高性能
5. **コストと効率のトレードオフ**: 必要な機能に絞ることで効率的に動作

**参考URL**:
- https://www.getguru.com/reference/domain-specific-ai
- https://arxiv.org/html/2305.18703v7
- https://www.researchgate.net/publication/391326622_The_Future_of_AI_How_Domain-Specific_LLMs_RAG_Agentic_AI_Are_Redefining_Intelligence

### 3.2 定義の粒度 - Less is More

#### シンプルな定義の強み

**問題**: 細かく定義しすぎると、定義しなかったことが抜けてしまう

**例**:
```yaml
# 悪い例（定義しすぎ）
---
name: perl-expert
---
推奨フレームワーク: Catalyst, Mojolicious, Dancer
推奨モジュール: Plack, DBIx::Class, Moo
推奨スタイル: PBP（Perl Best Practices）
テストツール: Test::More, Test::Deep
```

この場合、定義にないフレームワークやモジュールについて聞かれると対応が硬直化する。

**良い例（シンプル）**:
```yaml
---
name: perl-monger
description: Perl愛好家。熱狂的でオタク的だが役に立つ
---

イディオマティックなPerlを優先
必要に応じてバージョンやCPANモジュールに言及
```

AIの基礎知識と推論能力が、シンプルな性格設定から適切な回答を導く。

**教訓**: **定義しすぎない感じが良い**

**参考URL**:
- 実リポジトリの実例: https://github.com/nqou-net/www.nqou.net/blob/bca018e2c7b14cbafd21b4a4489525568a0e74c4/.github/agents/perl-monger.agent.md

---

## 4. 内部リンク（関連記事）

### タグ検索結果

リポジトリ内の関連記事で使用されているタグ:

**GitHub Copilot関連**:
- `github-copilot`
- `copilot`
- `custom-agents`
- `custom-agent`

**AI関連**:
- `ai`
- `ai-development`
- `domain-specific-ai`

**エージェント関連**:
- `agents`
- `awesome-copilot`

**プロンプト関連**:
- `prompt`
- `prompt-engineering`（提案）

### 既存の関連記事

1. **エージェントガイドラインを作成するプロンプトを試してみた**
   - パス: `/content/post/2025/11/27/233234.md`
   - タグ: `ai`, `copilot`, `prompt`
   - 内容: GitHub Blogのプロンプトを使ったAGENTS.md作成体験

2. **エージェントパネルから記事を生成してみた**
   - パス: `/content/post/2025/11/29/010643.md`
   - タグ: `ai`, `copilot`, `prompt`
   - 内容: エージェントパネルからの記事生成体験、AGENTS.mdの自動改善

3. **GitHub Copilot の awesome-copilot で開発体験を向上させる**
   - パス: `/content/post/2025/12/06/212332.md`
   - タグ: `github-copilot`, `awesome-copilot`, `custom-agents`, `ai-development`, `domain-specific-ai`
   - 内容: awesome-copilotリポジトリの紹介、ドメイン特化型AIの重要性

4. **perl-mongerをカスタムエージェントとして定義した**
   - パス: `/content/post/2025/12/07/012345.md`
   - タグ: `perl`, `custom-agent`, `github-copilot`, `ai`, `perl-monger`
   - 内容: ドメイン特化型エージェントの実例、定義の粒度、A2Aプロトコル

---

## 5. 追加の重要情報

### 5.1 A2Aプロトコル（Agent to Agent）

エージェント間通信の標準化プロトコル。

**目的**: 異なるベンダーや実装のAIエージェント同士が標準化された方法で連携

**中核要素**:
1. Agent Card（能力公開）
2. Task（作業単位）
3. Message/Parts（多モーダルなやり取り）
4. Artifact（成果物）

**通信**: JSON-RPC 2.0 over HTTP(S)、SSEストリーミング対応

**利点**:
- カスタム連携の減少
- 相互運用性の向上
- マイクロサービス的に専門エージェントを組み合わせやすい

**参考URL**:
- https://a2a-protocol.org/latest/

### 5.2 AGENTS.md vs その他の設定ファイル

**AGENTS.mdの位置づけ**:
- ベンダー中立的なフォーマット
- `.cursor`, `CLAUDE.md`, `gemini.md` などツール固有の設定を統合

**使い分け**:
- `README.md`: 人間向けのプロジェクト説明
- `AGENTS.md`: AIエージェント向けの指示・制約
- `copilot-instructions.md`: GitHub Copilot固有の設定
- `.github/agents/*.agent.md`: カスタムエージェント定義

**参考URL**:
- https://agents.md/
- https://devcenter.upsun.com/posts/why-your-readme-matters-more-than-ai-configuration-files/

---

## 6. ベストプラクティスまとめ

### AGENTS.md作成のベストプラクティス

1. ✅ **ルートディレクトリに配置** - リポジトリルートに `AGENTS.md`
2. ✅ **具体的なコード例を含める** - 説明だけでなく実例を示す
3. ✅ **境界を明確にする** - 編集禁止のファイル、実行禁止の操作
4. ✅ **バージョン情報を明記** - 技術スタック、依存関係のバージョン
5. ✅ **簡潔で実行可能な指示** - 曖昧な表現を避け、具体的なコマンドを記載
6. ✅ **定期的な更新** - プロジェクトの進化に合わせて更新

### カスタムエージェント定義のベストプラクティス

1. ✅ **役割を特化させる** - 汎用的ではなく、明確で狭い目的
2. ✅ **シンプルな定義** - 細かく定義しすぎない（Less is More）
3. ✅ **名前の一致** - handoffs での agent 名と参照先の name を一致
4. ✅ **配置場所の統一** - `.github/agents/{role}.agent.md`
5. ✅ **ツールの最小化** - 必要なツールのみを許可
6. ✅ **ワークフローの明示** - エージェント間の連携フローを定義

### プロンプトエンジニアリングのベストプラクティス

1. ✅ **役割を付与** - 専門家としての視点を与える
2. ✅ **優先順位を明示** - 正確性、簡潔性などの優先順位
3. ✅ **出典要求** - 必ず公式ソースを併記させる
4. ✅ **不明点の扱い** - わからない場合は推測せず「わからない」と答えさせる
5. ✅ **出力形式指定** - Markdown、コードブロックなど形式を明確に
6. ✅ **良例・悪例の提示** - 期待する出力の具体例を示す

---

## 7. 記事執筆時の推奨事項

### 技術的な正確性を担保するための情報源

**公式ドキュメント**:
1. GitHub Copilot カスタムエージェント公式ドキュメント
   - https://docs.github.com/en/copilot/how-tos/use-copilot-agents/coding-agent/create-custom-agents
   - https://docs.github.com/ja/copilot/concepts/agents/coding-agent/about-custom-agents

2. AGENTS.md 公式サイト
   - https://agents.md/

3. GitHub Blog
   - https://github.blog/ai-and-ml/github-copilot/how-to-write-a-great-agents-md-lessons-from-over-2500-repositories/

**研究論文**:
1. ドメイン特化型AI
   - https://arxiv.org/html/2305.18703v7
   - https://www.researchgate.net/publication/391326622_The_Future_of_AI_How_Domain-Specific_LLMs_RAG_Agentic_AI_Are_Redefining_Intelligence

**技術ブログ（信頼性：中～高）**:
1. Zenn記事
   - https://zenn.dev/studypocket/articles/github-copilot-agents-md-best-practices

2. 企業技術ブログ
   - https://blog.serverworks.co.jp/getting-started-custom-agents-github-copilot-agent-mode
   - https://it-araiguma.com/github-copilot-custom-agents-md-guide/

3. DeNA技術ブログ
   - https://engineering.dena.com/blog/2025/12/llm-study-1201/

**プロトコル仕様**:
1. A2Aプロトコル
   - https://a2a-protocol.org/latest/

### 記事の構成提案

1. **導入**
   - エージェント間連携がうまくいくようになってきた経緯
   - 読者への約束（この記事を読むと何ができるようになるか）

2. **基礎知識**
   - AGENTS.mdとは何か
   - カスタムエージェントとは何か
   - なぜドメイン特化型が効果的か

3. **実践編：3つのポイント**
   - 名前の一致
   - 定義の場所の明示
   - ワークフローとしての定義

4. **プロンプトエンジニアリングの基礎**
   - 役割付与
   - ハルシネーション防止
   - 強調方法

5. **実例紹介**
   - このリポジトリでの実装例
   - perl-monger の事例
   - ワークフローの実例

6. **まとめ**
   - ベストプラクティスの再確認
   - 次のステップの提案

### 内部リンクの配置推奨箇所

- **導入部**: 「エージェントガイドラインを作成するプロンプトを試してみた」へのリンク
- **ドメイン特化型の説明**: 「GitHub Copilot の awesome-copilot で開発体験を向上させる」へのリンク
- **実例紹介**: 「perl-mongerをカスタムエージェントとして定義した」へのリンク
- **エージェントパネルの説明**: 「エージェントパネルから記事を生成してみた」へのリンク

---

## 8. 調査結論

### 主要な発見

1. **AGENTS.mdは業界標準**: 60,000以上のリポジトリで採用され、ベンダー中立的なフォーマットとして確立

2. **エージェント間連携の成功は3つのポイント**: 
   - 名前の一致
   - 定義の場所の明示
   - ワークフローとしての定義

3. **ドメイン特化型AIの有効性**: 研究で裏付けられた、専門性を高めることの効果

4. **Less is More**: 細かく定義しすぎるより、シンプルな役割付与の方が効果的

5. **プロンプトエンジニアリングの5原則**: ハルシネーション防止のための明確な設計原則

### 次のステップ

記事作成時には以下を含めることを推奨:

1. ✅ 実際のコード例（YAML、Markdown）
2. ✅ ワークフロー図（テキストまたはmermaid）
3. ✅ 良い例・悪い例の対比
4. ✅ 内部リンクによる関連記事への誘導
5. ✅ 公式ドキュメントへの参照
6. ✅ 初心者にも分かりやすい説明

---

## 9. 参考資料一覧

### 公式ドキュメント
- [Creating custom agents - GitHub Docs](https://docs.github.com/en/copilot/how-tos/use-copilot-agents/coding-agent/create-custom-agents)
- [Custom agents configuration - GitHub Docs](https://docs.github.com/en/copilot/reference/custom-agents-configuration)
- [カスタム エージェントについて - GitHub ドキュメント](https://docs.github.com/ja/copilot/concepts/agents/coding-agent/about-custom-agents)
- [AGENTS.md Official Site](https://agents.md/)

### GitHub Blog
- [How to write a great agents.md: Lessons from over 2,500 repositories](https://github.blog/ai-and-ml/github-copilot/how-to-write-a-great-agents-md-lessons-from-over-2500-repositories/)
- [5 tips for writing better custom instructions for Copilot](https://github.blog/ai-and-ml/github-copilot/5-tips-for-writing-better-custom-instructions-for-copilot/)
- [Copilot coding agent now supports AGENTS.md custom instructions](https://github.blog/changelog/2025-08-28-copilot-coding-agent-now-supports-agents-md-custom-instructions/)

### 技術記事（日本語）
- [GitHub Copilot カスタムエージェントのための agents.md 作成ベストプラクティス - Zenn](https://zenn.dev/studypocket/articles/github-copilot-agents-md-best-practices)
- [GitHub Copilot カスタムエージェント実践ガイド - IT-ARAIGUMA](https://it-araiguma.com/github-copilot-custom-agents-md-guide/)
- [はじめてのカスタムエージェント【GitHub Copilot Agent Mode編】- ServerWorks](https://blog.serverworks.co.jp/getting-started-custom-agents-github-copilot-agent-mode)
- [プロンプトでハルシネーションは対策できる！- Taskhub](https://taskhub.jp/useful/prompt-hallucination/)
- [ChatGPTでハルシネーションを抑制する対策 - AI Market](https://ai-market.jp/howto/chatgpt-hallucination/)
- [LLM Study #1201 - DeNA Engineering](https://engineering.dena.com/blog/2025/12/llm-study-1201/)

### 技術記事（英語）
- [Build Your Own GitHub Copilot Agent: From Zero to Hero](https://dxrf.com/blog/2025/11/20/build-your-own-github-copilot-agent/)
- [Build a Custom Copilot @test-agent with agents.md Guide](https://aize.dev/546/how-to-build-a-custom-copilot-test-agent-with-agents-md/)
- [Unlock GitHub Copilot's Full Potential - Build5Nines](https://build5nines.com/unlock-github-copilots-full-potential-why-every-repo-needs-an-agents-md-file/)
- [What is AGENTS.md and Why Should You Care? - DEV Community](https://dev.to/proflead/what-is-agentsmd-and-why-should-you-care-3bg4)
- [AGENTS.md: Why your README matters more](https://devcenter.upsun.com/posts/why-your-readme-matters-more-than-ai-configuration-files/)

### 研究・仕様
- [A2A Protocol Official Site](https://a2a-protocol.org/latest/)
- [Domain-Specific AI - Guru](https://www.getguru.com/reference/domain-specific-ai)
- [Domain-Specific LLMs Research - arXiv](https://arxiv.org/html/2305.18703v7)
- [The Future of AI: Domain-Specific LLMs - ResearchGate](https://www.researchgate.net/publication/391326622_The_Future_of_AI_How_Domain-Specific_LLMs_RAG_Agentic_AI_Are_Redefining_Intelligence)

### リポジトリ内関連記事
- [エージェントガイドラインを作成するプロンプトを試してみた](/2025/11/27/233234/)
- [エージェントパネルから記事を生成してみた](/2025/11/29/010643/)
- [GitHub Copilot の awesome-copilot で開発体験を向上させる](/2025/12/06/212332/)
- [perl-mongerをカスタムエージェントとして定義した](/2025/12/07/012345/)

---

**調査完了日**: 2025-12-20
**調査者**: investigative-research エージェント
**保存場所**: `content/warehouse/agent-coordination-best-practices.md`
