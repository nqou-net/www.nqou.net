---
title: "Kubernetesを完全に理解した（第16回）- RBACでアクセス制御"
draft: true
tags:
- kubernetes
- rbac
- security
- access-control
- authorization
description: "適切な権限管理でクラスタを守る方法。チームメンバーやアプリケーションに必要最小限の権限だけを付与する実践を学びます。"
---

## はじめに - 第15回の振り返りと第16回で学ぶこと

前回の第15回では、バックアップとDR（災害復旧）について学びました。etcdバックアップの重要性、Veleroによるアプリケーションバックアップ、そして万が一の障害に備えた復旧計画の構築方法を理解できました。

今回の第16回からは、Kubernetesのセキュリティに焦点を当てた実践編が始まります。まずは **RBAC（Role-Based Access Control）によるアクセス制御** について学びます。適切な権限管理は、クラスタのセキュリティを守る最も基本的かつ重要な要素です。

本記事で学ぶ内容：

- RBACの基本概念と4つの主要リソース
- RoleとClusterRoleの違いと使い分け
- ServiceAccountを使ったPodへの権限付与
- 最小権限の原則（Principle of Least Privilege）
- 権限のテストと検証方法
- 監査ログによる不正アクセス検知

## RBACの基本概念

### RBACとは

**RBAC（Role-Based Access Control）** は、「誰が」「何を」できるかを制御する仕組みです。Kubernetesでは、以下の4つのリソースで構成されます：

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

### RoleとClusterRoleの違い

| 種類 | スコープ | 用途 |
|-----|---------|------|
| Role | Namespace単位 | 特定Namespaceのリソース制御 |
| ClusterRole | クラスタ全体 | Namespace非依存リソース、全Namespaceアクセス |

**重要**: Nodeや PersistentVolumeなどのNamespace非依存リソースは、ClusterRoleでのみ制御できます。

## RoleとRoleBindingの実装

### 基本的なRole定義

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

主要な **verbs**（動詞）：
- `get`: 個別リソースの取得
- `list`: リソース一覧の取得
- `watch`: リソースの変更監視
- `create`: リソースの作成
- `update`: リソースの更新
- `patch`: リソースの部分更新
- `delete`: リソースの削除
- `deletecollection`: 複数リソースの一括削除

### より実践的なRole定義

開発者向けの権限を定義してみましょう：

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

# Serviceは読み取りのみ
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

### RoleBindingの作成

Roleを実際のユーザーやServiceAccountに紐付けます：

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

適用と確認：

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

## ServiceAccountの活用

### ServiceAccountの作成と使用

PodにKubernetes APIへのアクセス権限を付与するには、ServiceAccountを使います：

```yaml
# app-serviceaccount.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: app-sa
  namespace: production
automountServiceAccountToken: true
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

### PodでServiceAccountを使用

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
```

### Pod内からKubernetes APIにアクセス

Pod内でServiceAccountのトークンを使ってKubernetes APIにアクセスできます：

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
# 成功！

# Podの一覧取得（app-roleで許可されていない）
curl --cacert $CACERT \
     -H "Authorization: Bearer $TOKEN" \
     https://kubernetes.default.svc/api/v1/namespaces/production/pods
# エラー: Forbidden
```

## 最小権限の原則

セキュリティのベストプラクティスとして、**最小権限の原則（Principle of Least Privilege）** に従い、必要最小限の権限のみを付与します。

### 権限の段階的付与

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

### 組み込みClusterRoleの活用

Kubernetesには便利な組み込みClusterRoleがあります：

```bash
# 組み込みClusterRoleの確認
kubectl get clusterrole | grep -E "^(view|edit|admin|cluster-admin)"
# admin                 2024-01-01T00:00:00Z
# cluster-admin         2024-01-01T00:00:00Z
# edit                  2024-01-01T00:00:00Z
# view                  2024-01-01T00:00:00Z
```

| ClusterRole | 権限レベル | 用途 |
|------------|----------|------|
| `view` | 読み取り専用 | モニタリング、確認作業 |
| `edit` | ほぼ全ての編集 | 開発者（Secretを除く） |
| `admin` | Namespace内の全権限 | Namespace管理者 |
| `cluster-admin` | クラスタ全体の全権限 | クラスタ管理者のみ |

### CI/CD用の最小権限ServiceAccount

```yaml
# ci-cd-serviceaccount.yaml
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

# ConfigMapの更新（特定のもののみ）
- apiGroups: [""]
  resources: ["configmaps"]
  resourceNames: ["app-config"]
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

## 権限のテストと検証

### kubectl auth can-i

自分の権限を確認する便利なコマンド：

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

### impersonation（なりすまし）でテスト

実際に権限をテストできます：

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

## 監査ログ

### 監査ログの有効化

重要な操作を記録するための監査ポリシー：

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

# その他のリソースはメタデータのみ記録
- level: Metadata
  resources:
  - group: ""
  - group: "apps"
  - group: "batch"
```

監査ログレベル：
- `None`: ログを記録しない
- `Metadata`: リクエストメタデータのみ（ユーザー、タイムスタンプ、リソース）
- `Request`: メタデータとリクエストボディ
- `RequestResponse`: メタデータ、リクエスト、レスポンスボディ

### 監査ログの確認

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
```

## まとめ

### 今回（第16回）学んだこと

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

### 次回予告

次回の第17回では、**NetworkPolicyによるネットワーク隔離** について学びます。ネットワークレベルでのセキュリティを強化し、Pod間の通信を細かく制御する方法を実践します。マイクロセグメンテーションによるゼロトラストネットワークの実現を目指しましょう！
