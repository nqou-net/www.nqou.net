---
title: "Kubernetesを完全に理解した（第7回）- PersistentVolumeでデータを永続化"
draft: true
tags:
- kubernetes
- storage
- persistent-volume
- pvc
- stateful
description: "Podが再起動してもデータを失わない仕組みを構築。データベースなどステートフルなアプリケーションの運用方法を学びます。"
---

## 導入 - 第6回の振り返りと第7回で学ぶこと

前回の記事では、**ConfigMapとSecret**を使ってアプリケーションの設定を適切に管理する方法を学びました。

**第6回のおさらい:**

- The Twelve-Factor Appにおける設定とコードの分離原則
- ConfigMapによる設定の外部化
- Secretによる機密情報の安全な管理
- 環境変数とVolumeマウントによる設定注入
- ConfigMapの動的更新とセキュリティベストプラクティス

これで、環境ごとに異なる設定や機密情報を安全に管理できるようになりました。しかし、実際のアプリケーション運用では、さらに重要な課題が残っています。

**データをどう永続化すべきか？**

例えば、データベースをKubernetes上で動かす場合を考えてみましょう：

```yaml
# 問題のある例: ストレージを指定していないPostgreSQL Pod
apiVersion: v1
kind: Pod
metadata:
  name: postgres
spec:
  containers:
  - name: postgres
    image: postgres:15-alpine
    env:
    - name: POSTGRES_PASSWORD
      value: "mypassword"
    # ストレージの設定がない！
```

このPodを起動してデータを保存しても、Podが再起動したり、別のノードに移動したりすると：

```bash
# データを保存
kubectl exec postgres -- psql -U postgres -c "CREATE TABLE users (id SERIAL PRIMARY KEY, name TEXT);"
kubectl exec postgres -- psql -U postgres -c "INSERT INTO users (name) VALUES ('Alice'), ('Bob');"

# データが存在することを確認
kubectl exec postgres -- psql -U postgres -c "SELECT * FROM users;"
#  id | name  
# ----+-------
#   1 | Alice
#   2 | Bob

# Podを削除して再作成
kubectl delete pod postgres
kubectl apply -f postgres-pod.yaml

# データが消えている！
kubectl exec postgres -- psql -U postgres -c "SELECT * FROM users;"
# ERROR: relation "users" does not exist
```

**なぜこうなるのか？**

コンテナのファイルシステムは**揮発性（Ephemeral）**です。コンテナが削除されると、その中に書き込まれたデータはすべて失われます。

第7回となる本記事では、この問題を解決する**PersistentVolume（永続ボリューム）**について学習します。

**この記事で学ぶこと:**

- コンテナの揮発性とデータ永続化が必要な理由
- PersistentVolume（PV）、PersistentVolumeClaim（PVC）、StorageClassの関係性
- PersistentVolumeの作成と設定パラメータ
- PersistentVolumeClaimでストレージを要求する方法
- StorageClassによる動的プロビジョニング
- PostgreSQLを使った実践的なデータベース永続化の例
- ステートフルアプリケーション運用のベストプラクティス

それでは、データを失わないKubernetesアプリケーションの構築方法を体験していきましょう！

## コンテナの揮発性 - なぜデータ永続化が必要か

### コンテナのファイルシステムの仕組み

Dockerコンテナは、**レイヤードファイルシステム**を使用しています：

```bash
# イメージレイヤーの確認
docker image inspect postgres:15-alpine --format='{{json .RootFS.Layers}}' | jq
```

```
[
  "sha256:base-layer...",      # ベースOS（Alpine Linux）
  "sha256:postgres-bin...",    # PostgreSQLバイナリ
  "sha256:config-files...",    # 設定ファイル
  "sha256:init-scripts..."     # 初期化スクリプト
]
```

コンテナが起動すると、これらの**読み取り専用レイヤー**の上に**書き込み可能レイヤー（Container Layer）**が追加されます：

```
┌─────────────────────────────┐
│  Container Layer (R/W)      │ ← データベースファイル、ログなど
├─────────────────────────────┤
│  Image Layers (Read-Only)   │
│  - Init Scripts             │
│  - Config Files             │
│  - PostgreSQL Binary        │
│  - Base OS (Alpine)         │
└─────────────────────────────┘
```

**問題点:**

コンテナが削除されると、この**書き込み可能レイヤーも一緒に削除**されます。つまり：

```bash
# Podを削除
kubectl delete pod postgres

# → Container Layerが削除される
# → データベースファイルが失われる
# → 全データが消失！
```

### どんなデータを永続化する必要があるか

**永続化が必須なデータ:**

1. **データベースファイル** - PostgreSQL、MySQL、MongoDBなど
2. **ユーザーがアップロードしたファイル** - 画像、動画、ドキュメント
3. **ログファイル** - 長期保存が必要なアプリケーションログ
4. **セッションデータ** - Redis、Memcachedのバックアップ
5. **設定ファイル** - 動的に生成・更新される設定

**永続化が不要なデータ:**

1. **一時ファイル** - `/tmp`に保存されるキャッシュ
2. **ビルド成果物** - 再ビルド可能なもの
3. **メトリクス** - Prometheusなどの外部システムに転送されるもの
4. **ステートレスなアプリケーションのコード** - イメージに含まれている

### 実際に起こる問題のシナリオ

#### シナリオ1: Podのクラッシュと再起動

```bash
# PostgreSQLが動作中
kubectl get pods
# NAME       READY   STATUS    RESTARTS   AGE
# postgres   1/1     Running   0          10m

# 何らかの理由でコンテナがクラッシュ（OOM、バグなど）
# Kubernetesが自動的に再起動

kubectl get pods
# NAME       READY   STATUS    RESTARTS   AGE
# postgres   1/1     Running   1          11m
#                              ↑ 再起動回数が増加

# 新しいコンテナが起動するため、データは失われている！
```

#### シナリオ2: Podの更新・ローリングアップデート

```bash
# イメージを更新
kubectl set image deployment/postgres postgres=postgres:16-alpine

# 古いPodが削除され、新しいPodが作成される
# → 新しいコンテナには以前のデータが存在しない
```

#### シナリオ3: ノード障害

```bash
# ノード1でPodが実行中
kubectl get pods -o wide
# NAME       READY   STATUS    NODE
# postgres   1/1     Running   node1

# ノード1がダウン
# KubernetesがPodをノード2に再スケジュール

kubectl get pods -o wide
# NAME       READY   STATUS    NODE
# postgres   1/1     Running   node2
#                              ↑ 別のノードで起動

# ノード1のローカルストレージにあったデータは失われている！
```

これらの問題を解決するのが**PersistentVolume**です。

## PV、PVC、StorageClassの関係 - 3つのリソースの役割

Kubernetesのストレージシステムは、3つの主要なリソースで構成されています。

### 全体像の理解

```
┌─────────────────────────────────────────────────────┐
│                    開発者                             │
│  「100GBのストレージが欲しい」                        │
└────────────────────┬────────────────────────────────┘
                     │ 要求（Claim）
                     ↓
┌─────────────────────────────────────────────────────┐
│         PersistentVolumeClaim (PVC)                 │
│  「SSDで100GBのストレージを要求します」              │
│   - アクセスモード: ReadWriteOnce                   │
│   - 容量: 100Gi                                      │
│   - StorageClass: fast-ssd                          │
└────────────────────┬────────────────────────────────┘
                     │ バインディング
                     ↓
┌─────────────────────────────────────────────────────┐
│          PersistentVolume (PV)                      │
│  「実際のストレージリソース」                        │
│   - 容量: 100Gi                                      │
│   - ストレージの種類: AWS EBS、GCE PD、NFSなど      │
│   - アクセスモード: ReadWriteOnce                   │
└────────────────────┬────────────────────────────────┘
                     │ プロビジョニング
                     ↓
┌─────────────────────────────────────────────────────┐
│            StorageClass                             │
│  「ストレージの種類と作成方法を定義」                │
│   - プロビジョナー: kubernetes.io/aws-ebs           │
│   - パラメータ: type=gp3, iops=3000                 │
└─────────────────────────────────────────────────────┘
```

### PersistentVolume (PV) - 実際のストレージ

**役割:** クラスタ内の実際のストレージリソースを表現

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: my-pv
spec:
  capacity:
    storage: 10Gi
  accessModes:
  - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  hostPath:  # ストレージの種類（minikubeでの例）
    path: /data/my-volume
```

**重要な設定項目:**

- `capacity.storage` - ストレージの容量
- `accessModes` - アクセスモード（後述）
- `persistentVolumeReclaimPolicy` - PVCが削除された後の挙動
- ストレージバックエンド - `hostPath`、`nfs`、`awsElasticBlockStore`など

### PersistentVolumeClaim (PVC) - ストレージの要求

**役割:** ユーザー（開発者）からのストレージ要求を表現

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: my-pvc
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 5Gi
  storageClassName: standard
```

**重要な設定項目:**

- `accessModes` - 必要なアクセスモード
- `resources.requests.storage` - 必要な容量
- `storageClassName` - 使用するStorageClass

**PVとPVCのバインディング:**

Kubernetesは、PVCの要求条件に合致するPVを自動的に見つけて**バインド（Bind）**します：

```bash
# PVCを作成
kubectl apply -f my-pvc.yaml

# バインディング状態を確認
kubectl get pvc
# NAME     STATUS   VOLUME   CAPACITY   ACCESS MODES   STORAGECLASS
# my-pvc   Bound    my-pv    10Gi       RWO            standard

# PVの状態も確認
kubectl get pv
# NAME    CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM
# my-pv   10Gi       RWO            Retain           Bound    default/my-pvc
```

### StorageClass - ストレージの動的プロビジョニング

**役割:** ストレージの種類と動的作成方法を定義

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: fast-ssd
provisioner: kubernetes.io/aws-ebs
parameters:
  type: gp3
  iopsPerGB: "50"
  fsType: ext4
```

**動的プロビジョニングの利点:**

手動でPVを作成する必要がなく、PVCを作成すると自動的にPVが作成されます：

```bash
# StorageClassを指定したPVCを作成
kubectl apply -f pvc-with-storageclass.yaml

# 自動的にPVが作成される
kubectl get pv
# NAME                                       CAPACITY   ACCESS MODES
# pvc-12345678-1234-1234-1234-123456789012   100Gi      RWO
```

### アクセスモードの種類

**ReadWriteOnce (RWO):**

- 単一のノードからRead/Write可能
- 最も一般的なモード
- 用途: データベース、アプリケーションデータ

**ReadOnlyMany (ROX):**

- 複数のノードからRead-only可能
- 用途: 静的コンテンツの配信、共有設定ファイル

**ReadWriteMany (RWX):**

- 複数のノードからRead/Write可能
- NFSなどの共有ファイルシステムが必要
- 用途: 共有ログディレクトリ、複数Podからアクセスするファイル

**ReadWriteOncePod (RWOP):**

- 単一のPodからのみRead/Write可能（Kubernetes 1.22+）
- 最も厳格なモード
- 用途: データベース、排他制御が必要なアプリケーション

```yaml
# アクセスモードの例
accessModes:
- ReadWriteOnce  # 略記: RWO
- ReadOnlyMany   # 略記: ROX
- ReadWriteMany  # 略記: RWX
```

## PersistentVolumeの作成 - YAMLマニフェストと設定

それでは、実際にPersistentVolumeを作成してみましょう。

### minikubeでの基本的なPV作成（hostPath）

minikubeでは、`hostPath`を使ってローカルディレクトリをストレージとして使用できます。

**PVマニフェスト（pv-hostpath.yaml）:**

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: postgres-pv
  labels:
    type: local
    app: postgres
spec:
  storageClassName: manual
  capacity:
    storage: 5Gi
  accessModes:
  - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  hostPath:
    path: /data/postgres
    type: DirectoryOrCreate
```

**設定の詳細:**

- `storageClassName: manual` - 手動プロビジョニング用のクラス名
- `capacity.storage: 5Gi` - 5GBのストレージ
- `accessModes` - 単一ノードからのみアクセス可能
- `persistentVolumeReclaimPolicy: Retain` - PVC削除後もデータを保持
- `hostPath.path` - minikubeノード上のパス
- `hostPath.type: DirectoryOrCreate` - ディレクトリが存在しない場合は作成

**PVの作成:**

```bash
# PVを作成
kubectl apply -f pv-hostpath.yaml
# persistentvolume/postgres-pv created

# PVの状態確認
kubectl get pv
# NAME          CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS      CLAIM
# postgres-pv   5Gi        RWO            Retain           Available

# 詳細情報の確認
kubectl describe pv postgres-pv
```

```
Name:            postgres-pv
Labels:          app=postgres
                 type=local
Annotations:     <none>
Finalizers:      [kubernetes.io/pv-protection]
StorageClass:    manual
Status:          Available  # まだ要求されていない
Claim:           
Reclaim Policy:  Retain
Access Modes:    RWO
VolumeMode:      Filesystem
Capacity:        5Gi
Node Affinity:   <none>
Message:         
Source:
    Type:          HostPath (bare host directory volume)
    Path:          /data/postgres
    HostPathType:  DirectoryOrCreate
Events:            <none>
```

### Reclaim Policyの種類

**Retain（保持）:**

- PVCが削除されてもPVとデータは残る
- 手動でデータを削除する必要がある
- 用途: 重要なデータ、手動バックアップが必要なケース

```yaml
persistentVolumeReclaimPolicy: Retain
```

**Delete（削除）:**

- PVCが削除されるとPVも自動削除される
- ストレージプロバイダーによっては実データも削除される
- 用途: 一時的なデータ、自動クリーンアップが必要なケース

```yaml
persistentVolumeReclaimPolicy: Delete
```

**Recycle（リサイクル）:** *非推奨*

- PVCが削除されるとデータが削除され、PVは再利用可能になる
- 現在は非推奨で、Dynamic Provisioningの使用が推奨される

### より高度なPV設定例

**NFSストレージを使ったPV:**

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: shared-files-pv
spec:
  capacity:
    storage: 100Gi
  accessModes:
  - ReadWriteMany  # 複数Podからアクセス可能
  persistentVolumeReclaimPolicy: Retain
  nfs:
    server: nfs-server.example.com
    path: /shared/data
```

**クラウドストレージを使ったPV（AWS EBS）:**

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: aws-ebs-pv
spec:
  capacity:
    storage: 50Gi
  accessModes:
  - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  awsElasticBlockStore:
    volumeID: vol-0123456789abcdef0
    fsType: ext4
```

**GCE Persistent Diskを使ったPV:**

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: gce-pd-pv
spec:
  capacity:
    storage: 200Gi
  accessModes:
  - ReadWriteOnce
  persistentVolumeReclaimPolicy: Delete
  gcePersistentDisk:
    pdName: my-data-disk
    fsType: ext4
```

## PersistentVolumeClaimで要求 - Podからストレージを利用

PVを作成したら、次はPVCを使ってストレージを要求します。

### PVCの作成

**PVCマニフェスト（pvc-postgres.yaml）:**

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: postgres-pvc
spec:
  storageClassName: manual
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 3Gi
```

**ポイント:**

- `storage: 3Gi` - 要求は3GBだが、5GBのPVとマッチする（容量が足りている）
- `storageClassName` - PVと同じクラス名を指定
- `accessModes` - PVと互換性のあるモードを指定

**PVCの作成とバインディング確認:**

```bash
# PVCを作成
kubectl apply -f pvc-postgres.yaml
# persistentvolumeclaim/postgres-pvc created

# PVCの状態確認
kubectl get pvc
# NAME           STATUS   VOLUME        CAPACITY   ACCESS MODES   STORAGECLASS
# postgres-pvc   Bound    postgres-pv   5Gi        RWO            manual
#                ↑ Boundになっていればバインディング成功

# PVの状態も変化
kubectl get pv
# NAME          CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM
# postgres-pv   5Gi        RWO            Retain           Bound    default/postgres-pvc
#                                                          ↑ Bound  ↑ どのPVCにバインドされたか
```

### PodでPVCを使用

PVCをPodにマウントするには、`volumes`と`volumeMounts`を使用します。

**Podマニフェスト（postgres-pod-with-pvc.yaml）:**

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: postgres
  labels:
    app: postgres
spec:
  containers:
  - name: postgres
    image: postgres:15-alpine
    env:
    - name: POSTGRES_PASSWORD
      value: mypassword
    - name: PGDATA
      value: /var/lib/postgresql/data/pgdata
    ports:
    - containerPort: 5432
    volumeMounts:
    - name: postgres-storage
      mountPath: /var/lib/postgresql/data
  volumes:
  - name: postgres-storage
    persistentVolumeClaim:
      claimName: postgres-pvc
```

**重要なポイント:**

1. **volumes定義** - PVCを参照
2. **volumeMounts** - コンテナ内のマウントパスを指定
3. **PGDATA環境変数** - PostgreSQLのデータディレクトリを指定（サブディレクトリにする必要がある）

**Podのデプロイと動作確認:**

```bash
# Podを作成
kubectl apply -f postgres-pod-with-pvc.yaml
# pod/postgres created

# Podが起動するまで待つ
kubectl wait --for=condition=Ready pod/postgres --timeout=60s

# Podの状態確認
kubectl get pods
# NAME       READY   STATUS    RESTARTS   AGE
# postgres   1/1     Running   0          30s

# マウント状態を確認
kubectl exec postgres -- df -h /var/lib/postgresql/data
```

```
Filesystem      Size  Used Avail Use% Mounted on
/dev/sda1       5.0G   40M  4.9G   1% /var/lib/postgresql/data
```

### データ永続化のテスト

実際にデータを保存して、Pod再作成後もデータが残ることを確認します：

```bash
# データベースとテーブルを作成
kubectl exec postgres -- psql -U postgres -c "CREATE DATABASE myapp;"
kubectl exec postgres -- psql -U postgres -d myapp -c "CREATE TABLE products (id SERIAL PRIMARY KEY, name TEXT, price DECIMAL);"

# データを挿入
kubectl exec postgres -- psql -U postgres -d myapp -c "INSERT INTO products (name, price) VALUES ('Laptop', 999.99), ('Mouse', 29.99), ('Keyboard', 79.99);"

# データを確認
kubectl exec postgres -- psql -U postgres -d myapp -c "SELECT * FROM products;"
```

```
 id |   name   | price  
----+----------+--------
  1 | Laptop   | 999.99
  2 | Mouse    |  29.99
  3 | Keyboard |  79.99
(3 rows)
```

**Podを削除して再作成:**

```bash
# Podを削除（PVCは削除しない！）
kubectl delete pod postgres

# 同じマニフェストで再作成
kubectl apply -f postgres-pod-with-pvc.yaml

# Podが起動するまで待つ
kubectl wait --for=condition=Ready pod/postgres --timeout=60s

# データが残っていることを確認！
kubectl exec postgres -- psql -U postgres -d myapp -c "SELECT * FROM products;"
```

```
 id |   name   | price  
----+----------+--------
  1 | Laptop   | 999.99
  2 | Mouse    |  29.99
  3 | Keyboard |  79.99
(3 rows)
```

**成功！** データが永続化されています。

### 複数コンテナでの共有ストレージ

同じPVCを複数のコンテナでマウントすることも可能です：

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: multi-container-app
spec:
  containers:
  - name: app
    image: myapp:latest
    volumeMounts:
    - name: shared-data
      mountPath: /app/data
  - name: backup
    image: backup-tool:latest
    volumeMounts:
    - name: shared-data
      mountPath: /backup/source
      readOnly: true  # 読み取り専用でマウント
  volumes:
  - name: shared-data
    persistentVolumeClaim:
      claimName: my-pvc
```

## StorageClassで動的プロビジョニング - クラウドストレージの自動作成

手動でPVを作成するのは手間がかかります。**StorageClass**を使えば、PVCを作成するだけで自動的にPVが作成されます。

### minikubeのデフォルトStorageClass

minikubeには、デフォルトでStorageClassが用意されています：

```bash
# StorageClassの一覧
kubectl get storageclass
```

```
NAME                 PROVISIONER                RECLAIMPOLICY   VOLUMEBINDINGMODE
standard (default)   k8s.io/minikube-hostpath   Delete          Immediate
```

**確認ポイント:**

- `(default)` - デフォルトのStorageClass
- `PROVISIONER` - ストレージを作成するプロビジョナー
- `RECLAIMPOLICY` - Delete（PVC削除時にPVも削除）
- `VOLUMEBINDINGMODE: Immediate` - PVC作成時に即座にPVを作成

### 動的プロビジョニングの実践

StorageClassを明示的に指定しないPVCは、デフォルトのStorageClassを使用します：

**動的PVCマニフェスト（pvc-dynamic.yaml）:**

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: dynamic-pvc
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 2Gi
  # storageClassNameを指定しない = デフォルトを使用
```

**動作確認:**

```bash
# PVCを作成
kubectl apply -f pvc-dynamic.yaml

# 即座にPVが自動作成される
kubectl get pv
# NAME                                       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS
# pvc-a1b2c3d4-e5f6-7890-abcd-ef1234567890   2Gi        RWO            Delete           Bound

# PVCの確認
kubectl get pvc dynamic-pvc
# NAME          STATUS   VOLUME                                     CAPACITY
# dynamic-pvc   Bound    pvc-a1b2c3d4-e5f6-7890-abcd-ef1234567890   2Gi
```

**自動作成されたPVの詳細:**

```bash
kubectl describe pv <pv-name>
```

```
Name:            pvc-a1b2c3d4-e5f6-7890-abcd-ef1234567890
Labels:          <none>
Annotations:     pv.kubernetes.io/provisioned-by: k8s.io/minikube-hostpath
Finalizers:      [kubernetes.io/pv-protection]
StorageClass:    standard
Status:          Bound
Claim:           default/dynamic-pvc
Reclaim Policy:  Delete  # 自動削除される
Access Modes:    RWO
VolumeMode:      Filesystem
Capacity:        2Gi
...
```

### カスタムStorageClassの作成

独自のStorageClassを定義することで、異なるストレージ性能やタイプを使い分けられます。

**高速SSD用StorageClass（AWS EBS gp3）:**

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: fast-ssd
provisioner: ebs.csi.aws.com
parameters:
  type: gp3
  iops: "3000"
  throughput: "125"
  fsType: ext4
allowVolumeExpansion: true
volumeBindingMode: WaitForFirstConsumer
```

**大容量HDD用StorageClass（AWS EBS sc1）:**

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: bulk-storage
provisioner: ebs.csi.aws.com
parameters:
  type: sc1
  fsType: ext4
allowVolumeExpansion: true
volumeBindingMode: WaitForFirstConsumer
```

**カスタムStorageClassを使ったPVC:**

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: database-pvc
spec:
  storageClassName: fast-ssd  # カスタムクラスを指定
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 100Gi
```

### volumeBindingModeの違い

**Immediate（即座にバインド）:**

```yaml
volumeBindingMode: Immediate
```

- PVC作成時に即座にPVを作成・バインド
- Podがスケジュールされる前にストレージが確保される
- 問題: Podがスケジュールされたノードとストレージのノードが異なる可能性

**WaitForFirstConsumer（最初の使用時にバインド）:**

```yaml
volumeBindingMode: WaitForFirstConsumer
```

- PodがスケジュールされるまでPVの作成を遅延
- Podと同じノード（またはゾーン）にストレージを作成
- クラウド環境で推奨される設定

## データベースでの実践 - PostgreSQLの永続化例

それでは、これまで学んだ内容を統合して、実践的なPostgreSQLのデプロイメントを作成しましょう。

### 完全な構成（Deployment + PVC）

**postgres-stateful.yaml:**

```yaml
# PersistentVolumeClaim
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: postgres-data
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
  # デフォルトStorageClassを使用（動的プロビジョニング）
---
# Deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: postgres
  labels:
    app: postgres
spec:
  replicas: 1  # データベースは通常1つ
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
        env:
        - name: POSTGRES_USER
          value: myuser
        - name: POSTGRES_PASSWORD
          valueFrom:
            secretKeyRef:
              name: postgres-secret
              key: password
        - name: POSTGRES_DB
          value: myappdb
        - name: PGDATA
          value: /var/lib/postgresql/data/pgdata
        ports:
        - containerPort: 5432
          name: postgres
        volumeMounts:
        - name: postgres-storage
          mountPath: /var/lib/postgresql/data
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        livenessProbe:
          exec:
            command:
            - pg_isready
            - -U
            - myuser
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          exec:
            command:
            - pg_isready
            - -U
            - myuser
          initialDelaySeconds: 5
          periodSeconds: 5
      volumes:
      - name: postgres-storage
        persistentVolumeClaim:
          claimName: postgres-data
---
# Service
apiVersion: v1
kind: Service
metadata:
  name: postgres
spec:
  selector:
    app: postgres
  ports:
  - port: 5432
    targetPort: 5432
  type: ClusterIP
---
# Secret（パスワード管理）
apiVersion: v1
kind: Secret
metadata:
  name: postgres-secret
type: Opaque
stringData:
  password: "MySecurePassword123!"
```

**デプロイ:**

```bash
# すべてのリソースを作成
kubectl apply -f postgres-stateful.yaml

# リソースの確認
kubectl get all,pvc,secret
```

```
NAME                            READY   STATUS    RESTARTS   AGE
pod/postgres-7b8c9d5f6-x2k4m    1/1     Running   0          1m

NAME                       TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)
service/postgres           ClusterIP   10.96.100.123   <none>        5432/TCP

NAME                       READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/postgres   1/1     1            1           1m

NAME                                  DESIRED   CURRENT   READY   AGE
replicaset.apps/postgres-7b8c9d5f6    1         1         1       1m

NAME                                  STATUS   VOLUME                                     CAPACITY
persistentvolumeclaim/postgres-data   Bound    pvc-12345678-1234-1234-1234-123456789012   10Gi

NAME                         TYPE     DATA   AGE
secret/postgres-secret       Opaque   1      1m
```

### 初期化スクリプトの追加

データベース作成時に初期スキーマを自動投入したい場合は、ConfigMapとInitContainerを使用します：

```yaml
# 初期化スクリプト用ConfigMap
apiVersion: v1
kind: ConfigMap
metadata:
  name: postgres-init-script
data:
  init.sql: |
    CREATE TABLE IF NOT EXISTS users (
        id SERIAL PRIMARY KEY,
        username VARCHAR(50) UNIQUE NOT NULL,
        email VARCHAR(100) UNIQUE NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );
    
    CREATE TABLE IF NOT EXISTS posts (
        id SERIAL PRIMARY KEY,
        user_id INTEGER REFERENCES users(id),
        title VARCHAR(200) NOT NULL,
        content TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );
    
    INSERT INTO users (username, email) VALUES
        ('alice', 'alice@example.com'),
        ('bob', 'bob@example.com')
    ON CONFLICT DO NOTHING;
---
# Deploymentに追加
spec:
  template:
    spec:
      initContainers:
      - name: init-db
        image: postgres:15-alpine
        command:
        - sh
        - -c
        - |
          until pg_isready -h localhost -U myuser; do
            echo "Waiting for PostgreSQL..."
            sleep 2
          done
          psql -h localhost -U myuser -d myappdb -f /scripts/init.sql
        env:
        - name: PGPASSWORD
          valueFrom:
            secretKeyRef:
              name: postgres-secret
              key: password
        volumeMounts:
        - name: init-scripts
          mountPath: /scripts
      volumes:
      - name: init-scripts
        configMap:
          name: postgres-init-script
```

### アプリケーションからの接続例

**Node.js（pg）での接続:**

```javascript
const { Pool } = require('pg');

const pool = new Pool({
  host: 'postgres',  // Service名
  port: 5432,
  database: 'myappdb',
  user: 'myuser',
  password: process.env.DB_PASSWORD,  // Secretから注入
});

// クエリ実行
async function getUsers() {
  const result = await pool.query('SELECT * FROM users');
  console.log(result.rows);
}
```

**Python（psycopg2）での接続:**

```python
import psycopg2
import os

conn = psycopg2.connect(
    host="postgres",  # Service名
    port=5432,
    database="myappdb",
    user="myuser",
    password=os.environ['DB_PASSWORD']  # Secretから注入
)

cur = conn.cursor()
cur.execute("SELECT * FROM users")
rows = cur.fetchall()
for row in rows:
    print(row)
```

### バックアップとリストア

**データベースのバックアップ:**

```bash
# pg_dumpでバックアップ
kubectl exec deployment/postgres -- pg_dump -U myuser myappdb > backup.sql

# または、Podを指定して実行
POD_NAME=$(kubectl get pod -l app=postgres -o jsonpath='{.items[0].metadata.name}')
kubectl exec $POD_NAME -- pg_dump -U myuser myappdb > backup-$(date +%Y%m%d).sql
```

**リストア:**

```bash
# バックアップファイルをリストア
cat backup.sql | kubectl exec -i deployment/postgres -- psql -U myuser myappdb
```

**CronJobを使った自動バックアップ:**

```yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: postgres-backup
spec:
  schedule: "0 2 * * *"  # 毎日2時に実行
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: backup
            image: postgres:15-alpine
            command:
            - sh
            - -c
            - |
              pg_dump -h postgres -U myuser myappdb > /backup/backup-$(date +%Y%m%d-%H%M%S).sql
            env:
            - name: PGPASSWORD
              valueFrom:
                secretKeyRef:
                  name: postgres-secret
                  key: password
            volumeMounts:
            - name: backup-storage
              mountPath: /backup
          restartPolicy: OnFailure
          volumes:
          - name: backup-storage
            persistentVolumeClaim:
              claimName: backup-pvc
```

## まとめと次回予告

### 今回学んだこと

本記事では、Kubernetesにおけるデータ永続化の仕組みを学習しました：

1. **コンテナの揮発性の理解**
   - コンテナのレイヤードファイルシステム
   - Pod再起動やノード障害でデータが失われる問題
   - 永続化が必要なデータと不要なデータの見分け方

2. **PersistentVolume (PV)**
   - クラスタ内の実際のストレージリソース
   - アクセスモード（RWO、ROX、RWX、RWOP）
   - Reclaim Policy（Retain、Delete）の違い

3. **PersistentVolumeClaim (PVC)**
   - ユーザーからのストレージ要求
   - PVとPVCの自動バインディング
   - Podでの使用方法（volumes、volumeMounts）

4. **StorageClass**
   - 動的プロビジョニングの仕組み
   - カスタムStorageClassの作成
   - volumeBindingMode（ImmediateとWaitForFirstConsumer）

5. **PostgreSQLでの実践**
   - Deployment + PVC構成
   - 初期化スクリプトの投入
   - アプリケーションからの接続
   - バックアップとリストア

**重要なポイント:**

- ステートフルアプリケーション（データベースなど）には必ずPersistentVolumeを使用する
- 本番環境では動的プロビジョニング（StorageClass）を活用する
- Reclaim Policyを理解し、重要なデータはRetainに設定する
- 定期的なバックアップ戦略を実装する

### 次回予告：第8回 StatefulSet

次回の記事「StatefulSetで安定したIDを持つPod群を管理」では、以下を学習します：

- **DeploymentとStatefulSetの違い**
  - Podの命名規則と安定したネットワークID
  - 順序付きデプロイメントとスケーリング

- **StatefulSetの実践**
  - volumeClaimTemplatesによるPVCの自動作成
  - Headless Serviceとの組み合わせ
  - Pod間の個別アクセス方法

- **ステートフルアプリケーションの設計パターン**
  - データベースクラスタ（PostgreSQL、MySQL）
  - 分散システム（Kafka、Elasticsearch、Cassandra）
  - マスター・スレーブ構成の実装

- **データの一貫性とバックアップ**
  - VolumeSnapshotによるスナップショット
  - データ移行とディザスタリカバリ

お楽しみに！

## 参考リンク

- [Kubernetes公式ドキュメント - Persistent Volumes](https://kubernetes.io/docs/concepts/storage/persistent-volumes/)
- [Kubernetes公式ドキュメント - Storage Classes](https://kubernetes.io/docs/concepts/storage/storage-classes/)
- [Kubernetes公式ドキュメント - Dynamic Volume Provisioning](https://kubernetes.io/docs/concepts/storage/dynamic-provisioning/)
- [PostgreSQL公式ドキュメント](https://www.postgresql.org/docs/)
