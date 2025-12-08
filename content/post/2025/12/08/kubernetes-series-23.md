---
title: "Kubernetesを完全に理解した(第23回) - カオスエンジニアリング"
draft: true
tags:
- kubernetes
- chaos-engineering
- reliability
- testing
- litmus
description: 意図的に障害を起こしてシステムの弾力性を検証する革新的な手法。本番環境で起きる前に弱点を発見し、真に堅牢なシステムを構築します。
---

## 前回の振り返り

第22回では、マルチリージョン構成を実装し、地理的に離れた複数のリージョンでKubernetesクラスタを運用する方法を学びました。Kubernetes Federationでクラスタを統合管理し、グローバルロードバランシングで最適なルーティングを実現し、リージョン全体の障害にも耐える究極の高可用性システムを構築しました。

しかし、どんなに綿密に設計しても、実際に障害が発生するまでシステムの真の堅牢性は分かりません。「本番環境で初めて障害に遭遇する」という状況は避けたいものです。

今回は、**カオスエンジニアリング**を実践します。意図的にシステムに障害を注入し、その挙動を観察することで、本番環境で起きる前に弱点を発見し、真に信頼性の高いシステムを構築します。

## カオスエンジニアリングとは

### Netflixから生まれた革新的手法

カオスエンジニアリングは、2011年にNetflixが開始したChaos Monkeyプロジェクトから始まりました。本番環境でランダムにサーバーを停止させることで、システムが単一障害点に依存していないか検証したのです。

### カオスエンジニアリングの原則

1. **定常状態の仮説を立てる**: システムが正常に動作している状態を定義
2. **現実世界の事象を変数化する**: Pod削除、ネットワーク遅延、リソース枯渇など
3. **本番環境で実験する**: 実際の環境でないと見つからない問題がある
4. **自動化して継続的に実行**: 定期的に実行してリグレッションを防ぐ
5. **影響範囲を最小化する**: 小さく始めて段階的に拡大

### なぜ重要なのか

- **未知の障害モードの発見**: 設計段階では想定できなかった障害パターンを発見
- **チームの対応力向上**: 障害対応の経験を安全に積める
- **システムの信頼性向上**: 弱点を事前に発見して修正
- **SLO達成の確度向上**: 実験データに基づいた信頼性評価

## Litmus Chaosの導入

### インストール

Litmus Chaosは、Kubernetes向けのカオスエンジニアリングフレームワークです。豊富な実験テンプレートと直感的なUIを提供します。

```bash
# Litmus operatorのインストール
kubectl apply -f https://litmuschaos.github.io/litmus/3.0.0/litmus-3.0.0.yaml

# インストール確認
kubectl get pods -n litmus

# ChaosCenter UIアクセス
kubectl port-forward -n litmus svc/litmusportal-frontend-service 9091:9091
```

ブラウザで`http://localhost:9091`にアクセスすると、直感的なダッシュボードが表示されます。

### 実験のセットアップ

まず、カオス実験を実行する権限を持つServiceAccountを作成します。

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: pod-delete-sa
  namespace: production
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: pod-delete-role
  namespace: production
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "list", "delete"]
- apiGroups: ["apps"]
  resources: ["deployments"]
  verbs: ["get", "list"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: pod-delete-rb
  namespace: production
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: pod-delete-role
subjects:
- kind: ServiceAccount
  name: pod-delete-sa
```

## Pod障害のシミュレーション

### Pod削除実験

最も基本的な実験は、ランダムにPodを削除してシステムの自動復旧能力を検証することです。

```yaml
apiVersion: litmuschaos.io/v1alpha1
kind: ChaosEngine
metadata:
  name: web-chaos-pod-delete
  namespace: production
spec:
  appinfo:
    appns: production
    applabel: "app=web"
    appkind: deployment
  engineState: active
  chaosServiceAccount: pod-delete-sa
  experiments:
  - name: pod-delete
    spec:
      components:
        env:
        - name: TOTAL_CHAOS_DURATION
          value: "60"
        - name: CHAOS_INTERVAL
          value: "10"
        - name: PODS_AFFECTED_PERC
          value: "50"
      probe:
      - name: check-web-availability
        type: httpProbe
        httpProbe/inputs:
          url: http://web-service.production.svc.cluster.local
          method:
            get:
              criteria: ==
              responseCode: "200"
        mode: Continuous
        runProperties:
          probeTimeout: 5
          interval: 2
```

この実験では、60秒間にわたって10秒ごとに50%のPodを削除します。同時に、HTTPプローブでサービスの可用性を継続的に監視します。

### 実験結果の確認

```bash
# ChaosEngineの状態確認
kubectl get chaosengine -n production

# 実験ログの確認
kubectl logs -n production -l name=pod-delete

# Probeの結果確認
kubectl describe chaosengine web-chaos-pod-delete -n production
```

プローブが成功し続けていれば、Podが削除されてもサービスは継続できたことになります。失敗していれば、レプリカ数やPodDisruptionBudgetの見直しが必要です。

## リソース負荷の実験

### CPU負荷テスト

本番環境で突然CPU使用率が急上昇した場合、システムはどう振る舞うでしょうか？

```yaml
apiVersion: litmuschaos.io/v1alpha1
kind: ChaosEngine
metadata:
  name: cpu-stress-test
  namespace: production
spec:
  appinfo:
    appns: production
    applabel: "app=api"
    appkind: deployment
  engineState: active
  chaosServiceAccount: pod-delete-sa
  experiments:
  - name: pod-cpu-hog
    spec:
      components:
        env:
        - name: TOTAL_CHAOS_DURATION
          value: "120"
        - name: CPU_CORES
          value: "2"
        - name: PODS_AFFECTED_PERC
          value: "30"
      probe:
      - name: check-api-latency
        type: promProbe
        promProbe/inputs:
          endpoint: http://prometheus.monitoring:9090
          query: "histogram_quantile(0.95, rate(http_request_duration_seconds_bucket{job='api'}[5m]))"
          comparator:
            criteria: <=
            value: "0.5"
        mode: Continuous
```

CPU負荷をかけながら、Prometheusメトリクスで95パーセンタイルのレイテンシを監視します。HPAが正しく動作して自動スケールするか、リソースリミットが適切か検証できます。

### メモリ負荷テスト

メモリリークやOOMKillの挙動も検証できます。

```yaml
apiVersion: litmuschaos.io/v1alpha1
kind: ChaosEngine
metadata:
  name: memory-stress-test
  namespace: production
spec:
  appinfo:
    appns: production
    applabel: "app=cache"
    appkind: deployment
  engineState: active
  chaosServiceAccount: pod-delete-sa
  experiments:
  - name: pod-memory-hog
    spec:
      components:
        env:
        - name: TOTAL_CHAOS_DURATION
          value: "120"
        - name: MEMORY_CONSUMPTION
          value: "500"
        - name: PODS_AFFECTED_PERC
          value: "25"
```

## ネットワーク障害のシミュレーション

### ネットワーク遅延

データベースへの接続に突然200msの遅延が発生したら？

```yaml
apiVersion: litmuschaos.io/v1alpha1
kind: ChaosEngine
metadata:
  name: network-latency-test
  namespace: production
spec:
  appinfo:
    appns: production
    applabel: "app=api"
    appkind: deployment
  engineState: active
  chaosServiceAccount: pod-delete-sa
  experiments:
  - name: pod-network-latency
    spec:
      components:
        env:
        - name: TOTAL_CHAOS_DURATION
          value: "120"
        - name: NETWORK_LATENCY
          value: "2000"
        - name: JITTER
          value: "200"
        - name: DESTINATION_IPS
          value: "postgres-service.production.svc.cluster.local"
```

タイムアウト設定、リトライロジック、サーキットブレーカーが正しく動作するか検証できます。

### パケットロス

ネットワークの品質が低下してパケットロスが発生する状況をシミュレートします。

```yaml
apiVersion: litmuschaos.io/v1alpha1
kind: ChaosEngine
metadata:
  name: network-loss-test
  namespace: production
spec:
  appinfo:
    appns: production
    applabel: "app=web"
    appkind: deployment
  engineState: active
  chaosServiceAccount: pod-delete-sa
  experiments:
  - name: pod-network-loss
    spec:
      components:
        env:
        - name: TOTAL_CHAOS_DURATION
          value: "60"
        - name: NETWORK_PACKET_LOSS_PERCENTAGE
          value: "10"
```

### 完全なネットワーク分断

外部APIとの通信が完全に遮断された場合の挙動を確認します。

```yaml
apiVersion: litmuschaos.io/v1alpha1
kind: ChaosEngine
metadata:
  name: network-partition-test
  namespace: production
spec:
  appinfo:
    appns: production
    applabel: "app=payment"
    appkind: deployment
  engineState: active
  chaosServiceAccount: pod-delete-sa
  experiments:
  - name: pod-network-partition
    spec:
      components:
        env:
        - name: TOTAL_CHAOS_DURATION
          value: "90"
        - name: DESTINATION_HOSTS
          value: "external-payment-api.example.com"
      probe:
      - name: check-circuit-breaker
        type: promProbe
        promProbe/inputs:
          query: "rate(payment_circuit_breaker_open_total[1m])"
          comparator:
            criteria: ">"
            value: "0"
        mode: Edge
```

サーキットブレーカーが正しく開いて、フォールバック処理が動作するか検証します。

## ノードレベルの障害

### Node CPU負荷

ノード全体のCPUが高負荷になった場合の影響を調べます。

```yaml
apiVersion: litmuschaos.io/v1alpha1
kind: ChaosEngine
metadata:
  name: node-cpu-stress
  namespace: production
spec:
  engineState: active
  chaosServiceAccount: node-chaos-sa
  experiments:
  - name: node-cpu-hog
    spec:
      components:
        env:
        - name: TOTAL_CHAOS_DURATION
          value: "120"
        - name: NODE_CPU_CORE
          value: "2"
        nodeSelector:
          node-role: worker
```

### Node Drain

計画的なノードメンテナンスをシミュレートします。

```yaml
apiVersion: litmuschaos.io/v1alpha1
kind: ChaosEngine
metadata:
  name: node-drain-test
  namespace: production
spec:
  engineState: active
  chaosServiceAccount: node-chaos-sa
  experiments:
  - name: node-drain
    spec:
      components:
        env:
        - name: TOTAL_CHAOS_DURATION
          value: "180"
        - name: TARGET_NODE
          value: "worker-node-3"
      probe:
      - name: check-pod-redistribution
        type: k8sProbe
        k8sProbe/inputs:
          resource: pods
          namespace: production
          fieldSelector: status.phase=Running
          labelSelector: app=web
          operation: present
        mode: Continuous
```

PodDisruptionBudgetが機能して最小レプリカ数が維持されるか、Podが正しく他のノードに退避されるか検証します。

## カオススケジューリング

### 定期的なカオス実験

毎週決まった時間に自動的にカオス実験を実行します。

```yaml
apiVersion: litmuschaos.io/v1alpha1
kind: ChaosSchedule
metadata:
  name: weekly-resilience-test
  namespace: production
spec:
  schedule:
    repeat:
      timeRange:
        startTime: "2024-01-01T09:00:00Z"
        endTime: "2024-12-31T17:00:00Z"
      properties:
        minChaosInterval: "24h"
      workDays:
        includedDays: "Mon,Wed,Fri"
  engineTemplateSpec:
    appinfo:
      appns: production
      applabel: "tier=frontend"
      appkind: deployment
    engineState: active
    chaosServiceAccount: pod-delete-sa
    experiments:
    - name: pod-delete
      spec:
        components:
          env:
          - name: TOTAL_CHAOS_DURATION
            value: "60"
```

この設定で、月・水・金曜日の9:00-17:00の間、24時間ごとにPod削除実験が自動実行されます。

## GameDayの実施

### GameDayとは

GameDayは、チーム全体でカオス実験を実施するイベントです。事前に計画を立て、各メンバーの役割を決めて、実際に障害を起こしながら対応します。

### GameDay実施手順

1. **事前準備**
   - 実験範囲の定義
   - ステークホルダーへの通知
   - ロールバック手順の確認
   - モニタリングダッシュボードの準備

2. **実施フェーズ**
   - 定常状態メトリクスの記録
   - 小規模な実験から開始
   - 影響範囲を段階的に拡大
   - 継続的な観測と記録

3. **振り返り**
   - 結果のレビュー
   - 改善項目の特定
   - アクションアイテムの作成
   - レポート作成と共有

## 安全な実験のベストプラクティス

### 小さく始める

いきなり本番環境で大規模な実験をするのではなく、開発環境やステージング環境から始めます。

```bash
# 開発環境で実験
kubectl apply -f chaos-experiment.yaml --context dev-cluster

# 結果を確認してから本番へ
kubectl apply -f chaos-experiment.yaml --context prod-cluster
```

### ブラストラディウスの制限

影響範囲を限定するため、最初は少数のPodやノードから始めます。

```yaml
env:
- name: PODS_AFFECTED_PERC
  value: "10"  # 最初は10%から
```

### 自動ロールバック

実験が予期しない結果をもたらした場合、自動的に停止する仕組みを用意します。

```yaml
probe:
- name: abort-on-high-error-rate
  type: promProbe
  promProbe/inputs:
    query: "rate(http_requests_total{status=~'5..'}[1m]) / rate(http_requests_total[1m])"
    comparator:
      criteria: "<"
      value: "0.05"
  mode: Continuous
  runProperties:
    stopOnFailure: true
```

エラー率が5%を超えたら実験を自動停止します。

## 実験結果の活用

### 発見した問題の修正サイクル

1. カオス実験で弱点を発見
2. 根本原因を分析
3. 修正を実装
4. 再度カオス実験で検証
5. 継続的に監視

### メトリクスとして記録

```yaml
# カオス実験の成功率をPrometheusで記録
litmuschaos_experiment_verdict{verdict="Pass"} / litmuschaos_experiment_verdict
```

これをダッシュボードで可視化し、システムの信頼性向上を追跡します。

## まとめ

カオスエンジニアリングは、本番環境で障害が発生する前にシステムの弱点を発見する強力な手法です。Litmus Chaosを使用してPod削除、リソース負荷、ネットワーク障害などを意図的に起こし、システムの自動復旧能力を検証しました。

定期的にカオス実験を実施し、継続的にシステムの堅牢性を向上させることで、真に信頼性の高いシステムを構築できます。

次回は、**GitOpsによる宣言的運用**を学びます。すべての変更をGitで管理し、自動同期で運用する最先端の手法で、人的ミスを削減し、完全な監査証跡を持つ理想的なDevOps環境を実現します。

### 主要な学習ポイント

- カオスエンジニアリングの原則と重要性
- Litmus Chaosの導入と設定
- Pod障害、リソース負荷、ネットワーク障害のシミュレーション
- ノードレベルの障害実験
- ChaosScheduleによる定期的な自動実験
- GameDayの実施方法
- 安全な実験のベストプラクティス

障害を恐れず、むしろ積極的に起こして学ぶ。これこそが真に堅牢なシステムを構築する道です！
