---
title: "Deploymentで実現する安全なデプロイ - ローリングアップデート入門（技術詳細）"
draft: true
tags:
- kubernetes
- deployment
- rolling-update
- rollback
- versioning
description: "ダウンタイムゼロでアプリケーションをアップデートするDeploymentの完全ガイド。ローリングアップデート、ロールバック、デプロイ戦略を実践的なコマンド例とともに徹底解説。"
---

## はじめに

本記事では、Kubernetesで最も重要なリソースの一つであるDeploymentを使って、ダウンタイムゼロでアプリケーションをアップデートする方法を学びます。ローリングアップデート、ロールバック、そして様々なデプロイ戦略を、実際のコマンド例とYAMLマニフェストを通じて徹底的に解説します。

## 1. DeploymentとReplicaSetの関係

### 1.1 ReplicaSetの復習と限界

前回の記事で学んだReplicaSetは、指定した数のPodレプリカを維持する責任を持っています。しかし、ReplicaSetには重大な制限があります。

#### ReplicaSetの基本動作

```yaml
# simple-replicaset.yaml
apiVersion: apps/v1
kind: ReplicaSet
metadata:
  name: nginx-replicaset
spec:
  replicas: 3
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
        image: nginx:1.19
        ports:
        - containerPort: 80
```

```bash
# ReplicaSetのデプロイ
kubectl apply -f simple-replicaset.yaml

# Pod確認
kubectl get pods
# 出力例:
# NAME                      READY   STATUS    RESTARTS   AGE
# nginx-replicaset-abc12    1/1     Running   0          10s
# nginx-replicaset-def34    1/1     Running   0          10s
# nginx-replicaset-ghi56    1/1     Running   0          10s
```

#### ReplicaSetでのアップデートの問題

ReplicaSetを直接使ってアプリケーションをアップデートしようとすると、問題が発生します：

```bash
# イメージバージョンを1.19から1.20に更新してみる
kubectl set image rs/nginx-replicaset nginx=nginx:1.20

# 実際のPodを確認
kubectl get pods -o wide
# 出力例:
# NAME                      READY   STATUS    RESTARTS   AGE   IMAGE
# nginx-replicaset-abc12    1/1     Running   0          2m    nginx:1.19
# nginx-replicaset-def34    1/1     Running   0          2m    nginx:1.19
# nginx-replicaset-ghi56    1/1     Running   0          2m    nginx:1.19

# 驚くべきことに、Podは古いイメージ（nginx:1.19）のまま！
```

**なぜこうなるのか？**

ReplicaSetは「指定した数のPodを維持する」ことだけが仕事です。既存のPodが健全に動作している限り、ReplicaSetはそれらを削除しません。

```bash
# Podを手動で削除してみる
kubectl delete pod nginx-replicaset-abc12

# 新しいPodが作成される
kubectl get pods -o wide
# 出力例:
# NAME                      READY   STATUS    RESTARTS   AGE   IMAGE
# nginx-replicaset-xyz89    1/1     Running   0          5s    nginx:1.20  ← 新しいイメージ！
# nginx-replicaset-def34    1/1     Running   0          3m    nginx:1.19  ← 古いまま
# nginx-replicaset-ghi56    1/1     Running   0          3m    nginx:1.19  ← 古いまま

# 全てのPodを更新するには、全て手動で削除する必要がある
# これはダウンタイムが発生し、本番環境では使えない！

# クリーンアップ
kubectl delete rs nginx-replicaset
```

### 1.2 Deploymentの登場 - 宣言的な管理

Deploymentは、ReplicaSetの上位レベルの抽象化を提供し、アプリケーションのデプロイメントとアップデートを宣言的に管理します。

#### Deploymentの階層構造

```
Deployment
  ├─ ReplicaSet (新バージョン) ← Deploymentが管理
  │   ├─ Pod
  │   ├─ Pod
  │   └─ Pod
  └─ ReplicaSet (旧バージョン) ← 履歴として保持（ロールバック用）
      └─ (レプリカ数: 0)
```

#### Deploymentの基本マニフェスト

```yaml
# nginx-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
spec:
  replicas: 3
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
        image: nginx:1.19
        ports:
        - containerPort: 80
```

```bash
# Deploymentのデプロイ
kubectl apply -f nginx-deployment.yaml

# Deployment、ReplicaSet、Podの関係を確認
kubectl get deployments
# 出力例:
# NAME               READY   UP-TO-DATE   AVAILABLE   AGE
# nginx-deployment   3/3     3            3           10s

kubectl get rs
# 出力例:
# NAME                          DESIRED   CURRENT   READY   AGE
# nginx-deployment-56db8d64f7   3         3         3       15s
#                   ^^^^^^^^^^
#                   Pod template hash (自動生成)

kubectl get pods
# 出力例:
# NAME                                READY   STATUS    RESTARTS   AGE
# nginx-deployment-56db8d64f7-abc12   1/1     Running   0          20s
# nginx-deployment-56db8d64f7-def34   1/1     Running   0          20s
# nginx-deployment-56db8d64f7-ghi56   1/1     Running   0          20s
```

### 1.3 なぜReplicaSetを直接使わずDeploymentを使うのか

| 機能 | ReplicaSet単独 | Deployment |
|-----|--------------|------------|
| レプリカ数の維持 | ✅ | ✅ |
| ローリングアップデート | ❌ 手動で全Pod削除が必要 | ✅ 自動 |
| ロールバック | ❌ 不可能 | ✅ 簡単に前のバージョンに戻せる |
| デプロイ履歴管理 | ❌ | ✅ revision履歴を保持 |
| デプロイの一時停止/再開 | ❌ | ✅ |
| 段階的ロールアウト | ❌ | ✅ maxSurge/maxUnavailableで制御 |

**結論**: 本番環境では、常にDeploymentを使うべきです。

### 1.4 宣言的な管理の利点

#### 命令的 vs 宣言的

```bash
# 命令的アプローチ（良くない方法）
kubectl run nginx --image=nginx:1.19 --replicas=3
kubectl set image deployment/nginx nginx=nginx:1.20
kubectl scale deployment/nginx --replicas=5
# 問題点: 現在の状態が不明確、再現性がない、バージョン管理できない

# 宣言的アプローチ（推奨）
# nginx-deployment.yaml に望ましい状態を記述
kubectl apply -f nginx-deployment.yaml
# 利点: 現在の状態が明確、Git管理可能、再現性がある
```

#### Gitによるバージョン管理

```bash
# Deploymentマニフェストをリポジトリで管理
git add nginx-deployment.yaml
git commit -m "Update nginx to version 1.20, scale to 5 replicas"
git push

# 履歴を確認
git log --oneline nginx-deployment.yaml
```

## 2. アプリケーションのバージョンアップ戦略

### 2.1 ローリングアップデート（デフォルト、ゼロダウンタイム）

ローリングアップデートは、古いバージョンのPodを段階的に新しいバージョンに置き換えていく戦略です。

#### 動作の流れ

```
初期状態: nginx:1.19 のPodが3つ
[Pod-A:1.19] [Pod-B:1.19] [Pod-C:1.19]

ステップ1: 新しいPodを1つ作成
[Pod-A:1.19] [Pod-B:1.19] [Pod-C:1.19] [Pod-D:1.20] ← 新規作成中

ステップ2: 新しいPodがReady、古いPodを1つ削除
[Pod-B:1.19] [Pod-C:1.19] [Pod-D:1.20] ← Pod-A削除

ステップ3: さらに新しいPodを1つ作成
[Pod-B:1.19] [Pod-C:1.19] [Pod-D:1.20] [Pod-E:1.20] ← 新規作成中

...繰り返し

完了状態:
[Pod-D:1.20] [Pod-E:1.20] [Pod-F:1.20]

常に最低2つのPodが稼働 → ゼロダウンタイム
```

**メリット:**
- ✅ ゼロダウンタイムでアップデート可能
- ✅ リスクを分散（段階的にロールアウト）
- ✅ 問題発見時に即座にロールバック可能

**デメリット:**
- ⚠️ アップデート中は新旧バージョンが混在
- ⚠️ データベーススキーマ変更など、後方互換性が必要

### 2.2 Recreate戦略（ダウンタイムあり）

Recreate戦略は、全ての古いPodを一度に削除してから、新しいPodを作成する方法です。

```yaml
# nginx-deployment-recreate.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment-recreate
spec:
  replicas: 3
  strategy:
    type: Recreate  # ← Recreate戦略を明示
  selector:
    matchLabels:
      app: nginx-recreate
  template:
    metadata:
      labels:
        app: nginx-recreate
    spec:
      containers:
      - name: nginx
        image: nginx:1.19
        ports:
        - containerPort: 80
```

**メリット:**
- ✅ 新旧バージョンの混在がない
- ✅ データベーススキーマの非互換な変更に対応可能

**デメリット:**
- ❌ ダウンタイムが発生する

### 2.3 Blue/Green デプロイメント（概要）

Blue（現行環境）とGreen（新環境）の2つの完全な環境を用意し、トラフィックを一度に切り替える方式です。

```
                    ┌─────────────┐
                    │   Service   │
                    └──────┬──────┘
                           │
                ┌──────────┴──────────┐
         ┌──────▼──────┐      ┌──────────────┐
         │    Blue     │      │    Green     │
         │  (v1.19)    │      │  (v1.20)     │
         │  ACTIVE ✅  │      │  STANDBY     │
         └─────────────┘      └──────────────┘
```

#### 簡易実装例

```yaml
# service.yaml（トラフィックの向き先を制御）
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
spec:
  selector:
    app: nginx
    version: blue  # ← ここを blue → green に変更してトラフィック切り替え
  ports:
  - protocol: TCP
    port: 80
    targetPort: 80
```

**トラフィック切り替えコマンド:**

```bash
# Serviceセレクタを変更してトラフィックを切り替え
kubectl patch service nginx-service -p '{"spec":{"selector":{"version":"green"}}}'

# 問題があればすぐにBlueに戻せる
kubectl patch service nginx-service -p '{"spec":{"selector":{"version":"blue"}}}'
```

**メリット:**
- ✅ 瞬時にトラフィック切り替え可能
- ✅ 瞬時にロールバック可能
- ✅ ゼロダウンタイム

**デメリット:**
- ❌ リソースが2倍必要（コスト増）

### 2.4 Canary デプロイメント（概要）

新バージョンを一部のユーザー（例: 10%）にだけ公開し、問題がなければ徐々に割合を増やしていく方式です。

```
                    ┌─────────────┐
                    │   Service   │
                    └──────┬──────┘
                           │
                ┌──────────┴─────────────┐
               90%                      10%
         ┌──────▼──────┐        ┌───────▼──────┐
         │   Stable    │        │    Canary    │
         │   (v1.19)   │        │   (v1.20)    │
         │   9 Pods    │        │   1 Pod      │
         └─────────────┘        └──────────────┘
```

**メリット:**
- ✅ リスクを最小化（影響範囲を限定）
- ✅ 本番環境で少数のユーザーでテスト可能

**詳細は後の回で**: Blue/GreenとCanaryの高度な実装は、Service Mesh（Istio）を使った実装を別の回で詳しく解説します。

## 3. ローリングアップデートの実践

ここからは、最も一般的なローリングアップデートを実際に手を動かして学びます。

### 3.1 Deployment YAMLマニフェストの詳細な書き方

#### 完全なマニフェスト例

```yaml
# nginx-deployment-complete.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
  labels:
    app: nginx
  annotations:
    kubernetes.io/change-cause: "Initial deployment with nginx 1.19"
spec:
  replicas: 3
  
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1        # 最大で1つ余分にPodを作成できる
      maxUnavailable: 1  # 最大で1つPodが利用不可でもOK
  
  revisionHistoryLimit: 10  # revision履歴の保持数
  
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
        image: nginx:1.19-alpine
        ports:
        - containerPort: 80
        
        resources:
          requests:
            memory: "64Mi"
            cpu: "100m"
          limits:
            memory: "128Mi"
            cpu: "200m"
        
        readinessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 5
          periodSeconds: 5
```

#### 各フィールドの詳細説明

**strategy.rollingUpdate.maxSurge**
- 「最大でいくつ余分にPodを作成してよいか」
- 数値（例: `1`）または割合（例: `25%`）で指定
- `replicas: 3, maxSurge: 1` の場合、アップデート中は最大4 Podまで存在可能

**strategy.rollingUpdate.maxUnavailable**
- 「最大でいくつPodが利用不可になってもよいか」
- `replicas: 3, maxUnavailable: 1` の場合、最低2 Podは常に稼働

**revisionHistoryLimit**
- 保持するReplicaSetの履歴数（デフォルトは10）
- ロールバック可能な履歴の数を制御

**annotations: kubernetes.io/change-cause**
- 変更理由を記録（`kubectl rollout history`で表示される）

### 3.2 イメージのバージョン変更手順

#### 方法1: kubectl set image コマンド

```bash
# Deploymentをデプロイ
kubectl apply -f nginx-deployment-complete.yaml

# イメージを1.19から1.20にアップデート
kubectl set image deployment/nginx-deployment nginx=nginx:1.20-alpine

# 変更理由を記録
kubectl annotate deployment/nginx-deployment \
  kubernetes.io/change-cause="Update nginx to 1.20 for security patch"

# デプロイ状況を監視
kubectl rollout status deployment/nginx-deployment
# 出力例:
# Waiting for deployment "nginx-deployment" rollout to finish: 1 out of 3 new replicas have been updated...
# Waiting for deployment "nginx-deployment" rollout to finish: 2 out of 3 new replicas have been updated...
# deployment "nginx-deployment" successfully rolled out
```

#### 方法2: マニフェストファイルの編集とapply（推奨）

```bash
# マニフェストファイルを編集
# image: nginx:1.19-alpine → nginx:1.20-alpine

vim nginx-deployment-complete.yaml

# 適用
kubectl apply -f nginx-deployment-complete.yaml

# ステータス確認
kubectl rollout status deployment/nginx-deployment
```

**推奨**: 本番環境ではGit管理されたマニフェストファイルを編集して `kubectl apply` する方法が最も安全です。

### 3.3 kubectl rollout status でのデプロイ進行確認

#### リアルタイム監視

```bash
# デプロイ状況をリアルタイムで監視
kubectl rollout status deployment/nginx-deployment

# Podの状態変化をリアルタイムで監視
kubectl get pods -l app=nginx -w

# 出力例:
# NAME                                READY   STATUS    RESTARTS   AGE
# nginx-deployment-56db8d64f7-abc12   1/1     Running   0          5m
# nginx-deployment-56db8d64f7-def34   1/1     Running   0          5m
# nginx-deployment-56db8d64f7-ghi56   1/1     Running   0          5m
# nginx-deployment-7d9c8bf7c5-xyz89   0/1     Pending   0          0s     ← 新しいPod
# nginx-deployment-7d9c8bf7c5-xyz89   0/1     ContainerCreating   0      1s
# nginx-deployment-7d9c8bf7c5-xyz89   1/1     Running             0      3s
# nginx-deployment-56db8d64f7-abc12   1/1     Terminating         0      5m  ← 古いPod削除
# nginx-deployment-7d9c8bf7c5-rst12   0/1     Pending             0      0s  ← 次の新しいPod
# ...
```

#### ReplicaSetの変化を確認

```bash
# ReplicaSetの状態を確認
kubectl get rs -l app=nginx

# 出力例:
# NAME                          DESIRED   CURRENT   READY   AGE
# nginx-deployment-56db8d64f7   0         0         0       10m  ← 旧ReplicaSet（レプリカ0）
# nginx-deployment-7d9c8bf7c5   3         3         3       2m   ← 新ReplicaSet（レプリカ3）
```

### 3.4 maxSurge と maxUnavailable パラメータの詳細説明

#### maxSurge の詳細

**例**: `replicas: 4, maxSurge: 1` の場合

```
初期状態: 4 Pods
[Pod-A:v1] [Pod-B:v1] [Pod-C:v1] [Pod-D:v1]

maxSurge: 1 なので、最大5 Podsまで許容
[Pod-A:v1] [Pod-B:v1] [Pod-C:v1] [Pod-D:v1] [Pod-E:v2] ← 5つになる

新しいPodがReady後、古いPodを削除
[Pod-B:v1] [Pod-C:v1] [Pod-D:v1] [Pod-E:v2] ← 4つに戻る

再び新しいPodを作成
[Pod-B:v1] [Pod-C:v1] [Pod-D:v1] [Pod-E:v2] [Pod-F:v2] ← 5つ

以下繰り返し...
```

#### maxUnavailable の詳細

**例**: `replicas: 4, maxUnavailable: 1` の場合

```
初期状態: 4 Pods、全てReady
[Pod-A:v1✅] [Pod-B:v1✅] [Pod-C:v1✅] [Pod-D:v1✅]

maxUnavailable: 1 なので、最低3 PodsはReadyでなければならない

古いPodを1つTerminating
[Pod-A:v1❌] [Pod-B:v1✅] [Pod-C:v1✅] [Pod-D:v1✅] ← 3つReady

新しいPodを作成（まだReady ではない）
[Pod-A:v1❌] [Pod-B:v1✅] [Pod-C:v1✅] [Pod-D:v1✅] [Pod-E:v2❌]

Pod-EがReady になってから次の古いPodを削除
[Pod-B:v1❌] [Pod-C:v1✅] [Pod-D:v1✅] [Pod-E:v2✅] ← 3つReady
```

#### 設定パターンの比較

| パターン | maxSurge | maxUnavailable | 特徴 |
|---------|----------|----------------|------|
| 高速デプロイ | 100% | 100% | 最も速いが、リソース使用量が2倍、ダウンタイムあり |
| バランス型 | 25% | 25% | デフォルト。速度とリソースのバランス |
| 安全重視 | 1 | 0 | 常に全Podが稼働。最も安全だが遅い |
| リソース節約 | 0 | 1 | 余分なリソース不要だが、一時的にキャパシティ減 |

#### 実践例: 異なる設定でのデプロイ速度比較

```yaml
# fast-deployment.yaml（高速だがリスク高）
spec:
  replicas: 10
  strategy:
    rollingUpdate:
      maxSurge: 5        # 50%余分に作成可能
      maxUnavailable: 5  # 50%が利用不可でもOK
```

```yaml
# safe-deployment.yaml（安全だが遅い）
spec:
  replicas: 10
  strategy:
    rollingUpdate:
      maxSurge: 1        # 1つずつ増やす
      maxUnavailable: 0  # 常に全Podが稼働
```

```bash
# 高速デプロイ（約30秒で完了）
kubectl apply -f fast-deployment.yaml
kubectl set image deployment/fast-deploy nginx=nginx:1.20
kubectl rollout status deployment/fast-deploy

# 安全デプロイ（約2分で完了）
kubectl apply -f safe-deployment.yaml
kubectl set image deployment/safe-deploy nginx=nginx:1.20
kubectl rollout status deployment/safe-deploy
```

## 4. デプロイ履歴の確認とロールバック

### 4.1 kubectl rollout history での履歴確認

Deploymentは過去のデプロイ履歴（ReplicaSet）を保持しており、いつでも前のバージョンに戻すことができます。

```bash
# 履歴を確認
kubectl rollout history deployment/nginx-deployment

# 出力例:
# deployment.apps/nginx-deployment
# REVISION  CHANGE-CAUSE
# 1         Initial deployment with nginx 1.19
# 2         Update nginx to 1.20 for security patch
# 3         Update nginx to 1.21 with performance improvements
```

#### 特定リビジョンの詳細確認

```bash
# リビジョン2の詳細を確認
kubectl rollout history deployment/nginx-deployment --revision=2

# 出力例:
# deployment.apps/nginx-deployment with revision #2
# Pod Template:
#   Labels:       app=nginx
#                 pod-template-hash=7d9c8bf7c5
#   Annotations:  kubernetes.io/change-cause: Update nginx to 1.20 for security patch
#   Containers:
#    nginx:
#     Image:      nginx:1.20-alpine
#     Port:       80/TCP
#     Limits:
#       cpu:      200m
#       memory:   128Mi
#     Requests:
#       cpu:        100m
#       memory:     64Mi
#     Environment:  <none>
#     Mounts:       <none>
#   Volumes:        <none>
```

### 4.2 アノテーションでの変更理由記録

変更理由を記録することで、後から「なぜこのデプロイが行われたのか」を追跡できます。

#### 方法1: kubectl apply 時にアノテーションを追加

```yaml
# nginx-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
  annotations:
    kubernetes.io/change-cause: "Update to nginx 1.21 for CVE-2023-XXXX fix"
spec:
  replicas: 3
  template:
    spec:
      containers:
      - name: nginx
        image: nginx:1.21-alpine
```

```bash
kubectl apply -f nginx-deployment.yaml
```

#### 方法2: kubectl annotate コマンド

```bash
# イメージ更新後にアノテーションを追加
kubectl set image deployment/nginx-deployment nginx=nginx:1.21-alpine

kubectl annotate deployment/nginx-deployment \
  kubernetes.io/change-cause="Update to nginx 1.21 for CVE-2023-XXXX fix"
```

#### 方法3: --record フラグ（非推奨）

```bash
# --recordフラグは非推奨（kubectl 1.19以降）
# 代わりにアノテーションを使用してください
kubectl apply -f nginx-deployment.yaml --record  # 非推奨
```

### 4.3 kubectl rollout undo でのロールバック

#### 直前のバージョンにロールバック

```bash
# 最新のデプロイをロールバック（1つ前のリビジョンに戻る）
kubectl rollout undo deployment/nginx-deployment

# ロールバックの進行状況を監視
kubectl rollout status deployment/nginx-deployment
# 出力:
# Waiting for deployment "nginx-deployment" rollout to finish: 1 out of 3 new replicas have been updated...
# deployment "nginx-deployment" successfully rolled out

# 確認
kubectl get pods
kubectl rollout history deployment/nginx-deployment
# REVISION  CHANGE-CAUSE
# 1         Initial deployment with nginx 1.19
# 3         Update nginx to 1.21 with performance improvements
# 4         Update nginx to 1.20 for security patch  ← リビジョン2が4として復活
```

**注意**: ロールバック自体が新しいリビジョンとして記録されます！

#### 特定リビジョンへのロールバック

```bash
# リビジョン1（初期デプロイ）に戻る
kubectl rollout undo deployment/nginx-deployment --to-revision=1

# 確認
kubectl describe deployment nginx-deployment | grep Image
#   Image:        nginx:1.19-alpine

kubectl rollout history deployment/nginx-deployment
# REVISION  CHANGE-CAUSE
# 3         Update nginx to 1.21 with performance improvements
# 4         Update nginx to 1.20 for security patch
# 5         Initial deployment with nginx 1.19  ← リビジョン1が5として復活
```

### 4.4 revision履歴の保持設定

#### revisionHistoryLimit の設定

```yaml
# nginx-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
spec:
  replicas: 3
  revisionHistoryLimit: 5  # 最新5つのReplicaSetを保持
  template:
    spec:
      containers:
      - name: nginx
        image: nginx:1.19-alpine
```

```bash
# 現在のrevisionHistoryLimitを確認
kubectl get deployment nginx-deployment -o jsonpath='{.spec.revisionHistoryLimit}'

# 変更
kubectl patch deployment nginx-deployment -p '{"spec":{"revisionHistoryLimit":5}}'
```

#### 古いReplicaSetの確認と削除

```bash
# 全てのReplicaSetを確認
kubectl get rs

# 出力例:
# NAME                          DESIRED   CURRENT   READY   AGE
# nginx-deployment-56db8d64f7   0         0         0       2h   ← 古い
# nginx-deployment-7d9c8bf7c5   0         0         0       1h   ← 古い
# nginx-deployment-8e0d9cf8d6   0         0         0       30m  ← 古い
# nginx-deployment-9f1e0dg9e7   3         3         3       5m   ← 現在アクティブ

# 古いReplicaSetは自動的に保持される（revisionHistoryLimit分）
# 手動削除も可能（ただし、その後ロールバックはできなくなる）
kubectl delete rs nginx-deployment-56db8d64f7
```

#### 履歴を完全に削除（注意）

```bash
# revisionHistoryLimitを0に設定すると、履歴を保持しない
kubectl patch deployment nginx-deployment -p '{"spec":{"revisionHistoryLimit":0}}'

# この場合、ロールバックはできなくなる！
# 本番環境では推奨しない
```

### 4.5 ロールバックの実践シナリオ

#### シナリオ: 壊れたイメージをデプロイしてロールバック

```bash
# 1. 正常なデプロイを確認
kubectl apply -f nginx-deployment-complete.yaml
kubectl rollout status deployment/nginx-deployment

# 2. 存在しないイメージタグをデプロイ（意図的な失敗）
kubectl set image deployment/nginx-deployment nginx=nginx:nonexistent-tag

# 3. 状態を確認
kubectl get pods
# 出力例:
# NAME                                READY   STATUS             RESTARTS   AGE
# nginx-deployment-abc123             0/1     ImagePullBackOff   0          30s  ← 新しいPod（失敗）
# nginx-deployment-old-def456         1/1     Running            0          5m   ← 古いPod（稼働中）
# nginx-deployment-old-ghi789         1/1     Running            0          5m
# nginx-deployment-old-jkl012         1/1     Running            0          5m

# maxUnavailable: 1 の設定により、3つ中2つは常に稼働！サービスは継続！

# 4. デプロイの状態確認
kubectl rollout status deployment/nginx-deployment
# 出力:
# Waiting for deployment "nginx-deployment" rollout to finish: 1 out of 3 new replicas have been updated...
# （ずっと待機状態）

# 5. イベントを確認
kubectl describe deployment nginx-deployment
# Events:
#   Warning  FailedCreate  1m  replicaset-controller  Error creating: pods "nginx-deployment-abc123" is forbidden: failed to pull image "nginx:nonexistent-tag": rpc error: code = Unknown desc = Error response from daemon: manifest for nginx:nonexistent-tag not found

# 6. ロールバック実行
kubectl rollout undo deployment/nginx-deployment

# 7. 即座に復旧
kubectl rollout status deployment/nginx-deployment
# deployment "nginx-deployment" successfully rolled out

kubectl get pods
# NAME                                READY   STATUS    RESTARTS   AGE
# nginx-deployment-old-def456         1/1     Running   0          6m
# nginx-deployment-old-ghi789         1/1     Running   0          6m
# nginx-deployment-old-jkl012         1/1     Running   0          6m
```

**重要**: ローリングアップデートとReadiness Probeの組み合わせにより、失敗したデプロイでもサービスは継続します！

## 5. 実践的なデプロイシナリオ

### 5.1 nginx:1.19 から nginx:1.20 へのアップデート実演

完全なハンズオン形式で、実際のアップデートを体験しましょう。

#### ステップ1: 初期デプロイ

```bash
# マニフェストを作成
cat > nginx-demo.yaml << 'YAML'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-demo
  annotations:
    kubernetes.io/change-cause: "Initial deployment - nginx 1.19"
spec:
  replicas: 5
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 1
  selector:
    matchLabels:
      app: nginx-demo
  template:
    metadata:
      labels:
        app: nginx-demo
        version: v1.19
    spec:
      containers:
      - name: nginx
        image: nginx:1.19-alpine
        ports:
        - containerPort: 80
        readinessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 2
          periodSeconds: 3
        resources:
          requests:
            memory: "32Mi"
            cpu: "50m"
YAML

# デプロイ
kubectl apply -f nginx-demo.yaml

# 確認
kubectl get deployment nginx-demo
# NAME         READY   UP-TO-DATE   AVAILABLE   AGE
# nginx-demo   5/5     5            5           20s

kubectl get pods -l app=nginx-demo
# NAME                          READY   STATUS    RESTARTS   AGE
# nginx-demo-7b8c9d5f6b-abcd1   1/1     Running   0          25s
# nginx-demo-7b8c9d5f6b-efgh2   1/1     Running   0          25s
# nginx-demo-7b8c9d5f6b-ijkl3   1/1     Running   0          25s
# nginx-demo-7b8c9d5f6b-mnop4   1/1     Running   0          25s
# nginx-demo-7b8c9d5f6b-qrst5   1/1     Running   0          25s
```

#### ステップ2: Serviceを作成してアクセス確認

```bash
# Serviceを作成
kubectl expose deployment nginx-demo --port=80 --type=NodePort

# Serviceを確認
kubectl get svc nginx-demo
# NAME         TYPE       CLUSTER-IP      EXTERNAL-IP   PORT(S)        AGE
# nginx-demo   NodePort   10.96.123.45    <none>        80:30123/TCP   5s

# minikubeでアクセス
minikube service nginx-demo --url
# http://192.168.49.2:30123

# アクセステスト（別ターミナル）
while true; do curl -s http://192.168.49.2:30123 | grep "nginx/" && sleep 1; done
# <title>Welcome to nginx!</title>
# <h1>Welcome to nginx!</h1>
# <a href="http://nginx.org/">nginx.org</a>.</p>
# ...（継続的にアクセス）
```

#### ステップ3: イメージを1.20にアップデート

```bash
# 新しいターミナルを開いて、Podの状態を監視
kubectl get pods -l app=nginx-demo -w

# 別のターミナルでアップデート実行
kubectl set image deployment/nginx-demo nginx=nginx:1.20-alpine

kubectl annotate deployment/nginx-demo \
  kubernetes.io/change-cause="Update to nginx 1.20 for new features"

# デプロイ状況を監視
kubectl rollout status deployment/nginx-demo
# Waiting for deployment "nginx-demo" rollout to finish: 1 out of 5 new replicas have been updated...
# Waiting for deployment "nginx-demo" rollout to finish: 1 out of 5 new replicas have been updated...
# Waiting for deployment "nginx-demo" rollout to finish: 2 out of 5 new replicas have been updated...
# Waiting for deployment "nginx-demo" rollout to finish: 2 out of 5 new replicas have been updated...
# Waiting for deployment "nginx-demo" rollout to finish: 3 out of 5 new replicas have been updated...
# Waiting for deployment "nginx-demo" rollout to finish: 3 out of 5 new replicas have been updated...
# Waiting for deployment "nginx-demo" rollout to finish: 4 out of 5 new replicas have been updated...
# Waiting for deployment "nginx-demo" rollout to finish: 4 out of 5 new replicas have been updated...
# Waiting for deployment "nginx-demo" rollout to finish: 1 old replicas are pending termination...
# deployment "nginx-demo" successfully rolled out
```

#### ステップ4: アップデート中のPod状態変化を観察

監視していたターミナルの出力:

```
NAME                          READY   STATUS    RESTARTS   AGE
nginx-demo-7b8c9d5f6b-abcd1   1/1     Running   0          2m
nginx-demo-7b8c9d5f6b-efgh2   1/1     Running   0          2m
nginx-demo-7b8c9d5f6b-ijkl3   1/1     Running   0          2m
nginx-demo-7b8c9d5f6b-mnop4   1/1     Running   0          2m
nginx-demo-7b8c9d5f6b-qrst5   1/1     Running   0          2m

# maxSurge: 1 により、6つ目のPodが作成される
nginx-demo-9e3f0eg0f8-uvwx1   0/1     Pending   0          0s
nginx-demo-9e3f0eg0f8-uvwx1   0/1     ContainerCreating   0          1s
nginx-demo-9e3f0eg0f8-uvwx1   0/1     Running   0          3s   ← まだReady ではない
nginx-demo-9e3f0eg0f8-uvwx1   1/1     Running   0          5s   ← Ready!

# 新しいPodがReady になったので、古いPodを1つ削除
nginx-demo-7b8c9d5f6b-abcd1   1/1     Terminating   0          2m

# maxSurge: 1 により、また6つ目のPodが作成される
nginx-demo-9e3f0eg0f8-yzab2   0/1     Pending   0          0s
nginx-demo-9e3f0eg0f8-yzab2   0/1     ContainerCreating   0          1s
nginx-demo-7b8c9d5f6b-abcd1   0/1     Terminating   0          2m
nginx-demo-9e3f0eg0f8-yzab2   0/1     Running   0          3s
nginx-demo-9e3f0eg0f8-yzab2   1/1     Running   0          5s

# 次の古いPodを削除
nginx-demo-7b8c9d5f6b-efgh2   1/1     Terminating   0          2m

# 以下同様に繰り返し...
nginx-demo-9e3f0eg0f8-cdef3   0/1     Pending   0          0s
nginx-demo-9e3f0eg0f8-cdef3   0/1     ContainerCreating   0          1s
...

# 最終的に全てのPodが新しいバージョンに
nginx-demo-9e3f0eg0f8-uvwx1   1/1     Running   0          45s
nginx-demo-9e3f0eg0f8-yzab2   1/1     Running   0          40s
nginx-demo-9e3f0eg0f8-cdef3   1/1     Running   0          35s
nginx-demo-9e3f0eg0f8-ghij4   1/1     Running   0          30s
nginx-demo-9e3f0eg0f8-klmn5   1/1     Running   0          25s
```

**重要な観察ポイント**:
- アップデート中、Pod数は4～6の間で変動（replicas: 5, maxSurge: 1, maxUnavailable: 1）
- 新しいPodは必ずReadiness Probeを通過してから古いPodが削除される
- アクセステストは一度も失敗しない（ゼロダウンタイム）

#### ステップ5: ReplicaSetの状態確認

```bash
kubectl get rs -l app=nginx-demo
# NAME                    DESIRED   CURRENT   READY   AGE
# nginx-demo-7b8c9d5f6b   0         0         0       5m   ← v1.19（レプリカ0）
# nginx-demo-9e3f0eg0f8   5         5         5       2m   ← v1.20（レプリカ5）
```

#### ステップ6: 履歴確認

```bash
kubectl rollout history deployment/nginx-demo
# REVISION  CHANGE-CAUSE
# 1         Initial deployment - nginx 1.19
# 2         Update to nginx 1.20 for new features
```

### 5.2 意図的に壊れたイメージでデプロイしてロールバック

#### シナリオ: 存在しないイメージタグをデプロイ

```bash
# 1. 壊れたイメージをデプロイ
kubectl set image deployment/nginx-demo nginx=nginx:broken-nonexistent-tag

kubectl annotate deployment/nginx-demo \
  kubernetes.io/change-cause="Broken deployment - testing rollback" --overwrite

# 2. 状態を監視
kubectl get pods -l app=nginx-demo -w

# 出力例:
# NAME                          READY   STATUS             RESTARTS   AGE
# nginx-demo-9e3f0eg0f8-uvwx1   1/1     Running            0          3m
# nginx-demo-9e3f0eg0f8-yzab2   1/1     Running            0          3m
# nginx-demo-9e3f0eg0f8-cdef3   1/1     Running            0          3m
# nginx-demo-9e3f0eg0f8-ghij4   1/1     Running            0          3m
# nginx-demo-9e3f0eg0f8-klmn5   1/1     Running            0          3m
# nginx-demo-bad123456-opqr1    0/1     Pending            0          0s   ← 新しいPod
# nginx-demo-bad123456-opqr1    0/1     ContainerCreating  0          1s
# nginx-demo-bad123456-opqr1    0/1     ErrImagePull       0          5s   ← エラー！
# nginx-demo-bad123456-opqr1    0/1     ImagePullBackOff   0          10s
# nginx-demo-bad123456-opqr1    0/1     ErrImagePull       0          25s
# nginx-demo-bad123456-opqr1    0/1     ImagePullBackOff   0          40s
# ...（繰り返し、Readyにならない）

# 3. サービスは継続中であることを確認
# アクセステストしているターミナルでは、引き続きnginxにアクセスできている！
# これは、新しいPodがReadyにならないため、古いPodが削除されないから

# 4. Deploymentの状態を確認
kubectl get deployment nginx-demo
# NAME         READY   UP-TO-DATE   AVAILABLE   AGE
# nginx-demo   5/5     1            5           10m
#               ↑       ↑
#           5つReady  1つ更新中（失敗）

# 5. エラーの詳細を確認
kubectl describe pod nginx-demo-bad123456-opqr1 | grep -A 5 Events
# Events:
#   Type     Reason     Age                From               Message
#   ----     ------     ----               ----               -------
#   Normal   Scheduled  2m                 default-scheduler  Successfully assigned default/nginx-demo-bad123456-opqr1 to minikube
#   Normal   Pulling    1m (x4 over 2m)    kubelet            Pulling image "nginx:broken-nonexistent-tag"
#   Warning  Failed     1m (x4 over 2m)    kubelet            Failed to pull image "nginx:broken-nonexistent-tag": rpc error: code = Unknown desc = Error response from daemon: manifest for nginx:broken-nonexistent-tag not found

# 6. ロールバック実行
kubectl rollout undo deployment/nginx-demo

# 7. 即座に復旧
kubectl rollout status deployment/nginx-demo
# deployment "nginx-demo" successfully rolled out

kubectl get pods -l app=nginx-demo
# NAME                          READY   STATUS    RESTARTS   AGE
# nginx-demo-9e3f0eg0f8-uvwx1   1/1     Running   0          5m
# nginx-demo-9e3f0eg0f8-yzab2   1/1     Running   0          5m
# nginx-demo-9e3f0eg0f8-cdef3   1/1     Running   0          5m
# nginx-demo-9e3f0eg0f8-ghij4   1/1     Running   0          5m
# nginx-demo-9e3f0eg0f8-klmn5   1/1     Running   0          5m
# ← 全て正常なPod、壊れたPodは削除された

# 8. 履歴確認
kubectl rollout history deployment/nginx-demo
# REVISION  CHANGE-CAUSE
# 1         Initial deployment - nginx 1.19
# 3         Broken deployment - testing rollback
# 4         Update to nginx 1.20 for new features  ← リビジョン2が4として復活
```

**学んだこと**:
- 失敗したデプロイでも、サービスは継続する
- Readiness Probeが正しく設定されていれば、壊れたPodにトラフィックは流れない
- ロールバックは簡単で高速

### 5.3 デプロイの一時停止と再開

複数の変更を一度にデプロイしたい場合、デプロイを一時停止して複数の変更を適用してから再開することができます。

```bash
# 1. デプロイを一時停止
kubectl rollout pause deployment/nginx-demo

# 2. 複数の変更を適用
# イメージを変更
kubectl set image deployment/nginx-demo nginx=nginx:1.21-alpine

# リソース制限を変更
kubectl set resources deployment/nginx-demo -c nginx \
  --requests=cpu=100m,memory=64Mi \
  --limits=cpu=200m,memory=128Mi

# レプリカ数を変更
kubectl scale deployment/nginx-demo --replicas=7

# 3. この時点ではまだ変更は適用されていない
kubectl get pods -l app=nginx-demo --watch-only=false
# まだ5つのPodのまま

# 4. デプロイを再開
kubectl rollout resume deployment/nginx-demo

# 5. 一度に全ての変更が適用される
kubectl rollout status deployment/nginx-demo
# Waiting for deployment "nginx-demo" rollout to finish: 2 out of 7 new replicas have been updated...
# ...
# deployment "nginx-demo" successfully rolled out

kubectl get deployment nginx-demo
# NAME         READY   UP-TO-DATE   AVAILABLE   AGE
# nginx-demo   7/7     7            7           15m

kubectl get pods -l app=nginx-demo
# 7つのPodが全て nginx:1.21-alpine で、新しいリソース制限で動作
```

**メリット**:
- 複数の変更を1つのリビジョンとして記録できる
- ローリングアップデートが1回だけ実行される（効率的）
- 途中で設定を確認・修正できる

**使用例**:
- メンテナンスウィンドウ中の大規模な変更
- 複数の設定変更を一度に適用したい場合
- 変更内容を慎重に確認してからデプロイしたい場合

## 6. Deploymentの高度な設定

### 6.1 minReadySeconds（準備完了待機時間）

新しいPodがReadyになってから、実際にトラフィックを受け入れるまでの待機時間を設定します。

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-with-minready
spec:
  replicas: 3
  minReadySeconds: 30  # 30秒間待機してから次のPodを更新
  strategy:
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 0
  template:
    spec:
      containers:
      - name: nginx
        image: nginx:1.20-alpine
        readinessProbe:
          httpGet:
            path: /
            port: 80
          periodSeconds: 5
```

**用途**:
- アプリケーションの起動後のウォームアップ時間を確保
- メモリリークなどの遅延障害を検出
- より安全なデプロイ（各Podを十分に観察してから次に進む）

**動作**:
```bash
kubectl apply -f nginx-with-minready.yaml
kubectl set image deployment/nginx-with-minready nginx=nginx:1.21-alpine

# Podの状態を監視
kubectl get pods -l app=nginx-with-minready -w

# 観察ポイント:
# - 新しいPodがReady になっても、すぐには古いPodが削除されない
# - 30秒間待機してから次のPodの更新が開始される
# - デプロイ全体の時間が長くなる（より安全）
```

### 6.2 progressDeadlineSeconds（デプロイタイムアウト）

デプロイが進行しない場合のタイムアウト時間を設定します。

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-with-deadline
spec:
  replicas: 3
  progressDeadlineSeconds: 600  # 10分でタイムアウト
  strategy:
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 1
  template:
    spec:
      containers:
      - name: nginx
        image: nginx:1.20-alpine
```

**デフォルト値**: 600秒（10分）

**タイムアウトになる条件**:
- 新しいPodが指定時間内にReadyにならない
- ImagePullBackOff、CrashLoopBackOff などで進行が停止

```bash
# タイムアウト後の状態確認
kubectl describe deployment nginx-with-deadline

# Conditions:
#   Type           Status  Reason
#   ----           ------  ------
#   Available      True    MinimumReplicasAvailable
#   Progressing    False   ProgressDeadlineExceeded  ← タイムアウト
# ...
# Events:
#   Warning  ProgressDeadlineExceeded  5m  deployment-controller  ReplicaSet "nginx-with-deadline-abc123" has timed out progressing.
```

**ベストプラクティス**:
- 開発環境: 短め（300秒など）で早期にエラーを検出
- 本番環境: 長め（600秒以上）で一時的な問題を許容

### 6.3 revisionHistoryLimit（履歴保持数）

既に説明した通り、保持するReplicaSetの履歴数を制御します。

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-history-limit
spec:
  replicas: 3
  revisionHistoryLimit: 3  # 最新3つのリビジョンのみ保持
  template:
    spec:
      containers:
      - name: nginx
        image: nginx:1.20-alpine
```

**推奨値**:
- 開発環境: 3～5（ディスク容量節約）
- 本番環境: 10～15（十分なロールバック履歴）

```bash
# 現在の履歴を確認
kubectl get rs -l app=nginx-history-limit

# revisionHistoryLimit: 3 の場合、最新3つのReplicaSetのみが保持される
# 古いReplicaSetは自動的に削除される
```

### 6.4 paused（デプロイ一時停止）

Deploymentを一時停止状態で作成または変更できます。

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-paused
spec:
  replicas: 3
  paused: true  # 一時停止状態で作成
  template:
    spec:
      containers:
      - name: nginx
        image: nginx:1.20-alpine
```

```bash
# 一時停止状態で作成
kubectl apply -f nginx-paused.yaml

# この時点では何も起こらない（ReplicaSetもPodも作成されない）
kubectl get pods -l app=nginx-paused
# No resources found

# 一時停止を解除
kubectl patch deployment nginx-paused -p '{"spec":{"paused":false}}'

# または
kubectl rollout resume deployment/nginx-paused

# これでPodが作成される
kubectl get pods -l app=nginx-paused
```

**使用例**:
- GitOpsワークフローでの段階的な適用
- 複雑な変更を事前に準備してから一度に適用
- カナリアデプロイの準備段階

### 6.5 完全な高度設定の例

```yaml
# nginx-deployment-advanced.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-production
  labels:
    app: nginx
    environment: production
  annotations:
    kubernetes.io/change-cause: "Production deployment with advanced settings"
spec:
  replicas: 10
  
  # 履歴保持
  revisionHistoryLimit: 15
  
  # デプロイ進行のタイムアウト（15分）
  progressDeadlineSeconds: 900
  
  # Ready後の待機時間（1分）
  minReadySeconds: 60
  
  # ローリングアップデート戦略
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 2        # 20%余分に作成可能
      maxUnavailable: 1  # 最大1つだけ利用不可
  
  selector:
    matchLabels:
      app: nginx
      environment: production
  
  template:
    metadata:
      labels:
        app: nginx
        environment: production
        version: v1.21
    spec:
      # Pod配置の制御（後の回で詳しく説明）
      affinity:
        podAntiAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 100
            podAffinityTerm:
              labelSelector:
                matchExpressions:
                - key: app
                  operator: In
                  values:
                  - nginx
              topologyKey: kubernetes.io/hostname
      
      containers:
      - name: nginx
        image: nginx:1.21-alpine
        ports:
        - name: http
          containerPort: 80
          protocol: TCP
        
        # リソース制限
        resources:
          requests:
            memory: "128Mi"
            cpu: "250m"
          limits:
            memory: "256Mi"
            cpu: "500m"
        
        # Liveness Probe
        livenessProbe:
          httpGet:
            path: /
            port: http
            scheme: HTTP
          initialDelaySeconds: 30
          periodSeconds: 10
          timeoutSeconds: 5
          successThreshold: 1
          failureThreshold: 3
        
        # Readiness Probe（より厳格）
        readinessProbe:
          httpGet:
            path: /
            port: http
            scheme: HTTP
          initialDelaySeconds: 5
          periodSeconds: 5
          timeoutSeconds: 3
          successThreshold: 2  # 2回連続成功が必要
          failureThreshold: 2
        
        # Lifecycle hooks
        lifecycle:
          preStop:
            exec:
              command: ["/bin/sh", "-c", "sleep 15"]  # 終了前に15秒待機
```

```bash
# デプロイ
kubectl apply -f nginx-deployment-advanced.yaml

# アップデート（慎重かつ段階的に進行）
kubectl set image deployment/nginx-production nginx=nginx:1.22-alpine
kubectl rollout status deployment/nginx-production

# 進行の詳細を監視
kubectl get pods -l app=nginx,environment=production -w

# 各Podが60秒間待機してから次のPodが更新されることを確認
```

## 7. 初心者がつまづきやすいポイント

### 7.1 Readiness Probeの重要性

**問題**: Readiness Probeを設定しないと、トラフィック喪失が発生する可能性があります。

#### シナリオ: Readiness Probeなしでのデプロイ

```yaml
# bad-deployment-no-probe.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-no-probe
spec:
  replicas: 3
  strategy:
    rollingUpdate:
      maxSurge: 1
      maxUnavailable: 1
  selector:
    matchLabels:
      app: slow-app
  template:
    metadata:
      labels:
        app: slow-app
    spec:
      containers:
      - name: app
        image: myapp:v2  # 起動に30秒かかるアプリ
        ports:
        - containerPort: 8080
        # Readiness Probeがない！
```

**何が起こるか**:

```
1. 新しいPodが作成される
2. コンテナが起動（プロセスは動作）
3. Readiness Probeがないため、Kubernetesは「即座にReady」と判断
4. Serviceが新しいPodにトラフィックを送信開始
5. しかし、アプリケーションはまだ初期化中
6. リクエストがエラー（500、503など）← ユーザーに影響！
7. 30秒後にアプリケーションが実際にReady
```

**正しい実装**:

```yaml
# good-deployment-with-probe.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-with-probe
spec:
  replicas: 3
  selector:
    matchLabels:
      app: slow-app
  template:
    metadata:
      labels:
        app: slow-app
    spec:
      containers:
      - name: app
        image: myapp:v2
        ports:
        - containerPort: 8080
        
        readinessProbe:  # ← 必須！
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 10  # 起動後10秒待ってから最初のチェック
          periodSeconds: 5
          timeoutSeconds: 3
          successThreshold: 1
          failureThreshold: 3
```

**結果**:
- アプリケーションが実際にReadyになってからトラフィックが流れる
- ユーザーへの影響ゼロ
- ローリングアップデートが安全に進行

### 7.2 maxSurge/maxUnavailableの設定ミス

#### 問題1: 両方を0に設定

```yaml
# wrong-zero-both.yaml（これはエラーになる）
spec:
  strategy:
    rollingUpdate:
      maxSurge: 0
      maxUnavailable: 0  # ← 両方0はNG!
```

```bash
kubectl apply -f wrong-zero-both.yaml
# Error: Deployment.apps "xxx" is invalid: spec.strategy.rollingUpdate.maxUnavailable: Invalid value: intstr.IntOrString{Type:0, IntVal:0, StrVal:""}: may not be 0 when `maxSurge` is 0
```

**理由**: 両方が0だと、新しいPodも作れず、古いPodも削除できず、アップデートが進行不可能。

#### 問題2: 割合の誤解

```yaml
# wrong-percentage.yaml
spec:
  replicas: 3
  strategy:
    rollingUpdate:
      maxSurge: 50%       # 50% = 1.5 → 切り上げで2
      maxUnavailable: 50% # 50% = 1.5 → 切り下げで1
```

**注意点**:
- `maxSurge`: 切り上げ（1.5 → 2）
- `maxUnavailable`: 切り下げ（1.5 → 1）
- `replicas: 3, maxSurge: 33%` → 0.99 → 切り上げで1

#### 問題3: リソース不足を考慮していない

```yaml
# resource-issue.yaml
spec:
  replicas: 10
  strategy:
    rollingUpdate:
      maxSurge: 10  # ← 一度に10個余分に作成しようとする
      maxUnavailable: 0
  template:
    spec:
      containers:
      - name: app
        resources:
          requests:
            memory: "2Gi"  # 1 Pod = 2GB
            cpu: "1"
```

**問題**:
- 通常10 Pods = 20GB メモリ
- maxSurge: 10 の場合、一時的に20 Pods = 40GB メモリが必要
- クラスタにリソースが不足していると、新しいPodがPending状態に
- デプロイが進行しない

**解決策**:
```yaml
spec:
  strategy:
    rollingUpdate:
      maxSurge: 2  # より小さい値にする
      maxUnavailable: 1
```

### 7.3 イメージタグのlatest使用の問題

**アンチパターン**:

```yaml
spec:
  template:
    spec:
      containers:
      - name: app
        image: myapp:latest  # ← 絶対に避けるべき！
```

**問題点**:

1. **再現性がない**
   ```bash
   # 今日デプロイ
   kubectl apply -f deployment.yaml  # myapp:latest = v1.2.3
   
   # 明日、誰かがlatestタグを更新
   # 別のクラスタにデプロイ
   kubectl apply -f deployment.yaml  # myapp:latest = v1.3.0（異なるバージョン！）
   ```

2. **ロールバックができない**
   ```bash
   # latest で問題が発生
   kubectl rollout undo deployment/myapp
   
   # ロールバックしても、latest は最新版を指している
   # 実際には同じ壊れたバージョンがデプロイされる！
   ```

3. **ImagePullPolicyの挙動**
   ```yaml
   image: myapp:latest
   imagePullPolicy: Always  # latestの場合は常にPull
   
   # 問題:
   # - 毎回イメージをPullするためデプロイが遅い
   # - レジストリがダウンすると既存Podでも再起動できない
   ```

**正しい方法**:

```yaml
spec:
  template:
    spec:
      containers:
      - name: app
        image: myapp:v1.2.3  # ← 明示的なバージョンタグ
        imagePullPolicy: IfNotPresent  # 既にあればPullしない
```

または、さらに良い方法（イミュータブルなダイジェスト）:

```yaml
spec:
  template:
    spec:
      containers:
      - name: app
        image: myapp@sha256:abc123def456...  # ← ダイジェストで指定
```

```bash
# ダイジェストの取得方法
docker pull myapp:v1.2.3
docker inspect --format='{{index .RepoDigests 0}}' myapp:v1.2.3
# myapp@sha256:abc123def456789...
```

### 7.4 ロールバック後のマニフェストとの不一致

**問題シナリオ**:

```bash
# 1. マニフェストでv1.20をデプロイ
cat > deployment.yaml << 'YAML'
spec:
  template:
    spec:
      containers:
      - name: nginx
        image: nginx:1.20
YAML

kubectl apply -f deployment.yaml
# リビジョン1: nginx:1.20

# 2. マニフェストを編集してv1.21をデプロイ
# image: nginx:1.21
kubectl apply -f deployment.yaml
# リビジョン2: nginx:1.21

# 3. 問題が発生してロールバック
kubectl rollout undo deployment/nginx-deployment
# 実際のクラスタ: nginx:1.20（リビジョン3として）

# 4. ここで問題：
# - 実際のクラスタ: nginx:1.20
# - deployment.yaml: nginx:1.21  ← 不一致！

# 5. 次にkubectl applyすると...
kubectl apply -f deployment.yaml
# nginx:1.21が再デプロイされる（意図しない場合がある）
```

**解決策**:

```bash
# ロールバック後、マニフェストファイルも更新する
kubectl rollout undo deployment/nginx-deployment

# マニフェストを実際の状態に合わせる
kubectl get deployment nginx-deployment -o yaml > current-state.yaml

# または、Gitで適切なコミットに戻す
git revert HEAD  # v1.21のコミットを取り消し
git push

# その後、GitOps（ArgoCD等）で同期
```

**ベストプラクティス**:
- GitOpsを使用（ArgoCD、Flux等）
- マニフェストファイルとクラスタの状態を常に同期
- ロールバックもGitで行う（コミットのrevert）

### 7.5 Podの強制削除とデプロイの混乱

**問題**:

```bash
# デプロイ中にPodを強制削除
kubectl delete pod nginx-deployment-abc123 --force --grace-period=0

# 何が起こるか:
# 1. PodはDeployment配下なので即座に再作成される
# 2. しかし、ローリングアップデートの状態機械は混乱
# 3. maxSurge/maxUnavailableの制御が効かなくなる可能性
```

**正しい方法**:

```bash
# Podを削除する必要がある場合は、Deploymentに任せる
# または、Deploymentを一度削除して再作成

# 問題のあるPodを含むDeploymentを修正
kubectl edit deployment nginx-deployment

# Kubernetesが適切にローリングアップデートを実行する
```

### 7.6 デバッグのベストプラクティス

デプロイに問題が発生した場合の調査手順:

```bash
# ステップ1: Deploymentの状態確認
kubectl get deployment nginx-deployment
kubectl describe deployment nginx-deployment

# ステップ2: ReplicaSetの状態確認
kubectl get rs -l app=nginx
kubectl describe rs <replicaset-name>

# ステップ3: Podの状態確認
kubectl get pods -l app=nginx
kubectl describe pod <pod-name>

# ステップ4: イベントの確認
kubectl get events --sort-by='.lastTimestamp' | grep nginx

# ステップ5: ログの確認
kubectl logs <pod-name>
kubectl logs <pod-name> --previous  # 前のコンテナのログ

# ステップ6: ロールアウト履歴
kubectl rollout history deployment/nginx-deployment
kubectl rollout history deployment/nginx-deployment --revision=2

# ステップ7: デプロイの進行状況
kubectl rollout status deployment/nginx-deployment

# ステップ8: 必要に応じてロールバック
kubectl rollout undo deployment/nginx-deployment
```

## まとめ

本記事では、Kubernetesの Deployment を使った安全なデプロイ方法について、以下の内容を学習しました：

### 学んだこと

1. **DeploymentとReplicaSetの関係**
   - Deploymentは内部的にReplicaSetを管理
   - 宣言的な管理により、望ましい状態を定義するだけでOK
   - 履歴管理とロールバック機能

2. **デプロイ戦略**
   - ローリングアップデート（ゼロダウンタイム）
   - Recreate（ダウンタイムあり）
   - Blue/GreenとCanaryの概要

3. **ローリングアップデートの実践**
   - YAMLマニフェストの詳細な書き方
   - kubectl コマンドでのイメージ更新
   - maxSurge/maxUnavailableの詳細な制御

4. **デプロイ履歴とロールバック**
   - kubectl rollout history での履歴確認
   - アノテーションでの変更理由記録
   - 簡単で高速なロールバック
   - 特定リビジョンへのロールバック

5. **実践的なシナリオ**
   - nginx のバージョンアップ実演
   - 失敗したデプロイのロールバック
   - デプロイの一時停止と再開

6. **高度な設定**
   - minReadySeconds（準備完了待機時間）
   - progressDeadlineSeconds（タイムアウト）
   - revisionHistoryLimit（履歴保持数）

7. **つまづきやすいポイント**
   - Readiness Probeの重要性
   - maxSurge/maxUnavailableの設定ミス
   - latestタグの問題
   - ロールバック後のマニフェスト不一致

### 重要なポイント

- **常にReadiness Probeを設定する**: トラフィック喪失を防ぐ
- **明示的なバージョンタグを使用**: latestは避ける
- **マニフェストをGit管理**: 再現性と追跡性を確保
- **適切なmaxSurge/maxUnavailableを設定**: 速度と安全性のバランス
- **デプロイ前にdry-runで確認**: `kubectl apply --dry-run=client -f deployment.yaml`

### 次のステップ

次回の記事「Serviceで実現する負荷分散 - トラフィック管理の基礎」では、以下を学習します：

- Serviceによるサービスディスカバリ
- ClusterIP、NodePort、LoadBalancerの違い
- Deploymentと Serviceの連携
- 負荷分散の仕組み
- Endpointsリソースの理解

ぜひ、実際に手を動かして、Deploymentによる安全なデプロイを体験してください！

## 参考リンク

- {{< linkcard "https://kubernetes.io/docs/concepts/workloads/controllers/deployment/" >}}
- {{< linkcard "https://kubernetes.io/docs/tutorials/kubernetes-basics/update/update-intro/" >}}
- {{< linkcard "https://kubernetes.io/docs/concepts/workloads/controllers/replicaset/" >}}
- {{< linkcard "https://kubernetes.io/docs/reference/kubectl/cheatsheet/" >}}
