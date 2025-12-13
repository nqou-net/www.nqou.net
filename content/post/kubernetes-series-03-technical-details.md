---
title: "アプリケーションを守るReplicaSet - 自動復旧の仕組み(技術詳細)"
draft: true
tags:
- kubernetes
- replicaset
- high-availability
- self-healing
- controller
description: "単一のPodでは不十分な理由を実験で確認し、ReplicaSetによる自動復旧の仕組みを徹底解説。コントローラーパターン、Reconciliation Loop、セレクタとラベルの使い方まで完全網羅。"
---

## はじめに

前回の記事では、KubernetesにおけるPodの概念、ライフサイクル、基本的な操作方法を学びました。しかし、**Pod単体では本番運用には不十分**です。

本記事では、なぜPod単体では不十分なのかを実験で確認し、**ReplicaSet**による自動復旧の仕組みを徹底的に解説します。Kubernetesの心臓部である**コントローラーパターン**と**Reconciliation Loop**の動作原理を理解することで、Kubernetesが「なぜ壊れても自動で直るのか」の秘密に迫ります。

## 1. なぜPod単体では不十分なのか

### 1.1 Pod削除の実験 - 何が起こるのか

まず、単一のPodを作成して、削除したときの挙動を確認しましょう。

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

#### この挙動の問題点

```bash
# シナリオ: 本番環境でPodがクラッシュした場合
# 
# 1. アプリケーションのバグでコンテナがクラッシュ
# 2. Podが削除される
# 3. 新しいPodは自動作成されない
# 4. サービスが完全停止
# 5. 手動で再作成するまで復旧しない ← 人間が介入するまでダウン
```

### 1.2 単一障害点（SPOF）の具体的なリスク

**SPOF (Single Point of Failure)**: システム全体の可用性が、単一のコンポーネントに依存している状態

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

# Pod内でメモリを大量消費
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

### 1.3 手動管理の限界

単一Podを手動で管理する場合の課題:

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

# 課題4: 設定の一貫性がない
# Pod1: メモリ制限512Mi
# Pod2: メモリ制限1Gi
# Pod3: メモリ制限なし
# ↑ 統一された設定がない
```

**結論**: Pod単体は、Kubernetesの強力な機能（自動復旧、スケーリング、ローリングアップデート）を一切利用できません。これでは従来の手動運用と変わりません。

## 2. ReplicaSetの仕組みと役割

### 2.1 ReplicaSetとは何か

**ReplicaSet**は、指定した数のPodレプリカを常に維持するKubernetesコントローラーです。

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

### 2.2 Desired State（期待状態）とCurrent State（現在状態）

Kubernetesの根幹を成す概念:

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

### 2.3 コントローラーパターンの説明

**コントローラーパターン**は、Kubernetesの自動化の核心です。

#### コントローラーの役割

```
┌─────────────────────────────────────┐
│  ReplicaSet Controller              │
│                                     │
│  while True:                        │
│    desired = spec.replicas          │
│    current = count_running_pods()   │
│                                     │
│    if current < desired:            │
│      create_pod()                   │
│    elif current > desired:          │
│      delete_pod()                   │
│                                     │
│    sleep(調整間隔)                   │
└─────────────────────────────────────┘
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
# kubectl get pods
# NAME                      READY   STATUS    RESTARTS   AGE
# nginx-replicaset-abc12    1/1     Running   0          5s
# nginx-replicaset-def34    1/1     Running   0          5s
# nginx-replicaset-ghi56    1/1     Running   0          5s
```

### 2.4 Reconciliation Loop（調整ループ）の動作

**Reconciliation Loop（リコンシリエーション・ループ）**は、コントローラーが継続的に状態を監視・調整する仕組みです。

#### ループの詳細動作

```python
# 疑似コードで理解するReconciliation Loop

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

#### 実際の挙動を観察

```bash
# ReplicaSetを作成
kubectl apply -f replicaset-nginx.yaml

# 別のターミナルでwatchモード
kubectl get pods -l app=nginx --watch

# 初期状態（Podが作成される様子）
# NAME                      READY   STATUS              RESTARTS   AGE
# nginx-replicaset-abc12    0/1     ContainerCreating   0          0s
# nginx-replicaset-def34    0/1     ContainerCreating   0          0s
# nginx-replicaset-ghi56    0/1     ContainerCreating   0          0s
# nginx-replicaset-abc12    1/1     Running             0          3s
# nginx-replicaset-def34    1/1     Running             0          3s
# nginx-replicaset-ghi56    1/1     Running             0          3s
```

## 3. レプリカ数の指定と動的な変更

### 3.1 ReplicaSet YAMLマニフェストの書き方

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

### 3.2 kubectl apply でのReplicaSet作成

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

### 3.3 kubectl scale でのレプリカ数変更

#### imperativeなスケーリング（即座に反映）

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

#### どのPodが削除されるか？

```bash
# ReplicaSetの削除ポリシー
# 
# 優先順位（削除されやすい順）:
# 1. Pending状態のPod
# 2. Unknown状態のPod
# 3. Running状態のPod（新しいものから）
# 4. ノード間で均等に削除
```

### 3.4 kubectl edit での設定変更

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

# YAMLファイルを直接編集する方法（推奨）
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

#### 環境変数の変更（注意点）

```bash
# ❌ 既存のPodには反映されない
kubectl edit replicaset nginx-replicaset
# template.spec.containers[0].envに追加
#   env:
#   - name: NEW_VAR
#     value: "new_value"

# 保存後
kubectl get pods -l app=nginx -o yaml | grep -A 2 "env:"
# ↑ 既存のPodにはNEW_VARが存在しない

# ✅ Podを再作成すると反映される
kubectl delete pods -l app=nginx
# 新しいPodが自動作成され、NEW_VARが含まれる

# または kubectl rollout restart (Deploymentの場合のみ)
```

## 4. 自動復旧体験

### 4.1 Podを手動削除して自動復旧を確認

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

### 4.2 Podのクラッシュを意図的に起こして復旧確認

#### パターン1: exitコマンドでコンテナ終了

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

#### パターン2: OOMによるクラッシュ

```yaml
# replicaset-oom-test.yaml
apiVersion: apps/v1
kind: ReplicaSet
metadata:
  name: oom-test
spec:
  replicas: 1
  selector:
    matchLabels:
      app: oom-test
  template:
    metadata:
      labels:
        app: oom-test
    spec:
      containers:
      - name: memory-hog
        image: polinux/stress
        resources:
          limits:
            memory: "50Mi"
          requests:
            memory: "20Mi"
        command:
        - stress
        args:
        - --vm
        - "1"
        - --vm-bytes
        - "100M"  # 50Mi制限を超えるメモリ消費
        - --vm-hang
        - "0"
```

```bash
# OOMテスト用ReplicaSetを作成
kubectl apply -f replicaset-oom-test.yaml

# 監視
kubectl get pods -l app=oom-test --watch
# NAME            READY   STATUS              RESTARTS   AGE
# oom-test-abc12  0/1     ContainerCreating   0          1s
# oom-test-abc12  1/1     Running             0          3s
# oom-test-abc12  0/1     OOMKilled           0          5s
# oom-test-abc12  0/1     CrashLoopBackOff    1          7s  ← 自動再起動
# oom-test-abc12  1/1     Running             1          20s
# oom-test-abc12  0/1     OOMKilled           1          22s
# oom-test-abc12  0/1     CrashLoopBackOff    2          35s ← 再試行間隔が延びる
```

#### CrashLoopBackOffの仕組み

```bash
# 再起動ポリシーと待機時間
# 
# RESTARTS   待機時間
#    1       10秒
#    2       20秒
#    3       40秒
#    4       80秒
#    5       160秒
#   6+       300秒（最大5分）
#
# exponential backoff（指数バックオフ）

# 状態を確認
kubectl describe pod oom-test-abc12 | grep -A 10 "State:"
# State:          Waiting
#   Reason:       CrashLoopBackOff
# Last State:     Terminated
#   Reason:       OOMKilled
#   Exit Code:    137  ← OOMKilledの特徴
```

### 4.3 複数Pod削除での挙動確認

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

### 4.4 kubectl get pods --watch での監視

```bash
# 基本的な監視
kubectl get pods --watch

# ラベル指定で特定のReplicaSet配下のPodを監視
kubectl get pods -l app=nginx --watch

# より詳細な情報を表示
kubectl get pods -l app=nginx --watch -o wide
# NAME                      READY   STATUS    IP           NODE
# nginx-replicaset-4fnvx    1/1     Running   10.244.0.5   minikube

# カスタムカラムで見やすく
kubectl get pods -l app=nginx --watch \
  -o custom-columns=NAME:.metadata.name,STATUS:.status.phase,RESTARTS:.status.containerStatuses[0].restartCount,AGE:.metadata.creationTimestamp

# JSONPathで特定フィールドを監視
kubectl get pods -l app=nginx --watch \
  -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.phase}{"\t"}{.status.podIP}{"\n"}{end}'
```

#### watchとeventsの併用

```bash
# Terminal 1: Podの状態監視
kubectl get pods -l app=nginx --watch

# Terminal 2: イベント監視
kubectl get events --watch --field-selector involvedObject.kind=Pod

# Terminal 3: 操作実行
kubectl delete pod nginx-replicaset-4fnvx

# Terminal 2で観察されるイベント
# LAST SEEN   TYPE      REASON      OBJECT                         MESSAGE
# 0s          Normal    Killing     pod/nginx-replicaset-4fnvx     Stopping container nginx
# 0s          Normal    Scheduled   pod/nginx-replicaset-vw8xy     Successfully assigned default/nginx-replicaset-vw8xy to minikube
# 0s          Normal    Pulling     pod/nginx-replicaset-vw8xy     Pulling image "nginx:1.25-alpine"
# 2s          Normal    Pulled      pod/nginx-replicaset-vw8xy     Successfully pulled image
# 2s          Normal    Created     pod/nginx-replicaset-vw8xy     Created container nginx
# 2s          Normal    Started     pod/nginx-replicaset-vw8xy     Started container nginx
```

## 5. セレクタとラベルの重要性

### 5.1 ラベルとは何か（key-valueペア）

**ラベル**は、Kubernetesリソースに付与するメタデータで、`key: value`形式で表現されます。

```yaml
# Podにラベルを付与
metadata:
  labels:
    app: nginx           # アプリケーション名
    tier: frontend       # アーキテクチャ層
    environment: prod    # 環境
    version: v1.25       # バージョン
    team: platform       # 担当チーム
    cost-center: eng001  # コストセンター
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

### 5.2 セレクタによるPod選択の仕組み

**セレクタ**は、ラベルを使ってリソースをフィルタリングする仕組みです。

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

### 5.3 matchLabels と matchExpressions

#### matchLabelsの使い方（等価マッチ）

```yaml
# 最もシンプルな形式
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

#### matchExpressionsの使い方（高度な条件指定）

```yaml
# より柔軟な条件指定
spec:
  selector:
    matchExpressions:
    - key: app
      operator: In
      values:
      - nginx
      - httpd
    - key: tier
      operator: NotIn
      values:
      - backend
    - key: environment
      operator: Exists
    - key: deprecated
      operator: DoesNotExist
```

**利用可能なoperator**:

| Operator | 意味 | 例 |
|----------|------|-----|
| `In` | 値がリストに含まれる | `tier In (frontend, api)` |
| `NotIn` | 値がリストに含まれない | `env NotIn (test)` |
| `Exists` | キーが存在する（値は問わない） | `version Exists` |
| `DoesNotExist` | キーが存在しない | `deprecated DoesNotExist` |

#### matchLabelsとmatchExpressionsの併用

```yaml
# 両方を組み合わせることも可能
spec:
  selector:
    matchLabels:
      app: nginx  # 必須条件
    matchExpressions:
    - key: environment
      operator: In
      values:
      - prod
      - staging
    - key: deprecated
      operator: DoesNotExist
# ↑ "app=nginx AND environment in (prod, staging) AND deprecated key does not exist"
```

```bash
# 実例: 複雑なセレクタを持つReplicaSet
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: ReplicaSet
metadata:
  name: complex-selector-rs
spec:
  replicas: 3
  selector:
    matchLabels:
      app: myapp
    matchExpressions:
    - key: tier
      operator: In
      values:
      - frontend
      - api
    - key: canary
      operator: DoesNotExist
  template:
    metadata:
      labels:
        app: myapp
        tier: frontend  # tier=frontend または tier=api
    spec:
      containers:
      - name: nginx
        image: nginx:1.25-alpine
EOF

# このReplicaSetが管理するPod
# ✅ app=myapp, tier=frontend
# ✅ app=myapp, tier=api
# ❌ app=myapp, tier=backend (tierがfrontend/api以外)
# ❌ app=myapp, tier=frontend, canary=true (canaryキーが存在)
```

### 5.4 ラベルの命名規則とベストプラクティス

#### 推奨される命名規則

```yaml
# 1. プレフィックス付き（組織や用途を明確に）
metadata:
  labels:
    app.kubernetes.io/name: nginx
    app.kubernetes.io/instance: nginx-prod-01
    app.kubernetes.io/version: "1.25"
    app.kubernetes.io/component: webserver
    app.kubernetes.io/part-of: ecommerce-platform
    app.kubernetes.io/managed-by: kubectl

# 2. カスタムプレフィックス
metadata:
  labels:
    mycompany.com/team: platform
    mycompany.com/cost-center: eng001
    mycompany.com/environment: production
```

#### ラベルの推奨パターン

```yaml
# アプリケーション識別用ラベル
app: myapp                    # アプリケーション名（必須）
version: v1.2.3               # バージョン
component: api                # コンポーネント（api, web, worker）

# アーキテクチャ層ラベル
tier: frontend                # frontend, backend, cache, database

# 環境ラベル
environment: production       # production, staging, dev, test

# リリース管理ラベル
release: stable               # stable, canary, beta
track: stable                 # stable, canary

# チーム・組織ラベル
team: platform                # 担当チーム
owner: platform-team          # オーナー

# コスト管理ラベル
cost-center: engineering      # コストセンター
project: project-x            # プロジェクト名
```

#### アンチパターン（避けるべき例）

```yaml
# ❌ 悪い例
metadata:
  labels:
    name: nginx  # 'name'は予約語的に使われるため避ける
    1app: myapp  # 数字で始まる（無効）
    app_name: myapp  # アンダースコアよりハイフン推奨
    "app-version": "1.2.3"  # 引用符不要
    very-long-label-name-that-exceeds-sixty-three-characters-limit: value  # 63文字制限超過
```

#### ラベルの動的管理

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

## 6. ReplicaSetの制限事項

### 6.1 なぜReplicaSetを直接使わないのか

実際の本番環境では、**ReplicaSetを直接使うことはほとんどありません**。代わりに**Deployment**を使用します。

#### 主な理由

```bash
# 1. ローリングアップデートができない
# 2. ロールバック機能がない
# 3. 更新履歴が保存されない
# 4. デプロイ戦略の選択肢がない
```

### 6.2 Deploymentとの違い（次回への布石）

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

### 6.3 ローリングアップデートができない問題

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

#### Deploymentでのローリングアップデート（正しい方法）

```bash
# Deploymentでイメージ更新
kubectl set image deployment/nginx-deployment nginx=nginx:1.25-alpine

# ✅ 自動的にローリングアップデート実行
kubectl get pods --watch
# NAME                                READY   STATUS              RESTARTS   AGE
# nginx-deployment-5d59d67564-abc12   1/1     Running             0          5m
# nginx-deployment-5d59d67564-def34   1/1     Running             0          5m
# nginx-deployment-5d59d67564-ghi56   1/1     Running             0          5m
# nginx-deployment-7d6c8f9b4d-jkl78   0/1     ContainerCreating   0          0s  ← 新Pod作成
# nginx-deployment-7d6c8f9b4d-jkl78   1/1     Running             0          2s  ← 新Pod起動
# nginx-deployment-5d59d67564-abc12   1/1     Terminating         0          5m  ← 旧Pod削除
# nginx-deployment-7d6c8f9b4d-mno90   0/1     ContainerCreating   0          0s  ← 新Pod作成
# nginx-deployment-7d6c8f9b4d-mno90   1/1     Running             0          2s
# nginx-deployment-5d59d67564-def34   1/1     Terminating         0          5m
# ...
# ↑ ダウンタイムなし、徐々に入れ替わる
```

**次回予告**: 第4回では、Deploymentを使った**ローリングアップデート**と**ロールバック**の実践を詳しく解説します。

## 7. 初心者がつまづきやすいポイント

### 7.1 セレクタとPodテンプレートのラベル不一致

#### よくあるエラー

```yaml
# ❌ 間違った設定
apiVersion: apps/v1
kind: ReplicaSet
metadata:
  name: broken-rs
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx      # ← セレクタ
  template:
    metadata:
      labels:
        app: web      # ← ラベルが不一致！
    spec:
      containers:
      - name: nginx
        image: nginx:1.25-alpine
```

```bash
# 適用しようとすると...
kubectl apply -f broken-rs.yaml
# The ReplicaSet "broken-rs" is invalid: 
# spec.template.metadata.labels: Invalid value: map[string]string{"app":"web"}: 
# `selector` does not match template `labels`

# エラーメッセージ解説
# - spec.template.metadata.labels: ラベルに問題がある
# - selector does not match template labels: セレクタとラベルが一致しない
```

#### 正しい設定

```yaml
# ✅ 正しい設定
apiVersion: apps/v1
kind: ReplicaSet
metadata:
  name: correct-rs
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx      # ← セレクタ
  template:
    metadata:
      labels:
        app: nginx    # ← 一致している
        version: v1   # ← 追加ラベルはOK
    spec:
      containers:
      - name: nginx
        image: nginx:1.25-alpine
```

**ルール**: `selector.matchLabels`のラベルは、`template.metadata.labels`に**必ず含まれている必要がある**。逆（テンプレートにあるラベルが全てセレクタに必要）は不要。

### 7.2 既存のPodとラベルが衝突する問題

```bash
# シナリオ1: 既存のPodを作成
kubectl run standalone-nginx --image=nginx:1.25-alpine --labels="app=nginx"

# Podが1つ存在
kubectl get pods -l app=nginx
# NAME               READY   STATUS    RESTARTS   AGE
# standalone-nginx   1/1     Running   0          10s

# シナリオ2: 同じラベルを使うReplicaSetを作成
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: ReplicaSet
metadata:
  name: nginx-rs
spec:
  replicas: 3
  selector:
    matchLabels:
      app: nginx  # ← 既存Podと同じラベル
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.25-alpine
EOF

# 何が起こるか?
kubectl get pods -l app=nginx
# NAME               READY   STATUS    RESTARTS   AGE
# standalone-nginx   1/1     Running   0          1m   ← 既存Pod（ReplicaSetに取り込まれる）
# nginx-rs-abc12     1/1     Running   0          5s   ← ReplicaSetが作成（2つだけ）
# nginx-rs-def34     1/1     Running   0          5s

# ReplicaSetの状態
kubectl get replicaset nginx-rs
# NAME       DESIRED   CURRENT   READY   AGE
# nginx-rs   3         3         3       10s
# ↑ 既存Podを含めて3つとカウント

# 既存Podを削除すると...
kubectl delete pod standalone-nginx
# ReplicaSetが即座に新しいPodを作成
kubectl get pods -l app=nginx
# NAME               READY   STATUS              RESTARTS   AGE
# nginx-rs-abc12     1/1     Running             0          1m
# nginx-rs-def34     1/1     Running             0          1m
# nginx-rs-ghi56     0/1     ContainerCreating   0          0s  ← 新規作成
```

#### なぜこうなるのか？

```bash
# ReplicaSetの動作原理
# 1. selector.matchLabelsに一致するPodを全て検索
# 2. 見つかったPod数とreplicas数を比較
# 3. 不足分だけ作成、超過分は削除

# 既存Podの所有者を確認
kubectl get pod standalone-nginx -o yaml | grep -A 5 ownerReferences
# ownerReferences:
# - apiVersion: apps/v1
#   blockOwnerDeletion: true
#   controller: true
#   kind: ReplicaSet
#   name: nginx-rs  ← ReplicaSetに自動的に管理下に入る
```

#### 対策

```yaml
# 1. より具体的なラベルを使う（推奨）
spec:
  selector:
    matchLabels:
      app: nginx
      managed-by: replicaset
      instance: prod-01  # ← ユニークなラベルを追加

# 2. matchExpressionsを使う
spec:
  selector:
    matchExpressions:
    - key: app
      operator: In
      values:
      - nginx
    - key: created-by
      operator: In
      values:
      - replicaset
```

### 7.3 レプリカ数を0にしたときの挙動

```bash
# レプリカ数を0にスケール
kubectl scale replicaset nginx-rs --replicas=0

# 全Podが削除される
kubectl get pods -l app=nginx --watch
# NAME               READY   STATUS        RESTARTS   AGE
# nginx-rs-abc12     1/1     Terminating   0          5m
# nginx-rs-def34     1/1     Terminating   0          5m
# nginx-rs-ghi56     1/1     Terminating   0          5m
# (Podが全て消える)

kubectl get pods -l app=nginx
# No resources found in default namespace.

# ReplicaSetは存在する
kubectl get replicaset nginx-rs
# NAME       DESIRED   CURRENT   READY   AGE
# nginx-rs   0         0         0       10m

# 再度スケールアウト
kubectl scale replicaset nginx-rs --replicas=5
# Podが5つ作成される
```

#### replicas=0 の用途

```bash
# 用途1: 一時的なメンテナンス
# ReplicaSetの定義は残したまま、全Podを停止

# 用途2: リソースの節約
# 開発環境で夜間は全Pod停止

# 用途3: トラブルシューティング
# 自動復旧を止めて、手動でPodを調査

# ❌ 注意: replicas=0でもReplicaSetは削除されない
kubectl delete replicaset nginx-rs  # ← ReplicaSet削除が必要
```

#### ReplicaSet削除時の挙動

```bash
# ReplicaSetを削除すると...
kubectl delete replicaset nginx-rs

# デフォルト: 配下のPodも全て削除される
kubectl get pods -l app=nginx
# No resources found in default namespace.

# ReplicaSetだけ削除してPodを残す（オーファン化）
kubectl delete replicaset nginx-rs --cascade=orphan

# ReplicaSetは削除されるが、Podは残る
kubectl get pods -l app=nginx
# NAME               READY   STATUS    RESTARTS   AGE
# nginx-rs-abc12     1/1     Running   0          10m
# nginx-rs-def34     1/1     Running   0          10m
# nginx-rs-ghi56     1/1     Running   0          10m

# これらのPodは「孤児(orphan)」状態
# 削除されても自動復旧しない
kubectl delete pod nginx-rs-abc12
# 復活しない
```

## まとめ

本記事では、ReplicaSetによる自動復旧の仕組みを徹底的に解説しました。

### 重要なポイント

1. **Pod単体の問題**: 自動復旧なし、SPOF、手動管理の限界
2. **ReplicaSetの役割**: Desired State維持、コントローラーパターン、Reconciliation Loop
3. **セレクタとラベル**: Pod選択の仕組み、matchLabels/matchExpressions
4. **自動復旧の実際**: Pod削除・クラッシュからの即座の復旧
5. **制限事項**: ローリングアップデート不可 → Deploymentが必要

### 次回予告

次回、第4回「**Deploymentで実現するゼロダウンタイム更新**」では、

- Deploymentとは何か
- ローリングアップデートの仕組み
- ロールバック戦略
- デプロイ戦略（Recreate vs RollingUpdate）
- カナリアリリースの実践

を解説します。Kubernetesの真の力を体験してください！

### 参考コマンド集

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
kubectl delete replicaset nginx-rs --cascade=orphan  # Podを残す
```
