---
title: "【第1回】docker-composeからKubernetes移行入門：Minikubeで始める10分デプロイ"
draft: true
tags:
  - kubernetes
  - docker
  - minikube
  - kompose
  - docker-compose
  - kubernetes-tutorial
  - container-orchestration
description: "docker-compose経験者向けKubernetes入門。Minikubeでローカル環境構築から3コマンドでNginxデプロイ、Komposeによるdocker-compose.yml自動変換まで10分で体験するステップバイステップチュートリアル。"
---

[@nqounet](https://x.com/nqounet)です。

## docker-composeからKubernetes移行を考える理由

以前の記事でdocker-composeの魅力をお伝えしました。

{{< linkcard "https://www.nqou.net/2017/12/03/025713/" >}}

docker-composeは今でもローカル開発環境の構築に最適なツールです。YAML1枚でコンテナを管理できる手軽さは、小規模なプロジェクトや個人開発において圧倒的な生産性を提供してくれます。

しかし、アプリケーションが成長し、本番環境への展開を考え始めると、docker-composeには限界が見えてきます。

複数のサーバーでコンテナを動かしたい、障害時に自動復旧させたい、無停止でアプリケーションを更新したい——こうした本番運用の要求に応えるのが**Kubernetes（通称：k8s）**です。

**この記事で学べること：**
- Minikubeを使ったローカルKubernetes環境の構築方法
- 3コマンドでアプリケーションをデプロイする手順
- Komposeでdocker-compose.ymlを自動変換する方法
- Pod、Deployment、Serviceの基本概念

### docker-composeとKubernetesの比較：どう違う？

| 観点                       | docker-compose     | Kubernetes             |
| -------------------------- | ------------------ | ---------------------- |
| **スケール**               | 単一ホスト         | 複数ノードのクラスタ   |
| **自己修復**               | なし（手動再起動） | Podの自動再作成        |
| **ローリングアップデート** | なし               | あり（無停止更新）     |
| **ロードバランシング**     | 手動設定           | 組み込み機能           |
| **本番運用**               | 非推奨             | 業界標準               |

Kubernetesは複雑に見えますが、その背後には本番環境での信頼性を担保する設計思想があります。

今回はdocker-compose経験者の既存知識を活かしながら、Kubernetesの世界に足を踏み入れてみましょう。

## Minikubeで始めるローカルKubernetes環境構築

Kubernetesを学ぶには、まずローカル環境が必要です。

本番環境ではマルチノードクラスタを構築しますが、学習には**Minikube**が最適です。

### Minikubeとは？選ぶべき3つの理由

- 本番環境に近いKubernetes APIを完全にサポート
- 公式ドキュメントが充実している
- LoadBalancer機能（トンネル経由）も使える
- macOS、Windows、Linux全てで動作

### 必要なツール3選

1. **Minikube** - ローカルKubernetesクラスタ実行環境
2. **kubectl** - Kubernetes操作用公式CLI
3. **Kompose** - docker-compose.yml変換ツール

### OS別インストール手順

#### macOS（Homebrew）

```bash
# Homebrewでインストール
brew install minikube kubectl kompose
```

#### Windows（Chocolatey）

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

# Kompose（2025年12月時点: v1.34.0が最新）
# 最新版の確認: https://github.com/kubernetes/kompose/releases/latest
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

### 公式ドキュメント

{{< linkcard "https://minikube.sigs.k8s.io/" >}}

{{< linkcard "https://kompose.io/" >}}

## 実践1：3コマンドでNginxをKubernetesにデプロイ

docker-composeでは`docker-compose up`一発でしたが、Kubernetesでもコマンド3つで同じことができます。

まずは最速体験で達成感を味わいましょう。

### Step 1: Deploymentを作成

```bash
# Nginxコンテナをデプロイ
kubectl create deployment nginx --image=nginx:latest
```

これでNginxコンテナを管理する「Deployment」が作成されました。

docker-composeの`service`定義に相当します。

### Step 2: Serviceで公開

```bash
# 外部からアクセスできるようにポートを公開
kubectl expose deployment nginx --type=NodePort --port=80
```

Kubernetesでは、Podへのアクセスを管理する「Service」というリソースが必要です。

`NodePort`タイプを使うことで、クラスタ外部からアクセスできるようになります。

### Step 3: ブラウザでアクセス

```bash
# Minikubeがブラウザを自動で開いてくれます
minikube service nginx
```

ブラウザにNginxのデフォルトページが表示されれば成功です！

### 確認コマンド

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

## 実践2：Komposeでdocker-compose.ymlをKubernetes形式に変換

次に、既存のdocker-compose.ymlをKubernetesに移行してみましょう。

手作業でYAMLを書き直すのは大変ですが、**Kompose**を使えば自動変換できます。

docker-composeでコンテナ管理に慣れている方なら、この移行プロセスがいかに簡単か実感できるはずです。

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

### Komposeコマンドで自動変換

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

### docker-composeとKubernetesのデプロイ手順の違いを体感

- docker-compose: `docker-compose up`の1コマンド
- Kubernetes: `kompose convert` → `kubectl apply`の2ステップ

手順は増えましたが、生成されたYAMLファイルを見ると、Kubernetesがどのようにアプリケーションを管理しているかが理解できます。

これこそが「宣言的設定（Infrastructure as Code）」の真髄です。

### Komposeの限界：本番環境への適用時の注意点

Komposeは便利ですが、本番運用には不十分です。以下は手動で追加する必要があります：

- リソース制限（CPU/メモリ）
- ヘルスチェック（liveness/readiness probes）
- データ永続化の詳細設定
- セキュリティ設定（Secret管理など）

変換されたYAMLは「叩き台」として使い、必ず内容を確認して調整しましょう。

{{< linkcard "https://kubernetes.io/docs/tasks/configure-pod-container/translate-compose-kubernetes/" >}}

## Kubernetesの基本リソース解説：Pod、Deployment、Service

ここまでコマンドで色々なリソースを作成してきましたが、それぞれが何をしているのか整理しましょう。

Kubernetesを理解する上で最も重要な3つの基本リソースを見ていきます。

### Kubernetesにおける3つのコアリソース

Kubernetesでは、**Pod**、**Deployment**、**Service**という3つのリソースが基本となります。

#### Pod - コンテナの実行単位

**Pod**はKubernetesにおける最小のデプロイ単位です。

docker-composeの1つの`service`が、Kubernetesでは1つのPodに概ね対応します。

**Podの特徴：**

- 1つ以上のコンテナをグループ化
- 同じPod内のコンテナはIPアドレスとストレージを共有
- エフェメラル（使い捨て）な設計——障害時は新しいPodが自動作成される

```bash
# Pod一覧を確認
kubectl get pods

# Pod詳細を確認
kubectl describe pod <pod-name>
```

#### Deployment - Podの管理レイヤー

**Deployment**は「このアプリケーションをどのように動かすか」を宣言するリソースです。

**主な機能：**

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

#### Service - ネットワーク公開

**Service**は、Podへの安定したアクセスポイントを提供します。

なぜ必要？Podは再作成されるたびにIPアドレスが変わるため、固定のアクセス先が必要だからです。

**Serviceタイプ：**

- **ClusterIP**（デフォルト）：クラスタ内部からのみアクセス可能
- **NodePort**：各ノードのポートを公開（今回使用）
- **LoadBalancer**：外部ロードバランサーを作成（クラウド環境で有効）

```bash
# Service一覧を確認
kubectl get services

# Service詳細を確認
kubectl describe service nginx
```

### リソース間の関係性を理解する

```
Deployment（管理者）
    ↓ 管理
Pod（実行単位）
    ↑ アクセス
Service（公開窓口）
```

docker-composeでは1つのYAMLに全て書きましたが、Kubernetesでは役割ごとにリソースを分離します。

これにより、より柔軟で堅牢なアプリケーション管理が可能になります。

**関連リンク：**

Kubernetesの公式ドキュメントでさらに詳しく学べます。

{{< linkcard "https://kubernetes.io/ja/docs/home/" >}}

**合わせて読みたい：**

docker-composeの基本については、こちらの記事で詳しく解説しています。

{{< linkcard "https://www.nqou.net/2017/12/03/025713/" >}}

## リソースのクリーンアップと次回への準備

### 作成したKubernetesリソースの削除方法

実験が終わったら、作成したリソースを削除しましょう。

```bash
# Deploymentを削除（関連するPodも自動削除される）
kubectl delete deployment nginx web cache

# Serviceを削除
kubectl delete service nginx web cache

# 全て削除されたことを確認
kubectl get all
```

### Minikubeクラスタの停止と削除

```bash
# クラスタを停止（次回はminikube startで再開できます）
minikube stop

# クラスタを完全に削除する場合
# minikube delete
```

### 第1回のまとめ：達成したこと

今回、あなたは以下を達成しました：

- ✅ ローカルKubernetes環境（Minikube）のセットアップ
- ✅ 3コマンドでのアプリケーションデプロイ体験
- ✅ Komposeを使ったdocker-compose.yml変換
- ✅ Pod、Deployment、Serviceの基本理解

docker-composeと比べると、確かに手順は増えました。

しかし、その裏側では、本番環境で必要な「自己修復」「スケーラビリティ」「宣言的管理」といった強力な機能が動いています。

## 【シリーズ第2回予告】YAMLマニフェスト詳細解説

次回は、今回使った`kubectl create deployment`や`kompose convert`が裏で何をしているのか、YAMLマニフェストの仕組みを詳しく見ていきます。実験的に設定を変更しながら、Kubernetesのコアコンセプトを理解していきましょう。

**次回のトピック：**

- Deployment YAMLの構造と設定項目
- Podのライフサイクルと詳細な管理方法
- Serviceの種類（ClusterIP、NodePort、LoadBalancer）と使い分け
- YAMLを自分で書いてカスタマイズする実践テクニック
- リソース制限とヘルスチェックの設定

お楽しみに！

---

**この記事が役に立ったら：**

- 次回の記事も読んでみてください
- 実際にMinikubeで手を動かしてみましょう
- わからないことがあれば、[@nqounet](https://x.com/nqounet)までお気軽にどうぞ
