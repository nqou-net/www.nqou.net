---
title: "Kubernetesを完全に理解した（第13回）- HPAで自動スケーリング"
draft: true
tags:
- kubernetes
- autoscaling
- hpa
- metrics
- scalability
description: "トラフィック変動に自動で追従するスケーラブルなシステムを構築。急激なアクセス増加にも耐えられる仕組みを実現します。"
---

## はじめに - 第12回の振り返りと第13回で学ぶこと

前回の第12回では、リソース管理について学びました。RequestsとLimitsの違い、QoSクラスの仕組み、OOMKillerとCPUスロットリングの動作を理解し、効率的なクラスタリソース配分の方法を習得できました。

今回の第13回では、**HPA（HorizontalPodAutoscaler）による自動スケーリング** について学びます。トラフィック変動に自動で追従し、負荷に応じてPod数を動的に調整する仕組みを実践します。

本記事で学ぶ内容：

- HPA（HorizontalPodAutoscaler）の基本概念
- Metrics Serverのセットアップ
- CPU使用率ベースの自動スケール
- メモリやカスタムメトリクスの活用
- スケーリング動作の制御とチューニング

## HPAとは

### 自動スケーリングの必要性

アプリケーションの負荷は時間帯やイベントによって変動します：

```
平日 8:00-9:00   : 高負荷（通勤時間）
平日 12:00-13:00 : 高負荷（昼休み）
平日 02:00-05:00 : 低負荷（深夜）
週末             : 中負荷
```

**手動スケーリングの課題：**

```bash
# 手動でPod数を調整
kubectl scale deployment myapp --replicas=10  # ピーク時
kubectl scale deployment myapp --replicas=3   # 通常時

# 課題:
# - 24時間監視が必要
# - 急激な負荷増加に対応できない
# - リソースの無駄（低負荷時も多くのPod）
```

**HPAによる自動スケーリング：**

```
負荷低 → Pod数減少 → コスト削減
負荷高 → Pod数増加 → パフォーマンス維持
```

### HPAの動作フロー

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

## Metrics Serverのセットアップ

HPAが動作するには、Metrics Serverが必要です。

### Metrics Serverのインストール

**minikubeの場合：**

```bash
# アドオンとして有効化
minikube addons enable metrics-server

# 確認
kubectl get deployment metrics-server -n kube-system
# NAME             READY   UP-TO-DATE   AVAILABLE   AGE
# metrics-server   1/1     1            1           30s
```

**通常のクラスタの場合：**

```bash
# 公式マニフェストをデプロイ
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

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

### トラブルシューティング

**問題: メトリクスが取得できない**

```bash
# エラー確認
kubectl logs -n kube-system deployment/metrics-server
# E1208 unable to fully collect metrics

# 解決策: TLS検証を無効化（開発環境のみ）
kubectl patch deployment metrics-server -n kube-system \
  --type='json' \
  -p='[
    {"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--kubelet-insecure-tls"}
  ]'
```

## CPU使用率ベースのHPA

### 基本的なHPA設定

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

**対象Deploymentの準備：**

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

**デプロイと確認：**

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
#   Resource cpu on pods (as a percentage of request): 15% (30m) / 70%
# Min replicas: 2
# Max replicas: 10
# Deployment pods: 2 current / 2 desired
```

### 負荷テストとスケール動作

```bash
# 負荷生成Pod
kubectl run -i --tty load-generator --rm --image=busybox --restart=Never -- /bin/sh

# Pod内で負荷をかける
while true; do wget -q -O- http://myapp-service; done

# 別のターミナルでHPA監視
kubectl get hpa myapp-hpa -w
# NAME        REFERENCE          TARGETS    MINPODS   MAXPODS   REPLICAS   AGE
# myapp-hpa   Deployment/myapp   15%/70%    2         10        2          1m
# myapp-hpa   Deployment/myapp   75%/70%    2         10        2          2m  ← 負荷上昇
# myapp-hpa   Deployment/myapp   75%/70%    2         10        4          2m  ← スケールアップ
# myapp-hpa   Deployment/myapp   45%/70%    2         10        4          3m  ← 安定

# Pod数の変化を確認
kubectl get pods -l app=myapp -w
# NAME                    READY   STATUS    RESTARTS   AGE
# myapp-7d8c9f5b6d-abc12  1/1     Running   0          2m
# myapp-7d8c9f5b6d-def34  1/1     Running   0          2m
# myapp-7d8c9f5b6d-ghi56  0/1     Pending   0          0s   ← 新しいPod
# myapp-7d8c9f5b6d-ghi56  1/1     Running   0          5s
# myapp-7d8c9f5b6d-jkl78  0/1     Pending   0          0s
# myapp-7d8c9f5b6d-jkl78  1/1     Running   0          5s
```

### Pod数の計算式

```
必要Pod数 = ceil(現在のPod数 × 現在の平均メトリクス / 目標メトリクス)

例1:
現在2 Pods, 平均CPU 75%, 目標50%
→ ceil(2 × 75 / 50) = ceil(3) = 3 Pods

例2:
現在3 Pods, 平均CPU 80%, 目標50%
→ ceil(3 × 80 / 50) = ceil(4.8) = 5 Pods
```

## スケーリング動作の制御

### スケールアップ・ダウンの速度制御

```yaml
# hpa-with-behavior.yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: controlled-hpa
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
        averageUtilization: 50
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

**動作の違い：**

```
デフォルト（behaviorなし）:
- スケールアップ: 急速
- スケールダウン: 急速
- 問題: フラッピング（頻繁な増減）

behavior設定あり:
- スケールアップ: 即座に対応（stabilizationWindow=0）
- スケールダウン: 慎重（5分間安定確認）
- メリット: 安定した運用
```

## メモリやカスタムメトリクスの活用

### メモリ使用率ベース

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

**注意点：**

```
メモリベースのHPAの課題:
- メモリは解放されにくい（Java、Goなど）
- スケールダウンが遅い
- CPU + メモリの組み合わせ推奨
```

### 複数メトリクスの組み合わせ

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
```

**計算ロジック：**

```
各メトリクスで必要Pod数を計算
→ 最大値を採用（最も厳しい条件）

例:
CPU: 3 Pods必要
Memory: 2 Pods必要
→ 3 Podsにスケール（より厳しい方）
```

## 実践的なHPA設計

### Webアプリケーション

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

### バッチ処理ワーカー

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
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
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

## トラブルシューティング

### よくある問題と解決策

**問題1: スケールしない**

```bash
# HPA状態確認
kubectl describe hpa myapp-hpa
# Conditions:
#   Type            Status  Reason                   Message
#   ----            ------  ------                   -------
#   AbleToScale     False   FailedGetResourceMetric  missing request for cpu

# 原因: Deploymentにresources.requestsがない
# 解決策: resources.requestsを設定
```

**問題2: 頻繁なスケールイン/アウト（フラッピング）**

```bash
# HPA履歴確認
kubectl get hpa myapp-hpa -w
# REPLICAS   AGE
# 3          1m
# 5          2m  ← 急増
# 3          3m  ← 急減
# 6          4m  ← また急増（フラッピング）

# 解決策: behaviorで安定化
```

```yaml
behavior:
  scaleDown:
    stabilizationWindowSeconds: 300  # 5分間安定を確認
  scaleUp:
    stabilizationWindowSeconds: 60   # 1分間安定を確認
```

**問題3: メトリクスが取得できない**

```bash
# Metrics Server確認
kubectl get pods -n kube-system -l k8s-app=metrics-server
# NAME                              READY   STATUS    RESTARTS   AGE
# metrics-server-5f9f776df5-abcde   0/1     Error     0          1m

# ログ確認
kubectl logs -n kube-system deployment/metrics-server

# 解決策: TLS設定の修正（前述）
```

## 実践シナリオ

### シナリオ: ECサイトのセール対応

**要件：**
```
通常時: 5 Pods
セール開始（10:00）: 急激にアクセス増加
想定ピーク: 50 Pods必要
```

**HPA設定：**

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: ec-site-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: ec-site
  minReplicas: 5
  maxReplicas: 100
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 60
  behavior:
    scaleUp:
      stabilizationWindowSeconds: 0
      policies:
      - type: Percent
        value: 200  # 急速に拡大（3倍）
        periodSeconds: 15
    scaleDown:
      stabilizationWindowSeconds: 900  # 15分間安定確認
      policies:
      - type: Pods
        value: 2
        periodSeconds: 180  # 3分ごとに2台ずつ削減
```

**動作の流れ：**

```
09:55 5 Pods（通常運用）
10:00 セール開始、アクセス急増
10:01 CPU使用率 85% → 15 Pods（3倍に拡大）
10:02 CPU使用率 80% → 30 Pods
10:03 CPU使用率 70% → 45 Pods
10:04 CPU使用率 60% → 50 Pods（安定）
...
12:00 セール終了、アクセス減少
12:15 CPU使用率 40%（15分間安定）→ 48 Pods（縮小開始）
12:18 CPU使用率 35% → 46 Pods
...
13:00 5 Pods（通常運用に戻る）
```

## まとめ

### 今回学んだこと

1. **HPAの基本**
   - メトリクスベースの自動スケール
   - minReplicas/maxReplicasで範囲指定

2. **Metrics Server**
   - HPAに必須
   - CPU/メモリメトリクス提供

3. **スケーリング戦略**
   - CPU/メモリベース
   - 複数メトリクス組み合わせ
   - behaviorで動作制御

4. **実践パターン**
   - Webアプリ: 早めに拡大、ゆっくり縮小
   - ワーカー: 急速拡大、慎重縮小
   - セール対応: 柔軟な設定

### ベストプラクティス

- resources.requestsを必ず設定
- behaviorで急激な変動を防ぐ
- 複数メトリクスの組み合わせ推奨
- スケールダウンは慎重に設定
- 定期的な負荷テストで検証

## 次回予告

次回の第14回では、**監視とログ基盤** について学びます。Prometheus/Grafanaによるメトリクス監視、Fluentd/Elasticsearchによるログ収集、そしてアラート設定について実践します。お楽しみに！
