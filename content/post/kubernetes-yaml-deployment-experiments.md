---
title: "【第2回】YAMLで理解するKubernetes：実験で学ぶDeployment・Pod・Service"
draft: true
tags:
  - kubernetes
  - yaml
  - deployment
  - pod
  - service
  - hands-on
description: "YAMLマニフェストを実験的に書き換えてKubernetesの動作を体感。レプリカ数変更、Pod削除、ローリングアップデート、Serviceタイプ切替を実践する第2回実験重視チュートリアル。"
---

[@nqounet](https://x.com/nqounet)です。

## 前回の振り返り：コマンドからYAMLへ

前回の記事では、Minikubeを使ってKubernetesのローカル環境を構築し、3つのコマンドでNginxをデプロイしました。

{{< linkcard "https://www.nqou.net/post/kubernetes-getting-started-minikube/" >}}

`kubectl create deployment`や`kubectl expose`といったコマンドで簡単にアプリケーションを動かせることは体験できましたが、その裏側で何が起こっているのか、YAMLマニフェストがどうなっているのかは見えませんでした。

今回は、そのYAMLファイルを自分で書いて、**実験的に設定を変更しながら**Kubernetesの動作を理解していきます。

**この記事で学べること：**
- Deployment、Pod、ServiceのYAML構造
- レプリカ数の変更とスケーリングの仕組み
- Podを削除したときの自己修復機能
- ローリングアップデートの実践
- Serviceタイプ（ClusterIP、NodePort、LoadBalancer）の使い分け
- YAMLマニフェストのデバッグ方法

**前提条件：**
- Minikubeがインストール済み
- kubectlが使える
- 前回の記事の内容を理解している

まだMinikubeをインストールしていない方は、前回の記事を参照してください。

## 実験環境の準備：Minikubeクラスタの起動

まずはMinikubeを起動して、実験用のクラスタを準備しましょう。

```bash
# Minikubeクラスタを起動
minikube start

# クラスタが正常に動いているか確認
kubectl cluster-info
kubectl get nodes
```

実行結果例：

```
Kubernetes control plane is running at https://192.168.49.2:8443

NAME       STATUS   ROLES           AGE   VERSION
minikube   Ready    control-plane   1m    v1.28.3
```

これで実験環境の準備が整いました。

## 実験1：DeploymentのYAMLを書いて理解する

前回は`kubectl create deployment`コマンドを使いましたが、今回はYAMLファイルから作成します。

### Deployment YAMLの基本構造

まずは最小限のDeployment YAMLを作成してみましょう。

```yaml
# nginx-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
  labels:
    app: nginx
spec:
  replicas: 3
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
        image: nginx:1.25
        ports:
        - containerPort: 80
```

### YAMLの構造を分解して理解する

このYAMLは4つのセクションに分かれています：

1. **apiVersion/kind**: リソースの種類を定義
   - `apps/v1`: Deploymentが属するAPIグループ
   - `Deployment`: リソースのタイプ

2. **metadata**: リソースのメタ情報
   - `name`: Deploymentの名前（クラスタ内で一意）
   - `labels`: リソースを識別するためのラベル

3. **spec**: Deploymentの仕様
   - `replicas: 3`: Podを3つ維持する
   - `selector`: どのPodを管理対象にするか（labelsと一致させる）
   - `template`: Podのテンプレート定義

4. **template.spec**: Pod内のコンテナ定義
   - `containers`: コンテナのリスト
   - `image`: 使用するDockerイメージ
   - `ports`: 公開するポート

### デプロイと確認

```bash
# YAMLファイルを適用
kubectl apply -f nginx-deployment.yaml

# Deploymentの確認
kubectl get deployments

# Podの確認（3つ起動しているはず）
kubectl get pods
```

実行結果例：

```
NAME               READY   UP-TO-DATE   AVAILABLE   AGE
nginx-deployment   3/3     3            3           10s

NAME                                READY   STATUS    RESTARTS   AGE
nginx-deployment-7fb96c846b-4xk2m   1/1     Running   0          10s
nginx-deployment-7fb96c846b-7n9qw   1/1     Running   0          10s
nginx-deployment-7fb96c846b-m8plz   1/1     Running   0          10s
```

**実験結果：** `replicas: 3`の指定通り、3つのPodが作成されました。

## 実験2：レプリカ数を変更してスケーリングを体験

Kubernetesの強力な機能の一つが、**宣言的なスケーリング**です。

YAMLファイルの`replicas`を変更して、どう動作するか観察してみましょう。

### 実験手順：5レプリカに増やす

```yaml
# nginx-deployment.yaml（replicas部分のみ変更）
spec:
  replicas: 5  # 3 → 5に変更
```

```bash
# 変更を適用
kubectl apply -f nginx-deployment.yaml

# リアルタイムでPodの変化を観察
kubectl get pods -w
```

**観察結果：**

数秒以内に新しいPodが2つ追加されます。`-w`オプション（watch）を使うと、リアルタイムで変化が見えます。

```
NAME                                READY   STATUS              RESTARTS   AGE
nginx-deployment-7fb96c846b-4xk2m   1/1     Running             0          2m
nginx-deployment-7fb96c846b-7n9qw   1/1     Running             0          2m
nginx-deployment-7fb96c846b-m8plz   1/1     Running             0          2m
nginx-deployment-7fb96c846b-x7k9n   0/1     ContainerCreating   0          1s
nginx-deployment-7fb96c846b-p2m4v   0/1     ContainerCreating   0          1s
nginx-deployment-7fb96c846b-x7k9n   1/1     Running             0          3s
nginx-deployment-7fb96c846b-p2m4v   1/1     Running             0          3s
```

### 実験手順：1レプリカに減らす

今度は逆に減らしてみます。

```yaml
spec:
  replicas: 1  # 5 → 1に変更
```

```bash
kubectl apply -f nginx-deployment.yaml
kubectl get pods
```

**観察結果：**

4つのPodが自動的に削除され、1つだけが残ります。Kubernetesは常に「あるべき状態（Desired State）」に合わせてくれます。

**実験のポイント：**
- docker-composeでは手動でコンテナ数を調整する必要があったが、Kubernetesでは数値を変更して`apply`するだけ
- スケールアップもダウンも同じコマンド（`kubectl apply`）で実現
- これが「宣言的設定」の本質

## 実験3：Podを削除したらどうなる？自己修復機能の確認

Kubernetesの最も重要な特徴の一つが**自己修復（Self-Healing）**です。

Podが何らかの理由で停止しても、Deploymentが自動的に再作成してくれます。これを実験で確認してみましょう。

### 実験準備：レプリカ数を3に戻す

```yaml
spec:
  replicas: 3
```

```bash
kubectl apply -f nginx-deployment.yaml
```

### 実験手順：意図的にPodを削除する

```bash
# 現在のPodを確認
kubectl get pods

# 1つのPodを選んで削除（名前はご自身の環境に合わせて変更）
kubectl delete pod nginx-deployment-7fb96c846b-4xk2m

# 即座に確認
kubectl get pods
```

**観察結果：**

削除したPodは`Terminating`状態になり、同時に新しいPodが`ContainerCreating`として作成されます。

```
NAME                                READY   STATUS              RESTARTS   AGE
nginx-deployment-7fb96c846b-4xk2m   1/1     Terminating         0          5m
nginx-deployment-7fb96c846b-7n9qw   1/1     Running             0          5m
nginx-deployment-7fb96c846b-m8plz   1/1     Running             0          5m
nginx-deployment-7fb96c846b-z9k3p   0/1     ContainerCreating   0          1s
```

数秒後に確認すると：

```
NAME                                READY   STATUS    RESTARTS   AGE
nginx-deployment-7fb96c846b-7n9qw   1/1     Running   0          6m
nginx-deployment-7fb96c846b-m8plz   1/1     Running   0          6m
nginx-deployment-7fb96c846b-z9k3p   1/1     Running   0          15s
```

**実験のポイント：**
- Deploymentが常に`replicas: 3`を維持しようとする
- 障害時も自動的に復旧する（本番運用で重要）
- docker-composeではコンテナが落ちたら手動で`up`する必要があったが、Kubernetesは自動

### 詳細な状態確認

```bash
# Deploymentの詳細を見る
kubectl describe deployment nginx-deployment
```

Events欄に以下のような記録が残っています：

```
Events:
  Type    Reason             Age   From                   Message
  ----    ------             ----  ----                   -------
  Normal  ScalingReplicaSet  10m   deployment-controller  Scaled up replica set nginx-deployment-7fb96c846b to 3
  Normal  ScalingReplicaSet  2m    deployment-controller  Scaled up replica set nginx-deployment-7fb96c846b to 3
```

Kubernetesはすべての操作を記録しているため、何が起こったかトレースできます。

## 実験4：ServiceのYAMLとタイプの使い分け

前回はコマンドでServiceを作成しましたが、今回はYAMLで定義します。

Serviceには3つの主要なタイプがあり、それぞれ使い分けが重要です。

### ServiceタイプのYAML比較

#### ClusterIP（デフォルト）：クラスタ内部専用

```yaml
# nginx-service-clusterip.yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-service-clusterip
spec:
  type: ClusterIP
  selector:
    app: nginx
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
```

**用途：** マイクロサービス間の内部通信（例：WebアプリからDB接続）

```bash
kubectl apply -f nginx-service-clusterip.yaml
kubectl get svc nginx-service-clusterip
```

実行結果：

```
NAME                       TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
nginx-service-clusterip    ClusterIP   10.96.123.45    <none>        80/TCP    10s
```

**確認：** EXTERNAL-IPが`<none>`なので、クラスタ外部からはアクセスできません。

#### NodePort：各ノードのポートで公開

```yaml
# nginx-service-nodeport.yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-service-nodeport
spec:
  type: NodePort
  selector:
    app: nginx
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
      nodePort: 30080  # 30000-32767の範囲で指定可能
```

**用途：** 開発環境でのテスト、ローカルでの動作確認

```bash
kubectl apply -f nginx-service-nodeport.yaml
kubectl get svc nginx-service-nodeport
```

実行結果：

```
NAME                      TYPE       CLUSTER-IP      EXTERNAL-IP   PORT(S)        AGE
nginx-service-nodeport    NodePort   10.96.78.234    <none>        80:30080/TCP   10s
```

**アクセス方法：**

```bash
# Minikubeの場合
minikube service nginx-service-nodeport

# または、ノードのIPアドレスとポート番号で直接アクセス
minikube ip  # 例: 192.168.49.2
# ブラウザで http://192.168.49.2:30080 にアクセス
```

#### LoadBalancer：外部ロードバランサー

```yaml
# nginx-service-loadbalancer.yaml
apiVersion: v1
kind: Service
metadata:
  name: nginx-service-loadbalancer
spec:
  type: LoadBalancer
  selector:
    app: nginx
  ports:
    - protocol: TCP
      port: 80
      targetPort: 80
```

**用途：** クラウド環境（AWS、GCP、Azure）での本番公開

```bash
kubectl apply -f nginx-service-loadbalancer.yaml
kubectl get svc nginx-service-loadbalancer
```

Minikube環境では：

```
NAME                          TYPE           CLUSTER-IP      EXTERNAL-IP   PORT(S)        AGE
nginx-service-loadbalancer    LoadBalancer   10.96.45.123    <pending>     80:31234/TCP   10s
```

**注意：** ローカル環境では`<pending>`のままです。クラウド環境では自動的に外部IPが割り当てられます。

Minikubeでテストする場合：

```bash
# トンネル機能を使う（別ターミナルで実行）
minikube tunnel

# これでEXTERNAL-IPが割り当てられる
kubectl get svc nginx-service-loadbalancer
```

### Serviceタイプの使い分けまとめ

| タイプ | 用途 | アクセス範囲 | 本番利用 |
|--------|------|------------|---------|
| **ClusterIP** | マイクロサービス間通信 | クラスタ内のみ | ○ |
| **NodePort** | 開発環境でのテスト | ノードのIP:ポート | △ |
| **LoadBalancer** | 外部公開 | インターネット全体 | ○（クラウド） |

**実験のポイント：**
- 同じアプリケーションでも、公開方法を簡単に変更できる
- YAMLの`type`を変えるだけで、ネットワーク構成が変わる
- docker-composeの`ports`設定に比べて、より柔軟な制御が可能

## 実験5：ローリングアップデートとロールバック

Kubernetesの最も強力な機能の一つが、**無停止でのアプリケーション更新（ローリングアップデート）**です。

### 実験準備：Nginx 1.25から1.26へアップデート

現在のDeploymentのイメージバージョンを確認：

```bash
kubectl get deployment nginx-deployment -o jsonpath='{.spec.template.spec.containers[0].image}'
```

出力：`nginx:1.25`

### 実験手順：イメージバージョンを変更

```yaml
# nginx-deployment.yaml（image部分のみ変更）
    spec:
      containers:
      - name: nginx
        image: nginx:1.26  # 1.25 → 1.26に変更
        ports:
        - containerPort: 80
```

```bash
# 変更を適用
kubectl apply -f nginx-deployment.yaml

# ローリングアップデートの進行をリアルタイムで観察
kubectl rollout status deployment/nginx-deployment
```

**観察結果：**

```
Waiting for deployment "nginx-deployment" rollout to finish: 1 out of 3 new replicas have been updated...
Waiting for deployment "nginx-deployment" rollout to finish: 2 out of 3 new replicas have been updated...
Waiting for deployment "nginx-deployment" rollout to finish: 1 old replicas are pending termination...
deployment "nginx-deployment" successfully rolled out
```

Podの状態変化を詳しく見る：

```bash
kubectl get pods -w
```

**重要な動作：**
- 一度に全てのPodを入れ替えるのではなく、**段階的に更新**
- 新しいPodが`Running`になってから、古いPodを削除
- **ダウンタイムなし**でバージョンアップが完了

### ロールバック：前のバージョンに戻す

もし新しいバージョンに問題があった場合、簡単に戻せます。

```bash
# ロールバックを実行
kubectl rollout undo deployment/nginx-deployment

# 状態確認
kubectl rollout status deployment/nginx-deployment

# イメージバージョン確認
kubectl get deployment nginx-deployment -o jsonpath='{.spec.template.spec.containers[0].image}'
```

出力：`nginx:1.25`（元のバージョンに戻った）

### ロールアウト履歴の確認

```bash
# 過去のデプロイ履歴を表示
kubectl rollout history deployment/nginx-deployment
```

実行結果：

```
deployment.apps/nginx-deployment
REVISION  CHANGE-CAUSE
1         <none>
2         <none>
3         <none>
```

特定のリビジョンに戻すことも可能：

```bash
# リビジョン2に戻す例
kubectl rollout undo deployment/nginx-deployment --to-revision=2
```

**実験のポイント：**
- 本番環境でも安全にアップデートできる仕組み
- docker-composeでは`down` → `up`で瞬断が発生するが、Kubernetesは無停止
- 問題があれば即座にロールバック可能

## YAMLデバッグのコツと便利なコマンド

実験中にYAMLの記述ミスでエラーが出ることがあります。デバッグ方法を覚えておきましょう。

### Dry-runでYAMLを検証

```bash
# 実際に適用せずに検証だけする
kubectl apply -f nginx-deployment.yaml --dry-run=client

# サーバー側でも検証（より詳しい）
kubectl apply -f nginx-deployment.yaml --dry-run=server
```

エラーがあれば、適用前に検出できます。

### よくあるYAMLエラーと対処法

#### エラー1: インデントミス

```yaml
# NG例（containersのインデントが間違っている）
spec:
containers:  # これはspecの下にあるべき
  - name: nginx
```

**エラーメッセージ：**
```
error: error parsing nginx-deployment.yaml: error converting YAML to JSON
```

**対処法：** YAMLはスペース2個または4個でインデント。タブは使わない。

#### エラー2: labelsとselectorの不一致

```yaml
spec:
  selector:
    matchLabels:
      app: nginx  # ここと
  template:
    metadata:
      labels:
        app: web  # ここが一致していない
```

**エラーメッセージ：**
```
The Deployment "nginx-deployment" is invalid: spec.template.metadata.labels: Invalid value
```

**対処法：** `selector.matchLabels`と`template.metadata.labels`は完全一致させる。

### 便利な確認コマンド集

```bash
# リソースの詳細を確認（問題の原因を特定）
kubectl describe deployment nginx-deployment
kubectl describe pod <pod-name>

# YAMLの実際の状態を出力（現在の設定を確認）
kubectl get deployment nginx-deployment -o yaml

# ログ確認（コンテナ内のエラーを見る）
kubectl logs <pod-name>

# Pod内でコマンド実行（デバッグ用）
kubectl exec -it <pod-name> -- /bin/bash
```

**実践のポイント：**
- エラーメッセージをよく読む（どの行が問題か示してくれる）
- `kubectl describe`でEventsを確認する
- YAML構造は公式ドキュメントの例を参照する

{{< linkcard "https://kubernetes.io/ja/docs/concepts/workloads/controllers/deployment/" >}}

## リソースのクリーンアップ

実験が終わったら、作成したリソースを削除しましょう。

```bash
# Deploymentを削除（関連するPodも自動削除）
kubectl delete -f nginx-deployment.yaml

# Serviceを削除
kubectl delete service nginx-service-clusterip
kubectl delete service nginx-service-nodeport
kubectl delete service nginx-service-loadbalancer

# 全て削除されたか確認
kubectl get all
```

クラスタ自体を停止する場合：

```bash
minikube stop
```

## 第2回のまとめ：実験で学んだこと

今回、あなたは以下の実験を通じてKubernetesの動作原理を体感しました：

- ✅ DeploymentのYAML構造を理解し、自分で記述できるようになった
- ✅ レプリカ数の変更でスケーリングを体験
- ✅ Podを削除して自己修復機能を確認
- ✅ Serviceの3つのタイプ（ClusterIP、NodePort、LoadBalancer）を使い分け
- ✅ ローリングアップデートで無停止更新を実践
- ✅ YAMLデバッグの基本を習得

**実験から得られた重要な気づき：**

1. **宣言的設定の威力**: YAMLで「あるべき状態」を書くだけで、Kubernetesが勝手に調整してくれる
2. **自己修復**: Podが落ちても自動復旧。本番運用で重要な機能
3. **無停止更新**: ローリングアップデートで、ユーザーに影響なくバージョンアップ可能
4. **柔軟なネットワーク制御**: Serviceタイプを変えるだけで、公開範囲を簡単に変更できる

docker-composeと比較すると、確かにYAMLは長くなりました。しかし、その分だけ**細かい制御**と**本番運用に必要な機能**が手に入ります。

## 【シリーズ第3回予告】ConfigMap・Secretと実用アプリケーション

次回は、より実用的なアプリケーション構成に挑戦します。

**次回のトピック：**

- **ConfigMapでアプリケーション設定を外部化**：環境変数をYAMLから分離
- **Secretで機密情報を安全に管理**：パスワード、APIキーの扱い方
- **2層アプリケーションのデプロイ**：WebアプリとDBを連携させる
- **PersistentVolumeでデータ永続化**：Podが消えてもデータを保持
- **ヘルスチェックの設定**：Liveness ProbeとReadiness Probeで安定性向上

docker-composeで管理していた実用的なアプリケーションを、Kubernetesで動かしてみましょう。

お楽しみに！

---

**この記事が役に立ったら：**

- 次回の記事もお見逃しなく
- 実際に手を動かして実験してみてください
- わからないことがあれば、[@nqounet](https://x.com/nqounet)までお気軽にどうぞ

**参考リンク：**

{{< linkcard "https://kubernetes.io/ja/docs/home/" >}}

{{< linkcard "https://kubernetes.io/ja/docs/concepts/workloads/controllers/deployment/" >}}

{{< linkcard "https://kubernetes.io/ja/docs/concepts/services-networking/service/" >}}
