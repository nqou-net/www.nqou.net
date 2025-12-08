---
title: "GitOpsで実現する宣言的運用 - インフラのコード化と自動化（技術詳細）"
draft: true
tags:
- kubernetes
- gitops
- argocd
- flux
- continuous-deployment
- declarative
description: "ArgoCD/FluxによるGitOps実践ガイド。マルチクラスタ管理、CI/CDパイプライン統合、宣言的な運用自動化を完全解説。"
---

## はじめに

GitOpsは、Git をSingle Source of Truth（信頼できる唯一の情報源）とし、インフラとアプリケーションの状態を宣言的に管理する運用手法です。Kubernetesとの相性が抜群で、コードレビュー、バージョン管理、自動デプロイ、監査証跡をすべてGitで実現できます。本記事では、ArgoCD/Fluxの実装、マルチクラスタ管理、CI/CDパイプライン統合、ベストプラクティスを徹底解説します。

## 1. GitOpsの原則

### 1.1 GitOpsとは

```
GitOpsの基本概念:

┌─────────────────────────────────────────────────────────┐
│ Git Repository (Single Source of Truth)                │
│ ┌─────────────────────────────────────────────────────┐ │
│ │ manifests/                                          │ │
│ │ ├── production/                                     │ │
│ │ │   ├── deployment.yaml                            │ │
│ │ │   ├── service.yaml                               │ │
│ │ │   └── ingress.yaml                               │ │
│ │ └── staging/                                        │ │
│ │     ├── deployment.yaml                            │ │
│ │     └── ...                                         │ │
│ └──────────────┬──────────────────────────────────────┘ │
└────────────────┼────────────────────────────────────────┘
                 │
                 │ Git Pull
                 ↓
┌─────────────────────────────────────────────────────────┐
│ GitOps Operator (ArgoCD / Flux)                        │
│ ┌─────────────────────────────────────────────────────┐ │
│ │ 1. Gitリポジトリを監視                               │ │
│ │ 2. 変更を検知                                        │ │
│ │ 3. クラスタの実際の状態と比較                         │ │
│ │ 4. 差分があれば自動同期                              │ │
│ └──────────────┬──────────────────────────────────────┘ │
└────────────────┼────────────────────────────────────────┘
                 │
                 │ kubectl apply
                 ↓
┌─────────────────────────────────────────────────────────┐
│ Kubernetes Cluster                                      │
│ ┌─────────┐  ┌─────────┐  ┌─────────┐                 │
│ │  Pod    │  │  Pod    │  │  Pod    │                 │
│ └─────────┘  └─────────┘  └─────────┘                 │
└─────────────────────────────────────────────────────────┘
```

### 1.2 GitOpsの4原則

```
1. 宣言的（Declarative）
   → "何を"実現するかを記述（"どのように"は記述しない）
   → YAMLマニフェストでKubernetesリソースを定義

2. バージョン管理（Versioned and Immutable）
   → 全ての変更がGitコミット履歴に記録
   → いつでも過去の状態に戻せる（ロールバック）

3. 自動プル（Pulled Automatically）
   → GitOps Operatorがリポジトリから自動的にプル
   → Push型ではなくPull型（セキュリティ向上）

4. 継続的な調整（Continuously Reconciled）
   → 実際の状態（Actual State）と期待する状態（Desired State）を
     常に比較し、差分があれば自動修正（Self-Healing）
```

### 1.3 従来のCI/CDとの違い

| 項目 | 従来のCI/CD | GitOps |
|------|------------|--------|
| **デプロイ方式** | Push（CI/CDからクラスタへ） | Pull（クラスタがGitから） |
| **認証** | CI/CDツールがクラスタ認証必要 | クラスタ内Operatorのみ |
| **監査** | CI/CDログ | Git履歴（完全な監査証跡） |
| **ロールバック** | 手動/スクリプト | Gitリバート |
| **Drift検知** | 困難 | 自動検知・修正 |
| **宣言的** | 部分的 | 完全に宣言的 |

## 2. ArgoCD

### 2.1 ArgoCDのインストール

```bash
# ArgoCDのインストール
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# インストール確認
kubectl get pods -n argocd
# NAME                                  READY   STATUS    RESTARTS   AGE
# argocd-application-controller-0       1/1     Running   0          2m
# argocd-applicationset-controller-xxx  1/1     Running   0          2m
# argocd-dex-server-xxx                 1/1     Running   0          2m
# argocd-notifications-controller-xxx   1/1     Running   0          2m
# argocd-redis-xxx                      1/1     Running   0          2m
# argocd-repo-server-xxx                1/1     Running   0          2m
# argocd-server-xxx                     1/1     Running   0          2m

# ArgoCD CLI のインストール
VERSION=$(curl --silent "https://api.github.com/repos/argoproj/argo-cd/releases/latest" | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/')
curl -sSL -o /tmp/argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/download/$VERSION/argocd-linux-amd64
sudo install -m 555 /tmp/argocd-linux-amd64 /usr/local/bin/argocd
rm /tmp/argocd-linux-amd64

# 初期パスワード取得
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
# xxx-yyy-zzz

# ArgoCD UIへのアクセス（Port Forward）
kubectl port-forward svc/argocd-server -n argocd 8080:443
# https://localhost:8080
# Username: admin
# Password: （上記で取得したパスワード）

# CLIでログイン
argocd login localhost:8080 --insecure
# Username: admin
# Password: xxx-yyy-zzz

# パスワード変更（推奨）
argocd account update-password
```

### 2.2 Applicationリソースの作成

```yaml
# application-web-app.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: web-app
  namespace: argocd
  # Finalizerで削除時にリソースも削除
  finalizers:
  - resources-finalizer.argocd.argoproj.io
spec:
  # デプロイ先プロジェクト
  project: default
  
  # Gitリポジトリソース
  source:
    repoURL: https://github.com/myorg/k8s-manifests.git
    targetRevision: main  # ブランチ/タグ/コミットSHA
    path: production/web-app  # マニフェストのパス
    
    # Helmの場合
    # helm:
    #   valueFiles:
    #   - values-production.yaml
    #   parameters:
    #   - name: image.tag
    #     value: "1.0.0"
    
    # Kustomizeの場合
    # kustomize:
    #   namePrefix: prod-
    #   images:
    #   - myregistry/web-app:1.0.0
  
  # デプロイ先クラスタ
  destination:
    server: https://kubernetes.default.svc
    namespace: production
  
  # 同期ポリシー
  syncPolicy:
    # 自動同期
    automated:
      prune: true  # Gitから削除されたリソースも削除
      selfHeal: true  # Drift検知時に自動修正
      allowEmpty: false
    
    # 同期オプション
    syncOptions:
    - CreateNamespace=true  # Namespace自動作成
    - PrunePropagationPolicy=foreground
    - PruneLast=true  # 削除を最後に実行
    
    # リトライ設定
    retry:
      limit: 5
      backoff:
        duration: 5s
        factor: 2
        maxDuration: 3m
  
  # ヘルスチェック
  ignoreDifferences:
  - group: apps
    kind: Deployment
    jsonPointers:
    - /spec/replicas  # HPA管理下のreplicasは無視
```

```bash
# Applicationの作成
kubectl apply -f application-web-app.yaml

# 状態確認
argocd app get web-app
# Name:               web-app
# Project:            default
# Server:             https://kubernetes.default.svc
# Namespace:          production
# URL:                https://localhost:8080/applications/web-app
# Repo:               https://github.com/myorg/k8s-manifests.git
# Target:             main
# Path:               production/web-app
# SyncWindow:         Sync Allowed
# Sync Policy:        Automated (Prune)
# Sync Status:        Synced to main (abc1234)
# Health Status:      Healthy

# 手動同期（automated: falseの場合）
argocd app sync web-app

# リソース一覧
argocd app resources web-app
# GROUP  KIND        NAMESPACE    NAME       STATUS
#        Service     production   web-svc    Synced
# apps   Deployment  production   web-app    Synced

# ログ確認
argocd app logs web-app

# Diff確認（GitとクラスタのPod差分）
argocd app diff web-app
```

### 2.3 マルチクラスタ管理

```bash
# 外部クラスタの登録
# クラスタのkubeconfigを準備

# 東京クラスタを登録
argocd cluster add tokyo-cluster \
  --name tokyo \
  --kubeconfig ~/.kube/config-tokyo

# アイルランドクラスタを登録
argocd cluster add ireland-cluster \
  --name ireland \
  --kubeconfig ~/.kube/config-ireland

# クラスタ一覧確認
argocd cluster list
# SERVER                          NAME      VERSION  STATUS   MESSAGE
# https://kubernetes.default.svc  in-cluster  1.28     Successful
# https://tokyo-api.example.com   tokyo       1.28     Successful
# https://ireland-api.example.com ireland     1.28     Successful
```

```yaml
# application-multi-cluster.yaml
# 東京クラスタへのデプロイ
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: web-app-tokyo
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/myorg/k8s-manifests.git
    targetRevision: main
    path: production/web-app
  
  destination:
    server: https://tokyo-api.example.com  # 東京クラスタ
    namespace: production
  
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
---
# アイルランドクラスタへのデプロイ
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: web-app-ireland
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/myorg/k8s-manifests.git
    targetRevision: main
    path: production/web-app
  
  destination:
    server: https://ireland-api.example.com  # アイルランドクラスタ
    namespace: production
  
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

### 2.4 ApplicationSet（複数Application自動生成）

```yaml
# applicationset-multi-region.yaml
apiVersion: argoproj.io/v1alpha1
kind: ApplicationSet
metadata:
  name: web-app-multi-region
  namespace: argocd
spec:
  # Generatorでクラスタ一覧を取得
  generators:
  - list:
      elements:
      - cluster: tokyo
        url: https://tokyo-api.example.com
        region: ap-northeast-1
      - cluster: ireland
        url: https://ireland-api.example.com
        region: eu-west-1
      - cluster: virginia
        url: https://virginia-api.example.com
        region: us-east-1
  
  # Applicationテンプレート
  template:
    metadata:
      name: 'web-app-{{cluster}}'
      labels:
        region: '{{region}}'
    spec:
      project: default
      
      source:
        repoURL: https://github.com/myorg/k8s-manifests.git
        targetRevision: main
        path: 'production/{{cluster}}/web-app'
        
        # クラスタ固有のvalues
        helm:
          valueFiles:
          - 'values-{{cluster}}.yaml'
      
      destination:
        server: '{{url}}'
        namespace: production
      
      syncPolicy:
        automated:
          prune: true
          selfHeal: true
        syncOptions:
        - CreateNamespace=true
```

```bash
# ApplicationSetの適用
kubectl apply -f applicationset-multi-region.yaml

# 自動生成されたApplication確認
argocd app list
# NAME               CLUSTER                           NAMESPACE   PROJECT  STATUS  HEALTH
# web-app-tokyo      https://tokyo-api.example.com     production  default  Synced  Healthy
# web-app-ireland    https://ireland-api.example.com   production  default  Synced  Healthy
# web-app-virginia   https://virginia-api.example.com  production  default  Synced  Healthy
```

## 3. Flux

### 3.1 Fluxのインストール

```bash
# Flux CLIのインストール
curl -s https://fluxcd.io/install.sh | sudo bash

# 確認
flux --version
# flux version 2.2.0

# GitHub Personal Access Token準備（repo権限）
export GITHUB_TOKEN=<your-token>
export GITHUB_USER=<your-username>

# Fluxのブートストラップ（Gitリポジトリ自動作成）
flux bootstrap github \
  --owner=$GITHUB_USER \
  --repository=fleet-infra \
  --branch=main \
  --path=clusters/production \
  --personal \
  --components-extra=image-reflector-controller,image-automation-controller

# インストール確認
kubectl get pods -n flux-system
# NAME                                       READY   STATUS    RESTARTS   AGE
# helm-controller-xxx                        1/1     Running   0          2m
# image-automation-controller-xxx            1/1     Running   0          2m
# image-reflector-controller-xxx             1/1     Running   0          2m
# kustomize-controller-xxx                   1/1     Running   0          2m
# notification-controller-xxx                1/1     Running   0          2m
# source-controller-xxx                      1/1     Running   0          2m
```

### 3.2 GitRepositoryリソース

```yaml
# gitrepository.yaml
apiVersion: source.toolkit.fluxcd.io/v1
kind: GitRepository
metadata:
  name: k8s-manifests
  namespace: flux-system
spec:
  interval: 1m  # 1分ごとにポーリング
  
  # Gitリポジトリ
  url: https://github.com/myorg/k8s-manifests
  ref:
    branch: main
  
  # 認証（GitHub Token）
  secretRef:
    name: github-token
  
  # 無視するファイル
  ignore: |
    # Exclude CI/CD files
    .github/
    .gitlab-ci.yml
    Jenkinsfile
---
# github-token Secret
apiVersion: v1
kind: Secret
metadata:
  name: github-token
  namespace: flux-system
type: Opaque
stringData:
  username: git
  password: <GITHUB_TOKEN>
```

### 3.3 Kustomizationリソース

```yaml
# kustomization-web-app.yaml
apiVersion: kustomize.toolkit.fluxcd.io/v1
kind: Kustomization
metadata:
  name: web-app
  namespace: flux-system
spec:
  # GitRepositoryソース
  sourceRef:
    kind: GitRepository
    name: k8s-manifests
  
  # マニフェストのパス
  path: ./production/web-app
  
  # 同期間隔
  interval: 5m
  
  # プルーニング（自動削除）
  prune: true
  
  # ヘルスチェック待機
  wait: true
  timeout: 5m
  
  # デプロイ先Namespace
  targetNamespace: production
  
  # 依存関係
  dependsOn:
  - name: infrastructure
  
  # ヘルスチェック
  healthChecks:
  - apiVersion: apps/v1
    kind: Deployment
    name: web-app
    namespace: production
  
  # Kustomize設定
  patches:
  - patch: |
      - op: replace
        path: /spec/replicas
        value: 5
    target:
      kind: Deployment
      name: web-app
```

```bash
# GitRepositoryとKustomizationの適用
kubectl apply -f gitrepository.yaml
kubectl apply -f kustomization-web-app.yaml

# Flux状態確認
flux get sources git
# NAME            REVISION        SUSPENDED  READY  MESSAGE
# k8s-manifests   main@sha1:abc123  False      True   stored artifact for revision 'main@sha1:abc123'

flux get kustomizations
# NAME     REVISION        SUSPENDED  READY  MESSAGE
# web-app  main@sha1:abc123  False      True   Applied revision: main@sha1:abc123

# 詳細ログ
flux logs --level=info --follow
```

### 3.4 HelmReleaseリソース

```yaml
# helmrelease-nginx-ingress.yaml
apiVersion: source.toolkit.fluxcd.io/v1beta2
kind: HelmRepository
metadata:
  name: ingress-nginx
  namespace: flux-system
spec:
  interval: 24h
  url: https://kubernetes.github.io/ingress-nginx
---
apiVersion: helm.toolkit.fluxcd.io/v2beta1
kind: HelmRelease
metadata:
  name: nginx-ingress
  namespace: flux-system
spec:
  interval: 10m
  
  # HelmRepositoryソース
  chart:
    spec:
      chart: ingress-nginx
      version: '4.8.x'  # セマンティックバージョニング
      sourceRef:
        kind: HelmRepository
        name: ingress-nginx
        namespace: flux-system
  
  # インストール先
  targetNamespace: ingress-nginx
  install:
    createNamespace: true
  
  # Values上書き
  values:
    controller:
      replicaCount: 3
      service:
        type: LoadBalancer
        annotations:
          service.beta.kubernetes.io/aws-load-balancer-type: "nlb"
      resources:
        requests:
          cpu: 100m
          memory: 128Mi
        limits:
          cpu: 500m
          memory: 512Mi
  
  # アップグレード戦略
  upgrade:
    remediation:
      retries: 3
  
  # ロールバック
  rollback:
    recreate: true
```

### 3.5 Image Automation（イメージ自動更新）

```yaml
# imagerepository.yaml
apiVersion: image.toolkit.fluxcd.io/v1beta2
kind: ImageRepository
metadata:
  name: web-app
  namespace: flux-system
spec:
  image: myregistry/web-app
  interval: 1m
  
  # 認証
  secretRef:
    name: docker-registry-credentials
---
# imagepolicy.yaml
apiVersion: image.toolkit.fluxcd.io/v1beta2
kind: ImagePolicy
metadata:
  name: web-app
  namespace: flux-system
spec:
  imageRepositoryRef:
    name: web-app
  
  # セマンティックバージョニング
  policy:
    semver:
      range: '>=1.0.0 <2.0.0'  # 1.x.x のみ
  
  # または正規表現
  # policy:
  #   alphabetical:
  #     order: asc
---
# imageupdateautomation.yaml
apiVersion: image.toolkit.fluxcd.io/v1beta1
kind: ImageUpdateAutomation
metadata:
  name: web-app-automation
  namespace: flux-system
spec:
  interval: 30m
  
  # GitRepositoryソース
  sourceRef:
    kind: GitRepository
    name: k8s-manifests
  
  # Git更新設定
  git:
    checkout:
      ref:
        branch: main
    commit:
      author:
        email: fluxcdbot@example.com
        name: FluxCD Bot
      messageTemplate: |
        Automated image update
        
        Automation name: {{ .AutomationObject }}
        
        Files:
        {{ range $filename, $_ := .Updated.Files -}}
        - {{ $filename }}
        {{ end -}}
        
        Images:
        {{ range $image, $_ := .Updated.Images -}}
        - {{$image.Repository}}:{{$image.Tag}}
        {{ end -}}
    push:
      branch: main
  
  # 更新対象
  update:
    path: ./production/web-app
    strategy: Setters
```

```yaml
# deployment.yaml (マーカー付き)
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app
  namespace: production
spec:
  replicas: 3
  selector:
    matchLabels:
      app: web
  template:
    metadata:
      labels:
        app: web
    spec:
      containers:
      - name: web
        image: myregistry/web-app:1.0.0  # {"$imagepolicy": "flux-system:web-app"}
        ports:
        - containerPort: 8080
```

```bash
# Image Automation確認
flux get image repository
# NAME     LAST SCAN               SUSPENDED  READY  MESSAGE
# web-app  2024-12-08T10:00:00Z    False      True   successful scan, found 25 tags

flux get image policy
# NAME     LATEST IMAGE                    READY  MESSAGE
# web-app  myregistry/web-app:1.2.5        True   Latest image tag for 'myregistry/web-app' resolved to 1.2.5

flux get image update
# NAME                  LAST RUN                SUSPENDED  READY  MESSAGE
# web-app-automation    2024-12-08T10:05:00Z    False      True   no updates made

# 新しいイメージタグがプッシュされると:
# 1. ImageRepositoryが新タグ検知
# 2. ImagePolicyがバージョン評価
# 3. ImageUpdateAutomationがdeployment.yamlを自動更新しGitコミット
# 4. Kustomizationが変更を検知し自動デプロイ
```

## 4. CI/CDパイプライン統合

### 4.1 GitHub ActionsとArgoCDの統合

```yaml
# .github/workflows/build-and-deploy.yaml
name: Build and Deploy

on:
  push:
    branches:
      - main
    paths:
      - 'src/**'

env:
  IMAGE_NAME: myregistry/web-app
  ARGOCD_SERVER: argocd.example.com

jobs:
  build:
    runs-on: ubuntu-latest
    outputs:
      image_tag: ${{ steps.meta.outputs.tags }}
    
    steps:
    - name: Checkout code
      uses: actions/checkout@v4
    
    - name: Set up Docker Buildx
      uses: docker/setup-buildx-action@v3
    
    - name: Login to Docker Registry
      uses: docker/login-action@v3
      with:
        registry: myregistry
        username: ${{ secrets.DOCKER_USERNAME }}
        password: ${{ secrets.DOCKER_PASSWORD }}
    
    - name: Docker metadata
      id: meta
      uses: docker/metadata-action@v5
      with:
        images: ${{ env.IMAGE_NAME }}
        tags: |
          type=sha,prefix={{branch}}-
          type=semver,pattern={{version}}
    
    - name: Build and push
      uses: docker/build-push-action@v5
      with:
        context: .
        push: true
        tags: ${{ steps.meta.outputs.tags }}
        cache-from: type=gha
        cache-to: type=gha,mode=max
  
  update-manifest:
    needs: build
    runs-on: ubuntu-latest
    
    steps:
    - name: Checkout manifest repo
      uses: actions/checkout@v4
      with:
        repository: myorg/k8s-manifests
        token: ${{ secrets.GITHUB_TOKEN }}
    
    - name: Update image tag
      run: |
        # Kustomizeで画像タグ更新
        cd production/web-app
        kustomize edit set image ${{ env.IMAGE_NAME }}=${{ needs.build.outputs.image_tag }}
    
    - name: Commit and push
      run: |
        git config user.name "GitHub Actions"
        git config user.email "actions@github.com"
        git add .
        git commit -m "Update image to ${{ needs.build.outputs.image_tag }}"
        git push
    
    # ArgoCD同期トリガー（オプション）
    - name: Trigger ArgoCD sync
      run: |
        # ArgoCD CLIで同期
        argocd login ${{ env.ARGOCD_SERVER }} \
          --username admin \
          --password ${{ secrets.ARGOCD_PASSWORD }} \
          --insecure
        
        argocd app sync web-app --prune
```

### 4.2 Progressive Delivery（段階的デプロイ）

```yaml
# rollout-canary.yaml (Argo Rollouts)
apiVersion: argoproj.io/v1alpha1
kind: Rollout
metadata:
  name: web-app
  namespace: production
spec:
  replicas: 10
  
  selector:
    matchLabels:
      app: web
  
  template:
    metadata:
      labels:
        app: web
    spec:
      containers:
      - name: web
        image: myregistry/web-app:1.0.0
        ports:
        - containerPort: 8080
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
  
  # Canary戦略
  strategy:
    canary:
      # カナリアService
      canaryService: web-canary
      # StableService
      stableService: web-stable
      
      # トラフィック分割
      trafficRouting:
        istio:
          virtualService:
            name: web-virtualservice
            routes:
            - primary
      
      # ステップ定義
      steps:
      # 1. 10%のトラフィックをカナリアに
      - setWeight: 10
      - pause: {duration: 5m}
      
      # 2. メトリクス分析
      - analysis:
          templates:
          - templateName: success-rate
          args:
          - name: service-name
            value: web-canary
      
      # 3. 30%に増加
      - setWeight: 30
      - pause: {duration: 5m}
      
      # 4. 50%に増加
      - setWeight: 50
      - pause: {duration: 10m}
      
      # 5. 100%（完全ロールアウト）
      - setWeight: 100
---
# analysistemplate.yaml
apiVersion: argoproj.io/v1alpha1
kind: AnalysisTemplate
metadata:
  name: success-rate
  namespace: production
spec:
  args:
  - name: service-name
  
  metrics:
  # 成功率（Prometheus）
  - name: success-rate
    interval: 1m
    successCondition: result >= 0.95  # 95%以上
    failureLimit: 3
    provider:
      prometheus:
        address: http://prometheus.monitoring.svc:9090
        query: |
          sum(rate(http_requests_total{service="{{args.service-name}}",status!~"5.."}[2m]))
          /
          sum(rate(http_requests_total{service="{{args.service-name}}"}[2m]))
  
  # レイテンシ
  - name: latency-p95
    interval: 1m
    successCondition: result <= 0.200  # 200ms以下
    failureLimit: 3
    provider:
      prometheus:
        address: http://prometheus.monitoring.svc:9090
        query: |
          histogram_quantile(0.95, 
            rate(http_request_duration_seconds_bucket{service="{{args.service-name}}"}[2m])
          )
```

## 5. ベストプラクティス

### 5.1 リポジトリ構成

```
推奨リポジトリ構造:

k8s-manifests/
├── base/                    # 共通マニフェスト
│   └── web-app/
│       ├── deployment.yaml
│       ├── service.yaml
│       ├── configmap.yaml
│       └── kustomization.yaml
│
├── overlays/                # 環境別オーバーレイ
│   ├── development/
│   │   ├── kustomization.yaml
│   │   ├── replica-patch.yaml
│   │   └── resource-patch.yaml
│   │
│   ├── staging/
│   │   ├── kustomization.yaml
│   │   └── ...
│   │
│   └── production/
│       ├── kustomization.yaml
│       ├── replica-patch.yaml  # replicas: 10
│       ├── resource-patch.yaml  # CPU/Memoryリソース
│       └── hpa.yaml
│
├── clusters/                # クラスタ固有設定
│   ├── tokyo/
│   │   ├── flux-system/
│   │   └── infrastructure/
│   │       ├── sources/
│   │       └── configs/
│   │
│   ├── ireland/
│   └── virginia/
│
└── README.md
```

### 5.2 チェックリスト

- ✅ Gitを唯一の信頼できる情報源とする
- ✅ マニフェストは宣言的に記述
- ✅ 環境ごとにブランチ/ディレクトリ分離
- ✅ Secretは暗号化（Sealed Secrets/External Secrets）
- ✅ 自動同期を有効化（selfHeal: true）
- ✅ Prune（自動削除）を有効化
- ✅ ヘルスチェックとProbe設定
- ✅ Progressive Delivery（段階的デプロイ）
- ✅ 監査証跡（Git履歴）の保持
- ✅ CI/CDパイプライン統合
- ❌ 手動でkubectl applyしない
- ❌ クラスタ直接変更しない（Driftの原因）

### 5.3 Secretの安全な管理

```yaml
# sealed-secret-integration.yaml
apiVersion: bitnami.com/v1alpha1
kind: SealedSecret
metadata:
  name: db-credentials
  namespace: production
spec:
  encryptedData:
    username: AgBi8F7N...
    password: AgCx9K2M...
  template:
    metadata:
      name: db-credentials
      namespace: production
    type: Opaque
```

```yaml
# external-secret-integration.yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: db-credentials
  namespace: production
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: aws-secretstore
    kind: SecretStore
  target:
    name: db-credentials
    creationPolicy: Owner
  data:
  - secretKey: username
    remoteRef:
      key: production/database
      property: username
  - secretKey: password
    remoteRef:
      key: production/database
      property: password
```

## まとめ

### 学んだこと

1. **GitOpsの原則**
   - 宣言的、バージョン管理、自動プル、継続的調整
   - GitをSingle Source of Truth
   - Push型からPull型へ

2. **ArgoCD実践**
   - Applicationリソース
   - マルチクラスタ管理
   - ApplicationSetによる自動生成

3. **Flux実践**
   - GitRepository/Kustomization
   - HelmRelease
   - Image Automation

4. **CI/CDパイプライン統合**
   - GitHub Actionsとの連携
   - Progressive Delivery（Canary/Blue-Green）
   - AnalysisTemplateによる自動評価

5. **ベストプラクティス**
   - リポジトリ構成
   - Secretの安全な管理
   - 監査証跡とロールバック

### 次回予告

次回は最終回「99.9999%を実現する完全構成」として、マルチリージョン+マルチAZ構成、SLO設定、コスト最適化、シリーズ全体のまとめをお届けします。

## 参考リンク

- {{< linkcard "https://argo-cd.readthedocs.io/" >}}
- {{< linkcard "https://fluxcd.io/" >}}
- {{< linkcard "https://opengitops.dev/" >}}
- {{< linkcard "https://argoproj.github.io/argo-rollouts/" >}}
