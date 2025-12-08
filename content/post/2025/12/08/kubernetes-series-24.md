---
title: "Kubernetesを完全に理解した(第24回) - GitOpsで宣言的運用"
draft: true
tags:
- kubernetes
- gitops
- argocd
- infrastructure-as-code
- automation
description: すべての変更をGitで管理し、自動同期で運用する最先端の手法。人的ミスを削減し、完全な監査証跡を持つ理想的なDevOps環境を実現します。
---

## 前回の振り返り

第23回では、カオスエンジニアリングを実践しました。Litmus Chaosを使用してPod削除、リソース負荷、ネットワーク障害などを意図的に起こし、システムの弾力性を検証しました。GameDayを通じてチーム全体で障害対応の経験を積み、真に堅牢なシステムを構築する手法を学びました。

しかし、どんなに堅牢なシステムを構築しても、デプロイ時の人的ミスや設定ドリフト(意図しない設定の乖離)によって障害が発生することがあります。「誰が・いつ・何を変更したか」が不明瞭だと、トラブルシューティングも困難です。

今回は、**GitOps**という革新的な運用手法を実践します。すべての変更をGitリポジトリで管理し、クラスタの状態を自動的に同期することで、完全な監査証跡と再現性を持つ理想的なDevOps環境を実現します。

## GitOpsとは

### GitOpsの基本原則

GitOpsは、Weaveworksが提唱した運用モデルで、以下の原則に基づいています。

1. **宣言的定義**: システムの望ましい状態をGit上のマニフェストで宣言的に定義
2. **バージョン管理**: すべての変更がGitの履歴として記録される
3. **自動同期**: GitリポジトリとクラスタのStateが常に一致するよう自動同期
4. **監査可能性**: 誰が・いつ・何を変更したかが完全に追跡可能

### 従来のPush型との違い

**従来のPush型CI/CD**:
```
Developer → Git Push → CI/CD Pipeline → kubectl apply → Cluster
```

CI/CDパイプラインがクラスタに直接変更を適用します。クラスタへの認証情報をCI/CDに持たせる必要があり、セキュリティリスクがあります。

**GitOps (Pull型)**:
```
Developer → Git Push → Git Repository ← Poll ← Cluster内のOperator
```

クラスタ内のOperator(ArgoCD等)がGitリポジトリを定期的に監視し、差分があれば自動的に同期します。クラスタ外からの直接アクセスが不要で、よりセキュアです。

### GitOpsのメリット

- **設定ドリフトの防止**: 手動変更が検知され、Gitの定義に自動修正される
- **完全な監査証跡**: すべての変更がGit履歴に記録される
- **簡単なロールバック**: `git revert`で即座に前の状態に戻せる
- **宣言的で理解しやすい**: マニフェストを見れば現在の状態が分かる
- **災害復旧が容易**: Gitリポジトリから全環境を再構築可能

## ArgoCDの導入

### インストール

ArgoCDは、Kubernetes向けの最も人気のあるGitOpsツールです。

```bash
# ArgoCD namespaceを作成
kubectl create namespace argocd

# ArgoCDをインストール
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# CLI インストール
curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd

# 初期パスワード取得
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d

# UIにアクセス(ポートフォワード)
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

ブラウザで`https://localhost:8080`にアクセスし、ユーザー名`admin`と取得したパスワードでログインします。

### 最初のApplication

ArgoCDでは、デプロイ対象を「Application」として定義します。

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: web-app
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/myorg/k8s-manifests
    targetRevision: main
    path: apps/web-app
  destination:
    server: https://kubernetes.default.svc
    namespace: production
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    - CreateNamespace=true
```

この設定を適用すると、ArgoCDが`apps/web-app`ディレクトリ内のマニフェストを自動的にクラスタに適用します。

```bash
kubectl apply -f web-app-application.yaml

# 同期状況の確認
argocd app get web-app

# 手動同期(自動同期を無効にしている場合)
argocd app sync web-app
```

## 自動同期とSelf-Healing

### 自動同期の威力

`syncPolicy.automated`を有効にすると、Gitリポジトリの変更を自動的にクラスタに反映します。

```bash
# Gitリポジトリでマニフェストを変更
cd k8s-manifests/apps/web-app
vi deployment.yaml  # replicasを3から5に変更
git add deployment.yaml
git commit -m "Scale web-app to 5 replicas"
git push

# 数秒後、ArgoCD が自動的に検知して同期
# クラスタのレプリカ数が5になる
```

### Self-Healing

`selfHeal: true`を設定すると、誰かが手動で`kubectl`コマンドでクラスタを変更しても、ArgoCDが自動的にGitの定義に戻します。

```bash
# 手動でレプリカ数を変更してみる
kubectl scale deployment web-app --replicas=10 -n production

# 数秒後、ArgoCDが検知してレプリカ数を5(Git上の定義)に戻す
kubectl get deployment web-app -n production
# READY: 5/5
```

これにより、設定ドリフトが完全に防止されます。

## Helmチャートの管理

### HelmをGitOpsで管理

ArgoCDは、素のマニフェストだけでなくHelmチャートも管理できます。

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: nginx-ingress
  namespace: argocd
spec:
  project: infrastructure
  source:
    repoURL: https://kubernetes.github.io/ingress-nginx
    chart: ingress-nginx
    targetRevision: 4.8.0
    helm:
      values: |
        controller:
          replicaCount: 3
          resources:
            requests:
              cpu: 100m
              memory: 128Mi
          service:
            type: LoadBalancer
          metrics:
            enabled: true
            serviceMonitor:
              enabled: true
  destination:
    server: https://kubernetes.default.svc
    namespace: ingress-nginx
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
    - CreateNamespace=true
```

Helmのvaluesファイルもバージョン管理され、変更履歴が明確になります。

## Kustomizeの活用

### 環境別の設定管理

Kustomizeを使用すると、ベース定義と環境別のオーバーレイを分離できます。

```
k8s-manifests/
├── apps/
│   └── web-app/
│       ├── base/
│       │   ├── kustomization.yaml
│       │   ├── deployment.yaml
│       │   └── service.yaml
│       └── overlays/
│           ├── staging/
│           │   ├── kustomization.yaml
│           │   └── patches.yaml
│           └── production/
│               ├── kustomization.yaml
│               └── patches.yaml
```

**base/kustomization.yaml**:
```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
- deployment.yaml
- service.yaml
```

**overlays/production/kustomization.yaml**:
```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
bases:
- ../../base
patchesStrategicMerge:
- patches.yaml
replicas:
- name: web-app
  count: 10
```

**overlays/production/patches.yaml**:
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app
spec:
  template:
    spec:
      containers:
      - name: web
        resources:
          requests:
            memory: "512Mi"
            cpu: "500m"
          limits:
            memory: "1Gi"
            cpu: "1000m"
```

ArgoCDのApplication定義でパスを指定するだけで、環境別の設定が適用されます。

```yaml
source:
  path: apps/web-app/overlays/production
```

## AppProjectとRBAC

### プロジェクトによる権限分離

AppProjectを使用することで、チームやアプリケーションごとにアクセス権限を分離できます。

```yaml
apiVersion: argoproj.io/v1alpha1
kind: AppProject
metadata:
  name: production
  namespace: argocd
spec:
  description: Production applications
  sourceRepos:
  - https://github.com/myorg/k8s-manifests
  destinations:
  - namespace: production
    server: https://kubernetes.default.svc
  - namespace: production-*
    server: https://kubernetes.default.svc
  clusterResourceWhitelist:
  - group: ''
    kind: Namespace
  namespaceResourceWhitelist:
  - group: 'apps'
    kind: Deployment
  - group: ''
    kind: Service
  roles:
  - name: developer
    description: Developer role
    policies:
    - p, proj:production:developer, applications, sync, production/*, allow
    groups:
    - dev-team
  - name: admin
    description: Admin role
    policies:
    - p, proj:production:admin, applications, *, production/*, allow
    groups:
    - platform-team
```

開発チームは`production` AppProject内のアプリケーションの同期のみ可能で、削除や変更は不可という制御ができます。

## Sync WavesとHooks

### デプロイ順序の制御

複数のリソースを特定の順序でデプロイしたい場合、Sync Wavesを使用します。

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: production
  annotations:
    argocd.argoproj.io/sync-wave: "0"
---
apiVersion: v1
kind: Secret
metadata:
  name: db-credentials
  namespace: production
  annotations:
    argocd.argoproj.io/sync-wave: "1"
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: postgres
  namespace: production
  annotations:
    argocd.argoproj.io/sync-wave: "2"
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app
  namespace: production
  annotations:
    argocd.argoproj.io/sync-wave: "3"
```

Wave 0 → 1 → 2 → 3 の順序でデプロイされます。

### Sync Hooks

デプロイ前後に特定のタスクを実行したい場合、Sync Hooksを使用します。

```yaml
# データベースマイグレーション(デプロイ前に実行)
apiVersion: batch/v1
kind: Job
metadata:
  name: db-migration
  annotations:
    argocd.argoproj.io/hook: PreSync
    argocd.argoproj.io/hook-delete-policy: BeforeHookCreation
spec:
  template:
    spec:
      containers:
      - name: migrate
        image: flyway/flyway:9
        command: ["flyway", "migrate"]
      restartPolicy: Never
---
# スモークテスト(デプロイ後に実行)
apiVersion: batch/v1
kind: Job
metadata:
  name: smoke-test
  annotations:
    argocd.argoproj.io/hook: PostSync
    argocd.argoproj.io/hook-delete-policy: HookSucceeded
spec:
  template:
    spec:
      containers:
      - name: test
        image: curlimages/curl
        command:
        - sh
        - -c
        - curl -f http://web-service/health || exit 1
      restartPolicy: Never
```

## ApplicationSetによる大規模管理

### 複数のアプリケーションを一括管理

ApplicationSetを使用すると、似たような構造のアプリケーションを効率的に管理できます。

```yaml
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: microservices
  namespace: argocd
spec:
  generators:
  - list:
      elements:
      - service: user-api
        replicas: "3"
      - service: order-api
        replicas: "5"
      - service: payment-api
        replicas: "2"
  template:
    metadata:
      name: '{{service}}'
    spec:
      project: default
      source:
        repoURL: https://github.com/myorg/k8s-manifests
        targetRevision: main
        path: 'apps/{{service}}'
      destination:
        server: https://kubernetes.default.svc
        namespace: production
      syncPolicy:
        automated:
          prune: true
          selfHeal: true
```

この1つのApplicationSetで、3つのマイクロサービスが自動的に管理されます。

## Sealed Secretsで機密情報を管理

### 暗号化されたSecretをGitで管理

通常、KubernetesのSecretをGitにコミットすることはセキュリティリスクです。Sealed Secretsを使用すると、暗号化されたSecretを安全にGitで管理できます。

```bash
# Sealed Secrets Controllerをインストール
kubectl apply -f https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.24.0/controller.yaml

# kubeseal CLIをインストール
wget https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.24.0/kubeseal-linux-amd64
sudo install -m 755 kubeseal-linux-amd64 /usr/local/bin/kubeseal

# 通常のSecretを作成
kubectl create secret generic db-credentials \
  --from-literal=username=admin \
  --from-literal=password=supersecret \
  --dry-run=client -o yaml > secret.yaml

# Sealed Secretに変換
kubeseal -f secret.yaml -w sealed-secret.yaml

# Gitにコミット(暗号化されているので安全)
git add sealed-secret.yaml
git commit -m "Add database credentials"
git push
```

クラスタにSealed Secretが適用されると、自動的に復号化されて通常のSecretとして利用可能になります。

## Notification統合

### Slackへの通知

デプロイ完了時にSlackへ通知を送ることができます。

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: argocd-notifications-cm
  namespace: argocd
data:
  service.slack: |
    token: $slack-token
  template.app-deployed: |
    message: |
      Application {{.app.metadata.name}} is deployed!
    slack:
      attachments: |
        [{
          "title": "{{ .app.metadata.name}}",
          "color": "#18be52",
          "fields": [{
            "title": "Sync Status",
            "value": "{{.app.status.sync.status}}"
          }]
        }]
  trigger.on-deployed: |
    - when: app.status.operationState.phase in ['Succeeded']
      send: [app-deployed]
```

## Progressive Deliveryとの統合

### Argo Rolloutsでカナリアデプロイ

ArgoCDとArgo Rolloutsを組み合わせると、段階的なデプロイが可能になります。

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Rollout
metadata:
  name: web-app
spec:
  replicas: 10
  strategy:
    canary:
      steps:
      - setWeight: 10
      - pause: {duration: 5m}
      - setWeight: 30
      - pause: {duration: 5m}
      - setWeight: 50
      - pause: {duration: 5m}
      - setWeight: 100
  template:
    spec:
      containers:
      - name: web
        image: myapp:v2.0
```

新バージョンを10% → 30% → 50% → 100%と段階的にロールアウトしながら、各段階でメトリクスを監視できます。

## まとめ

GitOpsにより、すべての変更がGitで管理され、クラスタの状態が自動的に同期される理想的な運用環境を実現しました。ArgoCDを使用して宣言的にアプリケーションを管理し、Sync WavesやHooksでデプロイを細かく制御し、ApplicationSetで大規模な環境を効率的に管理できます。

次回はいよいよシリーズ最終回！**99.9999%を実現する完全構成**として、これまで学んだすべての技術を統合し、真の無敵インフラを完成させます。

### 主要な学習ポイント

- GitOpsの原則とメリット
- ArgoCDの導入と基本的な使い方
- 自動同期とSelf-Healingによる設定ドリフト防止
- HelmとKustomizeのGitOps管理
- AppProjectによる権限分離
- Sync WavesとHooksでのデプロイ制御
- ApplicationSetによる大規模管理
- Sealed Secretsによる機密情報の安全な管理

Gitが唯一の真実の源(Single Source of Truth)となり、すべての変更が追跡可能な理想的な運用環境を手に入れました！
