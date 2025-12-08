---
title: "Kubernetesを完全に理解した(第21回) - マルチゾーンで可用性向上"
draft: true
tags:
- kubernetes
- high-availability
- multi-zone
- topology
- fault-tolerance
description: 単一データセンターの障害に耐えるマルチゾーン構成を実現。AZ障害時でもサービスを継続できる堅牢なアーキテクチャを構築します。
---

## 前回の振り返り

第20回では、Auto Scalingによる動的リソース管理を実現しました。HPA、VPA、Cluster Autoscalerを組み合わせることで、負荷に応じて自動的にスケールする柔軟なシステムを構築できました。

しかし、単一のデータセンター(アベイラビリティゾーン)で運用している場合、そのゾーンに障害が発生するとサービス全体が停止してしまいます。今回は、複数のゾーンにリソースを分散配置する**マルチゾーン構成**を実装し、ゾーン障害にも耐えられる高可用性システムを構築します。

## マルチゾーン構成の重要性

### ゾーン障害のリアル

クラウドプロバイダーのアベイラビリティゾーン(AZ)は、物理的に分離されたデータセンター群です。各ゾーンは独立した電源、ネットワーク、冷却システムを持ち、一つのゾーンで障害が発生しても他のゾーンには影響しません。

2023年のAWS US-East-1での大規模障害、2022年のGCP asia-northeast1での冷却システム障害など、ゾーンレベルの障害は決して珍しくありません。単一ゾーンで運用していると、これらの障害時にサービス全体が停止してしまいます。

### マルチゾーン構成のメリット

- **高可用性**: 1つのゾーンが停止しても残りのゾーンでサービス継続
- **災害耐性**: 物理的な災害(火災、洪水、停電など)に対する保護
- **メンテナンス時の無停止**: ゾーン単位でのローリングメンテナンスが可能
- **パフォーマンス**: ユーザーに近いゾーンからサービス提供

## Topology Spread Constraints

### 基本的なPod分散

Kubernetesには、Podを複数のゾーンやノードに均等に分散配置する強力な機能があります。`topologySpreadConstraints`を使用することで、障害時の影響を最小化できます。

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app
spec:
  replicas: 6
  template:
    spec:
      topologySpreadConstraints:
      - maxSkew: 1
        topologyKey: topology.kubernetes.io/zone
        whenUnsatisfiable: DoNotSchedule
        labelSelector:
          matchLabels:
            app: web
```

この設定により、6つのレプリカが3つのゾーンに2つずつ均等に配置されます。`maxSkew: 1`は、最も多いゾーンと最も少ないゾーンの差が1以下になるように制御します。

### 複数レベルの分散

ゾーンレベルだけでなく、ノードレベルでも分散させることで、さらに堅牢性が向上します。

```yaml
topologySpreadConstraints:
- maxSkew: 1
  topologyKey: topology.kubernetes.io/zone
  whenUnsatisfiable: DoNotSchedule
  labelSelector:
    matchLabels:
      app: web
- maxSkew: 2
  topologyKey: kubernetes.io/hostname
  whenUnsatisfiable: ScheduleAnyway
  labelSelector:
    matchLabels:
      app: web
```

この設定では、まずゾーン間で均等に分散し、その上で各ゾーン内のノード間でも可能な限り分散させます。

## StatefulSetのマルチゾーン配置

### データベースの高可用性配置

StatefulSetを使用するデータベースなどのステートフルアプリケーションでは、マルチゾーン配置が特に重要です。

```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: postgres
spec:
  serviceName: postgres
  replicas: 3
  template:
    spec:
      topologySpreadConstraints:
      - maxSkew: 1
        topologyKey: topology.kubernetes.io/zone
        whenUnsatisfiable: DoNotSchedule
        labelSelector:
          matchLabels:
            app: postgres
      affinity:
        podAntiAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
          - labelSelector:
              matchLabels:
                app: postgres
            topologyKey: kubernetes.io/hostname
```

この設定により、3つのPostgreSQLインスタンスが異なるゾーン、異なるノードに配置されます。1つのゾーンが停止しても、残り2つのインスタンスでデータベースサービスを継続できます。

### ボリュームの考慮事項

PersistentVolumeはゾーンに紐づくため、Podとボリュームが同じゾーンにある必要があります。`volumeBindingMode: WaitForFirstConsumer`を使用することで、Podがスケジュールされたゾーンでボリュームが作成されます。

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: zone-aware-ssd
provisioner: kubernetes.io/aws-ebs
parameters:
  type: gp3
  iops: "3000"
volumeBindingMode: WaitForFirstConsumer
allowedTopologies:
- matchLabelExpressions:
  - key: topology.kubernetes.io/zone
    values:
    - us-east-1a
    - us-east-1b
    - us-east-1c
```

## ロードバランサーの冗長化

### クロスゾーンロードバランシング

LoadBalancer Serviceを使用する場合、クロスゾーンロードバランシングを有効にすることで、すべてのゾーンのPodに均等にトラフィックを分散できます。

```yaml
apiVersion: v1
kind: Service
metadata:
  name: web-service
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-type: "nlb"
    service.beta.kubernetes.io/aws-load-balancer-cross-zone-load-balancing-enabled: "true"
spec:
  type: LoadBalancer
  selector:
    app: web
  ports:
  - protocol: TCP
    port: 80
    targetPort: 8080
```

### Topology Aware Routing

Kubernetes 1.27以降では、Topology Aware Routingを使用することで、可能な限り同じゾーン内のPodにトラフィックをルーティングし、クロスゾーン通信コストを削減できます。

```yaml
apiVersion: v1
kind: Service
metadata:
  name: internal-api
  annotations:
    service.kubernetes.io/topology-aware-hints: auto
spec:
  type: ClusterIP
  selector:
    app: api
  ports:
  - port: 8080
```

## コントロールプレーンの冗長化

### マルチマスター構成

本番環境では、APIサーバーやetcdなどのコントロールプレーンコンポーネントも複数のゾーンに配置すべきです。

```bash
# 1つ目のマスターノード(ゾーンA)を初期化
kubeadm init --control-plane-endpoint "k8s-api.example.com:6443" \
  --upload-certs \
  --pod-network-cidr=10.244.0.0/16

# 2つ目のマスターノード(ゾーンB)を追加
kubeadm join k8s-api.example.com:6443 \
  --token <token> \
  --discovery-token-ca-cert-hash sha256:<hash> \
  --control-plane \
  --certificate-key <key>

# 3つ目のマスターノード(ゾーンC)を追加
kubeadm join k8s-api.example.com:6443 \
  --token <token> \
  --discovery-token-ca-cert-hash sha256:<hash> \
  --control-plane \
  --certificate-key <key>
```

etcdは3台以上の奇数台で構成することで、1台が停止してもクォーラムを維持できます。

## モニタリングとアラート

### ゾーン別のメトリクス監視

Prometheusでゾーン別にメトリクスを収集し、ゾーン障害を迅速に検知します。

```yaml
groups:
- name: zone-alerts
  rules:
  - alert: ZoneDown
    expr: up{job="kubernetes-nodes"} == 0
    for: 5m
    labels:
      severity: critical
    annotations:
      summary: "Zone {{ $labels.zone }} appears to be down"
      
  - alert: UnbalancedZoneDistribution
    expr: |
      abs(
        count(kube_pod_info{namespace="production"}) by (node_zone) -
        avg(count(kube_pod_info{namespace="production"}) by (node_zone))
      ) > 2
    for: 10m
    labels:
      severity: warning
    annotations:
      summary: "Pod distribution across zones is unbalanced"
```

### PodDisruptionBudget

計画的なメンテナンス時でも最小限のPod数を維持するため、PodDisruptionBudgetを設定します。

```yaml
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: web-pdb
spec:
  minAvailable: 2
  selector:
    matchLabels:
      app: web
```

この設定により、ノードのドレインやアップグレード時でも常に最低2つのPodが稼働状態を保ちます。

## ゾーン障害のシミュレーション

### 障害訓練の実施

定期的にゾーン障害をシミュレートすることで、システムの堅牢性を検証できます。

```bash
# 特定ゾーンのノードをcordon(スケジューリング停止)
kubectl cordon -l topology.kubernetes.io/zone=us-east-1a

# 既存のPodを退避
kubectl drain -l topology.kubernetes.io/zone=us-east-1a \
  --ignore-daemonsets \
  --delete-emptydir-data

# サービスが継続していることを確認
curl http://web-service.example.com/health

# ノードを復旧
kubectl uncordon -l topology.kubernetes.io/zone=us-east-1a
```

### 配置の検証

Podが実際に複数のゾーンに分散されているか確認します。

```bash
# ゾーン別のPod分布を表示
kubectl get pods -o wide | \
  awk '{print $7}' | \
  sort | uniq -c

# 出力例:
# 2 us-east-1a
# 2 us-east-1b
# 2 us-east-1c
```

## 実践的な構成例

### 3ゾーン構成のWebアプリケーション

```yaml
# Deployment: 各ゾーンに2つずつ配置
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app
spec:
  replicas: 6
  template:
    spec:
      topologySpreadConstraints:
      - maxSkew: 1
        topologyKey: topology.kubernetes.io/zone
        whenUnsatisfiable: DoNotSchedule
        labelSelector:
          matchLabels:
            app: web
      containers:
      - name: web
        image: myapp:v1.0
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
---
# HPA: 負荷に応じて自動スケール
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: web-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: web-app
  minReplicas: 6
  maxReplicas: 18
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 50
  behavior:
    scaleUp:
      stabilizationWindowSeconds: 60
      policies:
      - type: Percent
        value: 100
        periodSeconds: 60
---
# PDB: 最低4つのPodを維持
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: web-pdb
spec:
  minAvailable: 4
  selector:
    matchLabels:
      app: web
```

## コストとパフォーマンスのバランス

### クロスゾーントラフィックのコスト

マルチゾーン構成では、ゾーン間のデータ転送に課金されることがあります。Topology Aware Routingを活用し、可能な限り同一ゾーン内で通信を完結させることでコストを削減できます。

### 最適なレプリカ数

最低でも各ゾーンに1つずつレプリカを配置し、合計で3つ以上のレプリカを維持することを推奨します。これにより、1つのゾーンが完全に停止しても、残りのゾーンで十分なキャパシティを確保できます。

## まとめ

マルチゾーン構成により、単一ゾーン障害に対する耐性が大幅に向上しました。Topology Spread Constraintsを使用してPodを均等に分散し、PodDisruptionBudgetで最小稼働数を保証することで、高い可用性を実現できます。

次回は、さらにスケールを大きくして**マルチリージョン構成**に挑戦します。地理的に離れた複数のリージョンでクラスタを運用し、リージョン全体の障害にも耐えられる究極の可用性を実現します。

### 主要な学習ポイント

- Topology Spread Constraintsでゾーン間のPod分散を制御
- StatefulSetとPersistentVolumeのゾーン対応設計
- クロスゾーンロードバランシングの設定
- コントロールプレーンのマルチゾーン配置
- PodDisruptionBudgetによる最小稼働数の保証
- ゾーン障害シミュレーションによる検証

さぁ、次回はグローバルスケールのマルチリージョン構成で、世界規模の災害にも耐えるシステムを構築しましょう！
