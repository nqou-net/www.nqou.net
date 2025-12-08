---
title: "Kubernetesを完全に理解した（第14回）- 監視とログ基盤"
draft: true
tags:
- kubernetes
- logging
- monitoring
- prometheus
- grafana
description: "システムの健全性を常に把握するための監視基盤を構築。ログとメトリクスを可視化し、問題の早期発見を実現します。"
---

## はじめに - 第13回の振り返りと第14回で学ぶこと

前回の第13回では、HPAによる自動スケーリングについて学びました。CPU使用率やメモリ使用率に基づいて、負荷に応じて自動的にPod数を増減させる仕組みを理解し、トラフィック変動に対応するスケーラブルなシステムを構築できました。

今回の第14回では、**監視とログ基盤** について学びます。本番環境でKubernetesを安定運用するために不可欠な、ログ収集とメトリクス監視の仕組みを実践します。

本記事で学ぶ内容：

- Kubernetesにおけるログ収集アーキテクチャ
- FluentBitによる効率的なログ収集
- Prometheus/Grafanaによるメトリクス監視
- アラート設定と通知
- 実践的な監視ダッシュボード

## ログ収集の基礎

### Kubernetesのログの種類

```
1. コンテナログ:
   アプリケーションの標準出力/エラー出力

2. Nodeログ:
   kubelet、container runtimeのログ

3. クラスタコンポーネントログ:
   API Server、etcd、schedulerのログ
```

### ログ収集パターン

**パターン1: Node-levelロギング（推奨）**

```
各Node
├── DaemonSet: FluentBit
│   ├── /var/log/containers/*.log を収集
│   └── 中央ログストアに転送
└── Pods
    ├── stdout/stderr → /var/log/containers/
    └── 直接収集される
```

**パターン2: サイドカーパターン**

```yaml
# sidecar-logging.yaml
apiVersion: v1
kind: Pod
metadata:
  name: app-with-sidecar
spec:
  containers:
  # メインアプリケーション
  - name: app
    image: myapp:1.0
    volumeMounts:
    - name: logs
      mountPath: /var/log/app
  
  # ログ収集サイドカー
  - name: fluentbit
    image: fluent/fluent-bit:2.0
    volumeMounts:
    - name: logs
      mountPath: /var/log/app
  
  volumes:
  - name: logs
    emptyDir: {}
```

## FluentBitによるログ収集

### FluentBit DaemonSetのデプロイ

```yaml
# fluentbit-daemonset.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: fluent-bit
  namespace: logging
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: fluent-bit-read
rules:
- apiGroups: [""]
  resources:
  - namespaces
  - pods
  verbs: ["get", "list", "watch"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: fluent-bit-read
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: fluent-bit-read
subjects:
- kind: ServiceAccount
  name: fluent-bit
  namespace: logging
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: fluent-bit-config
  namespace: logging
data:
  fluent-bit.conf: |
    [SERVICE]
        Flush         5
        Log_Level     info
        Daemon        off

    [INPUT]
        Name              tail
        Path              /var/log/containers/*.log
        Parser            docker
        Tag               kube.*
        Refresh_Interval  5

    [FILTER]
        Name                kubernetes
        Match               kube.*
        Kube_URL            https://kubernetes.default.svc:443
        Merge_Log           On
        Keep_Log            Off

    [OUTPUT]
        Name   stdout
        Match  *
---
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: fluent-bit
  namespace: logging
spec:
  selector:
    matchLabels:
      app: fluent-bit
  template:
    metadata:
      labels:
        app: fluent-bit
    spec:
      serviceAccountName: fluent-bit
      containers:
      - name: fluent-bit
        image: fluent/fluent-bit:2.0
        resources:
          limits:
            memory: "256Mi"
            cpu: "200m"
          requests:
            memory: "128Mi"
            cpu: "100m"
        volumeMounts:
        - name: varlog
          mountPath: /var/log
        - name: varlibdockercontainers
          mountPath: /var/lib/docker/containers
          readOnly: true
        - name: fluent-bit-config
          mountPath: /fluent-bit/etc/
      volumes:
      - name: varlog
        hostPath:
          path: /var/log
      - name: varlibdockercontainers
        hostPath:
          path: /var/lib/docker/containers
      - name: fluent-bit-config
        configMap:
          name: fluent-bit-config
```

**デプロイ：**

```bash
# Namespaceの作成
kubectl create namespace logging

# FluentBitのデプロイ
kubectl apply -f fluentbit-daemonset.yaml

# 確認
kubectl get pods -n logging
# NAME               READY   STATUS    RESTARTS   AGE
# fluent-bit-abc12   1/1     Running   0          30s
# fluent-bit-def34   1/1     Running   0          30s

# ログ確認
kubectl logs -n logging fluent-bit-abc12
# [info] [input:tail:tail.0] inotify_fs_add(): inode=12345
```

### 構造化ログの出力

**アプリケーション側のベストプラクティス：**

```go
// main.go - 構造化ログ（JSON）
package main

import (
    "go.uber.org/zap"
    "net/http"
)

var logger *zap.Logger

func init() {
    logger, _ = zap.NewProduction()
}

func handler(w http.ResponseWriter, r *http.Request) {
    logger.Info("HTTP request received",
        zap.String("method", r.Method),
        zap.String("path", r.URL.Path),
        zap.String("remote_addr", r.RemoteAddr),
    )
    
    w.Write([]byte("OK"))
    
    logger.Info("HTTP response sent",
        zap.Int("status_code", 200),
        zap.String("path", r.URL.Path),
    )
}

func main() {
    defer logger.Sync()
    http.HandleFunc("/", handler)
    logger.Info("Server starting", zap.Int("port", 8080))
    http.ListenAndServe(":8080", nil)
}
```

**出力例（JSON）：**

```json
{
  "level": "info",
  "ts": 1701993600.123,
  "msg": "HTTP request received",
  "method": "GET",
  "path": "/api/users",
  "remote_addr": "10.1.0.5:54321"
}
```

## Prometheus/Grafanaによるメトリクス監視

### Prometheusのアーキテクチャ

```
┌─────────────────────────────────────┐
│        Prometheus Server            │
│  ┌──────────────────────────────┐   │
│  │  Time Series Database (TSDB)│   │
│  └──────────────────────────────┘   │
│  ┌──────────────────────────────┐   │
│  │  Retrieval (Scraper)         │   │
│  └──────────────────────────────┘   │
└─────────────────────────────────────┘
         ↑           ↑            ↑
         │           │            │
    ┌────┴───┐  ┌────┴────┐  ┌───┴────┐
    │ Pods   │  │ Nodes   │  │ K8s API│
    │/metrics│  │/metrics │  │        │
    └────────┘  └─────────┘  └────────┘
```

### kube-prometheus-stackのインストール

```bash
# Helmリポジトリ追加
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

# インストール
helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring --create-namespace \
  --set prometheus.prometheusSpec.retention=30d \
  --set grafana.adminPassword=admin

# 確認
kubectl get pods -n monitoring
# NAME                                                   READY   STATUS
# prometheus-kube-prometheus-operator-abc123             1/1     Running
# prometheus-prometheus-kube-prometheus-prometheus-0     2/2     Running
# prometheus-grafana-def456                              3/3     Running
# alertmanager-prometheus-kube-prometheus-alertmgr-0     2/2     Running

# Grafanaアクセス
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80
# http://localhost:3000 (admin/admin)
```

### アプリケーションのメトリクス公開

**ServiceMonitorの作成：**

```yaml
# servicemonitor.yaml
apiVersion: v1
kind: Service
metadata:
  name: myapp-metrics
  namespace: default
  labels:
    app: myapp
spec:
  selector:
    app: myapp
  ports:
  - name: metrics
    port: 8080
    targetPort: 8080
---
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: myapp-monitor
  namespace: default
  labels:
    release: prometheus
spec:
  selector:
    matchLabels:
      app: myapp
  endpoints:
  - port: metrics
    interval: 30s
    path: /metrics
```

**アプリケーション側の実装：**

```go
// main.go - Prometheusメトリクス
package main

import (
    "net/http"
    "github.com/prometheus/client_golang/prometheus"
    "github.com/prometheus/client_golang/prometheus/promhttp"
)

var (
    httpRequestsTotal = prometheus.NewCounterVec(
        prometheus.CounterOpts{
            Name: "http_requests_total",
            Help: "Total number of HTTP requests",
        },
        []string{"method", "path", "status"},
    )
    
    httpRequestDuration = prometheus.NewHistogramVec(
        prometheus.HistogramOpts{
            Name:    "http_request_duration_seconds",
            Help:    "HTTP request duration in seconds",
            Buckets: []float64{.005, .01, .025, .05, .1, .25, .5, 1, 2.5, 5, 10},
        },
        []string{"method", "path"},
    )
)

func init() {
    prometheus.MustRegister(httpRequestsTotal)
    prometheus.MustRegister(httpRequestDuration)
}

func handler(w http.ResponseWriter, r *http.Request) {
    timer := prometheus.NewTimer(httpRequestDuration.WithLabelValues(r.Method, r.URL.Path))
    defer timer.ObserveDuration()
    
    w.Write([]byte("OK"))
    
    httpRequestsTotal.WithLabelValues(r.Method, r.URL.Path, "200").Inc()
}

func main() {
    http.HandleFunc("/", handler)
    http.Handle("/metrics", promhttp.Handler())
    http.ListenAndServe(":8080", nil)
}
```

**デプロイ：**

```bash
kubectl apply -f servicemonitor.yaml

# PrometheusがTargetとして認識しているか確認
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090
# http://localhost:9090/targets で確認
```

### PromQLクエリ例

```promql
# リクエスト数（過去5分間）
sum(rate(http_requests_total[5m])) by (path)

# エラー率
sum(rate(http_requests_total{status=~"5.."}[5m])) 
  / 
sum(rate(http_requests_total[5m]))

# P95レスポンスタイム
histogram_quantile(0.95, 
  sum(rate(http_request_duration_seconds_bucket[5m])) by (le, path)
)

# CPU使用率（Pod単位）
sum(rate(container_cpu_usage_seconds_total{pod=~"myapp-.*"}[5m])) by (pod)

# メモリ使用量
sum(container_memory_working_set_bytes{pod=~"myapp-.*"}) by (pod)
```

## アラート設定

### PrometheusRuleの定義

```yaml
# prometheus-rules.yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: myapp-alerts
  namespace: monitoring
  labels:
    release: prometheus
spec:
  groups:
  - name: myapp.rules
    interval: 30s
    rules:
    # エラー率が5%を超えた
    - alert: HighErrorRate
      expr: |
        sum(rate(http_requests_total{status=~"5.."}[5m])) 
          / 
        sum(rate(http_requests_total[5m])) 
          > 0.05
      for: 5m
      labels:
        severity: critical
      annotations:
        summary: "High error rate detected"
        description: "Error rate is {{ $value | humanizePercentage }}"
    
    # レスポンスタイムが遅い
    - alert: HighLatency
      expr: |
        histogram_quantile(0.95, 
          sum(rate(http_request_duration_seconds_bucket[5m])) by (le)
        ) > 1
      for: 10m
      labels:
        severity: warning
      annotations:
        summary: "High latency detected"
        description: "P95 latency is {{ $value }}s"
    
    # Podが頻繁に再起動
    - alert: PodRestarting
      expr: |
        rate(kube_pod_container_status_restarts_total{pod=~"myapp-.*"}[15m]) > 0
      for: 5m
      labels:
        severity: warning
      annotations:
        summary: "Pod {{ $labels.pod }} is restarting"
        description: "Pod has restarted {{ $value }} times"
    
    # メモリ使用量が高い
    - alert: HighMemoryUsage
      expr: |
        sum(container_memory_working_set_bytes{pod=~"myapp-.*"}) by (pod)
          /
        sum(container_spec_memory_limit_bytes{pod=~"myapp-.*"}) by (pod)
          > 0.9
      for: 5m
      labels:
        severity: warning
      annotations:
        summary: "High memory usage on {{ $labels.pod }}"
        description: "Memory usage is {{ $value | humanizePercentage }}"
```

```bash
kubectl apply -f prometheus-rules.yaml

# ルール確認
kubectl get prometheusrules -n monitoring
```

### Alertmanagerの設定

```yaml
# alertmanager-config.yaml
apiVersion: v1
kind: Secret
metadata:
  name: alertmanager-prometheus-kube-prometheus-alertmanager
  namespace: monitoring
stringData:
  alertmanager.yaml: |
    global:
      resolve_timeout: 5m
      slack_api_url: 'https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK'
    
    route:
      group_by: ['alertname', 'cluster', 'service']
      group_wait: 10s
      group_interval: 10s
      repeat_interval: 12h
      receiver: 'slack-notifications'
      routes:
      # Critical alerts
      - match:
          severity: critical
        receiver: 'slack-notifications'
      # Warning alerts
      - match:
          severity: warning
        receiver: 'slack-notifications'
    
    receivers:
    # Slack通知
    - name: 'slack-notifications'
      slack_configs:
      - channel: '#alerts'
        title: '{{ .GroupLabels.alertname }}'
        text: >-
          {{ range .Alerts }}
            *Alert:* {{ .Annotations.summary }}
            *Description:* {{ .Annotations.description }}
            *Severity:* {{ .Labels.severity }}
          {{ end }}
```

```bash
kubectl apply -f alertmanager-config.yaml

# Alertmanager再起動
kubectl rollout restart statefulset/alertmanager-prometheus-kube-prometheus-alertmgr -n monitoring
```

## Grafanaダッシュボード

### Golden Signalsダッシュボード

```
┌────────────────────────────────────────┐
│          Golden Signals                │
├────────────────────────────────────────┤
│ Latency    │ P50: 50ms   P95: 200ms  │
│ Traffic    │ 1000 req/s              │
│ Errors     │ 0.5%                    │
│ Saturation │ CPU: 60%  Memory: 70%   │
└────────────────────────────────────────┘
```

**PromQLクエリ：**

```promql
# Latency (P95)
histogram_quantile(0.95, sum(rate(http_request_duration_seconds_bucket[5m])) by (le))

# Traffic (req/s)
sum(rate(http_requests_total[5m]))

# Errors (%)
sum(rate(http_requests_total{status=~"5.."}[5m])) / sum(rate(http_requests_total[5m]))

# Saturation (CPU%)
sum(rate(container_cpu_usage_seconds_total[5m])) / sum(container_spec_cpu_quota / container_spec_cpu_period)
```

### ダッシュボードのインポート

```bash
# Grafanaにアクセス
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80

# ブラウザで http://localhost:3000
# 1. Dashboards → Import
# 2. Grafana.com Dashboard ID を入力:
#    - 315 (Kubernetes cluster monitoring)
#    - 6417 (Kubernetes Pods monitoring)
# 3. Prometheus データソースを選択
# 4. Import
```

## 実践的な監視設計

### 監視レベルの設計

```yaml
# 監視レベル定義
levels:
  # Level 1: インフラ監視
  infrastructure:
    - Node CPU/Memory使用率
    - Disk使用率
    - Network帯域
  
  # Level 2: Kubernetes監視
  kubernetes:
    - Pod状態（Running/Failed）
    - ReplicaSet数
    - リソース使用量
  
  # Level 3: アプリケーション監視
  application:
    - リクエスト数
    - エラー率
    - レスポンスタイム
    - カスタムメトリクス
  
  # Level 4: ビジネス監視
  business:
    - コンバージョン率
    - アクティブユーザー数
    - 売上
```

### アラートの優先度

| 優先度 | 対応時間 | 通知先 | 例 |
|-------|---------|-------|---|
| Critical | 即座 | PagerDuty + Slack | サービス停止、データ損失 |
| High | 30分以内 | Slack | エラー率5%超過 |
| Warning | 1時間以内 | Slack | メモリ使用率90% |
| Info | 翌営業日 | Email | 定期メンテナンス |

## まとめ

### 今回学んだこと

1. **ログ収集基盤**
   - FluentBit DaemonSetでログ収集
   - 構造化ログ（JSON）推奨

2. **メトリクス監視**
   - Prometheus + Grafana
   - ServiceMonitorで自動検出
   - PromQLでクエリ

3. **アラート設定**
   - PrometheusRuleで定義
   - Alertmanagerで通知
   - Slack連携

4. **監視設計**
   - Golden Signals
   - 監視レベルの階層化
   - アラート優先度の設定

### ベストプラクティス

- ログは構造化（JSON）で出力
- メトリクスは標準的な命名規則を遵守
- アラートは適切な閾値と継続時間を設定
- ダッシュボードはGolden Signalsを中心に
- 定期的な監視基盤の見直し

## 次回予告

次回の第15回では、**バックアップとDR（災害復旧）** について学びます。etcdバックアップ、Veleroによるアプリケーションバックアップ、そして万が一の障害に備えた復旧計画について実践します。シリーズ最終回です。お楽しみに！
