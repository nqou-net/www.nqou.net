---
title: "Kubernetesを完全に理解した（第9回）- Namespaceで環境を分離する"
draft: true
tags:
- kubernetes
- namespace
- resource-quota
- multi-tenancy
- isolation
description: "開発・検証・本番環境を一つのクラスタで安全に管理する方法。リソースの分離と適切な権限管理を実践します。"
---

## はじめに - 第8回の振り返りと第9回で学ぶこと

前回の第8回では、Persistentな運用の仕組みとして、PersistentVolumeとPersistentVolumeClaimによるストレージ管理、データベースのステートフル運用、そしてバックアップとリストア戦略について学びました。データを永続化し、Podが再作成されてもデータが失われない仕組みを理解できました。

今回の第9回では、**Namespace（ネームスペース）** を使った環境分離について学びます。一つのKubernetesクラスタ上で、開発環境、検証環境、本番環境を安全に共存させる方法、リソースの適切な制限、そして実運用で必要となる権限管理の基礎を解説します。

本記事で学ぶ内容：

- Namespaceの概念と用途
- 環境別Namespace設計（dev/staging/prod）
- ResourceQuotaによるリソース制限
- LimitRangeによるデフォルト値設定
- Namespace間通信とNetworkPolicy
- kubectlのコンテキスト管理

## Namespaceの概念と用途

### Namespaceとは何か

Namespaceは、Kubernetesクラスタ内でリソースを**論理的に分離**するための仕組みです。一つの物理的なクラスタを、複数の仮想的なクラスタとして扱うことができます。

```bash
# デフォルトで存在するNamespaceの確認
kubectl get namespaces
# または短縮形
kubectl get ns

# 出力例:
# NAME              STATUS   AGE
# default           Active   10d
# kube-node-lease   Active   10d
# kube-public       Active   10d
# kube-system       Active   10d
```

**デフォルトのNamespace：**

- `default`: 特に指定しない場合にリソースが作成される場所
- `kube-system`: Kubernetesシステムコンポーネントが動作する場所
- `kube-public`: 全ユーザーがアクセス可能な公開情報用
- `kube-node-lease`: ノードのハートビート情報管理用

### なぜNamespaceが必要なのか

**1. マルチテナント運用**

複数のチームやプロジェクトが同一クラスタを共有する場合、お互いのリソースを分離できます。

```bash
# チームAのNamespace
kubectl create namespace team-a

# チームBのNamespace
kubectl create namespace team-b

# 各チームは自分のNamespace内でのみ作業
kubectl get pods -n team-a
kubectl get pods -n team-b
```

**2. 環境の分離**

開発、検証、本番環境を同一クラスタ内で安全に分離できます。

```bash
# 環境別Namespaceの作成
kubectl create namespace dev
kubectl create namespace staging
kubectl create namespace prod

# 環境ごとに異なる設定を適用可能
```

**3. リソースの管理**

Namespace単位でリソースクォータを設定し、一部のチームや環境がクラスタ全体のリソースを占有することを防ぎます。

**4. アクセス制御**

RBAC（Role-Based Access Control）と組み合わせて、Namespace単位で権限を制御できます。

### Namespaceの制約と注意点

**Namespace内に配置できるリソース：**

- Pod、Deployment、Service、ConfigMap、Secret など

**Namespaceに属さないリソース（クラスタスコープ）：**

- Node、PersistentVolume、Namespace自体、ClusterRole など

```bash
# リソースがNamespace化されているか確認
kubectl api-resources --namespaced=true

# Namespace化されていないリソース
kubectl api-resources --namespaced=false
```

## 環境別Namespace設計 - dev/staging/prod構成

### 基本的な環境構成

実運用では、以下のような環境分離が一般的です。

```yaml
# namespaces.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: dev
  labels:
    environment: development
    team: engineering
---
apiVersion: v1
kind: Namespace
metadata:
  name: staging
  labels:
    environment: staging
    team: engineering
---
apiVersion: v1
kind: Namespace
metadata:
  name: prod
  labels:
    environment: production
    team: engineering
```

```bash
# 一括作成
kubectl apply -f namespaces.yaml

# 確認
kubectl get namespaces --show-labels
```

### 環境別の具体的な運用例

**開発環境（dev）：**

```yaml
# dev-nginx.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx
  namespace: dev  # 明示的にNamespaceを指定
  labels:
    app: nginx
    environment: dev
spec:
  replicas: 1  # 開発環境は最小限
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.25-alpine
        ports:
        - containerPort: 80
        resources:
          requests:
            memory: "64Mi"
            cpu: "100m"
          limits:
            memory: "128Mi"
            cpu: "200m"
---
apiVersion: v1
kind: Service
metadata:
  name: nginx
  namespace: dev
spec:
  selector:
    app: nginx
  ports:
  - port: 80
    targetPort: 80
  type: ClusterIP
```

**本番環境（prod）：**

```yaml
# prod-nginx.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx
  namespace: prod  # 本番Namespace
  labels:
    app: nginx
    environment: prod
spec:
  replicas: 3  # 本番環境は冗長性確保
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.25-alpine
        ports:
        - containerPort: 80
        resources:
          requests:
            memory: "256Mi"
            cpu: "500m"
          limits:
            memory: "512Mi"
            cpu: "1000m"
        livenessProbe:  # 本番環境はヘルスチェック必須
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 10
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 5
          periodSeconds: 5
---
apiVersion: v1
kind: Service
metadata:
  name: nginx
  namespace: prod
spec:
  selector:
    app: nginx
  ports:
  - port: 80
    targetPort: 80
  type: LoadBalancer  # 本番環境は外部公開
```

```bash
# デプロイ
kubectl apply -f dev-nginx.yaml
kubectl apply -f prod-nginx.yaml

# それぞれの環境を確認
kubectl get all -n dev
kubectl get all -n prod

# 同じ名前のリソースが異なるNamespaceに共存
kubectl get deployment nginx -n dev
kubectl get deployment nginx -n prod
```

### Namespace切り替えの効率化

毎回 `-n` オプションを付けるのは面倒なので、デフォルトNamespaceを切り替えます。

```bash
# 現在のコンテキスト確認
kubectl config current-context

# デフォルトNamespaceをdevに変更
kubectl config set-context --current --namespace=dev

# 確認（-nオプション不要）
kubectl get pods

# 本番環境に切り替え
kubectl config set-context --current --namespace=prod
kubectl get pods

# 元に戻す
kubectl config set-context --current --namespace=default
```

## ResourceQuotaでリソース制限

### ResourceQuotaの必要性

Namespace内で使用できるリソースの上限を設定し、一部の環境やチームがクラスタ全体のリソースを占有することを防ぎます。

### 基本的なResourceQuota

```yaml
# dev-quota.yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: dev-quota
  namespace: dev
spec:
  hard:
    # CPU/メモリの制限
    requests.cpu: "2"        # 合計リクエスト2コアまで
    requests.memory: "4Gi"   # 合計リクエスト4GiBまで
    limits.cpu: "4"          # 合計上限4コアまで
    limits.memory: "8Gi"     # 合計上限8GiBまで
    
    # リソース数の制限
    pods: "10"               # Pod数10個まで
    services: "5"            # Service数5個まで
    configmaps: "10"         # ConfigMap数10個まで
    persistentvolumeclaims: "5"  # PVC数5個まで
    secrets: "10"            # Secret数10個まで
```

### 環境別のQuota設定

**開発環境（制限緩め）：**

```yaml
# dev-quota.yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: dev-quota
  namespace: dev
spec:
  hard:
    requests.cpu: "4"
    requests.memory: "8Gi"
    limits.cpu: "8"
    limits.memory: "16Gi"
    pods: "50"
```

**本番環境（リソース多め、厳格な管理）：**

```yaml
# prod-quota.yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: prod-quota
  namespace: prod
spec:
  hard:
    requests.cpu: "20"
    requests.memory: "40Gi"
    limits.cpu: "30"
    limits.memory: "60Gi"
    pods: "100"
    services.loadbalancers: "3"  # LoadBalancer型Serviceの上限
```

```bash
# ResourceQuotaの適用
kubectl apply -f dev-quota.yaml
kubectl apply -f prod-quota.yaml

# 確認
kubectl get resourcequota -n dev
kubectl describe resourcequota dev-quota -n dev

# 出力例:
# Name:                   dev-quota
# Namespace:              dev
# Resource                Used  Hard
# --------                ----  ----
# limits.cpu              200m  8
# limits.memory           128Mi 16Gi
# pods                    1     50
# requests.cpu            100m  4
# requests.memory         64Mi  8Gi
```

### Quotaオーバー時の動作

ResourceQuotaを超えるリソースを作成しようとするとエラーになります。

```yaml
# 大きすぎるPodの例
apiVersion: v1
kind: Pod
metadata:
  name: huge-pod
  namespace: dev
spec:
  containers:
  - name: nginx
    image: nginx
    resources:
      requests:
        cpu: "5"  # dev-quotaの上限（4コア）を超える
```

```bash
kubectl apply -f huge-pod.yaml
# Error from server (Forbidden): error when creating "huge-pod.yaml": 
# pods "huge-pod" is forbidden: exceeded quota: dev-quota, 
# requested: requests.cpu=5, used: requests.cpu=100m, limited: requests.cpu=4
```

### Quotaの監視

```bash
# 定期的に使用状況を確認
kubectl get resourcequota -n dev -o yaml

# より見やすい形式で
kubectl describe resourcequota -n dev

# 全Namespaceのquota確認
kubectl get resourcequota --all-namespaces
```

## LimitRangeでデフォルト値設定

### LimitRangeの役割

ResourceQuotaはNamespace全体の上限を設定しますが、LimitRangeは**個別のPod/Containerのデフォルト値や制限範囲**を設定します。

### 基本的なLimitRange

```yaml
# dev-limitrange.yaml
apiVersion: v1
kind: LimitRange
metadata:
  name: dev-limitrange
  namespace: dev
spec:
  limits:
  # Containerごとの制限
  - type: Container
    default:  # デフォルトのlimits（未指定時に適用）
      cpu: "500m"
      memory: "512Mi"
    defaultRequest:  # デフォルトのrequests
      cpu: "100m"
      memory: "128Mi"
    max:  # 最大値
      cpu: "2"
      memory: "2Gi"
    min:  # 最小値
      cpu: "50m"
      memory: "64Mi"
    maxLimitRequestRatio:  # limits/requestsの最大比率
      cpu: "4"
      memory: "4"
  
  # Podごとの制限
  - type: Pod
    max:
      cpu: "4"
      memory: "4Gi"
    min:
      cpu: "100m"
      memory: "128Mi"
  
  # PersistentVolumeClaimの制限
  - type: PersistentVolumeClaim
    max:
      storage: "10Gi"
    min:
      storage: "1Gi"
```

```bash
# LimitRangeの適用
kubectl apply -f dev-limitrange.yaml

# 確認
kubectl get limitrange -n dev
kubectl describe limitrange dev-limitrange -n dev
```

### LimitRangeの効果確認

**リソース指定なしのPodをデプロイ：**

```yaml
# no-resources-pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: no-resources-pod
  namespace: dev
spec:
  containers:
  - name: nginx
    image: nginx:alpine
    # resources指定なし
```

```bash
kubectl apply -f no-resources-pod.yaml

# 自動的にデフォルト値が適用される
kubectl get pod no-resources-pod -n dev -o yaml | grep -A 10 resources:
# 出力例:
#   resources:
#     limits:
#       cpu: 500m
#       memory: 512Mi
#     requests:
#       cpu: 100m
#       memory: 128Mi
```

### 実践的なLimitRange設定例

**本番環境用（厳格な設定）：**

```yaml
# prod-limitrange.yaml
apiVersion: v1
kind: LimitRange
metadata:
  name: prod-limitrange
  namespace: prod
spec:
  limits:
  - type: Container
    default:
      cpu: "1"
      memory: "1Gi"
    defaultRequest:
      cpu: "500m"
      memory: "512Mi"
    max:
      cpu: "4"
      memory: "8Gi"
    min:
      cpu: "100m"
      memory: "128Mi"
    maxLimitRequestRatio:
      cpu: "2"  # 本番は比率を厳しく
      memory: "2"
  - type: Pod
    max:
      cpu: "8"
      memory: "16Gi"
```

## Namespaceを跨いだ通信

### Namespace内通信

同じNamespace内のServiceへは、サービス名だけでアクセスできます。

```bash
# dev Namespace内のnginx Serviceに接続
kubectl run test-pod --image=alpine --rm -it -n dev -- sh
/ # wget -O- http://nginx
# 成功（同じNamespace内）
```

### Namespace間通信

異なるNamespace間では、完全修飾ドメイン名（FQDN）を使用します。

**DNS名前解決のルール：**

```
<service-name>.<namespace>.svc.cluster.local
```

**具体例：**

```bash
# dev NamespaceからprodのServiceにアクセス
kubectl run test-pod --image=alpine --rm -it -n dev -- sh

/ # wget -O- http://nginx.prod.svc.cluster.local
# 成功（FQDN使用）

/ # wget -O- http://nginx
# 失敗（devのnginxを探してしまう）
```

### 実践例：マイクロサービス間通信

```yaml
# backend.yaml (prod Namespace)
apiVersion: v1
kind: Service
metadata:
  name: backend
  namespace: prod
spec:
  selector:
    app: backend
  ports:
  - port: 8080
---
# frontend.yaml (prod Namespace)
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend
  namespace: prod
spec:
  replicas: 2
  selector:
    matchLabels:
      app: frontend
  template:
    metadata:
      labels:
        app: frontend
    spec:
      containers:
      - name: frontend
        image: myapp/frontend:1.0
        env:
        - name: BACKEND_URL
          value: "http://backend.prod.svc.cluster.local:8080"
```

### NetworkPolicyによるNamespace間通信制御

デフォルトでは、全てのNamespace間通信が許可されています。セキュリティを強化するには、NetworkPolicyを使用します。

```yaml
# prod-network-policy.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-from-other-namespaces
  namespace: prod
spec:
  podSelector: {}  # 全てのPodに適用
  policyTypes:
  - Ingress
  ingress:
  - from:
    # 同じNamespace内からのみ許可
    - podSelector: {}
```

```bash
kubectl apply -f prod-network-policy.yaml

# これでdev Namespaceからprodへのアクセスがブロックされる
kubectl run test-pod --image=alpine --rm -it -n dev -- sh
/ # wget -O- http://nginx.prod.svc.cluster.local
# タイムアウト（通信がブロックされる）
```

**特定のNamespaceからのみ許可する例：**

```yaml
# allow-from-staging.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-from-staging
  namespace: prod
spec:
  podSelector:
    matchLabels:
      app: backend
  policyTypes:
  - Ingress
  ingress:
  - from:
    # stagingからのアクセスのみ許可
    - namespaceSelector:
        matchLabels:
          environment: staging
    ports:
    - protocol: TCP
      port: 8080
```

## 実践的な運用 - kubectlのコンテキスト管理

### コンテキストとは

コンテキストは、クラスタ、ユーザー、Namespaceの組み合わせです。複数の環境を効率的に管理できます。

```bash
# 現在のコンテキスト確認
kubectl config current-context

# 全コンテキストの一覧
kubectl config get-contexts

# 出力例:
# CURRENT   NAME              CLUSTER      AUTHINFO     NAMESPACE
# *         minikube          minikube     minikube     default
#           prod-cluster      prod         prod-user    prod
#           staging-cluster   staging      staging-user staging
```

### 環境別コンテキストの作成

```bash
# dev環境用コンテキスト
kubectl config set-context dev \
  --cluster=minikube \
  --user=minikube \
  --namespace=dev

# staging環境用コンテキスト
kubectl config set-context staging \
  --cluster=minikube \
  --user=minikube \
  --namespace=staging

# prod環境用コンテキスト
kubectl config set-context prod \
  --cluster=minikube \
  --user=minikube \
  --namespace=prod

# コンテキストの切り替え
kubectl config use-context dev
kubectl get pods  # devのPodが表示される

kubectl config use-context prod
kubectl get pods  # prodのPodが表示される
```

### kubectxとkubensツール

環境切り替えをより簡単にするツールです。

```bash
# インストール（macOS）
brew install kubectx

# インストール（Linux）
sudo git clone https://github.com/ahmetb/kubectx /opt/kubectx
sudo ln -s /opt/kubectx/kubectx /usr/local/bin/kubectx
sudo ln -s /opt/kubectx/kubens /usr/local/bin/kubens

# 使用例
kubectx  # コンテキスト一覧表示
kubectx dev  # devコンテキストに切り替え

kubens  # Namespace一覧表示
kubens prod  # prodに切り替え
```

### エイリアスとシェル設定

```bash
# ~/.bashrc または ~/.zshrc に追加

# kubectlのエイリアス
alias k=kubectl
alias kgp='kubectl get pods'
alias kgs='kubectl get services'
alias kgd='kubectl get deployments'
alias kd='kubectl describe'
alias kl='kubectl logs'
alias ke='kubectl exec -it'

# Namespace切り替えエイリアス
alias kdev='kubectl config set-context --current --namespace=dev'
alias kstg='kubectl config set-context --current --namespace=staging'
alias kprd='kubectl config set-context --current --namespace=prod'

# プロンプトに現在のNamespaceを表示（zsh + oh-my-zsh）
# PROMPT="${PROMPT}[$(kubectl config view --minify --output 'jsonpath={..namespace}')]$ "
```

### 実践的な運用フロー

```bash
# 1. 開発環境で作業
kdev  # dev namespaceに切り替え
kubectl apply -f app.yaml
kubectl get pods
kubectl logs -f my-app-xxx

# 2. 検証環境にデプロイ
kstg  # staging namespaceに切り替え
kubectl apply -f app.yaml
kubectl get pods
# テスト実施...

# 3. 本番環境にデプロイ（慎重に）
kprd  # prod namespaceに切り替え
kubectl apply -f app.yaml --dry-run=client  # まずdry-run
kubectl apply -f app.yaml  # 実際のデプロイ
kubectl rollout status deployment/my-app  # デプロイ状況監視
```

### Namespace削除時の注意

```bash
# Namespace削除（危険！）
kubectl delete namespace dev

# Namespace内の全リソースが削除される
# - Pods
# - Deployments
# - Services
# - ConfigMaps
# - Secrets
# など全て

# 削除前に必ず確認
kubectl get all -n dev
kubectl get pvc -n dev
kubectl get secrets -n dev

# 安全な削除手順
# 1. アプリケーションをスケールダウン
kubectl scale deployment --all --replicas=0 -n dev

# 2. 個別にリソース削除
kubectl delete deployment --all -n dev
kubectl delete service --all -n dev

# 3. 最後にNamespace削除
kubectl delete namespace dev
```

## まとめと次回予告

### 本記事のまとめ

第9回では、Kubernetesの**Namespace**を使った環境分離について学びました：

**学んだこと：**

1. **Namespaceの基本概念**
   - 論理的なリソース分離の仕組み
   - マルチテナント、環境分離での活用

2. **環境別Namespace設計**
   - dev/staging/prod構成
   - 環境ごとの異なるリソース設定

3. **ResourceQuotaによるリソース管理**
   - Namespace単位での上限設定
   - クラスタリソースの公平な分配

4. **LimitRangeによるデフォルト値制御**
   - Pod/Container単位の制限
   - リソース指定忘れの防止

5. **Namespace間通信**
   - DNSベースの名前解決
   - NetworkPolicyによる通信制御

6. **実践的な運用テクニック**
   - kubectlコンテキスト管理
   - 効率的な環境切り替え

**重要なポイント：**

- **Namespaceは論理的な分離**であり、完全な物理的分離ではない
- **ResourceQuotaとLimitRangeは必ずセット**で設定する
- **本番環境は慎重に**、NetworkPolicyで適切に保護
- **コンテキスト管理で作業効率**を大幅に向上

### 次回予告：第10回「Ingressで外部公開を管理する」

次回の第10回では、**Ingress**について学びます。これまでServiceを使ってクラスタ内通信や簡易的な外部公開を行ってきましたが、Ingressを使うことで、より高度で実用的な外部公開が可能になります。

**次回の内容：**

- Ingressの概念とServiceとの違い
- Ingress ControllerのセットアップとNGINX Ingress
- パスベースルーティングとホストベースルーティング
- TLS/SSL証明書の設定（HTTPS化）
- 認証・認可とBasic認証の実装
- レート制限とアクセス制御
- 複数環境でのIngress運用パターン

本番環境でWebアプリケーションを公開する際に必須の知識となります。ぜひ次回もご期待ください！

## 参考リンク

- Kubernetes公式ドキュメント - Namespaces: https://kubernetes.io/docs/concepts/overview/working-with-objects/namespaces/
- Kubernetes公式ドキュメント - Resource Quotas: https://kubernetes.io/docs/concepts/policy/resource-quotas/
- Kubernetes公式ドキュメント - Limit Ranges: https://kubernetes.io/docs/concepts/policy/limit-range/
- Kubernetes公式ドキュメント - Network Policies: https://kubernetes.io/docs/concepts/services-networking/network-policies/
