---
title: "Kubernetesを完全に理解した（第3回）- ReplicaSetで実現する自動復旧"
draft: true
tags:
- kubernetes
- replicaset
- high-availability
- self-healing
- labels
description: "単一障害点を解消するReplicaSetの仕組みを学習。Podを手動で削除しても自動復旧する様子を実際に体験します。"
---

## 導入 - 第2回の振り返りと第3回で学ぶこと

前回の記事では、Kubernetesの最小単位である**Pod**について徹底的に学びました。

**第2回のおさらい:**

- PodとコンテナとDockerの違い
- Podのライフサイクルとフェーズ遷移
- kubectlコマンドの実践的な使い方
- YAMLマニフェストの段階的な書き方
- 障害時の挙動とトラブルシューティング

しかし、実際に手を動かした方はこんな疑問を持ったかもしれません：

「**Podを削除したら二度と復活しないのでは?**」
「**本番環境でPodがクラッシュしたら、手動で再作成するの?**」

そうです。**Pod単体では、自動復旧してくれません**。これが本番環境で致命的な問題になります。

第3回となる本記事では、この問題を解決する**ReplicaSet**について学習します。

**この記事で学ぶこと:**

- なぜPod単体では不十分なのか（実験で体感）
- ReplicaSetの仕組み（Desired StateとReconciliation Loop）
- レプリカ数の管理（YAMLマニフェストとscaleコマンド）
- 自動復旧を体験する（Pod削除とクラッシュからの回復）
- ラベルとセレクタの使い方（Podを選択する仕組み）
- ReplicaSetの制限（なぜDeploymentが必要か）

それでは、ReplicaSetの世界へ深く潜っていきましょう！

## なぜPod単体では不十分なのか - 実験で問題を体感

### 実験: Podを削除したら何が起こる?

まずは実験してみましょう。シンプルなnginx Podを作成し、削除してみます。

```bash
# シンプルなNginx Podを作成
kubectl run single-nginx --image=nginx:1.25-alpine

# Podが起動したことを確認
kubectl get pods
# NAME            READY   STATUS    RESTARTS   AGE
# single-nginx    1/1     Running   0          5s

# Podの詳細情報を確認
kubectl get pod single-nginx -o wide
# NAME            READY   STATUS    IP           NODE
# single-nginx    1/1     Running   10.244.0.5   minikube
```

ここで、このPodを削除してみます。

```bash
# Podを削除
kubectl delete pod single-nginx

# すぐに状態確認
kubectl get pods
# No resources found in default namespace.
```

**結果**: Podは削除され、**二度と復活しません**。

### この挙動の何が問題なのか?

想像してみてください。本番環境でこのような状況が発生したら：

```bash
# 本番環境でのシナリオ:
# 
# 1. 午前2時: アプリケーションのバグでコンテナがクラッシュ
# 2. Podが削除される
# 3. 新しいPodは自動作成されない
# 4. サービスが完全停止 ← ユーザーはアクセスできない！
# 5. 午前8時: 担当者が出社して気づく
# 6. 手動でPodを再作成
# 7. 復旧完了
# 
# ダウンタイム: 6時間 ← これは許されない！
```

この問題には専門用語があります：**単一障害点（SPOF: Single Point of Failure）**です。

### 単一障害点（SPOF）の具体的なリスク

SPOFとは、システム全体の可用性が単一のコンポーネントに依存している状態です。Pod単体で運用すると、以下のリスクがあります。

#### リスク1: ハードウェア障害

```bash
# 想定シナリオ: ノード障害
# 
# [Before]
# Node1: single-nginx Pod (Running)
# 
# [Event] Node1がハードウェア障害でダウン
# 
# [After]
# Node1: ダウン (Pod消失)
# サービス: 完全停止
# 復旧: 人間がNode復旧 or 手動でPod再作成が必要
```

#### リスク2: アプリケーションのクラッシュ

```bash
# OOM (Out of Memory) Killerの例
kubectl run memory-hog --image=nginx:1.25-alpine \
  --limits=memory=50Mi

# Pod内でメモリを大量消費させる
kubectl exec memory-hog -- sh -c '
  dd if=/dev/zero of=/tmp/big bs=1M count=100
'

# 結果を確認
kubectl get pods
# NAME         READY   STATUS      RESTARTS   AGE
# memory-hog   0/1     OOMKilled   0          10s

# しばらく待っても...
kubectl get pods
# NAME         READY   STATUS      RESTARTS   AGE
# memory-hog   0/1     OOMKilled   0          2m
# ↑ クラッシュしたまま、自動復旧しない
```

#### リスク3: 人為的ミスによる削除

```bash
# 開発者が誤ってPodを削除
kubectl delete pod single-nginx

# 「あれ、このPod、なんでないの?」
# 「誰か削除した?」
# 「手動で作り直すか...」
# ← この間、サービスはダウン
```

### 手動管理の限界

Pod単体を手動で管理する場合、こんな面倒な作業が必要になります：

```bash
# 課題1: スケーリングが手作業
# トラフィックが増えたら...
kubectl run nginx-1 --image=nginx:1.25-alpine
kubectl run nginx-2 --image=nginx:1.25-alpine
kubectl run nginx-3 --image=nginx:1.25-alpine
# ↑ 1つずつ手動で増やす（非現実的）

# 課題2: 障害検知と復旧が手作業
# 1. 監視システムからアラート受信
# 2. kubectl get podsで状態確認
# 3. 問題のPodを特定
# 4. kubectl delete pod <name> で削除
# 5. kubectl run で再作成
# ↑ 深夜3時にこれをやりたいですか？

# 課題3: バージョン管理が困難
# Pod1: nginx:1.24
# Pod2: nginx:1.25  ← バージョンバラバラ
# Pod3: nginx:1.23
# ↑ どれが正しいバージョン？
```

**結論**: Pod単体では、Kubernetesの強力な機能（自動復旧、スケーリング、ローリングアップデート）を一切利用できません。これでは従来の手動運用と変わりません。

では、どうすればいいのでしょうか? その答えが**ReplicaSet**です。

## ReplicaSetの仕組み - Desired StateとReconciliation Loop

### ReplicaSetとは何か

**ReplicaSet**は、指定した数のPodレプリカを常に維持するKubernetesコントローラーです。

簡単に言えば：**「常に指定した数のPodが動いている状態を保証してくれる番人」**です。

```yaml
# replicaset-nginx.yaml
apiVersion: apps/v1
kind: ReplicaSet
metadata:
  name: nginx-replicaset
  labels:
    app: nginx
spec:
  replicas: 3  # ← 常に3つのPodを維持
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

#### ReplicaSetの3つの重要な要素

| 要素 | 役割 | 設定場所 |
|------|------|---------|
| **replicas** | 維持すべきPod数 | `spec.replicas` |
| **selector** | 管理対象Podの選択条件 | `spec.selector` |
| **template** | Podの設計図（テンプレート） | `spec.template` |

### Desired State（期待状態）の概念

Kubernetesの根幹を成す重要な概念があります：**Desired State（期待状態）**です。

```
Desired State (期待状態)
  ↓
  ユーザーが宣言した「あるべき姿」
  例: replicas: 3 → 「常に3つのPodが動いているべき」
  
Current State (現在状態)
  ↓
  クラスタ内の実際の状態
  例: 実際に動いているPodは2つ
  
Kubernetesの仕事
  ↓
  Current StateをDesired Stateに一致させること
```

#### 状態の不一致が発生する例

```bash
# Desired State: replicas=3
# Current State: Podが2つ

# なぜ不一致?
# 理由1: Podが1つクラッシュした
# 理由2: 誰かがPodを削除した
# 理由3: ノードがダウンしてPodが消えた

# Kubernetesの対応
# → 自動的にPodを1つ作成してDesired Stateに戻す
```

この「現在の状態を期待する状態に合わせる」仕組みを**Reconciliation Loop（調整ループ）**と呼びます。

### Reconciliation Loop（調整ループ）の動作

**Reconciliation Loop**は、コントローラーが継続的に状態を監視・調整する仕組みです。

擬似コードで理解してみましょう：

```python
# ReplicaSet Controllerの動作（擬似コード）

def reconciliation_loop():
    while True:
        # 1. 現在の状態を取得
        desired_replicas = replicaset.spec.replicas
        current_pods = get_pods_matching_selector(
            replicaset.spec.selector
        )
        current_count = len(current_pods)
        
        # 2. 差分を計算
        diff = desired_replicas - current_count
        
        # 3. 調整アクションを実行
        if diff > 0:
            # Podが足りない → 作成
            for i in range(diff):
                create_pod_from_template(
                    replicaset.spec.template
                )
                log(f"Created pod {i+1}/{diff}")
        
        elif diff < 0:
            # Podが多すぎる → 削除
            pods_to_delete = current_pods[:abs(diff)]
            for pod in pods_to_delete:
                delete_pod(pod)
                log(f"Deleted pod {pod.name}")
        
        else:
            # 一致している → 何もしない
            log("Desired state achieved")
        
        # 4. 次の調整まで待機
        sleep(10)  # 10秒後に再チェック
```

#### 実際の動作フロー

```bash
# 1. ユーザーがReplicaSetを作成
kubectl apply -f replicaset-nginx.yaml

# 2. ReplicaSet Controllerが検知
# Controller: "新しいReplicaSetが作られた!"
# Controller: "Desired State = 3 Pods"

# 3. Current Stateを確認
# Controller: "現在のPod数は0"

# 4. 差分を解消
# Controller: "3つPodを作成する"

# 5. Podが作成される
kubectl get pods
# NAME                      READY   STATUS    RESTARTS   AGE
# nginx-replicaset-abc12    1/1     Running   0          5s
# nginx-replicaset-def34    1/1     Running   0          5s
# nginx-replicaset-ghi56    1/1     Running   0          5s
```

この仕組みが、Kubernetesの**自己修復能力（Self-Healing）**の正体です！

## レプリカ数の管理 - YAMLマニフェストとscaleコマンド

### ReplicaSet YAMLマニフェストの書き方

#### 最小構成のReplicaSet

```yaml
# replicaset-minimal.yaml
apiVersion: apps/v1        # ReplicaSetのAPIバージョン
kind: ReplicaSet           # リソースタイプ
metadata:
  name: nginx-rs           # ReplicaSet名
spec:
  replicas: 3              # レプリカ数
  selector:                # Pod選択条件
    matchLabels:
      app: nginx
  template:                # Podテンプレート
    metadata:
      labels:
        app: nginx         # selector.matchLabelsと一致必須
    spec:
      containers:
      - name: nginx
        image: nginx:1.25-alpine
```

#### リソース制限付きReplicaSet

本番環境では、リソース制限を設定することが**必須**です：

```yaml
# replicaset-with-resources.yaml
apiVersion: apps/v1
kind: ReplicaSet
metadata:
  name: nginx-rs-limits
  labels:
    tier: frontend
    version: v1
spec:
  replicas: 5
  selector:
    matchLabels:
      app: nginx
      tier: frontend
  template:
    metadata:
      labels:
        app: nginx
        tier: frontend
        version: v1
    spec:
      containers:
      - name: nginx
        image: nginx:1.25-alpine
        ports:
        - containerPort: 80
          name: http
        resources:
          requests:
            memory: "64Mi"
            cpu: "100m"
          limits:
            memory: "128Mi"
            cpu: "200m"
        livenessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 3
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /
            port: 80
          initialDelaySeconds: 3
          periodSeconds: 5
```

### kubectl apply でのReplicaSet作成

```bash
# ReplicaSetを作成
kubectl apply -f replicaset-nginx.yaml
# replicaset.apps/nginx-replicaset created

# 作成直後の状態確認
kubectl get replicaset
# NAME               DESIRED   CURRENT   READY   AGE
# nginx-replicaset   3         3         0       2s
# ↑ DESIREDとCURRENTが一致している

# Pod詳細を確認
kubectl get replicaset nginx-replicaset -o wide
# NAME               DESIRED   CURRENT   READY   AGE   CONTAINERS   IMAGES                 SELECTOR
# nginx-replicaset   3         3         3       10s   nginx        nginx:1.25-alpine      app=nginx

# 管理されているPodを確認
kubectl get pods -l app=nginx
# NAME                      READY   STATUS    RESTARTS   AGE
# nginx-replicaset-4fnvx    1/1     Running   0          15s
# nginx-replicaset-k8pwd    1/1     Running   0          15s
# nginx-replicaset-xm2lq    1/1     Running   0          15s
```

#### Pod名の命名規則

```bash
# ReplicaSetが作成するPod名
# 形式: <replicaset-name>-<random-5chars>
#
# 例:
# nginx-replicaset-4fnvx
# │                │
# │                └─ ランダムな5文字（一意性を保証）
# └─ ReplicaSet名

# Podの所有者を確認
kubectl get pod nginx-replicaset-4fnvx -o yaml | grep -A 5 ownerReferences
# ownerReferences:
# - apiVersion: apps/v1
#   blockOwnerDeletion: true
#   controller: true
#   kind: ReplicaSet
#   name: nginx-replicaset
```

### kubectl scale でのレプリカ数変更

#### スケールアウト（増やす）

```bash
# 3 → 5にスケールアウト
kubectl scale replicaset nginx-replicaset --replicas=5

# 即座に確認
kubectl get replicaset
# NAME               DESIRED   CURRENT   READY   AGE
# nginx-replicaset   5         5         3       1m
# ↑ DESIREDが5に変更された

# Podの増加を確認
kubectl get pods -l app=nginx
# NAME                      READY   STATUS              RESTARTS   AGE
# nginx-replicaset-4fnvx    1/1     Running             0          2m
# nginx-replicaset-k8pwd    1/1     Running             0          2m
# nginx-replicaset-xm2lq    1/1     Running             0          2m
# nginx-replicaset-np7rz    0/1     ContainerCreating   0          2s  ← 新規
# nginx-replicaset-qw3ty    0/1     ContainerCreating   0          2s  ← 新規
```

#### スケールイン（減らす）

```bash
# 5 → 2にスケールイン
kubectl scale replicaset nginx-replicaset --replicas=2

# Pod削除の様子を観察
kubectl get pods -l app=nginx --watch
# NAME                      READY   STATUS        RESTARTS   AGE
# nginx-replicaset-4fnvx    1/1     Running       0          3m
# nginx-replicaset-k8pwd    1/1     Running       0          3m
# nginx-replicaset-xm2lq    1/1     Terminating   0          3m  ← 削除中
# nginx-replicaset-np7rz    1/1     Terminating   0          1m  ← 削除中
# nginx-replicaset-qw3ty    1/1     Terminating   0          1m  ← 削除中
```

### kubectl edit での設定変更

```bash
# ReplicaSetをエディタで直接編集
kubectl edit replicaset nginx-replicaset

# エディタが開く（デフォルトはvi）
# spec.replicasを変更
# 例: replicas: 3 → replicas: 7

# 保存して終了(:wq)
# replicaset.apps/nginx-replicaset edited

# 変更が即座に反映される
kubectl get replicaset
# NAME               DESIRED   CURRENT   READY   AGE
# nginx-replicaset   7         7         5       5m
```

**推奨方法**: YAMLファイルを直接編集する方法

```bash
# 1. ファイルを編集
vim replicaset-nginx.yaml
# spec:
#   replicas: 10  # 3 → 10に変更

# 2. 変更を適用
kubectl apply -f replicaset-nginx.yaml
# replicaset.apps/nginx-replicaset configured

# 3. 確認
kubectl get pods -l app=nginx --watch
```

## 自動復旧を体験する - Pod削除とクラッシュからの回復

### Podを手動削除して自動復旧を確認

いよいよReplicaSetの真骨頂、**自動復旧**を体験しましょう！

```bash
# 監視用ターミナル（Terminal 1）
kubectl get pods -l app=nginx --watch

# 操作用ターミナル（Terminal 2）
# 現在のPod一覧を取得
kubectl get pods -l app=nginx
# NAME                      READY   STATUS    RESTARTS   AGE
# nginx-replicaset-4fnvx    1/1     Running   0          10m
# nginx-replicaset-k8pwd    1/1     Running   0          10m
# nginx-replicaset-xm2lq    1/1     Running   0          10m

# Podを1つ削除
kubectl delete pod nginx-replicaset-4fnvx

# Terminal 1で観察される内容
# NAME                      READY   STATUS        RESTARTS   AGE
# nginx-replicaset-4fnvx    1/1     Terminating   0          10m  ← 削除開始
# nginx-replicaset-vw8xy    0/1     Pending       0          0s   ← 即座に新規作成
# nginx-replicaset-vw8xy    0/1     ContainerCreating   0     0s
# nginx-replicaset-4fnvx    0/1     Terminating   0          10m  ← 削除完了
# nginx-replicaset-vw8xy    1/1     Running       0          3s   ← 新規Pod起動完了
```

**驚きのポイント**: Podが削除されると、**ほぼ同時に新しいPodが作成されます**！

#### 自動復旧のタイミング測定

```bash
# Podを削除して復旧までの時間を計測
time kubectl delete pod nginx-replicaset-k8pwd

# 同時に別ターミナルで監視
kubectl get pods -l app=nginx --watch

# 典型的な復旧時間
# - Pod削除検知: 0.1秒以内
# - 新規Pod作成指示: 0.5秒以内
# - イメージPull: 5-30秒（キャッシュ有無で変動）
# - コンテナ起動: 1-5秒
# 合計: 約7-35秒で完全復旧
```

### Podのクラッシュを意図的に起こして復旧確認

#### パターン1: プロセスを強制終了

```bash
# Podに入って強制終了
kubectl exec nginx-replicaset-xm2lq -- sh -c 'kill 1'

# watchしているターミナルで観察
# NAME                      READY   STATUS    RESTARTS   AGE
# nginx-replicaset-xm2lq    0/1     Error     0          15m
# nginx-replicaset-xm2lq    0/1     Pending   1          15m  ← RESTARTSが増加
# nginx-replicaset-xm2lq    1/1     Running   1          15m  ← 同じPod内で再起動
```

**重要な違い**:
- **Pod削除**: 新しいPodが作成される（Pod名が変わる）
- **コンテナクラッシュ**: 同じPod内でコンテナが再起動される（Pod名は同じ、RESTARTSカウントが増加）

### 複数Pod削除での挙動確認

```bash
# ReplicaSet作成（replicas=5）
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: ReplicaSet
metadata:
  name: multi-delete-test
spec:
  replicas: 5
  selector:
    matchLabels:
      app: multi-test
  template:
    metadata:
      labels:
        app: multi-test
    spec:
      containers:
      - name: nginx
        image: nginx:1.25-alpine
EOF

# 監視開始
kubectl get pods -l app=multi-test --watch

# 別ターミナルで複数Pod同時削除
kubectl get pods -l app=multi-test -o name | head -3 | xargs kubectl delete

# 観察される挙動
# NAME                      READY   STATUS        RESTARTS   AGE
# multi-delete-test-abc12   1/1     Terminating   0          2m
# multi-delete-test-def34   1/1     Terminating   0          2m
# multi-delete-test-ghi56   1/1     Terminating   0          2m
# multi-delete-test-jkl78   0/1     Pending       0          0s  ← 即座に作成開始
# multi-delete-test-mno90   0/1     Pending       0          0s
# multi-delete-test-pqr12   0/1     Pending       0          0s
# multi-delete-test-jkl78   0/1     ContainerCreating  0     1s
# multi-delete-test-mno90   0/1     ContainerCreating  0     1s
# multi-delete-test-pqr12   0/1     ContainerCreating  0     1s
```

#### 全Pod削除の実験

```bash
# 全Podを削除
kubectl delete pods -l app=multi-test

# 監視結果
# 5つのPodが全てTerminatingに
# ↓
# ほぼ同時に5つの新規Podが作成される
# ↓
# 数秒後に全Pod復旧完了

# ReplicaSetは常にreplicas=5を維持する
kubectl get replicaset multi-delete-test
# NAME                DESIRED   CURRENT   READY   AGE
# multi-delete-test   5         5         5       5m
```

**結論**: ReplicaSetは、何があっても指定した数のPodを維持し続けます。これが**自己修復能力（Self-Healing）**の実力です！

## ラベルとセレクタ - Podを選択する仕組み

### ラベルとは何か（key-valueペア）

**ラベル**は、Kubernetesリソースに付与するメタデータで、`key: value`形式で表現されます。

```yaml
# Podにラベルを付与
metadata:
  labels:
    app: nginx           # アプリケーション名
    tier: frontend       # アーキテクチャ層
    environment: prod    # 環境
    version: v1.25       # バージョン
```

#### ラベルの特徴

```bash
# 1. 複数付与可能
# 2. 動的に追加・削除可能
# 3. 同じラベルを複数リソースに付与可能
# 4. セレクタによる検索・フィルタリングが可能

# ラベルの確認
kubectl get pods --show-labels
# NAME                      READY   STATUS    LABELS
# nginx-replicaset-4fnvx    1/1     Running   app=nginx,tier=frontend

# 特定ラベルを持つPodを検索
kubectl get pods -l app=nginx
kubectl get pods -l tier=frontend
kubectl get pods -l environment=prod

# 複数条件（AND）
kubectl get pods -l app=nginx,tier=frontend

# 否定条件
kubectl get pods -l app!=nginx

# セット条件
kubectl get pods -l 'environment in (dev,staging)'
kubectl get pods -l 'tier notin (backend,database)'
```

### セレクタによるPod選択の仕組み

**セレクタ**は、ラベルを使ってリソースをフィルタリングする仕組みです。ReplicaSetはセレクタを使って、「どのPodを管理するか」を決定します。

#### ReplicaSetのセレクタ

```yaml
apiVersion: apps/v1
kind: ReplicaSet
metadata:
  name: nginx-rs
spec:
  replicas: 3
  selector:           # ← このセレクタに一致するPodを管理
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:         # ← selector.matchLabelsと一致必須
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.25-alpine
```

**重要なルール**: `selector.matchLabels`のラベルは、`template.metadata.labels`に**必ず含まれている必要がある**。

#### セレクタの動作確認

```bash
# ReplicaSetが管理しているPodを確認
kubectl get pods -l app=nginx
# NAME               READY   STATUS    RESTARTS   AGE
# nginx-rs-abc12     1/1     Running   0          5m
# nginx-rs-def34     1/1     Running   0          5m
# nginx-rs-ghi56     1/1     Running   0          5m

# ReplicaSetの情報を確認
kubectl describe replicaset nginx-rs
# Name:           nginx-rs
# Selector:       app=nginx
# Replicas:       3 current / 3 desired
# Pods Status:    3 Running / 0 Waiting / 0 Succeeded / 0 Failed
```

### matchLabels の使い方

最もシンプルな形式：

```yaml
# 等価マッチング
spec:
  selector:
    matchLabels:
      app: nginx
      tier: frontend
# ↑ "app=nginx AND tier=frontend" に一致するPodを選択
```

```bash
# 複数ラベルでの厳密なマッチング
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: ReplicaSet
metadata:
  name: frontend-rs
spec:
  replicas: 2
  selector:
    matchLabels:
      app: webapp
      tier: frontend
      version: v2
  template:
    metadata:
      labels:
        app: webapp
        tier: frontend
        version: v2
    spec:
      containers:
      - name: nginx
        image: nginx:1.25-alpine
EOF
```

### ラベルの動的管理

```bash
# 既存Podにラベル追加
kubectl label pod nginx-rs-abc12 environment=prod

# ラベル上書き
kubectl label pod nginx-rs-abc12 version=v2 --overwrite

# ラベル削除
kubectl label pod nginx-rs-abc12 version-

# ReplicaSet配下の全Podに一括でラベル追加
kubectl label pods -l app=nginx team=platform

# ラベルの確認
kubectl get pod nginx-rs-abc12 --show-labels
# NAME             READY   STATUS    LABELS
# nginx-rs-abc12   1/1     Running   app=nginx,environment=prod,team=platform
```

## ReplicaSetの制限 - なぜDeploymentが必要か

### なぜReplicaSetを直接使わないのか

実際の本番環境では、**ReplicaSetを直接使うことはほとんどありません**。代わりに**Deployment**を使用します。

#### 主な理由

```bash
# 1. ローリングアップデートができない
# 2. ロールバック機能がない
# 3. 更新履歴が保存されない
# 4. デプロイ戦略の選択肢がない
```

### ローリングアップデートができない問題

#### ReplicaSetでのイメージ更新（問題のある方法）

```bash
# 現在のイメージ: nginx:1.24-alpine
kubectl get replicaset nginx-rs -o yaml | grep image:
#     image: nginx:1.24-alpine

# イメージを更新してみる
kubectl set image replicaset/nginx-rs nginx=nginx:1.25-alpine
# replicaset.apps/nginx-rs image updated

# ❌ 問題: 既存のPodは更新されない
kubectl get pods -l app=nginx -o yaml | grep "image: nginx"
#     image: nginx:1.24-alpine  ← まだ古いイメージ
#     image: nginx:1.24-alpine
#     image: nginx:1.24-alpine

# ReplicaSetのテンプレートだけが更新された
kubectl get replicaset nginx-rs -o yaml | grep image:
#     image: nginx:1.25-alpine  ← テンプレートは新しい

# 手動でPodを削除すれば新イメージで再作成される
kubectl delete pod nginx-rs-abc12
# 新しいPodは nginx:1.25-alpine で起動

# ❌ 全Podを手動削除が必要 → ダウンタイム発生
kubectl delete pods -l app=nginx
# → 一時的に全Podが停止 → サービス停止
```

この問題を解決するのが、次回学ぶ**Deployment**です。

### Deploymentとの違い（次回への布石）

```yaml
# ReplicaSet: 低レベルなAPI
apiVersion: apps/v1
kind: ReplicaSet
metadata:
  name: nginx-rs
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

---
# Deployment: 高レベルなAPI（本番推奨）
apiVersion: apps/v1
kind: Deployment  # ← ReplicaSetの代わりにDeployment
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
        image: nginx:1.25-alpine
```

#### Deploymentの利点

```bash
# Deploymentを作成すると...
kubectl apply -f deployment-nginx.yaml

# バックグラウンドで自動的にReplicaSetが作成される
kubectl get replicaset
# NAME                          DESIRED   CURRENT   READY   AGE
# nginx-deployment-5d59d67564   3         3         3       10s
# ↑ Deploymentが自動生成したReplicaSet

# Deploymentの階層構造
# Deployment
#   └── ReplicaSet (自動管理)
#        └── Pod × 3

# ユーザーは直接ReplicaSetを操作しない
# Deploymentを通してReplicaSetを間接的に管理
```

**次回予告**: 第4回では、Deploymentを使った**ローリングアップデート**と**ロールバック**の実践を詳しく解説します。

## まとめと次回予告

### この記事で学んだこと

本記事では、ReplicaSetによる自動復旧の仕組みを徹底的に解説しました。

**重要なポイント:**

1. **Pod単体の問題**: 自動復旧なし、SPOF、手動管理の限界
2. **ReplicaSetの役割**: Desired State維持、Reconciliation Loop
3. **セレクタとラベル**: Pod選択の仕組み、matchLabels
4. **自動復旧の実際**: Pod削除・クラッシュからの即座の復旧
5. **制限事項**: ローリングアップデート不可 → Deploymentが必要

### 実践的なコマンド集

```bash
# ReplicaSet作成
kubectl apply -f replicaset.yaml

# 状態確認
kubectl get replicaset
kubectl get pods -l app=nginx

# スケーリング
kubectl scale replicaset nginx-rs --replicas=5

# 自動復旧の確認
kubectl delete pod <pod-name>
kubectl get pods --watch

# ラベル操作
kubectl label pod <pod-name> env=prod
kubectl get pods --show-labels

# ReplicaSet削除
kubectl delete replicaset nginx-rs
```

### 次回予告 - 第4回「Deploymentで実現するゼロダウンタイム更新」

次回、第4回では、以下を学習します：

- **Deploymentとは何か** - ReplicaSetとの違い
- **ローリングアップデートの仕組み** - ダウンタイムゼロの更新
- **ロールバック戦略** - 問題発生時の迅速な復旧
- **デプロイ戦略** - Recreate vs RollingUpdate
- **更新の制御** - maxSurge, maxUnavailableの詳細

Kubernetesの真の力を体験してください！

ぜひ、実際に手を動かしながら学習を続けてください！
