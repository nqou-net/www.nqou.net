---
title: "Kubernetesを完全に理解した（第10回）- IngressでHTTPルーティング"
draft: true
tags:
- kubernetes
- ingress
- routing
- tls
- https
description: "複数のWebアプリケーションを一つのクラスタで効率的に公開する方法。HTTPS対応の本格的なサービスを構築します。"
---

## はじめに - 第9回の振り返りと第10回で学ぶこと

前回の第9回では、Namespaceを使った環境分離について学びました。一つのKubernetesクラスタ上で開発・検証・本番環境を安全に共存させる方法、ResourceQuotaによるリソース制限、そしてNamespace間の通信制御について理解できました。

今回の第10回では、**Ingress（イングレス）** を使ったHTTPルーティングについて学びます。複数のWebアプリケーションを一つのクラスタで効率的に公開し、ホスト名やURLパスに基づいたルーティング、そしてHTTPS/TLS対応まで実践します。

本記事で学ぶ内容：

- LoadBalancerとIngressの違い
- Ingress Controllerのインストール
- ホスト名によるルーティング
- URLパスによるルーティング
- TLS/HTTPS対応
- 高度なルーティング機能

## LoadBalancerとIngressの違い

### LoadBalancer Serviceの課題

これまで、外部からアプリケーションにアクセスするためにLoadBalancer Serviceを使用してきました。しかし、LoadBalancerには以下の課題があります。

```bash
# 複数のアプリケーションをLoadBalancerで公開する場合
kubectl expose deployment app1 --type=LoadBalancer --port=80
kubectl expose deployment app2 --type=LoadBalancer --port=80
kubectl expose deployment app3 --type=LoadBalancer --port=80

# 課題：
# - 各アプリケーションに1つずつLoadBalancerが必要
# - クラウド環境では1つのLoadBalancerに課金が発生
# - IPアドレスやポート番号で区別する必要がある
# - ホスト名ベースのルーティングができない
```

**LoadBalancer Serviceの構成図：**

```
インターネット
    |
    ├─ LoadBalancer IP: 203.0.113.1:80  → app1
    ├─ LoadBalancer IP: 203.0.113.2:80  → app2
    └─ LoadBalancer IP: 203.0.113.3:80  → app3
    
コスト: LoadBalancer x 3台分の料金
```

### Ingressによる解決

Ingressは、HTTPレベルでのルーティング機能を提供し、1つのLoadBalancerで複数のアプリケーションを公開できます。

```
インターネット
    |
    LoadBalancer (1つだけ)
    |
    Ingress Controller
    |
    ├─ app1.example.com → app1 Service → app1 Pod
    ├─ app2.example.com → app2 Service → app2 Pod
    └─ app3.example.com → app3 Service → app3 Pod
    
コスト: LoadBalancer x 1台分の料金
```

**Ingressの主なメリット：**

1. **コスト削減**: 1つのLoadBalancerで複数サービスを公開
2. **ホスト名ベースルーティング**: ドメイン名で振り分け
3. **パスベースルーティング**: URLパスで振り分け
4. **TLS/SSL終端**: 証明書の一元管理
5. **負荷分散**: 高度な負荷分散設定
6. **リダイレクトやリライト**: HTTPレベルの制御

## Ingress Controllerのインストール

IngressリソースはKubernetesの標準機能ですが、実際に動作させるためには**Ingress Controller**が必要です。

### 主要なIngress Controller

- **Nginx Ingress Controller**: 最も人気がある
- **Traefik**: 設定が簡単、動的設定に強い
- **HAProxy Ingress**: 高性能
- **Istio Gateway**: サービスメッシュと統合
- **AWS ALB Ingress**: AWS特化

本記事では、最も広く使われている**Nginx Ingress Controller**を使用します。

### Nginx Ingress Controllerのインストール

```bash
# Helmを使用したインストール（推奨）
# Helmがない場合はインストール
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# Nginx Ingressのリポジトリを追加
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

# インストール
helm install nginx-ingress ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace \
  --set controller.service.type=LoadBalancer

# インストール確認
kubectl get pods -n ingress-nginx
# 出力例:
# NAME                                        READY   STATUS    RESTARTS   AGE
# nginx-ingress-controller-5d4b4c8f9f-xxxxx   1/1     Running   0          1m

kubectl get svc -n ingress-nginx
# 出力例:
# NAME                    TYPE           CLUSTER-IP      EXTERNAL-IP   PORT(S)
# nginx-ingress-controller LoadBalancer  10.96.123.45    <pending>     80:32080/TCP,443:32443/TCP
```

**minikubeでの簡易インストール：**

```bash
# minikubeのアドオンを有効化
minikube addons enable ingress

# 確認
kubectl get pods -n ingress-nginx
```

### Ingress Controllerの動作確認

```bash
# Ingress ControllerのPodが起動していることを確認
kubectl get pods -n ingress-nginx -w

# LoadBalancer Serviceが作成されていることを確認
kubectl get svc -n ingress-nginx

# minikubeの場合、IPアドレスを取得
minikube ip
# 出力例: 192.168.49.2
```

## ホスト名によるルーティング

### サンプルアプリケーションのデプロイ

まず、ルーティング先となる2つのアプリケーションをデプロイします。

```yaml
# app1-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app1
spec:
  replicas: 2
  selector:
    matchLabels:
      app: app1
  template:
    metadata:
      labels:
        app: app1
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
          name: app1-html
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: app1-html
data:
  index.html: |
    <!DOCTYPE html>
    <html>
    <head><title>App 1</title></head>
    <body style="background: #3498db; color: white; text-align: center; padding: 50px;">
        <h1>🚀 Application 1</h1>
        <p>You are accessing app1.example.com</p>
    </body>
    </html>
---
apiVersion: v1
kind: Service
metadata:
  name: app1-service
spec:
  selector:
    app: app1
  ports:
  - port: 80
    targetPort: 80
```

```yaml
# app2-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app2
spec:
  replicas: 2
  selector:
    matchLabels:
      app: app2
  template:
    metadata:
      labels:
        app: app2
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
          name: app2-html
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: app2-html
data:
  index.html: |
    <!DOCTYPE html>
    <html>
    <head><title>App 2</title></head>
    <body style="background: #e74c3c; color: white; text-align: center; padding: 50px;">
        <h1>🎯 Application 2</h1>
        <p>You are accessing app2.example.com</p>
    </body>
    </html>
---
apiVersion: v1
kind: Service
metadata:
  name: app2-service
spec:
  selector:
    app: app2
  ports:
  - port: 80
    targetPort: 80
```

```bash
# アプリケーションのデプロイ
kubectl apply -f app1-deployment.yaml
kubectl apply -f app2-deployment.yaml

# 確認
kubectl get deployments
kubectl get services
kubectl get pods
```

### ホストベースルーティングのIngressリソース

```yaml
# ingress-host-routing.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: host-based-routing
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx
  rules:
  - host: app1.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: app1-service
            port:
              number: 80
  - host: app2.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: app2-service
            port:
              number: 80
```

```bash
# Ingressの作成
kubectl apply -f ingress-host-routing.yaml

# Ingressの確認
kubectl get ingress
# 出力例:
# NAME                 CLASS   HOSTS                              ADDRESS         PORTS   AGE
# host-based-routing   nginx   app1.example.com,app2.example.com  192.168.49.2    80      10s

# 詳細情報
kubectl describe ingress host-based-routing
```

### 動作確認（/etc/hostsを編集）

```bash
# minikubeのIPアドレスを確認
minikube ip
# 出力例: 192.168.49.2

# /etc/hostsに追加（Linux/macOS）
echo "192.168.49.2 app1.example.com app2.example.com" | sudo tee -a /etc/hosts

# 動作確認
curl http://app1.example.com
# App 1のHTMLが返される

curl http://app2.example.com
# App 2のHTMLが返される

# ブラウザでもアクセス可能
# http://app1.example.com
# http://app2.example.com
```

## URLパスによるルーティング

同一ドメインで、URLパスによって異なるサービスにルーティングすることもできます。

### サンプル：APIとフロントエンドの分離

```yaml
# api-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api
spec:
  replicas: 2
  selector:
    matchLabels:
      app: api
  template:
    metadata:
      labels:
        app: api
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
          name: api-html
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: api-html
data:
  index.html: |
    {
      "service": "API Backend",
      "version": "1.0.0",
      "status": "healthy"
    }
---
apiVersion: v1
kind: Service
metadata:
  name: api-service
spec:
  selector:
    app: api
  ports:
  - port: 80
    targetPort: 80
```

```yaml
# web-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web
spec:
  replicas: 2
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
        volumeMounts:
        - name: html
          mountPath: /usr/share/nginx/html
      volumes:
      - name: html
        configMap:
          name: web-html
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: web-html
data:
  index.html: |
    <!DOCTYPE html>
    <html>
    <head><title>Web Frontend</title></head>
    <body style="background: #2ecc71; color: white; text-align: center; padding: 50px;">
        <h1>🌐 Web Frontend</h1>
        <p>This is the frontend application</p>
    </body>
    </html>
---
apiVersion: v1
kind: Service
metadata:
  name: web-service
spec:
  selector:
    app: web
  ports:
  - port: 80
    targetPort: 80
```

### パスベースルーティングのIngressリソース

```yaml
# ingress-path-routing.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: path-based-routing
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /$2
spec:
  ingressClassName: nginx
  rules:
  - host: myapp.example.com
    http:
      paths:
      - path: /api(/|$)(.*)
        pathType: ImplementationSpecific
        backend:
          service:
            name: api-service
            port:
              number: 80
      - path: /()(.*)
        pathType: ImplementationSpecific
        backend:
          service:
            name: web-service
            port:
              number: 80
```

```bash
# デプロイ
kubectl apply -f api-deployment.yaml
kubectl apply -f web-deployment.yaml
kubectl apply -f ingress-path-routing.yaml

# /etc/hostsに追加
echo "192.168.49.2 myapp.example.com" | sudo tee -a /etc/hosts

# 動作確認
curl http://myapp.example.com/
# Web Frontendが返される

curl http://myapp.example.com/api
# API Backendが返される
```

**パスベースルーティングのメリット：**

- フロントエンドとバックエンドを分離
- マイクロサービスアーキテクチャに適している
- 段階的なマイグレーションが可能
- 異なるチームが独立して開発可能

## TLS/HTTPS対応

本番環境では、HTTPS通信が必須です。IngressでTLS証明書を管理します。

### 自己署名証明書の作成（テスト用）

```bash
# 秘密鍵と証明書の作成
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout tls.key \
  -out tls.crt \
  -subj "/CN=myapp.example.com/O=myapp"

# Secretの作成
kubectl create secret tls myapp-tls \
  --cert=tls.crt \
  --key=tls.key

# 確認
kubectl get secrets
kubectl describe secret myapp-tls
```

### TLS対応Ingressリソース

```yaml
# ingress-tls.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: tls-ingress
  annotations:
    nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - myapp.example.com
    secretName: myapp-tls
  rules:
  - host: myapp.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: web-service
            port:
              number: 80
```

```bash
# デプロイ
kubectl apply -f ingress-tls.yaml

# HTTPSでアクセス（自己署名証明書なので警告が出る）
curl -k https://myapp.example.com
# または
curl --insecure https://myapp.example.com

# HTTPでアクセスすると自動的にHTTPSにリダイレクト
curl -v http://myapp.example.com
# Location: https://myapp.example.com が返される
```

### Let's Encryptを使った本番対応（cert-manager）

本番環境では、Let's Encryptを使って無料で有効な証明書を取得できます。

```bash
# cert-managerのインストール
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml

# ClusterIssuerの作成（Let's Encrypt）
cat <<EOF | kubectl apply -f -
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: your-email@example.com
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
    - http01:
        ingress:
          class: nginx
EOF
```

```yaml
# ingress-letsencrypt.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: letsencrypt-ingress
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
    nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - myapp.example.com
    secretName: myapp-letsencrypt-tls
  rules:
  - host: myapp.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: web-service
            port:
              number: 80
```

```bash
# デプロイ
kubectl apply -f ingress-letsencrypt.yaml

# 証明書の自動発行を確認
kubectl get certificate
kubectl describe certificate myapp-letsencrypt-tls

# 証明書発行完了まで数分待つ
kubectl get certificate -w
```

## 高度なルーティング

### リダイレクト設定

```yaml
# ingress-redirect.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: redirect-ingress
  annotations:
    nginx.ingress.kubernetes.io/permanent-redirect: "https://newdomain.example.com"
spec:
  ingressClassName: nginx
  rules:
  - host: olddomain.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: web-service
            port:
              number: 80
```

### URLリライト

```yaml
# ingress-rewrite.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: rewrite-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /new-path/$2
spec:
  ingressClassName: nginx
  rules:
  - host: myapp.example.com
    http:
      paths:
      - path: /old-path(/|$)(.*)
        pathType: ImplementationSpecific
        backend:
          service:
            name: web-service
            port:
              number: 80
```

### カナリアデプロイメント

新バージョンに段階的にトラフィックを流すカナリアデプロイが可能です。

```yaml
# ingress-canary.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: canary-ingress
  annotations:
    nginx.ingress.kubernetes.io/canary: "true"
    nginx.ingress.kubernetes.io/canary-weight: "20"
spec:
  ingressClassName: nginx
  rules:
  - host: myapp.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: web-service-v2  # 新バージョン
            port:
              number: 80
```

**カナリアデプロイの戦略：**

- `canary-weight`: トラフィックの割合（0-100）
- `canary-by-header`: 特定のヘッダーでルーティング
- `canary-by-cookie`: Cookieでルーティング

### レート制限

```yaml
# ingress-rate-limit.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: rate-limit-ingress
  annotations:
    nginx.ingress.kubernetes.io/limit-rps: "10"
    nginx.ingress.kubernetes.io/limit-connections: "5"
spec:
  ingressClassName: nginx
  rules:
  - host: myapp.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: web-service
            port:
              number: 80
```

### ヘッダーの追加

```yaml
# ingress-custom-headers.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: custom-headers-ingress
  annotations:
    nginx.ingress.kubernetes.io/configuration-snippet: |
      add_header X-Custom-Header "My Custom Value" always;
      add_header X-Frame-Options "DENY" always;
      add_header X-Content-Type-Options "nosniff" always;
spec:
  ingressClassName: nginx
  rules:
  - host: myapp.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: web-service
            port:
              number: 80
```

## まとめと次回予告

### 本記事で学んだこと

本記事では、以下の内容を学習しました：

1. **LoadBalancerとIngressの違い**
   - コスト削減とルーティングの柔軟性
   - HTTPレベルの制御

2. **Ingress Controllerのインストール**
   - Nginx Ingress Controllerの導入
   - minikubeでの簡易セットアップ

3. **ホスト名によるルーティング**
   - 複数ドメインの管理
   - 仮想ホスティング

4. **URLパスによるルーティング**
   - /api、/webなどのパス分け
   - マイクロサービスの統合

5. **TLS/HTTPS対応**
   - 自己署名証明書の作成
   - Let's Encryptとcert-manager
   - 証明書の自動更新

6. **高度なルーティング**
   - リダイレクト設定
   - URLリライト
   - カナリアデプロイメント
   - レート制限
   - カスタムヘッダー

### Ingressのベストプラクティス

**1. 証明書管理**
- cert-managerで証明書を自動更新
- 本番環境では必ずHTTPSを使用
- 定期的な証明書の有効期限確認

**2. セキュリティ**
- レート制限の設定
- セキュリティヘッダーの追加
- 適切なアクセス制御

**3. パフォーマンス**
- Ingress Controllerのリソース設定
- キャッシュの活用
- 圧縮設定

**4. 監視とログ**
- アクセスログの収集
- エラーログの監視
- メトリクスの可視化

### 次回予告：第11回 Probeでヘルスチェック

次回の第11回では、**Probe（プローブ）** を使ったヘルスチェックについて学びます：

- Liveness Probe（生存確認）
- Readiness Probe（準備確認）
- Startup Probe（起動確認）
- ヘルスチェックのベストプラクティス
- ゼロダウンタイムデプロイメント

Podの健全性を自動的に監視し、問題があるPodを自動的に再起動・隔離する仕組みを理解しましょう！

## トラブルシューティング

### Ingressが動作しない

```bash
# Ingress Controllerが起動しているか確認
kubectl get pods -n ingress-nginx

# Ingressリソースの状態確認
kubectl describe ingress <ingress-name>

# Ingress Controllerのログ確認
kubectl logs -n ingress-nginx deployment/nginx-ingress-controller

# Serviceが正しく作成されているか確認
kubectl get svc
```

### 証明書関連のエラー

```bash
# cert-managerのPodが起動しているか確認
kubectl get pods -n cert-manager

# Certificate リソースの状態確認
kubectl describe certificate <certificate-name>

# cert-managerのログ確認
kubectl logs -n cert-manager deployment/cert-manager
```

### 404エラーが返される

```bash
# パスのマッピングを確認
kubectl get ingress <ingress-name> -o yaml

# Serviceのエンドポイント確認
kubectl get endpoints <service-name>

# Podが正常に動作しているか確認
kubectl get pods
kubectl logs <pod-name>
```

Ingressは、Kubernetesで本格的なWebサービスを運用する上で必須の機能です。ホスト名やパスによる柔軟なルーティング、HTTPS対応、そして高度な制御機能を活用して、効率的なアプリケーション公開を実現しましょう！
