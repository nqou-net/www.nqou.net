---
title: "Kubernetesを完全に理解した（第1回）- 一つのサーバーでWebアプリを動かす"
draft: true
tags:
- kubernetes
- docker
- minikube
- getting-started
- container
description: "従来の単一サーバー運用からKubernetesの世界への入り口。minikubeを使って、初めてのPodを動かすまでの手順を丁寧に解説します。"
---

## はじめに - なぜKubernetesを学ぶのか

このシリーズでは、Kubernetesを「完全に理解」することを目標に、基礎から実践的な内容まで段階的に解説していきます。第1回となる本記事では、Kubernetesへの第一歩として、従来の単一サーバー構成の課題を理解し、Dockerの基礎を学び、minikubeを使って実際にPodをデプロイするまでの具体的な手順を解説します。

**この記事で学ぶこと:**

- 従来の単一サーバー構成の限界と問題点
- Dockerコンテナ技術の基礎と実践
- minikubeを使ったローカルKubernetes環境の構築
- 初めてのPodデプロイと基本操作
- よくあるエラーと対処法

## 従来の単一サーバー構成の限界

まず、Kubernetesがなぜ必要なのかを理解するため、従来の単一サーバー構成を見てみましょう。

### Nginxを使った簡単なWebサーバーの起動

従来の方法では、物理サーバーや仮想マシン上に直接Webサーバーをインストールして運用していました。

```bash
# Nginxのインストール
sudo apt update
sudo apt install -y nginx

# Nginxの起動
sudo systemctl start nginx
sudo systemctl enable nginx

# 動作確認
curl http://localhost
```

簡単なHTMLページを配置してみます：

```bash
# カスタムHTMLページの作成
sudo tee /var/www/html/index.html > /dev/null <<EOF
<!DOCTYPE html>
<html>
<head>
    <title>My Web App</title>
</head>
<body>
    <h1>Hello from Single Server!</h1>
    <p>Version: 1.0.0</p>
</body>
</html>
EOF

# 確認
curl http://localhost
```

### 単一サーバー構成の具体的な問題点

#### 問題1: スケーリングの難しさ

アクセスが急増した場合、単一サーバーでは以下の限界に直面します：

```bash
# CPU使用率: 100%に達する
# メモリ不足: OOM Killerが発動
# ネットワーク帯域: 飽和状態

# スケールアップの課題
# 1. サーバーの停止が必要（ダウンタイム発生）
# 2. 物理的なリソース上限がある
# 3. コストが線形に増加

# スケールアウトの課題
# 1. 手動で複数サーバーを立ち上げ
# 2. ロードバランサーの手動設定
# 3. 各サーバーの設定を個別に管理
```

#### 問題2: 障害への脆弱性

単一障害点（Single Point of Failure）により、サーバーがダウンすると即座にサービス停止します：

```bash
# サーバークラッシュのシミュレーション
sudo systemctl stop nginx
# → 即座に503エラー、サービス全停止

# 復旧作業
# 1. 障害検知（監視システムからアラート）
# 2. サーバーへのログイン
# 3. 原因調査
# 4. 手動でサービス再起動
sudo systemctl start nginx
# → この間、ユーザーはアクセスできない
```

#### 問題3: デプロイの複雑さ

```bash
# 従来のデプロイフロー
# 1. 新バージョンのコードを取得
git pull origin main

# 2. 依存関係のインストール
npm install  # または pip install -r requirements.txt

# 3. アプリケーションのビルド
npm run build

# 4. サービスの再起動（ダウンタイム発生）
sudo systemctl restart nginx

# 問題点:
# - ゼロダウンタイムデプロイが困難
# - ロールバックが複雑（前のバージョンに戻す手順が煩雑）
# - 環境差異（本番と開発で依存関係が異なる可能性）
# - 複数サーバーがある場合、全て手動で繰り返し
```

#### 問題4: 環境の一貫性の欠如

```bash
# 「開発環境では動いたのに本番で動かない」問題

# 開発環境
$ python --version
Python 3.10.0

# 本番環境
$ python --version
Python 3.8.10

# → バージョン差異によるエラー
# → 「Works on my machine」問題
```

これらの問題を解決するのが、コンテナ技術とKubernetesです。

## Dockerの基礎 - コンテナ技術への入り口

Dockerは、上記の問題を解決する第一歩となる技術です。

### Dockerのインストール

#### Ubuntu 22.04/24.04での例

```bash
# 古いバージョンの削除
sudo apt-get remove docker docker-engine docker.io containerd runc

# 必要なパッケージのインストール
sudo apt-get update
sudo apt-get install -y \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

# Docker公式GPGキーの追加
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | \
    sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Dockerリポジトリの設定
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Dockerのインストール
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# 現在のユーザーをdockerグループに追加（sudo不要にする）
sudo usermod -aG docker $USER

# 一度ログアウトして再ログイン、または以下を実行
newgrp docker

# インストール確認
docker --version
# 出力例: Docker version 24.0.7, build afdd53b
```

#### macOSでの例

```bash
# Homebrewを使用したインストール
brew install --cask docker

# Docker Desktopを起動
open -a Docker

# インストール確認（Docker Desktopの起動後）
docker --version
# 出力例: Docker version 24.0.7, build afdd53b

# 動作確認
docker run hello-world
```

### Dockerfileの基本

シンプルなNginx用Dockerfileを作成してみましょう：

```dockerfile
# ベースイメージの指定
FROM nginx:1.25-alpine

# 作業ディレクトリの設定
WORKDIR /usr/share/nginx/html

# カスタムHTMLファイルのコピー
COPY index.html .

# ポートの公開（ドキュメント目的）
EXPOSE 80

# コンテナ起動時のコマンド（nginx imageですでに定義されている）
# CMD ["nginx", "-g", "daemon off;"]
```

カスタムHTMLファイル（`index.html`）：

```html
<!DOCTYPE html>
<html>
<head>
    <title>Dockerized Web App</title>
    <style>
        body {
            font-family: Arial, sans-serif;
            max-width: 800px;
            margin: 50px auto;
            padding: 20px;
        }
        .container {
            background: #f0f0f0;
            padding: 20px;
            border-radius: 8px;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🐳 Hello from Docker!</h1>
        <p>Version: 2.0.0</p>
        <p>This app is running in a Docker container.</p>
    </div>
</body>
</html>
```

### イメージのビルドと実行

```bash
# Dockerイメージのビルド
docker build -t my-nginx-app:v1.0 .

# ビルドされたイメージの確認
docker images
# 出力例:
# REPOSITORY      TAG       IMAGE ID       CREATED         SIZE
# my-nginx-app    v1.0      abc123def456   5 seconds ago   41.4MB

# コンテナの実行
docker run -d -p 8080:80 --name my-app my-nginx-app:v1.0

# 実行中のコンテナ確認
docker ps
# 出力例:
# CONTAINER ID   IMAGE              COMMAND                  CREATED         STATUS         PORTS                  NAMES
# 789xyz012abc   my-nginx-app:v1.0  "/docker-entrypoint.…"   3 seconds ago   Up 2 seconds   0.0.0.0:8080->80/tcp   my-app

# 動作確認
curl http://localhost:8080
```

### 基本的なDockerコマンド

```bash
# コンテナのログ確認
docker logs my-app

# リアルタイムでログを追跡
docker logs -f my-app

# コンテナ内でコマンド実行
docker exec -it my-app sh
# コンテナ内のシェルに入る（exitで抜ける）

# コンテナの停止
docker stop my-app

# コンテナの削除
docker rm my-app

# イメージの削除
docker rmi my-nginx-app:v1.0

# 全ての停止中コンテナを削除
docker container prune

# 使用していないイメージを削除
docker image prune
```

### Dockerのメリット

```bash
# メリット1: 環境の一貫性
# Dockerイメージは開発・本番で完全に同一
docker run my-nginx-app:v1.0  # どこでも同じ動作

# メリット2: 軽量で高速
# 従来の仮想マシンと比較
# VM: 数GB、起動に数分
# Container: 数十MB、起動に数秒

# 起動時間の比較
time docker run --rm nginx:alpine echo "Hello"
# 出力例: real 0m1.234s

# メリット3: バージョン管理が容易
docker run my-nginx-app:v1.0  # バージョン1.0
docker run my-nginx-app:v2.0  # バージョン2.0
# 簡単に切り替え・ロールバック可能
```

## minikubeでKubernetes環境構築

minikubeは、ローカル環境でKubernetesクラスタを簡単に起動できるツールです。

### minikubeのインストール

#### Ubuntu/Linuxの場合

```bash
# minikubeバイナリのダウンロード
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64

# インストール
sudo install minikube-linux-amd64 /usr/local/bin/minikube

# バージョン確認
minikube version
# 出力例: minikube version: v1.32.0
```

#### macOSの場合

```bash
# Homebrewを使用
brew install minikube

# または直接ダウンロード
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-darwin-amd64
sudo install minikube-darwin-amd64 /usr/local/bin/minikube

# バージョン確認
minikube version
# 出力例: minikube version: v1.32.0
```

### minikubeの起動

```bash
# 基本的な起動（デフォルト設定）
minikube start

# より詳細な設定での起動
minikube start \
  --driver=docker \
  --cpus=2 \
  --memory=4096 \
  --disk-size=20g \
  --kubernetes-version=v1.28.3

# 出力例:
# 😄  minikube v1.32.0 on Ubuntu 22.04
# ✨  Using the docker driver based on user configuration
# 👍  Starting control plane node minikube in cluster minikube
# 🚜  Pulling base image ...
# 🔥  Creating docker container (CPUs=2, Memory=4096MB) ...
# 🐳  Preparing Kubernetes v1.28.3 on Docker 24.0.7 ...
#     ▪ Generating certificates and keys ...
#     ▪ Booting up control plane ...
#     ▪ Configuring RBAC rules ...
# 🔗  Configuring bridge CNI (Container Networking Interface) ...
# 🔎  Verifying Kubernetes components...
# 🌟  Enabled addons: storage-provisioner, default-storageclass
# 🏄  Done! kubectl is now configured to use "minikube" cluster and "default" namespace by default

# ステータス確認
minikube status
# 出力例:
# minikube
# type: Control Plane
# host: Running
# kubelet: Running
# apiserver: Running
# kubeconfig: Configured
```

### minikubeの便利なコマンド

```bash
# ダッシュボードの起動（GUIでクラスタを確認）
minikube dashboard

# SSHでminikubeノードに接続
minikube ssh

# minikube内のDockerを使用
eval $(minikube docker-env)
# これ以降のdockerコマンドはminikube内のDockerを操作

# アドオンの一覧表示
minikube addons list

# メトリクスサーバーの有効化（後のHPA等で使用）
minikube addons enable metrics-server

# minikubeの停止
minikube stop

# minikubeの削除（クリーンアップ）
minikube delete
```

### kubectlのインストールと設定

kubectlは、Kubernetesクラスタを操作するためのコマンドラインツールです。

#### Ubuntuでのインストール

```bash
# 最新版のダウンロード
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"

# バイナリの検証（オプション）
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl.sha256"
echo "$(cat kubectl.sha256)  kubectl" | sha256sum --check

# インストール
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# バージョン確認
kubectl version --client
# 出力例: Client Version: v1.28.3
```

#### macOSでのインストール

```bash
# Homebrewを使用
brew install kubectl

# または直接ダウンロード
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/darwin/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/

# バージョン確認
kubectl version --client
```

#### kubectlの基本設定

```bash
# クラスタへの接続確認
kubectl cluster-info
# 出力例:
# Kubernetes control plane is running at https://127.0.0.1:32768
# CoreDNS is running at https://127.0.0.1:32768/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy

# ノードの確認
kubectl get nodes
# 出力例:
# NAME       STATUS   ROLES           AGE   VERSION
# minikube   Ready    control-plane   5m    v1.28.3

# コンテキストの確認
kubectl config get-contexts
# 出力例:
# CURRENT   NAME       CLUSTER    AUTHINFO   NAMESPACE
# *         minikube   minikube   minikube   default

# 自動補完の設定（bash）
echo 'source <(kubectl completion bash)' >> ~/.bashrc
source ~/.bashrc

# 自動補完の設定（zsh）
echo 'source <(kubectl completion zsh)' >> ~/.zshrc
source ~/.zshrc

# kubectlのエイリアス設定（オプション）
echo 'alias k=kubectl' >> ~/.bashrc
echo 'complete -o default -F __start_kubectl k' >> ~/.bashrc
source ~/.bashrc
```

## 初めてのPodデプロイ

ついに、Kubernetes上で最初のアプリケーションを動かします！

### 最もシンプルなnginx Podのマニフェスト

`nginx-pod.yaml` ファイルを作成します：

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx-pod
  labels:
    app: nginx
    environment: learning
spec:
  containers:
  - name: nginx
    image: nginx:1.25-alpine
    ports:
    - containerPort: 80
      protocol: TCP
```

### Podのデプロイ

```bash
# マニフェストの適用
kubectl apply -f nginx-pod.yaml
# 出力: pod/nginx-pod created

# Podの状態確認
kubectl get pods
# 出力例:
# NAME        READY   STATUS    RESTARTS   AGE
# nginx-pod   1/1     Running   0          10s

# より詳細な情報
kubectl get pods -o wide
# 出力例:
# NAME        READY   STATUS    RESTARTS   AGE   IP           NODE       NOMINATED NODE   READINESS GATES
# nginx-pod   1/1     Running   0          30s   10.244.0.5   minikube   <none>           <none>

# Pod詳細情報の確認
kubectl describe pod nginx-pod
# 出力例（抜粋）:
# Name:             nginx-pod
# Namespace:        default
# Priority:         0
# Service Account:  default
# Node:             minikube/192.168.49.2
# Start Time:       Sun, 07 Dec 2025 19:00:00 +0000
# Labels:           app=nginx
#                   environment=learning
# Status:           Running
# IP:               10.244.0.5
# Containers:
#   nginx:
#     Container ID:   docker://abc123...
#     Image:          nginx:1.25-alpine
#     Port:           80/TCP
#     State:          Running
#       Started:      Sun, 07 Dec 2025 19:00:05 +0000
```

### Podのログ確認

```bash
# リアルタイムでログを表示
kubectl logs -f nginx-pod

# 最新の50行を表示
kubectl logs --tail=50 nginx-pod

# タイムスタンプ付きでログ表示
kubectl logs --timestamps nginx-pod
```

### port-forwardでローカルからアクセス

```bash
# ローカルの8080ポートをPodの80ポートに転送
kubectl port-forward nginx-pod 8080:80
# 出力: Forwarding from 127.0.0.1:8080 -> 80

# 別のターミナルで動作確認
curl http://localhost:8080
# nginxのデフォルトページが表示される

# ブラウザでアクセス
# http://localhost:8080 を開く

# port-forwardの停止はCtrl+C
```

### Pod内でコマンド実行

```bash
# Podのシェルに接続
kubectl exec -it nginx-pod -- sh

# Pod内で操作（例）
/ # hostname
nginx-pod

/ # cat /etc/nginx/nginx.conf
# nginxの設定を確認

/ # ls -la /usr/share/nginx/html/
# HTMLファイルの確認

/ # wget -O- http://localhost
# Pod内部からnginxにアクセス

/ # exit
# シェルから抜ける

# 1行のコマンド実行
kubectl exec nginx-pod -- nginx -v
# 出力例: nginx version: nginx/1.25.3
```

### カスタムHTMLを使ったPodの例

より実践的な例として、カスタムHTMLを使ったPodをデプロイします。

#### ConfigMapを使った方法

`nginx-configmap.yaml` ファイルを作成します：

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: nginx-html
data:
  index.html: |
    <!DOCTYPE html>
    <html>
    <head>
        <title>My First Kubernetes App</title>
        <style>
            body {
                font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
                max-width: 800px;
                margin: 50px auto;
                padding: 20px;
                background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            }
            .container {
                background: white;
                padding: 40px;
                border-radius: 12px;
                box-shadow: 0 10px 40px rgba(0,0,0,0.1);
            }
            h1 { color: #667eea; }
            .info { 
                background: #f7fafc;
                padding: 15px;
                border-left: 4px solid #667eea;
                margin: 20px 0;
            }
        </style>
    </head>
    <body>
        <div class="container">
            <h1>🚀 Welcome to Kubernetes!</h1>
            <p>This is my first Pod running on minikube.</p>
            <div class="info">
                <strong>Pod Name:</strong> nginx-custom<br>
                <strong>Version:</strong> 1.0.0<br>
                <strong>Status:</strong> Running ✅
            </div>
            <p>Kubernetes makes container orchestration easy and powerful!</p>
        </div>
    </body>
    </html>
---
apiVersion: v1
kind: Pod
metadata:
  name: nginx-custom
  labels:
    app: nginx-custom
spec:
  containers:
  - name: nginx
    image: nginx:1.25-alpine
    ports:
    - containerPort: 80
    volumeMounts:
    - name: html
      mountPath: /usr/share/nginx/html
  volumes:
  - name: html
    configMap:
      name: nginx-html
```

#### デプロイと確認

```bash
# ConfigMapとPodをデプロイ
kubectl apply -f nginx-configmap.yaml
# 出力:
# configmap/nginx-html created
# pod/nginx-custom created

# 確認
kubectl get pods
kubectl get configmaps

# port-forwardでアクセス
kubectl port-forward nginx-custom 8081:80

# 別のターミナルで
curl http://localhost:8081
# カスタムHTMLが表示される
```

### Podのクリーンアップ

```bash
# 個別のPod削除
kubectl delete pod nginx-pod
kubectl delete pod nginx-custom

# ConfigMapの削除
kubectl delete configmap nginx-html

# マニフェストファイルを使った削除
kubectl delete -f nginx-pod.yaml
kubectl delete -f nginx-configmap.yaml

# 確認
kubectl get pods
# 出力: No resources found in default namespace.
```

## トラブルシューティング - よくあるエラーと対処法

### minikubeが起動しない

#### 問題: Dockerドライバーが見つからない

```bash
# エラーメッセージ例
❌  Exiting due to PROVIDER_DOCKER_NOT_FOUND: The docker driver is not installed
```

**解決方法:**

```bash
# Dockerがインストールされているか確認
docker --version

# Dockerが起動しているか確認
docker ps

# Dockerが起動していない場合
sudo systemctl start docker  # Linux
# または Docker Desktop を起動（macOS/Windows）

# 再度minikube起動
minikube start --driver=docker
```

#### 問題: リソース不足

```bash
# エラーメッセージ例
❌  Exiting due to RSRC_INSUFFICIENT_CORES: Requested cpu count 2 is greater than the available cpus of 1
```

**解決方法:**

```bash
# より少ないリソースで起動
minikube start --cpus=1 --memory=2048

# 現在のマシンのリソースを確認
# Linux
nproc  # CPUコア数
free -h  # メモリ

# macOS
sysctl -n hw.ncpu  # CPUコア数
sysctl -n hw.memsize | awk '{print $1/1024/1024/1024 " GB"}'  # メモリ
```

#### 問題: ポート競合

```bash
# エラーメッセージ例
❌  Unable to bind to port: 8443
```

**解決方法:**

```bash
# 使用中のポートを確認
sudo lsof -i :8443  # Linux/macOS
# または
sudo netstat -tulpn | grep 8443

# 競合するプロセスを停止するか、minikubeのクリーンアップ
minikube delete
minikube start
```

### ImagePullBackOffエラー

#### エラーの確認

```bash
# Podのステータスを確認
kubectl get pods
# 出力例:
# NAME        READY   STATUS             RESTARTS   AGE
# my-app      0/1     ImagePullBackOff   0          2m

# 詳細を確認
kubectl describe pod my-app
# Events:
#   Warning  Failed     2m   kubelet  Failed to pull image "my-typo-image:v1.0": rpc error: code = Unknown desc = Error response from daemon: pull access denied for my-typo-image, repository does not exist or may require 'docker login'
```

#### よくある原因と解決方法

**原因1: イメージ名のタイポ**

```yaml
# 間違い
spec:
  containers:
  - name: nginx
    image: ngixn:1.25  # タイポ!

# 正しい
spec:
  containers:
  - name: nginx
    image: nginx:1.25
```

**原因2: プライベートレジストリの認証不足**

```bash
# Dockerレジストリのシークレット作成
kubectl create secret docker-registry my-registry-secret \
  --docker-server=registry.example.com \
  --docker-username=myuser \
  --docker-password=mypassword \
  --docker-email=myemail@example.com
```

Podマニフェストでシークレットを指定：

```yaml
spec:
  imagePullSecrets:
  - name: my-registry-secret
  containers:
  - name: my-app
    image: registry.example.com/my-app:v1.0
```

**原因3: ネットワーク問題**

```bash
# minikube内からインターネット接続を確認
minikube ssh
$ ping 8.8.8.8
$ ping registry-1.docker.io

# プロキシ設定が必要な環境の場合
minikube start --docker-env HTTP_PROXY=http://proxy.example.com:8080 \
               --docker-env HTTPS_PROXY=http://proxy.example.com:8080
```

**原因4: レート制限（Docker Hub）**

```bash
# Docker Hubの認証情報を設定
kubectl create secret docker-registry dockerhub \
  --docker-username=your-username \
  --docker-password=your-password

# または、minikube内のDockerを使用（イメージを事前にpull）
eval $(minikube docker-env)
docker pull nginx:1.25-alpine
```

### kubectlコマンドが見つからない

#### エラー例

```bash
$ kubectl get pods
bash: kubectl: command not found
```

#### 解決方法

```bash
# kubectlがインストールされているか確認
which kubectl

# インストールされていない場合、再インストール
# Ubuntu
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install kubectl /usr/local/bin/

# macOS
brew install kubectl

# PATHの確認
echo $PATH

# /usr/local/binがPATHに含まれているか確認
# 含まれていない場合は~/.bashrcまたは~/.zshrcに追加
echo 'export PATH="/usr/local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

### Podがずっとpending状態

#### エラーの確認

```bash
kubectl get pods
# 出力:
# NAME      READY   STATUS    RESTARTS   AGE
# my-pod    0/1     Pending   0          5m

kubectl describe pod my-pod
# Events:
#   Warning  FailedScheduling  5m   default-scheduler  0/1 nodes are available: 1 Insufficient cpu.
```

#### 原因と解決方法

**原因1: リソース不足**

要求リソースが大きすぎる場合：

```yaml
# より小さいリソースに変更
spec:
  containers:
  - name: my-app
    resources:
      requests:
        memory: "128Mi"
        cpu: "100m"
```

**原因2: ノードセレクタの不一致**

```bash
# ノードのラベルを確認
kubectl get nodes --show-labels

# ノードセレクタを削除または修正
```

### port-forwardが接続できない

#### 問題確認

```bash
kubectl port-forward my-pod 8080:80
# Ctrl+Cで停止せず、別ターミナルで:
curl http://localhost:8080
# curl: (7) Failed to connect to localhost port 8080: Connection refused
```

#### 解決方法

```bash
# 1. Podが実際にRunning状態か確認
kubectl get pods

# 2. Podのポートが正しいか確認
kubectl describe pod my-pod | grep Port

# 3. Podがリッスンしているか確認
kubectl exec my-pod -- netstat -tulpn
# または
kubectl exec my-pod -- ss -tulpn

# 4. ファイアウォールの確認（Linux）
sudo ufw status
sudo iptables -L

# 5. 正しい構文でport-forward
kubectl port-forward pod/my-pod 8080:80
# "pod/"のプレフィックスを明示
```

### デバッグの基本テクニック

#### 問題切り分けのフローチャート

```bash
# ステップ1: Podのステータス確認
kubectl get pods

# ステップ2: 詳細情報の確認
kubectl describe pod <pod-name>
# Eventsセクションを重点的に確認

# ステップ3: ログの確認
kubectl logs <pod-name>
# 複数コンテナの場合
kubectl logs <pod-name> -c <container-name>

# ステップ4: 直前のコンテナログ（再起動している場合）
kubectl logs <pod-name> --previous

# ステップ5: Pod内でインタラクティブに調査
kubectl exec -it <pod-name> -- sh

# ステップ6: ネットワーク接続テスト用のデバッグPod
kubectl run debug-pod --image=nicolaka/netshoot -it --rm -- bash
# Pod内で:
# nslookup my-service
# curl http://my-service
# ping 8.8.8.8
```

#### よく使うデバッグコマンド集

```bash
# すべてのリソースを一覧表示
kubectl get all

# すべてのイベントを表示
kubectl get events --sort-by='.lastTimestamp'

# 特定のNamespaceのイベント
kubectl get events -n kube-system

# YAMLフォーマットでリソースを確認
kubectl get pod my-pod -o yaml

# JSONフォーマットで特定フィールドを抽出
kubectl get pod my-pod -o jsonpath='{.status.podIP}'

# リソースの詳細情報をファイルに保存
kubectl get pod my-pod -o yaml > pod-debug.yaml

# ラベルセレクタでフィルタ
kubectl get pods -l app=nginx

# すべてのNamespaceを確認
kubectl get pods --all-namespaces
# または
kubectl get pods -A
```

## まとめ

本記事では、以下の内容を学習しました：

1. **従来の単一サーバー構成の課題**
   - スケーリングの難しさ
   - 障害への脆弱性
   - デプロイの複雑さ
   - 環境の不一致

2. **Dockerの基礎**
   - インストール方法
   - Dockerfileの書き方
   - 基本的なコマンド操作

3. **minikubeのセットアップ**
   - インストールと起動
   - 基本的な操作方法
   - kubectlの設定

4. **初めてのPodデプロイ**
   - マニフェストの作成
   - Podのデプロイと確認
   - ログとデバッグ方法

5. **トラブルシューティング**
   - よくあるエラーと解決方法
   - デバッグの基本テクニック

これで、Kubernetesの世界への最初の一歩を踏み出すことができました！

## 次回予告 - 第2回

次回の記事では、以下を学習します：

- **Podのライフサイクルの詳細** - Podがどのように生まれ、動き、そして終わるのか
- **kubectlコマンドの応用** - より高度な操作とデバッグ手法
- **Podが停止・再起動する様々なシナリオ** - 実際の運用で遭遇する問題への対処
- **YAMLマニフェストの詳細な書き方** - より複雑な設定の実現

ぜひ、実際に手を動かしながら学習を続けてください！

## 参考リンク

- [Kubernetes公式ドキュメント](https://kubernetes.io/docs/home/)
- [minikube公式ドキュメント](https://minikube.sigs.k8s.io/docs/)
- [Docker公式ドキュメント](https://docs.docker.com/)
- [kubectl チートシート](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)
