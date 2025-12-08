---
title: "カオスエンジニアリング - 障害注入で可用性を証明する（技術詳細）"
draft: true
tags:
- kubernetes
- chaos-engineering
- litmuschaos
- resilience
- sre
- fault-injection
description: "LitmusChaosによるカオスエンジニアリング実践ガイド。Pod削除、ネットワーク障害、リソースストレス、SLO/SLIベースの評価まで徹底解説。"
---

## はじめに

「システムが本当に障害に強いか」を確認する最善の方法は、実際に障害を起こしてみることです。カオスエンジニアリングは、本番環境で意図的に障害を注入し、システムの回復力を検証する手法です。本記事では、LitmusChaosを使ったKubernetesでのカオスエンジニアリング実践、Pod削除・ネットワーク障害・リソースストレスの注入方法、SLO/SLIベースの評価まで徹底解説します。

## 1. カオスエンジニアリングの原則

### 1.1 カオスエンジニアリングとは

```
カオスエンジニアリングの定義 (Principles of Chaos Engineering):

「本番環境での混乱に耐えうるシステムの能力に対する信頼を
 構築するための訓練」

┌─────────────────────────────────────────────────────────┐
│ カオスエンジニアリングのサイクル                          │
│                                                         │
│  1. 定常状態の定義                                       │
│     ↓                                                   │
│  2. 仮説の立案（障害が起きても定常状態を保つ）            │
│     ↓                                                   │
│  3. 障害の注入（Pod削除、ネットワーク遅延、CPU負荷等）     │
│     ↓                                                   │
│  4. 観察と分析（定常状態から逸脱したか？）                │
│     ↓                                                   │
│  5. 学習と改善（脆弱性を発見し、修正）                    │
│     ↓                                                   │
│  （繰り返し）                                            │
└─────────────────────────────────────────────────────────┘
```

### 1.2 カオスエンジニアリングの5原則

```
1. 定常状態の仮説を立てる
   → SLI/SLOを定義（例: 99.9%の可用性、レイテンシ<200ms）

2. 現実世界のイベントをモデル化
   → 実際に起こりうる障害を再現
   ・Pod/Nodeの突然の停止
   ・ネットワークの遅延や切断
   ・リソース不足（CPU、メモリ、ディスク）
   ・外部依存サービスの障害

3. 本番環境で実験
   → ステージング環境だけでなく、本番環境でも実施
   （リスク管理しながら）

4. 自動化して継続的に実行
   → CI/CDパイプラインに組み込む

5. 影響範囲を最小化
   → Blast Radius（爆発半径）を制限
   → 段階的にスケールアップ
```

### 1.3 カオスエンジニアリング vs 従来のテスト

| 項目 | 従来のテスト | カオスエンジニアリング |
|------|------------|---------------------|
| **目的** | 既知の障害の検証 | 未知の障害の発見 |
| **環境** | テスト環境 | 本番環境（推奨） |
| **スコープ** | 個別コンポーネント | システム全体 |
| **実行** | 手動/定期的 | 自動/継続的 |
| **アプローチ** | 仮説検証 | 仮説の反証 |
| **測定** | パス/フェイル | SLI/SLO |

## 2. LitmusChaosの基礎

### 2.1 LitmusChaosとは

```
LitmusChaos アーキテクチャ:

┌─────────────────────────────────────────────────────────┐
│ Litmus Portal (Web UI)                                  │
│ ┌─────────────────────────────────────────────────────┐ │
│ │ - Chaos Workflows作成                               │ │
│ │ - 実験の実行・スケジューリング                         │ │
│ │ - 結果の可視化・分析                                  │ │
│ └──────────────────┬──────────────────────────────────┘ │
└────────────────────┼────────────────────────────────────┘
                     │
         ┌───────────┴───────────┐
         ↓                       ↓
┌─────────────────┐     ┌─────────────────┐
│ Chaos Operator  │     │ Chaos Exporter  │
│ (CRDコントローラ) │     │ (メトリクス出力) │
└────────┬────────┘     └─────────────────┘
         │
         ↓
┌─────────────────────────────────────────┐
│ ChaosEngine                             │
│ ├─ ChaosExperiment (Pod Delete)         │
│ ├─ ChaosExperiment (Network Loss)       │
│ ├─ ChaosExperiment (CPU Hog)            │
│ └─ ... (50+ experiments)                │
└─────────────────────────────────────────┘
```

### 2.2 LitmusChaosのインストール

```bash
# Litmus Chaosのインストール (Helm)
helm repo add litmuschaos https://litmuschaos.github.io/litmus-helm/
helm repo update

# Litmus Operatorのインストール
kubectl create ns litmus
helm install litmus litmuschaos/litmus \
  --namespace litmus \
  --set portal.server.service.type=LoadBalancer

# インストール確認
kubectl get pods -n litmus
# NAME                                      READY   STATUS    RESTARTS   AGE
# litmus-server-xxx                         1/1     Running   0          2m
# litmus-frontend-xxx                       1/1     Running   0          2m
# litmusportal-auth-server-xxx              1/1     Running   0          2m
# mongo-0                                   1/1     Running   0          2m

# Litmus Portalのアクセス
kubectl get svc -n litmus litmus-frontend-service
# NAME                       TYPE           CLUSTER-IP      EXTERNAL-IP
# litmus-frontend-service    LoadBalancer   10.100.200.10   xxx.elb.amazonaws.com

# デフォルト認証情報:
# Username: admin
# Password: litmus
```

### 2.3 ChaosExperiment CRDの理解

```yaml
# pod-delete-experiment.yaml
apiVersion: litmuschaos.io/v1alpha1
kind: ChaosExperiment
metadata:
  name: pod-delete
  namespace: litmus
  labels:
    name: pod-delete
spec:
  definition:
    # 実験のスコープ
    scope: Namespaced
    
    # 必要な権限
    permissions:
    - apiGroups: [""]
      resources: ["pods"]
      verbs: ["create", "delete", "get", "list", "patch", "update"]
    - apiGroups: ["apps"]
      resources: ["deployments", "statefulsets", "replicasets"]
      verbs: ["list", "get"]
    
    # 実験イメージ
    image: "litmuschaos/go-runner:latest"
    imagePullPolicy: Always
    
    # 環境変数（デフォルト値）
    env:
    - name: TOTAL_CHAOS_DURATION
      value: "30"  # 30秒間カオス継続
    
    - name: CHAOS_INTERVAL
      value: "10"  # 10秒ごとにPod削除
    
    - name: FORCE
      value: "true"  # 強制削除
    
    labels:
      name: pod-delete
```

## 3. 基本的なChaos実験

### 3.1 Pod削除実験

```yaml
# pod-delete-chaosengine.yaml
apiVersion: litmuschaos.io/v1alpha1
kind: ChaosEngine
metadata:
  name: web-app-pod-delete
  namespace: production
spec:
  # 対象アプリケーション
  appinfo:
    appns: production
    applabel: "app=web"
    appkind: deployment
  
  # Chaos ServiceAccount
  chaosServiceAccount: litmus-admin
  
  # 実験設定
  experiments:
  - name: pod-delete
    spec:
      components:
        env:
        # 削除するPod数
        - name: TOTAL_CHAOS_DURATION
          value: "60"  # 60秒間
        
        - name: CHAOS_INTERVAL
          value: "15"  # 15秒ごと
        
        # Pod選択方法（random/oldest/youngest）
        - name: PODS_AFFECTED_PERC
          value: "50"  # 50%のPodを対象
        
        - name: SEQUENCE
          value: "parallel"  # parallel or serial
        
        - name: FORCE
          value: "false"  # Graceful termination
      
      probe:
      # ヘルスチェック: HTTP応答を監視
      - name: "web-app-health"
        type: "httpProbe"
        mode: "Continuous"
        runProperties:
          probeTimeout: 5
          interval: 2
          retry: 3
        httpProbe/inputs:
          url: "http://web-service.production.svc.cluster.local/healthz"
          insecureSkipVerify: false
          method:
            get:
              criteria: "=="
              responseCode: "200"
---
# ServiceAccount for Chaos
apiVersion: v1
kind: ServiceAccount
metadata:
  name: litmus-admin
  namespace: production
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: litmus-admin
  namespace: production
rules:
- apiGroups: [""]
  resources: ["pods", "events", "services"]
  verbs: ["create", "delete", "get", "list", "patch", "update", "watch"]
- apiGroups: ["apps"]
  resources: ["deployments", "replicasets", "statefulsets"]
  verbs: ["list", "get", "patch", "update"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: litmus-admin
  namespace: production
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: litmus-admin
subjects:
- kind: ServiceAccount
  name: litmus-admin
  namespace: production
```

```bash
# Experimentのインストール
kubectl apply -f https://hub.litmuschaos.io/api/chaos/master?file=charts/generic/pod-delete/experiment.yaml -n production

# ChaosEngineの実行
kubectl apply -f pod-delete-chaosengine.yaml

# 実験状態の確認
kubectl get chaosengine -n production
# NAME                  AGE
# web-app-pod-delete    30s

kubectl describe chaosengine web-app-pod-delete -n production

# ChaosResult確認
kubectl get chaosresult -n production
# NAME                             AGE
# web-app-pod-delete-pod-delete    1m

kubectl describe chaosresult web-app-pod-delete-pod-delete -n production
# Status:
#   Experiment Status:
#     Phase:  Completed
#     Verdict: Pass
#     Probe Success Percentage: 100

# ログ確認
kubectl logs -n production -l name=pod-delete -f
```

### 3.2 ネットワーク遅延注入

```yaml
# network-latency-chaosengine.yaml
apiVersion: litmuschaos.io/v1alpha1
kind: ChaosEngine
metadata:
  name: web-app-network-latency
  namespace: production
spec:
  appinfo:
    appns: production
    applabel: "app=web"
    appkind: deployment
  
  chaosServiceAccount: litmus-admin
  
  experiments:
  - name: pod-network-latency
    spec:
      components:
        env:
        # ネットワーク遅延時間
        - name: NETWORK_LATENCY
          value: "2000"  # 2000ms (2秒)
        
        # Jitter（遅延のゆらぎ）
        - name: JITTER
          value: "500"  # 500ms
        
        # 対象インターフェース
        - name: NETWORK_INTERFACE
          value: "eth0"
        
        # カオス継続時間
        - name: TOTAL_CHAOS_DURATION
          value: "120"  # 120秒
        
        # 対象Pod割合
        - name: PODS_AFFECTED_PERC
          value: "30"
        
        # 対象先フィルタ（オプション）
        - name: DESTINATION_IPS
          value: "10.100.0.0/16"  # ClusterIPレンジ
        
        - name: DESTINATION_HOSTS
          value: ""  # 全ホスト
      
      probe:
      - name: "api-latency-check"
        type: "cmdProbe"
        mode: "Edge"
        runProperties:
          probeTimeout: 10
          interval: 5
          retry: 3
        cmdProbe/inputs:
          command: "curl -w '%{time_total}' -o /dev/null -s http://web-service/api"
          comparator:
            type: "float"
            criteria: "<"
            value: "3.0"  # 3秒以内
```

```bash
# Experimentのインストール
kubectl apply -f https://hub.litmuschaos.io/api/chaos/master?file=charts/generic/pod-network-latency/experiment.yaml -n production

# 実行
kubectl apply -f network-latency-chaosengine.yaml

# レイテンシ確認（別ターミナルで）
while true; do
  curl -w "\nTime: %{time_total}s\n" -o /dev/null -s http://web-service.production.svc.cluster.local/api
  sleep 2
done

# 出力例（カオス注入前）:
# Time: 0.050s
# 出力例（カオス注入中）:
# Time: 2.450s ← 遅延発生
```

### 3.3 ネットワークパケットロス

```yaml
# network-loss-chaosengine.yaml
apiVersion: litmuschaos.io/v1alpha1
kind: ChaosEngine
metadata:
  name: web-app-network-loss
  namespace: production
spec:
  appinfo:
    appns: production
    applabel: "app=web"
    appkind: deployment
  
  chaosServiceAccount: litmus-admin
  
  experiments:
  - name: pod-network-loss
    spec:
      components:
        env:
        # パケットロス率
        - name: NETWORK_PACKET_LOSS_PERCENTAGE
          value: "50"  # 50%のパケットをドロップ
        
        - name: TOTAL_CHAOS_DURATION
          value: "90"
        
        - name: NETWORK_INTERFACE
          value: "eth0"
        
        - name: PODS_AFFECTED_PERC
          value: "25"
      
      probe:
      - name: "service-availability"
        type: "httpProbe"
        mode: "Continuous"
        runProperties:
          probeTimeout: 10
          interval: 3
          retry: 5  # リトライ増やす
        httpProbe/inputs:
          url: "http://web-service.production.svc.cluster.local"
          method:
            get:
              criteria: "=="
              responseCode: "200"
```

### 3.4 CPU負荷注入（CPU Hog）

```yaml
# cpu-hog-chaosengine.yaml
apiVersion: litmuschaos.io/v1alpha1
kind: ChaosEngine
metadata:
  name: web-app-cpu-hog
  namespace: production
spec:
  appinfo:
    appns: production
    applabel: "app=web"
    appkind: deployment
  
  chaosServiceAccount: litmus-admin
  
  experiments:
  - name: pod-cpu-hog
    spec:
      components:
        env:
        # CPU負荷時間
        - name: TOTAL_CHAOS_DURATION
          value: "120"
        
        # CPUコア数
        - name: CPU_CORES
          value: "2"  # 2コア分の負荷
        
        # CPU使用率（パーセント）
        - name: CPU_LOAD
          value: "100"  # 100%
        
        - name: PODS_AFFECTED_PERC
          value: "50"
        
        # 負荷タイプ（md5sum計算でCPU消費）
        - name: CHAOS_INJECT_COMMAND
          value: "md5sum /dev/zero"
        
        - name: CHAOS_KILL_COMMAND
          value: "kill $(pgrep md5sum)"
      
      probe:
      - name: "cpu-usage-check"
        type: "promProbe"
        mode: "Edge"
        runProperties:
          probeTimeout: 5
          interval: 2
          retry: 3
        promProbe/inputs:
          endpoint: "http://prometheus.monitoring.svc.cluster.local:9090"
          query: "avg(rate(container_cpu_usage_seconds_total{pod=~'web-.*'}[1m]))"
          comparator:
            criteria: "<"
            value: "0.9"  # 90%以下
```

### 3.5 メモリ負荷注入（Memory Hog）

```yaml
# memory-hog-chaosengine.yaml
apiVersion: litmuschaos.io/v1alpha1
kind: ChaosEngine
metadata:
  name: web-app-memory-hog
  namespace: production
spec:
  appinfo:
    appns: production
    applabel: "app=web"
    appkind: deployment
  
  chaosServiceAccount: litmus-admin
  
  experiments:
  - name: pod-memory-hog
    spec:
      components:
        env:
        # メモリ消費量
        - name: MEMORY_CONSUMPTION
          value: "500"  # 500MB
        
        - name: TOTAL_CHAOS_DURATION
          value: "120"
        
        - name: PODS_AFFECTED_PERC
          value: "30"
        
        # メモリ消費方法
        - name: CHAOS_INJECT_COMMAND
          value: "dd if=/dev/zero of=/dev/null bs=500M count=1 iflag=fullblock"
      
      probe:
      - name: "oom-check"
        type: "k8sProbe"
        mode: "Continuous"
        runProperties:
          probeTimeout: 5
          interval: 3
          retry: 3
        k8sProbe/inputs:
          group: ""
          version: "v1"
          resource: "pods"
          namespace: "production"
          fieldSelector: "status.phase=Running"
          labelSelector: "app=web"
          operation: "present"
```

## 4. 高度なChaos Workflow

### 4.1 連続的なカオス実験

```yaml
# chaos-workflow.yaml
apiVersion: argoproj.io/v1alpha1
kind: Workflow
metadata:
  name: multi-chaos-workflow
  namespace: litmus
spec:
  entrypoint: chaos-pipeline
  serviceAccountName: argo-chaos
  
  templates:
  # メインパイプライン
  - name: chaos-pipeline
    steps:
    # ステップ1: Pod削除
    - - name: pod-delete-chaos
        template: pod-delete-experiment
    
    # ステップ2: ネットワーク遅延
    - - name: network-latency-chaos
        template: network-latency-experiment
    
    # ステップ3: CPU負荷
    - - name: cpu-hog-chaos
        template: cpu-hog-experiment
    
    # ステップ4: 結果検証
    - - name: validate-slo
        template: slo-validation
  
  # Pod削除実験
  - name: pod-delete-experiment
    resource:
      action: create
      manifest: |
        apiVersion: litmuschaos.io/v1alpha1
        kind: ChaosEngine
        metadata:
          name: workflow-pod-delete
          namespace: production
        spec:
          appinfo:
            appns: production
            applabel: "app=web"
            appkind: deployment
          chaosServiceAccount: litmus-admin
          experiments:
          - name: pod-delete
            spec:
              components:
                env:
                - name: TOTAL_CHAOS_DURATION
                  value: "60"
                - name: PODS_AFFECTED_PERC
                  value: "30"
  
  # ネットワーク遅延実験
  - name: network-latency-experiment
    resource:
      action: create
      manifest: |
        apiVersion: litmuschaos.io/v1alpha1
        kind: ChaosEngine
        metadata:
          name: workflow-network-latency
          namespace: production
        spec:
          appinfo:
            appns: production
            applabel: "app=web"
            appkind: deployment
          chaosServiceAccount: litmus-admin
          experiments:
          - name: pod-network-latency
            spec:
              components:
                env:
                - name: NETWORK_LATENCY
                  value: "1000"
                - name: TOTAL_CHAOS_DURATION
                  value: "90"
  
  # CPU負荷実験
  - name: cpu-hog-experiment
    resource:
      action: create
      manifest: |
        apiVersion: litmuschaos.io/v1alpha1
        kind: ChaosEngine
        metadata:
          name: workflow-cpu-hog
          namespace: production
        spec:
          appinfo:
            appns: production
            applabel: "app=web"
            appkind: deployment
          chaosServiceAccount: litmus-admin
          experiments:
          - name: pod-cpu-hog
            spec:
              components:
                env:
                - name: CPU_CORES
                  value: "1"
                - name: TOTAL_CHAOS_DURATION
                  value: "60"
  
  # SLO検証
  - name: slo-validation
    script:
      image: curlimages/curl
      command: [sh]
      source: |
        # Prometheusからメトリクス取得
        AVAILABILITY=$(curl -s "http://prometheus.monitoring.svc.cluster.local:9090/api/v1/query?query=avg_over_time(up{job='web-app'}[5m])")
        echo "Availability: $AVAILABILITY"
        
        # 99.9%以上であればPass
        if [ "$AVAILABILITY" -ge "0.999" ]; then
          echo "SLO Met: Availability >= 99.9%"
          exit 0
        else
          echo "SLO Failed: Availability < 99.9%"
          exit 1
        fi
```

```bash
# Argo Workflowsのインストール
kubectl create namespace argo
kubectl apply -n argo -f https://github.com/argoproj/argo-workflows/releases/download/v3.5.0/install.yaml

# Workflowの実行
kubectl apply -f chaos-workflow.yaml

# Workflow確認
kubectl get workflow -n litmus
# NAME                    STATUS    AGE
# multi-chaos-workflow    Running   2m

# Argo UI でビジュアル確認
kubectl -n argo port-forward deployment/argo-server 2746:2746
# https://localhost:2746
```

### 4.2 定期的なカオス実験（ChaosSchedule）

```yaml
# chaos-schedule.yaml
apiVersion: litmuschaos.io/v1alpha1
kind: ChaosSchedule
metadata:
  name: daily-pod-delete
  namespace: production
spec:
  # Cron形式のスケジュール
  schedule:
    repeat:
      timeRange:
        startTime: "2024-01-01T00:00:00Z"
        endTime: "2024-12-31T23:59:59Z"
      properties:
        minChaosInterval: "24h"  # 最小24時間間隔
      workDays:
        includedDays: "Mon,Tue,Wed,Thu,Fri"  # 平日のみ
      workHours:
        includedHours: "10:00-18:00"  # 10時〜18時（業務時間）
  
  # 実験設定
  engineTemplateSpec:
    appinfo:
      appns: production
      applabel: "app=web"
      appkind: deployment
    
    chaosServiceAccount: litmus-admin
    
    experiments:
    - name: pod-delete
      spec:
        components:
          env:
          - name: TOTAL_CHAOS_DURATION
            value: "30"
          - name: PODS_AFFECTED_PERC
            value: "20"
        
        probe:
        - name: "availability-check"
          type: "promProbe"
          mode: "EOT"  # End of Test
          runProperties:
            probeTimeout: 5
            retry: 3
          promProbe/inputs:
            endpoint: "http://prometheus.monitoring.svc.cluster.local:9090"
            query: "avg_over_time(up{job='web-app'}[5m])"
            comparator:
              criteria: ">="
              value: "0.999"  # 99.9%
  
  # 並列実行制御
  concurrencyPolicy: Forbid  # 前回が完了するまで次を実行しない
  
  # 実験履歴保持
  historyLimit: 10
```

```bash
# ChaosScheduleの適用
kubectl apply -f chaos-schedule.yaml

# スケジュール確認
kubectl get chaosschedule -n production
# NAME                AGE
# daily-pod-delete    1m

kubectl describe chaosschedule daily-pod-delete -n production
# Schedule:
#   Repeat:
#     Time Range:
#       Start Time: 2024-01-01T00:00:00Z
#       End Time:   2024-12-31T23:59:59Z
#     Properties:
#       Min Chaos Interval: 24h
#     Work Days:
#       Included Days: Mon,Tue,Wed,Thu,Fri
#     Work Hours:
#       Included Hours: 10:00-18:00

# 実行履歴確認
kubectl get chaosengine -n production --sort-by=.metadata.creationTimestamp
```

## 5. SLO/SLIベースの評価

### 5.1 SLI（Service Level Indicator）の定義

```yaml
# sli-prometheus-rules.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: sli-rules
  namespace: monitoring
data:
  sli-rules.yml: |
    groups:
    - name: sli
      interval: 30s
      rules:
      # 可用性 SLI
      - record: sli:availability:ratio
        expr: |
          sum(up{job="web-app"}) /
          count(up{job="web-app"})
      
      # レイテンシ SLI (95パーセンタイル < 200ms)
      - record: sli:latency:p95
        expr: |
          histogram_quantile(0.95,
            rate(http_request_duration_seconds_bucket{job="web-app"}[5m])
          )
      
      # エラー率 SLI (< 1%)
      - record: sli:error_rate:ratio
        expr: |
          sum(rate(http_requests_total{job="web-app",status=~"5.."}[5m])) /
          sum(rate(http_requests_total{job="web-app"}[5m]))
      
      # スループット SLI
      - record: sli:throughput:rate
        expr: |
          sum(rate(http_requests_total{job="web-app"}[5m]))
```

### 5.2 SLO（Service Level Objective）の定義

```yaml
# slo-definition.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: slo-definitions
  namespace: monitoring
data:
  slo.json: |
    {
      "slos": [
        {
          "name": "availability",
          "description": "99.9% of requests succeed",
          "target": 0.999,
          "sli": "sli:availability:ratio",
          "window": "30d"
        },
        {
          "name": "latency",
          "description": "95% of requests complete within 200ms",
          "target": 0.200,
          "sli": "sli:latency:p95",
          "window": "30d"
        },
        {
          "name": "error_rate",
          "description": "Less than 1% error rate",
          "target": 0.01,
          "sli": "sli:error_rate:ratio",
          "window": "30d"
        }
      ]
    }
```

### 5.3 SLOベースのカオス実験評価

```yaml
# chaos-with-slo-validation.yaml
apiVersion: litmuschaos.io/v1alpha1
kind: ChaosEngine
metadata:
  name: slo-aware-chaos
  namespace: production
spec:
  appinfo:
    appns: production
    applabel: "app=web"
    appkind: deployment
  
  chaosServiceAccount: litmus-admin
  
  # アノテーションでSLO閾値を定義
  annotationCheck: "true"
  annotations:
    slo.availability.target: "0.999"
    slo.latency.p95.target: "0.200"
    slo.error_rate.target: "0.01"
  
  experiments:
  - name: pod-delete
    spec:
      components:
        env:
        - name: TOTAL_CHAOS_DURATION
          value: "120"
        - name: PODS_AFFECTED_PERC
          value: "40"
      
      probe:
      # Probe 1: 可用性チェック
      - name: "availability-slo"
        type: "promProbe"
        mode: "Continuous"
        runProperties:
          probeTimeout: 5
          interval: 10
          retry: 3
        promProbe/inputs:
          endpoint: "http://prometheus.monitoring.svc.cluster.local:9090"
          query: "sli:availability:ratio"
          comparator:
            type: "float"
            criteria: ">="
            value: "0.999"  # 99.9% SLO
      
      # Probe 2: レイテンシチェック
      - name: "latency-slo"
        type: "promProbe"
        mode: "Continuous"
        runProperties:
          probeTimeout: 5
          interval: 10
          retry: 3
        promProbe/inputs:
          endpoint: "http://prometheus.monitoring.svc.cluster.local:9090"
          query: "sli:latency:p95"
          comparator:
            type: "float"
            criteria: "<="
            value: "0.200"  # 200ms SLO
      
      # Probe 3: エラー率チェック
      - name: "error-rate-slo"
        type: "promProbe"
        mode: "Continuous"
        runProperties:
          probeTimeout: 5
          interval: 10
          retry: 3
        promProbe/inputs:
          endpoint: "http://prometheus.monitoring.svc.cluster.local:9090"
          query: "sli:error_rate:ratio"
          comparator:
            type: "float"
            criteria: "<="
            value: "0.01"  # 1% SLO
```

```bash
# SLO対応カオス実験の実行
kubectl apply -f chaos-with-slo-validation.yaml

# 結果確認
kubectl describe chaosresult slo-aware-chaos-pod-delete -n production

# Probe結果（全てPassならSLO達成）
# Probe Status:
#   - Name: availability-slo
#     Status: Passed
#   - Name: latency-slo
#     Status: Passed
#   - Name: error-rate-slo
#     Status: Passed
# 
# Experiment Status:
#   Verdict: Pass (All SLOs met during chaos)
```

### 5.4 Error Budgetの計算

```yaml
# error-budget-calculation.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: error-budget-calculator
  namespace: monitoring
data:
  calculate.sh: |
    #!/bin/bash
    # Error Budget計算スクリプト
    
    # SLO設定
    SLO_TARGET=0.999  # 99.9%
    WINDOW_DAYS=30
    
    # Prometheusから実際のSLI取得
    ACTUAL_SLI=$(curl -s "http://prometheus.monitoring.svc.cluster.local:9090/api/v1/query?query=avg_over_time(sli:availability:ratio[${WINDOW_DAYS}d])" | jq -r '.data.result[0].value[1]')
    
    # Error Budget計算
    # Error Budget = 1 - SLO
    # Remaining Budget = (Actual SLI - SLO) / (1 - SLO)
    
    ERROR_BUDGET=$(echo "1 - $SLO_TARGET" | bc -l)
    # 0.001 (0.1%)
    
    CONSUMED=$(echo "$SLO_TARGET - $ACTUAL_SLI" | bc -l)
    REMAINING=$(echo "($ERROR_BUDGET - $CONSUMED) / $ERROR_BUDGET * 100" | bc -l)
    
    echo "SLO Target: $SLO_TARGET (99.9%)"
    echo "Actual SLI: $ACTUAL_SLI"
    echo "Error Budget: $ERROR_BUDGET (0.1%)"
    echo "Consumed: $CONSUMED"
    echo "Remaining: ${REMAINING}%"
    
    # 例:
    # SLO Target: 0.999
    # Actual SLI: 0.9995
    # Error Budget: 0.001
    # Consumed: -0.0005 (余裕あり)
    # Remaining: 150% (50%余剰)
```

## 6. ベストプラクティス

### 6.1 カオス実験の段階的導入

```
カオス実験の導入ステップ:

フェーズ1: テスト環境
  ├─ 基本的な実験（Pod削除）
  ├─ SLI/SLO定義
  └─ 監視体制構築

フェーズ2: ステージング環境
  ├─ より高度な実験（ネットワーク、リソース）
  ├─ 自動化（Workflow）
  └─ SLO検証

フェーズ3: 本番環境（制限付き）
  ├─ Blast Radius最小化（影響範囲を限定）
  ├─ 業務時間外に実施
  └─ 手動承認プロセス

フェーズ4: 本番環境（完全自動化）
  ├─ 定期的な自動実行
  ├─ 業務時間中も実施
  └─ SLOベースの自動判定
```

### 6.2 チェックリスト

- ✅ SLI/SLOを明確に定義
- ✅ テスト環境から段階的に導入
- ✅ Blast Radiusを最小限に（PODS_AFFECTED_PERC < 50%）
- ✅ Probeで継続的にヘルスチェック
- ✅ 監視・アラート体制を整備
- ✅ ロールバック手順の準備
- ✅ 定期的なカオス実験の自動化
- ✅ 実験結果の記録・分析
- ✅ チーム全体での知見共有
- ❌ 本番環境でいきなり大規模実験しない

## まとめ

### 学んだこと

1. **カオスエンジニアリングの原則**
   - 定常状態の定義とSLO
   - 現実世界の障害モデル化
   - 本番環境での継続的実験

2. **LitmusChaos実践**
   - Pod削除、ネットワーク障害、リソースストレス
   - ChaosEngine/ChaosExperimentの設定
   - Probeによるヘルスチェック

3. **高度なWorkflow**
   - 連続的なカオス実験
   - ChaosScheduleによる定期実行
   - Argo Workflowsとの統合

4. **SLO/SLIベースの評価**
   - SLI定義（可用性、レイテンシ、エラー率）
   - SLO閾値での実験評価
   - Error Budget計算

5. **ベストプラクティス**
   - 段階的導入
   - Blast Radius最小化
   - 継続的な改善サイクル

### 次回予告

次回は「GitOpsで実現する宣言的運用」として、ArgoCD/Fluxの実装、マルチクラスタ管理、CI/CDパイプライン統合を解説します。

## 参考リンク

- {{< linkcard "https://litmuschaos.io/" >}}
- {{< linkcard "https://principlesofchaos.org/" >}}
- {{< linkcard "https://sre.google/sre-book/embracing-risk/" >}}
- {{< linkcard "https://github.com/litmuschaos/litmus" >}}
