---
title: "ResourceとLimitsでリソース管理 - QoSと効率的なリソース配分（技術詳細）"
draft: true
tags:
- kubernetes
- resource-management
- qos
- resource-limits
- oom-killer
description: "Kubernetes Resource RequestsとLimitsの完全ガイド。QoSクラスの仕組み、OOMKillerとCPUスロットリング、効率的なリソース配分設計を実践的に解説。"
---

## はじめに

Kubernetesクラスタで複数のアプリケーションを効率的に運用するには、適切なリソース管理が不可欠です。本記事では、RequestsとLimitsの違い、QoS（Quality of Service）クラス、OOMKillerとCPUスロットリングについて、実践的なコード例とともに徹底解説します。

## 1. RequestsとLimitsの基本

### 1.1 Requestsとは - リソース保証

**Requests**: Podが**最低限必要**とするリソース量（スケジューリングの基準）

```yaml
# requests-example.yaml
apiVersion: v1
kind: Pod
metadata:
  name: requests-demo
spec:
  containers:
  - name: app
    image: nginx:1.21
    resources:
      requests:
        memory: "128Mi"  # 128MiBのメモリを保証
        cpu: "250m"      # 0.25 CPUコアを保証
```

**動作**:
```bash
# デプロイ
kubectl apply -f requests-example.yaml

# Nodeのリソース確認
kubectl describe node minikube
# Allocated resources:
#   (Total limits may be over 100 percent, i.e., overcommitted.)
#   Resource           Requests    Limits
#   --------           --------    ------
#   cpu                750m (37%)  2 (100%)
#   memory             512Mi (13%) 1Gi (26%)
#   ↑ requests-demoの250m、128Miが含まれる
```

**Requestsの役割**:
1. **スケジューリング**: 十分なリソースを持つNodeにPodを配置
2. **リソース保証**: 他のPodがどれだけ動いても、Requestsは確保される
3. **課金基準**: クラウドでは通常Requestsベースで課金

### 1.2 Limitsとは - リソース上限

**Limits**: Podが使用できる**最大**リソース量

```yaml
# limits-example.yaml
apiVersion: v1
kind: Pod
metadata:
  name: limits-demo
spec:
  containers:
  - name: app
    image: stress-ng:latest
    resources:
      requests:
        memory: "128Mi"
        cpu: "250m"
      limits:
        memory: "256Mi"  # 最大256MiB
        cpu: "500m"      # 最大0.5 CPUコア
```

**Limitsを超えた場合の動作**:

#### メモリLimits超過 → OOMKiller発動

```bash
# メモリを大量消費するPodをデプロイ
cat > memory-hog.yaml << 'YAML'
apiVersion: v1
kind: Pod
metadata:
  name: memory-hog
spec:
  containers:
  - name: stress
    image: polinux/stress
    command: ["stress"]
    args:
    - "--vm"
    - "1"
    - "--vm-bytes"
    - "300M"  # 300MB消費を試みる
    resources:
      requests:
        memory: "100Mi"
      limits:
        memory: "200Mi"  # 上限200MB
YAML

kubectl apply -f memory-hog.yaml

# Pod状態確認
kubectl get pod memory-hog -w
# NAME         READY   STATUS      RESTARTS   AGE
# memory-hog   1/1     Running     0          5s
# memory-hog   0/1     OOMKilled   0          10s  ← メモリ上限超過でKill
# memory-hog   1/1     Running     1          15s  ← 自動再起動

# イベント確認
kubectl describe pod memory-hog
# Events:
#   Warning  BackOff  1m  kubelet  Back-off restarting failed container
#   Normal   Killing  1m  kubelet  Memory cgroup out of memory: Killed process 1234
```

#### CPU Limits超過 → スロットリング

```bash
# CPUを大量消費するPodをデプロイ
cat > cpu-hog.yaml << 'YAML'
apiVersion: v1
kind: Pod
metadata:
  name: cpu-hog
spec:
  containers:
  - name: stress
    image: polinux/stress
    command: ["stress"]
    args:
    - "--cpu"
    - "2"  # 2コア分のCPU負荷
    resources:
      requests:
        cpu: "250m"
      limits:
        cpu: "500m"  # 上限0.5コア
YAML

kubectl apply -f cpu-hog.yaml

# CPU使用率確認
kubectl top pod cpu-hog
# NAME      CPU(cores)   MEMORY(bytes)
# cpu-hog   500m         10Mi  ← 500m（Limits）に制限される

# スロットリング確認（Node内で）
kubectl exec cpu-hog -- cat /sys/fs/cgroup/cpu/cpu.stat
# nr_periods 10000
# nr_throttled 5000    ← 50%の期間でスロットリングされている
# throttled_time 25000000000  ← スロットリングされた時間（ナノ秒）
```

**重要な違い**:
- **メモリ**: Limits超過 → 即座にKill（非圧縮可能リソース）
- **CPU**: Limits超過 → スロットリング（圧縮可能リソース）

### 1.3 RequestsとLimitsの関係

```yaml
# パターン1: Requests = Limits（Guaranteed QoS）
resources:
  requests:
    memory: "256Mi"
    cpu: "500m"
  limits:
    memory: "256Mi"  # 同じ
    cpu: "500m"      # 同じ

# パターン2: Requests < Limits（Burstable QoS）
resources:
  requests:
    memory: "128Mi"
    cpu: "250m"
  limits:
    memory: "512Mi"  # 4倍まで使える
    cpu: "1000m"     # 4倍まで使える

# パターン3: Requestsのみ（Burstable QoS）
resources:
  requests:
    memory: "128Mi"
    cpu: "250m"
  # Limitsなし → Node上限まで使える

# パターン4: 何も指定しない（BestEffort QoS）
resources: {}
# 最も優先度が低い
```

## 2. QoS（Quality of Service）クラス

Kubernetesは、RequestsとLimitsの設定に基づいて、自動的に3つのQoSクラスを割り当てます。

### 2.1 Guaranteed（最優先）

**条件**: 全コンテナで `requests == limits`

```yaml
# guaranteed-pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: guaranteed-pod
spec:
  containers:
  - name: app
    image: nginx:1.21
    resources:
      requests:
        memory: "256Mi"
        cpu: "500m"
      limits:
        memory: "256Mi"
        cpu: "500m"
```

**確認**:
```bash
kubectl apply -f guaranteed-pod.yaml
kubectl get pod guaranteed-pod -o jsonpath='{.status.qosClass}'
# Guaranteed

kubectl describe pod guaranteed-pod | grep QoS
# QoS Class:       Guaranteed
```

**特徴**:
- **最も保護される**: リソース不足時も最後まで残る
- **予測可能**: 常に固定量のリソースを使用
- **OOM Killerからの保護**: メモリ不足時も最後に削除される

**使用例**:
- データベース
- 本番環境の重要なアプリケーション
- レイテンシ重視のサービス

### 2.2 Burstable（中優先）

**条件**: 少なくとも1つのコンテナでRequestsが設定されているが、Guaranteedではない

```yaml
# burstable-pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: burstable-pod
spec:
  containers:
  - name: app
    image: nginx:1.21
    resources:
      requests:
        memory: "128Mi"
        cpu: "250m"
      limits:
        memory: "512Mi"  # Requestsの4倍
        cpu: "1000m"
```

**確認**:
```bash
kubectl get pod burstable-pod -o jsonpath='{.status.qosClass}'
# Burstable
```

**特徴**:
- **バースト可能**: アイドル時は少なく、ピーク時は多く使える
- **コスト効率**: Requestsベースで課金されるため効率的
- **リスク**: Limits超過でOOMKiller

**使用例**:
- Webアプリケーション（トラフィック変動あり）
- バッチ処理
- 開発・ステージング環境

### 2.3 BestEffort（最低優先）

**条件**: RequestsもLimitsも設定されていない

```yaml
# besteffort-pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: besteffort-pod
spec:
  containers:
  - name: app
    image: nginx:1.21
    resources: {}  # 何も指定しない
```

**確認**:
```bash
kubectl get pod besteffort-pod -o jsonpath='{.status.qosClass}'
# BestEffort
```

**特徴**:
- **最初に削除**: リソース不足時、真っ先に削除される
- **制限なし**: Node全体のリソースを使える（他に空きがあれば）
- **リスク高**: いつでもEvictされる可能性

**使用例**:
- 非重要なバッチジョブ
- ログ収集（失っても問題ない）
- テスト用Pod

### 2.4 QoSクラスによる優先順位

```
リソース不足時の削除順序:
BestEffort → Burstable → Guaranteed
    ↓            ↓           ↓
  最初に削除   次に削除    最後まで残る
```

**実験: Node圧迫時の挙動**

```bash
# 1. 各QoSクラスのPodをデプロイ
kubectl apply -f guaranteed-pod.yaml
kubectl apply -f burstable-pod.yaml
kubectl apply -f besteffort-pod.yaml

# 2. メモリ圧迫を引き起こす
cat > memory-pressure.yaml << 'YAML'
apiVersion: v1
kind: Pod
metadata:
  name: memory-eater
spec:
  containers:
  - name: stress
    image: polinux/stress
    command: ["stress"]
    args:
    - "--vm"
    - "1"
    - "--vm-bytes"
    - "2G"  # 大量のメモリ消費
    resources:
      requests:
        memory: "1Gi"
      limits:
        memory: "2Gi"
YAML

kubectl apply -f memory-pressure.yaml

# 3. Evictionを観察
kubectl get pods -w
# NAME              READY   STATUS    RESTARTS   AGE
# besteffort-pod    1/1     Running   0          2m
# burstable-pod     1/1     Running   0          2m
# guaranteed-pod    1/1     Running   0          2m
# memory-eater      1/1     Running   0          5s
# besteffort-pod    0/1     Evicted   0          2m10s  ← 最初に削除
# burstable-pod     0/1     Evicted   0          2m15s  ← 次に削除
# guaranteed-pod    1/1     Running   0          2m30s  ← 最後まで残る

# Eviction理由確認
kubectl describe pod besteffort-pod
# Reason:  Evicted
# Message: The node was low on resource: memory. Container besteffort was using 100Mi, which exceeds its request of 0.
```

## 3. OOMKiller（Out of Memory Killer）

### 3.1 OOMKillerの仕組み

Linuxカーネルのメモリ不足時の自己防衛機能:

```
1. メモリ不足検知
   ↓
2. OOM Scoreを計算（各プロセス）
   ↓
3. 最もスコアが高いプロセスをKill
   ↓
4. Kubernetesが検知
   ↓
5. Podを再起動（RestartPolicy: Always）
```

**OOM Scoreの計算**:
```bash
# Podのプロセス確認
kubectl exec my-pod -- ps aux
# USER  PID  %CPU %MEM    VSZ   RSS COMMAND
# root    1   0.1  2.0 123456 78901 /app/server

# OOM Score確認（Node内で）
cat /proc/1/oom_score
# 200

# OOM Score調整値
cat /proc/1/oom_score_adj
# -998  ← Guaranteed（保護される）
# 0     ← Burstable
# 1000  ← BestEffort（最優先でKill）
```

### 3.2 OOMKillerを避ける設計

#### パターン1: メモリリーク対策

```go
// 悪い例: メモリリーク
var cache = make(map[string][]byte)

func handler(w http.ResponseWriter, r *http.Request) {
    data := make([]byte, 1024*1024) // 1MB
    cache[r.URL.Path] = data        // 永遠に増え続ける
}

// 良い例: サイズ制限付きキャッシュ
import "github.com/hashicorp/golang-lru"

cache, _ := lru.New(1000) // 最大1000エントリ

func handler(w http.ResponseWriter, r *http.Request) {
    data := make([]byte, 1024*1024)
    cache.Add(r.URL.Path, data) // 古いエントリは自動削除
}
```

#### パターン2: 適切なLimits設定

```yaml
# 実測ベースで設定
apiVersion: v1
kind: Pod
metadata:
  name: optimized-pod
spec:
  containers:
  - name: app
    image: myapp:1.0
    resources:
      requests:
        memory: "256Mi"   # 通常使用量 + バッファ
      limits:
        memory: "512Mi"   # ピーク時 + 余裕
        cpu: "500m"
```

**メモリ使用量の計測**:
```bash
# 1. 本番相当の負荷をかける
kubectl run load-test --image=load-generator --env="TARGET=http://myapp"

# 2. メトリクスを収集
kubectl top pod myapp-pod
# NAME        CPU(cores)   MEMORY(bytes)
# myapp-pod   150m         320Mi  ← ピーク時

# 3. Limitsを設定
# ピーク320Mi + 余裕50% = 480Mi → 512Miに設定
```

#### パターン3: Vertical Pod Autoscaler（VPA）

```yaml
# vpa.yaml
apiVersion: autoscaling.k8s.io/v1
kind: VerticalPodAutoscaler
metadata:
  name: myapp-vpa
spec:
  targetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: myapp
  updatePolicy:
    updateMode: "Auto"  # 自動でリソース調整
  resourcePolicy:
    containerPolicies:
    - containerName: app
      minAllowed:
        memory: "128Mi"
        cpu: "100m"
      maxAllowed:
        memory: "1Gi"
        cpu: "1000m"
```

```bash
# VPAの推奨値確認
kubectl describe vpa myapp-vpa
# Recommendation:
#   Container Recommendations:
#     Container Name:  app
#     Lower Bound:
#       Cpu:     250m
#       Memory:  256Mi
#     Target:
#       Cpu:     500m
#       Memory:  512Mi  ← VPAの推奨値
#     Upper Bound:
#       Cpu:     1000m
#       Memory:  1Gi
```

## 4. CPUスロットリング

### 4.1 スロットリングの仕組み

Linuxの**CFS（Completely Fair Scheduler）**による制御:

```
1CPU = 100,000マイクロ秒/100ms期間

cpu.cfs_period_us = 100000  # 100ms期間
cpu.cfs_quota_us = 50000    # 500m CPU = 50ms/100ms
```

**スロットリングの発生**:
```bash
# CPU Limitsを超過したプロセス
kubectl exec cpu-hog -- cat /sys/fs/cgroup/cpu/cpu.stat
# nr_periods 1000         # チェック期間回数
# nr_throttled 800        # スロットリングされた回数
# throttled_time 4000000  # スロットリング時間（マイクロ秒）

# スロットリング率 = 800/1000 = 80%
```

### 4.2 スロットリングのパフォーマンス影響

```yaml
# 実験: CPU Limitsの影響
apiVersion: v1
kind: Pod
metadata:
  name: cpu-test
spec:
  containers:
  - name: benchmark
    image: benchmark:latest
    resources:
      requests:
        cpu: "100m"
      limits:
        cpu: "500m"  # この値を変えて比較
```

**ベンチマーク結果**:
```bash
# Limitsなし（2コア使用可能）
kubectl exec cpu-test -- /benchmark
# Execution time: 10s

# Limits: 1000m（1コア）
# Execution time: 20s  ← 2倍

# Limits: 500m（0.5コア）
# Execution time: 40s  ← 4倍

# Limits: 100m（0.1コア）
# Execution time: 200s ← 20倍
```

**推奨設定**:
```yaml
# CPU集約的なアプリ
resources:
  requests:
    cpu: "1000m"
  limits:
    cpu: "2000m"  # バースト許容

# I/O集約的なアプリ
resources:
  requests:
    cpu: "100m"
  limits:
    cpu: "500m"   # あまりCPUを使わない
```

### 4.3 スロットリング回避策

#### オプション1: Limitsを削除（非推奨）

```yaml
resources:
  requests:
    cpu: "500m"
  # limits なし → Node全体を使える
```

**リスク**:
- 他のPodに影響（Noisy Neighbor問題）
- QoSクラスがGuaranteedにならない

#### オプション2: Requests = Limits（推奨）

```yaml
resources:
  requests:
    cpu: "1000m"
  limits:
    cpu: "1000m"  # 同じ値
```

**メリット**:
- QoS: Guaranteed
- スロットリングは発生するが予測可能

#### オプション3: Node Affinityで専有

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: cpu-intensive
spec:
  nodeSelector:
    workload-type: cpu-intensive
  containers:
  - name: app
    image: myapp:1.0
    resources:
      requests:
        cpu: "8000m"  # 8コア占有
      limits:
        cpu: "8000m"
```

## 5. 実践的なリソース設計パターン

### 5.1 本番Webアプリケーション

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: production-web
spec:
  replicas: 5
  template:
    spec:
      containers:
      - name: web
        image: myapp:v1.0
        resources:
          requests:
            memory: "512Mi"   # 通常400Mi使用
            cpu: "500m"       # 通常300m使用
          limits:
            memory: "1Gi"     # ピーク時800Mi
            cpu: "1000m"      # ピーク時700m
        # QoS: Burstable（バースト可能、コスト効率的）
```

### 5.2 データベース

```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: postgres
spec:
  template:
    spec:
      containers:
      - name: postgres
        image: postgres:14
        resources:
          requests:
            memory: "2Gi"
            cpu: "1000m"
          limits:
            memory: "2Gi"     # 同じ値
            cpu: "1000m"      # 同じ値
        # QoS: Guaranteed（最優先、安定性重視）
```

### 5.3 バッチ処理

```yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: data-processing
spec:
  template:
    spec:
      restartPolicy: OnFailure
      containers:
      - name: processor
        image: batch-processor:v1.0
        resources:
          requests:
            memory: "1Gi"
            cpu: "2000m"
          limits:
            memory: "4Gi"     # メモリ集約的
            cpu: "4000m"      # CPU集約的
        # QoS: Burstable（大量リソース使用、完了後解放）
```

### 5.4 LimitRange でデフォルト設定

```yaml
# namespace-limits.yaml
apiVersion: v1
kind: LimitRange
metadata:
  name: default-limits
  namespace: production
spec:
  limits:
  - default:  # Limitsのデフォルト
      memory: "512Mi"
      cpu: "500m"
    defaultRequest:  # Requestsのデフォルト
      memory: "256Mi"
      cpu: "250m"
    max:  # 最大値
      memory: "2Gi"
      cpu: "2000m"
    min:  # 最小値
      memory: "64Mi"
      cpu: "100m"
    type: Container
```

```bash
kubectl apply -f namespace-limits.yaml

# リソース未指定のPodをデプロイ
kubectl run test --image=nginx -n production

# 自動的にデフォルト値が設定される
kubectl get pod test -n production -o yaml | grep -A 10 resources
#   resources:
#     limits:
#       cpu: 500m
#       memory: 512Mi
#     requests:
#       cpu: 250m
#       memory: 256Mi
```

### 5.5 ResourceQuota で全体制限

```yaml
# namespace-quota.yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: team-quota
  namespace: production
spec:
  hard:
    requests.cpu: "10"        # 合計10コア
    requests.memory: "20Gi"   # 合計20GB
    limits.cpu: "20"          # 合計20コア
    limits.memory: "40Gi"     # 合計40GB
    pods: "50"                # 最大50Pod
```

```bash
kubectl apply -f namespace-quota.yaml

# Quota確認
kubectl describe resourcequota team-quota -n production
# Name:            team-quota
# Namespace:       production
# Resource         Used   Hard
# --------         ----   ----
# limits.cpu       5      20
# limits.memory    10Gi   40Gi
# pods             15     50
# requests.cpu     2500m  10
# requests.memory  5Gi    20Gi
```

## まとめ

### 学んだこと

1. **RequestsとLimitsの違い**
   - Requests: 保証されるリソース（スケジューリング基準）
   - Limits: 使用可能な最大リソース

2. **QoSクラス**
   - Guaranteed: 最優先（requests = limits）
   - Burstable: 中優先（requestsあり）
   - BestEffort: 最低優先（何も指定なし）

3. **OOMKiller**
   - メモリLimits超過で発動
   - QoSクラスに基づいて優先度決定
   - 適切なLimits設定で回避

4. **CPUスロットリング**
   - CPU Limits超過でスロットリング
   - パフォーマンスに影響
   - 適切な設計で最小化

5. **実践的パターン**
   - アプリ種別ごとの推奨設定
   - LimitRangeでデフォルト設定
   - ResourceQuotaで全体制限

### ベストプラクティス

- 常にRequestsを設定（スケジューリング最適化）
- 本番環境ではLimitsも設定（暴走防止）
- 実測に基づいて値を決定
- QoSクラスを意識して設計
- LimitRangeとResourceQuotaで統制

## 参考リンク

- {{< linkcard "https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/" >}}
- {{< linkcard "https://kubernetes.io/docs/tasks/configure-pod-container/quality-service-pod/" >}}
- {{< linkcard "https://kubernetes.io/docs/concepts/policy/limit-range/" >}}
