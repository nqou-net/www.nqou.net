---
title: "マルチリージョン構成とフェデレーション - グローバル展開の実現（技術詳細）"
draft: true
tags:
- kubernetes
- multi-region
- federation
- kubefed
- global-load-balancing
- disaster-recovery
description: "KubeFedによるマルチクラスタ管理を完全解説。Global Load Balancing、データレプリケーション戦略、アクティブ-アクティブ/スタンバイ構成まで実践的に学ぶ。"
---

## はじめに

マルチAZ構成は単一リージョン内の可用性を高めますが、リージョン全体の障害やグローバル展開には対応できません。マルチリージョン構成では、複数の地理的に離れたリージョンにKubernetesクラスタを配置し、KubeFed（Kubernetes Federation）で統合管理します。本記事では、KubeFedの実装、Global Load Balancing、データレプリケーション戦略、アクティブ-アクティブ/スタンバイ構成を徹底解説します。

## 1. マルチリージョン構成の基礎

### 1.1 なぜマルチリージョンが必要か

```
マルチリージョンの目的:

1. 災害対策（DR: Disaster Recovery）
   リージョン全体の障害に対応

2. グローバルユーザー対応
   ユーザーに最も近いリージョンからサービス提供

3. データ主権・コンプライアンス
   国・地域のデータ保管要件に対応

4. 高可用性の究極形
   99.999%（ファイブナイン）以上の可用性

┌─────────────────────────────────────────────────────────┐
│ グローバル構成例                                          │
│                                                         │
│  アジア太平洋         ヨーロッパ        北米             │
│  ap-northeast-1       eu-west-1        us-east-1       │
│  (東京)              (アイルランド)    (バージニア)     │
│  ┌─────────┐         ┌─────────┐      ┌─────────┐      │
│  │Cluster 1│ ←────→ │Cluster 2│ ←──→ │Cluster 3│      │
│  │  (主)   │  同期   │  (主)   │ 同期 │  (主)   │      │
│  └─────────┘         └─────────┘      └─────────┘      │
│      ↓                   ↓                ↓            │
│  アジアユーザー       欧州ユーザー    米国ユーザー        │
│  (低レイテンシ)      (低レイテンシ)   (低レイテンシ)     │
└─────────────────────────────────────────────────────────┘
```

### 1.2 マルチリージョン vs マルチAZ

| 項目 | マルチAZ | マルチリージョン |
|------|---------|-----------------|
| **スコープ** | 単一リージョン内 | 複数リージョン |
| **レイテンシ** | <2ms | 50-300ms |
| **障害範囲** | AZ障害に対応 | リージョン障害に対応 |
| **コスト** | 低（同一リージョン転送無料） | 高（リージョン間転送課金） |
| **複雑性** | 低 | 高 |
| **データ同期** | 同期レプリケーション可能 | 非同期レプリケーション |
| **ユースケース** | 単一リージョン内HA | グローバル展開、DR |

## 2. KubeFed（Kubernetes Federation v2）

### 2.1 KubeFedとは

```
KubeFedの仕組み:

┌─────────────────────────────────────────────────────────┐
│ KubeFed Control Plane (Host Cluster)                    │
│ ┌─────────────────────────────────────────────────────┐ │
│ │ FederatedDeployment                                 │ │
│ │ FederatedService                                    │ │
│ │ FederatedConfigMap                                  │ │
│ └────────────────┬────────────────────────────────────┘ │
│                  │                                      │
│                  │ Propagates                           │
│        ┌─────────┴─────────┬─────────────┐             │
│        ↓                   ↓             ↓             │
│  ┌──────────┐        ┌──────────┐  ┌──────────┐       │
│  │Cluster 1 │        │Cluster 2 │  │Cluster 3 │       │
│  │ (東京)   │        │(アイルランド)│ │(バージニア)│       │
│  └──────────┘        └──────────┘  └──────────┘       │
└─────────────────────────────────────────────────────────┘

KubeFedの役割:
✅ 複数クラスタの一元管理
✅ リソースの自動配布
✅ クラスタ間のスケジューリング
✅ フェイルオーバー自動化
```

### 2.2 KubeFedのインストール

```bash
# Helm経由でKubeFedをインストール
# Host Cluster（管理クラスタ）で実行

# Helmリポジトリ追加
helm repo add kubefed-charts https://raw.githubusercontent.com/kubernetes-sigs/kubefed/master/charts
helm repo update

# KubeFed CRDとControllerのインストール
helm install kubefed kubefed-charts/kubefed \
  --namespace kube-federation-system \
  --create-namespace \
  --set controllermanager.replicaCount=2

# インストール確認
kubectl get pods -n kube-federation-system
# NAME                                          READY   STATUS    RESTARTS   AGE
# kubefed-controller-manager-xxx                2/2     Running   0          1m
# kubefed-admission-webhook-xxx                 1/1     Running   0          1m

# kubefedctlのインストール（CLIツール）
OS="linux"  # or "darwin" for macOS
ARCH="amd64"
VERSION="0.10.0"
wget https://github.com/kubernetes-sigs/kubefed/releases/download/v${VERSION}/kubefedctl-${VERSION}-${OS}-${ARCH}.tgz
tar -xzf kubefedctl-${VERSION}-${OS}-${ARCH}.tgz
sudo mv kubefedctl /usr/local/bin/
rm kubefedctl-${VERSION}-${OS}-${ARCH}.tgz

# 確認
kubefedctl version
# kubefedctl version: version.Info{Version:"v0.10.0", ...}
```

### 2.3 Member Clusterの登録

```bash
# 前提: 各クラスタのkubeconfigファイルが存在する
# - ~/.kube/config-tokyo (ap-northeast-1)
# - ~/.kube/config-ireland (eu-west-1)
# - ~/.kube/config-virginia (us-east-1)

# Host Clusterのコンテキストを設定
kubectl config use-context host-cluster

# Member Cluster 1の登録（東京）
kubefedctl join tokyo-cluster \
  --cluster-context tokyo-cluster \
  --host-cluster-context host-cluster \
  --kubefed-namespace kube-federation-system

# Member Cluster 2の登録（アイルランド）
kubefedctl join ireland-cluster \
  --cluster-context ireland-cluster \
  --host-cluster-context host-cluster \
  --kubefed-namespace kube-federation-system

# Member Cluster 3の登録（バージニア）
kubefedctl join virginia-cluster \
  --cluster-context virginia-cluster \
  --host-cluster-context host-cluster \
  --kubefed-namespace kube-federation-system

# 登録確認
kubectl get kubefedclusters -n kube-federation-system
# NAME               AGE   READY
# tokyo-cluster      2m    True
# ireland-cluster    2m    True
# virginia-cluster   2m    True

# 各クラスタの詳細確認
kubectl describe kubefedcluster tokyo-cluster -n kube-federation-system
# Status:
#   Conditions:
#     Type: Ready
#     Status: True
#     Reason: ClusterReady
```

### 2.4 Federated Typeの有効化

```bash
# DeploymentをFederated管理対象にする
kubefedctl enable deployments

# Serviceを有効化
kubefedctl enable services

# ConfigMapを有効化
kubefedctl enable configmaps

# Secretを有効化
kubefedctl enable secrets

# IngressをFederated管理対象にする
kubefedctl enable ingresses

# 有効化されたリソースの確認
kubectl get federatedtypeconfigs -n kube-federation-system
# NAME                         AGE
# deployments.apps             1m
# services                     1m
# configmaps                   1m
# secrets                      1m
# ingresses.networking.k8s.io  1m
```

## 3. FederatedDeploymentの実装

### 3.1 基本的なFederatedDeployment

```yaml
# federated-web-app.yaml
apiVersion: types.kubefed.io/v1beta1
kind: FederatedDeployment
metadata:
  name: web-app
  namespace: production
spec:
  # テンプレート: 全クラスタに共通のDeployment定義
  template:
    metadata:
      labels:
        app: web
    spec:
      replicas: 3  # デフォルトレプリカ数
      selector:
        matchLabels:
          app: web
      template:
        metadata:
          labels:
            app: web
        spec:
          containers:
          - name: web
            image: myregistry/web-app:1.0.0
            ports:
            - containerPort: 8080
            resources:
              requests:
                cpu: 200m
                memory: 256Mi
              limits:
                cpu: 500m
                memory: 512Mi
            livenessProbe:
              httpGet:
                path: /healthz
                port: 8080
              initialDelaySeconds: 30
              periodSeconds: 10
            readinessProbe:
              httpGet:
                path: /ready
                port: 8080
              initialDelaySeconds: 5
              periodSeconds: 5
  
  # Placement: どのクラスタにデプロイするか
  placement:
    clusters:
    - name: tokyo-cluster
    - name: ireland-cluster
    - name: virginia-cluster
  
  # Overrides: クラスタごとの設定上書き
  overrides:
  # 東京クラスタはレプリカ数5
  - clusterName: tokyo-cluster
    clusterOverrides:
    - path: "/spec/replicas"
      value: 5
  
  # アイルランドクラスタはレプリカ数3
  - clusterName: ireland-cluster
    clusterOverrides:
    - path: "/spec/replicas"
      value: 3
  
  # バージニアクラスタはレプリカ数4
  - clusterName: virginia-cluster
    clusterOverrides:
    - path: "/spec/replicas"
      value: 4
```

```bash
# FederatedDeploymentのデプロイ
kubectl apply -f federated-web-app.yaml

# 各クラスタでのDeployment確認
# 東京クラスタ
kubectl --context tokyo-cluster get deployment web-app -n production
# NAME      READY   UP-TO-DATE   AVAILABLE   AGE
# web-app   5/5     5            5           2m

# アイルランドクラスタ
kubectl --context ireland-cluster get deployment web-app -n production
# NAME      READY   UP-TO-DATE   AVAILABLE   AGE
# web-app   3/3     3            3           2m

# バージニアクラスタ
kubectl --context virginia-cluster get deployment web-app -n production
# NAME      READY   UP-TO-DATE   AVAILABLE   AGE
# web-app   4/4     4            4           2m
```

### 3.2 ReplicaSchedulingPreference

```yaml
# federated-web-app-scheduling.yaml
apiVersion: types.kubefed.io/v1beta1
kind: FederatedDeployment
metadata:
  name: web-app
  namespace: production
spec:
  template:
    # ... (前述と同じ)
  
  placement:
    clusters:
    - name: tokyo-cluster
    - name: ireland-cluster
    - name: virginia-cluster
---
# ReplicaSchedulingPreference: レプリカの自動分散
apiVersion: scheduling.kubefed.io/v1alpha1
kind: ReplicaSchedulingPreference
metadata:
  name: web-app
  namespace: production
spec:
  targetKind: FederatedDeployment
  totalReplicas: 12  # 全体のレプリカ数
  
  # 重み付けによる分散
  clusters:
    tokyo-cluster:
      weight: 5  # 50% (5/10)
    ireland-cluster:
      weight: 3  # 30% (3/10)
    virginia-cluster:
      weight: 2  # 20% (2/10)
  
  # 最小/最大レプリカ数
  rebalance: true  # 自動再バランシング
  
  # クラスタごとの最小レプリカ数
  minReplicas:
    tokyo-cluster: 3
    ireland-cluster: 2
    virginia-cluster: 2
```

```bash
# ReplicaSchedulingPreferenceの適用
kubectl apply -f federated-web-app-scheduling.yaml

# 分散確認
# 東京: 12 * 50% = 6 replicas (最小3以上)
# アイルランド: 12 * 30% = 3.6 → 4 replicas (最小2以上)
# バージニア: 12 * 20% = 2.4 → 2 replicas (最小2以上)

# 実際の分散確認
kubectl --context tokyo-cluster get deployment web-app -n production -o jsonpath='{.spec.replicas}'
# 6

kubectl --context ireland-cluster get deployment web-app -n production -o jsonpath='{.spec.replicas}'
# 4

kubectl --context virginia-cluster get deployment web-app -n production -o jsonpath='{.spec.replicas}'
# 2
```

## 4. Global Load Balancing

### 4.1 DNS-based Global Load Balancing

```
DNS-based GLBの仕組み:

┌─────────────────────────────────────────────────────────┐
│ Global DNS (例: Route 53 / Cloud DNS)                   │
│                                                         │
│ app.example.com → Geolocation/Latency-based Routing    │
│         │                                               │
│         ├─→ アジアユーザー → tokyo-lb.example.com       │
│         │                   (ALB in ap-northeast-1)    │
│         ├─→ 欧州ユーザー → ireland-lb.example.com       │
│         │                   (ALB in eu-west-1)         │
│         └─→ 米国ユーザー → virginia-lb.example.com      │
│                             (ALB in us-east-1)         │
└─────────────────────────────────────────────────────────┘
```

**AWS Route 53の設定例**:

```yaml
# external-dns-config.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: external-dns
  namespace: kube-system
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::123456789012:role/ExternalDNSRole
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: external-dns
  namespace: kube-system
spec:
  replicas: 1
  selector:
    matchLabels:
      app: external-dns
  template:
    metadata:
      labels:
        app: external-dns
    spec:
      serviceAccountName: external-dns
      containers:
      - name: external-dns
        image: registry.k8s.io/external-dns/external-dns:v0.14.0
        args:
        - --source=service
        - --source=ingress
        - --domain-filter=example.com
        - --provider=aws
        - --policy=sync
        - --aws-zone-type=public
        - --registry=txt
        - --txt-owner-id=my-cluster-id
```

```yaml
# web-service-global.yaml (各クラスタで実行)
apiVersion: v1
kind: Service
metadata:
  name: web-service
  namespace: production
  annotations:
    # 東京クラスタ
    external-dns.alpha.kubernetes.io/hostname: tokyo-lb.example.com
    # Geolocation routing
    external-dns.alpha.kubernetes.io/set-identifier: tokyo
    external-dns.alpha.kubernetes.io/aws-geolocation-continent-code: AS
    
    # AWS Load Balancer
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

### 4.2 Multi-Cluster Ingress（GKE）

```yaml
# multi-cluster-ingress.yaml (GKE)
apiVersion: networking.gke.io/v1
kind: MultiClusterIngress
metadata:
  name: global-ingress
  namespace: production
spec:
  template:
    spec:
      backend:
        serviceName: web-service
        servicePort: 80
      rules:
      - host: app.example.com
        http:
          paths:
          - path: /
            backend:
              serviceName: web-service
              servicePort: 80
---
apiVersion: networking.gke.io/v1
kind: MultiClusterService
metadata:
  name: web-service
  namespace: production
spec:
  template:
    spec:
      selector:
        app: web
      ports:
      - name: http
        protocol: TCP
        port: 80
        targetPort: 8080
  
  # クラスタごとの設定
  clusters:
  - link: "tokyo-cluster"
  - link: "singapore-cluster"
  - link: "sydney-cluster"
```

### 4.3 トラフィック分散戦略

```yaml
# traffic-split-strategy.yaml
apiVersion: scheduling.kubefed.io/v1alpha1
kind: ReplicaSchedulingPreference
metadata:
  name: web-app-traffic
  namespace: production
spec:
  targetKind: FederatedDeployment
  totalReplicas: 30
  
  # 地理的分散 + 負荷分散
  clusters:
    # アジア太平洋: 50%
    tokyo-cluster:
      weight: 15
      minReplicas: 10
    
    # ヨーロッパ: 30%
    ireland-cluster:
      weight: 9
      minReplicas: 6
    
    # 北米: 20%
    virginia-cluster:
      weight: 6
      minReplicas: 4
  
  # 自動リバランシング
  rebalance: true
  
  # ヘルスチェックベースのフェイルオーバー
  # クラスタが不健全な場合、他のクラスタにトラフィックを移動
```

## 5. データレプリケーション戦略

### 5.1 非同期レプリケーション（推奨）

```
非同期レプリケーションの仕組み:

┌─────────────────────────────────────────────────────────┐
│ Primary (東京)                                          │
│ ┌──────────┐                                           │
│ │PostgreSQL│                                           │
│ │  Primary │                                           │
│ └────┬─────┘                                           │
│      │ WAL Shipping (非同期)                           │
│      ├───────────────────────────────┐                 │
│      │                               │                 │
│      ↓                               ↓                 │
│ ┌──────────┐                    ┌──────────┐          │
│ │PostgreSQL│                    │PostgreSQL│          │
│ │ Standby  │                    │ Standby  │          │
│ │(アイルランド)│                    │(バージニア)│          │
│ └──────────┘                    └──────────┘          │
│                                                         │
│ RPO (Recovery Point Objective): 数秒〜数分              │
│ RTO (Recovery Time Objective): 数分〜数十分            │
└─────────────────────────────────────────────────────────┘
```

**PostgreSQL Streaming Replicationの設定**:

```yaml
# postgres-primary-statefulset.yaml (東京)
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: postgres-primary
  namespace: database
spec:
  serviceName: postgres-primary
  replicas: 1
  selector:
    matchLabels:
      app: postgres
      role: primary
  template:
    metadata:
      labels:
        app: postgres
        role: primary
    spec:
      containers:
      - name: postgres
        image: postgres:15
        ports:
        - containerPort: 5432
          name: postgres
        env:
        - name: POSTGRES_PASSWORD
          valueFrom:
            secretKeyRef:
              name: postgres-credentials
              key: password
        - name: POSTGRES_REPLICATION_PASSWORD
          valueFrom:
            secretKeyRef:
              name: postgres-credentials
              key: replication-password
        volumeMounts:
        - name: data
          mountPath: /var/lib/postgresql/data
        - name: config
          mountPath: /etc/postgresql
      
      volumes:
      - name: config
        configMap:
          name: postgres-primary-config
  
  volumeClaimTemplates:
  - metadata:
      name: data
    spec:
      accessModes: ["ReadWriteOnce"]
      storageClassName: gp3
      resources:
        requests:
          storage: 500Gi
---
# postgres-primary-config
apiVersion: v1
kind: ConfigMap
metadata:
  name: postgres-primary-config
  namespace: database
data:
  postgresql.conf: |
    # Replication設定
    wal_level = replica
    max_wal_senders = 10
    max_replication_slots = 10
    wal_keep_size = 1GB
    
    # 非同期レプリケーション
    synchronous_commit = off
    synchronous_standby_names = ''
  
  pg_hba.conf: |
    # Replicationユーザーの接続許可
    host replication replicator 0.0.0.0/0 md5
```

```yaml
# postgres-standby-statefulset.yaml (アイルランド、バージニア)
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: postgres-standby
  namespace: database
spec:
  serviceName: postgres-standby
  replicas: 1
  selector:
    matchLabels:
      app: postgres
      role: standby
  template:
    metadata:
      labels:
        app: postgres
        role: standby
    spec:
      containers:
      - name: postgres
        image: postgres:15
        ports:
        - containerPort: 5432
          name: postgres
        env:
        - name: PGDATA
          value: /var/lib/postgresql/data/pgdata
        - name: POSTGRES_PASSWORD
          valueFrom:
            secretKeyRef:
              name: postgres-credentials
              key: password
        volumeMounts:
        - name: data
          mountPath: /var/lib/postgresql/data
        - name: config
          mountPath: /docker-entrypoint-initdb.d
      
      volumes:
      - name: config
        configMap:
          name: postgres-standby-config
  
  volumeClaimTemplates:
  - metadata:
      name: data
    spec:
      accessModes: ["ReadWriteOnce"]
      storageClassName: gp3
      resources:
        requests:
          storage: 500Gi
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: postgres-standby-config
  namespace: database
data:
  setup-replication.sh: |
    #!/bin/bash
    # Primary接続情報
    PRIMARY_HOST="postgres-primary.database.svc.cluster-tokyo.local"
    
    # ベースバックアップ取得
    pg_basebackup -h $PRIMARY_HOST -U replicator -D /var/lib/postgresql/data/pgdata -P -R -X stream
    
    # standby.signal作成（PostgreSQL 12+）
    touch /var/lib/postgresql/data/pgdata/standby.signal
```

### 5.2 アプリケーションレベルレプリケーション

```yaml
# app-with-multi-region-cache.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app-with-cache
  namespace: production
spec:
  replicas: 3
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
        image: myapp:1.0.0
        env:
        # プライマリDB（読み書き）
        - name: DATABASE_PRIMARY_URL
          value: "postgres://postgres-primary.database.svc.cluster.local:5432/mydb"
        
        # ローカルスタンバイDB（読み取り専用）
        - name: DATABASE_REPLICA_URL
          value: "postgres://postgres-standby.database.svc.cluster.local:5432/mydb"
        
        # Redis for Caching
        - name: REDIS_URL
          value: "redis://redis-cluster.cache.svc.cluster.local:6379"
        
        # 書き込みはプライマリ、読み取りはローカルレプリカ
        - name: READ_WRITE_SPLITTING
          value: "true"
```

### 5.3 オブジェクトストレージのクロスリージョンレプリケーション

```bash
# AWS S3 Cross-Region Replication

# レプリケーションルールの作成 (AWS CLI)
aws s3api put-bucket-replication \
  --bucket my-app-storage-tokyo \
  --replication-configuration '{
    "Role": "arn:aws:iam::123456789012:role/S3ReplicationRole",
    "Rules": [
      {
        "Status": "Enabled",
        "Priority": 1,
        "Filter": {},
        "Destination": {
          "Bucket": "arn:aws:s3:::my-app-storage-ireland",
          "ReplicationTime": {
            "Status": "Enabled",
            "Time": {
              "Minutes": 15
            }
          },
          "Metrics": {
            "Status": "Enabled",
            "EventThreshold": {
              "Minutes": 15
            }
          }
        },
        "DeleteMarkerReplication": {
          "Status": "Enabled"
        }
      }
    ]
  }'

# バージニアへのレプリケーションも同様に設定
```

## 6. アクティブ-アクティブ vs アクティブ-スタンバイ

### 6.1 アクティブ-アクティブ構成

```
アクティブ-アクティブ:

全リージョンが同時に稼働し、トラフィックを処理

┌─────────────────────────────────────────────────────────┐
│                     Global Load Balancer                │
│                  (Geolocation/Latency-based)            │
│         ┌────────────────┬────────────────┐             │
│         ↓                ↓                ↓             │
│    ┌─────────┐      ┌─────────┐      ┌─────────┐       │
│    │ 東京    │      │アイルランド│      │バージニア│       │
│    │ Active  │      │ Active  │      │ Active  │       │
│    │ 100%    │      │ 100%    │      │ 100%    │       │
│    └────┬────┘      └────┬────┘      └────┬────┘       │
│         │                │                │             │
│         ↓                ↓                ↓             │
│    アジアユーザー      欧州ユーザー      米国ユーザー        │
└─────────────────────────────────────────────────────────┘

メリット:
✅ 全リージョンでリソース活用
✅ 地理的に最適なレイテンシ
✅ リージョン障害時の即座のフェイルオーバー

デメリット:
❌ データ整合性の複雑性
❌ クロスリージョントラフィックコスト
❌ 複雑な運用
```

```yaml
# active-active-deployment.yaml
apiVersion: types.kubefed.io/v1beta1
kind: FederatedDeployment
metadata:
  name: active-active-app
  namespace: production
spec:
  template:
    metadata:
      labels:
        app: webapp
        mode: active-active
    spec:
      replicas: 5
      selector:
        matchLabels:
          app: webapp
      template:
        metadata:
          labels:
            app: webapp
        spec:
          containers:
          - name: app
            image: webapp:1.0.0
            env:
            # 全リージョンで書き込み可能
            - name: DATABASE_MODE
              value: "read-write"
            # コンフリクト解決戦略
            - name: CONFLICT_RESOLUTION
              value: "last-write-wins"
  
  placement:
    clusters:
    - name: tokyo-cluster
    - name: ireland-cluster
    - name: virginia-cluster
  
  # 均等分散
  overrides: []
```

### 6.2 アクティブ-スタンバイ構成

```
アクティブ-スタンバイ:

プライマリリージョンが主に稼働、障害時にスタンバイへ

┌─────────────────────────────────────────────────────────┐
│                     Global Load Balancer                │
│                      (Health Check)                     │
│                            │                            │
│          ┌─────────────────┴──────────────┐             │
│          ↓ (Primary)                      ↓ (Standby)  │
│    ┌─────────┐                       ┌─────────┐       │
│    │ 東京    │  ──────同期────────→  │アイルランド│       │
│    │ Active  │                       │ Standby │       │
│    │ 100%    │                       │  0%     │       │
│    └─────────┘                       └─────────┘       │
│         │                                               │
│         ↓                                               │
│    全ユーザー                                            │
│                                                         │
│ 障害時:                                                 │
│    アイルランドがActiveに昇格 → 全トラフィック受信         │
└─────────────────────────────────────────────────────────┘

メリット:
✅ シンプルなデータ整合性
✅ 低いクロスリージョントラフィックコスト
✅ 運用が容易

デメリット:
❌ スタンバイリソースが未使用
❌ フェイルオーバー時間が必要
❌ 地理的レイテンシ最適化できない
```

```yaml
# active-standby-deployment.yaml
apiVersion: types.kubefed.io/v1beta1
kind: FederatedDeployment
metadata:
  name: active-standby-app
  namespace: production
spec:
  template:
    metadata:
      labels:
        app: webapp
        mode: active-standby
    spec:
      replicas: 10
      selector:
        matchLabels:
          app: webapp
      template:
        metadata:
          labels:
            app: webapp
        spec:
          containers:
          - name: app
            image: webapp:1.0.0
  
  placement:
    clusters:
    - name: tokyo-cluster  # Primary
    - name: ireland-cluster  # Standby
  
  overrides:
  # Primaryクラスタ: 10 replicas
  - clusterName: tokyo-cluster
    clusterOverrides:
    - path: "/spec/replicas"
      value: 10
    - path: "/spec/template/spec/containers/0/env"
      value:
      - name: DATABASE_MODE
        value: "read-write"
      - name: ROLE
        value: "primary"
  
  # Standbyクラスタ: 2 replicas (最小限)
  - clusterName: ireland-cluster
    clusterOverrides:
    - path: "/spec/replicas"
      value: 2
    - path: "/spec/template/spec/containers/0/env"
      value:
      - name: DATABASE_MODE
        value: "read-only"
      - name: ROLE
        value: "standby"
```

### 6.3 フェイルオーバー自動化

```yaml
# failover-automation.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: failover-script
  namespace: kube-federation-system
data:
  failover.sh: |
    #!/bin/bash
    # プライマリクラスタのヘルスチェック
    
    PRIMARY_CLUSTER="tokyo-cluster"
    STANDBY_CLUSTER="ireland-cluster"
    
    # プライマリクラスタの健全性チェック
    if ! kubectl --context $PRIMARY_CLUSTER cluster-info > /dev/null 2>&1; then
      echo "Primary cluster is down. Initiating failover..."
      
      # スタンバイをアクティブに昇格
      kubectl patch federateddeployment active-standby-app \
        -n production \
        --type='json' \
        -p='[
          {
            "op": "replace",
            "path": "/spec/overrides/1/clusterOverrides/0/value",
            "value": 10
          },
          {
            "op": "replace",
            "path": "/spec/overrides/1/clusterOverrides/1/value/1/value",
            "value": "primary"
          }
        ]'
      
      # DNSをスタンバイに切り替え
      aws route53 change-resource-record-sets \
        --hosted-zone-id Z1234567890ABC \
        --change-batch '{
          "Changes": [{
            "Action": "UPSERT",
            "ResourceRecordSet": {
              "Name": "app.example.com",
              "Type": "CNAME",
              "TTL": 60,
              "ResourceRecords": [{
                "Value": "ireland-lb.example.com"
              }]
            }
          }]
        }'
      
      echo "Failover completed."
    fi
---
# CronJobで定期実行
apiVersion: batch/v1
kind: CronJob
metadata:
  name: failover-checker
  namespace: kube-federation-system
spec:
  schedule: "*/5 * * * *"  # 5分ごと
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: failover
            image: amazon/aws-cli
            command:
            - /bin/bash
            - /scripts/failover.sh
            volumeMounts:
            - name: script
              mountPath: /scripts
          volumes:
          - name: script
            configMap:
              name: failover-script
              defaultMode: 0755
          restartPolicy: OnFailure
```

## まとめ

### 学んだこと

1. **マルチリージョン構成の基礎**
   - リージョン障害対策とグローバル展開
   - マルチAZとの違い
   - レイテンシとコストのトレードオフ

2. **KubeFed（Kubernetes Federation）**
   - FederatedDeploymentによる一元管理
   - ReplicaSchedulingPreferenceでの自動分散
   - Member Clusterの登録と管理

3. **Global Load Balancing**
   - DNS-based GLB（Route 53）
   - Multi-Cluster Ingress（GKE）
   - 地理的トラフィック分散

4. **データレプリケーション**
   - 非同期レプリケーション（PostgreSQL）
   - アプリケーションレベルレプリケーション
   - S3クロスリージョンレプリケーション

5. **アクティブ-アクティブ vs スタンバイ**
   - それぞれのメリット・デメリット
   - ユースケースに応じた選択
   - フェイルオーバー自動化

### ベストプラクティス

- 最低2リージョン、推奨3リージョン以上
- KubeFedで一元管理
- DNS-based GLBで地理的分散
- 非同期レプリケーションでRPO最小化
- 定期的なフェイルオーバー訓練
- モニタリングとアラート（クロスリージョン）
- コスト最適化（データ転送料金に注意）

### 次回予告

次回は「カオスエンジニアリング」として、LitmusChaosを使った障害注入テスト、SLO/SLIベースの評価、本番環境での実践方法を解説します。

## 参考リンク

- {{< linkcard "https://github.com/kubernetes-sigs/kubefed" >}}
- {{< linkcard "https://kubernetes.io/docs/concepts/cluster-administration/federation/" >}}
- {{< linkcard "https://aws.amazon.com/route53/" >}}
- {{< linkcard "https://cloud.google.com/kubernetes-engine/docs/how-to/multi-cluster-ingress" >}}
