---
title: "マルチゾーン構成で可用性向上 - AZ分散による障害耐性（技術詳細）"
draft: true
tags:
- kubernetes
- high-availability
- multi-az
- availability-zone
- pod-topology
- affinity
description: "KubernetesのマルチAZ構成を完全解説。PodTopologySpreadConstraints、PodAntiAffinity、EBSとAZの制約、ゾーン障害対策まで実践的に学ぶ。"
---

## はじめに

クラウドプロバイダーのAvailability Zone（AZ）は物理的に分離されたデータセンターであり、一つのAZ全体が障害を起こしても他のAZは影響を受けません。KubernetesでマルチAZ構成を実装することで、単一障害点を排除し、高可用性を実現できます。本記事では、PodTopologySpreadConstraints、PodAntiAffinity、ストレージとAZの制約について徹底解説します。

## 1. Availability Zone（AZ）の基礎

### 1.1 AZとは何か

```
AWSリージョンの例（ap-northeast-1）:

┌─────────────────────────────────────────────────────────┐
│ ap-northeast-1 (東京リージョン)                          │
│                                                         │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐ │
│  │ ap-northeast │  │ ap-northeast │  │ ap-northeast │ │
│  │     -1a      │  │     -1c      │  │     -1d      │ │
│  │              │  │              │  │              │ │
│  │ データセンタ  │  │ データセンタ  │  │ データセンタ  │ │
│  │   グループ1  │  │   グループ2  │  │   グループ3  │ │
│  │              │  │              │  │              │ │
│  │ 独立電源     │  │ 独立電源     │  │ 独立電源     │ │
│  │ 独立ネットワーク│  │ 独立ネットワーク│  │ 独立ネットワーク│ │
│  └──────────────┘  └──────────────┘  └──────────────┘ │
│         ↕️              ↕️              ↕️          │
│    低遅延接続       低遅延接続       低遅延接続         │
└─────────────────────────────────────────────────────────┘

AZの特性:
✅ 物理的に分離（異なる建物、電源、ネットワーク）
✅ 低レイテンシ接続（<2ms）
✅ 独立した障害ドメイン
✅ 同期レプリケーション可能
```

### 1.2 KubernetesとAZ

```bash
# Nodeのラベルを確認（AZ情報）
kubectl get nodes -L topology.kubernetes.io/zone

# 出力例:
# NAME                              STATUS   ROLES    AGE   VERSION   ZONE
# ip-10-0-1-100.ec2.internal        Ready    <none>   5d    v1.28.0   ap-northeast-1a
# ip-10-0-1-101.ec2.internal        Ready    <none>   5d    v1.28.0   ap-northeast-1a
# ip-10-0-2-100.ec2.internal        Ready    <none>   5d    v1.28.0   ap-northeast-1c
# ip-10-0-2-101.ec2.internal        Ready    <none>   5d    v1.28.0   ap-northeast-1c
# ip-10-0-3-100.ec2.internal        Ready    <none>   5d    v1.28.0   ap-northeast-1d
# ip-10-0-3-101.ec2.internal        Ready    <none>   5d    v1.28.0   ap-northeast-1d

# 標準のゾーンラベル
kubectl get nodes --show-labels | grep topology.kubernetes.io/zone
# topology.kubernetes.io/zone=ap-northeast-1a
# topology.kubernetes.io/zone=ap-northeast-1c
# topology.kubernetes.io/zone=ap-northeast-1d
```

## 2. PodTopologySpreadConstraints（推奨）

### 2.1 基本概念

```
PodTopologySpreadConstraintsの仕組み:

目的: Podを指定したトポロジドメイン（AZ、ノード、リージョンなど）に均等に分散

┌─────────────────────────────────────────────────────────┐
│ 3つのAZに6つのPodを均等分散                              │
│                                                         │
│  AZ-1a         AZ-1c         AZ-1d                      │
│  ┌────┐       ┌────┐       ┌────┐                      │
│  │Pod1│       │Pod3│       │Pod5│                      │
│  │Pod2│       │Pod4│       │Pod6│                      │
│  └────┘       └────┘       └────┘                      │
│   2個          2個          2個                         │
│                                                         │
│ maxSkew=1 → 最大差は1個まで許容                         │
└─────────────────────────────────────────────────────────┘
```

### 2.2 基本設定

```yaml
# web-deployment-spread.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app
  namespace: production
spec:
  replicas: 6
  selector:
    matchLabels:
      app: web
  template:
    metadata:
      labels:
        app: web
    spec:
      # PodTopologySpreadConstraints
      topologySpreadConstraints:
      # AZ間での分散
      - maxSkew: 1  # 最大スキュー（差）
        topologyKey: topology.kubernetes.io/zone  # 分散キー
        whenUnsatisfiable: DoNotSchedule  # 満たせない場合はスケジュールしない
        labelSelector:
          matchLabels:
            app: web
      
      containers:
      - name: web
        image: nginx:1.25
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            cpu: 200m
            memory: 256Mi
```

```bash
# デプロイ
kubectl apply -f web-deployment-spread.yaml

# Pod配置の確認
kubectl get pods -l app=web -o wide \
  --sort-by=.spec.nodeName

# どのAZに配置されたか確認
kubectl get pods -l app=web -o custom-columns=\
NAME:.metadata.name,\
NODE:.spec.nodeName,\
ZONE:.spec.nodeSelector.'topology\.kubernetes\.io/zone'

# 分散状況の確認
for zone in ap-northeast-1a ap-northeast-1c ap-northeast-1d; do
  count=$(kubectl get pods -l app=web -o json | \
    jq -r --arg zone "$zone" \
    '.items[] | select(.spec.nodeSelector."topology.kubernetes.io/zone"==$zone) | .metadata.name' | wc -l)
  echo "Zone $zone: $count pods"
done

# 出力例:
# Zone ap-northeast-1a: 2 pods
# Zone ap-northeast-1c: 2 pods
# Zone ap-northeast-1d: 2 pods
```

### 2.3 高度な設定オプション

```yaml
# advanced-topology-spread.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: critical-app
  namespace: production
spec:
  replicas: 9
  selector:
    matchLabels:
      app: critical
      tier: frontend
  template:
    metadata:
      labels:
        app: critical
        tier: frontend
    spec:
      topologySpreadConstraints:
      # 1. AZ間での分散（最優先）
      - maxSkew: 1
        topologyKey: topology.kubernetes.io/zone
        whenUnsatisfiable: DoNotSchedule
        labelSelector:
          matchLabels:
            app: critical
            tier: frontend
      
      # 2. ノード間での分散（次優先）
      - maxSkew: 1
        topologyKey: kubernetes.io/hostname
        whenUnsatisfiable: ScheduleAnyway  # できれば分散、無理なら許容
        labelSelector:
          matchLabels:
            app: critical
            tier: frontend
      
      # 3. インスタンスタイプ間での分散
      - maxSkew: 2
        topologyKey: node.kubernetes.io/instance-type
        whenUnsatisfiable: ScheduleAnyway
        labelSelector:
          matchLabels:
            app: critical
      
      containers:
      - name: app
        image: critical-app:1.0
        resources:
          requests:
            cpu: 500m
            memory: 512Mi
          limits:
            cpu: 1000m
            memory: 1Gi
```

### 2.4 whenUnsatisfiableの挙動

```yaml
# whenUnsatisfiable の比較

# DoNotSchedule: 制約を満たせない場合はスケジュールしない（厳密）
topologySpreadConstraints:
- maxSkew: 1
  topologyKey: topology.kubernetes.io/zone
  whenUnsatisfiable: DoNotSchedule  # ⛔ 満たせなければPending
  labelSelector:
    matchLabels:
      app: web

# ScheduleAnyway: できれば制約を満たすが、無理なら許容（柔軟）
topologySpreadConstraints:
- maxSkew: 1
  topologyKey: topology.kubernetes.io/zone
  whenUnsatisfiable: ScheduleAnyway  # ✅ 満たせなくても配置
  labelSelector:
    matchLabels:
      app: web
```

```bash
# シナリオ: 2つのAZしか利用可能でない場合

# DoNotSchedule の場合
# replicas: 7 → 3個ずつ配置 + 1個がPending（maxSkew=1を満たせない）

# ScheduleAnyway の場合
# replicas: 7 → 3個と4個に配置（maxSkew=1を超えるが配置される）
```

## 3. PodAntiAffinity（旧方式）

### 3.1 基本概念

```
PodAntiAffinityの仕組み:

目的: 特定のPodと同じノード/AZに配置されないようにする

┌─────────────────────────────────────────────────────────┐
│ 同じアプリのPodを異なるAZに配置                          │
│                                                         │
│  AZ-1a         AZ-1c         AZ-1d                      │
│  ┌────┐       ┌────┐       ┌────┐                      │
│  │Pod1│  ←─→ │Pod2│  ←─→ │Pod3│                      │
│  └────┘  反発  └────┘  反発  └────┘                      │
│                                                         │
│ AntiAffinity: app=web のPodは同じゾーンに配置しない      │
└─────────────────────────────────────────────────────────┘
```

### 3.2 必須AntiAffinity（requiredDuringScheduling）

```yaml
# web-deployment-antiaffinity.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app-antiaffinity
  namespace: production
spec:
  replicas: 3
  selector:
    matchLabels:
      app: web
  template:
    metadata:
      labels:
        app: web
    spec:
      # PodAntiAffinity（必須）
      affinity:
        podAntiAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
          # 同じAZに同じアプリのPodを配置しない
          - labelSelector:
              matchLabels:
                app: web
            topologyKey: topology.kubernetes.io/zone
      
      containers:
      - name: web
        image: nginx:1.25
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
```

```bash
# デプロイ
kubectl apply -f web-deployment-antiaffinity.yaml

# 配置確認
kubectl get pods -l app=web -o wide

# 期待される動作:
# - 3つのPodがそれぞれ異なるAZに配置される
# - AZが2つしかない場合、3つ目のPodはPendingになる
```

### 3.3 優先AntiAffinity（preferredDuringScheduling）

```yaml
# web-deployment-preferred-antiaffinity.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app-preferred
  namespace: production
spec:
  replicas: 6
  selector:
    matchLabels:
      app: web
  template:
    metadata:
      labels:
        app: web
    spec:
      affinity:
        podAntiAffinity:
          # 優先的にAntiAffinityを適用（柔軟）
          preferredDuringSchedulingIgnoredDuringExecution:
          # 重み100: できるだけ異なるAZに配置
          - weight: 100
            podAffinityTerm:
              labelSelector:
                matchLabels:
                  app: web
              topologyKey: topology.kubernetes.io/zone
          
          # 重み50: できるだけ異なるノードに配置
          - weight: 50
            podAffinityTerm:
              labelSelector:
                matchLabels:
                  app: web
              topologyKey: kubernetes.io/hostname
      
      containers:
      - name: web
        image: nginx:1.25
```

### 3.4 TopologySpreadConstraints vs PodAntiAffinity

| 項目 | TopologySpreadConstraints | PodAntiAffinity |
|------|--------------------------|-----------------|
| **推奨度** | ✅ 推奨（Kubernetes 1.19+） | ⚠️ レガシー |
| **分散制御** | 細かい制御可能（maxSkew） | 粗い制御（完全分離のみ） |
| **柔軟性** | 高い | 低い |
| **複数トポロジ** | 複数同時指定可能 | 複雑になる |
| **使いやすさ** | シンプル | 複雑 |
| **パフォーマンス** | 良好 | やや劣る |

**推奨**: 新規構成では`TopologySpreadConstraints`を使用。

## 4. EBSとAZの制約

### 4.1 EBS Volumeの制約

```
EBS VolumeとAZの制約:

重要な制約:
❌ EBS VolumeはAZを跨げない
❌ 異なるAZのEC2インスタンスからアタッチ不可
✅ 同じAZ内でのみアタッチ可能

┌─────────────────────────────────────────────────────────┐
│ AZ-1a                      AZ-1c                        │
│ ┌──────────┐              ┌──────────┐                 │
│ │  Pod A   │              │  Pod B   │                 │
│ │          │              │          │                 │
│ │  Node1   │              │  Node2   │                 │
│ └────┬─────┘              └──────────┘                 │
│      │                                                  │
│      ↓ ✅ アタッチ可能                                   │
│ ┌──────────┐                                           │
│ │EBS Volume│                                           │
│ │(AZ-1a)   │                                           │
│ └──────────┘                                           │
│      ↓ ❌ アタッチ不可（異なるAZ）                        │
│      ✗ ────────────────────→ Node2 (AZ-1c)             │
└─────────────────────────────────────────────────────────┘
```

### 4.2 StatefulSetとAZ分散

```yaml
# statefulset-multi-az.yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: database
  namespace: production
spec:
  serviceName: database
  replicas: 3
  selector:
    matchLabels:
      app: database
  
  # PodTopologySpreadConstraints でAZ分散
  template:
    metadata:
      labels:
        app: database
    spec:
      topologySpreadConstraints:
      - maxSkew: 1
        topologyKey: topology.kubernetes.io/zone
        whenUnsatisfiable: DoNotSchedule
        labelSelector:
          matchLabels:
            app: database
      
      containers:
      - name: postgres
        image: postgres:15
        ports:
        - containerPort: 5432
          name: postgres
        volumeMounts:
        - name: data
          mountPath: /var/lib/postgresql/data
        env:
        - name: POSTGRES_PASSWORD
          valueFrom:
            secretKeyRef:
              name: db-credentials
              key: password
  
  # VolumeClaimTemplates: 各Podが個別のEBSボリュームを持つ
  volumeClaimTemplates:
  - metadata:
      name: data
    spec:
      accessModes: ["ReadWriteOnce"]
      storageClassName: gp3  # AWS EBS gp3
      resources:
        requests:
          storage: 100Gi
```

```bash
# デプロイ
kubectl apply -f statefulset-multi-az.yaml

# PVCとPodの配置確認
kubectl get pvc -l app=database
# NAME              STATUS   VOLUME                                     CAPACITY   STORAGECLASS
# data-database-0   Bound    pvc-xxx-1a                                 100Gi      gp3
# data-database-1   Bound    pvc-xxx-1c                                 100Gi      gp3
# data-database-2   Bound    pvc-xxx-1d                                 100Gi      gp3

# Podが各AZに配置されていることを確認
kubectl get pods -l app=database -o custom-columns=\
NAME:.metadata.name,\
NODE:.spec.nodeName,\
ZONE:.spec.nodeSelector.'topology\.kubernetes\.io/zone'

# 出力:
# NAME          NODE                              ZONE
# database-0    ip-10-0-1-100.ec2.internal        ap-northeast-1a
# database-1    ip-10-0-2-100.ec2.internal        ap-northeast-1c
# database-2    ip-10-0-3-100.ec2.internal        ap-northeast-1d
```

### 4.3 EBS CSI Driverのトポロジ対応

```yaml
# ebs-storageclass-topology.yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: gp3-wait-for-first-consumer
provisioner: ebs.csi.aws.com
parameters:
  type: gp3
  iops: "3000"
  throughput: "125"
  encrypted: "true"
  kmsKeyId: "arn:aws:kms:ap-northeast-1:123456789012:key/xxx"

# volumeBindingMode: WaitForFirstConsumer
# PodがスケジュールされたAZでPVをプロビジョニング
volumeBindingMode: WaitForFirstConsumer

# 許可されたトポロジ
allowedTopologies:
- matchLabelExpressions:
  - key: topology.kubernetes.io/zone
    values:
    - ap-northeast-1a
    - ap-northeast-1c
    - ap-northeast-1d
```

```bash
# StorageClassの適用
kubectl apply -f ebs-storageclass-topology.yaml

# 動作確認用PVC
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: test-pvc
  namespace: default
spec:
  accessModes:
  - ReadWriteOnce
  storageClassName: gp3-wait-for-first-consumer
  resources:
    requests:
      storage: 10Gi
EOF

# PVCの状態確認（Pending: Podがまだ作成されていないため）
kubectl get pvc test-pvc
# NAME       STATUS    VOLUME   CAPACITY   ACCESS MODES   STORAGECLASS
# test-pvc   Pending                                      gp3-wait-for-first-consumer

# Podを作成してPVCを使用
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: test-pod
  namespace: default
spec:
  containers:
  - name: app
    image: nginx
    volumeMounts:
    - name: data
      mountPath: /data
  volumes:
  - name: data
    persistentVolumeClaim:
      claimName: test-pvc
  # Node Affinityで特定AZを指定
  nodeSelector:
    topology.kubernetes.io/zone: ap-northeast-1a
EOF

# PodがスケジュールされたAZでPVが作成される
kubectl get pvc test-pvc
# NAME       STATUS   VOLUME      CAPACITY   ACCESS MODES   STORAGECLASS
# test-pvc   Bound    pvc-xxx-1a  10Gi       RWO            gp3-wait-for-first-consumer

# PVの詳細確認（AZ情報）
kubectl get pv $(kubectl get pvc test-pvc -o jsonpath='{.spec.volumeName}') \
  -o jsonpath='{.metadata.labels.topology\.kubernetes\.io/zone}'
# ap-northeast-1a
```

## 5. ゾーン障害対策

### 5.1 ゾーン障害シミュレーション

```bash
# 特定AZのノードを全て停止（シミュレーション）
# ⚠️ 本番環境では絶対に実行しない

# AZ-1aのノード一覧取得
NODES=$(kubectl get nodes -l topology.kubernetes.io/zone=ap-northeast-1a -o name)

# ノードをcordon（新規Pod配置を停止）
for node in $NODES; do
  kubectl cordon $node
done

# 既存Podを退避（drain）
for node in $NODES; do
  kubectl drain $node --ignore-daemonsets --delete-emptydir-data
done

# Podの再配置確認
kubectl get pods -l app=web -o wide
# Podが他のAZ（1c、1d）に自動的に再配置される

# 復旧
for node in $NODES; do
  kubectl uncordon $node
done
```

### 5.2 Deployment with PDB（Pod Disruption Budget）

```yaml
# web-deployment-with-pdb.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app
  namespace: production
spec:
  replicas: 6
  selector:
    matchLabels:
      app: web
  template:
    metadata:
      labels:
        app: web
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
        image: nginx:1.25
        ports:
        - containerPort: 80
        resources:
          requests:
            cpu: 100m
            memory: 128Mi
          limits:
            cpu: 200m
            memory: 256Mi
        
        # Liveness/Readiness Probe
        livenessProbe:
          httpGet:
            path: /healthz
            port: 80
          initialDelaySeconds: 30
          periodSeconds: 10
        
        readinessProbe:
          httpGet:
            path: /ready
            port: 80
          initialDelaySeconds: 5
          periodSeconds: 5
---
# Pod Disruption Budget
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: web-app-pdb
  namespace: production
spec:
  minAvailable: 4  # 最低4つのPodは常に稼働
  selector:
    matchLabels:
      app: web
```

```bash
# デプロイ
kubectl apply -f web-deployment-with-pdb.yaml

# PDBの確認
kubectl get pdb web-app-pdb -n production
# NAME          MIN AVAILABLE   MAX UNAVAILABLE   ALLOWED DISRUPTIONS   AGE
# web-app-pdb   4               N/A               2                     10s

# ゾーン障害時の動作:
# - AZ-1aが障害（2つのPodダウン）
# - PDBにより、4つのPodは常に稼働を維持
# - 残りのAZ（1c、1d）でサービス継続
```

### 5.3 複数AZ対応Serviceの設定

```yaml
# web-service-multi-az.yaml
apiVersion: v1
kind: Service
metadata:
  name: web-service
  namespace: production
  annotations:
    # AWS Load Balancer Controller
    service.beta.kubernetes.io/aws-load-balancer-type: "nlb"
    service.beta.kubernetes.io/aws-load-balancer-cross-zone-load-balancing-enabled: "true"
    service.beta.kubernetes.io/aws-load-balancer-scheme: "internet-facing"
    
    # マルチAZ対応
    service.beta.kubernetes.io/aws-load-balancer-subnets: subnet-1a,subnet-1c,subnet-1d
spec:
  type: LoadBalancer
  selector:
    app: web
  ports:
  - protocol: TCP
    port: 80
    targetPort: 80
  
  # トラフィック分散ポリシー
  externalTrafficPolicy: Local  # ノードローカルエンドポイントのみ使用
  internalTrafficPolicy: Local
```

```bash
# Serviceのデプロイ
kubectl apply -f web-service-multi-az.yaml

# Load Balancerの確認
kubectl get svc web-service -n production
# NAME          TYPE           CLUSTER-IP      EXTERNAL-IP
# web-service   LoadBalancer   10.100.200.50   xxx.elb.amazonaws.com

# Load Balancerのターゲット確認（AWS CLI）
aws elbv2 describe-target-health \
  --target-group-arn arn:aws:elasticloadbalancing:ap-northeast-1:123456789012:targetgroup/xxx \
  --query 'TargetHealthDescriptions[*].[Target.Id,Target.AvailabilityZone,TargetHealth.State]' \
  --output table

# 出力例:
# |  i-xxx1  |  ap-northeast-1a  |  healthy  |
# |  i-xxx2  |  ap-northeast-1a  |  healthy  |
# |  i-xxx3  |  ap-northeast-1c  |  healthy  |
# |  i-xxx4  |  ap-northeast-1c  |  healthy  |
# |  i-xxx5  |  ap-northeast-1d  |  healthy  |
# |  i-xxx6  |  ap-northeast-1d  |  healthy  |
```

## 6. マルチAZ構成のベストプラクティス

### 6.1 推奨構成パターン

```yaml
# production-app-multi-az.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: production-app
  namespace: production
  labels:
    app: production-app
    tier: backend
spec:
  # 最低でも3のreplicas（各AZに1つ以上）
  replicas: 6
  
  selector:
    matchLabels:
      app: production-app
      tier: backend
  
  template:
    metadata:
      labels:
        app: production-app
        tier: backend
    spec:
      # TopologySpreadConstraints（推奨）
      topologySpreadConstraints:
      # AZ分散（必須）
      - maxSkew: 1
        topologyKey: topology.kubernetes.io/zone
        whenUnsatisfiable: DoNotSchedule
        labelSelector:
          matchLabels:
            app: production-app
      
      # ノード分散（推奨）
      - maxSkew: 2
        topologyKey: kubernetes.io/hostname
        whenUnsatisfiable: ScheduleAnyway
        labelSelector:
          matchLabels:
            app: production-app
      
      # 優先: 異なるホストに配置
      affinity:
        podAntiAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 100
            podAffinityTerm:
              labelSelector:
                matchLabels:
                  app: production-app
              topologyKey: kubernetes.io/hostname
      
      containers:
      - name: app
        image: production-app:1.0.0
        ports:
        - containerPort: 8080
          name: http
        
        resources:
          requests:
            cpu: 500m
            memory: 512Mi
          limits:
            cpu: 1000m
            memory: 1Gi
        
        # 健全性チェック
        livenessProbe:
          httpGet:
            path: /healthz
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 10
          timeoutSeconds: 5
          failureThreshold: 3
        
        readinessProbe:
          httpGet:
            path: /ready
            port: 8080
          initialDelaySeconds: 5
          periodSeconds: 5
          timeoutSeconds: 3
          failureThreshold: 2
---
# Pod Disruption Budget
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: production-app-pdb
  namespace: production
spec:
  minAvailable: 4  # 6つ中4つは常に稼働
  selector:
    matchLabels:
      app: production-app
      tier: backend
```

### 6.2 チェックリスト

- ✅ 最低3つのAZ使用（2つでは不十分）
- ✅ レプリカ数は3の倍数（AZ数の倍数）
- ✅ TopologySpreadConstraintsで均等分散
- ✅ PodDisruptionBudgetで最小稼働数保証
- ✅ WaitForFirstConsumerでストレージのAZ最適化
- ✅ externalTrafficPolicy: Localでノードローカル通信
- ✅ クロスゾーンロードバランシング有効化
- ✅ 定期的なゾーン障害訓練
- ✅ モニタリングでAZ別メトリクス収集
- ❌ 単一AZへの偏り配置を避ける

## まとめ

### 学んだこと

1. **Availability Zoneの基礎**
   - 物理的に分離されたデータセンター
   - 独立した障害ドメイン
   - Kubernetesのゾーンラベル

2. **PodTopologySpreadConstraints**
   - 柔軟な分散制御（maxSkew）
   - 複数トポロジキー対応
   - DoNotSchedule vs ScheduleAnyway

3. **EBSとAZの制約**
   - EBSはAZを跨げない
   - WaitForFirstConsumerが重要
   - StatefulSetでのAZ分散

4. **ゾーン障害対策**
   - PodDisruptionBudget
   - クロスゾーンロードバランシング
   - 定期的な障害訓練

5. **ベストプラクティス**
   - 最低3つのAZ使用
   - TopologySpreadConstraints推奨
   - レプリカ数はAZ数の倍数
   - モニタリングとアラート

### 次回予告

次回は「マルチリージョン構成とフェデレーション」として、KubeFedによる複数リージョンのクラスタ管理、Global Load Balancing、データレプリケーション戦略を解説します。

## 参考リンク

- {{< linkcard "https://kubernetes.io/docs/concepts/scheduling-eviction/topology-spread-constraints/" >}}
- {{< linkcard "https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/" >}}
- {{< linkcard "https://aws.amazon.com/about-aws/global-infrastructure/regions_az/" >}}
- {{< linkcard "https://kubernetes.io/docs/concepts/storage/storage-classes/" >}}
