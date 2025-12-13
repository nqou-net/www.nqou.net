# 第10回「IngressでHTTPルーティング」技術詳細

## 主要な概念と仕組み

### Ingressとは
Ingressは、Kubernetesクラスタ外部からクラスタ内のServiceへの**HTTP/HTTPSルーティング**を定義するリソースです。単一のエントリーポイント(ロードバランサー)から複数のサービスへのトラフィックを振り分け、SSL/TLS終端、パスベース/ホストベースルーティング、URL書き換えなどを実現します。

### Ingressの構成要素

1. **Ingress Resource(リソース定義)**
   - ルーティングルールを定義するKubernetesオブジェクト
   - どのホスト名、パスをどのServiceに転送するか記述
   - TLS証明書の設定
   - アノテーションによる詳細制御

2. **Ingress Controller(実装)**
   - Ingressリソースを監視し、実際のルーティングを実行するコンポーネント
   - NGINX Ingress Controller、Traefik、HAProxy、Istio Gateway、AWS ALB Controller、GCE Ingress Controllerなど
   - クラスタに必ず1つ以上のIngressControllerをデプロイする必要がある
   - 各実装は独自のアノテーションと機能を持つ

3. **Backend Service**
   - Ingressが転送先とするKubernetes Service
   - 通常はClusterIP型Serviceを使用
   - ServiceはPodセレクタでバックエンドPodを指定

### 内部動作の詳細

Ingressの処理フロー:

```
外部クライアント
    ↓
ロードバランサー/NodePort (Ingress Controllerへの入口)
    ↓
Ingress Controller Pod (NGINX/Traefik等)
    ↓ ルーティング判定(Host/Path)
Service (ClusterIP)
    ↓
Backend Pods
```

1. **Ingress Controllerの起動**
   - Deployment/DaemonSetとしてデプロイ
   - Ingressリソースの変更をWatch
   - 設定ファイル(nginx.conf等)を動的生成・リロード

2. **トラフィック受信**
   - LoadBalancer型Service or NodePortでクラスタ外部からアクセス受付
   - クラウド環境では自動的にL4ロードバランサーがプロビジョニング

3. **ルーティング処理**
   - HTTPリクエストのHostヘッダーとパスを評価
   - マッチするIngressルールを検索
   - 対応するServiceのClusterIPに転送
   - ServiceがラウンドロビンでバックエンドPodに振り分け

4. **TLS終端**
   - Ingress ControllerでSSL/TLS終端
   - バックエンドとはHTTP通信(平文)
   - Secretリソースに証明書を格納

## 実践的なYAMLマニフェスト例

### 基本的なIngress(単一サービス)

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: simple-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx  # 使用するIngressControllerを指定
  rules:
  - host: app.example.com  # ホスト名ベースルーティング
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

### パスベースルーティング(マイクロサービス)

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: microservices-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /$2
spec:
  ingressClassName: nginx
  rules:
  - host: api.example.com
    http:
      paths:
      # /api/users/* → user-service
      - path: /api/users(/|$)(.*)
        pathType: ImplementationSpecific
        backend:
          service:
            name: user-service
            port:
              number: 8080
      # /api/orders/* → order-service
      - path: /api/orders(/|$)(.*)
        pathType: ImplementationSpecific
        backend:
          service:
            name: order-service
            port:
              number: 8080
      # /api/products/* → product-service
      - path: /api/products(/|$)(.*)
        pathType: ImplementationSpecific
        backend:
          service:
            name: product-service
            port:
              number: 8080
      # デフォルトルート
      - path: /
        pathType: Prefix
        backend:
          service:
            name: frontend-service
            port:
              number: 80
```

### TLS/HTTPS設定

```yaml
---
# TLS証明書をSecretに格納
apiVersion: v1
kind: Secret
metadata:
  name: tls-secret
  namespace: default
type: kubernetes.io/tls
data:
  tls.crt: LS0tLS1CRUdJTi... # Base64エンコードされた証明書
  tls.key: LS0tLS1CRUdJTi... # Base64エンコードされた秘密鍵
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: tls-ingress
  annotations:
    nginx.ingress.kubernetes.io/ssl-redirect: "true"  # HTTPをHTTPSにリダイレクト
    nginx.ingress.kubernetes.io/force-ssl-redirect: "true"
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - secure.example.com
    secretName: tls-secret  # 証明書Secret
  rules:
  - host: secure.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: secure-app
            port:
              number: 443
```

### ホストベースルーティング(複数ドメイン)

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: multi-host-ingress
spec:
  ingressClassName: nginx
  rules:
  # www.example.com → メインサイト
  - host: www.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: main-website
            port:
              number: 80
  # blog.example.com → ブログ
  - host: blog.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: blog-service
            port:
              number: 80
  # api.example.com → API
  - host: api.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: api-service
            port:
              number: 8080
```

### 高度なアノテーション設定(NGINX Ingress Controller)

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: advanced-ingress
  annotations:
    # レート制限
    nginx.ingress.kubernetes.io/limit-rps: "10"
    nginx.ingress.kubernetes.io/limit-connections: "5"
    
    # タイムアウト設定
    nginx.ingress.kubernetes.io/proxy-connect-timeout: "60"
    nginx.ingress.kubernetes.io/proxy-send-timeout: "60"
    nginx.ingress.kubernetes.io/proxy-read-timeout: "60"
    
    # リクエストサイズ制限
    nginx.ingress.kubernetes.io/proxy-body-size: "10m"
    
    # CORS設定
    nginx.ingress.kubernetes.io/enable-cors: "true"
    nginx.ingress.kubernetes.io/cors-allow-origin: "https://frontend.example.com"
    nginx.ingress.kubernetes.io/cors-allow-methods: "GET, POST, PUT, DELETE, OPTIONS"
    nginx.ingress.kubernetes.io/cors-allow-headers: "Authorization, Content-Type"
    
    # カスタムヘッダー追加
    nginx.ingress.kubernetes.io/configuration-snippet: |
      more_set_headers "X-Frame-Options: DENY";
      more_set_headers "X-Content-Type-Options: nosniff";
      more_set_headers "X-XSS-Protection: 1; mode=block";
    
    # Basic認証
    nginx.ingress.kubernetes.io/auth-type: basic
    nginx.ingress.kubernetes.io/auth-secret: basic-auth
    nginx.ingress.kubernetes.io/auth-realm: "Authentication Required"
    
    # スティッキーセッション
    nginx.ingress.kubernetes.io/affinity: "cookie"
    nginx.ingress.kubernetes.io/session-cookie-name: "route"
    nginx.ingress.kubernetes.io/session-cookie-expires: "172800"
    nginx.ingress.kubernetes.io/session-cookie-max-age: "172800"
    
    # URL書き換え
    nginx.ingress.kubernetes.io/rewrite-target: /$2
    nginx.ingress.kubernetes.io/use-regex: "true"
spec:
  ingressClassName: nginx
  rules:
  - host: app.example.com
    http:
      paths:
      - path: /v1(/|$)(.*)
        pathType: ImplementationSpecific
        backend:
          service:
            name: app-v1
            port:
              number: 8080
```

### Cert-Manager自動SSL証明書取得(Let's Encrypt)

```yaml
---
# ClusterIssuer(証明書発行者)
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: admin@example.com
    privateKeySecretRef:
      name: letsencrypt-prod-key
    solvers:
    - http01:
        ingress:
          class: nginx
---
# 自動証明書発行を有効化したIngress
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: auto-tls-ingress
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - auto-ssl.example.com
    secretName: auto-tls-secret  # cert-managerが自動生成
  rules:
  - host: auto-ssl.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: web-app
            port:
              number: 80
```

### カナリアデプロイメント

```yaml
---
# メイン本番環境
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: production-ingress
spec:
  ingressClassName: nginx
  rules:
  - host: app.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: app-v1  # 安定版
            port:
              number: 80
---
# カナリアリリース(トラフィック10%)
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: canary-ingress
  annotations:
    nginx.ingress.kubernetes.io/canary: "true"
    nginx.ingress.kubernetes.io/canary-weight: "10"  # 10%のトラフィック
spec:
  ingressClassName: nginx
  rules:
  - host: app.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: app-v2  # 新バージョン
            port:
              number: 80
---
# ヘッダーベースカナリア(特定ユーザーのみ新版)
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: canary-header-ingress
  annotations:
    nginx.ingress.kubernetes.io/canary: "true"
    nginx.ingress.kubernetes.io/canary-by-header: "X-Canary"
    nginx.ingress.kubernetes.io/canary-by-header-value: "beta-user"
spec:
  ingressClassName: nginx
  rules:
  - host: app.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: app-v2-beta
            port:
              number: 80
```

### デフォルトバックエンド(404カスタマイズ)

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: default-backend-ingress
spec:
  ingressClassName: nginx
  defaultBackend:  # マッチするルールがない場合
    service:
      name: custom-404-service
      port:
        number: 80
  rules:
  - host: app.example.com
    http:
      paths:
      - path: /app
        pathType: Prefix
        backend:
          service:
            name: app-service
            port:
              number: 80
```

## kubectlコマンド例

### Ingress基本操作

```bash
# Ingress作成
kubectl apply -f ingress.yaml

# Ingress一覧
kubectl get ingress
kubectl get ing  # 短縮形

# 全Namespace
kubectl get ingress --all-namespaces

# 詳細表示
kubectl describe ingress simple-ingress

# YAML出力
kubectl get ingress simple-ingress -o yaml

# エンドポイント確認
kubectl get ingress simple-ingress -o jsonpath='{.status.loadBalancer.ingress[0].ip}'

# Ingress削除
kubectl delete ingress simple-ingress
```

### Ingress Controller操作

```bash
# NGINX Ingress Controllerインストール(Helm)
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm install nginx-ingress ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace

# インストール確認
kubectl get pods -n ingress-nginx
kubectl get svc -n ingress-nginx

# Ingress Controllerログ確認
kubectl logs -n ingress-nginx deployment/nginx-ingress-controller -f

# 設定リロード
kubectl exec -n ingress-nginx deployment/nginx-ingress-controller -- /nginx-ingress-controller --reload

# NGINX設定確認
kubectl exec -n ingress-nginx deployment/nginx-ingress-controller -- cat /etc/nginx/nginx.conf
```

### デバッグとトラブルシューティング

```bash
# Ingressイベント確認
kubectl describe ingress my-ingress

# バックエンドService確認
kubectl get svc web-service
kubectl get endpoints web-service

# Pod稼働確認
kubectl get pods -l app=web

# Ingress Controllerログ
kubectl logs -n ingress-nginx -l app.kubernetes.io/name=ingress-nginx --tail=100

# リクエストトレース(詳細ログ有効化)
kubectl annotate ingress my-ingress nginx.ingress.kubernetes.io/enable-access-log="true"

# アクセスログ確認
kubectl logs -n ingress-nginx deployment/nginx-ingress-controller | grep "GET /path"

# 外部からのアクセステスト
curl -H "Host: app.example.com" http://<EXTERNAL-IP>/

# ローカルからのテスト(/etc/hosts編集)
echo "<EXTERNAL-IP> app.example.com" | sudo tee -a /etc/hosts
curl http://app.example.com/

# TLS証明書確認
kubectl get secret tls-secret -o jsonpath='{.data.tls\.crt}' | base64 -d | openssl x509 -text -noout

# 証明書有効期限確認
kubectl get secret tls-secret -o jsonpath='{.data.tls\.crt}' | base64 -d | openssl x509 -noout -dates
```

### パフォーマンステスト

```bash
# 負荷テスト(Apache Bench)
ab -n 1000 -c 10 http://app.example.com/

# より詳細な負荷テスト(hey)
hey -n 10000 -c 100 -q 10 http://app.example.com/api

# レート制限テスト
for i in {1..20}; do
  curl -w "\nStatus: %{http_code}\n" http://app.example.com/
  sleep 0.1
done

# コネクション数確認
kubectl exec -n ingress-nginx deployment/nginx-ingress-controller -- \
  sh -c "echo 'GET /nginx_status HTTP/1.0\r\n\r\n' | nc localhost 18080"
```

### メトリクス確認

```bash
# Prometheus形式のメトリクス
kubectl exec -n ingress-nginx deployment/nginx-ingress-controller -- \
  curl -s http://localhost:10254/metrics

# リクエスト数確認
kubectl exec -n ingress-nginx deployment/nginx-ingress-controller -- \
  curl -s http://localhost:10254/metrics | grep nginx_ingress_controller_requests

# レスポンスタイム確認
kubectl exec -n ingress-nginx deployment/nginx-ingress-controller -- \
  curl -s http://localhost:10254/metrics | grep nginx_ingress_controller_request_duration_seconds
```

### 証明書管理(Cert-Manager)

```bash
# Cert-Managerインストール
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml

# 証明書確認
kubectl get certificate
kubectl describe certificate auto-tls-secret

# 証明書リクエスト確認
kubectl get certificaterequest
kubectl describe certificaterequest auto-tls-secret-xxxxx

# 証明書更新(手動)
kubectl delete certificate auto-tls-secret
# Ingressが自動的に再作成

# Let's Encrypt チャレンジ確認
kubectl get challenges
kubectl describe challenge auto-tls-secret-xxxxx
```

### IngressClass管理

```bash
# IngressClass一覧
kubectl get ingressclass

# デフォルトIngressClass設定
kubectl annotate ingressclass nginx \
  ingressclass.kubernetes.io/is-default-class="true"

# IngressClass詳細
kubectl describe ingressclass nginx

# 複数のIngressControllerを使い分け
kubectl get ingressclass
# NAME      CONTROLLER                  PARAMETERS
# nginx     k8s.io/ingress-nginx        <none>
# traefik   traefik.io/ingress-traefik  <none>

# 特定のIngressClassを指定
spec:
  ingressClassName: traefik
```

## 初心者がつまづきやすいポイント

### 1. Ingress Controllerのインストール忘れ

**問題**: Ingressリソースを作成してもアクセスできない

**原因**: 
- Ingressリソースはあくまでもルーティングルールの定義
- 実際の処理を行うIngress Controllerのインストールが必須

**解決策**:
```bash
# Ingress Controller存在確認
kubectl get pods -n ingress-nginx
kubectl get svc -n ingress-nginx

# インストールされていない場合
helm install nginx-ingress ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace

# LoadBalancerのExternal IP確認
kubectl get svc -n ingress-nginx
# 待機中の場合(クラウドでない環境)
kubectl patch svc nginx-ingress-controller -n ingress-nginx \
  -p '{"spec":{"type":"NodePort"}}'
```

### 2. ホスト名解決の問題

**問題**: IPアドレスで直接アクセスできない、404エラーが返る

**原因**: 
- IngressはHostヘッダーベースでルーティング
- IPアドレス直接アクセスはホスト名と一致しない

**解決策**:
```bash
# ローカルテスト用にhostsファイル編集
echo "192.168.1.100 app.example.com" | sudo tee -a /etc/hosts

# またはcurlでHostヘッダー指定
curl -H "Host: app.example.com" http://192.168.1.100/

# ホスト名なしでアクセスしたい場合
spec:
  rules:
  - http:  # hostフィールドを省略(全てのホストにマッチ)
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: default-service
            port:
              number: 80
```

### 3. pathTypeの誤解

**問題**: パスルーティングが期待通り動作しない

**原因**: 
- `Exact`: 完全一致のみ(`/app` は `/app/` とマッチしない)
- `Prefix`: プレフィックス一致(`/app` は `/app/test` にマッチ)
- `ImplementationSpecific`: Ingress Controller依存

**正しい使い方**:
```yaml
paths:
# 完全一致(/api のみ)
- path: /api
  pathType: Exact
  
# プレフィックス一致(/app, /app/, /app/users 全てマッチ)
- path: /app
  pathType: Prefix
  
# 正規表現(NGINX Ingress)
- path: /api/v[0-9]+/(.*)
  pathType: ImplementationSpecific
```

```bash
# テスト
curl http://app.example.com/app      # Prefixでマッチ
curl http://app.example.com/app/     # Prefixでマッチ
curl http://app.example.com/app/test # Prefixでマッチ
curl http://app.example.com/api      # Exactでマッチ
curl http://app.example.com/api/     # Exactでマッチしない！
```

### 4. rewrite-targetの混乱

**問題**: バックエンドに予期しないパスが送信される

**原因**: 
- Ingressのパスとバックエンドのパスが異なる場合、書き換えが必要
- `rewrite-target`アノテーションの理解不足

**例**:
```yaml
# 問題のある設定
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: problem-ingress
spec:
  rules:
  - host: app.example.com
    http:
      paths:
      - path: /api
        pathType: Prefix
        backend:
          service:
            name: api-service
            port:
              number: 8080

# リクエスト: GET /api/users
# バックエンドに送信: GET /api/users ← /apiが残る！
```

**正しい設定**:
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: rewrite-ingress
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /$2
spec:
  rules:
  - host: app.example.com
    http:
      paths:
      - path: /api(/|$)(.*)
        pathType: ImplementationSpecific
        backend:
          service:
            name: api-service
            port:
              number: 8080

# リクエスト: GET /api/users
# バックエンドに送信: GET /users ← /apiが削除される
```

### 5. TLS証明書の問題

**問題**: HTTPSアクセスで証明書エラーが出る

**原因**: 
- Secretの形式が間違っている(`kubernetes.io/tls`型でない)
- 証明書と秘密鍵がBase64エンコードされていない
- 中間証明書が含まれていない

**正しい証明書Secret作成**:
```bash
# 証明書ファイルから作成
kubectl create secret tls tls-secret \
  --cert=cert.pem \
  --key=key.pem

# または手動でYAML作成
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: tls-secret
type: kubernetes.io/tls
data:
  tls.crt: $(cat cert.pem | base64 -w0)
  tls.key: $(cat key.pem | base64 -w0)
EOF

# 中間証明書を含める場合
cat cert.pem intermediate.pem > fullchain.pem
kubectl create secret tls tls-secret \
  --cert=fullchain.pem \
  --key=key.pem

# 証明書確認
kubectl get secret tls-secret -o yaml
openssl x509 -in <(kubectl get secret tls-secret -o jsonpath='{.data.tls\.crt}' | base64 -d) -text -noout
```

### 6. バックエンドServiceが見つからない

**問題**: `503 Service Temporarily Unavailable`エラー

**原因**: 
- Serviceが存在しない、または異なるNamespaceにある
- Serviceのセレクタが間違っていてPodが見つからない
- Podが起動していない

**診断手順**:
```bash
# Service確認
kubectl get svc web-service
kubectl describe svc web-service

# Endpoints確認(最重要)
kubectl get endpoints web-service
# → ENDPOINTS列が空なら問題あり

# Pod確認
kubectl get pods -l app=web
kubectl describe pod web-xxx

# Ingress Controllerログで詳細確認
kubectl logs -n ingress-nginx deployment/nginx-ingress-controller | grep "upstream"

# Ingressリソース確認
kubectl describe ingress my-ingress
# Backend欄に "default backend - 404" があればServiceが見つからない
```

### 7. 複数Ingressルールの競合

**問題**: 期待したルールが適用されない

**原因**: 
- 複数のIngressリソースで同じホスト/パスを定義
- ルールの優先順位を理解していない

**ルール評価順序**:
```yaml
# 1. 完全一致のホスト + パス
# 2. ワイルドカードホスト + 完全パス
# 3. 完全ホスト + プレフィックスパス
# 4. デフォルトバックエンド

# 競合例
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ingress-1
spec:
  rules:
  - host: app.example.com
    http:
      paths:
      - path: /api
        pathType: Prefix  # これが適用される
        backend:
          service:
            name: api-v1
            port:
              number: 80
---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: ingress-2
spec:
  rules:
  - host: app.example.com
    http:
      paths:
      - path: /api
        pathType: Exact  # 同じホスト/パスで競合！
        backend:
          service:
            name: api-v2
            port:
              number: 80
```

**解決策**:
```bash
# 全Ingressリソース確認
kubectl get ingress

# 統合する
kubectl delete ingress ingress-2
# ingress-1にルールを追加
```

### 8. レート制限やCORS設定が効かない

**問題**: アノテーションを追加しても動作しない

**原因**: 
- Ingress Controllerごとにアノテーションの名前空間が異なる
- NGINX用のアノテーションをTraefikで使用している

**Ingress Controller別アノテーション**:
```yaml
# NGINX Ingress
metadata:
  annotations:
    nginx.ingress.kubernetes.io/limit-rps: "10"
    nginx.ingress.kubernetes.io/enable-cors: "true"

# Traefik
metadata:
  annotations:
    traefik.ingress.kubernetes.io/rate-limit: |
      extractorfunc: client.ip
      rateset:
        rate1:
          period: 1s
          average: 10
          burst: 20

# AWS ALB Ingress
metadata:
  annotations:
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
```

```bash
# 使用しているIngress Controller確認
kubectl get ingressclass
kubectl describe ingressclass nginx

# 各Controllerのドキュメント確認が必須
# NGINX: https://kubernetes.github.io/ingress-nginx/user-guide/nginx-configuration/annotations/
# Traefik: https://doc.traefik.io/traefik/routing/providers/kubernetes-ingress/
```

これらのポイントを理解することで、Ingressを活用した堅牢なHTTPルーティングとロードバランシングが実現できます！
