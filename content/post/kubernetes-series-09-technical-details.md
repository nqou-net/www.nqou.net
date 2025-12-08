# 第9回「Namespaceによる環境分離」技術詳細

## 主要な概念と仕組み

### Namespaceとは
Namespaceは、Kubernetesクラスタ内に**仮想的なクラスタ境界**を作成する論理的な分離機構です。単一の物理クラスタを複数の仮想クラスタに分割し、リソースの隔離、アクセス制御、リソースクォータの適用を実現します。

### Namespaceの特徴

1. **リソーススコープの分離**
   - Pod、Service、ConfigMap、Secretなどのリソースは特定のNamespaceに属する
   - 同じ名前のリソースを異なるNamespaceに作成可能（例: dev/app-1とprod/app-1）
   - Namespace間のリソースは基本的に独立

2. **アクセス制御の境界**
   - RBACでNamespace単位の権限制御が可能
   - 特定のNamespaceにのみアクセス可能なユーザー/サービスアカウントを作成
   - マルチテナント環境での隔離

3. **リソースクォータとリミット**
   - Namespace単位でCPU/メモリ/ストレージの使用量を制限
   - Pod数、Service数などのオブジェクト数制限
   - リソース枯渇の防止

### 内部動作の詳細

Namespaceは以下のレイヤーで機能します：

1. **APIサーバーレベル**
   - 全てのリソース作成時にNamespace情報が付加される
   - デフォルトでは`default` Namespaceが使用される
   - システムコンポーネントは`kube-system`、パブリック情報は`kube-public`

2. **DNSレベル**
   - Service名の完全修飾ドメイン名（FQDN）: `{service}.{namespace}.svc.cluster.local`
   - 同一Namespace内では短縮名でアクセス可能（`http://api-service`）
   - 異なるNamespaceへは完全名が必要（`http://api-service.production.svc.cluster.local`）

3. **ネットワークポリシーレベル**
   - NetworkPolicyでNamespace間通信を制御
   - デフォルトでは全Namespace間通信が許可
   - 明示的な拒否ルールで隔離強化

### Namespace対象外のリソース

以下はクラスタスコープのリソース（Namespaceに属さない）：
- Node
- PersistentVolume（PVCはNamespaceスコープ）
- StorageClass
- ClusterRole / ClusterRoleBinding
- Namespace自体

```bash
# Namespaceスコープのリソース一覧
kubectl api-resources --namespaced=true

# クラスタスコープのリソース一覧
kubectl api-resources --namespaced=false
```

## 実践的なYAMLマニフェスト例

### 基本的なNamespace作成

```yaml
apiVersion: v1
kind: Namespace
metadata:
  name: production
  labels:
    environment: production
    team: platform
  annotations:
    description: "Production environment for all services"
```

### 環境別Namespace構成（開発・ステージング・本番）

```yaml
---
apiVersion: v1
kind: Namespace
metadata:
  name: development
  labels:
    environment: dev
    cost-center: engineering
---
apiVersion: v1
kind: Namespace
metadata:
  name: staging
  labels:
    environment: staging
    cost-center: engineering
---
apiVersion: v1
kind: Namespace
metadata:
  name: production
  labels:
    environment: prod
    cost-center: operations
    compliance: pci-dss
```

### ResourceQuotaの設定

```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: compute-quota
  namespace: development
spec:
  hard:
    # CPU/メモリ制限
    requests.cpu: "10"          # 合計10コアまでリクエスト可能
    requests.memory: 20Gi       # 合計20GBまでリクエスト可能
    limits.cpu: "20"            # 合計20コアまで上限設定可能
    limits.memory: 40Gi         # 合計40GBまで上限設定可能
    
    # オブジェクト数制限
    pods: "50"                  # 最大50 Pod
    services: "20"              # 最大20 Service
    persistentvolumeclaims: "10" # 最大10 PVC
    
    # ストレージ制限
    requests.storage: 100Gi     # 合計100GBまで
    
    # 特定StorageClassの制限
    fast-ssd.storageclass.storage.k8s.io/requests.storage: 50Gi
---
apiVersion: v1
kind: ResourceQuota
metadata:
  name: object-quota
  namespace: development
spec:
  hard:
    configmaps: "20"
    secrets: "20"
    services.loadbalancers: "2"
    services.nodeports: "5"
```

### LimitRangeの設定（デフォルト値と制限）

```yaml
apiVersion: v1
kind: LimitRange
metadata:
  name: resource-limits
  namespace: development
spec:
  limits:
  # Podレベルの制限
  - type: Pod
    max:
      cpu: "4"
      memory: 8Gi
    min:
      cpu: 100m
      memory: 128Mi
  
  # Containerレベルの制限
  - type: Container
    max:
      cpu: "2"
      memory: 4Gi
    min:
      cpu: 50m
      memory: 64Mi
    default:  # limits未指定時のデフォルト
      cpu: 500m
      memory: 512Mi
    defaultRequest:  # requests未指定時のデフォルト
      cpu: 200m
      memory: 256Mi
    maxLimitRequestRatio:  # limit/requestの最大比率
      cpu: "4"
      memory: "3"
  
  # PVCレベルの制限
  - type: PersistentVolumeClaim
    max:
      storage: 50Gi
    min:
      storage: 1Gi
```

### チーム別Namespace（マルチテナント）

```yaml
---
apiVersion: v1
kind: Namespace
metadata:
  name: team-alpha
  labels:
    team: alpha
    department: engineering
---
apiVersion: v1
kind: Namespace
metadata:
  name: team-beta
  labels:
    team: beta
    department: data-science
---
# Team Alphaのリソースクォータ
apiVersion: v1
kind: ResourceQuota
metadata:
  name: team-alpha-quota
  namespace: team-alpha
spec:
  hard:
    requests.cpu: "50"
    requests.memory: 100Gi
    limits.cpu: "100"
    limits.memory: 200Gi
---
# Team Alphaのネットワークポリシー（隔離）
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-other-teams
  namespace: team-alpha
spec:
  podSelector: {}  # 全Podに適用
  policyTypes:
  - Ingress
  - Egress
  ingress:
  # 同じNamespace内からのみ許可
  - from:
    - namespaceSelector:
        matchLabels:
          team: alpha
  egress:
  # DNSへのアクセス許可
  - to:
    - namespaceSelector:
        matchLabels:
          name: kube-system
    ports:
    - protocol: UDP
      port: 53
  # 同じチーム内への通信許可
  - to:
    - namespaceSelector:
        matchLabels:
          team: alpha
```

### アプリケーション環境完全構成例

```yaml
---
# Namespace作成
apiVersion: v1
kind: Namespace
metadata:
  name: ecommerce-prod
  labels:
    app: ecommerce
    environment: production
---
# ResourceQuota
apiVersion: v1
kind: ResourceQuota
metadata:
  name: prod-quota
  namespace: ecommerce-prod
spec:
  hard:
    requests.cpu: "100"
    requests.memory: 200Gi
    limits.cpu: "200"
    limits.memory: 400Gi
    pods: "100"
---
# LimitRange
apiVersion: v1
kind: LimitRange
metadata:
  name: prod-limits
  namespace: ecommerce-prod
spec:
  limits:
  - type: Container
    default:
      cpu: 500m
      memory: 512Mi
    defaultRequest:
      cpu: 200m
      memory: 256Mi
---
# NetworkPolicy（外部通信制御）
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-ingress-only
  namespace: ecommerce-prod
spec:
  podSelector:
    matchLabels:
      tier: frontend
  policyTypes:
  - Ingress
  ingress:
  - from:
    - namespaceSelector:
        matchLabels:
          name: ingress-nginx
---
# ServiceAccount（専用権限）
apiVersion: v1
kind: ServiceAccount
metadata:
  name: ecommerce-app
  namespace: ecommerce-prod
---
# Role（Namespace内権限）
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: ecommerce-app-role
  namespace: ecommerce-prod
rules:
- apiGroups: [""]
  resources: ["configmaps", "secrets"]
  verbs: ["get", "list"]
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list", "watch"]
---
# RoleBinding
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: ecommerce-app-binding
  namespace: ecommerce-prod
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: ecommerce-app-role
subjects:
- kind: ServiceAccount
  name: ecommerce-app
  namespace: ecommerce-prod
```

## kubectlコマンド例

### Namespace基本操作

```bash
# Namespace作成
kubectl create namespace development
kubectl create ns dev  # 短縮形

# YAMLから作成
kubectl apply -f namespace.yaml

# Namespace一覧
kubectl get namespaces
kubectl get ns

# 詳細表示
kubectl describe namespace production

# Namespace削除（配下の全リソースも削除される）
kubectl delete namespace staging

# 強制削除（終了処理待たずに削除）
kubectl delete namespace old-env --force --grace-period=0
```

### Namespace内リソース操作

```bash
# 特定Namespaceのリソース表示
kubectl get pods -n production
kubectl get all -n production

# デフォルトNamespaceの変更
kubectl config set-context --current --namespace=production

# 現在のNamespace確認
kubectl config view --minify | grep namespace:

# 全Namespace横断検索
kubectl get pods --all-namespaces
kubectl get pods -A  # 短縮形

# 特定ラベルを持つNamespace内のリソース
kubectl get pods -n production -l app=api

# Namespace指定でリソース作成
kubectl run nginx --image=nginx -n development

# YAMLに明示的にNamespace指定
kubectl apply -f deployment.yaml -n production
```

### Namespaceコンテキスト管理

```bash
# コンテキスト一覧
kubectl config get-contexts

# 新しいコンテキスト作成（Namespace指定）
kubectl config set-context dev-context \
  --cluster=my-cluster \
  --user=developer \
  --namespace=development

# コンテキスト切り替え
kubectl config use-context dev-context

# 現在のコンテキスト確認
kubectl config current-context

# コンテキスト情報詳細
kubectl config view --minify

# kubens使用（便利ツール）
# インストール: brew install kubectx
kubens                    # Namespace一覧
kubens production         # 切り替え
kubens -                  # 前のNamespaceに戻る
```

### ResourceQuota確認

```bash
# ResourceQuota一覧
kubectl get resourcequota -n development
kubectl get quota -n development  # 短縮形

# 詳細表示（使用量/制限値）
kubectl describe resourcequota compute-quota -n development

# 全Namespaceのクォータ確認
kubectl get resourcequota --all-namespaces

# 使用状況をJSON形式で取得
kubectl get resourcequota -n development -o json

# 使用率計算スクリプト
kubectl get resourcequota compute-quota -n development -o json | \
  jq '.status.used, .status.hard'
```

### LimitRange確認

```bash
# LimitRange一覧
kubectl get limitrange -n development

# 詳細表示
kubectl describe limitrange resource-limits -n development

# 全Namespaceで確認
kubectl get limitrange --all-namespaces
```

### リソース使用量監視

```bash
# Namespace別リソース使用量
kubectl top pods -n production
kubectl top nodes

# 全Namespaceの合計
kubectl top pods --all-namespaces

# Namespace別集計（カスタムスクリプト）
for ns in $(kubectl get ns -o jsonpath='{.items[*].metadata.name}'); do
  echo "Namespace: $ns"
  kubectl top pods -n $ns --no-headers | \
    awk '{cpu+=$2; mem+=$3} END {print "Total CPU:", cpu, "Total Memory:", mem}'
done

# リソース使用率ソート
kubectl top pods -n production --sort-by=memory
kubectl top pods -n production --sort-by=cpu
```

### Namespace間リソースコピー

```bash
# ConfigMapコピー
kubectl get configmap app-config -n development -o yaml | \
  sed 's/namespace: development/namespace: staging/' | \
  kubectl apply -f -

# Secretコピー
kubectl get secret db-credentials -n development -o yaml | \
  sed 's/namespace: development/namespace: production/' | \
  kubectl apply -f -

# 複数リソース一括コピー
kubectl get deploy,svc,configmap -n development -o yaml | \
  sed 's/namespace: development/namespace: staging/' | \
  kubectl apply -f -
```

### デバッグとトラブルシューティング

```bash
# Namespace削除が終わらない場合の確認
kubectl get namespace stuck-namespace -o json | \
  jq '.status'

# Finalizerを削除して強制削除
kubectl get namespace stuck-namespace -o json | \
  jq '.spec.finalizers = []' | \
  kubectl replace --raw /api/v1/namespaces/stuck-namespace/finalize -f -

# Namespace内のリソース完全削除確認
kubectl api-resources --verbs=list --namespaced -o name | \
  xargs -n 1 kubectl get --show-kind --ignore-not-found -n old-namespace

# クォータ超過エラーの確認
kubectl describe resourcequota -n development

# イベント確認
kubectl get events -n production --sort-by='.lastTimestamp'
```

## 初心者がつまづきやすいポイント

### 1. デフォルトNamespaceの混乱

**問題**: `-n` オプションを忘れて意図しないNamespaceにデプロイしてしまう

**原因**: 
- Namespace指定がない場合、デフォルトで`default` Namespaceが使用される
- 環境変数やコンテキストの設定を忘れている

**解決策**:
```bash
# 常にNamespaceを明示
kubectl apply -f app.yaml -n production

# デフォルトNamespaceを変更
kubectl config set-context --current --namespace=production

# YAMLファイルに明記
metadata:
  name: my-app
  namespace: production

# シェルエイリアス設定
alias kp='kubectl -n production'
alias kd='kubectl -n development'

# プロンプトに現在のNamespace表示（kube-ps1使用）
# ~/.bashrc or ~/.zshrc
source "/usr/local/opt/kube-ps1/share/kube-ps1.sh"
PS1='[\u@\h \W $(kube_ps1)]\$ '
```

### 2. Namespace削除時の注意点

**問題**: Namespace削除で全リソースが消えてしまった

**原因**: 
- Namespaceを削除すると配下の全リソースも自動削除される
- PersistentVolumeは残るがPVCは削除される（データアクセス不可）

**安全な手順**:
```bash
# 削除前に内容確認
kubectl get all -n old-namespace

# バックアップ（全リソースエクスポート）
kubectl get all -n old-namespace -o yaml > backup-old-namespace.yaml

# 重要データのバックアップ
kubectl get pvc -n old-namespace
kubectl exec -n old-namespace db-pod -- mysqldump -u root > db-backup.sql

# 削除実行
kubectl delete namespace old-namespace

# Namespace削除がハングした場合（Finalizerが原因）
kubectl patch namespace old-namespace -p '{"metadata":{"finalizers":[]}}' --type=merge
```

### 3. DNS名前解決の誤解

**問題**: 他のNamespaceのServiceにアクセスできない

**原因**: 
- 同一Namespace内では短縮名（`http://api-service`）でアクセス可能
- 異なるNamespaceには完全修飾ドメイン名（FQDN）が必要

**正しいアクセス方法**:
```bash
# 同じNamespace内
curl http://api-service:8080

# 異なるNamespace（FQDNを使用）
curl http://api-service.production.svc.cluster.local:8080

# パターン: {service-name}.{namespace}.svc.cluster.local
```

```yaml
# Deployment内での環境変数設定例
env:
- name: API_ENDPOINT
  value: "http://api-service.production.svc.cluster.local:8080"
```

**DNS確認方法**:
```bash
# テストPod起動
kubectl run -it --rm debug --image=busybox --restart=Never -- sh

# コンテナ内でDNS確認
nslookup api-service  # 同じNamespace内
nslookup api-service.production  # 短縮形
nslookup api-service.production.svc.cluster.local  # 完全形

# A/AAAAレコード確認
dig api-service.production.svc.cluster.local
```

### 4. ResourceQuota超過エラー

**問題**: Podが起動しない、`exceeded quota` エラーが出る

**原因**: 
- Namespace全体でCPU/メモリの使用量が上限に達している
- オブジェクト数制限に達している
- リソースrequests/limitsが未設定

**診断と解決**:
```bash
# クォータ確認
kubectl describe resourcequota -n development

# 出力例:
# Name:       compute-quota
# Resource    Used   Hard
# --------    ----   ----
# limits.cpu     15     20   ← あと5コア余裕
# limits.memory  30Gi   40Gi
# pods           48     50   ← あと2 Pod
# requests.cpu   9      10   ← 残り1コアしかない！

# 現在の使用量確認
kubectl top pods -n development

# リソース未設定のPod検出
kubectl get pods -n development -o json | \
  jq '.items[] | select(.spec.containers[].resources.requests.cpu == null) | .metadata.name'

# リソース設定を追加
kubectl set resources deployment/app -n development \
  --requests=cpu=200m,memory=256Mi \
  --limits=cpu=500m,memory=512Mi

# または一時的にクォータを増やす
kubectl patch resourcequota compute-quota -n development \
  -p '{"spec":{"hard":{"requests.cpu":"15"}}}'
```

### 5. LimitRangeのデフォルト値適用

**問題**: リソース指定してないのにlimitsが勝手に設定されている

**原因**: 
- LimitRangeでデフォルト値が設定されている
- 既存のPodには適用されず、新規Pod作成時のみ適用

**確認と制御**:
```bash
# LimitRange確認
kubectl describe limitrange -n development

# 既存Podのリソース確認
kubectl get pod my-app -n development -o yaml | grep -A5 resources:

# LimitRangeを一時的に削除して再作成
kubectl delete limitrange resource-limits -n development
kubectl run test-pod --image=nginx -n development
kubectl get pod test-pod -n development -o yaml | grep -A5 resources:
# → デフォルト値が適用されない

# LimitRangeを再適用
kubectl apply -f limitrange.yaml
```

### 6. ネットワークポリシーによる予期せぬ通信遮断

**問題**: NetworkPolicy追加後にアプリケーション間通信ができなくなった

**原因**: 
- NetworkPolicyは**ホワイトリスト方式**（明示的に許可したもの以外は拒否）
- DNSへのアクセスを許可し忘れている

**デバッグと修正**:
```bash
# NetworkPolicy確認
kubectl get networkpolicy -n production

# 詳細確認
kubectl describe networkpolicy deny-all -n production

# ポリシー削除してテスト
kubectl delete networkpolicy deny-all -n production
# → 通信が復旧すればNetworkPolicyが原因

# DNSアクセス許可（必須）
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-dns
  namespace: production
spec:
  podSelector: {}
  policyTypes:
  - Egress
  egress:
  - to:
    - namespaceSelector:
        matchLabels:
          name: kube-system
    ports:
    - protocol: UDP
      port: 53

# 通信テスト
kubectl run -it --rm debug -n production --image=busybox -- sh
# コンテナ内で
wget -O- http://api-service:8080  # 成功するか確認
```

### 7. RBAC権限不足

**問題**: 特定のNamespaceにしかアクセスできない

**原因**: 
- RoleBindingはNamespaceスコープ
- 複数NamespaceにアクセスするにはそれぞれにRoleBindingが必要

**確認と設定**:
```bash
# 自分の権限確認
kubectl auth can-i get pods -n production
kubectl auth can-i create deployments -n development

# 全アクション確認
kubectl auth can-i --list -n production

# ServiceAccountの権限確認
kubectl auth can-i get pods \
  --as=system:serviceaccount:production:app-sa \
  -n production

# 複数Namespaceへのアクセス許可（ClusterRole使用）
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: multi-namespace-reader
rules:
- apiGroups: [""]
  resources: ["pods", "services"]
  verbs: ["get", "list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: dev-reader
  namespace: development
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: multi-namespace-reader
subjects:
- kind: User
  name: developer
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: prod-reader
  namespace: production
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: multi-namespace-reader
subjects:
- kind: User
  name: developer
```

### 8. Namespace分離の過信

**問題**: Namespace分けたから完全に隔離されていると思っていた

**現実**: 
- デフォルトではNamespace間のネットワーク通信は**制限されない**
- NetworkPolicyを明示的に設定する必要がある
- ノードリソースは共有される（完全隔離ではない）

**適切な隔離戦略**:
```yaml
# Namespace間通信を完全遮断
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: deny-other-namespaces
  namespace: production
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - podSelector: {}  # 同じNamespace内のみ許可
  egress:
  - to:
    - podSelector: {}
```

```bash
# 真の隔離が必要な場合
# 1. 別々のクラスタを使用
# 2. ノードプール分離（GKE/AKS/EKS）
# 3. Taints/Tolerationsでノード分離
kubectl taint nodes node-prod env=production:NoSchedule
```

これらのポイントを理解することで、Namespaceを活用した効果的な環境分離とリソース管理が可能になります！
