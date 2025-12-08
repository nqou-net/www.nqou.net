---
title: "Kubernetesを完全に理解した（第8回）- StatefulSetで作るステートフルアプリ"
draft: true
tags:
- kubernetes
- statefulset
- database
- stateful-apps
- replication
description: "順序性と識別性が重要なステートフルアプリケーションの構築方法。データベースのマスター・レプリカ構成を実際に組んでみます。"
---

## 導入 - 第7回の振り返りと第8回で学ぶこと

前回の記事では、**PersistentVolume（永続ボリューム）**を使ってデータを永続化する方法を学びました。

**第7回のおさらい:**

- コンテナの揮発性とデータ永続化が必要な理由
- PersistentVolume（PV）とPersistentVolumeClaim（PVC）の関係性
- StorageClassによる動的プロビジョニング
- PostgreSQLを使った実践的なデータ永続化の例
- ステートフルアプリケーション運用のベストプラクティス

これで、Podが再起動してもデータを失わない仕組みを構築できるようになりました。しかし、実際のデータベースやクラスタ構成のアプリケーションでは、さらに複雑な要求があります。

**データベースのレプリケーションをどう構成すべきか？**

例えば、PostgreSQLのマスター・レプリカ構成を考えてみましょう：

```bash
# 通常のDeploymentで3つのPostgreSQL Podを起動
kubectl create deployment postgres --image=postgres:15-alpine --replicas=3

# 各Podの名前を確認
kubectl get pods
# NAME                        READY   STATUS    RESTARTS   AGE
# postgres-7d8f9c5b6d-abc12   1/1     Running   0          10s
# postgres-7d8f9c5b6d-def34   1/1     Running   0          10s
# postgres-7d8f9c5b6d-ghi56   1/1     Running   0          10s
```

この構成では、いくつかの重大な問題があります：

1. **ランダムな名前**: Podの名前がランダムなハッシュ付き（abc12、def34など）で、どれがマスターかわからない
2. **順序保証なし**: すべてのPodが同時に起動し、初期化の順序を制御できない
3. **不安定なネットワークID**: Podが再起動すると異なる名前とIPアドレスが割り当てられる
4. **ストレージの関連付けが困難**: どのPodにどのPersistentVolumeを紐付けるか管理できない

これらの問題は、**マスター・レプリカ構成**や**クォーラムベースのクラスタ**（例：etcd、MongoDB、Zookeeper）にとって致命的です。

**StatefulSetの登場**

第8回となる本記事では、これらの問題を解決する**StatefulSet**について学習します。

**この記事で学ぶこと:**

- DeploymentとStatefulSetの本質的な違い
- StatefulSetが提供する3つの保証（順序、識別性、永続ストレージ）
- Headless Serviceとの組み合わせによる直接アクセス
- PostgreSQLマスター・レプリカクラスタの実践的な構築
- StatefulSetのスケーリングと更新戦略
- よくある問題とトラブルシューティング

それでは、ステートフルなアプリケーションを適切に運用する方法を体験していきましょう！

## ステートフルアプリケーションの特性 - DeploymentとStatefulSetの違い

### DeploymentとStatefulSetの比較

まず、これまで使ってきた**Deployment**と、今回学ぶ**StatefulSet**の違いを明確にしましょう。

#### Deployment（ステートレスアプリケーション向け）

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app
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
      containers:
      - name: nginx
        image: nginx:1.25-alpine
        ports:
        - containerPort: 80
```

**Deploymentの特性:**

- **交換可能性（Fungibility）**: すべてのPodは同一で、どれが消えても代替可能
- **ランダムな名前**: `web-app-7d8f9c5b6d-abc12`のようなハッシュベースの名前
- **並列起動**: すべてのPodが同時に起動・終了
- **ランダムなスケールダウン**: どのPodが削除されるかは不定
- **一時的なストレージ**: 通常は永続化しない、またはすべてのPodが同じデータを共有

**適しているアプリケーション:**

- Webサーバー（Nginx、Apache）
- APIサーバー（REST APIなど）
- ワーカープロセス（ステートレスなジョブ処理）
- フロントエンドアプリケーション

#### StatefulSet（ステートフルアプリケーション向け）

```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: postgres
spec:
  serviceName: postgres-headless
  replicas: 3
  selector:
    matchLabels:
      app: postgres
  template:
    metadata:
      labels:
        app: postgres
    spec:
      containers:
      - name: postgres
        image: postgres:15-alpine
        ports:
        - containerPort: 5432
  volumeClaimTemplates:
  - metadata:
      name: data
    spec:
      accessModes: ["ReadWriteOnce"]
      resources:
        requests:
          storage: 10Gi
```

**StatefulSetの特性:**

- **一意な識別子（Unique Identity）**: 各Podが安定した名前を持つ（`postgres-0`, `postgres-1`, `postgres-2`）
- **順序保証（Ordered Deployment）**: Pod-0 → Pod-1 → Pod-2の順に起動・終了
- **順序あるスケールダウン**: 常に最後のPod（Pod-2 → Pod-1 → Pod-0）から削除
- **安定したネットワークID**: 再起動してもホスト名とDNS名が変わらない
- **専用の永続ストレージ**: 各Podが個別のPersistentVolumeを持つ

**適しているアプリケーション:**

- データベース（PostgreSQL、MySQL、MongoDB）
- 分散ストレージ（Cassandra、Ceph）
- クォーラムベースのシステム（etcd、Zookeeper、Consul）
- メッセージキュー（Kafka、RabbitMQ）

### なぜ順序性と識別性が重要なのか

#### ケース1: PostgreSQLマスター・レプリカ構成

PostgreSQLのストリーミングレプリケーションでは：

1. **マスター（Pod-0）** を最初に起動してデータベースを初期化
2. **レプリカ（Pod-1、Pod-2）** がマスターからベースバックアップを取得
3. レプリカは`postgres-0.postgres-headless:5432`という**安定したDNS名**でマスターに接続

```bash
# レプリカ側の設定（postgresql.conf）
primary_conninfo = 'host=postgres-0.postgres-headless port=5432 user=replicator'
```

もしマスターのDNS名が変わってしまったら、レプリカは接続できなくなります。

#### ケース2: etcdクラスタ

etcdは分散合意アルゴリズム（Raft）を使用するため、各メンバーは他のメンバーを正確に知る必要があります：

```bash
# etcdの初期クラスタ設定
--initial-cluster etcd-0=http://etcd-0.etcd:2380,etcd-1=http://etcd-1.etcd:2380,etcd-2=http://etcd-2.etcd:2380
```

安定した名前がないと、クラスタのメンバーシップ管理が不可能になります。

#### ケース3: Kafkaブローカー

Kafkaでは、各ブローカーに一意のBroker IDが必要です：

```bash
# broker.idの設定
broker.id=0  # kafka-0の場合
broker.id=1  # kafka-1の場合
broker.id=2  # kafka-2の場合
```

Pod名から一貫したIDを生成できることが、Kafka運用の前提条件です。

### StatefulSetが解決する3つの課題

| 課題 | Deploymentでの問題 | StatefulSetの解決策 |
|------|-------------------|---------------------|
| **識別性** | ランダムな名前で区別不可 | 安定した順序付き名前（`pod-0`, `pod-1`） |
| **順序制御** | 並列起動・削除 | 順序を保証した起動・終了 |
| **ストレージ関連付け** | PVCとPodの紐付けが困難 | 各Podが専用のPVCを自動作成・保持 |

これらの保証により、StatefulSetはデータベースや分散システムのような複雑なステートフルアプリケーションを実現できます。

## StatefulSetの仕組み - 安定したネットワークID、順序保証、永続ストレージ

StatefulSetは、3つの重要なメカニズムを組み合わせてステートフルアプリケーションを実現します。

### 1. 安定したネットワークID（Stable Network Identity）

#### Pod命名規則

StatefulSetのPodは、以下の命名規則に従います：

```
<statefulset-name>-<ordinal-index>
```

例：

```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: postgres
spec:
  replicas: 3
  # ...
```

このStatefulSetから作られるPodの名前：

```
postgres-0
postgres-1
postgres-2
```

**重要なポイント:**

- インデックスは**0から開始**
- Podが削除されて再作成されても、**同じ名前**が使われる
- スケールダウンして再びスケールアップしても、同じ名前が復活

#### 安定したDNS名

各Podは、以下の形式のDNS名を持ちます：

```
<pod-name>.<headless-service-name>.<namespace>.svc.cluster.local
```

例えば、`default`ネームスペースの`postgres` StatefulSetで`postgres-headless`というHeadless Serviceを使う場合：

```
postgres-0.postgres-headless.default.svc.cluster.local
postgres-1.postgres-headless.default.svc.cluster.local
postgres-2.postgres-headless.default.svc.cluster.local
```

これらのDNS名は、Podが再起動されても**変わりません**。

#### 実際に確認してみる

```bash
# StatefulSetを作成
kubectl apply -f postgres-statefulset.yaml

# Pod名を確認
kubectl get pods -l app=postgres
# NAME         READY   STATUS    RESTARTS   AGE
# postgres-0   1/1     Running   0          30s
# postgres-1   1/1     Running   0          25s
# postgres-2   1/1     Running   0          20s

# DNS名の解決を確認
kubectl run -it --rm debug --image=busybox --restart=Never -- nslookup postgres-0.postgres-headless
# Server:    10.96.0.10
# Address 1: 10.96.0.10 kube-dns.kube-system.svc.cluster.local
# 
# Name:      postgres-0.postgres-headless
# Address 1: 10.244.1.5 postgres-0.postgres-headless.default.svc.cluster.local

# postgres-0を削除
kubectl delete pod postgres-0

# 再作成されたPodを確認
kubectl get pods -l app=postgres
# NAME         READY   STATUS    RESTARTS   AGE
# postgres-0   1/1     Running   0          10s  # 同じ名前で復活！
# postgres-1   1/1     Running   0          3m
# postgres-2   1/1     Running   0          2m55s

# DNS名は変わらずに解決される
kubectl run -it --rm debug --image=busybox --restart=Never -- nslookup postgres-0.postgres-headless
# 同じDNS名で新しいIPアドレスを返す
```

### 2. 順序保証（Ordered Deployment and Scaling）

StatefulSetは、Podの起動・終了・スケーリングを**厳密な順序**で実行します。

#### 起動時の動作

```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: postgres
spec:
  replicas: 3
  podManagementPolicy: OrderedReady  # デフォルト
  # ...
```

**起動シーケンス:**

1. **postgres-0** を作成し、Readyになるまで待機
2. postgres-0がReady → **postgres-1** を作成し、Readyになるまで待機
3. postgres-1がReady → **postgres-2** を作成

```bash
# StatefulSetを作成して、起動を観察
kubectl apply -f postgres-statefulset.yaml

# 別のターミナルでwatchモードで監視
kubectl get pods -l app=postgres --watch
# NAME         READY   STATUS              RESTARTS   AGE
# postgres-0   0/1     ContainerCreating   0          0s
# postgres-0   1/1     Running             0          5s   # ← Ready!
# postgres-1   0/1     Pending             0          0s   # ← Pod-1が作成開始
# postgres-1   0/1     ContainerCreating   0          0s
# postgres-1   1/1     Running             0          5s   # ← Ready!
# postgres-2   0/1     Pending             0          0s   # ← Pod-2が作成開始
# postgres-2   0/1     ContainerCreating   0          0s
# postgres-2   1/1     Running             0          5s
```

#### スケールダウン時の動作

スケールダウンは、**逆順**で実行されます：

```bash
# 3→1にスケールダウン
kubectl scale statefulset postgres --replicas=1

# 削除される順序
kubectl get pods -l app=postgres --watch
# NAME         READY   STATUS        RESTARTS   AGE
# postgres-2   1/1     Terminating   0          5m   # ← 最初にPod-2が削除
# postgres-2   0/1     Terminating   0          5m
# (postgres-2が完全に削除されるまで待機)
# postgres-1   1/1     Terminating   0          5m5s # ← 次にPod-1が削除
# postgres-1   0/1     Terminating   0          5m5s
```

**なぜ逆順なのか？**

データベースのマスター・レプリカ構成では：

- Pod-0 = マスター
- Pod-1, Pod-2 = レプリカ

レプリカから先に削除することで、マスターを最後まで保持できます。

#### Parallel Podマネジメント（並列起動）

順序保証が不要な場合は、`podManagementPolicy: Parallel`を指定できます：

```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: web
spec:
  replicas: 3
  podManagementPolicy: Parallel  # すべてのPodを同時に起動
  # ...
```

これは、Webサーバーのように順序が重要でないステートフルアプリケーション（安定した名前は必要だが起動順序は不要）に有用です。

### 3. 永続ストレージ（Persistent Storage per Pod）

StatefulSetの最も強力な機能の1つが、**volumeClaimTemplates**です。

#### volumeClaimTemplatesの仕組み

```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: postgres
spec:
  replicas: 3
  volumeClaimTemplates:
  - metadata:
      name: data
    spec:
      accessModes: ["ReadWriteOnce"]
      storageClassName: standard
      resources:
        requests:
          storage: 10Gi
```

**動作の流れ:**

1. **postgres-0**が作成される
   - → PVC `data-postgres-0`が自動作成される
   - → StorageClassによってPV `pv-xxx`がプロビジョニングされる
   - → `data-postgres-0`が`pv-xxx`にバインドされる
   - → Pod内で`/var/lib/postgresql/data`にマウント

2. **postgres-1**が作成される
   - → PVC `data-postgres-1`が自動作成される（別のPV）
   - → 同様にバインドとマウント

3. **postgres-2**が作成される
   - → PVC `data-postgres-2`が自動作成される（別のPV）
   - → 同様にバインドとマウント

```bash
# PVCの確認
kubectl get pvc
# NAME              STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS
# data-postgres-0   Bound    pvc-a1b2c3d4-e5f6-7890-abcd-ef1234567890   10Gi       RWO            standard
# data-postgres-1   Bound    pvc-b2c3d4e5-f6a7-8901-bcde-f12345678901   10Gi       RWO            standard
# data-postgres-2   Bound    pvc-c3d4e5f6-a7b8-9012-cdef-123456789012   10Gi       RWO            standard
```

#### Podとストレージの永続的な関連付け

**重要な特性:**

- Podが削除されても、PVCは**削除されない**
- 同じ名前のPodが再作成されると、同じPVCに**自動的に再接続**される
- データは完全に保持される

```bash
# データを書き込む
kubectl exec postgres-1 -- psql -U postgres -c "CREATE TABLE test (id INT, data TEXT);"
kubectl exec postgres-1 -- psql -U postgres -c "INSERT INTO test VALUES (1, 'important data');"

# Podを削除
kubectl delete pod postgres-1

# 新しいpostgres-1が起動するのを待つ
kubectl wait --for=condition=ready pod/postgres-1 --timeout=60s

# データが残っている
kubectl exec postgres-1 -- psql -U postgres -c "SELECT * FROM test;"
#  id |      data       
# ----+-----------------
#   1 | important data
# (1 row)
```

#### StatefulSetを削除してもPVCは残る

**デフォルトの動作:**

```bash
# StatefulSetを削除
kubectl delete statefulset postgres

# Podは削除される
kubectl get pods
# No resources found in default namespace.

# しかしPVCは残っている！
kubectl get pvc
# NAME              STATUS   VOLUME                                     CAPACITY
# data-postgres-0   Bound    pvc-a1b2c3d4-e5f6-7890-abcd-ef1234567890   10Gi
# data-postgres-1   Bound    pvc-b2c3d4e5-f6a7-8901-bcde-f12345678901   10Gi
# data-postgres-2   Bound    pvc-c3d4e5f6-a7b8-9012-cdef-123456789012   10Gi

# StatefulSetを再作成
kubectl apply -f postgres-statefulset.yaml

# Podは既存のPVCに再接続され、データは完全に保持される
```

これは**データの偶発的な削除を防ぐ**ための安全機構です。

## Headless Serviceとの組み合わせ - 各Podへの直接アクセス

StatefulSetを最大限に活用するには、**Headless Service**と組み合わせる必要があります。

### Headless Serviceとは

通常のServiceは、複数のPodへのトラフィックを**ロードバランス**します。一方、Headless Serviceは、各Pod への**直接アクセス**を可能にします。

#### 通常のService vs Headless Service

**通常のService（ClusterIP）:**

```yaml
apiVersion: v1
kind: Service
metadata:
  name: postgres-service
spec:
  type: ClusterIP
  selector:
    app: postgres
  ports:
  - port: 5432
    targetPort: 5432
```

```bash
# DNS解決 → 単一のClusterIP
nslookup postgres-service
# Name:      postgres-service
# Address 1: 10.96.100.50  # ← 単一のIPアドレス（VIP）

# トラフィックはランダムにポッド間で分散される
# マスター・レプリカ構成には不適切！
```

**Headless Service（`clusterIP: None`）:**

```yaml
apiVersion: v1
kind: Service
metadata:
  name: postgres-headless
spec:
  clusterIP: None  # ← Headlessの設定
  selector:
    app: postgres
  ports:
  - port: 5432
    targetPort: 5432
```

```bash
# DNS解決 → すべてのPodのIPアドレス
nslookup postgres-headless
# Name:      postgres-headless
# Address 1: 10.244.1.5 postgres-0.postgres-headless.default.svc.cluster.local
# Address 2: 10.244.2.6 postgres-1.postgres-headless.default.svc.cluster.local
# Address 3: 10.244.3.7 postgres-2.postgres-headless.default.svc.cluster.local

# 各Podへの直接DNS名
# postgres-0.postgres-headless → 10.244.1.5
# postgres-1.postgres-headless → 10.244.2.6
# postgres-2.postgres-headless → 10.244.3.7
```

### StatefulSetでHeadless Serviceを指定

```yaml
apiVersion: v1
kind: Service
metadata:
  name: postgres-headless
spec:
  clusterIP: None
  selector:
    app: postgres
  ports:
  - port: 5432
    targetPort: 5432
    name: postgres
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: postgres
spec:
  serviceName: postgres-headless  # ← Headless Serviceを参照
  replicas: 3
  selector:
    matchLabels:
      app: postgres
  template:
    metadata:
      labels:
        app: postgres
    spec:
      containers:
      - name: postgres
        image: postgres:15-alpine
        ports:
        - containerPort: 5432
          name: postgres
```

### なぜHeadless Serviceが必要なのか

#### ケース1: PostgreSQLレプリケーション

レプリカは、**特定のマスター**（postgres-0）に接続する必要があります：

```bash
# レプリカの設定
primary_conninfo = 'host=postgres-0.postgres-headless port=5432 user=replicator'
```

通常のServiceでは、接続先がランダムに選ばれるため、レプリケーションが成立しません。

#### ケース2: etcdクラスタのピア検出

各etcdメンバーは、他のすべてのメンバーを直接知る必要があります：

```bash
--initial-cluster etcd-0=http://etcd-0.etcd-headless:2380,etcd-1=http://etcd-1.etcd-headless:2380,etcd-2=http://etcd-2.etcd-headless:2380
```

### 読み取り専用レプリカへのロードバランス

マスターへは直接アクセスし、レプリカへの読み取りクエリはロードバランスしたい場合：

**マスター用のService（Headless）:**

```yaml
apiVersion: v1
kind: Service
metadata:
  name: postgres-headless
spec:
  clusterIP: None
  selector:
    app: postgres
  ports:
  - port: 5432
```

**読み取り専用レプリカ用のService（通常のClusterIP）:**

```yaml
apiVersion: v1
kind: Service
metadata:
  name: postgres-read
spec:
  type: ClusterIP
  selector:
    app: postgres
    role: replica  # レプリカのみを対象
  ports:
  - port: 5432
    targetPort: 5432
```

使い分け：

```python
# 書き込みはマスターへ
master_conn = psycopg2.connect(host="postgres-0.postgres-headless", port=5432, ...)
master_conn.cursor().execute("INSERT INTO users (name) VALUES ('Alice')")

# 読み取りはレプリカへ（ロードバランス）
read_conn = psycopg2.connect(host="postgres-read", port=5432, ...)
read_conn.cursor().execute("SELECT * FROM users")
```

## PostgreSQLクラスタの構築 - 実践的なStatefulSet例

それでは、実際にPostgreSQLのマスター・レプリカ構成をStatefulSetで構築してみましょう。

### アーキテクチャ概要

```
+-------------------+       +-----------------------+
|   postgres-0      |       |   postgres-1          |
|   (Master)        | ----> |   (Streaming Replica) |
|                   |       |                       |
|  PVC: data-pg-0   |       |  PVC: data-pg-1       |
+-------------------+       +-----------------------+
         ^                           |
         |                           |
    Write queries            Read-only queries
         |                           |
    +---------+                 +---------+
    | App Pod |                 | App Pod |
    +---------+                 +---------+
```

**構成要素:**

1. **postgres-0**: マスター（読み書き可能）
2. **postgres-1, postgres-2**: ストリーミングレプリカ（読み取り専用）
3. 各Podは専用のPersistentVolumeを持つ
4. レプリカは`postgres-0.postgres-headless`経由でマスターに接続

### ステップ1: ConfigMapで設定を準備

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: postgres-config
data:
  # マスター用設定
  master.conf: |
    listen_addresses = '*'
    wal_level = replica
    max_wal_senders = 3
    wal_keep_size = 64MB
    hot_standby = on
  
  # レプリカ用設定
  replica.conf: |
    hot_standby = on
  
  # pg_hba.conf（アクセス制御）
  pg_hba.conf: |
    local   all             all                                     trust
    host    all             all             127.0.0.1/32            trust
    host    all             all             ::1/128                 trust
    host    replication     replicator      0.0.0.0/0               md5
    host    all             all             0.0.0.0/0               md5
```

```bash
kubectl apply -f postgres-config.yaml
```

### ステップ2: レプリケーション用のSecret

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: postgres-secret
type: Opaque
stringData:
  postgres-password: "masterpassword"
  replication-password: "replicapassword"
```

```bash
kubectl apply -f postgres-secret.yaml
```

### ステップ3: Headless Service

```yaml
apiVersion: v1
kind: Service
metadata:
  name: postgres-headless
spec:
  clusterIP: None
  selector:
    app: postgres
  ports:
  - port: 5432
    targetPort: 5432
    name: postgres
```

```bash
kubectl apply -f postgres-headless-service.yaml
```

### ステップ4: StatefulSetの定義

```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: postgres
spec:
  serviceName: postgres-headless
  replicas: 3
  selector:
    matchLabels:
      app: postgres
  template:
    metadata:
      labels:
        app: postgres
    spec:
      initContainers:
      # 初期化コンテナ: マスターかレプリカかを判定
      - name: init-postgres
        image: postgres:15-alpine
        command:
        - bash
        - "-c"
        - |
          set -ex
          # Podのインデックスを取得
          [[ $HOSTNAME =~ -([0-9]+)$ ]] || exit 1
          ordinal=${BASH_REMATCH[1]}
          
          # Pod-0 = マスター、それ以外 = レプリカ
          if [[ $ordinal -eq 0 ]]; then
            echo "This is the master (postgres-0)"
            cp /config/master.conf /etc/postgresql/postgresql.conf
          else
            echo "This is a replica (postgres-$ordinal)"
            cp /config/replica.conf /etc/postgresql/postgresql.conf
            
            # レプリカの場合、マスターからベースバックアップ
            until pg_isready -h postgres-0.postgres-headless -p 5432; do
              echo "Waiting for master to be ready..."
              sleep 2
            done
            
            # ベースバックアップの取得
            PGPASSWORD=$REPLICATION_PASSWORD pg_basebackup \
              -h postgres-0.postgres-headless \
              -D /var/lib/postgresql/data \
              -U replicator \
              -v -P -W
            
            # standby.signalファイルを作成（レプリカモード）
            touch /var/lib/postgresql/data/standby.signal
            
            # primary_conninfoを設定
            cat >> /var/lib/postgresql/data/postgresql.auto.conf <<EOF
          primary_conninfo = 'host=postgres-0.postgres-headless port=5432 user=replicator password=$REPLICATION_PASSWORD'
          EOF
          fi
        env:
        - name: PGDATA
          value: /var/lib/postgresql/data
        - name: REPLICATION_PASSWORD
          valueFrom:
            secretKeyRef:
              name: postgres-secret
              key: replication-password
        volumeMounts:
        - name: data
          mountPath: /var/lib/postgresql/data
        - name: config
          mountPath: /config
      
      containers:
      - name: postgres
        image: postgres:15-alpine
        ports:
        - containerPort: 5432
          name: postgres
        env:
        - name: POSTGRES_PASSWORD
          valueFrom:
            secretKeyRef:
              name: postgres-secret
              key: postgres-password
        - name: POSTGRES_INITDB_ARGS
          value: "--encoding=UTF8 --locale=C"
        - name: PGDATA
          value: /var/lib/postgresql/data
        volumeMounts:
        - name: data
          mountPath: /var/lib/postgresql/data
        - name: config
          mountPath: /config
        livenessProbe:
          exec:
            command:
            - pg_isready
            - -U
            - postgres
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          exec:
            command:
            - pg_isready
            - -U
            - postgres
          initialDelaySeconds: 5
          periodSeconds: 5
      
      volumes:
      - name: config
        configMap:
          name: postgres-config
  
  volumeClaimTemplates:
  - metadata:
      name: data
    spec:
      accessModes: ["ReadWriteOnce"]
      storageClassName: standard
      resources:
        requests:
          storage: 10Gi
```

```bash
kubectl apply -f postgres-statefulset.yaml
```

### ステップ5: 起動の確認

```bash
# Podの起動を監視
kubectl get pods -l app=postgres --watch
# NAME         READY   STATUS     RESTARTS   AGE
# postgres-0   0/1     Init:0/1   0          5s   # マスターが初期化中
# postgres-0   0/1     Running    0          30s  # マスター起動
# postgres-0   1/1     Running    0          35s  # マスターReady
# postgres-1   0/1     Init:0/1   0          0s   # レプリカ1が初期化開始
# postgres-1   0/1     Running    0          45s  # ベースバックアップ取得中
# postgres-1   1/1     Running    0          60s  # レプリカ1 Ready
# postgres-2   0/1     Init:0/1   0          0s
# postgres-2   0/1     Running    0          45s
# postgres-2   1/1     Running    0          60s

# レプリケーション状態の確認
kubectl exec postgres-0 -- psql -U postgres -c "SELECT client_addr, state, sync_state FROM pg_stat_replication;"
#  client_addr |   state   | sync_state 
# -------------+-----------+------------
#  10.244.2.6  | streaming | async
#  10.244.3.7  | streaming | async
# (2 rows)
```

### ステップ6: 動作確認

```bash
# マスターにデータを書き込む
kubectl exec postgres-0 -- psql -U postgres -c "CREATE TABLE test (id SERIAL PRIMARY KEY, data TEXT);"
kubectl exec postgres-0 -- psql -U postgres -c "INSERT INTO test (data) VALUES ('Hello from master');"

# レプリカでデータを確認（レプリケーションされている）
kubectl exec postgres-1 -- psql -U postgres -c "SELECT * FROM test;"
#  id |       data         
# ----+--------------------
#   1 | Hello from master
# (1 row)

# レプリカは読み取り専用
kubectl exec postgres-1 -- psql -U postgres -c "INSERT INTO test (data) VALUES ('Try from replica');"
# ERROR:  cannot execute INSERT in a read-only transaction
```

### 読み取り専用Service（オプション）

レプリカへの読み取りクエリをロードバランスするService：

```yaml
apiVersion: v1
kind: Service
metadata:
  name: postgres-read
spec:
  type: ClusterIP
  selector:
    app: postgres
  ports:
  - port: 5432
    targetPort: 5432
```

レプリカにはラベルを追加して区別することも可能です（StatefulSetのPodManagementPolicyと組み合わせて使用）。

## スケーリングと更新 - 順序を守った操作

StatefulSetのスケーリングと更新は、順序保証を維持しながら実行されます。

### スケールアップ（レプリカ追加）

```bash
# 3→5にスケールアップ
kubectl scale statefulset postgres --replicas=5

# 起動順序の確認
kubectl get pods -l app=postgres --watch
# postgres-0   1/1     Running   0          10m
# postgres-1   1/1     Running   0          9m
# postgres-2   1/1     Running   0          8m
# postgres-3   0/1     Pending   0          0s   # ← Pod-3が追加される
# postgres-3   0/1     Init:0/1  0          0s
# postgres-3   0/1     Running   0          30s
# postgres-3   1/1     Running   0          45s  # ← Ready後に次へ
# postgres-4   0/1     Pending   0          0s   # ← Pod-4が追加される
# postgres-4   0/1     Init:0/1  0          0s
# postgres-4   0/1     Running   0          30s
# postgres-4   1/1     Running   0          45s

# 新しいPVCが作成される
kubectl get pvc
# NAME              STATUS   VOLUME                                     CAPACITY
# data-postgres-0   Bound    pvc-xxx                                    10Gi
# data-postgres-1   Bound    pvc-yyy                                    10Gi
# data-postgres-2   Bound    pvc-zzz                                    10Gi
# data-postgres-3   Bound    pvc-aaa                                    10Gi  # ← 新規
# data-postgres-4   Bound    pvc-bbb                                    10Gi  # ← 新規
```

### スケールダウン（レプリカ削除）

```bash
# 5→2にスケールダウン
kubectl scale statefulset postgres --replicas=2

# 削除順序の確認（逆順）
kubectl get pods -l app=postgres --watch
# postgres-4   1/1     Terminating   0          5m   # ← 最後のPodから削除
# postgres-4   0/1     Terminating   0          5m
# (postgres-4の完全削除を待つ)
# postgres-3   1/1     Terminating   0          6m
# postgres-3   0/1     Terminating   0          6m
# (postgres-3の完全削除を待つ)
# postgres-2   1/1     Terminating   0          7m
# postgres-2   0/1     Terminating   0          7m

# 残ったPod
kubectl get pods -l app=postgres
# NAME         READY   STATUS    RESTARTS   AGE
# postgres-0   1/1     Running   0          15m
# postgres-1   1/1     Running   0          14m

# PVCは削除されない！
kubectl get pvc
# NAME              STATUS   VOLUME                                     CAPACITY
# data-postgres-0   Bound    pvc-xxx                                    10Gi
# data-postgres-1   Bound    pvc-yyy                                    10Gi
# data-postgres-2   Bound    pvc-zzz                                    10Gi  # ← 残る
# data-postgres-3   Bound    pvc-aaa                                    10Gi  # ← 残る
# data-postgres-4   Bound    pvc-bbb                                    10Gi  # ← 残る
```

**PVCが残る理由:**

再度スケールアップしたときに、同じデータを使って復元できるようにするためです。

```bash
# 再びスケールアップ
kubectl scale statefulset postgres --replicas=5

# postgres-2, postgres-3, postgres-4が既存のPVCに再接続される
kubectl get pods -l app=postgres
# NAME         READY   STATUS    RESTARTS   AGE
# postgres-0   1/1     Running   0          20m
# postgres-1   1/1     Running   0          19m
# postgres-2   1/1     Running   0          30s  # ← data-postgres-2に再接続
# postgres-3   1/1     Running   0          25s  # ← data-postgres-3に再接続
# postgres-4   1/1     Running   0          20s  # ← data-postgres-4に再接続
```

### 更新戦略（Update Strategy）

StatefulSetは、2つの更新戦略をサポートします。

#### 1. RollingUpdate（デフォルト）

```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: postgres
spec:
  updateStrategy:
    type: RollingUpdate
    rollingUpdate:
      partition: 0  # この値以上のインデックスのPodを更新
```

**動作:**

イメージを更新すると、**逆順**（Pod-2 → Pod-1 → Pod-0）で更新されます：

```bash
# イメージを更新
kubectl set image statefulset/postgres postgres=postgres:16-alpine

# 更新の進行
kubectl get pods -l app=postgres --watch
# postgres-2   1/1     Terminating   0          10m   # ← 最後のPodから更新
# postgres-2   0/1     Terminating   0          10m
# postgres-2   0/1     Pending       0          0s
# postgres-2   0/1     Init:0/1      0          0s
# postgres-2   0/1     Running       0          30s
# postgres-2   1/1     Running       0          45s   # ← Ready後に次へ
# postgres-1   1/1     Terminating   0          11m
# postgres-1   0/1     Terminating   0          11m
# postgres-1   0/1     Pending       0          0s
# postgres-1   0/1     Init:0/1      0          0s
# postgres-1   0/1     Running       0          30s
# postgres-1   1/1     Running       0          45s
# postgres-0   1/1     Terminating   0          12m   # ← マスターは最後
# postgres-0   0/1     Terminating   0          12m
# postgres-0   0/1     Pending       0          0s
# postgres-0   0/1     Init:0/1      0          0s
# postgres-0   0/1     Running       0          30s
# postgres-0   1/1     Running       0          45s
```

#### 2. OnDelete

```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: postgres
spec:
  updateStrategy:
    type: OnDelete
```

**動作:**

StatefulSetの定義を更新しても、Podは**自動的には更新されません**。Podを手動で削除したときに、新しい定義で再作成されます。

```bash
# イメージを更新
kubectl set image statefulset/postgres postgres=postgres:16-alpine

# 何も起こらない
kubectl get pods -l app=postgres
# NAME         READY   STATUS    RESTARTS   AGE
# postgres-0   1/1     Running   0          15m  # まだ古いイメージ
# postgres-1   1/1     Running   0          14m
# postgres-2   1/1     Running   0          13m

# 手動でPodを削除
kubectl delete pod postgres-2

# 新しいイメージで再作成される
kubectl get pods -l app=postgres
# NAME         READY   STATUS    RESTARTS   AGE
# postgres-0   1/1     Running   0          16m
# postgres-1   1/1     Running   0          15m
# postgres-2   1/1     Running   0          10s  # ← 新しいイメージ（16-alpine）
```

**OnDeleteの利点:**

完全な制御が可能で、任意の順序でPodを更新できます。データベースのメジャーバージョンアップグレードなど、慎重な操作が必要な場合に有用です。

#### Partitioned RollingUpdate

`partition`パラメータを使うと、一部のPodだけを更新できます（カナリアデプロイメント）：

```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: postgres
spec:
  replicas: 5
  updateStrategy:
    type: RollingUpdate
    rollingUpdate:
      partition: 3  # インデックス3以上（Pod-3, Pod-4）のみ更新
```

```bash
# イメージを更新
kubectl set image statefulset/postgres postgres=postgres:16-alpine

# Pod-3とPod-4だけが更新される
kubectl get pods -l app=postgres -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.containers[0].image}{"\n"}{end}'
# postgres-0    postgres:15-alpine  # ← 更新されない
# postgres-1    postgres:15-alpine  # ← 更新されない
# postgres-2    postgres:15-alpine  # ← 更新されない
# postgres-3    postgres:16-alpine  # ← 更新された
# postgres-4    postgres:16-alpine  # ← 更新された

# 問題なければpartitionを下げて残りを更新
kubectl patch statefulset postgres -p '{"spec":{"updateStrategy":{"rollingUpdate":{"partition":0}}}}'
```

## トラブルシューティング - よくある問題と対処法

StatefulSetの運用で遭遇する典型的な問題と解決策を紹介します。

### 問題1: Podが起動しない（PVCがBound状態にならない）

**症状:**

```bash
kubectl get pods
# NAME         READY   STATUS    RESTARTS   AGE
# postgres-0   0/1     Pending   0          2m

kubectl describe pod postgres-0
# Events:
#   Warning  FailedScheduling  2m    default-scheduler  0/3 nodes are available: 3 pod has unbound immediate PersistentVolumeClaims.
```

**原因:**

StorageClassが動的プロビジョニングをサポートしていない、またはPVが不足しています。

**解決策:**

```bash
# 1. StorageClassの確認
kubectl get storageclass
# NAME                 PROVISIONER            RECLAIMPOLICY
# standard (default)   kubernetes.io/gce-pd   Delete

# 2. StorageClassが存在しない場合、作成または手動でPVを作成
# 手動PVの例
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-postgres-0
spec:
  capacity:
    storage: 10Gi
  accessModes:
  - ReadWriteOnce
  hostPath:
    path: /data/postgres-0
  claimRef:
    namespace: default
    name: data-postgres-0

kubectl apply -f pv-postgres-0.yaml

# 3. PVCの状態を確認
kubectl get pvc
# NAME              STATUS   VOLUME          CAPACITY
# data-postgres-0   Bound    pv-postgres-0   10Gi
```

### 問題2: Pod-0以外が起動しない（レプリカの初期化失敗）

**症状:**

```bash
kubectl get pods
# NAME         READY   STATUS             RESTARTS   AGE
# postgres-0   1/1     Running            0          5m
# postgres-1   0/1     CrashLoopBackOff   3          2m

kubectl logs postgres-1
# Error: cannot execute pg_basebackup: connection to database failed
```

**原因:**

レプリケーションユーザーが作成されていない、またはpg_hba.confの設定が不足しています。

**解決策:**

```bash
# マスター（postgres-0）でレプリケーションユーザーを作成
kubectl exec postgres-0 -- psql -U postgres -c "CREATE ROLE replicator WITH REPLICATION LOGIN PASSWORD 'replicapassword';"

# pg_hba.confにレプリケーション接続を許可する行を追加
# （ConfigMapで設定済みの場合は不要）
kubectl exec postgres-0 -- psql -U postgres -c "SELECT pg_reload_conf();"

# Pod-1を再起動
kubectl delete pod postgres-1
```

### 問題3: スケールダウン後、PVCが残りすぎてコストがかかる

**症状:**

```bash
# スケールダウン後
kubectl get pvc
# NAME              STATUS   VOLUME      CAPACITY
# data-postgres-0   Bound    pvc-xxx     10Gi
# data-postgres-1   Bound    pvc-yyy     10Gi
# data-postgres-2   Bound    pvc-zzz     10Gi  # 使われていない
# data-postgres-3   Bound    pvc-aaa     10Gi  # 使われていない
# data-postgres-4   Bound    pvc-bbb     10Gi  # 使われていない
```

**解決策:**

不要なPVCを手動で削除（データは完全に削除されるので注意）：

```bash
# 削除前にデータのバックアップを確認
kubectl get pvc data-postgres-3 -o yaml > backup-pvc-postgres-3.yaml

# PVCを削除
kubectl delete pvc data-postgres-3 data-postgres-4

# PVCが削除され、reclaimPolicyに従ってPVも削除される（StorageClassがDeleteの場合）
```

**自動削除の設定（Kubernetes 1.23以降）:**

StatefulSetに`persistentVolumeClaimRetentionPolicy`を設定：

```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: postgres
spec:
  persistentVolumeClaimRetentionPolicy:
    whenDeleted: Delete  # StatefulSet削除時にPVCも削除
    whenScaled: Retain   # スケールダウン時はPVCを保持（デフォルト）
```

### 問題4: Podが順序通りに起動しない

**症状:**

```bash
kubectl get pods -l app=postgres --watch
# postgres-0   1/1     Running   0          10s
# postgres-2   0/1     Pending   0          0s   # ← Pod-1をスキップしてPod-2が起動？
```

**原因:**

`podManagementPolicy: Parallel`が設定されている可能性があります。

**解決策:**

StatefulSetの設定を確認：

```bash
kubectl get statefulset postgres -o yaml | grep podManagementPolicy
# podManagementPolicy: Parallel  # ← これが原因

# OrderedReadyに変更
kubectl patch statefulset postgres -p '{"spec":{"podManagementPolicy":"OrderedReady"}}'
```

### 問題5: 更新後にPodが起動しない（イメージの互換性問題）

**症状:**

```bash
# ローリングアップデート中
kubectl get pods
# NAME         READY   STATUS             RESTARTS   AGE
# postgres-0   1/1     Running            0          10m
# postgres-1   1/1     Running            0          9m
# postgres-2   0/1     CrashLoopBackOff   5          3m

kubectl logs postgres-2
# FATAL: database files are incompatible with server
# DETAIL: The data directory was initialized by PostgreSQL version 15...
```

**原因:**

PostgreSQLのメジャーバージョンアップグレード（15→16）は、データディレクトリの互換性がありません。

**解決策:**

ローリングアップデートをロールバック：

```bash
# 以前のイメージに戻す
kubectl rollout undo statefulset/postgres

# 確認
kubectl rollout status statefulset/postgres
# statefulset rolling update complete 3 pods at revision postgres-78d4f9c5b6...

# メジャーバージョンアップグレードはpg_upgradeを使う必要がある
# 別途アップグレード手順を実施
```

### 問題6: Headless Serviceの名前解決ができない

**症状:**

```bash
kubectl run -it --rm debug --image=busybox --restart=Never -- nslookup postgres-0.postgres-headless
# Server:    10.96.0.10
# Address 1: 10.96.0.10 kube-dns.kube-system.svc.cluster.local
# 
# nslookup: can't resolve 'postgres-0.postgres-headless'
```

**原因:**

Headless Serviceが作成されていない、またはStatefulSetの`serviceName`が間違っています。

**解決策:**

```bash
# Headless Serviceの存在確認
kubectl get service postgres-headless
# NAME                TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)
# postgres-headless   ClusterIP   None         <none>        5432/TCP

# StatefulSetのserviceNameを確認
kubectl get statefulset postgres -o jsonpath='{.spec.serviceName}'
# postgres-headless

# 一致しない場合、修正
kubectl patch statefulset postgres -p '{"spec":{"serviceName":"postgres-headless"}}'
```

## まとめと次回予告 - 第9回Namespaceの予告

第8回では、**StatefulSet**を使ってステートフルアプリケーションを構築する方法を学びました。

**この記事で学んだこと:**

1. **DeploymentとStatefulSetの違い**
   - Deploymentはステートレスアプリケーション向け（交換可能、ランダムな名前）
   - StatefulSetはステートフルアプリケーション向け（一意な識別子、順序保証、永続ストレージ）

2. **StatefulSetの3つの保証**
   - 安定したネットワークID（`pod-0`, `pod-1`という固定名）
   - 順序保証（起動・終了・スケーリングが順序通り）
   - 永続ストレージ（各Podが専用のPVCを自動作成・保持）

3. **Headless Serviceとの組み合わせ**
   - `clusterIP: None`で各Podへの直接アクセスを可能に
   - `postgres-0.postgres-headless`のような安定したDNS名

4. **PostgreSQLマスター・レプリカクラスタの構築**
   - Pod-0をマスター、Pod-1以降をレプリカとして構成
   - ストリーミングレプリケーションで自動的にデータ同期

5. **スケーリングと更新戦略**
   - スケールアップは順序通り、スケールダウンは逆順
   - RollingUpdateとOnDeleteの使い分け
   - Partitioned Updateでカナリアデプロイメント

6. **トラブルシューティング**
   - PVCのバインド問題、レプリケーション失敗、互換性問題などの対処法

**StatefulSetが適しているアプリケーション:**

- データベース（PostgreSQL、MySQL、MongoDB、Cassandra）
- 分散ストレージ（Ceph、Minio）
- クォーラムベースのシステム（etcd、Zookeeper、Consul）
- メッセージキュー（Kafka、RabbitMQクラスタ）

**次回予告: 第9回「Namespaceで実現するマルチテナント環境」**

これまでの記事では、主に`default`ネームスペースでリソースを管理してきました。しかし、本番環境では複数のチームやアプリケーションが同じKubernetesクラスタを共有することが一般的です。

**次回学ぶこと:**

- Namespaceによるリソースの論理的分離
- 環境ごとの分離（development、staging、production）
- ResourceQuotaとLimitRangeによるリソース制限
- ネームスペース間のネットワークポリシー
- RBACとの組み合わせによるアクセス制御

それでは、第9回でお会いしましょう！
