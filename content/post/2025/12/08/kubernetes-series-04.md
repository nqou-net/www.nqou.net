---
title: "Kubernetesを完全に理解した（第4回）- Deploymentでゼロダウンタイム更新"
draft: true
tags:
- kubernetes
- deployment
- rolling-update
- rollback
- versioning
description: "ダウンタイムゼロでアプリケーションをアップデートするDeploymentの使い方。失敗しても簡単にロールバックできる安全性を体感します。"
---

## 導入 - 第3回の振り返りと第4回で学ぶこと

前回の記事では、**ReplicaSet**を使って複数のPodレプリカを維持し、自動復旧を実現する方法を学びました。

**第3回のおさらい:**

- Pod単体の限界（自動復旧しない、単一障害点）
- ReplicaSetによる自動復旧とスケーリング
- Desired StateとReconciliation Loopの仕組み
- ラベルとセレクタによるPod選択
- レプリカ数の管理（YAMLマニフェストとscaleコマンド）

しかし、ReplicaSetには重大な制限があります。それは、**アプリケーションのバージョンアップが難しい**という点です。

実際に試してみると、こんな問題が発生します：

```bash
# ReplicaSetのイメージバージョンを変更
kubectl set image rs/nginx-replicaset nginx=nginx:1.26

# Podを確認
kubectl get pods -o wide
# 出力: Podは古いイメージのまま！新しいイメージに更新されない！
```

**なぜこうなるのか？**

ReplicaSetは「指定した数のPodを維持する」ことだけが仕事です。既存のPodが健全に動作している限り、ReplicaSetはそれらを削除しません。全てのPodを手動で削除すれば新しいイメージで再作成されますが、**その間サービスが停止してしまいます**。

第4回となる本記事では、この問題を解決する**Deployment**について学習します。

**この記事で学ぶこと:**

- DeploymentとReplicaSetの関係（なぜDeploymentが必要か）
- ローリングアップデート戦略（ゼロダウンタイムでのバージョンアップ）
- ローリングアップデートの実践（nginx 1.19から1.20への更新）
- デプロイ履歴の管理とロールバック（失敗したデプロイから復旧）
- 高度な設定（minReadySeconds、progressDeadlineSecondsなど）
- Recreate戦略とBlue/Greenデプロイの概要

それでは、Deploymentによる安全で確実なアプリケーション更新を体験していきましょう！

## DeploymentとReplicaSetの関係 - なぜDeploymentが必要か

### ReplicaSetの限界を再確認

前回学んだReplicaSetは、指定した数のPodレプリカを維持する責任を持っています。しかし、**アプリケーションの更新**という観点では重大な制限があります。

実際に試してみましょう：

```bash
# シンプルなReplicaSetを作成
cat > simple-replicaset.yaml << 'EOF'
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
        image: nginx:1.25-alpine
        ports:
        - containerPort: 80
EOF

# デプロイ
kubectl apply -f simple-replicaset.yaml

# Pod確認
kubectl get pods -o wide
# NAME                      READY   STATUS    RESTARTS   AGE   IMAGE
# nginx-replicaset-abc12    1/1     Running   0          10s   nginx:1.25-alpine
# nginx-replicaset-def34    1/1     Running   0          10s   nginx:1.25-alpine
# nginx-replicaset-ghi56    1/1     Running   0          10s   nginx:1.25-alpine
```

ここで、イメージバージョンを1.25から1.26に更新してみます：

```bash
# イメージバージョンを更新
kubectl set image rs/nginx-replicaset nginx=nginx:1.26-alpine

# 実際のPodを確認
kubectl get pods -o wide
# NAME                      READY   STATUS    RESTARTS   AGE   IMAGE
# nginx-replicaset-abc12    1/1     Running   0          2m    nginx:1.25-alpine ← 古いまま！
# nginx-replicaset-def34    1/1     Running   0          2m    nginx:1.25-alpine ← 古いまま！
# nginx-replicaset-ghi56    1/1     Running   0          2m    nginx:1.25-alpine ← 古いまま！

# 驚くべきことに、Podは古いイメージのまま！
```

**なぜこうなるのか？**

ReplicaSetは既存のPodが健全に動作している限り、それらを削除しません。ReplicaSet specが更新されても、既存のPodには影響しないのです。

```bash
# Podを手動で1つ削除してみる
kubectl delete pod nginx-replicaset-abc12

# 新しいPodが作成される
kubectl get pods -o wide
# NAME                      READY   STATUS    RESTARTS   AGE   IMAGE
# nginx-replicaset-xyz89    1/1     Running   0          5s    nginx:1.26-alpine ← 新イメージ！
# nginx-replicaset-def34    1/1     Running   0          3m    nginx:1.25-alpine ← 古いまま
# nginx-replicaset-ghi56    1/1     Running   0          3m    nginx:1.25-alpine ← 古いまま

# 全てのPodを更新するには、全て手動で削除する必要がある
# これはダウンタイムが発生し、本番環境では使えない！

# クリーンアップ
kubectl delete rs nginx-replicaset
```

### Deploymentの登場 - 宣言的なアップデート管理

Deploymentは、ReplicaSetの上位レベルの抽象化を提供し、アプリケーションのデプロイメントとアップデートを宣言的に管理します。

**Deploymentの階層構造:**

```
Deployment
  ├─ ReplicaSet (新バージョン) ← Deploymentが自動管理
  │   ├─ Pod (nginx:1.26)
  │   ├─ Pod (nginx:1.26)
  │   └─ Pod (nginx:1.26)
  └─ ReplicaSet (旧バージョン) ← 履歴として保持（ロールバック用）
      └─ (レプリカ数: 0)
```

Deploymentは内部的にReplicaSetを作成・管理します。アプリケーションを更新すると、Deploymentは新しいReplicaSetを作成し、古いPodから新しいPodへ段階的に切り替えていきます。

### ReplicaSet vs Deployment 比較表

| 機能 | ReplicaSet単独 | Deployment |
|-----|--------------|------------|
| レプリカ数の維持 | ✅ | ✅ |
| ローリングアップデート | ❌ 手動で全Pod削除が必要 | ✅ 自動 |
| ロールバック | ❌ 不可能 | ✅ 簡単に前のバージョンに戻せる |
| デプロイ履歴管理 | ❌ | ✅ revision履歴を保持 |
| デプロイの一時停止/再開 | ❌ | ✅ |
| 段階的ロールアウト | ❌ | ✅ maxSurge/maxUnavailableで制御 |

**結論**: 本番環境では、**常にDeploymentを使うべきです**。直接ReplicaSetを作成することは、ほとんどありません。

### 宣言的な管理の利点

Deploymentを使うことで、「望ましい状態」を宣言するだけで、Kubernetesがその状態を実現してくれます。

```bash
# 宣言的アプローチ（推奨）
# deployment.yaml に望ましい状態を記述
kubectl apply -f deployment.yaml
# 利点: 現在の状態が明確、Git管理可能、再現性がある

# Gitによるバージョン管理
git add deployment.yaml
git commit -m "Update nginx to version 1.26, scale to 5 replicas"
git push

# 履歴を確認
git log --oneline deployment.yaml
```

これにより、インフラのバージョン管理が可能になり、チーム全体で安全にアプリケーションを管理できます。

## バージョンアップ戦略 - ローリングアップデートとRecreate

Deploymentには、アプリケーションを更新する際の戦略が用意されています。主な戦略は2つです：**RollingUpdate**（ローリングアップデート）と**Recreate**です。

### ローリングアップデート（デフォルト、ゼロダウンタイム）

ローリングアップデートは、古いバージョンのPodを段階的に新しいバージョンに置き換えていく戦略です。これが**Deploymentのデフォルト戦略**です。

**動作の流れ:**

```
初期状態: nginx:1.25 のPodが3つ
[Pod-A:1.25] [Pod-B:1.25] [Pod-C:1.25]

ステップ1: 新しいPodを1つ作成
[Pod-A:1.25] [Pod-B:1.25] [Pod-C:1.25] [Pod-D:1.26] ← 新規作成中

ステップ2: 新しいPodがReady、古いPodを1つ削除
[Pod-B:1.25] [Pod-C:1.25] [Pod-D:1.26] ← Pod-A削除

ステップ3: さらに新しいPodを1つ作成
[Pod-B:1.25] [Pod-C:1.25] [Pod-D:1.26] [Pod-E:1.26] ← 新規作成中

...繰り返し...

完了状態:
[Pod-D:1.26] [Pod-E:1.26] [Pod-F:1.26]

常に最低2つのPodが稼働 → ゼロダウンタイム！
```

**メリット:**

- ✅ ゼロダウンタイムでアップデート可能
- ✅ リスクを分散（段階的にロールアウト）
- ✅ 問題発見時に即座にロールバック可能

**デメリット:**

- ⚠️ アップデート中は新旧バージョンが混在
- ⚠️ データベーススキーマ変更など、後方互換性が必要

### Recreate戦略（ダウンタイムあり）

Recreate戦略は、全ての古いPodを一度に削除してから、新しいPodを作成する方法です。

```yaml
# deployment-recreate.yaml
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
        image: nginx:1.25-alpine
        ports:
        - containerPort: 80
```

**動作の流れ:**

```
初期状態: nginx:1.25 のPodが3つ
[Pod-A:1.25] [Pod-B:1.25] [Pod-C:1.25]

ステップ1: 全てのPodを一度に削除
[削除中...] [削除中...] [削除中...]

ステップ2: この間サービス停止 ← ダウンタイム発生！

ステップ3: 新しいPodを3つ作成
[Pod-D:1.26] [Pod-E:1.26] [Pod-F:1.26]
```

**メリット:**

- ✅ 新旧バージョンの混在がない
- ✅ データベーススキーマの非互換な変更に対応可能
- ✅ シンプルでわかりやすい

**デメリット:**

- ❌ ダウンタイムが発生する

**使用ケース:**

- 開発環境やステージング環境
- 後方互換性のない大幅な変更
- 短時間のメンテナンスウィンドウが許容される場合

### その他の戦略（概要）

実際の本番環境では、さらに高度な戦略も使われます：

**Blue/Greenデプロイメント:**

Blue（現行環境）とGreen（新環境）の2つの完全な環境を用意し、トラフィックを一度に切り替える方式です。

- ✅ 瞬時にトラフィック切り替え可能
- ✅ 瞬時にロールバック可能
- ❌ リソースが2倍必要（コスト増）

**Canaryデプロイメント:**

新バージョンを一部のユーザー（例: 10%）にだけ公開し、問題がなければ徐々に割合を増やしていく方式です。

- ✅ リスクを最小化（影響範囲を限定）
- ✅ 本番環境で少数のユーザーでテスト可能

これらの高度な戦略は、Service MeshやIngress Controllerを使って実装します。詳細は別の回で解説します。

## ローリングアップデートの実践 - YAMLマニフェストとmaxSurge/maxUnavailable

ここからは、最も一般的なローリングアップデートを実際に手を動かして学びます。

### 基本的なDeploymentマニフェスト

まず、シンプルなDeploymentを作成します：

```yaml
# nginx-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
  labels:
    app: nginx
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
        image: nginx:1.25-alpine
        ports:
        - containerPort: 80
```

このマニフェストをデプロイしてみましょう：

```bash
# Deploymentのデプロイ
kubectl apply -f nginx-deployment.yaml

# Deployment、ReplicaSet、Podの関係を確認
kubectl get deployments
# NAME               READY   UP-TO-DATE   AVAILABLE   AGE
# nginx-deployment   3/3     3            3           10s

kubectl get rs
# NAME                          DESIRED   CURRENT   READY   AGE
# nginx-deployment-56db8d64f7   3         3         3       15s
#                   ^^^^^^^^^^
#                   Pod template hash (自動生成)

kubectl get pods
# NAME                                READY   STATUS    RESTARTS   AGE
# nginx-deployment-56db8d64f7-abc12   1/1     Running   0          20s
# nginx-deployment-56db8d64f7-def34   1/1     Running   0          20s
# nginx-deployment-56db8d64f7-ghi56   1/1     Running   0          20s
```

注目すべき点：

- DeploymentがReplicaSetを自動的に作成
- ReplicaSet名には「Pod template hash」が自動付与される
- Pod名にはReplicaSet名が含まれる

### maxSurgeとmaxUnavailableパラメータ

ローリングアップデートの挙動を細かく制御するパラメータが、**maxSurge**と**maxUnavailable**です。

```yaml
# nginx-deployment-advanced.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
  annotations:
    kubernetes.io/change-cause: "Initial deployment with nginx 1.25"
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
        
        readinessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 5
          periodSeconds: 5
```

**各フィールドの詳細説明:**

**maxSurge（最大増加数）:**

- 「最大でいくつ余分にPodを作成してよいか」
- 数値（例: `1`）または割合（例: `25%`）で指定
- `replicas: 3, maxSurge: 1` の場合、アップデート中は最大4 Podまで存在可能

**maxUnavailable（最大利用不可数）:**

- 「最大でいくつPodが利用不可になってもよいか」
- `replicas: 3, maxUnavailable: 1` の場合、最低2 Podは常に稼働

**設定パターンの比較:**

| パターン | maxSurge | maxUnavailable | 特徴 |
|---------|----------|----------------|------|
| 高速デプロイ | 100% | 100% | 最も速いが、リソース使用量が2倍、ダウンタイムあり |
| バランス型 | 25% | 25% | デフォルト。速度とリソースのバランス |
| 安全重視 | 1 | 0 | 常に全Podが稼働。最も安全だが遅い |
| リソース節約 | 0 | 1 | 余分なリソース不要だが、一時的にキャパシティ減 |

**重要な制約:**

両方を同時に0には設定できません：

```yaml
# これはエラーになる！
strategy:
  rollingUpdate:
    maxSurge: 0
    maxUnavailable: 0  # ← NG!
```

理由：両方が0だと、新しいPodも作れず、古いPodも削除できず、アップデートが進行不可能になります。

### readinessProbeの重要性

上記のマニフェストには`readinessProbe`が含まれています。これは**極めて重要**です。

Readiness Probeがないと、Podは起動した瞬間に「Ready」と判断され、アプリケーションの初期化が完了していなくてもトラフィックが流れてしまいます。これにより、エラーレスポンスが返る可能性があります。

Readiness Probeを設定することで：

- アプリケーションが実際にリクエストを処理できる状態になってからトラフィックを受け入れる
- ローリングアップデート中に、新しいPodがReadyになってから古いPodを削除する
- ゼロダウンタイムを実現

## 実際のアップデートを体験 - nginx:1.25から1.26への更新

ここからは、実際にアプリケーションのバージョンアップを体験します。

### ステップ1: 初期デプロイ

まず、nginx 1.25をデプロイします：

```bash
# マニフェストを作成
cat > nginx-demo.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-demo
  annotations:
    kubernetes.io/change-cause: "Initial deployment - nginx 1.25"
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
        version: v1.25
    spec:
      containers:
      - name: nginx
        image: nginx:1.25-alpine
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
EOF

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

### ステップ2: Serviceを作成してアクセス確認

実際のサービスとして動作させるため、Serviceを作成します：

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

# アクセステスト（別ターミナルで実行して、継続的にアクセス）
while true; do 
  curl -s http://192.168.49.2:30123 | grep -o "<title>.*</title>" && sleep 1
done
# <title>Welcome to nginx!</title>
# <title>Welcome to nginx!</title>
# ...（継続的にアクセス成功）
```

### ステップ3: イメージを1.26にアップデート

それでは、nginx 1.26にアップデートします：

```bash
# 新しいターミナルを開いて、Podの状態を監視
kubectl get pods -l app=nginx-demo -w

# 別のターミナルでアップデート実行
kubectl set image deployment/nginx-demo nginx=nginx:1.26-alpine

kubectl annotate deployment/nginx-demo \
  kubernetes.io/change-cause="Update to nginx 1.26 for new features"

# デプロイ状況を監視
kubectl rollout status deployment/nginx-demo
# Waiting for deployment "nginx-demo" rollout to finish: 1 out of 5 new replicas have been updated...
# Waiting for deployment "nginx-demo" rollout to finish: 2 out of 5 new replicas have been updated...
# Waiting for deployment "nginx-demo" rollout to finish: 3 out of 5 new replicas have been updated...
# Waiting for deployment "nginx-demo" rollout to finish: 4 out of 5 new replicas have been updated...
# Waiting for deployment "nginx-demo" rollout to finish: 1 old replicas are pending termination...
# deployment "nginx-demo" successfully rolled out
```

### ステップ4: アップデート中のPod状態変化を観察

監視していたターミナルの出力を見ると、以下のような状態変化が観察できます：

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
nginx-demo-9e3f0eg0f8-yzab2   1/1     Running   0          5s

# 次の古いPodを削除
nginx-demo-7b8c9d5f6b-efgh2   1/1     Terminating   0          2m

# ...以下繰り返し...

# 最終的に全てのPodが新しいバージョンに
nginx-demo-9e3f0eg0f8-uvwx1   1/1     Running   0          45s
nginx-demo-9e3f0eg0f8-yzab2   1/1     Running   0          40s
nginx-demo-9e3f0eg0f8-cdef3   1/1     Running   0          35s
nginx-demo-9e3f0eg0f8-ghij4   1/1     Running   0          30s
nginx-demo-9e3f0eg0f8-klmn5   1/1     Running   0          25s
```

**重要な観察ポイント:**

- アップデート中、Pod数は4～6の間で変動（replicas: 5, maxSurge: 1, maxUnavailable: 1）
- 新しいPodは必ずReadiness Probeを通過してから古いPodが削除される
- アクセステストは一度も失敗しない（**ゼロダウンタイム！**）

### ステップ5: ReplicaSetの状態確認

アップデート完了後、ReplicaSetの状態を確認します：

```bash
kubectl get rs -l app=nginx-demo
# NAME                    DESIRED   CURRENT   READY   AGE
# nginx-demo-7b8c9d5f6b   0         0         0       5m   ← v1.25（レプリカ0）
# nginx-demo-9e3f0eg0f8   5         5         5       2m   ← v1.26（レプリカ5）
```

古いReplicaSetはレプリカ数が0になりましたが、**削除されずに残っています**。これがロールバックを可能にする仕組みです。

### ステップ6: 履歴確認

```bash
kubectl rollout history deployment/nginx-demo
# REVISION  CHANGE-CAUSE
# 1         Initial deployment - nginx 1.25
# 2         Update to nginx 1.26 for new features
```

アップデートの履歴が記録されています。`kubernetes.io/change-cause`アノテーションに記録した内容が表示されます。

## デプロイ履歴とロールバック - 失敗したデプロイから復旧

Deploymentの最も強力な機能の1つが、**簡単にロールバックできる**ことです。

### シナリオ: 壊れたイメージでデプロイしてロールバック

意図的に存在しないイメージタグをデプロイし、ロールバックを体験してみましょう：

```bash
# 1. 存在しないイメージをデプロイ
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
# ...（繰り返し、Readyにならない）
```

**重要なポイント:**

新しいPodがReadyにならないため、古いPodは削除されず、**サービスは継続しています**！

アクセステストしているターミナルでは、引き続きnginxにアクセスできているはずです。

```bash
# 3. サービスが継続していることを確認
# （アクセステストのターミナルを見ると、まだ成功し続けている）

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
#   Warning  Failed     1m (x4 over 2m)    kubelet            Failed to pull image "nginx:broken-nonexistent-tag"
#   Warning  Failed     1m (x4 over 2m)    kubelet            Error: ErrImagePull
```

### ロールバックの実行

それでは、ロールバックを実行します：

```bash
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
# 1         Initial deployment - nginx 1.25
# 3         Broken deployment - testing rollback
# 4         Update to nginx 1.26 for new features  ← リビジョン2が4として復活
```

**学んだこと:**

- 失敗したデプロイでも、サービスは継続する
- Readiness Probeが正しく設定されていれば、壊れたPodにトラフィックは流れない
- ロールバックは簡単で高速
- ロールバック自体が新しいリビジョンとして記録される

### 特定リビジョンへのロールバック

直前のバージョンではなく、特定のリビジョンに戻すこともできます：

```bash
# リビジョン1（初期デプロイ）に戻る
kubectl rollout undo deployment/nginx-demo --to-revision=1

# 確認
kubectl describe deployment nginx-demo | grep Image
#   Image:        nginx:1.25-alpine

kubectl rollout history deployment/nginx-demo
# REVISION  CHANGE-CAUSE
# 3         Broken deployment - testing rollback
# 4         Update to nginx 1.26 for new features
# 5         Initial deployment - nginx 1.25  ← リビジョン1が5として復活
```

### デプロイの一時停止と再開

複数の変更を一度にデプロイしたい場合、デプロイを一時停止して複数の変更を適用してから再開できます：

```bash
# 1. デプロイを一時停止
kubectl rollout pause deployment/nginx-demo

# 2. 複数の変更を適用
kubectl set image deployment/nginx-demo nginx=nginx:1.26-alpine
kubectl set resources deployment/nginx-demo -c nginx \
  --requests=cpu=100m,memory=64Mi \
  --limits=cpu=200m,memory=128Mi
kubectl scale deployment/nginx-demo --replicas=7

# 3. この時点ではまだ変更は適用されていない
kubectl get pods -l app=nginx-demo --watch-only=false
# まだ5つのPodのまま

# 4. デプロイを再開
kubectl rollout resume deployment/nginx-demo

# 5. 一度に全ての変更が適用される
kubectl rollout status deployment/nginx-demo
# deployment "nginx-demo" successfully rolled out

kubectl get deployment nginx-demo
# NAME         READY   UP-TO-DATE   AVAILABLE   AGE
# nginx-demo   7/7     7            7           15m
```

**メリット:**

- 複数の変更を1つのリビジョンとして記録できる
- ローリングアップデートが1回だけ実行される（効率的）
- 途中で設定を確認・修正できる

## 高度な設定 - minReadySeconds、progressDeadlineSecondsなど

Deploymentには、より細かい制御を可能にする設定があります。

### minReadySeconds（準備完了待機時間）

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
        image: nginx:1.26-alpine
        readinessProbe:
          httpGet:
            path: /
            port: 80
          periodSeconds: 5
```

**用途:**

- アプリケーションの起動後のウォームアップ時間を確保
- メモリリークなどの遅延障害を検出
- より安全なデプロイ（各Podを十分に観察してから次に進む）

### progressDeadlineSeconds（デプロイタイムアウト）

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
        image: nginx:1.26-alpine
```

**デフォルト値**: 600秒（10分）

**タイムアウトになる条件:**

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
```

### revisionHistoryLimit（履歴保持数）

保持するReplicaSetの履歴数を制御します。

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
        image: nginx:1.26-alpine
```

**デフォルト値**: 10

**推奨値:**

- 開発環境: 3～5（ディスク容量節約）
- 本番環境: 10～15（十分なロールバック履歴）

### 完全な高度設定の例

```yaml
# nginx-deployment-production.yaml
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
        version: v1.26
    spec:
      containers:
      - name: nginx
        image: nginx:1.26-alpine
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
          initialDelaySeconds: 30
          periodSeconds: 10
          timeoutSeconds: 5
          failureThreshold: 3
        
        # Readiness Probe
        readinessProbe:
          httpGet:
            path: /
            port: http
          initialDelaySeconds: 5
          periodSeconds: 5
          timeoutSeconds: 3
          successThreshold: 2
          failureThreshold: 2
        
        # Lifecycle hooks
        lifecycle:
          preStop:
            exec:
              command: ["/bin/sh", "-c", "sleep 15"]
```

この設定は本番環境を想定した、安全性とパフォーマンスのバランスが取れた構成です。

## まとめと次回予告

本記事では、Kubernetesの**Deployment**を使った安全なデプロイ方法について、以下の内容を学習しました：

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
   - kubectlコマンドでのイメージ更新
   - maxSurge/maxUnavailableの詳細な制御

4. **デプロイ履歴とロールバック**
   - kubectl rollout historyでの履歴確認
   - アノテーションでの変更理由記録
   - 簡単で高速なロールバック
   - 特定リビジョンへのロールバック

5. **実践的なシナリオ**
   - nginx 1.25から1.26へのバージョンアップ実演
   - 失敗したデプロイのロールバック
   - デプロイの一時停止と再開

6. **高度な設定**
   - minReadySeconds（準備完了待機時間）
   - progressDeadlineSeconds（タイムアウト）
   - revisionHistoryLimit（履歴保持数）

### 重要なポイント

- **常にReadiness Probeを設定する**: トラフィック喪失を防ぐ
- **明示的なバージョンタグを使用**: `latest`は避ける
- **マニフェストをGit管理**: 再現性と追跡性を確保
- **適切なmaxSurge/maxUnavailableを設定**: 速度と安全性のバランス
- **デプロイ前にdry-runで確認**: `kubectl apply --dry-run=client -f deployment.yaml`

### 次回予告 - 第5回「Serviceで実現する負荷分散」

次回は、**Service**について学習します。

Deploymentで複数のPodを動かせるようになりましたが、これらのPodにどうやってアクセスすればよいのでしょうか？Pod IPは動的に変わるため、直接アクセスするのは困難です。

第5回では、以下を学習します：

- Serviceによるサービスディスカバリ
- ClusterIP、NodePort、LoadBalancerの違い
- DeploymentとServiceの連携
- 負荷分散の仕組み
- Endpointsリソースの理解
- DNS名でのアクセス

Deploymentと組み合わせることで、本番環境で実用的なアプリケーションデプロイが可能になります。

ぜひ、実際に手を動かして、Deploymentによる安全なデプロイを体験してください！

## クリーンアップ

実験で作成したリソースをクリーンアップしましょう：

```bash
# Deploymentを削除（関連するReplicaSetとPodも自動削除される）
kubectl delete deployment nginx-demo

# Serviceを削除
kubectl delete service nginx-demo

# 確認
kubectl get deployments
kubectl get pods
kubectl get services
```

Deploymentを削除すると、関連するReplicaSetとPodも自動的に削除されます。これがDeploymentによる宣言的管理の利点です。
