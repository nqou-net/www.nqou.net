---
title: "【2025年版】docker-composeからKubernetesへ移行 - ローカル開発環境構築ガイド"
draft: true
tags:
  - kubernetes
  - minikube
  - docker-compose
  - kubectl
  - container
  - local-development
  - devops
  - infrastructure-as-code
description: "docker-composeユーザー向けのKubernetes入門ガイド。2025年最新のMinikubeでローカル開発環境を構築し、Web+DB構成の既存アプリを移行する実践的な手順を解説。kubectl基本操作からトラブルシューティングまで網羅。"
---

## はじめに

[@nqounet](https://x.com/nqounet)です。

Dockerとdocker-composeで快適に開発していたあなた。Kubernetesという言葉は何度も耳にしたけれど、「難しそう」「本番環境の話でしょ?」と敬遠していませんか？

実は、Kubernetesはローカル開発環境でも十分に活用できます。そして2025年の今、ローカルでKubernetesを使うためのツールやドキュメントは大幅に充実しています。

以前、[ローカルでの開発は docker-compose を使うと楽だった](https://www.nqou.net/2017/12/03/025713/)という記事を書きましたが、それから約8年。コンテナオーケストレーションの世界は大きく進化しました。本記事では、docker-composeの知識をベースに、Kubernetesへステップアップする方法を実践的に解説します。

**この記事で学べること:**

- docker-composeとKubernetesの本質的な違い
- 2025年時点でのローカルKubernetes環境の選択肢
- Minikubeを使った実践的な環境構築
- 具体的なアプリケーション（Web + DB構成）の移行手順
- よくあるトラブルとその解決方法

## docker-composeとKubernetesの違いを理解する

まず、docker-composeとKubernetesの根本的な違いを理解しましょう。

### docker-composeの世界観

docker-composeは、複数のDockerコンテナをまとめて管理するためのツールです。`docker-compose.yml`に定義を書けば、`docker-compose up`一発で全てのコンテナが起動します。

```yaml
version: "3.8"
services:
  web:
    image: nginx:latest
    ports:
      - "8080:80"
  db:
    image: postgres:15
    environment:
      POSTGRES_PASSWORD: password
```

シンプルで直感的。開発環境には最適です。

### Kubernetesの世界観

一方、Kubernetesは**コンテナオーケストレーションプラットフォーム**です。単にコンテナを起動するだけでなく、以下のような高度な機能を提供します：

- **自己修復**: コンテナが落ちたら自動的に再起動
- **スケーリング**: 負荷に応じてコンテナ数を自動調整
- **ロードバランシング**: 複数のコンテナへトラフィックを分散
- **ローリングアップデート**: ダウンタイムなしでアプリを更新
- **シークレット管理**: 機密情報を安全に管理

**主な概念の対比:**

| docker-compose | Kubernetes | 説明 |
|----------------|------------|------|
| サービス | Deployment + Service | アプリケーションの実行単位 |
| コンテナ | Pod | 最小実行単位（1つ以上のコンテナ） |
| ボリューム | PersistentVolume | データの永続化 |
| ネットワーク | Service + Ingress | コンテナ間通信、外部公開 |

Kubernetesは確かに複雑ですが、その複雑さは**本番環境で必要な機能**を提供するためのものです。ローカル開発では、その一部を理解するだけで十分活用できます。

## ローカル開発環境の選択肢（2025年版）

2025年現在、ローカルでKubernetesを動かす選択肢はいくつかあります：

### 1. Minikube（推奨）

- **特徴**: 最も歴史が長く、安定している
- **対応OS**: Windows, macOS, Linux
- **リソース**: 比較的軽量
- **学習曲線**: 緩やか
- **本記事での採用理由**: 汎用性が高く、初心者に最適

{{< linkcard "https://minikube.sigs.k8s.io/" >}}

### 2. kind (Kubernetes IN Docker)

- **特徴**: DockerコンテナでKubernetesクラスタを作成
- **対応OS**: Windows, macOS, Linux
- **リソース**: 非常に軽量
- **学習曲線**: やや急
- **向いている人**: CI/CDパイプラインでの自動テスト

{{< linkcard "https://kind.sigs.k8s.io/" >}}

### 3. Docker Desktop（Kubernetes有効化）

- **特徴**: Docker Desktopに統合されたKubernetes
- **対応OS**: Windows, macOS
- **リソース**: やや重い
- **学習曲線**: 緩やか
- **注意点**: ライセンス条件を確認する必要あり

### 4. Rancher Desktop

- **特徴**: Docker Desktopの代替として人気
- **対応OS**: Windows, macOS, Linux
- **リソース**: 中程度
- **学習曲線**: 緩やか
- **メリット**: オープンソースで無料

{{< linkcard "https://rancherdesktop.io/" >}}

**本記事ではMinikubeを使用します。** 理由は、Kubernetesの公式ツールとして広くサポートされており、学習リソースが豊富だからです。

## Minikubeのインストールと初期設定

それでは、実際にMinikubeをインストールしましょう。

### 前提条件

- Docker Desktop、または他のコンテナランタイムがインストール済み
- メモリ: 最低2GB、推奨4GB以上
- ディスク空き容量: 20GB以上

### macOSでのインストール

```bash
# Homebrewを使ってインストール
brew install minikube

# インストール確認
minikube version
```

Homebrewを使えば、依存関係も自動的に解決される。

### Windowsでのインストール

```powershell
# Chocolateyを使う場合
choco install minikube
```

または、公式サイトからインストーラーをダウンロードして実行する方法もある。

{{< linkcard "https://minikube.sigs.k8s.io/docs/start/" >}}

### Linuxでのインストール

```bash
# 最新版をダウンロード
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube

# インストール確認
minikube version
```

バイナリを直接ダウンロードしてインストールする方式である。

### Minikubeクラスタの起動

```bash
# Dockerドライバーでクラスタを作成
minikube start --driver=docker

# メモリやCPUを指定する場合
minikube start --driver=docker --memory=4096 --cpus=2
```

初回起動時は、Kubernetesのイメージをダウンロードするため、数分かかる。

```text
😄  minikube v1.33.0 on Darwin 14.5
✨  Using the docker driver based on user configuration
👍  Starting control plane node minikube in cluster minikube
🚜  Pulling base image ...
🔥  Creating docker container (CPUs=2, Memory=4096MB) ...
🐳  Preparing Kubernetes v1.30.0 on Docker 26.1.1 ...
🔎  Verifying Kubernetes components...
🌟  Enabled addons: storage-provisioner, default-storageclass
🏄  Done! kubectl is now configured to use "minikube" cluster
```

上記のような出力が表示されれば、起動成功である。

### kubectlのインストール

`kubectl`はKubernetesを操作するためのコマンドラインツールです。

```bash
# macOS
brew install kubectl

# Windows (Chocolatey)
choco install kubernetes-cli

# Linux
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
```

### 接続確認

```bash
# クラスタの状態確認
kubectl cluster-info

# ノード一覧表示
kubectl get nodes
```

正常に動作していれば、以下のような出力が得られる。

```text
NAME       STATUS   ROLES           AGE   VERSION
minikube   Ready    control-plane   2m    v1.30.0
```

`STATUS`が`Ready`になっていれば、クラスタは正常に動作している。

## kubectlの基本操作を学ぶ

Kubernetesを操作する上で、`kubectl`コマンドは必須です。docker-composeと対比しながら基本操作を学びましょう。

### リソースの確認

```bash
# 全てのPodを表示（docker ps相当）
kubectl get pods

# 全てのServiceを表示
kubectl get services

# 全てのDeploymentを表示
kubectl get deployments

# 複数のリソースを一度に表示
kubectl get pods,services,deployments

# より詳細な情報を表示
kubectl get pods -o wide
```

### リソースの詳細確認

```bash
# Podの詳細情報を表示（docker inspect相当）
kubectl describe pod <pod-name>

# Deploymentの詳細情報
kubectl describe deployment <deployment-name>
```

### ログの確認

```bash
# Podのログを表示（docker logs相当）
kubectl logs <pod-name>

# リアルタイムでログを追跡
kubectl logs -f <pod-name>

# 過去1時間のログを表示
kubectl logs --since=1h <pod-name>
```

### コンテナへの接続

```bash
# Podの中に入る（docker exec相当）
kubectl exec -it <pod-name> -- /bin/bash

# 特定のコンテナを指定する場合
kubectl exec -it <pod-name> -c <container-name> -- /bin/bash
```

### リソースの削除

```bash
# Podを削除
kubectl delete pod <pod-name>

# Deploymentを削除
kubectl delete deployment <deployment-name>

# YAMLファイルで定義したリソースを削除
kubectl delete -f myapp.yaml
```

### よく使うショートカット

kubectlには便利なエイリアスがある。

| 短縮形 | フル表記 |
|--------|----------|
| `po` | `pods` |
| `svc` | `services` |
| `deploy` | `deployments` |
| `ns` | `namespaces` |

```bash
# これらは同じ意味
kubectl get pods
kubectl get po
```

短縮形を覚えておくと、コマンド入力が効率的になる。

### YAML形式でのリソース確認

```bash
# リソースの定義をYAML形式で出力
kubectl get pod <pod-name> -o yaml

# 実行中のDeploymentからYAMLを生成
kubectl get deployment <deployment-name> -o yaml > deployment.yaml
```

これは既存リソースからYAML定義を学ぶのに便利です。

## 実践: docker-composeアプリをKubernetesに移行する

それでは、実際のアプリケーションをdocker-composeからKubernetesへ移行してみましょう。

### サンプルアプリケーションの構成

以下のような、Webアプリ + PostgreSQLデータベースという典型的な構成を例にします。

**元のdocker-compose.yml:**

```yaml
version: "3.8"
services:
  web:
    image: nginx:1.25-alpine
    ports:
      - "8080:80"
    volumes:
      - ./html:/usr/share/nginx/html
    depends_on:
      - db
    environment:
      - DB_HOST=db
      - DB_PORT=5432
  
  db:
    image: postgres:15-alpine
    environment:
      POSTGRES_DB: myapp
      POSTGRES_USER: myuser
      POSTGRES_PASSWORD: mypassword
    volumes:
      - pgdata:/var/lib/postgresql/data
    ports:
      - "5432:5432"

volumes:
  pgdata:
```

これをKubernetesに移行していきます。

### Step 1: Podを作成する

まず最もシンプルな形として、Podを直接作成してみます。

**nginx-pod.yaml:**

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx-pod
  labels:
    app: nginx
spec:
  containers:
  - name: nginx
    image: nginx:1.25-alpine
    ports:
    - containerPort: 80
    env:
    - name: DB_HOST
      value: "postgres-pod"
    - name: DB_PORT
      value: "5432"
```

**postgres-pod.yaml:**

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: postgres-pod
  labels:
    app: postgres
spec:
  containers:
  - name: postgres
    image: postgres:15-alpine
    ports:
    - containerPort: 5432
    env:
    - name: POSTGRES_DB
      value: "myapp"
    - name: POSTGRES_USER
      value: "myuser"
    - name: POSTGRES_PASSWORD
      value: "mypassword"
```

適用してみましょう：

```bash
# Podを作成
kubectl apply -f nginx-pod.yaml
kubectl apply -f postgres-pod.yaml

# Podの状態を確認
kubectl get pods

# 詳細を確認
kubectl describe pod nginx-pod
```

**しかし、これには問題がある。**

1. Podは一時的なものであり、削除されたら終わり
2. 自動的に再起動されない
3. スケーリングできない

そこで、**Deployment**を使う。

### Step 2: Deploymentで管理する

Deploymentは、Podのライフサイクルを管理し、自己修復機能を提供します。

**nginx-deployment.yaml:**

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
spec:
  replicas: 2  # Podを2つ起動
  selector:
    matchLabels:
      app: nginx
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:1.25-alpine
        ports:
        - containerPort: 80
        env:
        - name: DB_HOST
          value: "postgres-service"  # 後で作成するServiceの名前
        - name: DB_PORT
          value: "5432"
        resources:
          requests:
            memory: "64Mi"
            cpu: "100m"
          limits:
            memory: "128Mi"
            cpu: "200m"
```

**postgres-deployment.yaml:**

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: postgres-deployment
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
        ports:
        - containerPort: 5432
        env:
        - name: POSTGRES_DB
          value: "myapp"
        - name: POSTGRES_USER
          value: "myuser"
        - name: POSTGRES_PASSWORD
          value: "mypassword"
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
```

まず、既存のPodを削除してから、Deploymentを作成する。

```bash
# 古いPodを削除
kubectl delete pod nginx-pod postgres-pod

# Deploymentを作成
kubectl apply -f nginx-deployment.yaml
kubectl apply -f postgres-deployment.yaml

# 状態確認
kubectl get deployments
kubectl get pods
```

Deploymentによって管理されたPodは、名前の末尾にランダムな文字列が付く。

```text
NAME                                   READY   STATUS    RESTARTS   AGE
nginx-deployment-7d6b8c5f9d-abc12      1/1     Running   0          30s
nginx-deployment-7d6b8c5f9d-def34      1/1     Running   0          30s
postgres-deployment-6c8d9b7f5a-xyz78   1/1     Running   0          30s
```

この命名規則により、複数のレプリカが管理される。

試しに、Podを削除してみる。

```bash
# 1つのPodを削除
kubectl delete pod nginx-deployment-7d6b8c5f9d-abc12

# すぐに確認
kubectl get pods
```

**Deploymentが自動的に新しいPodを起動する。** これが自己修復機能である。

### Step 3: Serviceで通信を確立する

現状では、Podはまだ外部からアクセスできません。また、Nginx PodからPostgreSQL Podへの通信も不安定です（PodのIPアドレスは変動するため）。

**Service**を使って、安定したネットワーク接続を確立する。

**postgres-service.yaml:**

```yaml
apiVersion: v1
kind: Service
metadata:
  name: postgres-service
spec:
  selector:
    app: postgres
  ports:
  - protocol: TCP
    port: 5432
    targetPort: 5432
  type: ClusterIP  # クラスタ内部からのみアクセス可能
```

**nginx-service.yaml:**

```yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
spec:
  selector:
    app: nginx
  ports:
  - protocol: TCP
    port: 80
    targetPort: 80
  type: NodePort  # 外部からアクセス可能にする
```

適用する。

```bash
kubectl apply -f postgres-service.yaml
kubectl apply -f nginx-service.yaml

# Service一覧を確認
kubectl get services
```

出力例は以下の通りである。

```text
NAME               TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)        AGE
kubernetes         ClusterIP   10.96.0.1       <none>        443/TCP        1h
postgres-service   ClusterIP   10.96.123.45    <none>        5432/TCP       10s
nginx-service      NodePort    10.96.234.56    <none>        80:30123/TCP   10s
```

`nginx-service`の`PORT(S)`欄に`80:30123/TCP`と表示されており、ノードポート30123番で外部からアクセス可能になっている。

**Serviceのタイプ:**

- `ClusterIP`: クラスタ内部からのみアクセス可能（デフォルト）
- `NodePort`: ノードのIPアドレス + ポート番号でアクセス可能
- `LoadBalancer`: クラウド環境でロードバランサーを作成（ローカルでは使用不可）

### 外部からアクセスする

MinikubeでNodePort Serviceにアクセスするには、専用のコマンドを使う。

```bash
# Serviceのエンドポイントを取得
minikube service nginx-service --url
```

このコマンドで表示されるURLにブラウザでアクセスすれば、Nginxの画面が見える。

または、ポートフォワーディングを使う方法もある。

```bash
# ローカルの8080ポートをnginx-serviceの80ポートに転送
kubectl port-forward service/nginx-service 8080:80
```

これで`http://localhost:8080`でアクセスできる。

### クラスタ内部での名前解決

Kubernetesでは、ServiceはDNS名でアクセスできる。同じNamespace内では、Service名がそのままホスト名になる。

```text
# nginx Podから postgres-service に接続できる
postgres-service:5432
```

これにより、nginx-deployment.yamlで指定した環境変数`DB_HOST=postgres-service`が機能する。

### Step 4: データの永続化

現状では、PostgreSQL Podが再起動するとデータが消えてしまう。**PersistentVolume（PV）**と**PersistentVolumeClaim（PVC）**を使ってデータを永続化する。

**postgres-pvc.yaml:**

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: postgres-pvc
spec:
  accessModes:
    - ReadWriteOnce  # 1つのノードから読み書き可能
  resources:
    requests:
      storage: 1Gi  # 1GBのストレージを要求
```

**postgres-deployment.yaml（更新版）:**

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: postgres-deployment
spec:
  replicas: 1
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
        env:
        - name: POSTGRES_DB
          value: "myapp"
        - name: POSTGRES_USER
          value: "myuser"
        - name: POSTGRES_PASSWORD
          value: "mypassword"
        volumeMounts:
        - name: postgres-storage
          mountPath: /var/lib/postgresql/data
          subPath: postgres  # データディレクトリの競合を避ける
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
      volumes:
      - name: postgres-storage
        persistentVolumeClaim:
          claimName: postgres-pvc
```

適用する。

```bash
# PVCを作成
kubectl apply -f postgres-pvc.yaml

# PVCの状態確認
kubectl get pvc

# Deploymentを更新
kubectl apply -f postgres-deployment.yaml
```

これで、PostgreSQL Podが再起動してもデータが保持されるようになった。

**確認方法は以下の通りである。**

```bash
# PostgreSQL Podに接続
kubectl exec -it $(kubectl get pod -l app=postgres -o jsonpath='{.items[0].metadata.name}') -- psql -U myuser -d myapp

# テーブルを作成
CREATE TABLE test (id SERIAL PRIMARY KEY, name TEXT);
INSERT INTO test (name) VALUES ('Kubernetes');

# Podを削除して再作成
kubectl delete pod -l app=postgres

# 再度接続してデータを確認
kubectl exec -it $(kubectl get pod -l app=postgres -o jsonpath='{.items[0].metadata.name}') -- psql -U myuser -d myapp -c "SELECT * FROM test;"
```

データが残っていれば成功である。

### ConfigMapとSecretの活用

環境変数をYAMLファイルに直接書くのはベストプラクティスではない。**ConfigMap**と**Secret**を使う。

**postgres-secret.yaml:**

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: postgres-secret
type: Opaque
stringData:
  POSTGRES_USER: myuser
  POSTGRES_PASSWORD: mypassword
  POSTGRES_DB: myapp
```

**postgres-deployment.yaml（Secret使用版）:**

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: postgres-deployment
spec:
  replicas: 1
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
        envFrom:
        - secretRef:
            name: postgres-secret
        volumeMounts:
        - name: postgres-storage
          mountPath: /var/lib/postgresql/data
          subPath: postgres
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
      volumes:
      - name: postgres-storage
        persistentVolumeClaim:
          claimName: postgres-pvc
```

適用する。

```bash
kubectl apply -f postgres-secret.yaml
kubectl apply -f postgres-deployment.yaml
```

**注意:** Secretはbase64エンコードされるだけで、暗号化されるわけではない。本番環境では、外部のシークレット管理ツール（HashiCorp Vault、AWS Secrets Manager等）の使用を検討すべきである。

## 動作確認とトラブルシューティング

Kubernetesでアプリケーションを動かす際、様々な問題に遭遇することがあります。よくあるトラブルとその解決方法を見ていきましょう。

### Podが起動しない（ImagePullBackOff）

**症状は以下の通りである。**

```text
kubectl get pods
NAME                                   READY   STATUS             RESTARTS   AGE
nginx-deployment-7d6b8c5f9d-abc12      0/1     ImagePullBackOff   0          2m
```

**原因:** Dockerイメージが見つからない、またはプルできない

**解決方法は以下の通りである。**

```bash
# Podの詳細を確認
kubectl describe pod nginx-deployment-7d6b8c5f9d-abc12

# イメージ名のスペルミスをチェック
# プライベートレジストリの場合はimagePullSecretsが必要
```

イメージ名やタグの誤りが最も一般的な原因である。

### Podが起動しない（CrashLoopBackOff）

**症状は以下の通りである。**

```text
NAME                                   READY   STATUS             RESTARTS   AGE
postgres-deployment-6c8d9b7f5a-xyz78   0/1     CrashLoopBackOff   5          3m
```

**原因:** コンテナが起動後すぐにクラッシュしている

**解決方法は以下の通りである。**

```bash
# ログを確認
kubectl logs postgres-deployment-6c8d9b7f5a-xyz78

# 前回の実行ログを確認（コンテナが再起動している場合）
kubectl logs postgres-deployment-6c8d9b7f5a-xyz78 --previous

# よくある原因:
# - 環境変数の設定ミス
# - ボリュームのマウントエラー
# - メモリ不足
```

ログを詳細に確認することで、根本原因を特定できる。

### Serviceに接続できない

**症状:** PodからServiceに接続できない

**解決方法:**

```bash
# Serviceが正しく作成されているか確認
kubectl get services

# Serviceのセレクターが正しいか確認
kubectl describe service postgres-service

# エンドポイントが存在するか確認
kubectl get endpoints postgres-service

# Pod内からDNS解決をテスト
kubectl exec -it <nginx-pod-name> -- nslookup postgres-service
```

### PVCがBound状態にならない

**症状は以下の通りである。**

```text
kubectl get pvc
NAME           STATUS    VOLUME   CAPACITY   ACCESS MODES   STORAGECLASS   AGE
postgres-pvc   Pending                                      standard       5m
```

**原因:** 利用可能なPersistentVolumeがない

**解決方法は以下の通りである。**

```bash
# Minikubeでは通常、動的プロビジョニングが有効
# StorageClassを確認
kubectl get storageclass

# Minikubeのストレージアドオンを有効化
minikube addons enable storage-provisioner

# PVCを再作成
kubectl delete pvc postgres-pvc
kubectl apply -f postgres-pvc.yaml
```

Minikubeでは`storage-provisioner`アドオンが必須である。

### リソース不足エラー

**症状:** Podが `Pending` 状態のまま

**解決方法:**

```bash
# ノードのリソース使用状況を確認
kubectl top nodes
kubectl top pods

# Podのイベントを確認
kubectl describe pod <pod-name>

# Minikubeのリソースを増やして再起動
minikube delete
minikube start --memory=8192 --cpus=4
```

### デバッグ用の便利なコマンド

```bash
# 全てのリソースを一覧表示
kubectl get all

# 特定のNamespaceのリソース
kubectl get all -n kube-system

# リソースの変更をリアルタイムで監視
kubectl get pods --watch

# YAML形式でリソースを確認
kubectl get deployment nginx-deployment -o yaml

# JSONPath形式で特定の値を抽出
kubectl get pods -o jsonpath='{.items[0].metadata.name}'

# 一時的なデバッグPodを起動
kubectl run debug-pod --image=alpine --rm -it -- /bin/sh
```

### ログの効果的な活用

```bash
# 全てのPodのログを表示
kubectl logs -l app=nginx

# 過去のログを確認
kubectl logs <pod-name> --previous

# タイムスタンプ付きでログを表示
kubectl logs <pod-name> --timestamps

# 複数のコンテナがある場合
kubectl logs <pod-name> -c <container-name>
```

## 次のステップ

ここまでで、docker-composeからKubernetesへの基本的な移行ができました。さらに学びを深めるための次のステップを紹介します。

### Helmを学ぶ

HelmはKubernetesのパッケージマネージャーです。複雑なアプリケーションを簡単にデプロイできます。

{{< linkcard "https://helm.sh/" >}}

```bash
# Helmのインストール
brew install helm

# WordPressをワンコマンドでデプロイ
helm install my-wordpress oci://registry-1.docker.io/bitnamicharts/wordpress
```

### Ingressを使った外部公開

Ingressコントローラーを使えば、複数のServiceを1つのエントリーポイントで公開できます。

```bash
# Minikubeでingress addonを有効化
minikube addons enable ingress

# Ingressリソースを作成
kubectl apply -f ingress.yaml
```

### Kubernetesの監視とロギング

- **Prometheus + Grafana**: メトリクス収集と可視化
- **EFK Stack** (Elasticsearch + Fluentd + Kibana): ログ集約
- **Lens**: Kubernetes IDE（GUIツール）

{{< linkcard "https://k8slens.dev/" >}}

### CI/CDパイプラインとの統合

- GitHub Actions、GitLab CI/CD、Jenkins等と連携
- ArgoCD、Fluxを使ったGitOps

{{< linkcard "https://argo-cd.readthedocs.io/" >}}

### 本番環境への展開

- マネージドKubernetesサービス（EKS、GKE、AKS）の利用
- セキュリティベストプラクティスの実践
- リソースクォータと制限の設定
- RBAC（Role-Based Access Control）の実装

### 学習リソース

**公式ドキュメント:**

{{< linkcard "https://kubernetes.io/ja/docs/home/" >}}

{{< linkcard "https://github.com/kelseyhightower/kubernetes-the-hard-way" >}}

**オンラインコース:**

{{< linkcard "https://www.edx.org/course/introduction-to-kubernetes" >}}

また、CKA（Certified Kubernetes Administrator）認定資格の取得も体系的な学習に有効である。

**ハンズオン:**

- Katacoda Kubernetes Scenarios（インタラクティブ学習）
- Play with Kubernetes（ブラウザで試せるK8s環境）

## まとめ

本記事では、docker-composeからKubernetesへの移行について、実践的に解説した。

**振り返り:**

1. **docker-composeとKubernetesの違い**: オーケストレーション機能の有無が最大の違い
2. **Minikubeの選択**: 2025年時点でも最も安定したローカル環境
3. **kubectlの基本操作**: docker-composeコマンドとの対比で理解
4. **実践的な移行手順**: Pod → Deployment → Service → PersistentVolumeの順で段階的に構築
5. **トラブルシューティング**: よくあるエラーとその解決方法

**Kubernetesの学習で大切なこと:**

- **段階的に学ぶ**: 全てを一度に理解しようとしない
- **実際に手を動かす**: ドキュメントを読むだけでなく、実際に試す
- **失敗を恐れない**: ローカル環境なので何度でもやり直せる
- **コミュニティを活用**: Kubernetes Slackコミュニティ、Stack Overflow等で質問

docker-composeで十分な場面も多いが、Kubernetesを学ぶことで、モダンなクラウドネイティブアプリケーションの世界が広がる。本番環境で使うかどうかに関わらず、コンテナオーケストレーションの概念を理解することは、今後のキャリアにおいて大きな武器になる。

2025年、Kubernetesの学習環境はかつてないほど整っている。この記事が、あなたのKubernetes学習の第一歩となれば幸いである。

Happy Kubernetes Learning! 🚀
