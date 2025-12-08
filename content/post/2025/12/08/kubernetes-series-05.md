---
title: "Kubernetesを完全に理解した（第5回）- Serviceで実現する負荷分散"
draft: true
tags:
- kubernetes
- service
- load-balancing
- networking
- clusterip
description: "動的に変化するPod群への安定したアクセスを実現するServiceの概念。複数のPodへのトラフィック分散を実際に確認します。"
---

## 導入 - 第4回の振り返りと第5回で学ぶこと

前回の記事では、**Deployment**を使ってゼロダウンタイムでアプリケーションをアップデートする方法を学びました。

**第4回のおさらい:**

- DeploymentとReplicaSetの関係（Deploymentが内部でReplicaSetを管理）
- ローリングアップデート戦略（maxSurge/maxUnavailableの制御）
- nginx 1.25から1.26への実際のバージョンアップ
- デプロイ履歴の管理とロールバック
- Readiness Probeの重要性

しかし、Deploymentで複数のPodを動かせるようになっても、重大な問題が残っています。それは、**どうやってこれらのPodにアクセスするのか？**という点です。

実際に試してみると、こんな問題が発生します：

```bash
# Deploymentで3つのPodを作成
kubectl create deployment nginx --image=nginx:1.26-alpine --replicas=3

# Pod IPアドレスを確認
kubectl get pods -o wide
# NAME                     READY   STATUS    IP            NODE
# nginx-7b8c9d5f6b-abc12   1/1     Running   10.244.1.5    node-1
# nginx-7b8c9d5f6b-def34   1/1     Running   10.244.2.8    node-2
# nginx-7b8c9d5f6b-ghi56   1/1     Running   10.244.1.9    node-1

# 特定のPod IPに直接アクセスしてみる
curl http://10.244.1.5
# 成功！でも、このやり方には問題がある...
```

**なぜPod IPに直接アクセスしてはいけないのか？**

1. **IPアドレスが動的に変わる** - Podが再作成されると新しいIPが割り当てられる
2. **負荷分散できない** - 特定のPodだけにアクセスが集中してしまう
3. **Pod障害に対応できない** - そのPodが停止したらアクセス不可能

第5回となる本記事では、この問題を解決する**Service**について学習します。

**この記事で学ぶこと:**

- なぜPodに直接アクセスしてはいけないのか（Podの短命性）
- Serviceの3つのタイプ（ClusterIP、NodePort、LoadBalancer）
- ClusterIPで内部通信を実現する方法
- NodePortで外部アクセスを実現する方法
- LoadBalancerとクラウド統合
- サービスディスカバリとDNS名前解決
- 実際にトラフィック分散を確認する手順

それでは、Serviceによる安定したアクセスと負荷分散を体験していきましょう！

## なぜPodに直接アクセスしてはいけないのか - Podの短命性とIPの変化

### Podの短命性（Ephemeral Nature）

Kubernetesにおいて、**Podは短命（Ephemeral）な存在**として設計されています。これは、Podが頻繁に作成・削除されることを前提としているということです。

**Podが再作成される典型的なケース:**

```bash
# シナリオ1: Deploymentによるローリングアップデート
kubectl set image deployment/nginx nginx=nginx:1.27-alpine
# → 全てのPodが新しいIPで再作成される

# シナリオ2: Podの障害
# → ReplicaSetが自動的に新しいPodを作成（新しいIP）

# シナリオ3: ノード障害
# → 全てのPodが別ノードで再作成（新しいIP）

# シナリオ4: スケーリング
kubectl scale deployment/nginx --replicas=5
# → 新しいPodが追加される（それぞれ新しいIP）
```

### Pod IP直接アクセスの問題を実証

実際にPod IPの変化を確認してみましょう：

```bash
# 1. Deploymentを作成
kubectl create deployment web-app --image=nginx:1.26-alpine --replicas=3

# 2. Pod IPを確認
kubectl get pods -o wide
# NAME                       READY   STATUS    IP            NODE
# web-app-7b8c9d5f6b-abc12   1/1     Running   10.244.1.10   node-1
# web-app-7b8c9d5f6b-def34   1/1     Running   10.244.2.15   node-2
# web-app-7b8c9d5f6b-ghi56   1/1     Running   10.244.1.11   node-1

# 3. 1つのPodを手動で削除
kubectl delete pod web-app-7b8c9d5f6b-abc12

# 4. 新しいPodが作成される（IPが変わる！）
kubectl get pods -o wide
# NAME                       READY   STATUS    IP            NODE
# web-app-7b8c9d5f6b-xyz99   1/1     Running   10.244.1.20   node-1  ← 新しいIP！
# web-app-7b8c9d5f6b-def34   1/1     Running   10.244.2.15   node-2
# web-app-7b8c9d5f6b-ghi56   1/1     Running   10.244.1.11   node-1

# 古いIP（10.244.1.10）にアクセスしようとすると失敗する
```

### 複数Podへの負荷分散の問題

仮にPod IPが安定していたとしても、**負荷分散の問題**があります：

```bash
# 3つのPodがあるとして...
# クライアントアプリケーションのコード例（疑似コード）

# 問題のあるアプローチ:
target_ip = "10.244.1.10"  # 1つのPod IPにハードコード
response = http_get(target_ip)
# → このPodだけに負荷が集中！他の2つのPodは遊んでいる

# 手動で負荷分散を実装する必要がある？
pod_ips = ["10.244.1.10", "10.244.2.15", "10.244.1.11"]
target_ip = random.choice(pod_ips)
# → IPが変わったら？新しいPodが追加されたら？
# → アプリケーションコードが複雑になる！
```

### Serviceの登場 - 問題を一気に解決

Serviceは、これらの問題を全て解決します：

```
+------------------+
|     Service      |  ← 固定されたIPとDNS名
|  10.96.10.100    |  ← クラスタ内でずっと同じ
|  (ClusterIP)     |
+------------------+
        |
        | 自動負荷分散
        |
   +----+----+----+
   |    |    |    |
   v    v    v    v
 Pod1 Pod2 Pod3 Pod4  ← IPは動的に変わる
 (動的IP) (動的IP)
```

**Serviceの利点:**

- ✅ **固定IPアドレス** - ServiceのClusterIPは変わらない
- ✅ **固定DNS名** - `service-name.namespace.svc.cluster.local`
- ✅ **自動負荷分散** - 複数のPodに自動的にトラフィックを振り分け
- ✅ **自動サービスディスカバリ** - Podが増減しても自動追跡
- ✅ **ヘルスチェック統合** - 不健全なPodを自動的に除外

## Serviceの3つのタイプ - ClusterIP、NodePort、LoadBalancer

Serviceには主に3つのタイプがあり、それぞれ異なる用途で使用します。

### タイプ比較表

| タイプ | アクセス範囲 | IPアドレス | 主な用途 | 例 |
|--------|------------|-----------|---------|-----|
| **ClusterIP** | クラスタ内のみ | クラスタ内部IP | 内部通信 | DB、キャッシュ、内部API |
| **NodePort** | 外部からノードIP経由 | ClusterIP + 各ノードのポート | 開発・テスト | ローカル開発 |
| **LoadBalancer** | 外部からロードバランサ経由 | ClusterIP + 外部IP | 本番環境の外部公開 | Webサーバー、API |

### 各タイプの概要

**ClusterIP（デフォルト）:**

```yaml
apiVersion: v1
kind: Service
metadata:
  name: backend-service
spec:
  type: ClusterIP  # デフォルトなので省略可能
  selector:
    app: backend
  ports:
  - port: 80
    targetPort: 8080
```

- クラスタ内部からのみアクセス可能
- 固定のClusterIPが割り当てられる（例: `10.96.10.100`）
- Pod間通信に最適

**NodePort:**

```yaml
apiVersion: v1
kind: Service
metadata:
  name: web-service
spec:
  type: NodePort
  selector:
    app: web
  ports:
  - port: 80
    targetPort: 8080
    nodePort: 30080  # 30000-32767の範囲
```

- 全てのノードの特定ポートでサービスを公開
- `<NodeIP>:<NodePort>`でアクセス可能
- 開発環境やテスト環境向け

**LoadBalancer:**

```yaml
apiVersion: v1
kind: Service
metadata:
  name: public-web
spec:
  type: LoadBalancer
  selector:
    app: web
  ports:
  - port: 80
    targetPort: 8080
```

- クラウドプロバイダのロードバランサを自動プロビジョニング
- 外部からアクセス可能な固定IPを取得
- 本番環境での外部公開に最適

### タイプ間の関係

実は、これらのタイプは階層的な関係にあります：

```
LoadBalancer
  ├─ NodePort の機能を全て含む
  │   ├─ ClusterIP の機能を全て含む
  │   │   └─ 基本的な負荷分散とサービスディスカバリ
  │   └─ 全ノードでのポート公開
  └─ 外部ロードバランサの自動作成
```

つまり：

- **NodePort**を作ると、ClusterIPも自動的に作成される
- **LoadBalancer**を作ると、ClusterIPとNodePortも自動的に作成される

## ClusterIPで内部通信 - YAMLマニフェストと動作確認

ClusterIPは最も基本的で、最も頻繁に使用されるServiceタイプです。マイクロサービスアーキテクチャでは、ほとんどのサービスがClusterIPです。

### ClusterIPの作成

まず、バックエンドアプリケーションとして3つのnginx Podを作成し、Serviceで公開します：

```bash
# 1. Deploymentを作成
cat > backend-deployment.yaml << 'EOF'
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend-app
  labels:
    app: backend
spec:
  replicas: 3
  selector:
    matchLabels:
      app: backend
  template:
    metadata:
      labels:
        app: backend
    spec:
      containers:
      - name: nginx
        image: nginx:1.26-alpine
        ports:
        - containerPort: 80
        resources:
          requests:
            memory: "32Mi"
            cpu: "50m"
EOF

kubectl apply -f backend-deployment.yaml

# 2. ClusterIP Serviceを作成
cat > backend-service.yaml << 'EOF'
apiVersion: v1
kind: Service
metadata:
  name: backend-service
spec:
  type: ClusterIP  # デフォルトなので省略可能
  selector:
    app: backend   # app=backendラベルを持つPodを対象
  ports:
  - name: http
    protocol: TCP
    port: 80       # Serviceが受け付けるポート
    targetPort: 80 # Pod内のコンテナポート
EOF

kubectl apply -f backend-service.yaml
```

### Serviceの詳細確認

```bash
# Service情報を確認
kubectl get service backend-service
# NAME              TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
# backend-service   ClusterIP   10.96.123.45    <none>        80/TCP    10s
#                                ^^^^^^^^^^^^
#                                固定ClusterIP（クラスタ内でずっと同じ）

# 詳細情報を表示
kubectl describe service backend-service
# Name:              backend-service
# Namespace:         default
# Labels:            <none>
# Annotations:       <none>
# Selector:          app=backend  ← このラベルを持つPodを対象
# Type:              ClusterIP
# IP Family Policy:  SingleStack
# IP Families:       IPv4
# IP:                10.96.123.45  ← ServiceのClusterIP
# IPs:               10.96.123.45
# Port:              http  80/TCP
# TargetPort:        80/TCP
# Endpoints:         10.244.1.10:80,10.244.1.11:80,10.244.2.15:80  ← 対象Pod IPリスト
# Session Affinity:  None
# Events:            <none>
```

### Endpointsの確認

ServiceはラベルセレクタでPodを見つけ、**Endpoints**リソースに記録します：

```bash
# Endpointsを確認
kubectl get endpoints backend-service
# NAME              ENDPOINTS                                          AGE
# backend-service   10.244.1.10:80,10.244.1.11:80,10.244.2.15:80      30s
#                   ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
#                   ServiceがトラフィックをルーティングするPod IPリスト

# 詳細表示
kubectl describe endpoints backend-service
# Name:         backend-service
# Namespace:    default
# Labels:       <none>
# Annotations:  endpoints.kubernetes.io/last-change-trigger-time: 2024-...
# Subsets:
#   Addresses:          10.244.1.10,10.244.1.11,10.244.2.15
#   NotReadyAddresses:  <none>
#   Ports:
#     Name     Port  Protocol
#     ----     ----  --------
#     http     80    TCP
```

**重要なポイント:**

- EndpointsはServiceと同じ名前で自動作成される
- PodのIPが動的に変わっても、Endpointsは自動更新される
- Readiness Probeが失敗したPodは`NotReadyAddresses`に移動される（トラフィックが流れない）

### 負荷分散の確認

ClusterIP Serviceへのアクセスを実際に試してみましょう：

```bash
# テスト用Podを作成して内部からアクセス
kubectl run test-pod --image=curlimages/curl:latest --rm -it --restart=Never -- sh

# Pod内で実行:
# 1. Service経由でアクセス（ClusterIP）
curl http://10.96.123.45
# Welcome to nginx! （成功！）

# 2. DNS名でアクセス（推奨）
curl http://backend-service
# Welcome to nginx! （成功！）

# 3. FQDN（完全修飾ドメイン名）でアクセス
curl http://backend-service.default.svc.cluster.local
# Welcome to nginx! （成功！）

# 4. 負荷分散を確認するため、複数回アクセス
for i in {1..10}; do
  curl -s http://backend-service | grep -o "Server: .*"
done
# → 複数のPodに分散されているはず
```

### カスタムレスポンスで負荷分散を視覚化

各Podが異なるレスポンスを返すようにして、負荷分散を視覚的に確認してみましょう：

```bash
# 各Podに異なるコンテンツを設定
PODS=$(kubectl get pods -l app=backend -o name)

i=1
for pod in $PODS; do
  kubectl exec $pod -- sh -c "echo 'Pod $i responding!' > /usr/share/nginx/html/index.html"
  i=$((i+1))
done

# テストPodから繰り返しアクセス
kubectl run test-pod --image=curlimages/curl:latest --rm -it --restart=Never -- sh

# Pod内で:
for i in {1..15}; do
  curl -s http://backend-service && sleep 0.5
done

# 出力例:
# Pod 1 responding!
# Pod 3 responding!
# Pod 2 responding!
# Pod 1 responding!
# Pod 3 responding!
# Pod 2 responding!
# ...
# → ラウンドロビンで分散されている！
```

### ポート変換（port vs targetPort）

Serviceの`port`と`targetPort`は異なる値を設定できます：

```yaml
apiVersion: v1
kind: Service
metadata:
  name: custom-port-service
spec:
  selector:
    app: backend
  ports:
  - name: http
    protocol: TCP
    port: 8080        # Service側のポート（クライアントはこのポートにアクセス）
    targetPort: 80    # Pod側のポート（nginxは80番で待機）
```

これにより、以下が可能になります：

```bash
# Serviceには8080番ポートでアクセス
curl http://custom-port-service:8080

# でも、実際のPodは80番で待機している
# Serviceが自動的にポート変換してくれる！
```

**用途:**

- レガシーアプリケーションのポート標準化
- セキュリティ（内部ポート番号を隠蔽）
- 複数のServiceで同じPodを異なるポートで公開

## NodePortで外部アクセス - ポート番号の範囲と使い方

NodePortは、クラスタ外部からアクセスできるようにするServiceタイプです。開発環境やテスト環境で頻繁に使用されます。

### NodePortの作成

```bash
# NodePort Serviceを作成
cat > web-nodeport.yaml << 'EOF'
apiVersion: v1
kind: Service
metadata:
  name: web-nodeport
spec:
  type: NodePort
  selector:
    app: web
  ports:
  - name: http
    protocol: TCP
    port: 80          # ClusterIP側のポート
    targetPort: 80    # Pod側のポート
    nodePort: 30080   # ノード側のポート（省略可能）
EOF

# まずDeploymentを作成
kubectl create deployment web --image=nginx:1.26-alpine --replicas=2

# Serviceを適用
kubectl apply -f web-nodeport.yaml

# 確認
kubectl get service web-nodeport
# NAME           TYPE       CLUSTER-IP      EXTERNAL-IP   PORT(S)        AGE
# web-nodeport   NodePort   10.96.200.50    <none>        80:30080/TCP   5s
#                                                          ^^^^^^^^
#                                                          <ClusterIP>:<NodePort>
```

### NodePortの動作原理

NodePortは、全てのノードで指定されたポートをリッスンし、そのポートへのトラフィックをServiceに転送します：

```
外部クライアント
    |
    | http://192.168.49.2:30080
    v
+-------------------+     +-------------------+     +-------------------+
| Node 1            |     | Node 2            |     | Node 3            |
| :30080 ← Listen   |     | :30080 ← Listen   |     | :30080 ← Listen   |
+-------------------+     +-------------------+     +-------------------+
    |                         |                         |
    +-------------------------+-------------------------+
                              |
                              v
                     +------------------+
                     |   Service        |
                     |   ClusterIP      |
                     +------------------+
                              |
                     +--------+--------+
                     |                 |
                   Pod1              Pod2
```

**重要なポイント:**

- どのノードのIPアドレス経由でアクセスしても、同じServiceに到達する
- Podがそのノードで動作していなくても問題ない（自動転送）

### ポート番号の範囲と制限

**NodePortのポート範囲:**

- デフォルト範囲: **30000-32767**
- この範囲外のポートは指定できない
- 範囲はAPI Serverの起動オプションで変更可能（非推奨）

```yaml
# これはエラーになる
spec:
  type: NodePort
  ports:
  - port: 80
    nodePort: 8080  # NG! 30000未満
```

```yaml
# nodePortを省略すると自動割り当て
spec:
  type: NodePort
  ports:
  - port: 80
    # nodePortを指定しない → 30000-32767から自動割り当て
```

### minikubeでのアクセス

```bash
# minikube環境でNodePort Serviceにアクセス
minikube service web-nodeport --url
# http://192.168.49.2:30080

# ブラウザで開く
minikube service web-nodeport

# curlでテスト
curl http://192.168.49.2:30080
# Welcome to nginx!
```

### 本番環境でのNodePortの制限

NodePortは開発・テスト環境では便利ですが、本番環境では以下の問題があります：

**デメリット:**

- ❌ 高番号ポート（30000番台）は覚えにくい
- ❌ HTTPSの標準ポート（443）やHTTPの標準ポート（80）が使えない
- ❌ ノードIPアドレスを直接公開（セキュリティリスク）
- ❌ ノードが増減した時にクライアント側で管理が必要
- ❌ TLS証明書の管理が複雑

**推奨される使い方:**

- ✅ ローカル開発環境（minikube、kind）
- ✅ テスト環境での一時的な公開
- ✅ LoadBalancerが使えない環境での次善策

## LoadBalancerとクラウド統合 - AWS/GCP/Azureでの利用

LoadBalancerタイプは、クラウド環境での本番運用に最適なServiceタイプです。

### LoadBalancerの作成

```yaml
# web-loadbalancer.yaml
apiVersion: v1
kind: Service
metadata:
  name: web-loadbalancer
spec:
  type: LoadBalancer
  selector:
    app: web
  ports:
  - name: http
    protocol: TCP
    port: 80
    targetPort: 80
  - name: https
    protocol: TCP
    port: 443
    targetPort: 443
```

```bash
# Serviceを作成
kubectl apply -f web-loadbalancer.yaml

# 確認（クラウド環境の場合）
kubectl get service web-loadbalancer
# NAME               TYPE           CLUSTER-IP      EXTERNAL-IP       PORT(S)                      AGE
# web-loadbalancer   LoadBalancer   10.96.150.100   35.123.45.67      80:31234/TCP,443:31567/TCP   2m
#                                                    ^^^^^^^^^^^^
#                                                    外部IPアドレス（クラウドLBが自動作成）

# minikubeの場合（外部IPは<pending>のまま）
# NAME               TYPE           CLUSTER-IP      EXTERNAL-IP   PORT(S)                      AGE
# web-loadbalancer   LoadBalancer   10.96.150.100   <pending>     80:31234/TCP,443:31567/TCP   2m
```

### クラウドプロバイダ別の動作

**AWS（EKS）:**

```bash
# LoadBalancerタイプのServiceを作成すると...
kubectl apply -f web-loadbalancer.yaml

# 自動的にClassic Load BalancerまたはNetwork Load Balancerが作成される
# EXTERNAL-IPにはELBのDNS名が表示される

kubectl get svc web-loadbalancer
# NAME               TYPE           CLUSTER-IP      EXTERNAL-IP                                             PORT(S)
# web-loadbalancer   LoadBalancer   10.100.200.50   a1b2c3d4e5f6g7h8.us-west-2.elb.amazonaws.com          80:30123/TCP

# アノテーションでNetwork Load Balancerを指定
apiVersion: v1
kind: Service
metadata:
  name: web-nlb
  annotations:
    service.beta.kubernetes.io/aws-load-balancer-type: "nlb"
spec:
  type: LoadBalancer
  selector:
    app: web
  ports:
  - port: 80
```

**GCP（GKE）:**

```bash
# LoadBalancerタイプのServiceを作成すると...
# 自動的にGoogle Cloud Load Balancerが作成される

kubectl get svc web-loadbalancer
# NAME               TYPE           CLUSTER-IP      EXTERNAL-IP      PORT(S)
# web-loadbalancer   LoadBalancer   10.3.240.10     35.123.45.67     80:30456/TCP
#                                                    ^^^^^^^^^^^^
#                                                    グローバルIPアドレス
```

**Azure（AKS）:**

```bash
# LoadBalancerタイプのServiceを作成すると...
# 自動的にAzure Load Balancerが作成される

kubectl get svc web-loadbalancer
# NAME               TYPE           CLUSTER-IP      EXTERNAL-IP       PORT(S)
# web-loadbalancer   LoadBalancer   10.0.123.45     20.50.100.200     80:31789/TCP

# 静的パブリックIPを使用する場合
apiVersion: v1
kind: Service
metadata:
  name: web-static-ip
  annotations:
    service.beta.kubernetes.io/azure-load-balancer-resource-group: "myResourceGroup"
spec:
  type: LoadBalancer
  loadBalancerIP: 20.50.100.200  # 事前に作成した静的IP
  selector:
    app: web
  ports:
  - port: 80
```

### minikubeでのLoadBalancerサポート

minikubeではデフォルトでLoadBalancerタイプは`<pending>`のままですが、`minikube tunnel`で擬似的にサポートできます：

```bash
# 別ターミナルでtunnelを起動（要sudo）
minikube tunnel
# Status:
#         machine: minikube
#         pid: 12345
#         route: 10.96.0.0/12 -> 192.168.49.2
#         minikube: Running
#         services: [web-loadbalancer]
#     errors:
#                 minikube: no errors
#                 router: no errors
#                 loadbalancer emulator: no errors

# 元のターミナルで確認
kubectl get svc web-loadbalancer
# NAME               TYPE           CLUSTER-IP      EXTERNAL-IP      PORT(S)
# web-loadbalancer   LoadBalancer   10.96.150.100   10.96.150.100    80:31234/TCP
#                                                    ^^^^^^^^^^^^^
#                                                    EXTERNAL-IPが割り当てられた！

# アクセステスト
curl http://10.96.150.100
# Welcome to nginx!
```

### LoadBalancerの高度な設定

```yaml
# production-loadbalancer.yaml
apiVersion: v1
kind: Service
metadata:
  name: production-web
  annotations:
    # AWS固有の設定例
    service.beta.kubernetes.io/aws-load-balancer-type: "nlb"
    service.beta.kubernetes.io/aws-load-balancer-backend-protocol: "http"
    service.beta.kubernetes.io/aws-load-balancer-ssl-cert: "arn:aws:acm:..."
    service.beta.kubernetes.io/aws-load-balancer-ssl-ports: "443"
    
    # クライアントIPの保持
    service.beta.kubernetes.io/aws-load-balancer-proxy-protocol: "*"
spec:
  type: LoadBalancer
  
  # クライアントIPを保持（externalTrafficPolicy）
  externalTrafficPolicy: Local  # デフォルトはCluster
  
  # セッションアフィニティ（同じクライアントは同じPodへ）
  sessionAffinity: ClientIP
  sessionAffinityConfig:
    clientIP:
      timeoutSeconds: 10800  # 3時間
  
  selector:
    app: web
  
  ports:
  - name: http
    protocol: TCP
    port: 80
    targetPort: 8080
  - name: https
    protocol: TCP
    port: 443
    targetPort: 8443
```

**externalTrafficPolicyの説明:**

- **Cluster（デフォルト）**: ノード間でトラフィックを転送、負荷分散が均等
- **Local**: 同じノード内のPodにのみ転送、クライアントIPを保持

## サービスディスカバリとDNS - 名前解決の仕組み

Kubernetesは、Serviceに対して自動的にDNSレコードを作成します。これにより、IPアドレスを気にせずに名前でアクセスできます。

### DNS名の形式

Serviceが作成されると、以下の形式でDNS名が自動登録されます：

```
<service-name>.<namespace>.svc.cluster.local
```

**例:**

```bash
# defaultネームスペースのbackend-service
backend-service.default.svc.cluster.local

# productionネームスペースのapi-service
api-service.production.svc.cluster.local

# kube-systemネームスペースのkube-dns
kube-dns.kube-system.svc.cluster.local
```

### 名前解決のレベル

同じネームスペース内では、より短い名前でアクセスできます：

```bash
# テストPodを作成
kubectl run dns-test --image=curlimages/curl:latest --rm -it -- sh

# Pod内で実行:

# 1. 短縮名（同じネームスペース内のみ）
curl http://backend-service
# → backend-service.default.svc.cluster.local に解決

# 2. ネームスペース付き（異なるネームスペースからもアクセス可能）
curl http://backend-service.default
# → backend-service.default.svc.cluster.local に解決

# 3. 完全修飾ドメイン名（FQDN、最も明示的）
curl http://backend-service.default.svc.cluster.local
# → そのまま解決

# 4. nslookupで確認
nslookup backend-service
# Server:    10.96.0.10
# Address:   10.96.0.10:53
#
# Name:      backend-service.default.svc.cluster.local
# Address:   10.96.123.45  ← ServiceのClusterIP
```

### 実際のマイクロサービス連携例

フロントエンドとバックエンドの連携を例にします：

```yaml
# backend-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend
spec:
  replicas: 3
  selector:
    matchLabels:
      app: backend
  template:
    metadata:
      labels:
        app: backend
    spec:
      containers:
      - name: api
        image: my-backend-api:v1
        ports:
        - containerPort: 8080
---
# backend-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: backend-api
spec:
  selector:
    app: backend
  ports:
  - port: 80
    targetPort: 8080
---
# frontend-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend
spec:
  replicas: 2
  selector:
    matchLabels:
      app: frontend
  template:
    metadata:
      labels:
        app: frontend
    spec:
      containers:
      - name: web
        image: my-frontend-web:v1
        env:
        - name: BACKEND_URL
          value: "http://backend-api"  # ← DNS名でバックエンドを参照！
        ports:
        - containerPort: 80
```

フロントエンドのアプリケーションコード内では：

```javascript
// フロントエンド内のコード例
const backendUrl = process.env.BACKEND_URL; // "http://backend-api"

// APIリクエスト
fetch(`${backendUrl}/api/users`)
  .then(response => response.json())
  .then(data => console.log(data));

// KubernetesのDNSが自動的に以下を解決:
// backend-api → backend-api.default.svc.cluster.local → 10.96.123.45
// → 3つのバックエンドPodに負荷分散
```

### DNS-based Service Discovery の利点

- ✅ **IP管理不要** - IPアドレスを知る必要がない
- ✅ **環境非依存** - 開発・ステージング・本番で同じコードが動作
- ✅ **自動更新** - PodのIPが変わってもDNS名は不変
- ✅ **可読性** - `backend-api`の方が`10.96.123.45`より分かりやすい

### CoreDNSの確認

KubernetesのDNS解決は**CoreDNS**が担当しています：

```bash
# CoreDNSのPodを確認
kubectl get pods -n kube-system -l k8s-app=kube-dns
# NAME                       READY   STATUS    RESTARTS   AGE
# coredns-5d78c9869d-abcd1   1/1     Running   0          10d
# coredns-5d78c9869d-efgh2   1/1     Running   0          10d

# CoreDNSの設定を確認
kubectl get configmap coredns -n kube-system -o yaml
# apiVersion: v1
# kind: ConfigMap
# data:
#   Corefile: |
#     .:53 {
#         errors
#         health
#         kubernetes cluster.local in-addr.arpa ip6.arpa {
#            pods insecure
#            fallthrough in-addr.arpa ip6.arpa
#         }
#         prometheus :9153
#         forward . /etc/resolv.conf
#         cache 30
#         loop
#         reload
#         loadbalance
#     }
```

## まとめと次回予告

本記事では、Kubernetesの**Service**を使った安定したアクセスと負荷分散について、以下の内容を学習しました：

### 学んだこと

1. **Podの短命性と問題点**
   - PodのIPアドレスは動的に変化する
   - Pod IPへの直接アクセスは推奨されない
   - 負荷分散とサービスディスカバリの必要性

2. **Serviceの3つのタイプ**
   - **ClusterIP**: クラスタ内部通信用（デフォルト、最も一般的）
   - **NodePort**: 開発・テスト環境での外部公開
   - **LoadBalancer**: 本番環境での外部公開（クラウド統合）

3. **ClusterIPの実践**
   - YAMLマニフェストの書き方
   - Endpointsリソースの自動管理
   - 実際の負荷分散動作の確認
   - port vs targetPortの違い

4. **NodePortの利用**
   - 30000-32767のポート範囲
   - 全ノードでのポート公開
   - minikubeでのアクセス方法
   - 本番環境での制限

5. **LoadBalancerとクラウド統合**
   - AWS/GCP/Azureでの自動プロビジョニング
   - externalTrafficPolicyの違い
   - セッションアフィニティ
   - クラウド固有のアノテーション

6. **サービスディスカバリとDNS**
   - 自動DNS名登録の仕組み
   - FQDN形式（`<service>.<namespace>.svc.cluster.local`）
   - 短縮名でのアクセス
   - マイクロサービス間通信の実装

### 重要なポイント

- **Pod IPに直接アクセスしない** - 必ずServiceを経由する
- **ClusterIPが基本** - 内部通信はClusterIPで十分
- **DNS名を活用** - 環境変数にService名を使う
- **Readiness Probeとの連携** - 不健全なPodは自動除外される
- **ラベルセレクタが鍵** - ServiceとPodを正しく紐付ける

### 次回予告 - 第6回「ConfigMapとSecretで設定を管理」

次回は、**ConfigMap**と**Secret**について学習します。

アプリケーションには設定情報（データベース接続文字列、APIキーなど）が必要ですが、コンテナイメージにハードコードするのは良い方法ではありません。環境ごとに異なる設定をどう管理すればよいのでしょうか？

第6回では、以下を学習します：

- ConfigMapによる設定の外部化
- Secretによる機密情報の管理
- 環境変数としての注入
- ボリュームマウントでの利用
- 設定の動的更新
- ベストプラクティスとセキュリティ

DeploymentとServiceに加えて、ConfigMapとSecretを使いこなすことで、実用的なアプリケーションデプロイが可能になります。

ぜひ、実際に手を動かして、Serviceによる安定したアクセスと負荷分散を体験してください！

## クリーンアップ

実験で作成したリソースをクリーンアップしましょう：

```bash
# Deploymentを削除
kubectl delete deployment backend-app web

# Serviceを削除
kubectl delete service backend-service web-nodeport web-loadbalancer

# 確認
kubectl get all
# No resources found in default namespace.
```

Serviceを削除すると、クラウド環境では自動作成されたロードバランサも削除されます（課金停止）。
