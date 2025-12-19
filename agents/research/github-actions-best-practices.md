# GitHub Actions ベストプラクティス - 調査レポート

## 調査目的
技術ブログ記事「GitHub Actions のベストプラクティス」を執筆するための包括的な情報収集

## 対象読者
- 初心者〜中級者
- GitHub Actions を使い始めた、またはこれから導入を検討している開発者

## 想定文字数
3000〜5000文字

---

## 1. GitHub Actions の基本概念と最新情報

### 1.1 公式ドキュメント

#### GitHub Actions 公式ドキュメント
- **URL**: https://docs.github.com/en/actions
- **信頼性**: 公式（最高）
- **要点**:
  - CI/CDワークフローの自動化方法
  - YAML構文によるワークフロー定義
  - GITHUB_TOKENなどのセキュリティ機能
  - 実行メトリクスの監視とトラブルシューティング
  - ワークフローディスパッチの改善など新機能
- **引用すべき重要情報**:
  - ワークフローの基本構造とトリガーイベント
  - セキュリティ設定の推奨事項
  - パフォーマンス最適化のテクニック

### 1.2 最新のプラットフォームアップデート

#### GitHub Blog: Let's talk about GitHub Actions
- **URL**: https://github.blog/news-insights/product-news/lets-talk-about-github-actions/
- **信頼性**: 公式
- **要点**:
  - 2024-2025年に大規模なアーキテクチャアップグレード実施
  - 新しいバックエンドで1日のジョブ実行量が3倍に増加
  - 企業ユーザーは1分あたりに開始できるジョブ数が大幅に向上
  - スピード、信頼性、柔軟性が向上
  - キャッシング、診断機能のさらなる改善を予定
- **引用すべき重要情報**:
  - パフォーマンス向上の具体的な数値
  - 今後のロードマップ

#### Upcoming breaking changes and releases
- **URL**: https://github.blog/changelog/2025-04-15-upcoming-breaking-changes-and-releases-for-github-actions/
- **信頼性**: 公式
- **要点**:
  - Copilot生成イベントには明示的な管理者承認が必要に
  - Windows Server 2019ホスト済みイメージは非推奨
  - 新しいランナーイメージへの更新が必要
  - パフォーマンスとコストを最適化するための新しい制御とメトリクス
- **引用すべき重要情報**:
  - 破壊的変更への対応方法
  - 最新のベストプラクティスへの移行手順

---

## 2. 主要なベストプラクティス

### 2.1 セキュリティのベストプラクティス

#### GitHub Actions Security Best Practices Cheat Sheet - GitGuardian
- **URL**: https://blog.gitguardian.com/github-actions-security-cheat-sheet/
- **信頼性**: コミュニティ（高評価）
- **要点**:
  - 最小権限の原則を適用（デフォルトトークン権限は読み取り専用にすべき）
  - 特定のアクションバージョンをピン留め
  - 信頼できない入力の参照を避ける
  - 静的シークレットの代わりにOpenID Connect (OIDC)を使用
  - ワークフローを積極的に監視
  - セルフホストランナーの使用を制限
- **引用すべき重要情報**:
  - OIDC認証の実装方法
  - トークン権限の適切な設定例
  - サプライチェーン攻撃からの防御策

#### 7 GitHub Actions Security Best Practices (With Checklist) - StepSecurity
- **URL**: https://www.stepsecurity.io/blog/github-actions-security-best-practices
- **信頼性**: コミュニティ（セキュリティ専門企業）
- **要点**:
  - PRの自動承認を制限
  - リポジトリの作成や可視性変更を制限
  - 組織内でのポリシー強化
  - アクションのバージョンをコミットSHAで固定
  - サードパーティアクションの審査
- **引用すべき重要情報**:
  - セキュリティチェックリスト
  - 実践的な設定例

#### Secure use reference - GitHub Docs
- **URL**: https://docs.github.com/en/actions/reference/security/secure-use
- **信頼性**: 公式
- **要点**:
  - シークレットをコードやプレーンテキストにコミットしない
  - `${{ secrets.SECRET_NAME }}`形式でシークレットを参照
  - `::add-mask::VALUE`でログにマスキング追加
  - JSON、YAML、XMLなどの構造化データをシークレットとして保存しない
  - 変換されたシークレットも再登録する
- **引用すべき重要情報**:
  - シークレット管理の詳細なガイドライン
  - ログ出力におけるセキュリティ対策

### 2.2 シークレット管理のベストプラクティス

#### Best Practices for Managing Secrets in GitHub Actions - Blacksmith
- **URL**: https://www.blacksmith.sh/blog/best-practices-for-managing-secrets-in-github-actions
- **信頼性**: コミュニティ（専門ツールベンダー）
- **要点**:
  - 30-90日ごとにシークレットをローテーション
  - 組織/環境シークレットでロールベースアクセス制御
  - 定期的に権限を監査
  - 監査ログ機能を活用
  - 環境ベースのシークレットと承認ワークフローを使用
- **引用すべき重要情報**:
  - シークレットローテーションの自動化手法
  - 環境別のシークレット管理戦略

#### OIDC認証（AWS、Azure、GCP）

##### Configuring OpenID Connect in cloud providers - GitHub Docs
- **URL**: https://docs.github.com/en/actions/how-tos/secure-your-work/security-harden-deployments/oidc-in-cloud-providers
- **信頼性**: 公式
- **要点**:
  - GitHubとクラウドプロバイダー間でOIDC信頼を設定
  - ワークフロー実行時にOIDCトークンをリクエスト
  - 短期間の一時的な認証情報を取得
  - 静的な認証情報やシークレットの保存が不要
- **引用すべき重要情報**:
  - OIDC設定の手順
  - セキュリティ上の利点

##### AWS OIDC統合
- **URL**: https://aws.amazon.com/blogs/security/use-iam-roles-to-connect-github-actions-to-actions-in-aws/
- **信頼性**: 公式（AWS）
- **要点**:
  1. AWSでOIDC IDプロバイダーを作成（`https://token.actions.githubusercontent.com`を指定）
  2. リポジトリ/ブランチに限定した信頼関係でIAMロールを作成
  3. `aws-actions/configure-aws-credentials`アクションを使用
  4. `id-token: write`権限を設定
- **引用すべき重要情報**:
  - 実装手順の詳細
  - セキュリティ設定のベストプラクティス

##### Azure OIDC統合
- **URL**: https://learn.microsoft.com/en-us/azure/developer/github/connect-from-azure-openid-connect
- **信頼性**: 公式（Microsoft）
- **要点**:
  - Microsoft Entraでフェデレーション ID 認証情報を設定
  - 必要なロールと権限を割り当て
  - クライアントID、サブスクリプションID、テナントIDをGitHubシークレットに保存
  - `azure/login`アクションを使用
- **引用すべき重要情報**:
  - パスワードレスログインの実装
  - Azure RBACとの統合方法

### 2.3 パフォーマンス最適化

#### GitHub Actions Cache - A Complete Guide with Examples - CICube
- **URL**: https://cicube.io/blog/github-actions-cache/
- **信頼性**: コミュニティ
- **要点**:
  - 依存関係のキャッシング（npm、yarn、pip等）
  - パッケージロックファイルに基づくキャッシュキーの設定
  - `if: steps.cache.outputs.cache-hit != 'true'`で条件付きインストール
  - マトリックスベースのキャッシング
  - ジョブ間のキャッシュ共有
- **引用すべき重要情報**:
  - キャッシュキーの設計パターン
  - キャッシュヒット率を高める手法

#### Supercharge Your GitHub Actions with Smart Caching
- **URL**: https://nowham.dev/posts/github_actions_caching_strategies/
- **信頼性**: コミュニティ
- **要点**:
  - 効果的なキャッシングでビルド時間を40-80%削減可能
  - キャッシュヒット率85%達成でビルド時間を14分から4分に短縮
  - 月額コストを$50から$15に削減した実例
  - `restore-keys`を使用した部分的なキャッシュヒット
- **引用すべき重要情報**:
  - 実際の改善事例と具体的な数値
  - コスト削減の実績

#### Optimizing GitHub Actions Workflows for Speed and Efficiency
- **URL**: https://marcusfelling.com/blog/2025/optimizing-github-actions-workflows-for-speed
- **信頼性**: コミュニティ
- **要点**:
  - Dockerレイヤーキャッシング（`cache-from`と`cache-to`）
  - Buildxキャッシュディレクトリの保存
  - ジョブの並列化
  - パスフィルタリングで不要なビルドを回避
  - セルフホストランナーの活用
- **引用すべき重要情報**:
  - Dockerビルドの最適化手法
  - パフォーマンス監視とプロファイリング

#### Matrix Strategy最適化
- **URL**: https://devopsdirective.com/posts/2025/08/advanced-github-actions-matrix/
- **信頼性**: コミュニティ
- **要点**:
  - マトリックス戦略で複数環境での並列実行
  - `include`でカスタム組み合わせを追加
  - `exclude`で特定の組み合わせをスキップ
  - 動的マトリックスの生成（変更されたファイルに基づく）
  - `fail-fast: false`で全ジョブを実行
- **引用すべき重要情報**:
  - マトリックスのカスタマイズ例
  - 並列実行の最適化パターン

### 2.4 再利用可能なワークフロー

#### Best practices to create reusable workflows on GitHub Actions
- **URL**: https://www.incredibuild.com/blog/best-practices-to-create-reusable-workflows-on-github-actions
- **信頼性**: コミュニティ
- **要点**:
  - DRY原則の適用（重複を避ける）
  - タグやセマンティックバージョンでバージョン管理（`main`ではなく）
  - `workflow_call`トリガーで入力とシークレットを定義
  - 中央リポジトリに再利用可能なワークフローを保存
  - マトリックスジョブ、キャッシング、条件付きジョブのサポート
- **引用すべき重要情報**:
  - 再利用可能なワークフローの設計パターン
  - 組織全体での標準化手法

#### GitHub Actions Composite vs Reusable Workflows - DEV Community
- **URL**: https://dev.to/hkhelil/github-actions-composite-vs-reusable-workflows-4bih
- **信頼性**: コミュニティ
- **要点**:
  - **Composite Actions**: ステップレベルの粒度、`.github/actions`に保存
  - **Reusable Workflows**: ワークフローレベルの粒度、高レベルオーケストレーション
  - Composite Actionsで複雑なロジックをカプセル化
  - Reusable Workflowsで標準CI/CDプロセスを定義
  - 両者を組み合わせて使用可能
- **引用すべき重要情報**:
  - 使い分けのガイドライン
  - 実装パターンの比較

### 2.5 セルフホストランナーのセキュリティ

#### GitHub - dduzgun-security/github-self-hosted-runners
- **URL**: https://github.com/dduzgun-security/github-self-hosted-runners
- **信頼性**: コミュニティ（セキュリティ専門家）
- **要点**:
  - パブリックリポジトリでは使用しない
  - ランナーグループで制限を設定
  - フォークからのPRビルドを無効化
  - OSを最新に保ち、セキュリティパッチを適用
  - 分離環境またはコンテナで実行
  - エフェメラル（一時的）ランナーを優先
  - ランナーにシークレットを保存しない
- **引用すべき重要情報**:
  - セキュリティチェックリスト
  - セルフホストランナー運用のベストプラクティス

#### Best practices working with self-hosted GitHub Action runners at scale on AWS
- **URL**: https://aws.amazon.com/blogs/devops/best-practices-working-with-self-hosted-github-action-runners-at-scale-on-aws/
- **信頼性**: 公式（AWS）
- **要点**:
  - エフェメラルランナーの使用
  - 短期間の認証情報を使用（OIDC、AWS STS）
  - ネットワークアクセスを制限
  - 自動更新の設定
  - 監査とアクセス追跡
- **引用すべき重要情報**:
  - AWS環境での実装ガイド
  - スケーラビリティと可用性の考慮事項

### 2.6 ワークフロー構文とよくある間違い

#### Common Mistakes in GitHub Actions and How to Avoid Them - MoldStud
- **URL**: https://moldstud.com/articles/p-avoid-these-common-pitfalls-in-github-actions-key-tips-for-success
- **信頼性**: コミュニティ
- **要点**:
  - YAML構文エラー（インデント、タブ使用）- 19%のパイプラインエラーの原因
  - アクションバージョンの固定不足 - 34%のCI/CDインシデントの原因
  - 過剰な権限設定
  - 広すぎるイベントトリガー
  - 不要なcheckoutステップの重複
  - ケースセンシティブな環境変数名
  - プレーンテキストでのシークレット保存
- **引用すべき重要情報**:
  - 統計データに基づく問題の重要度
  - 具体的な回避策

#### GitHub Actions Workflow Syntax Cheat Sheet 2025
- **URL**: https://generalistprogrammer.com/cheatsheets/github-actions
- **信頼性**: コミュニティ
- **要点**:
  - ブランチやパスでトリガーを絞り込む
  - イベントアクティビティタイプを明示的に指定
  - 依存ファイルに紐づいた一意のキャッシュキーを使用
  - マトリックスビルドでツールバージョンを固定
  - `needs`キーワードで適切にジョブを順序付け
  - `timeout-minutes`で合理的なタイムアウトを設定
- **引用すべき重要情報**:
  - 構文チートシート
  - ベストプラクティスの簡潔なまとめ

---

## 3. 日本語リソース

### 3.1 総合的なベストプラクティス

#### なんとなくから脱却する GitHub Actionsグッドプラクティス11選 - Gihyo.jp
- **URL**: https://gihyo.jp/article/2024/10/good-practices-for-github-actions
- **信頼性**: 信頼できる日本の技術メディア
- **要点**:
  - フェイルファースト（短いタイムアウト設定）
  - 不要なワークフロー実行の最小化（フィルタリング、concurrency）
  - 必要最小限の権限付与（permissions）
  - Secretsの適切な管理
  - サードパーティアクションのバージョン固定（コミットハッシュ推奨）
  - Reusable Workflowの活用
  - actionlint/ShellCheckによる事前チェック
- **引用すべき重要情報**:
  - 日本語での詳細な解説
  - 実践的な11の推奨事項

#### GitHub Actionsを徹底活用！CI/CDを加速させるセキュリティ・効率化・コスト削減のベストプラクティス
- **URL**: https://omomuki-tech.com/archives/406
- **信頼性**: コミュニティブログ
- **要点**:
  - Concurrencyによる自動キャンセル
  - 公式Action優先とバージョン管理
  - 依存パッケージのキャッシング
  - ジョブログとジョブサマリーの活用（`::group::`、`GITHUB_STEP_SUMMARY`）
  - linter/formatterの自動実行
  - コスト削減とパフォーマンス向上の具体例
- **引用すべき重要情報**:
  - 日本語での実装例
  - CI/CD高速化の実践テクニック

#### GitHub Actions完全ガイド：エンジニアが知るべき実践的活用法とセキュリティ対策
- **URL**: https://note.com/kamibukuro18/n/neae2dbe78bf4
- **信頼性**: コミュニティブログ
- **要点**:
  - 2025年春のサプライチェーン攻撃事例（tj-actions/changed-files他）
  - サードパーティアクション利用時のバージョン管理必須
  - Secretsのスコープ管理と定期レビュー
  - GITHUB_TOKENの権限明示化
  - セキュリティインシデントへの対応
- **引用すべき重要情報**:
  - 実際のセキュリティ事例
  - 日本語でのセキュリティ対策解説

#### GitHub Actions 入門 - Zenn
- **URL**: https://zenn.dev/farstep/books/learn-github-actions
- **信頼性**: コミュニティ（Zenn技術書）
- **要点**:
  - GitHub Actionsの基礎から応用まで
  - 標準化されたCI/CDプロセスの構築
  - パラメータとバージョニング
  - モジュラー設計
  - ワークフローロジックのドキュメント化
- **引用すべき重要情報**:
  - 初心者向けの体系的な学習リソース
  - 日本語での包括的なガイド

#### GitHub Actionsワークフローを今よりちょっと最適化してみる - Qiita
- **URL**: https://qiita.com/yoda_naan/items/06345b395b515a275f36
- **信頼性**: コミュニティ（Qiita）
- **要点**:
  - 実践ガイドに基づく最適化Tips
  - エラー制御とデバッグ
  - タイムアウト設定
  - 条件分岐の活用
  - ロギングによるデバッグ支援
- **引用すべき重要情報**:
  - 実践的な改善手法
  - トラブルシューティングのコツ

---

## 4. 実践的なワークフロー例

### 4.1 CI/CD実装例

#### How to Automate CI/CD with GitHub Actions - FreeCodeCamp
- **URL**: https://www.freecodecamp.org/news/automate-cicd-with-github-actions-streamline-workflow/
- **信頼性**: コミュニティ（教育プラットフォーム）
- **要点**:
  - Node.jsアプリケーションのビルドとデプロイ
  - テスト自動化
  - 複数環境への対応
  - ステップバイステップガイド
- **引用すべき重要情報**:
  - 初心者向けの実装例
  - 基本的なCI/CDパイプラインの構築方法

#### GitHub Actions Real-World Use Cases and Examples
- **URL**: https://devtoolhub.com/github-actions-use-cases-examples/
- **信頼性**: コミュニティ
- **要点**:
  - Dockerイメージのビルドと公開
  - ドキュメント自動化
  - クラウドプロバイダーへのデプロイ（AWS、Azure、Kubernetes）
  - セキュリティスキャンとコード品質チェック
  - プロジェクトガバナンスと自動化
- **引用すべき重要情報**:
  - YAMLスニペットと実用例
  - 多様なユースケース

#### Alliedium/awesome-github-actions
- **URL**: https://github.com/Alliedium/awesome-github-actions
- **信頼性**: コミュニティ（キュレーションリポジトリ）
- **要点**:
  - CI/CD、シークレット管理、ジョブ順序付けの多様なワークフロー例
  - マトリックスビルド
  - 高度な式の使用
  - monorepo管理
- **引用すべき重要情報**:
  - 包括的なワークフロー例のコレクション
  - 実装パターンのリファレンス

---

## 5. エンタープライズとガバナンス

### 5.1 組織レベルのベストプラクティス

#### GitHub Enterprise Policies & Best Practices
- **URL**: https://wellarchitected.github.com/library/governance/recommendations/governance-policies-best-practices/
- **信頼性**: 公式（GitHub）
- **要点**:
  - 信頼できるリポジトリへのアクション実行を制限
  - アクセストークンと外部コラボレーターの承認を強制
  - 不正なリポジトリ変更やパブリックリポジトリ作成を防止
  - コンプライアンスとサプライチェーンリスク軽減のための中央集約的なワークフロー構成管理
  - 検証済みアクションの使用を強制
- **引用すべき重要情報**:
  - エンタープライズポリシーの設定方法
  - ガバナンス強化のベストプラクティス

---

## 6. 競合記事分析

### 6.1 日本語記事の傾向
- Gihyo.jp、Qiita、Zenn、noteなどの技術メディアで多数の記事が公開されている
- 基礎的な使い方から、セキュリティ、パフォーマンス最適化まで幅広くカバー
- 2024-2025年にかけてセキュリティ関連の記事が増加（サプライチェーン攻撃への対応）
- 実践的な実装例とトラブルシューティングが人気

### 6.2 英語記事の傾向
- 公式ドキュメント、AWS/Azure/GCPの公式ブログが信頼性の高い情報源
- セキュリティベンダー（GitGuardian、StepSecurity等）の専門的なガイドが充実
- パフォーマンス最適化、OIDC認証、再利用可能なワークフローが主要トピック
- 実際の改善事例と数値データを示す記事が評価されている

### 6.3 差別化ポイント
1. **日本語での包括的なガイド**: 公式ドキュメントの重要ポイントを日本語で分かりやすく解説
2. **実践的な数値データ**: パフォーマンス改善の具体的な数値（ビルド時間短縮率、コスト削減額等）
3. **セキュリティ重視**: 最新のセキュリティ脅威とその対策を強調
4. **初心者から中級者向けの段階的な解説**: 基本から応用まで無理なく理解できる構成
5. **2025年の最新情報**: プラットフォームアップデートと破壊的変更への対応

---

## 7. 記事執筆時に参照すべき重要リソース

### 7.1 必須リソース（公式）
1. **GitHub Actions 公式ドキュメント**
   - https://docs.github.com/en/actions
   - 最も信頼性が高く、最新情報を反映

2. **GitHub Blog - GitHub Actions関連記事**
   - https://github.blog/news-insights/product-news/lets-talk-about-github-actions/
   - プラットフォームアップデートの情報源

3. **Secure use reference**
   - https://docs.github.com/en/actions/reference/security/secure-use
   - セキュリティのベストプラクティス

4. **OIDC in cloud providers**
   - https://docs.github.com/en/actions/how-tos/secure-your-work/security-harden-deployments/oidc-in-cloud-providers
   - クラウド認証の最新手法

### 7.2 推奨リソース（セキュリティ）
1. **GitGuardian Security Cheat Sheet**
   - https://blog.gitguardian.com/github-actions-security-cheat-sheet/
   - セキュリティのクイックリファレンス

2. **StepSecurity Best Practices**
   - https://www.stepsecurity.io/blog/github-actions-security-best-practices
   - チェックリスト形式で実用的

3. **AWS Security Blog - IAM roles for GitHub Actions**
   - https://aws.amazon.com/blogs/security/use-iam-roles-to-connect-github-actions-to-actions-in-aws/
   - OIDC実装の詳細

### 7.3 推奨リソース（パフォーマンス）
1. **CICube - GitHub Actions Cache Guide**
   - https://cicube.io/blog/github-actions-cache/
   - キャッシング戦略の包括的ガイド

2. **Marcus Felling - Optimization Techniques**
   - https://marcusfelling.com/blog/2025/optimizing-github-actions-workflows-for-speed
   - 実践的な最適化手法

3. **DevOps Directive - Advanced Matrix Strategy**
   - https://devopsdirective.com/posts/2025/08/advanced-github-actions-matrix/
   - 並列実行の高度なテクニック

### 7.4 推奨リソース（日本語）
1. **Gihyo.jp - グッドプラクティス11選**
   - https://gihyo.jp/article/2024/10/good-practices-for-github-actions
   - 日本語での包括的な解説

2. **omomuki-tech - CI/CD加速のベストプラクティス**
   - https://omomuki-tech.com/archives/406
   - 実装例とパフォーマンス改善

3. **note - セキュリティ完全ガイド**
   - https://note.com/kamibukuro18/n/neae2dbe78bf4
   - セキュリティインシデント事例

### 7.5 推奨リソース（実装例）
1. **Incredibuild - Reusable Workflows**
   - https://www.incredibuild.com/blog/best-practices-to-create-reusable-workflows-on-github-actions
   - 再利用可能なワークフローの設計

2. **DevToolHub - Real-World Use Cases**
   - https://devtoolhub.com/github-actions-use-cases-examples/
   - 実用的なワークフロー例

3. **Alliedium - Awesome GitHub Actions**
   - https://github.com/Alliedium/awesome-github-actions
   - ワークフロー例のコレクション

---

## 8. 記事構成の推奨アウトライン

### 導入（約500文字）
- GitHub Actionsとは何か
- なぜベストプラクティスが重要か
- 本記事で学べること

### 第1章: セキュリティのベストプラクティス（約800文字）
- シークレット管理
- OIDC認証
- 最小権限の原則
- アクションのバージョン固定

### 第2章: パフォーマンス最適化（約700文字）
- キャッシング戦略
- 並列実行（マトリックス戦略）
- ジョブの最適化

### 第3章: 再利用可能なワークフロー（約600文字）
- Reusable Workflowsの作成
- Composite Actionsの活用
- 組織全体での標準化

### 第4章: よくある間違いと対策（約600文字）
- YAML構文エラー
- アクションバージョン管理
- 権限設定の問題

### 第5章: 実践的なワークフロー例（約500文字）
- 基本的なCI/CDパイプライン
- Dockerイメージのビルド
- クラウドデプロイ

### まとめ（約300文字）
- ベストプラクティスの重要ポイント
- 継続的な改善の推奨
- さらに学ぶためのリソース

---

## 9. 内部リンク候補（関連記事調査）

### 調査結果
リポジトリ内のコンテンツを調査した結果、以下のタグに関連する記事は現時点では見つかりませんでした：
- `github`
- `ci-cd`
- `devops`
- `automation`
- `workflow`

### 推奨事項
本記事が、上記のタグを持つ最初の記事となる可能性があります。今後、関連記事が増えた際には相互リンクを検討することを推奨します。

将来的に作成する価値がある関連記事案：
1. 「GitHub Actions で始める CI/CD 入門」
2. 「Docker と GitHub Actions で実現するコンテナベース開発」
3. 「GitHub Actions による自動テストの実装パターン」
4. 「セキュアな開発を実現する GitHub Actions セキュリティガイド」

---

## 10. キーワード戦略

### 主要キーワード
- GitHub Actions
- ベストプラクティス
- CI/CD
- セキュリティ
- パフォーマンス最適化
- ワークフロー

### 副次キーワード
- OIDC認証
- キャッシング
- マトリックスビルド
- 再利用可能なワークフロー
- シークレット管理
- セルフホストランナー

---

## 調査完了日
2025-12-19

## 調査者メモ
本調査では、GitHub Actions のベストプラクティスに関する包括的な情報を収集しました。公式ドキュメント、セキュリティベンダーのガイド、コミュニティの実践例、日本語リソースを網羅的に調査し、信頼性の高い情報源を特定しました。

特に注目すべき点：
1. 2024-2025年のプラットフォームアップデートにより、パフォーマンスが大幅に向上
2. OIDC認証が静的シークレットに代わる推奨手法として確立
3. 2025年春のサプライチェーン攻撃により、アクションのバージョン固定がより重要に
4. キャッシング戦略による40-80%のビルド時間短縮が実証されている
5. 日本語リソースも充実しており、初心者向けの情報が豊富

記事執筆時には、最新の統計データと具体的な改善事例を引用することで、読者にとって実用的で説得力のある内容とすることを推奨します。
