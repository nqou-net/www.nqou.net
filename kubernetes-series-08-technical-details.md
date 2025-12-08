# 第8回「StatefulSetで作るステートフルアプリ」技術詳細

## 主要な概念と仕組み

### StatefulSetとは
StatefulSetは、ステートフルなアプリケーション（データベース、分散システム、永続化が必要なサービス）を管理するためのKubernetesリソースです。Deploymentとは異なり、各Podに**安定したネットワークアイデンティティ**と**永続的なストレージ**を提供します。

### StatefulSetの特徴

1. **順序付けられたデプロイと削除**
   - Podは `{StatefulSet名}-{序数}` という予測可能な名前で作成される（例: `mysql-0`, `mysql-1`, `mysql-2`）
   - スケールアップ時は序数順に起動（0→1→2）
   - スケールダウン時は逆順に削除（2→1→0）
   - 各Podは前のPodがReady状態になってから起動

2. **安定したネットワークアイデンティティ**
   - 各PodはHeadless Serviceを通じて `{Pod名}.{Service名}.{Namespace}.svc.cluster.local` という安定したDNS名を持つ
   - Pod再作成後も同じ名前とホスト名が保証される
   - クラスタ内の他のPodから個別にアクセス可能

3. **永続的なストレージ**
   - PersistentVolumeClaimテンプレートを使用して各Podに専用のPVCを自動作成
   - Pod削除後もPVCは保持される（データ保護）
   - Pod再作成時に同じPVCが再アタッチされる

### 内部動作の詳細

StatefulSetコントローラーは以下のロジックで動作します：

1. **Pod作成フェーズ**
   - 序数0から順に1つずつPodを作成
   - 各Pod作成時に対応するPVCも生成（`{volumeClaimTemplate名}-{Pod名}`）
   - 前のPodがRunningかつReadyになるまで次のPod作成を待機

2. **Pod更新フェーズ**
   - RollingUpdate戦略（デフォルト）では最大序数から逆順に更新
   - OnDelete戦略では手動削除されたPodのみ更新
   - `partition`パラメータで更新対象を制御可能（カナリアデプロイメント）

3. **Pod削除フェーズ**
   - 最大序数から順に削除
   - 各Pod削除前にGraceful Terminationを実行
   - PVCは自動削除されない（明示的な削除が必要）

## 実践的なYAMLマニフェスト例

### 基本的なStatefulSet（PostgreSQLクラスタ）

```yaml
apiVersion: v1
kind: Service
metadata:
  name: postgres-headless
  labels:
    app: postgres
spec:
  ports:
  - port: 5432
    name: postgres
  clusterIP: None  # Headless Service
  selector:
    app: postgres
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: postgres
spec:
  serviceName: postgres-headless  # Headless Serviceの名前
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
        env:
        - name: POSTGRES_PASSWORD
          valueFrom:
            secretKeyRef:
              name: postgres-secret
              key: password
        - name: PGDATA
          value: /var/lib/postgresql/data/pgdata
        - name: POD_NAME
          valueFrom:
            fieldRef:
              fieldPath: metadata.name
        volumeMounts:
        - name: postgres-storage
          mountPath: /var/lib/postgresql/data
        livenessProbe:
          exec:
            command:
            - /bin/sh
            - -c
            - pg_isready -U postgres
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          exec:
            command:
            - /bin/sh
            - -c
            - pg_isready -U postgres
          initialDelaySeconds: 10
          periodSeconds: 5
  volumeClaimTemplates:  # 各Podに自動でPVCを作成
  - metadata:
      name: postgres-storage
    spec:
      accessModes: [ "ReadWriteOnce" ]
      storageClassName: standard
      resources:
        requests:
          storage: 10Gi
```

### 高度な例：初期化処理とリーダー選出を含むStatefulSet

```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: redis-cluster
spec:
  serviceName: redis-cluster
  replicas: 6
  selector:
    matchLabels:
      app: redis-cluster
  template:
    metadata:
      labels:
        app: redis-cluster
    spec:
      initContainers:
      # 初期設定を行うinitContainer
      - name: config
        image: redis:7-alpine
        command:
        - sh
        - -c
        - |
          set -ex
          # 序数を取得（redis-cluster-0なら0）
          [[ $HOSTNAME =~ -([0-9]+)$ ]] || exit 1
          ordinal=${BASH_REMATCH[1]}
          
          # 設定ファイル生成
          cp /mnt/config-map/redis.conf /etc/redis/redis.conf
          
          # 最初の3台をマスター、残りをレプリカとして設定
          if [[ $ordinal -lt 3 ]]; then
            echo "cluster-enabled yes" >> /etc/redis/redis.conf
          else
            master_ordinal=$((ordinal - 3))
            echo "slaveof redis-cluster-${master_ordinal}.redis-cluster 6379" >> /etc/redis/redis.conf
          fi
        volumeMounts:
        - name: conf
          mountPath: /etc/redis
        - name: config-map
          mountPath: /mnt/config-map
      containers:
      - name: redis
        image: redis:7-alpine
        command:
        - redis-server
        - /etc/redis/redis.conf
        ports:
        - containerPort: 6379
          name: client
        - containerPort: 16379
          name: gossip
        volumeMounts:
        - name: data
          mountPath: /data
        - name: conf
          mountPath: /etc/redis
        resources:
          requests:
            memory: "512Mi"
            cpu: "250m"
          limits:
            memory: "1Gi"
            cpu: "500m"
      volumes:
      - name: conf
        emptyDir: {}
      - name: config-map
        configMap:
          name: redis-config
  volumeClaimTemplates:
  - metadata:
      name: data
    spec:
      accessModes: [ "ReadWriteOnce" ]
      resources:
        requests:
          storage: 5Gi
  # RollingUpdate戦略の設定
  updateStrategy:
    type: RollingUpdate
    rollingUpdate:
      partition: 0  # この序数以上のPodのみ更新
```

### PodManagementPolicyの活用例

```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: web-cache
spec:
  serviceName: web-cache
  replicas: 5
  podManagementPolicy: Parallel  # 並列起動（デフォルトはOrderedReady）
  selector:
    matchLabels:
      app: web-cache
  template:
    metadata:
      labels:
        app: web-cache
    spec:
      containers:
      - name: nginx
        image: nginx:alpine
        ports:
        - containerPort: 80
        volumeMounts:
        - name: cache-volume
          mountPath: /usr/share/nginx/html
  volumeClaimTemplates:
  - metadata:
      name: cache-volume
    spec:
      accessModes: [ "ReadWriteOnce" ]
      resources:
        requests:
          storage: 1Gi
```

## kubectlコマンド例

### StatefulSetの基本操作

```bash
# StatefulSet作成
kubectl apply -f statefulset.yaml

# StatefulSet一覧表示
kubectl get statefulsets
kubectl get sts  # 短縮形

# 詳細情報表示
kubectl describe statefulset postgres

# StatefulSetのPod一覧
kubectl get pods -l app=postgres

# 特定のPod情報
kubectl get pod postgres-0 -o yaml

# StatefulSetのスケーリング
kubectl scale statefulset postgres --replicas=5

# または
kubectl patch statefulset postgres -p '{"spec":{"replicas":5}}'

# StatefulSet削除（PVCは残る）
kubectl delete statefulset postgres

# StatefulSetとPVCを同時削除
kubectl delete statefulset postgres
kubectl delete pvc -l app=postgres

# カスケード削除の制御
kubectl delete statefulset postgres --cascade=orphan  # Podを残す
```

### Pod個別操作

```bash
# 特定のPodに接続
kubectl exec -it postgres-0 -- psql -U postgres

# 複数Podで並列コマンド実行
for i in 0 1 2; do
  kubectl exec postgres-$i -- psql -U postgres -c "SELECT version();"
done

# Pod削除（自動再作成される）
kubectl delete pod postgres-1

# 強制削除（Graceful Terminationスキップ）
kubectl delete pod postgres-2 --force --grace-period=0
```

### ローリングアップデート

```bash
# イメージ更新
kubectl set image statefulset/postgres postgres=postgres:16-alpine

# 更新状況確認
kubectl rollout status statefulset/postgres

# 更新履歴
kubectl rollout history statefulset/postgres

# ロールバック
kubectl rollout undo statefulset/postgres

# 特定リビジョンにロールバック
kubectl rollout undo statefulset/postgres --to-revision=2

# partition使用（カナリアデプロイ）
kubectl patch statefulset postgres -p '{"spec":{"updateStrategy":{"rollingUpdate":{"partition":2}}}}'
# → postgres-2以上のみ更新される
```

### デバッグとトラブルシューティング

```bash
# Pod起動順序の確認
kubectl get events --sort-by='.lastTimestamp' | grep postgres

# PVC確認
kubectl get pvc
kubectl describe pvc postgres-storage-postgres-0

# PV確認
kubectl get pv

# StatefulSetコントローラーログ
kubectl logs -n kube-system deployment/kube-controller-manager

# ネットワーク疎通確認
kubectl run -it --rm debug --image=busybox --restart=Never -- nslookup postgres-0.postgres-headless

# DNS解決確認
kubectl run -it --rm debug --image=busybox --restart=Never -- sh
# コンテナ内で
nslookup postgres-0.postgres-headless.default.svc.cluster.local
ping postgres-1.postgres-headless
```

### ストレージ管理

```bash
# PVC容量確認
kubectl get pvc -o custom-columns=NAME:.metadata.name,CAPACITY:.spec.resources.requests.storage,STATUS:.status.phase

# PVCの詳細とバインド状態
kubectl describe pvc postgres-storage-postgres-0

# PVC削除（StatefulSet削除後）
kubectl delete pvc postgres-storage-postgres-0

# 全PVC一括削除
kubectl delete pvc -l app=postgres

# 孤立したPVCの検出
kubectl get pvc -o json | jq '.items[] | select(.status.phase=="Pending") | .metadata.name'
```

## 初心者がつまづきやすいポイント

### 1. Headless Serviceの理解不足

**問題**: なぜclusterIP: Noneが必要なのか分からない

**説明**: 
- 通常のServiceはロードバランシング用の単一IPを持つ
- StatefulSetでは各Pod個別にアクセスする必要がある
- Headless ServiceはPod個別のDNSエントリを提供
- `postgres-0.postgres-headless.default.svc.cluster.local` のようにPod単位でアクセス可能

**解決策**:
```bash
# 通常のService（ClusterIP有り）
kubectl get svc normal-service
# NAME             TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)
# normal-service   ClusterIP   10.96.100.10   <none>        80/TCP

# Headless Service（ClusterIP無し）
kubectl get svc postgres-headless
# NAME                TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)
# postgres-headless   ClusterIP   None         <none>        5432/TCP

# DNS確認
kubectl run -it --rm debug --image=busybox -- nslookup postgres-headless
# 各PodのIPアドレスが返される（複数Aレコード）
```

### 2. PVC自動削除されない問題

**問題**: StatefulSet削除後もPVCが残っていてストレージを圧迫

**原因**: 
- データ保護のため、PVCは意図的に自動削除されない仕様
- 誤削除防止とデータ永続化のため

**解決策**:
```bash
# StatefulSet削除
kubectl delete statefulset postgres

# PVC確認（残っている）
kubectl get pvc

# 不要なら手動削除
kubectl delete pvc -l app=postgres

# またはスクリプトで一括削除
kubectl get pvc -o name | grep postgres | xargs kubectl delete
```

### 3. 起動順序の誤解

**問題**: 全Pod同時に起動すると思っていた

**説明**: 
- デフォルトでは順序保証（OrderedReady）
- 前のPodがReady状態になるまで次のPodは起動しない
- ReadinessProbeが重要

**確認方法**:
```bash
# Pod作成を監視
kubectl get pods -w

# イベント確認
kubectl get events --sort-by='.lastTimestamp'

# 並列起動したい場合
spec:
  podManagementPolicy: Parallel  # 追加
```

### 4. 更新戦略の理解不足

**問題**: イメージ更新しても古いPodが残る

**原因**: 
- updateStrategy.typeがOnDeleteの場合、手動削除が必要
- partitionが設定されている場合、その序数未満は更新されない

**確認と修正**:
```bash
# 現在の設定確認
kubectl get statefulset postgres -o yaml | grep -A5 updateStrategy

# RollingUpdateに変更
kubectl patch statefulset postgres -p '{"spec":{"updateStrategy":{"type":"RollingUpdate"}}}'

# partition確認
kubectl get statefulset postgres -o jsonpath='{.spec.updateStrategy.rollingUpdate.partition}'

# partition解除（全Pod更新）
kubectl patch statefulset postgres -p '{"spec":{"updateStrategy":{"rollingUpdate":{"partition":0}}}}'
```

### 5. ストレージクラスの選択ミス

**問題**: 性能が出ない、マルチアタッチエラーが出る

**原因**: 
- ReadWriteOnce（RWO）を使うべきなのにReadWriteMany（RWX）を使用
- ローカルストレージを使っているため再スケジュール時にPod起動失敗

**ベストプラクティス**:
```yaml
volumeClaimTemplates:
- metadata:
    name: data
  spec:
    accessModes: [ "ReadWriteOnce" ]  # StatefulSetはRWOが基本
    storageClassName: fast-ssd  # 性能要件に合わせて選択
    resources:
      requests:
        storage: 10Gi
```

```bash
# 利用可能なStorageClass確認
kubectl get storageclass

# デフォルトStorageClass確認
kubectl get storageclass -o jsonpath='{.items[?(@.metadata.annotations.storageclass\.kubernetes\.io/is-default-class=="true")].metadata.name}'

# StorageClassの詳細（provisioner確認）
kubectl describe storageclass standard
```

### 6. スケールダウン時のデータ損失

**問題**: レプリカ数を減らしたらデータが消えた

**原因**: 
- スケールダウンで削除されたPodのPVCは残るが、再度スケールアップしても別のPVCが作成される可能性

**安全な手順**:
```bash
# 現在の状態確認
kubectl get statefulset postgres
kubectl get pvc

# スケールダウン前にバックアップ
kubectl exec postgres-2 -- pg_dump -U postgres > backup.sql

# スケールダウン
kubectl scale statefulset postgres --replicas=2

# PVC確認（postgres-storage-postgres-2は残る）
kubectl get pvc

# 再スケールアップ
kubectl scale statefulset postgres --replicas=3
# → postgres-2は既存のPVCを再利用（データ保持）
```

### 7. ネットワーク分割（Split-brain）問題

**問題**: データベースレプリケーションで不整合が発生

**原因**: 
- Pod間通信断絶時の整合性保証が不十分
- Quorumベースの合意形成が未実装

**対策**:
```yaml
# PodDisruptionBudgetの設定
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: postgres-pdb
spec:
  minAvailable: 2  # 最低2台は常に稼働
  selector:
    matchLabels:
      app: postgres
```

```bash
# PDB確認
kubectl get pdb
kubectl describe pdb postgres-pdb

# ノードドレイン時のPod退避制御
kubectl drain node-1 --ignore-daemonsets --delete-emptydir-data
```

### 8. リソース制限未設定

**問題**: 1つのPodがリソースを独占してクラスタ全体に影響

**ベストプラクティス**:
```yaml
spec:
  template:
    spec:
      containers:
      - name: postgres
        resources:
          requests:
            memory: "1Gi"
            cpu: "500m"
          limits:
            memory: "2Gi"
            cpu: "1000m"
```

```bash
# リソース使用状況確認
kubectl top pods

# ノード全体のリソース
kubectl top nodes

# リソース不足によるEviction確認
kubectl describe pod postgres-0 | grep -i evict
```

これらのポイントを理解することで、StatefulSetを本番環境で安全に運用できるようになります！
