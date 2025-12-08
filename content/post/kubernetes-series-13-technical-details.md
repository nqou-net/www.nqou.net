---
title: "HorizontalPodAutoscalerで自動スケーリング - 負荷に応じた動的拡張（技術詳細）"
draft: true
tags:
- kubernetes
- autoscaling
- hpa
- metrics-server
- custom-metrics
description: "Kubernetes HPA（HorizontalPodAutoscaler）の完全ガイド。メトリクスベースの自動スケール、Metrics Serverの設定、カスタムメトリクスの活用を実践的に解説。"
---

## はじめに

アプリケーションの負荷は時間帯やイベントによって大きく変動します。Kubernetes HPA（HorizontalPodAutoscaler）を使うと、CPU使用率やカスタムメトリクスに基づいて、自動的にPod数を増減できます。本記事では、HPAの仕組みから実践的な設定方法まで徹底解説します。

## 1. HPA（HorizontalPodAutoscaler）の基本

### 1.1 HPAとは

**目的**: 負荷に応じて自動的にPod数を調整

```
負荷低 → Pod数減少 → コスト削減
負荷高 → Pod数増加 → パフォーマンス維持
```

**動作フロー**:
```
1. メトリクス収集（CPU、メモリ、カスタム）
   ↓
2. 現在の平均値と目標値を比較
   ↓
3. 必要なPod数を計算
   ↓
4. Deploymentのreplicas数を更新
   ↓
5. 30秒後に再評価（デフォルト）
```

### 1.2 基本的なHPA設定

```yaml
# hpa-basic.yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: myapp-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: myapp           # 対象Deployment
  minReplicas: 2          # 最小Pod数
  maxReplicas: 10         # 最大Pod数
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70  # CPU使用率70%を目標
```

**対象Deploymentの準備**:
```yaml
# myapp-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
spec:
  replicas: 2  # 初期値（HPAが上書き）
  selector:
    matchLabels:
      app: myapp
  template:
    metadata:
      labels:
        app: myapp
    spec:
      containers:
      - name: app
        image: nginx:1.21
        resources:
          requests:
            cpu: "200m"    # HPAにはrequestsが必須
            memory: "256Mi"
          limits:
            cpu: "500m"
            memory: "512Mi"
        ports:
        - containerPort: 80
```

**デプロイと確認**:
```bash
# Deploymentをデプロイ
kubectl apply -f myapp-deployment.yaml

# HPAをデプロイ
kubectl apply -f hpa-basic.yaml

# HPA状態確認
kubectl get hpa
# NAME        REFERENCE          TARGETS   MINPODS   MAXPODS   REPLICAS   AGE
# myapp-hpa   Deployment/myapp   15%/70%   2         10        2          30s
#                                 ↑
#                          現在15%, 目標70%

# 詳細確認
kubectl describe hpa myapp-hpa
# Metrics:
#   Resource cpu on pods  (as a percentage of request):  15% (30m) / 70%
# Min replicas:  2
# Max replicas:  10
# Deployment pods:  2 current / 2 desired
```

## 2. Metrics Serverのセットアップ

HPAが動作するには、Metrics Serverが必要です。

### 2.1 Metrics Serverのインストール

#### minikubeの場合

```bash
# アドオンとして有効化
minikube addons enable metrics-server

# 確認
kubectl get deployment metrics-server -n kube-system
# NAME             READY   UP-TO-DATE   AVAILABLE   AGE
# metrics-server   1/1     1            1           30s
```

#### 通常のクラスタの場合

```bash
# 公式マニフェストをデプロイ
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# 自己署名証明書を使う場合（開発環境のみ）
kubectl patch deployment metrics-server -n kube-system --type='json' \
  -p='[{"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--kubelet-insecure-tls"}]'

# 起動確認
kubectl get pods -n kube-system -l k8s-app=metrics-server
# NAME                              READY   STATUS    RESTARTS   AGE
# metrics-server-5f9f776df5-abcde   1/1     Running   0          1m

# APIが利用可能になるまで待つ（約1分）
kubectl top nodes
# NAME       CPU(cores)   CPU%   MEMORY(bytes)   MEMORY%
# minikube   250m         12%    2048Mi          50%

kubectl top pods
# NAME                     CPU(cores)   MEMORY(bytes)
# myapp-7d8c9f5b6d-abc12   50m          128Mi
# myapp-7d8c9f5b6d-def34   45m          120Mi
```

### 2.2 Metrics Serverのトラブルシューティング

**問題1: メトリクスが取得できない**

```bash
# エラー確認
kubectl logs -n kube-system deployment/metrics-server
# E1208 unable to fully collect metrics: unable to fetch metrics from Kubelet

# ノードの状態確認
kubectl describe node minikube | grep -A 5 Conditions
# Conditions:
#   Type             Status  Reason                       Message
#   ----             ------  ------                       -------
#   MemoryPressure   False   KubeletHasSufficientMemory   kubelet has sufficient memory
#   DiskPressure     False   KubeletHasNoDiskPressure     kubelet has no disk pressure
```

**解決策**:
```bash
# TLS検証を無効化（開発環境のみ）
kubectl patch deployment metrics-server -n kube-system \
  --type='json' \
  -p='[
    {"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--kubelet-insecure-tls"},
    {"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--kubelet-preferred-address-types=InternalIP,ExternalIP,Hostname"}
  ]'
```

## 3. メトリクスベースの自動スケール

### 3.1 CPU使用率ベース

```yaml
# hpa-cpu.yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: cpu-based-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: myapp
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 50  # CPU 50%を目標
  behavior:  # スケーリング動作の制御
    scaleDown:
      stabilizationWindowSeconds: 300  # 5分間安定してから縮小
      policies:
      - type: Percent
        value: 50       # 一度に50%まで削減可能
        periodSeconds: 60
      - type: Pods
        value: 2        # または一度に2 Podまで削減
        periodSeconds: 60
    scaleUp:
      stabilizationWindowSeconds: 0  # 即座に拡大
      policies:
      - type: Percent
        value: 100      # 一度に100%（2倍）まで増加可能
        periodSeconds: 15
      - type: Pods
        value: 4        # または一度に4 Podまで増加
        periodSeconds: 15
```

**負荷テスト**:
```bash
# 負荷生成Pod
kubectl run -i --tty load-generator --rm --image=busybox --restart=Never -- /bin/sh

# Pod内で負荷をかける
while true; do wget -q -O- http://myapp-service; done

# 別のターミナルでHPA監視
kubectl get hpa cpu-based-hpa -w
# NAME             REFERENCE          TARGETS    MINPODS   MAXPODS   REPLICAS   AGE
# cpu-based-hpa    Deployment/myapp   15%/50%    2         10        2          1m
# cpu-based-hpa    Deployment/myapp   75%/50%    2         10        2          2m  ← 負荷上昇
# cpu-based-hpa    Deployment/myapp   75%/50%    2         10        4          2m  ← スケールアップ
# cpu-based-hpa    Deployment/myapp   45%/50%    2         10        4          3m  ← 安定

# Pod数の変化を確認
kubectl get pods -l app=myapp -w
```

**Pod数の計算式**:
```
必要Pod数 = ceil(現在のPod数 × 現在の平均メトリクス / 目標メトリクス)

例:
現在2 Pods, 平均CPU 75%, 目標50%
→ ceil(2 × 75 / 50) = ceil(3) = 3 Pods

現在3 Pods, 平均CPU 80%, 目標50%
→ ceil(3 × 80 / 50) = ceil(4.8) = 5 Pods
```

### 3.2 メモリ使用率ベース

```yaml
# hpa-memory.yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: memory-based-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: myapp
  minReplicas: 2
  maxReplicas: 8
  metrics:
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80  # メモリ80%を目標
```

**注意点**:
- メモリは解放されにくい（Java、Goなど）
- スケールダウンが遅い
- CPU + メモリの組み合わせ推奨

### 3.3 複数メトリクスの組み合わせ

```yaml
# hpa-multi-metrics.yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: multi-metrics-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: myapp
  minReplicas: 2
  maxReplicas: 20
  metrics:
  # CPU使用率
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  # メモリ使用率
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
  # リクエスト数（カスタムメトリクス）
  - type: Pods
    pods:
      metric:
        name: http_requests_per_second
      target:
        type: AverageValue
        averageValue: "1000"  # 1Pod当たり1000 req/s
```

**計算ロジック**:
```
各メトリクスで必要Pod数を計算
→ 最大値を採用（最も厳しい条件）

例:
CPU: 3 Pods必要
Memory: 2 Pods必要
Requests: 5 Pods必要
→ 5 Podsにスケール
```

## 4. カスタムメトリクス

### 4.1 Prometheus Adapterのセットアップ

```bash
# Helmでインストール
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# Prometheusをインストール（メトリクス収集）
helm install prometheus prometheus-community/prometheus \
  --namespace monitoring --create-namespace

# Prometheus Adapterをインストール（HPA連携）
helm install prometheus-adapter prometheus-community/prometheus-adapter \
  --namespace monitoring \
  --set prometheus.url=http://prometheus-server.monitoring.svc \
  --set prometheus.port=80
```

**カスタムメトリクス設定**:
```yaml
# prometheus-adapter-config.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: adapter-config
  namespace: monitoring
data:
  config.yaml: |
    rules:
    - seriesQuery: 'http_requests_total{namespace!="",pod!=""}'
      resources:
        overrides:
          namespace: {resource: "namespace"}
          pod: {resource: "pod"}
      name:
        matches: "^(.*)_total$"
        as: "${1}_per_second"
      metricsQuery: 'rate(http_requests_total{<<.LabelMatchers>>}[1m])'
```

### 4.2 アプリケーションからメトリクスを公開

**Go言語の例**:
```go
// main.go
package main

import (
    "net/http"
    "github.com/prometheus/client_golang/prometheus"
    "github.com/prometheus/client_golang/prometheus/promhttp"
)

var (
    httpRequests = prometheus.NewCounterVec(
        prometheus.CounterOpts{
            Name: "http_requests_total",
            Help: "Total number of HTTP requests",
        },
        []string{"path", "method", "status"},
    )
)

func init() {
    prometheus.MustRegister(httpRequests)
}

func handler(w http.ResponseWriter, r *http.Request) {
    // リクエスト処理
    w.Write([]byte("Hello, World!"))
    
    // メトリクス記録
    httpRequests.WithLabelValues(r.URL.Path, r.Method, "200").Inc()
}

func main() {
    http.HandleFunc("/", handler)
    http.Handle("/metrics", promhttp.Handler())  // Prometheusエンドポイント
    http.ListenAndServe(":8080", nil)
}
```

**Kubernetes ServiceMonitor**:
```yaml
# servicemonitor.yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: myapp-monitor
  namespace: default
spec:
  selector:
    matchLabels:
      app: myapp
  endpoints:
  - port: metrics
    interval: 30s
```

### 4.3 カスタムメトリクスベースのHPA

```yaml
# hpa-custom-metrics.yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: custom-metrics-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: myapp
  minReplicas: 2
  maxReplicas: 50
  metrics:
  # リクエスト数
  - type: Pods
    pods:
      metric:
        name: http_requests_per_second
      target:
        type: AverageValue
        averageValue: "500"  # 1 Pod当たり500 req/s
  # レスポンスタイム
  - type: Pods
    pods:
      metric:
        name: http_request_duration_seconds
      target:
        type: AverageValue
        averageValue: "0.5"  # 平均500ms
  # キュー長
  - type: Object
    object:
      metric:
        name: queue_depth
      describedObject:
        apiVersion: v1
        kind: Service
        name: rabbitmq
      target:
        type: Value
        value: "100"  # キュー100件以下
```

**確認**:
```bash
# カスタムメトリクスAPI確認
kubectl get --raw /apis/custom.metrics.k8s.io/v1beta1 | jq .

# 特定メトリクス確認
kubectl get --raw "/apis/custom.metrics.k8s.io/v1beta1/namespaces/default/pods/*/http_requests_per_second" | jq .

# HPA状態確認
kubectl get hpa custom-metrics-hpa
# NAME                  REFERENCE          TARGETS                MINPODS   MAXPODS   REPLICAS
# custom-metrics-hpa    Deployment/myapp   450/500 (requests)     2         50        2
```

## 5. 実践的なHPA設計パターン

### 5.1 Webアプリケーション

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: web-app-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: web-app
  minReplicas: 3      # 常時3台（冗長性）
  maxReplicas: 100    # ピーク時100台
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 60
  - type: Pods
    pods:
      metric:
        name: http_requests_per_second
      target:
        type: AverageValue
        averageValue: "1000"
  behavior:
    scaleUp:
      stabilizationWindowSeconds: 30  # 早めに拡大
      policies:
      - type: Percent
        value: 100
        periodSeconds: 30
    scaleDown:
      stabilizationWindowSeconds: 600  # 10分間安定確認
      policies:
      - type: Pods
        value: 1
        periodSeconds: 120  # 2分ごとに1台ずつ削減
```

### 5.2 バッチ処理ワーカー

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: worker-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: batch-worker
  minReplicas: 0      # アイドル時は0台（コスト削減）
  maxReplicas: 50
  metrics:
  - type: Object
    object:
      metric:
        name: queue_messages_ready
      describedObject:
        apiVersion: v1
        kind: Service
        name: rabbitmq
      target:
        type: AverageValue
        averageValue: "10"  # 1 Worker当たり10メッセージ
  behavior:
    scaleUp:
      stabilizationWindowSeconds: 0
      policies:
      - type: Percent
        value: 200  # 一度に3倍まで増加可能
        periodSeconds: 15
    scaleDown:
      stabilizationWindowSeconds: 300
      policies:
      - type: Pods
        value: 5    # 一度に5台まで削減
        periodSeconds: 60
```

### 5.3 時間帯別の事前スケール（CronHPA）

```yaml
# keda-scaledobject.yaml（KEDAを使用）
apiVersion: keda.sh/v1alpha1
kind: ScaledObject
metadata:
  name: scheduled-hpa
spec:
  scaleTargetRef:
    name: myapp
  minReplicaCount: 2
  maxReplicaCount: 100
  triggers:
  # 平日8-18時は最小10台
  - type: cron
    metadata:
      timezone: Asia/Tokyo
      start: 0 8 * * 1-5
      end: 0 18 * * 1-5
      desiredReplicas: "10"
  # その他の時間は最小2台
  - type: cron
    metadata:
      timezone: Asia/Tokyo
      start: 0 18 * * 1-5
      end: 0 8 * * 1-5
      desiredReplicas: "2"
  # CPU使用率ベースのスケール
  - type: cpu
    metadata:
      type: Utilization
      value: "70"
```

## 6. トラブルシューティング

### 6.1 スケールしない問題

```bash
# HPA状態確認
kubectl describe hpa myapp-hpa
# Conditions:
#   Type            Status  Reason                   Message
#   ----            ------  ------                   -------
#   AbleToScale     False   FailedGetResourceMetric  missing request for cpu

# 原因: Deploymentにresources.requestsがない
```

**解決策**:
```yaml
spec:
  template:
    spec:
      containers:
      - name: app
        resources:
          requests:
            cpu: "200m"  # 必須
```

### 6.2 頻繁なスケールイン/アウト

```bash
# HPA履歴確認
kubectl get hpa myapp-hpa -w
# REPLICAS   AGE
# 3          1m
# 5          2m  ← 急増
# 3          3m  ← 急減
# 6          4m  ← また急増（フラッピング）
```

**解決策**:
```yaml
behavior:
  scaleDown:
    stabilizationWindowSeconds: 300  # 5分間安定を確認
  scaleUp:
    stabilizationWindowSeconds: 60   # 1分間安定を確認
```

## まとめ

### 学んだこと

1. **HPAの基本**
   - メトリクスベースの自動スケール
   - minReplicas/maxReplicasで範囲指定

2. **Metrics Server**
   - HPAに必須
   - CPU/メモリメトリクス提供

3. **スケーリング戦略**
   - CPU/メモリベース
   - カスタムメトリクス
   - 複数メトリクス組み合わせ

4. **実践パターン**
   - Webアプリ: 早めに拡大、ゆっくり縮小
   - ワーカー: キュー長ベース
   - 時間帯別: CronHPA

### ベストプラクティス

- resources.requestsを必ず設定
- behaviorで急激な変動を防ぐ
- 本番環境ではカスタムメトリクス推奨
- スケールダウンは慎重に設定

## 参考リンク

- {{< linkcard "https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/" >}}
- {{< linkcard "https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale-walkthrough/" >}}
- {{< linkcard "https://github.com/kubernetes-sigs/metrics-server" >}}
