---
title: "【第3回】実践Kubernetes：ConfigMap・Secret・永続化とデバッグ完全ガイド"
draft: true
tags:
  - kubernetes
  - configmap
  - secret
  - persistent-volume
  - debugging
  - troubleshooting
description: "完結編。ConfigMap・Secret・永続化・デバッグを習得し本番運用に必要なKubernetesスキルを完成させる実践ガイド。"
---

[@nqounet](https://x.com/nqounet)です。

## シリーズ最終回：本番運用に必要な設定管理と永続化

Kubernetesシリーズもついに最終回を迎えました。

第1回ではMinikubeで爆速セットアップとデプロイを体験し、第2回ではYAMLマニフェストの仕組みを実験的に理解しました。

{{< linkcard "https://www.nqou.net/post/kubernetes-getting-started-minikube/" >}}

{{< linkcard "https://www.nqou.net/post/kubernetes-yaml-deployment-experiments/" >}}

今回は、本番運用に欠かせない**設定管理**、**データ永続化**、**デバッグ技術**を習得します。

**この記事で学べること：**
- ConfigMapによる設定の外部化と環境別管理
- Secretによる機密情報の安全な取り扱い
- PersistentVolumeによるデータ永続化の仕組み
- 実践的なデバッグ手法とログ確認
- トラブルシューティングのベストプラクティス
- Kubernetesシリーズ全体の総まとめ

**前提条件：**
- Minikubeがインストール済み
- 第1回・第2回の内容を理解している
- kubectl操作の基本を習得している

それでは、Kubernetes運用の実践的なスキルを身につけていきましょう！

## ConfigMap：設定を外部化して環境ごとに切り替える

アプリケーションを本番環境にデプロイする際、開発・ステージング・本番で異なる設定を使い分ける必要があります。

docker-composeでは`.env`ファイルで管理していましたが、Kubernetesでは**ConfigMap**を使います。

### なぜConfigMapが必要なのか？

**問題：** DeploymentのYAMLに直接環境変数を書くと、環境ごとにYAMLを複製する必要がある

```yaml
# 悪い例：環境変数をYAMLに直接記述
containers:
- name: webapp
  image: myapp:latest
  env:
  - name: DATABASE_HOST
    value: "db.prod.example.com"  # 本番用にハードコード
  - name: API_ENDPOINT
    value: "https://api.prod.example.com"
```

この方法では、開発環境用に別のYAMLを用意し、値を書き換える必要があります。

**解決策：** ConfigMapで設定を分離し、環境ごとにConfigMapだけを切り替える

### ConfigMapの作成方法3選

#### 方法1: コマンドラインから直接作成（クイック）

```bash
# 環境変数をkey-value形式で作成
kubectl create configmap webapp-config \
  --from-literal=DATABASE_HOST=localhost \
  --from-literal=API_ENDPOINT=http://localhost:8080 \
  --from-literal=LOG_LEVEL=debug

# 確認
kubectl get configmap webapp-config -o yaml
```

実行結果：

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: webapp-config
data:
  DATABASE_HOST: localhost
  API_ENDPOINT: http://localhost:8080
  LOG_LEVEL: debug
```

#### 方法2: 設定ファイルから作成（推奨）

```bash
# app.confファイルを作成
cat > app.conf << EOF
server.port=8080
database.maxConnections=100
cache.enabled=true
EOF

# ファイル全体をConfigMapに格納
kubectl create configmap webapp-fileconfig --from-file=app.conf

# 確認
kubectl describe configmap webapp-fileconfig
```

#### 方法3: YAMLマニフェストで定義（本番推奨）

```yaml
# configmap-webapp.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: webapp-config
  labels:
    app: webapp
    env: production
data:
  DATABASE_HOST: "db.prod.example.com"
  API_ENDPOINT: "https://api.prod.example.com"
  LOG_LEVEL: "info"
  FEATURE_FLAG_NEW_UI: "true"
  # 複数行の設定ファイルも格納可能
  nginx.conf: |
    server {
      listen 80;
      server_name example.com;
      location / {
        proxy_pass http://backend:8080;
      }
    }
```

```bash
kubectl apply -f configmap-webapp.yaml
```

### ConfigMapをDeploymentで使う

#### パターン1: 環境変数として注入

```yaml
# deployment-with-configmap.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: webapp
spec:
  replicas: 2
  selector:
    matchLabels:
      app: webapp
  template:
    metadata:
      labels:
        app: webapp
    spec:
      containers:
      - name: webapp
        image: nginx:latest
        # ConfigMapの全keyを環境変数として注入
        envFrom:
        - configMapRef:
            name: webapp-config
        # または、特定のkeyだけ個別に注入
        env:
        - name: DB_HOST
          valueFrom:
            configMapKeyRef:
              name: webapp-config
              key: DATABASE_HOST
```

```bash
kubectl apply -f deployment-with-configmap.yaml

# Podに環境変数が設定されたか確認
kubectl exec -it <pod-name> -- env | grep DATABASE_HOST
```

#### パターン2: ボリュームとしてマウント（設定ファイルとして利用）

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: webapp-volume
spec:
  replicas: 1
  selector:
    matchLabels:
      app: webapp-volume
  template:
    metadata:
      labels:
        app: webapp-volume
    spec:
      containers:
      - name: nginx
        image: nginx:latest
        volumeMounts:
        - name: config-volume
          mountPath: /etc/config  # ConfigMapの内容がファイルとして配置される
      volumes:
      - name: config-volume
        configMap:
          name: webapp-config
```

```bash
kubectl apply -f deployment-with-configmap.yaml

# マウントされたファイルを確認
kubectl exec -it <pod-name> -- ls -la /etc/config
kubectl exec -it <pod-name> -- cat /etc/config/nginx.conf
```

### 環境ごとの切り替え方法

```bash
# 開発環境用ConfigMap
kubectl create configmap webapp-config \
  --from-literal=DATABASE_HOST=localhost \
  --from-literal=LOG_LEVEL=debug

# 本番環境用ConfigMap（同じ名前で内容が異なる）
kubectl create configmap webapp-config \
  --from-literal=DATABASE_HOST=db.prod.example.com \
  --from-literal=LOG_LEVEL=info
```

**ポイント：**
- DeploymentのYAMLは変更不要
- ConfigMapだけを環境ごとに切り替える
- Infrastructure as Code（IaC）として管理しやすい

### ConfigMapの更新と反映

```bash
# ConfigMapを編集
kubectl edit configmap webapp-config

# またはYAMLファイルを更新して再適用
kubectl apply -f configmap-webapp.yaml

# Podを再起動して変更を反映（環境変数の場合）
kubectl rollout restart deployment webapp
```

**注意：** 環境変数として注入した場合、ConfigMap変更後にPodの再起動が必要です。ボリュームマウントの場合は自動的に反映されます（ただし、アプリケーションが設定ファイルをリロードする必要あり）。

## Secret：機密情報を安全に管理する

パスワード、APIキー、TLS証明書などの機密情報を**平文でConfigMapに入れてはいけません**。

Kubernetesでは、こうした情報を**Secret**として管理します。

### ConfigMapとSecretの違い

| 項目 | ConfigMap | Secret |
|------|----------|--------|
| **用途** | 一般的な設定値 | パスワード、トークン、証明書 |
| **エンコード** | 平文 | Base64エンコード（暗号化ではない） |
| **表示** | `kubectl get`で見える | デフォルトで隠される |
| **メモリ展開** | ディスクに書かれる | tmpfsメモリに展開（セキュア） |

**重要：** SecretはBase64エンコードされるだけで、暗号化されません。本番環境では追加の暗号化対策（KMS統合など）が必要です。

### Secretの作成方法

#### 方法1: コマンドラインから作成

```bash
# ユーザー名とパスワードをSecretとして作成
kubectl create secret generic db-credentials \
  --from-literal=username=admin \
  --from-literal=password=SuperSecret123

# 確認（値はBase64エンコードされている）
kubectl get secret db-credentials -o yaml
```

実行結果：

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: db-credentials
type: Opaque
data:
  username: YWRtaW4=         # "admin" のBase64
  password: U3VwZXJTZWNyZXQxMjM=  # "SuperSecret123" のBase64
```

#### 方法2: YAMLファイルで作成（注意：GitHubにpushしない）

```yaml
# secret-db.yaml
apiVersion: v1
kind: Secret
metadata:
  name: db-credentials
type: Opaque
stringData:  # stringDataを使えば平文で書ける（自動的にBase64化される）
  username: admin
  password: SuperSecret123
```

```bash
kubectl apply -f secret-db.yaml

# ⚠️ 注意：このYAMLファイルはGitリポジトリにコミットしないこと！
# .gitignoreに追加する
echo "secret-*.yaml" >> .gitignore
```

#### 方法3: ファイルからSecretを作成（TLS証明書など）

```bash
# SSH秘密鍵をSecretとして保存
kubectl create secret generic ssh-key \
  --from-file=ssh-privatekey=/path/to/.ssh/id_rsa \
  --from-file=ssh-publickey=/path/to/.ssh/id_rsa.pub

# TLS証明書をSecretとして保存
kubectl create secret tls tls-secret \
  --cert=/path/to/tls.crt \
  --key=/path/to/tls.key
```

### SecretをDeploymentで使う

#### パターン1: 環境変数として注入

```yaml
# deployment-with-secret.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: webapp-db
spec:
  replicas: 1
  selector:
    matchLabels:
      app: webapp-db
  template:
    metadata:
      labels:
        app: webapp-db
    spec:
      containers:
      - name: webapp
        image: mysql:8.0
        env:
        # Secretから環境変数を注入
        - name: MYSQL_ROOT_PASSWORD
          valueFrom:
            secretKeyRef:
              name: db-credentials
              key: password
        - name: MYSQL_USER
          valueFrom:
            secretKeyRef:
              name: db-credentials
              key: username
```

```bash
kubectl apply -f deployment-with-secret.yaml

# Pod内で環境変数を確認（実際の値が見える）
kubectl exec -it <pod-name> -- env | grep MYSQL
```

#### パターン2: ボリュームとしてマウント（証明書ファイルなど）

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: webapp-tls
spec:
  replicas: 1
  selector:
    matchLabels:
      app: webapp-tls
  template:
    metadata:
      labels:
        app: webapp-tls
    spec:
      containers:
      - name: nginx
        image: nginx:latest
        volumeMounts:
        - name: tls-certs
          mountPath: /etc/nginx/ssl
          readOnly: true  # 読み取り専用でマウント
      volumes:
      - name: tls-certs
        secret:
          secretName: tls-secret
```

### Secretの確認とデコード

```bash
# Secretの一覧
kubectl get secrets

# Secret詳細（Base64エンコード済み）
kubectl get secret db-credentials -o yaml

# 値をデコードして確認
kubectl get secret db-credentials -o jsonpath='{.data.password}' | base64 --decode
```

### 本番環境でのSecret管理ベストプラクティス

1. **Secretを直接YAMLに書かない**：CI/CDパイプラインで動的に作成
2. **外部シークレット管理ツールを使う**：HashiCorp Vault、AWS Secrets Manager、Azure Key Vault
3. **暗号化を有効にする**：Kubernetes Secrets Encryption at Rest
4. **RBAC（Role-Based Access Control）で権限制限**：誰がSecretを読めるかを厳密に管理

```bash
# Secretへのアクセス権限を制限する例（RBACの設定）
kubectl create role secret-reader \
  --verb=get,list \
  --resource=secrets

kubectl create rolebinding dev-secret-reader \
  --role=secret-reader \
  --user=developer@example.com
```

## PersistentVolume：データを永続化する

これまで見てきたPodは、削除されるとコンテナ内のデータも消えます。

データベースやファイルストレージなど、**データを永続化したい場合**はどうすればよいでしょうか？

### Kubernetes永続化の3つのコンポーネント

1. **PersistentVolume (PV)**：物理的なストレージリソース（管理者が用意）
2. **PersistentVolumeClaim (PVC)**：ユーザーがストレージを要求する申請書
3. **Pod**：PVCを通じてPVをマウントして使用

docker-composeの`volumes`に相当しますが、Kubernetesでは役割が分離されています。

### 実験：MySQLデータを永続化する

#### Step 1: PersistentVolumeClaimを作成

```yaml
# mysql-pvc.yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: mysql-pvc
spec:
  accessModes:
    - ReadWriteOnce  # 単一Podから読み書き
  resources:
    requests:
      storage: 1Gi  # 1GBのストレージを要求
```

```bash
kubectl apply -f mysql-pvc.yaml

# PVCの状態確認
kubectl get pvc
```

実行結果：

```
NAME        STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
mysql-pvc   Bound    pvc-abcd1234-5678-90ef-ghij-klmnopqrstuv   1Gi        RWO            standard       10s
```

**STATUS: Bound** = ストレージが確保された状態

Minikubeでは自動的にPersistentVolumeが作成されます（動的プロビジョニング）。

#### Step 2: MySQLデータベースをデプロイ

```yaml
# mysql-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mysql
spec:
  replicas: 1  # データベースは通常1レプリカ
  selector:
    matchLabels:
      app: mysql
  template:
    metadata:
      labels:
        app: mysql
    spec:
      containers:
      - name: mysql
        image: mysql:8.0
        env:
        - name: MYSQL_ROOT_PASSWORD
          valueFrom:
            secretKeyRef:
              name: db-credentials
              key: password
        ports:
        - containerPort: 3306
        volumeMounts:
        - name: mysql-storage
          mountPath: /var/lib/mysql  # MySQLのデータディレクトリ
      volumes:
      - name: mysql-storage
        persistentVolumeClaim:
          claimName: mysql-pvc  # 先ほど作成したPVCを使用
```

```bash
# Secretが存在しない場合は先に作成
kubectl create secret generic db-credentials \
  --from-literal=password=RootPassword123

# MySQLをデプロイ
kubectl apply -f mysql-deployment.yaml

# Pod起動を確認
kubectl get pods -l app=mysql
```

#### Step 3: データを書き込んで永続化を検証

```bash
# MySQLコンテナに接続
kubectl exec -it <mysql-pod-name> -- mysql -uroot -pRootPassword123

# MySQLコンソールでデータベースとテーブルを作成
CREATE DATABASE testdb;
USE testdb;
CREATE TABLE users (id INT, name VARCHAR(50));
INSERT INTO users VALUES (1, 'Alice'), (2, 'Bob');
SELECT * FROM users;
EXIT;
```

#### Step 4: Podを削除してデータ永続化を確認

```bash
# MySQLのPodを削除（強制的にクラッシュをシミュレート）
kubectl delete pod <mysql-pod-name>

# 新しいPodが自動作成される（Deploymentの自己修復機能）
kubectl get pods -l app=mysql

# 新しいPodで再度MySQLに接続
kubectl exec -it <new-mysql-pod-name> -- mysql -uroot -pRootPassword123

# データが残っているか確認
USE testdb;
SELECT * FROM users;
```

**実験結果：** Podは削除されたが、PersistentVolumeに保存されたデータは残っている！

### AccessModeの種類と使い分け

| AccessMode | 略称 | 説明 | 用途 |
|-----------|-----|------|------|
| **ReadWriteOnce** | RWO | 単一ノードから読み書き | MySQL、PostgreSQLなど |
| **ReadOnlyMany** | ROX | 複数ノードから読み取り専用 | 静的コンテンツ配信 |
| **ReadWriteMany** | RWX | 複数ノードから読み書き | 共有ファイルシステム（NFS） |

**注意：** Minikubeのデフォルトストレージは`ReadWriteOnce`のみサポート。クラウド環境（EBS、Azure Disk）も多くがRWOのみです。

### PersistentVolumeとPVCのライフサイクル

```bash
# PVCを削除
kubectl delete pvc mysql-pvc

# PVの状態を確認
kubectl get pv
```

**デフォルト動作：** PVCを削除すると、紐づいていたPVも削除される（reclaimPolicy: Delete）

本番環境では`Retain`に設定してデータを保護することも可能。

### StatefulSetによる永続化（高度なトピック）

データベースのような**ステートフルなアプリケーション**には、`Deployment`ではなく`StatefulSet`を使うのがベストプラクティスです。

```yaml
# mysql-statefulset.yaml（参考）
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: mysql
spec:
  serviceName: mysql
  replicas: 1
  selector:
    matchLabels:
      app: mysql
  template:
    metadata:
      labels:
        app: mysql
    spec:
      containers:
      - name: mysql
        image: mysql:8.0
        env:
        - name: MYSQL_ROOT_PASSWORD
          valueFrom:
            secretKeyRef:
              name: db-credentials
              key: password
        volumeMounts:
        - name: mysql-storage
          mountPath: /var/lib/mysql
  volumeClaimTemplates:  # StatefulSet専用：Pod毎に個別PVCを自動作成
  - metadata:
      name: mysql-storage
    spec:
      accessModes: [ "ReadWriteOnce" ]
      resources:
        requests:
          storage: 1Gi
```

**StatefulSetの特徴：**
- Podに安定した名前（`mysql-0`、`mysql-1`など）
- 順序付きのデプロイとスケーリング
- 各Pod専用のPersistentVolumeを自動作成

本格的なデータベース運用では`StatefulSet` + `PersistentVolume`の組み合わせを推奨します。

## 実践デバッグ：ログ確認とトラブルシューティング

本番運用では、必ず問題が発生します。迅速に原因を特定し、解決するためのデバッグ手法を身につけましょう。

### デバッグの基本フロー

```
1. 症状を確認（何が起きているか）
   ↓
2. リソースの状態をチェック（Pod、Service、Deploymentなど）
   ↓
3. イベントログを確認（何が原因か）
   ↓
4. コンテナログを確認（アプリケーションレベルのエラー）
   ↓
5. Pod内で直接調査（exec）
```

### レベル1: リソースの状態確認

```bash
# すべてのリソースを一覧表示
kubectl get all

# Pod一覧（状態を確認）
kubectl get pods

# よくある状態
# Running        - 正常稼働中
# Pending        - 起動待ち（イメージダウンロード中、リソース不足など）
# CrashLoopBackOff - 起動に失敗して再起動を繰り返している
# ImagePullBackOff - Dockerイメージの取得に失敗
# Error          - エラー終了
# Completed      - 正常終了（Jobなど）
```

### レベル2: 詳細情報とイベント確認

```bash
# Podの詳細を確認（最も重要なコマンド）
kubectl describe pod <pod-name>

# 出力の見方：
# - Conditions: Podの状態遷移
# - Events: 最近の出来事（エラーの原因がここに書かれる）
# - Containers.State: コンテナの現在の状態
```

**Eventsセクションの例：**

```
Events:
  Type     Reason     Age   From               Message
  ----     ------     ----  ----               -------
  Warning  Failed     30s   kubelet            Failed to pull image "nginx:invalid"
  Warning  BackOff    15s   kubelet            Back-off pulling image "nginx:invalid"
```

→ イメージ名が間違っている（`nginx:invalid`は存在しない）

### レベル3: コンテナログの確認

```bash
# Podのログを表示
kubectl logs <pod-name>

# 複数コンテナがある場合はコンテナ名を指定
kubectl logs <pod-name> -c <container-name>

# リアルタイムでログを追跡（tail -f相当）
kubectl logs -f <pod-name>

# 過去に失敗したPodのログを確認
kubectl logs <pod-name> --previous

# 最新100行だけ表示
kubectl logs <pod-name> --tail=100

# タイムスタンプ付きで表示
kubectl logs <pod-name> --timestamps
```

**実践例：アプリケーションエラーの特定**

```bash
# MySQLの起動エラーを確認
kubectl logs mysql-7b9f8c6d4-xk2p9

# 出力例：
# [ERROR] [MY-010735] [Server] Can't open the mysql.plugin table.
# [ERROR] [MY-010735] [Server] Plugin 'InnoDB' init function returned error.
```

→ データディレクトリの権限問題やディスク容量不足の可能性

### レベル4: Pod内で直接デバッグ

```bash
# Pod内でbashシェルを起動
kubectl exec -it <pod-name> -- /bin/bash

# コンテナ内でデバッグコマンドを実行
kubectl exec <pod-name> -- ls -la /var/lib/mysql
kubectl exec <pod-name> -- df -h
kubectl exec <pod-name> -- ps aux
kubectl exec <pod-name> -- cat /etc/hosts

# ネットワーク疎通確認
kubectl exec <pod-name> -- curl http://other-service:8080
kubectl exec <pod-name> -- ping other-service
```

**一時的なデバッグPodを起動する（ネットワーク診断）**

```bash
# curlやnslookupが入ったデバッグ用Pod
kubectl run debug-pod --image=nicolaka/netshoot -it --rm -- /bin/bash

# Pod内から他のServiceへ接続テスト
curl http://nginx-service:80
nslookup nginx-service
```

### よくあるトラブルと解決方法

#### トラブル1: ImagePullBackOff

**症状：**

```bash
kubectl get pods
# NAME                     READY   STATUS             RESTARTS   AGE
# webapp-7fb96c846b-xk2p9  0/1     ImagePullBackOff   0          2m
```

**原因と対処：**

```bash
kubectl describe pod webapp-7fb96c846b-xk2p9

# Events:
# Failed to pull image "nginx:invalidtag": rpc error: code = Unknown
```

**解決策：**
- イメージ名・タグのスペルミスを修正
- プライベートレジストリの場合、認証Secretを設定

```bash
# DockerHub認証Secretを作成
kubectl create secret docker-registry regcred \
  --docker-server=https://index.docker.io/v1/ \
  --docker-username=myuser \
  --docker-password=mypassword

# DeploymentでSecretを指定
spec:
  template:
    spec:
      imagePullSecrets:
      - name: regcred
```

#### トラブル2: CrashLoopBackOff

**症状：**

```bash
kubectl get pods
# NAME                     READY   STATUS             RESTARTS   AGE
# mysql-7b9f8c6d4-xk2p9    0/1     CrashLoopBackOff   5          3m
```

**原因と対処：**

```bash
# 前回のログを確認（コンテナが起動に失敗した原因）
kubectl logs mysql-7b9f8c6d4-xk2p9 --previous

# 出力例：
# Error: Database is uninitialized and password option is not specified
```

**解決策：** 必須環境変数が設定されていない → Secretを確認・追加

```bash
# Secretが存在するか確認
kubectl get secret db-credentials

# なければ作成
kubectl create secret generic db-credentials \
  --from-literal=password=RootPassword123
```

#### トラブル3: Pending（リソース不足）

**症状：**

```bash
kubectl get pods
# NAME                     READY   STATUS    RESTARTS   AGE
# webapp-7fb96c846b-xk2p9  0/1     Pending   0          5m
```

**原因と対処：**

```bash
kubectl describe pod webapp-7fb96c846b-xk2p9

# Events:
# 0/1 nodes are available: 1 Insufficient memory.
```

**解決策：**
- リソース要求を減らす
- ノードを追加（クラウド環境）
- 他のPodを削除してリソースを解放

```yaml
# リソース要求を適切に設定
resources:
  requests:
    memory: "256Mi"
    cpu: "200m"
  limits:
    memory: "512Mi"
    cpu: "500m"
```

#### トラブル4: Service経由でアクセスできない

**症状：** Podは`Running`だが、ブラウザでアクセスできない

**原因と対処：**

```bash
# Serviceが存在するか確認
kubectl get svc

# Serviceの詳細とエンドポイント確認
kubectl describe svc nginx-service

# Endpoints欄を確認
# Endpoints: 10.244.0.5:80,10.244.0.6:80
# → Podが正しく紐づいている

# Endpoints: <none>
# → ラベルセレクタが一致していない
```

**解決策：** ServiceのselectorとPodのlabelsを一致させる

```yaml
# Service
spec:
  selector:
    app: nginx  # ← ここと

# Deployment
template:
  metadata:
    labels:
      app: nginx  # ← ここが一致しているか確認
```

### デバッグコマンド一覧（まとめ）

```bash
# 基本確認
kubectl get pods
kubectl get all
kubectl get events --sort-by='.lastTimestamp'

# 詳細情報
kubectl describe pod <pod-name>
kubectl describe service <service-name>
kubectl describe deployment <deployment-name>

# ログ確認
kubectl logs <pod-name>
kubectl logs -f <pod-name>  # リアルタイム
kubectl logs <pod-name> --previous  # 前回起動時

# Pod内調査
kubectl exec -it <pod-name> -- /bin/bash
kubectl exec <pod-name> -- <command>

# ネットワーク診断
kubectl run debug --image=nicolaka/netshoot -it --rm -- /bin/bash

# リソース使用状況
kubectl top nodes
kubectl top pods

# 設定確認
kubectl get pod <pod-name> -o yaml
kubectl get deployment <deployment-name> -o yaml
```

## Kubernetes運用のベストプラクティス

シリーズを通じて学んだKubernetesの知識を本番環境で活かすため、運用のベストプラクティスをまとめます。

### 1. リソース制限を必ず設定する

```yaml
resources:
  requests:  # 最低限必要なリソース（スケジューリングの基準）
    memory: "256Mi"
    cpu: "200m"
  limits:    # 上限（これを超えるとPodが停止される）
    memory: "512Mi"
    cpu: "500m"
```

**なぜ重要？**
- requests未設定 → ノードリソース枯渇のリスク
- limits未設定 → 1つのPodが全リソースを消費し他に影響

### 2. ヘルスチェックを設定する

```yaml
livenessProbe:  # Podが生きているか（死んだら再起動）
  httpGet:
    path: /healthz
    port: 8080
  initialDelaySeconds: 30
  periodSeconds: 10

readinessProbe:  # トラフィックを受け入れられるか
  httpGet:
    path: /ready
    port: 8080
  initialDelaySeconds: 5
  periodSeconds: 5
```

**なぜ重要？**
- livenessProbe：アプリがフリーズしても自動復旧
- readinessProbe：起動中のPodにトラフィックを送らない

### 3. 本番環境では必ずNamespaceで分離

```bash
# 環境別Namespaceを作成
kubectl create namespace production
kubectl create namespace staging
kubectl create namespace development

# 特定Namespace内にデプロイ
kubectl apply -f deployment.yaml -n production

# デフォルトNamespaceを切り替え
kubectl config set-context --current --namespace=production
```

### 4. ラベルを活用した管理

```yaml
metadata:
  labels:
    app: webapp
    version: v1.2.3
    environment: production
    team: backend
```

```bash
# ラベルで絞り込み
kubectl get pods -l app=webapp
kubectl get pods -l environment=production,team=backend

# ラベルを後から追加
kubectl label pod <pod-name> tier=frontend
```

### 5. YAML管理とGit運用

```bash
# YAMLをGitで管理
git init
git add deployment.yaml service.yaml configmap.yaml
git commit -m "Initial Kubernetes manifests"

# ⚠️ Secretは含めない
echo "secret-*.yaml" >> .gitignore
echo "*.key" >> .gitignore
echo "*.crt" >> .gitignore
```

**推奨ディレクトリ構造：**

```
k8s/
├── base/              # 共通設定
│   ├── deployment.yaml
│   └── service.yaml
├── overlays/
│   ├── production/    # 本番環境固有
│   │   └── configmap.yaml
│   └── staging/       # ステージング環境固有
│       └── configmap.yaml
└── README.md
```

### 6. CI/CDパイプラインでデプロイ自動化

```yaml
# GitHub Actionsの例（.github/workflows/deploy.yaml）
name: Deploy to Kubernetes
on:
  push:
    branches: [main]
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    - name: Set up kubectl
      uses: azure/setup-kubectl@v3
    - name: Deploy
      run: |
        kubectl apply -f k8s/deployment.yaml
        kubectl rollout status deployment/webapp
```

## シリーズ総まとめ：3回で学んだこと

Kubernetesシリーズ全3回を通じて、以下のスキルを習得しました。

### 第1回：Minikubeで爆速セットアップ

- ✅ ローカルKubernetes環境（Minikube）のセットアップ
- ✅ 3コマンドでNginxデプロイ
- ✅ Komposeでdocker-compose.yml変換
- ✅ Pod、Deployment、Serviceの基本理解

**学び：** docker-composeと同じくらい簡単にKubernetesでアプリを動かせる

### 第2回：YAMLマニフェストの実験

- ✅ DeploymentのYAML構造を理解
- ✅ レプリカ数変更でスケーリング体験
- ✅ Podを削除して自己修復機能を確認
- ✅ Serviceの3つのタイプ（ClusterIP、NodePort、LoadBalancer）
- ✅ ローリングアップデートで無停止更新

**学び：** 宣言的設定の威力。YAMLで「あるべき姿」を書くだけでKubernetesが調整してくれる

### 第3回：設定管理・永続化・デバッグ（本記事）

- ✅ ConfigMapで設定を外部化・環境別管理
- ✅ Secretで機密情報を安全に扱う
- ✅ PersistentVolumeでデータ永続化
- ✅ 実践的なデバッグ手法とログ確認
- ✅ トラブルシューティングのベストプラクティス
- ✅ 本番運用のための設計パターン

**学び：** 本番環境で必要な設定管理、データ保護、障害対応のスキル

### docker-composeとKubernetesの対応表（復習）

| docker-compose | Kubernetes | 役割 |
|---------------|-----------|------|
| `service` | `Deployment` + `Pod` | アプリケーション実行 |
| `ports` | `Service` | ポート公開 |
| `volumes` | `PersistentVolume` + `PVC` | データ永続化 |
| `environment` | `ConfigMap` / `Secret` | 環境変数設定 |
| `depends_on` | `initContainers` / `readinessProbe` | 起動順序制御 |
| `.env`ファイル | `ConfigMap` | 設定ファイル |

### 次のステップ：さらに学ぶために

Kubernetesの世界は広大です。このシリーズで基礎は身につきましたが、以下のトピックも学ぶことでより実践的なスキルが得られます。

**中級者向けトピック：**
- **Ingress**：複数Serviceを1つのエントリポイントで公開
- **Helm**：Kubernetesのパッケージマネージャ（テンプレート化）
- **Horizontal Pod Autoscaler (HPA)**：負荷に応じた自動スケーリング
- **Network Policy**：Pod間通信の制御（セキュリティ強化）
- **RBAC（Role-Based Access Control）**：権限管理

**上級者向けトピック：**
- **Operator Pattern**：カスタムリソースによるアプリケーション自動化
- **Service Mesh（Istio、Linkerd）**：マイクロサービスの高度なネットワーク制御
- **Multi-cluster Management**：複数Kubernetesクラスタの統合管理
- **GitOps（ArgoCD、Flux）**：Gitを真実の情報源とした自動デプロイ

**公式ドキュメント：**

{{< linkcard "https://kubernetes.io/ja/docs/home/" >}}

{{< linkcard "https://kubernetes.io/ja/docs/concepts/" >}}

**Kubernetesコミュニティ：**

- Kubernetes Slack: https://slack.k8s.io/
- KubeCon（年次カンファレンス）
- CNCF（Cloud Native Computing Foundation）

## おわりに：Kubernetesの旅はここから始まる

3回のシリーズを通じて、Kubernetesの基礎から実践的な運用スキルまでを習得しました。

docker-composeで簡単にコンテナを管理していた世界から、スケーラブルで自己修復可能なKubernetesの世界へ——最初は複雑に感じたかもしれません。

しかし、YAMLを書き、実験し、トラブルを解決する中で、Kubernetesが提供する**宣言的設定**、**自己修復**、**スケーラビリティ**の本当の価値が理解できたのではないでしょうか。

**本番環境でKubernetesを使う準備が整いました。**

次はあなたの実際のアプリケーションをKubernetesにデプロイしてみてください。

小さく始めて、徐々に機能を追加していく——それがKubernetes習得の近道です。

**このシリーズが、あなたのKubernetes学習の第一歩として役立ったなら幸いです。**

何か困ったことがあれば、[@nqounet](https://x.com/nqounet)までお気軽にどうぞ。

Happy Kubernetes learning! 🚀

---

**シリーズ全記事：**

{{< linkcard "https://www.nqou.net/post/kubernetes-getting-started-minikube/" >}}

{{< linkcard "https://www.nqou.net/post/kubernetes-yaml-deployment-experiments/" >}}

**関連記事：**

{{< linkcard "https://www.nqou.net/2017/12/03/025713/" >}}
