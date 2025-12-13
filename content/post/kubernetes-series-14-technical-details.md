---
title: "Loggingとモニタリング基盤 - 可観測性を実現する（技術詳細）"
draft: true
tags:
- kubernetes
- logging
- monitoring
- fluentd
- prometheus
- grafana
description: "Kubernetes環境での完全なロギングとモニタリング基盤の構築ガイド。Fluentd/FluentBit、Prometheus/Grafana、アラート設定を実践的に解説。"
---

## はじめに

本番環境でKubernetesを運用するには、適切なロギングとモニタリング基盤が不可欠です。本記事では、Fluentd/FluentBitによるログ収集、Prometheus/Grafanaによるメトリクス監視、効果的なアラート設定について、実践的に解説します。

## 1. Kubernetesにおけるロギングアーキテクチャ

### 1.1 ログの種類と収集方法

**3つのログレベル**:
```
1. コンテナログ: アプリケーションの標準出力/エラー出力
2. Nodeログ: kubelet、container runtimeのログ
3. クラスタコンポーネントログ: API Server、etcd、schedulerのログ
```

**ログ収集パターン**:

#### パターン1: Node-levelロギング（推奨）

```
各Node
├── DaemonSet: Fluentd/FluentBit
│   ├── /var/log/containers/*.log を収集
│   └── 中央ログストアに転送
└── Pods
    ├── stdout/stderr → /var/log/containers/
    └── ファイルログ → Volume経由で収集
```

#### パターン2: サイドカーパターン

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
    - name: config
      mountPath: /fluent-bit/etc/
  
  volumes:
  - name: logs
    emptyDir: {}
  - name: config
    configMap:
      name: fluentbit-config
```

### 1.2 ログの保存先

**選択肢**:
1. **Elasticsearch**: 全文検索、Kibanaでの可視化
2. **Loki**: Prometheusライクな軽量ログシステム
3. **CloudWatch/Stackdriver**: クラウドネイティブ
4. **S3/GCS**: 長期保存、コスト効率的

## 2. Fluentd/FluentBitによるログ収集

### 2.1 FluentBitのDaemonSet構成（推奨）

**Fluentd vs FluentBit**:

| 項目 | Fluentd | FluentBit |
|-----|---------|----------|
| メモリ使用量 | 40MB～ | 450KB～ |
| パフォーマンス | 良い | 非常に良い |
| プラグイン | 豊富 | 必要最小限 |
| 設定 | Ruby DSL | INI形式 |
| 推奨用途 | 中央集約 | Edge収集 |

#### FluentBit DaemonSetのデプロイ

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
        Parsers_File  parsers.conf

    [INPUT]
        Name              tail
        Path              /var/log/containers/*.log
        Parser            docker
        Tag               kube.*
        Refresh_Interval  5
        Mem_Buf_Limit     5MB
        Skip_Long_Lines   On

    [FILTER]
        Name                kubernetes
        Match               kube.*
        Kube_URL            https://kubernetes.default.svc:443
        Kube_CA_File        /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
        Kube_Token_File     /var/run/secrets/kubernetes.io/serviceaccount/token
        Kube_Tag_Prefix     kube.var.log.containers.
        Merge_Log           On
        Keep_Log            Off
        K8S-Logging.Parser  On
        K8S-Logging.Exclude On

    [OUTPUT]
        Name   es
        Match  *
        Host   elasticsearch.logging.svc
        Port   9200
        Index  kubernetes
        Type   _doc
        Logstash_Format On
        Logstash_Prefix kubernetes
        Retry_Limit False

  parsers.conf: |
    [PARSER]
        Name   docker
        Format json
        Time_Key time
        Time_Format %Y-%m-%dT%H:%M:%S.%L%z

    [PARSER]
        Name        json
        Format      json
        Time_Key    time
        Time_Format %d/%b/%Y:%H:%M:%S %z
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

**デプロイ**:
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
# fluent-bit-ghi56   1/1     Running   0          30s

# ログ確認
kubectl logs -n logging fluent-bit-abc12
# [2024/12/08 03:00:00] [ info] [input:tail:tail.0] inotify_fs_add(): inode=12345 watch_fd=1 name=/var/log/containers/myapp.log
```

### 2.2 構造化ログの出力

**アプリケーション側のベストプラクティス**:

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
        zap.String("user_agent", r.UserAgent()),
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

**出力例（JSON）**:
```json
{"level":"info","ts":1701993600.123,"msg":"HTTP request received","method":"GET","path":"/api/users","remote_addr":"10.1.0.5:54321","user_agent":"curl/7.68.0"}
```

### 2.3 Elasticsearch + Kibanaでのログ検索

```bash
# Elastic Stackをデプロイ（Helmチャート）
helm repo add elastic https://helm.elastic.co
helm repo update

# Elasticsearch
helm install elasticsearch elastic/elasticsearch \
  --namespace logging \
  --set replicas=3 \
  --set minimumMasterNodes=2

# Kibana
helm install kibana elastic/kibana \
  --namespace logging \
  --set elasticsearchHosts="http://elasticsearch-master:9200"

# アクセス
kubectl port-forward -n logging svc/kibana-kibana 5601:5601
# ブラウザで http://localhost:5601
```

**Kibanaでのクエリ例**:
```
# 特定Podのエラーログ
kubernetes.pod_name:"myapp-*" AND level:"error"

# 特定時間範囲
@timestamp:[now-1h TO now] AND kubernetes.namespace_name:"production"

# HTTPステータスコード5xx
status_code:>=500 AND status_code:<600

# レスポンスタイムが遅い
response_time_ms:>1000
```

## 3. Prometheus/Grafanaによるメトリクス監視

### 3.1 Prometheusアーキテクチャ

```
┌─────────────────────────────────────────┐
│           Prometheus Server             │
│  ┌──────────────────────────────────┐   │
│  │   Time Series Database (TSDB)   │   │
│  └──────────────────────────────────┘   │
│  ┌──────────────────────────────────┐   │
│  │   Retrieval (Scraper)            │   │
│  └──────────────────────────────────┘   │
│  ┌──────────────────────────────────┐   │
│  │   HTTP Server (API/UI)           │   │
│  └──────────────────────────────────┘   │
└─────────────────────────────────────────┘
         ↑           ↑            ↑
         │           │            │
    ┌────┴───┐  ┌────┴────┐  ┌───┴────┐
    │ Pods   │  │ Nodes   │  │ K8s API│
    │/metrics│  │/metrics │  │        │
    └────────┘  └─────────┘  └────────┘
```

### 3.2 Prometheus Operatorのデプロイ

```bash
# kube-prometheus-stackをインストール
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

helm install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring --create-namespace \
  --set prometheus.prometheusSpec.retention=30d \
  --set prometheus.prometheusSpec.storageSpec.volumeClaimTemplate.spec.resources.requests.storage=50Gi \
  --set grafana.adminPassword=admin

# 確認
kubectl get pods -n monitoring
# NAME                                                   READY   STATUS    RESTARTS   AGE
# prometheus-kube-prometheus-operator-abc123             1/1     Running   0          1m
# prometheus-prometheus-kube-prometheus-prometheus-0     2/2     Running   0          1m
# prometheus-grafana-def456                              3/3     Running   0          1m
# alertmanager-prometheus-kube-prometheus-alertmgr-0     2/2     Running   0          1m

# Grafanaアクセス
kubectl port-forward -n monitoring svc/prometheus-grafana 3000:80
# http://localhost:3000 (admin/admin)
```

### 3.3 アプリケーションのメトリクス公開

#### ServiceMonitorの作成

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
    release: prometheus  # kube-prometheus-stackのラベル
spec:
  selector:
    matchLabels:
      app: myapp
  endpoints:
  - port: metrics
    interval: 30s
    path: /metrics
```

#### アプリケーション側の実装

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
    
    activeConnections = prometheus.NewGauge(
        prometheus.GaugeOpts{
            Name: "active_connections",
            Help: "Number of active connections",
        },
    )
)

func init() {
    prometheus.MustRegister(httpRequestsTotal)
    prometheus.MustRegister(httpRequestDuration)
    prometheus.MustRegister(activeConnections)
}

func handler(w http.ResponseWriter, r *http.Request) {
    timer := prometheus.NewTimer(httpRequestDuration.WithLabelValues(r.Method, r.URL.Path))
    defer timer.ObserveDuration()
    
    activeConnections.Inc()
    defer activeConnections.Dec()
    
    // ビジネスロジック
    w.Write([]byte("OK"))
    
    httpRequestsTotal.WithLabelValues(r.Method, r.URL.Path, "200").Inc()
}

func main() {
    http.HandleFunc("/", handler)
    http.Handle("/metrics", promhttp.Handler())
    http.ListenAndServe(":8080", nil)
}
```

**デプロイ**:
```bash
kubectl apply -f servicemonitor.yaml

# PrometheusがTargetとして認識しているか確認
kubectl port-forward -n monitoring svc/prometheus-kube-prometheus-prometheus 9090:9090
# http://localhost:9090/targets で確認
```

### 3.4 PromQLクエリ例

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

# Pod再起動回数
sum(kube_pod_container_status_restarts_total{pod=~"myapp-.*"}) by (pod)
```

### 3.5 Grafanaダッシュボード

**基本的なダッシュボード構成**:

```json
{
  "dashboard": {
    "title": "Application Metrics",
    "panels": [
      {
        "title": "Request Rate",
        "targets": [
          {
            "expr": "sum(rate(http_requests_total[5m])) by (path)"
          }
        ],
        "type": "graph"
      },
      {
        "title": "Error Rate",
        "targets": [
          {
            "expr": "sum(rate(http_requests_total{status=~\"5..\"}[5m])) / sum(rate(http_requests_total[5m]))"
          }
        ],
        "type": "singlestat"
      },
      {
        "title": "Response Time (P95)",
        "targets": [
          {
            "expr": "histogram_quantile(0.95, sum(rate(http_request_duration_seconds_bucket[5m])) by (le))"
          }
        ],
        "type": "graph"
      }
    ]
  }
}
```

**ConfigMapとしてダッシュボードを管理**:

```yaml
# grafana-dashboard.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: myapp-dashboard
  namespace: monitoring
  labels:
    grafana_dashboard: "1"  # Grafanaが自動検出
data:
  myapp-dashboard.json: |
    { ... JSONダッシュボード定義 ... }
```

## 4. アラート設定

### 4.1 PrometheusRuleの定義

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
        description: "Error rate is {{ $value | humanizePercentage }} (threshold: 5%)"
    
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
        description: "P95 latency is {{ $value }}s (threshold: 1s)"
    
    # Podが頻繁に再起動
    - alert: PodRestarting
      expr: |
        rate(kube_pod_container_status_restarts_total{pod=~"myapp-.*"}[15m]) > 0
      for: 5m
      labels:
        severity: warning
      annotations:
        summary: "Pod {{ $labels.pod }} is restarting"
        description: "Pod has restarted {{ $value }} times in the last 15 minutes"
    
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
    
    # Podが存在しない
    - alert: PodDown
      expr: |
        sum(up{job="myapp-metrics"}) < 2
      for: 5m
      labels:
        severity: critical
      annotations:
        summary: "Insufficient pods running"
        description: "Only {{ $value }} pods are running (expected: >= 2)"
```

```bash
kubectl apply -f prometheus-rules.yaml

# ルール確認
kubectl get prometheusrules -n monitoring
```

### 4.2 Alertmanagerの設定

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
      # Critical alerts -> PagerDuty
      - match:
          severity: critical
        receiver: 'pagerduty'
        continue: true
      # Warning alerts -> Slack
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
    
    # PagerDuty通知
    - name: 'pagerduty'
      pagerduty_configs:
      - service_key: 'YOUR_PAGERDUTY_SERVICE_KEY'
        description: '{{ .GroupLabels.alertname }}'
```

```bash
kubectl apply -f alertmanager-config.yaml

# Alertmanager再起動
kubectl rollout restart statefulset/alertmanager-prometheus-kube-prometheus-alertmgr -n monitoring
```

### 4.3 通知チャネルの設定

**Slack Webhook設定**:
```bash
# 1. Slackで Incoming Webhook を作成
# https://api.slack.com/messaging/webhooks

# 2. WebhookURLを取得
# https://hooks.slack.com/services/T00000000/B00000000/XXXXXXXXXXXXXXXXXXXX

# 3. Alertmanager設定に追加（上記参照）
```

**テスト通知**:
```bash
# 手動でアラートを発火
kubectl port-forward -n monitoring svc/alertmanager-operated 9093:9093

curl -XPOST http://localhost:9093/api/v1/alerts -d '[
  {
    "labels": {
      "alertname": "TestAlert",
      "severity": "warning"
    },
    "annotations": {
      "summary": "Test alert",
      "description": "This is a test alert"
    }
  }
]'
```

## 5. 統合監視ダッシュボード

### 5.1 Golden Signalsダッシュボード

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

**PromQLクエリ**:
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

## まとめ

### 学んだこと

1. **ロギング基盤**
   - FluentBit DaemonSetでログ収集
   - Elasticsearch + Kibanaで検索
   - 構造化ログ（JSON）推奨

2. **メトリクス監視**
   - Prometheus + Grafana
   - ServiceMonitorで自動検出
   - PromQLでクエリ

3. **アラート設定**
   - PrometheusRuleで定義
   - Alertmanagerで通知
   - Slack/PagerDuty連携

### ベストプラクティス

- ログは構造化（JSON）で出力
- メトリクスは標準的な命名規則を遵守
- アラートは適切な閾値と継続時間を設定
- ダッシュボードはGolden Signalsを中心に

## 参考リンク

- {{< linkcard "https://kubernetes.io/docs/concepts/cluster-administration/logging/" >}}
- {{< linkcard "https://prometheus.io/docs/introduction/overview/" >}}
- {{< linkcard "https://grafana.com/docs/grafana/latest/" >}}
