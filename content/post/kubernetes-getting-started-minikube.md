---
title: "docker-compose経験者のためのKubernetes入門：Minikubeで10分デプロイ体験"
draft: true
tags:
  - kubernetes
  - docker
  - minikube
  - kompose
  - getting-started
description: "docker-compose経験者向けのKubernetes超速スタートガイド。Minikubeのインストールから3コマンドでのアプリデプロイ、Komposeによる自動変換まで、10分で体験できる実践チュートリアル。"
---

## docker-composeからKubernetesへ：移行の理由と期待値

以前の記事でdocker-composeの魅力をお伝えしました。

{{< linkcard "https://www.nqou.net/2017/12/03/025713/" >}}

docker-composeは今でもローカル開発環境の構築に最適なツールです。YAML一枚でコンテナを管理できる手軽さは、小規模なプロジェクトや個人開発において圧倒的な生産性を提供してくれます。

しかし、アプリケーションが成長し、本番環境への展開を考え始めると、docker-composeには限界が見えてきます。複数のサーバーでコンテナを動かしたい、障害時に自動復旧させたい、無停止でアプリケーションを更新したい——こうした本番運用の要求に応えるのがKubernetesです。

**docker-compose vs Kubernetesの主要な違い**

| 観点 | docker-compose | Kubernetes |
|------|---------------|------------|
| **スケール** | 単一ホスト | 複数ノードのクラスタ |
| **自己修復** | なし（手動再起動） | Podの自動再作成 |
| **ローリングアップデート** | なし | あり（無停止更新） |
| **ロードバランシング** | 手動設定 | 組み込み機能 |
| **本番運用** | 非推奨 | 業界標準 |

Kubernetesは複雑に見えますが、その背後には本番環境での信頼性を担保する設計思想があります。今回はdocker-compose経験者の既存知識を活かしながら、Kubernetesの世界に足を踏み入れてみましょう。

## ローカルKubernetes環境のセットアップ

Kubernetesを学ぶには、まずローカル環境が必要です。本番環境ではマルチノードクラスタを構築しますが、学習には**Minikube**が最適です。

**Minikubeを選ぶ理由**

- 本番環境に近いKubernetes APIを完全にサポート
- 公式ドキュメントが充実している
- LoadBalancer機能（トンネル経由）も使える
- macOS、Windows、Linux全てで動作

**必要なツール**

1. **Minikube** - ローカルKubernetesクラスタ
2. **kubectl** - Kubernetes操作用CLI
3. **Kompose** - docker-compose.yml変換ツール

### インストール手順

#### macOS

```bash
# Homebrewでインストール
brew install minikube kubectl kompose
```

#### Windows

```powershell
# Chocolateyでインストール
choco install minikube kubernetes-cli kompose
```

#### Linux

```bash
# Minikube
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube

# kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
sudo install kubectl /usr/local/bin/kubectl

# Kompose
curl -L https://github.com/kubernetes/kompose/releases/download/v1.34.0/kompose-linux-amd64 -o kompose
chmod +x kompose
sudo mv kompose /usr/local/bin/kompose
```

### クラスタの起動と確認

```bash
# Minikubeクラスタを起動（初回は数分かかります）
minikube start

# バージョン確認
kubectl version --client

# ノードの確認（1つのノードが表示されればOK）
kubectl get nodes
```

実行結果例：

```
NAME       STATUS   ROLES           AGE   VERSION
minikube   Ready    control-plane   30s   v1.28.3
```

ここまでで、あなたのローカルマシンに本物のKubernetesクラスタが動いています！

公式ドキュメント：

{{< linkcard "https://minikube.sigs.k8s.io/" >}}

{{< linkcard "https://kompose.io/" >}}

## 実践1：3コマンドでNginxをデプロイ

docker-composeでは`docker-compose up`一発でしたが、Kubernetesでもコマンド3つで同じことができます。まずは最速体験で達成感を味わいましょう。

### Step 1: Deploymentを作成

```bash
# Nginxコンテナをデプロイ
kubectl create deployment nginx --image=nginx:latest
```

これでNginxコンテナを管理する「Deployment」が作成されました。docker-composeの`service`定義に相当します。

### Step 2: Serviceで公開

```bash
# 外部からアクセスできるようにポートを公開
kubectl expose deployment nginx --type=NodePort --port=80
```

Kubernetesでは、Podへのアクセスを管理する「Service」というリソースが必要です。`NodePort`タイプを使うことで、クラスタ外部からアクセスできるようになります。

### Step 3: ブラウザでアクセス

```bash
# Minikubeがブラウザを自動で開いてくれます
minikube service nginx
```

ブラウザにNginxのデフォルトページが表示されれば成功です！

**確認コマンド**

```bash
# 作成されたリソースを確認
kubectl get deployments
kubectl get pods
kubectl get services
```

実行結果例：

```
NAME    READY   UP-TO-DATE   AVAILABLE   AGE
nginx   1/1     1            1           1m

NAME                     READY   STATUS    RESTARTS   AGE
nginx-7854ff8877-xkp9b   1/1     Running   0          1m

NAME         TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)        AGE
nginx        NodePort    10.96.123.45    <none>        80:30123/TCP   30s
```

わずか3コマンドで、Nginxがクラスタにデプロイされ、外部からアクセスできるようになりました。docker-composeと比べても簡潔ではないでしょうか？

## 実践2：Komposeでdocker-compose.ymlを変換する

次に、既存のdocker-compose.ymlをKubernetesに移行してみましょう。手作業でYAMLを書き直すのは大変ですが、**Kompose**を使えば自動変換できます。

### サンプルdocker-compose.yml

ここではシンプルなNginx + Redisの構成を用意します。

```yaml
# docker-compose.yml
version: '3'
services:
  web:
    image: nginx:latest
    ports:
      - "8080:80"
  
  cache:
    image: redis:latest
    ports:
      - "6379:6379"
```

### Komposeで変換

```bash
# 同じディレクトリでKomposeを実行
kompose convert

# 生成されたファイルを確認
ls -l
```

Komposeは以下のファイルを自動生成します：

- `web-deployment.yaml` - Nginxの定義
- `web-service.yaml` - Nginxへのアクセス設定
- `cache-deployment.yaml` - Redisの定義
- `cache-service.yaml` - Redisへのアクセス設定

### Kubernetesにデプロイ

```bash
# 生成されたYAMLを全て適用
kubectl apply -f .

# 確認
kubectl get pods,svc
```

実行結果例：

```
NAME                        READY   STATUS    RESTARTS   AGE
pod/cache-59c8f9f5b-h7k2x   1/1     Running   0          10s
pod/web-7b9c5d6f8-m4p3v     1/1     Running   0          10s

NAME                 TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)          AGE
service/cache        ClusterIP   10.96.45.123     <none>        6379/TCP         10s
service/web          ClusterIP   10.96.78.234     <none>        80/TCP           10s
```

**docker-composeとの違いを体感**

- docker-compose: `docker-compose up`の1コマンド
- Kubernetes: `kompose convert` → `kubectl apply`の2ステップ

手順は増えましたが、生成されたYAMLファイルを見ると、Kubernetesがどのようにアプリケーションを管理しているかが理解できます。これこそが「宣言的設定」の真髄です。

**注意点：Komposeの限界**

Komposeは便利ですが、本番運用には不十分です。以下は手動で追加する必要があります：

- リソース制限（CPU/メモリ）
- ヘルスチェック（liveness/readiness probes）
- データ永続化の詳細設定
- セキュリティ設定（Secret管理など）

変換されたYAMLは「叩き台」として使い、必ず内容を確認して調整しましょう。

{{< linkcard "https://kubernetes.io/docs/tasks/configure-pod-container/translate-compose-kubernetes/" >}}

## Kubernetesリソースの基本理解

ここまでコマンドで色々なリソースを作成してきましたが、それぞれが何をしているのか整理しましょう。

### Pod - コンテナの実行単位

**Pod**はKubernetesにおける最小のデプロイ単位です。docker-composeの1つの`service`が、Kubernetesでは1つのPodに概ね対応します。

Podの特徴：

- 1つ以上のコンテナをグループ化
- 同じPod内のコンテナはIPアドレスとストレージを共有
- エフェメラル（使い捨て）な設計——障害時は新しいPodが自動作成される

```bash
# Pod一覧を確認
kubectl get pods

# Pod詳細を確認
kubectl describe pod <pod-name>
```

### Deployment - Podの管理レイヤー

**Deployment**は「このアプリケーションをどのように動かすか」を宣言するリソースです。

主な機能：

- レプリカ数の管理（Podを3つ動かす、など）
- ローリングアップデート（無停止でバージョンアップ）
- ロールバック（問題があれば前のバージョンに戻す）
- 自己修復（Podが落ちたら自動で再作成）

docker-composeの`scale`機能に似ていますが、より高度な管理が可能です。

```bash
# Deployment一覧を確認
kubectl get deployments

# レプリカ数を変更（3つに増やす）
kubectl scale deployment nginx --replicas=3

# 確認（3つのPodが動いているはず）
kubectl get pods
```

### Service - ネットワーク公開

**Service**は、Podへの安定したアクセスポイントを提供します。

なぜ必要？Podは再作成のたびにIPアドレスが変わるため、固定のアクセス先が必要だからです。

Serviceタイプ：

- **ClusterIP**（デフォルト）: クラスタ内部からのみアクセス可能
- **NodePort**: 各ノードのポートを公開（今回使用）
- **LoadBalancer**: 外部ロードバランサーを作成（クラウド環境で有効）

```bash
# Service一覧を確認
kubectl get services

# Service詳細を確認
kubectl describe service nginx
```

### リソースの関係性

```
Deployment（管理者）
    ↓ 管理
Pod（実行単位）
    ↑ アクセス
Service（公開窓口）
```

docker-composeでは1つのYAMLに全て書きましたが、Kubernetesでは役割ごとにリソースを分離します。これにより、より柔軟で堅牢なアプリケーション管理が可能になります。

{{< linkcard "https://kubernetes.io/ja/docs/home/" >}}

## クリーンアップと次回への橋渡し

### リソースの削除

実験が終わったら、作成したリソースを削除しましょう。

```bash
# Deploymentを削除（関連するPodも自動削除される）
kubectl delete deployment nginx web cache

# Serviceを削除
kubectl delete service nginx web cache

# 全て削除されたことを確認
kubectl get all
```

### Minikubeの停止

```bash
# クラスタを停止（次回はminikube startで再開できます）
minikube stop

# クラスタを完全に削除する場合
# minikube delete
```

### 今回の学び

今回、あなたは以下を達成しました：

✅ ローカルKubernetes環境（Minikube）のセットアップ  
✅ 3コマンドでのアプリケーションデプロイ体験  
✅ Komposeを使ったdocker-compose.yml変換  
✅ Pod、Deployment、Serviceの基本理解

docker-composeと比べると、確かに手順は増えました。しかし、その裏側では本番環境で必要な「自己修復」「スケーラビリティ」「宣言的管理」といった強力な機能が動いています。

## 次回予告

次回は、今回使った`kubectl create deployment`や`kompose convert`が裏で何をしているのか、YAMLマニフェストの仕組みを詳しく見ていきます。実験的に設定を変更しながら、Kubernetesのコアコンセプトを理解していきましょう。

- Deploymentの仕組みとYAML構造
- Podのライフサイクルと管理
- Serviceの種類と使い分け
- 自分でYAMLを書いてカスタマイズする方法

お楽しみに！
