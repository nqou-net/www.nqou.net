---
title: "Kubernetesを完全に理解した（第12回）- リソース管理の鍵"
draft: true
tags:
- kubernetes
- resources
- limits
- capacity-planning
- performance
description: "クラスタリソースを効率的に使いながら、各アプリケーションの安定動作を保証する方法。リソース不足によるトラブルを未然に防ぎます。"
---

## はじめに - 第11回の振り返りと第12回で学ぶこと

前回の第11回では、Probeを使ったヘルスチェックについて学びました。Liveness、Readiness、Startupの3つのProbeを適切に設定することで、アプリケーションの異常を自動検出し、問題を早期に発見・修復する仕組みを理解できました。

今回の第12回では、**リソース管理** について学びます。限られたクラスタリソース（CPU・メモリ）を効率的に配分しながら、各アプリケーションの安定動作を保証する方法を実践します。

本記事で学ぶ内容：

- RequestsとLimitsの違いと役割
- QoS（Quality of Service）クラスの仕組み
- OOMKiller（Out of Memory Killer）の動作
- CPUスロットリングとパフォーマンス影響
- LimitRangeとResourceQuotaによる統制

## RequestsとLimitsの基本

### Requestsとは - リソースの保証

**Requests**: Podが最低限必要とするリソース量

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

**Requestsの役割：**

```
1. スケジューリング:
   十分なリソースを持つNodeにPodを配置

2. リソース保証:
   他のPodがどれだけ動いても、Requestsは確保される

3. 課金基準:
   クラウド環境では通常Requestsベースで課金
```

**動作確認：**

```bash
kubectl apply -f requests-example.yaml

# Nodeのリソース使用状況
kubectl describe node minikube
# Allocated resources:
#   Resource           Requests    Limits
#   --------           --------    ------
#   cpu                750m (37%)  2 (100%)
#   memory             512Mi (13%) 1Gi (26%)
#   ↑ requests-demoの250m、128Miが含まれる
```

### Limitsとは - リソースの上限

**Limits**: Podが使用できる最大リソース量

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

### Limitsを超えた場合の動作

**メモリLimits超過 → OOMKiller発動：**

```bash
# メモリを大量消費するPod
cat > memory-hog.yaml << 'EOF'
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
      limits:
        memory: "200Mi"  # 上限200MB
EOF

kubectl apply -f memory-hog.yaml

# Pod状態確認
kubectl get pods memory-hog -w
# NAME         READY   STATUS      RESTARTS   AGE
# memory-hog   1/1     Running     0          5s
# memory-hog   0/1     OOMKilled   0          10s  ← メモリ上限超過
# memory-hog   1/1     Running     1          15s  ← 自動再起動
```

**CPU Limits超過 → スロットリング：**

```bash
# CPUを大量消費するPod
cat > cpu-hog.yaml << 'EOF'
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
      limits:
        cpu: "500m"  # 上限0.5コア
EOF

kubectl apply -f cpu-hog.yaml

# CPU使用率確認
kubectl top pod cpu-hog
# NAME      CPU(cores)   MEMORY(bytes)
# cpu-hog   500m         10Mi  ← 500m（Limits）に制限
```

**重要な違い：**

```
メモリ: Limits超過 → 即座にKill（非圧縮可能リソース）
CPU:    Limits超過 → スロットリング（圧縮可能リソース）
```

## QoS（Quality of Service）クラス

Kubernetesは、RequestsとLimitsの設定に基づいて、自動的に3つのQoSクラスを割り当てます。

### Guaranteed（最優先）

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
        memory: "256Mi"  # 同じ
        cpu: "500m"      # 同じ
```

**確認：**

```bash
kubectl apply -f guaranteed-pod.yaml
kubectl get pod guaranteed-pod -o jsonpath='{.status.qosClass}'
# Guaranteed
```

**特徴：**

```
✅ 最も保護される（リソース不足時も最後まで残る）
✅ 予測可能（常に固定量のリソース使用）
✅ OOM Killerから保護（メモリ不足時も最後に削除）

使用例:
- データベース
- 本番環境の重要アプリケーション
- レイテンシ重視のサービス
```

### Burstable（中優先）

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

**特徴：**

```
✅ バースト可能（アイドル時は少なく、ピーク時は多く使える）
✅ コスト効率（Requestsベースで課金）
⚠️  リスク（Limits超過でOOMKiller）

使用例:
- Webアプリケーション（トラフィック変動あり）
- バッチ処理
- 開発・ステージング環境
```

### BestEffort（最低優先）

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

**特徴：**

```
❌ 最初に削除（リソース不足時に真っ先に削除）
⚠️  制限なし（Node全体のリソースを使える）
❌ リスク高（いつでもEvictされる可能性）

使用例:
- 非重要なバッチジョブ
- ログ収集（失っても問題ない）
- テスト用Pod
```

### QoSクラスによる優先順位

```
リソース不足時の削除順序:

BestEffort → Burstable → Guaranteed
  ↓            ↓           ↓
最初に削除   次に削除    最後まで残る
```

**実験：Node圧迫時の挙動**

```bash
# 各QoSクラスのPodをデプロイ
kubectl apply -f guaranteed-pod.yaml
kubectl apply -f burstable-pod.yaml
kubectl apply -f besteffort-pod.yaml

# メモリ圧迫を引き起こす
cat > memory-pressure.yaml << 'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: memory-eater
spec:
  containers:
  - name: stress
    image: polinux/stress
    command: ["stress"]
    args: ["--vm", "1", "--vm-bytes", "2G"]
    resources:
      requests:
        memory: "1Gi"
      limits:
        memory: "2Gi"
EOF

kubectl apply -f memory-pressure.yaml

# Evictionを観察
kubectl get pods -w
# besteffort-pod    0/1     Evicted   0   2m10s  ← 最初に削除
# burstable-pod     0/1     Evicted   0   2m15s  ← 次に削除
# guaranteed-pod    1/1     Running   0   2m30s  ← 最後まで残る
```

## OOMKiller（Out of Memory Killer）

### OOMKillerの仕組み

Linuxカーネルのメモリ不足時の自己防衛機能：

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

**OOM Score確認：**

```bash
# Podのプロセス確認
kubectl exec my-pod -- ps aux
# USER  PID  %CPU %MEM    VSZ   RSS COMMAND
# root    1   0.1  2.0 123456 78901 /app/server

# OOM Score（Node内で確認）
cat /proc/1/oom_score
# 200

# OOM Score調整値
cat /proc/1/oom_score_adj
# -998  ← Guaranteed（保護される）
# 0     ← Burstable
# 1000  ← BestEffort（最優先でKill）
```

### OOMKillerを避ける設計

**パターン1: 適切なLimits設定**

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
```

**メモリ使用量の計測：**

```bash
# 1. 本番相当の負荷をかける
kubectl run load-test --image=load-generator

# 2. メトリクスを収集
kubectl top pod myapp-pod
# NAME        CPU(cores)   MEMORY(bytes)
# myapp-pod   150m         320Mi  ← ピーク時

# 3. Limitsを設定
# ピーク320Mi + 余裕50% = 480Mi → 512Miに設定
```

**パターン2: メモリリーク対策**

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

## CPUスロットリング

### スロットリングの仕組み

Linuxの**CFS（Completely Fair Scheduler）**による制御：

```
1CPU = 100,000マイクロ秒/100ms期間

cpu.cfs_period_us = 100000  # 100ms期間
cpu.cfs_quota_us = 50000    # 500m CPU = 50ms/100ms
```

**スロットリング確認：**

```bash
kubectl exec cpu-hog -- cat /sys/fs/cgroup/cpu/cpu.stat
# nr_periods 1000         # チェック期間回数
# nr_throttled 800        # スロットリングされた回数
# throttled_time 4000000  # スロットリング時間

# スロットリング率 = 800/1000 = 80%
```

### スロットリングのパフォーマンス影響

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
      limits:
        cpu: "500m"  # この値を変えて比較
```

**ベンチマーク結果：**

```
Limitsなし（2コア使用可能）:
  実行時間: 10s

Limits: 1000m（1コア）:
  実行時間: 20s  ← 2倍

Limits: 500m（0.5コア）:
  実行時間: 40s  ← 4倍

Limits: 100m（0.1コア）:
  実行時間: 200s ← 20倍
```

### スロットリング回避策

**オプション1: Requests = Limits（推奨）**

```yaml
resources:
  requests:
    cpu: "1000m"
  limits:
    cpu: "1000m"  # 同じ値

# メリット: QoS: Guaranteed、予測可能
```

**オプション2: Limitsを削除（注意）**

```yaml
resources:
  requests:
    cpu: "500m"
  # limits なし

# リスク:
# - 他のPodに影響（Noisy Neighbor問題）
# - QoSクラスがGuaranteedにならない
```

## LimitRangeとResourceQuota

### LimitRange - デフォルト値設定

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

**動作確認：**

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

### ResourceQuota - 全体制限

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

**確認：**

```bash
kubectl apply -f namespace-quota.yaml

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

## 実践的なリソース設計

### 本番Webアプリケーション

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
        # QoS: Burstable（コスト効率的）
```

### データベース

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

### バッチ処理

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
        # QoS: Burstable（大量リソース使用）
```

## まとめ

### 今回学んだこと

1. **RequestsとLimitsの違い**
   - Requests: 保証されるリソース（スケジューリング基準）
   - Limits: 使用可能な最大リソース

2. **QoSクラス**
   - Guaranteed: 最優先（requests = limits）
   - Burstable: 中優先（requestsあり）
   - BestEffort: 最低優先（何も指定なし）

3. **OOMKillerとCPUスロットリング**
   - メモリLimits超過 → Kill
   - CPU Limits超過 → スロットリング

4. **統制ツール**
   - LimitRange: デフォルト値設定
   - ResourceQuota: 全体制限

### ベストプラクティス

- 常にRequestsを設定（スケジューリング最適化）
- 本番環境ではLimitsも設定（暴走防止）
- 実測に基づいて値を決定
- QoSクラスを意識して設計
- LimitRangeとResourceQuotaで統制

## 次回予告

次回の第13回では、**HPAで自動スケーリング** について学びます。トラフィック変動に自動で追従し、負荷に応じてPod数を動的に調整する仕組みを実践します。お楽しみに！
