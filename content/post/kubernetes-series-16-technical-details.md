---
title: "RBACで実現するアクセス制御 - Kubernetesのセキュリティ基盤（技術詳細）"
draft: true
tags:
- kubernetes
- rbac
- security
- access-control
- serviceaccount
- authorization
description: "Kubernetes RBACの完全ガイド。Role、RoleBinding、ServiceAccountの関係から最小権限の原則、監査ログまで実践的に解説。"
---

## はじめに

Kubernetes環境において、適切なアクセス制御は最も重要なセキュリティ対策の一つです。RBAC（Role-Based Access Control）を正しく実装することで、誰が何をできるかを細かく制御し、セキュリティインシデントのリスクを大幅に削減できます。本記事では、RBACの仕組みから実践的な設定、監査ログまで徹底解説します。

## 1. RBACの基本概念

### 1.1 RBACとは

**RBAC**: 役割ベースのアクセス制御（Role-Based Access Control）

```
┌──────────────────────────────────────────┐
│         RBAC の4つの主要リソース          │
├──────────────────────────────────────────┤
│ 1. Role / ClusterRole                    │
│    → 何ができるか（権限の定義）           │
│                                          │
│ 2. RoleBinding / ClusterRoleBinding      │
│    → 誰にその権限を与えるか（紐付け）     │
│                                          │
│ 3. ServiceAccount                        │
│    → Podが使うアカウント                 │
│                                          │
│ 4. User / Group                          │
│    → 人間が使うアカウント                │
└──────────────────────────────────────────┘
```

### 1.2 RoleとClusterRoleの違い

```yaml
# Role: Namespace単位の権限
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: production  # このNamespaceのみ有効
  name: pod-reader

---
# ClusterRole: クラスタ全体の権限
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: node-reader  # 全Namespaceで有効
```

| 種類 | スコープ | 用途 |
|-----|---------|------|
| Role | Namespace単位 | 特定Namespaceのリソース制御 |
| ClusterRole | クラスタ全体 | Namespace非依存リソース、全Namespaceアクセス |

### 1.3 RBACの動作フロー

```
リクエスト → 認証 → RBAC認可 → Admission Control → 実行
              ↓        ↓
           誰？   何ができる？

1. Authentication（認証）
   - ServiceAccount
   - X.509証明書
   - OIDC Token

2. Authorization（認可）- RBAC
   - RoleBindingで権限チェック
   - 許可されていなければ拒否

3. Admission Control
   - PodSecurityPolicy
   - ResourceQuota
```

## 2. Role と RoleBinding の実装

### 2.1 基本的なRole定義

```yaml
# pod-reader-role.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: production
  name: pod-reader
rules:
- apiGroups: [""]  # "" はコアAPIグループ
  resources: ["pods"]
  verbs: ["get", "list", "watch"]
```

**主要な verbs**:
- `get`: 個別リソースの取得
- `list`: リソース一覧の取得
- `watch`: リソースの変更監視
- `create`: リソースの作成
- `update`: リソースの更新
- `patch`: リソースの部分更新
- `delete`: リソースの削除
- `deletecollection`: 複数リソースの一括削除

### 2.2 より複雑なRole定義

```yaml
# developer-role.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: development
  name: developer
rules:
# Podの全操作を許可
- apiGroups: [""]
  resources: ["pods", "pods/log", "pods/exec"]
  verbs: ["*"]

# Deployment、ReplicaSetの読み取りと更新
- apiGroups: ["apps"]
  resources: ["deployments", "replicasets"]
  verbs: ["get", "list", "watch", "update", "patch"]

# Serviceの作成と削除は許可しない（読み取りのみ）
- apiGroups: [""]
  resources: ["services"]
  verbs: ["get", "list"]

# ConfigMapは読み取りと作成のみ（削除は不可）
- apiGroups: [""]
  resources: ["configmaps"]
  verbs: ["get", "list", "create", "update"]

# Secretへのアクセスは特定の名前のみ
- apiGroups: [""]
  resources: ["secrets"]
  resourceNames: ["app-secret", "db-secret"]
  verbs: ["get"]
```

### 2.3 RoleBinding の作成

```yaml
# developer-rolebinding.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  namespace: development
  name: developer-binding
subjects:
# ユーザーに紐付け
- kind: User
  name: alice@example.com
  apiGroup: rbac.authorization.k8s.io

# グループに紐付け
- kind: Group
  name: developers
  apiGroup: rbac.authorization.k8s.io

# ServiceAccountに紐付け
- kind: ServiceAccount
  name: dev-sa
  namespace: development

roleRef:
  kind: Role
  name: developer
  apiGroup: rbac.authorization.k8s.io
```

```bash
# 適用
kubectl apply -f developer-role.yaml
kubectl apply -f developer-rolebinding.yaml

# 確認
kubectl get role -n development
# NAME        CREATED AT
# developer   2024-12-08T03:00:00Z

kubectl get rolebinding -n development
# NAME                ROLE             AGE
# developer-binding   Role/developer   1m

# 詳細確認
kubectl describe role developer -n development
kubectl describe rolebinding developer-binding -n development
```

## 3. ClusterRole と ClusterRoleBinding

### 3.1 ClusterRoleの定義

```yaml
# node-reader-clusterrole.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: node-reader
rules:
# Nodeの読み取り（Namespace非依存リソース）
- apiGroups: [""]
  resources: ["nodes"]
  verbs: ["get", "list", "watch"]

# PersistentVolumeの読み取り
- apiGroups: [""]
  resources: ["persistentvolumes"]
  verbs: ["get", "list"]

# StorageClassの読み取り
- apiGroups: ["storage.k8s.io"]
  resources: ["storageclasses"]
  verbs: ["get", "list"]
```

### 3.2 全Namespaceアクセス用ClusterRole

```yaml
# cluster-admin-reader.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: cluster-admin-reader
rules:
# 全てのリソースの読み取り権限
- apiGroups: ["*"]
  resources: ["*"]
  verbs: ["get", "list", "watch"]
```

### 3.3 ClusterRoleBindingの作成

```yaml
# sre-clusterrolebinding.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: sre-cluster-admin-reader
subjects:
- kind: Group
  name: sre-team
  apiGroup: rbac.authorization.k8s.io
roleRef:
  kind: ClusterRole
  name: cluster-admin-reader
  apiGroup: rbac.authorization.k8s.io
```

### 3.4 ClusterRoleとRoleBindingの組み合わせ

```yaml
# view-clusterrole は標準で提供されているClusterRole
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: read-pods
  namespace: production
subjects:
- kind: ServiceAccount
  name: monitoring-sa
  namespace: monitoring
roleRef:
  # ClusterRoleを参照
  kind: ClusterRole
  name: view  # 組み込みClusterRole
  apiGroup: rbac.authorization.k8s.io
```

## 4. ServiceAccount の活用

### 4.1 ServiceAccountの作成と使用

```yaml
# app-serviceaccount.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: app-sa
  namespace: production
automountServiceAccountToken: true  # Podに自動マウント
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: production
  name: app-role
rules:
- apiGroups: [""]
  resources: ["configmaps"]
  verbs: ["get", "list"]
- apiGroups: [""]
  resources: ["secrets"]
  resourceNames: ["app-credentials"]
  verbs: ["get"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: app-rolebinding
  namespace: production
subjects:
- kind: ServiceAccount
  name: app-sa
  namespace: production
roleRef:
  kind: Role
  name: app-role
  apiGroup: rbac.authorization.k8s.io
```

### 4.2 PodでServiceAccountを使用

```yaml
# app-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
  namespace: production
spec:
  replicas: 3
  selector:
    matchLabels:
      app: myapp
  template:
    metadata:
      labels:
        app: myapp
    spec:
      serviceAccountName: app-sa  # ServiceAccountを指定
      containers:
      - name: app
        image: myapp:1.0
        env:
        - name: KUBERNETES_SERVICE_HOST
          value: kubernetes.default.svc
```

```bash
# ServiceAccountの確認
kubectl get sa -n production
# NAME      SECRETS   AGE
# app-sa    1         5m
# default   1         30d

# ServiceAccountのSecretを確認
kubectl describe sa app-sa -n production
# Name:                app-sa
# Namespace:           production
# Labels:              <none>
# Annotations:         <none>
# Image pull secrets:  <none>
# Mountable secrets:   app-sa-token-abc12
# Tokens:              app-sa-token-abc12

# TokenのSecretを確認
kubectl get secret app-sa-token-abc12 -n production -o yaml
```

### 4.3 Pod内からKubernetes APIにアクセス

```bash
# Pod内で実行
kubectl exec -it myapp-pod -n production -- /bin/sh

# ServiceAccountのトークンを確認
cat /var/run/secrets/kubernetes.io/serviceaccount/token

# curlでKubernetes APIにアクセス
TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)
CACERT=/var/run/secrets/kubernetes.io/serviceaccount/ca.crt

# ConfigMapの取得（app-roleで許可されている）
curl --cacert $CACERT \
     -H "Authorization: Bearer $TOKEN" \
     https://kubernetes.default.svc/api/v1/namespaces/production/configmaps

# Podの一覧取得（app-roleで許可されていない）
curl --cacert $CACERT \
     -H "Authorization: Bearer $TOKEN" \
     https://kubernetes.default.svc/api/v1/namespaces/production/pods
# エラー: Forbidden
```

## 5. 最小権限の原則（Principle of Least Privilege）

### 5.1 権限の段階的付与

```yaml
# レベル1: 読み取り専用
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: reader
  namespace: production
rules:
- apiGroups: [""]
  resources: ["pods", "services", "configmaps"]
  verbs: ["get", "list", "watch"]

---
# レベル2: アプリケーション管理者
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: app-admin
  namespace: production
rules:
- apiGroups: ["apps"]
  resources: ["deployments", "replicasets"]
  verbs: ["get", "list", "watch", "create", "update", "patch"]
- apiGroups: [""]
  resources: ["pods", "pods/log"]
  verbs: ["get", "list", "watch"]
- apiGroups: [""]
  resources: ["configmaps"]
  verbs: ["get", "list", "create", "update"]

---
# レベル3: Namespace管理者
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: namespace-admin
  namespace: production
rules:
- apiGroups: ["*"]
  resources: ["*"]
  verbs: ["*"]
```

### 5.2 組み込みClusterRoleの活用

```bash
# 組み込みClusterRoleの確認
kubectl get clusterrole | grep -E "^(view|edit|admin|cluster-admin)"
# admin                 2024-01-01T00:00:00Z
# cluster-admin         2024-01-01T00:00:00Z
# edit                  2024-01-01T00:00:00Z
# view                  2024-01-01T00:00:00Z

# viewの詳細確認（読み取り専用）
kubectl describe clusterrole view
# PolicyRule:
#   Resources  Non-Resource URLs  Resource Names  Verbs
#   ---------  -----------------  --------------  -----
#   pods       []                 []              [get list watch]
#   services   []                 []              [get list watch]
#   ...

# editの詳細確認（Secretを除く大半のリソースを編集可能）
kubectl describe clusterrole edit

# adminの詳細確認（Namespace内の全権限、RBACは除く）
kubectl describe clusterrole admin

# cluster-adminの詳細確認（クラスタ全体の全権限）
kubectl describe clusterrole cluster-admin
```

### 5.3 実践的なロール設計例

```yaml
# ci-cd-serviceaccount.yaml
# CI/CDパイプライン用の最小権限ServiceAccount
apiVersion: v1
kind: ServiceAccount
metadata:
  name: ci-cd-deployer
  namespace: production
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: ci-cd-deploy-role
  namespace: production
rules:
# Deploymentの更新のみ
- apiGroups: ["apps"]
  resources: ["deployments"]
  verbs: ["get", "list", "update", "patch"]

# ReplicaSetの読み取り（デプロイ状況確認用）
- apiGroups: ["apps"]
  resources: ["replicasets"]
  verbs: ["get", "list"]

# Podの読み取り（ステータス確認用）
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list"]

# ConfigMapの更新
- apiGroups: [""]
  resources: ["configmaps"]
  resourceNames: ["app-config"]  # 特定のConfigMapのみ
  verbs: ["get", "update"]

# Secretは参照のみ（更新不可）
- apiGroups: [""]
  resources: ["secrets"]
  resourceNames: ["app-credentials"]
  verbs: ["get"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: ci-cd-deploy-binding
  namespace: production
subjects:
- kind: ServiceAccount
  name: ci-cd-deployer
  namespace: production
roleRef:
  kind: Role
  name: ci-cd-deploy-role
  apiGroup: rbac.authorization.k8s.io
```

## 6. 権限のテストと検証

### 6.1 kubectl auth can-i

```bash
# 自分の権限を確認
kubectl auth can-i create deployments -n production
# yes

kubectl auth can-i delete pods -n production
# no

# 全権限を確認
kubectl auth can-i --list -n production
# Resources                                  Non-Resource URLs   Resource Names   Verbs
# pods                                       []                  []               [get list watch]
# deployments.apps                           []                  []               [get list create update]
# ...

# 他ユーザー/ServiceAccountの権限を確認（admin権限が必要）
kubectl auth can-i get pods \
  --as=system:serviceaccount:production:app-sa \
  -n production
# yes

kubectl auth can-i delete deployments \
  --as=alice@example.com \
  -n production
# no
```

### 6.2 impersonation（なりすまし）でテスト

```bash
# ServiceAccountになりすましてテスト
kubectl get pods -n production \
  --as=system:serviceaccount:production:app-sa
# NAME                     READY   STATUS    RESTARTS   AGE
# myapp-5d8f9c7b6d-abc12   1/1     Running   0          10m

# ユーザーになりすましてテスト
kubectl get secrets -n production \
  --as=alice@example.com
# Error from server (Forbidden): secrets is forbidden

# グループになりすましてテスト
kubectl get nodes --as=bob --as-group=developers
```

### 6.3 RBAC診断ツール

```bash
# rbac-lookup（便利なサードパーティツール）のインストール
kubectl krew install rbac-lookup

# 特定Subjectの権限を確認
kubectl rbac-lookup alice@example.com

# 特定Roleを持つSubjectを確認
kubectl rbac-lookup -k role -n production

# ServiceAccountの権限を確認
kubectl rbac-lookup -k serviceaccount -n production
```

## 7. 監査ログ（Audit Log）

### 7.1 監査ログの有効化

```yaml
# audit-policy.yaml
apiVersion: audit.k8s.io/v1
kind: Policy
rules:
# Secretsへのアクセスを全て記録
- level: RequestResponse
  resources:
  - group: ""
    resources: ["secrets"]

# RBACの変更を全て記録
- level: RequestResponse
  verbs: ["create", "update", "patch", "delete"]
  resources:
  - group: "rbac.authorization.k8s.io"
    resources: ["roles", "rolebindings", "clusterroles", "clusterrolebindings"]

# Pod execとportforwardを記録
- level: Request
  resources:
  - group: ""
    resources: ["pods/exec", "pods/portforward"]

# 認証失敗を記録
- level: Metadata
  omitStages:
  - "RequestReceived"

# その他のリソースはメタデータのみ記録
- level: Metadata
  resources:
  - group: ""
  - group: "apps"
  - group: "batch"
```

**監査ログレベル**:
- `None`: ログを記録しない
- `Metadata`: リクエストメタデータのみ（ユーザー、タイムスタンプ、リソース）
- `Request`: メタデータとリクエストボディ
- `RequestResponse`: メタデータ、リクエスト、レスポンスボディ

### 7.2 kube-apiserverの設定

```bash
# kube-apiserver の起動オプションに追加
# /etc/kubernetes/manifests/kube-apiserver.yaml

spec:
  containers:
  - command:
    - kube-apiserver
    - --audit-policy-file=/etc/kubernetes/audit-policy.yaml
    - --audit-log-path=/var/log/kubernetes/audit.log
    - --audit-log-maxage=30        # 30日間保持
    - --audit-log-maxbackup=10     # 10ファイルまで保持
    - --audit-log-maxsize=100      # 100MBでローテート
    volumeMounts:
    - name: audit-policy
      mountPath: /etc/kubernetes/audit-policy.yaml
      readOnly: true
    - name: audit-log
      mountPath: /var/log/kubernetes
  volumes:
  - name: audit-policy
    hostPath:
      path: /etc/kubernetes/audit-policy.yaml
      type: File
  - name: audit-log
    hostPath:
      path: /var/log/kubernetes
      type: DirectoryOrCreate
```

### 7.3 監査ログの確認

```bash
# 監査ログの確認
sudo tail -f /var/log/kubernetes/audit.log

# jqで整形
sudo tail -f /var/log/kubernetes/audit.log | jq .

# Secretsへのアクセスを抽出
sudo cat /var/log/kubernetes/audit.log | \
  jq 'select(.objectRef.resource=="secrets")'

# 特定ユーザーの操作を抽出
sudo cat /var/log/kubernetes/audit.log | \
  jq 'select(.user.username=="alice@example.com")'

# 認証失敗を抽出
sudo cat /var/log/kubernetes/audit.log | \
  jq 'select(.responseStatus.code >= 400)'

# Pod execの実行を抽出
sudo cat /var/log/kubernetes/audit.log | \
  jq 'select(.objectRef.subresource=="exec")'
```

### 7.4 監査ログの例

```json
{
  "kind": "Event",
  "apiVersion": "audit.k8s.io/v1",
  "level": "RequestResponse",
  "auditID": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
  "stage": "ResponseComplete",
  "requestURI": "/api/v1/namespaces/production/secrets/app-credentials",
  "verb": "get",
  "user": {
    "username": "system:serviceaccount:production:app-sa",
    "uid": "12345678-1234-1234-1234-123456789012",
    "groups": [
      "system:serviceaccounts",
      "system:serviceaccounts:production",
      "system:authenticated"
    ]
  },
  "sourceIPs": [
    "10.244.0.5"
  ],
  "userAgent": "kubectl/v1.28.0",
  "objectRef": {
    "resource": "secrets",
    "namespace": "production",
    "name": "app-credentials",
    "apiVersion": "v1"
  },
  "responseStatus": {
    "metadata": {},
    "code": 200
  },
  "requestReceivedTimestamp": "2024-12-08T03:00:00.000000Z",
  "stageTimestamp": "2024-12-08T03:00:00.123456Z"
}
```

### 7.5 監査ログのFluentd転送

```yaml
# fluentd-audit-config.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: fluentd-config
  namespace: kube-system
data:
  fluent.conf: |
    <source>
      @type tail
      path /var/log/kubernetes/audit.log
      pos_file /var/log/kubernetes/audit.log.pos
      tag kubernetes.audit
      <parse>
        @type json
        time_key requestReceivedTimestamp
        time_format %Y-%m-%dT%H:%M:%S.%NZ
      </parse>
    </source>
    
    # 重要度の高いイベントのみフィルタ
    <filter kubernetes.audit>
      @type grep
      <regexp>
        key $.verb
        pattern ^(create|update|patch|delete)$
      </regexp>
    </filter>
    
    # Elasticsearchに転送
    <match kubernetes.audit>
      @type elasticsearch
      host elasticsearch.monitoring.svc
      port 9200
      logstash_format true
      logstash_prefix k8s-audit
    </match>
```

## 8. RBAC運用のベストプラクティス

### 8.1 定期的な権限レビュー

```bash
# 全RoleBindingの確認スクリプト
cat > review-rbac.sh << 'EOF'
#!/bin/bash

echo "=== RoleBindings Review ==="
for ns in $(kubectl get ns -o jsonpath='{.items[*].metadata.name}'); do
  echo ""
  echo "Namespace: $ns"
  kubectl get rolebinding -n $ns -o json | jq -r '
    .items[] | 
    "\(.metadata.name): \(.subjects[]?.name // "N/A") -> \(.roleRef.name)"
  '
done

echo ""
echo "=== ClusterRoleBindings Review ==="
kubectl get clusterrolebinding -o json | jq -r '
  .items[] | 
  "\(.metadata.name): \(.subjects[]?.name // "N/A") -> \(.roleRef.name)"
'
EOF

chmod +x review-rbac.sh
./review-rbac.sh
```

### 8.2 未使用ServiceAccountの検出

```bash
# 使用されていないServiceAccountを検出
cat > find-unused-sa.sh << 'EOF'
#!/bin/bash

for ns in $(kubectl get ns -o jsonpath='{.items[*].metadata.name}'); do
  echo "Checking namespace: $ns"
  
  # Namespace内の全ServiceAccount
  all_sa=$(kubectl get sa -n $ns -o jsonpath='{.items[*].metadata.name}')
  
  # Pod/Deployment/StatefulSet/DaemonSetで使用されているServiceAccount
  used_sa=$(kubectl get pods,deploy,sts,ds -n $ns -o jsonpath='{.items[*].spec.serviceAccountName}' | tr ' ' '\n' | sort -u)
  
  # 未使用を検出
  for sa in $all_sa; do
    if ! echo "$used_sa" | grep -q "^$sa$"; then
      echo "  Unused ServiceAccount: $sa"
    fi
  done
done
EOF

chmod +x find-unused-sa.sh
./find-unused-sa.sh
```

### 8.3 過剰な権限の検出

```yaml
# rbac-police (OPA Policy)
package kubernetes.admission

deny[msg] {
  input.request.kind.kind == "RoleBinding"
  input.request.object.roleRef.name == "cluster-admin"
  msg := "cluster-admin should not be bound at namespace level"
}

deny[msg] {
  input.request.kind.kind == "Role"
  rule := input.request.object.rules[_]
  rule.verbs[_] == "*"
  rule.resources[_] == "*"
  msg := "Wildcard permissions (*) should be avoided"
}
```

## まとめ

### 学んだこと

1. **RBACの基本構造**
   - Role/ClusterRoleで権限定義
   - RoleBinding/ClusterRoleBindingで紐付け
   - ServiceAccountでPodに権限付与

2. **最小権限の原則**
   - 必要最小限の権限のみ付与
   - 組み込みClusterRoleの活用
   - 段階的な権限付与

3. **権限のテストと検証**
   - kubectl auth can-i
   - impersonation
   - RBAC診断ツール

4. **監査ログ**
   - 監査ポリシーの設定
   - ログレベルの選択
   - ログの分析と転送

### ベストプラクティス

- 最小権限の原則を徹底
- ServiceAccountは用途別に作成
- 定期的な権限レビュー実施
- 監査ログで不正アクセス検知
- 組み込みClusterRole（view/edit/admin）の活用
- resourceNamesで特定リソースに限定
- 本番環境ではcluster-adminの使用を最小化

## 参考リンク

- {{< linkcard "https://kubernetes.io/docs/reference/access-authn-authz/rbac/" >}}
- {{< linkcard "https://kubernetes.io/docs/reference/access-authn-authz/authentication/" >}}
- {{< linkcard "https://kubernetes.io/docs/tasks/debug/debug-cluster/audit/" >}}
