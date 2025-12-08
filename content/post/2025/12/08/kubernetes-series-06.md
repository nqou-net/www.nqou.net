---
title: "Kubernetesを完全に理解した（第6回）- ConfigMapとSecretで設定を分離"
draft: true
tags:
- kubernetes
- configmap
- secret
- configuration
- security
description: "アプリケーションの設定を適切に管理する方法を学習。パスワードやAPIキーなどの機密情報を安全に扱う手法を習得します。"
---

## 導入 - 第5回の振り返りと第6回で学ぶこと

前回の記事では、**Service**を使って動的に変化するPod群への安定したアクセスを実現する方法を学びました。

**第5回のおさらい:**

- Podの短命性とPod IPに直接アクセスしてはいけない理由
- Serviceの3つのタイプ（ClusterIP、NodePort、LoadBalancer）
- ClusterIPによる内部通信と負荷分散
- NodePortによる外部アクセスの実現
- サービスディスカバリとDNS名前解決

これで、安定したネットワークアクセスと負荷分散が実現できるようになりました。しかし、実際のアプリケーション運用では、さらに重要な課題が残っています。

**アプリケーションの設定はどう管理すべきか？**

例えば、以下のようなケースを考えてみましょう：

```yaml
# 悪い例: 設定をコンテナイメージに埋め込んでいる
apiVersion: v1
kind: Pod
metadata:
  name: web-app
spec:
  containers:
  - name: app
    image: myapp:1.0
    env:
    - name: DATABASE_URL
      value: "postgres://db.example.com:5432/mydb"  # ハードコーディング！
    - name: API_KEY
      value: "sk-1234567890abcdef"  # APIキーが平文で！
    - name: MAX_CONNECTIONS
      value: "100"
```

このアプローチには重大な問題があります：

1. **環境ごとに異なるイメージが必要** - dev/staging/prodで別々のイメージをビルド
2. **機密情報がバージョン管理される危険性** - GitにAPIキーやパスワードがコミットされる
3. **設定変更のたびにイメージ再ビルド** - デプロイが遅く、ロールバックが困難

第6回となる本記事では、この問題を解決する**ConfigMapとSecret**について学習します。

**この記事で学ぶこと:**

- The Twelve-Factor Appにおける設定とコードの分離原則
- ConfigMapによる設定の外部化とYAMLマニフェスト
- Secretによる機密情報の管理とBase64エンコード
- 環境変数としての設定注入（envとenvFrom）
- Volumeを使った設定ファイルのマウント
- ConfigMapの動的更新とPod再起動の注意点
- セキュリティのベストプラクティス

それでは、アプリケーション設定の適切な管理方法を体験していきましょう！

## 設定とコードの分離 - Twelve-Factor Appの原則

### なぜ設定を分離するのか

**The Twelve-Factor App**は、モダンなクラウドネイティブアプリケーションの設計原則です。その中でも特に重要なのが**第3原則：設定（Config）**です。

**第3原則が示すこと:**

> 設定は環境ごとに変わるものであり、コードから厳密に分離すべきである。設定は環境変数に格納する。

この原則に従うことで、以下のメリットが得られます：

```bash
# 同じコンテナイメージで全環境をカバー
docker pull myapp:v1.2.3

# 開発環境
kubectl run myapp --image=myapp:v1.2.3 --env="ENV=dev"

# ステージング環境
kubectl run myapp --image=myapp:v1.2.3 --env="ENV=staging"

# 本番環境
kubectl run myapp --image=myapp:v1.2.3 --env="ENV=production"

# → 同じイメージ、異なる設定
```

### 設定とは何か？ 設定でないものは何か？

**設定に該当するもの（環境ごとに変化する）:**

- データベース接続文字列（dev/staging/prodで異なる）
- 外部サービスのエンドポイントURL
- APIキー、パスワード、トークン
- ポート番号、タイムアウト値
- ログレベル、デバッグフラグ
- 機能フラグ（Feature Flags）

**設定に該当しないもの（コードに含めるべき）:**

- アプリケーションのビジネスロジック
- ルーティング設定
- 内部的な定数（π = 3.14159...）
- アルゴリズムのパラメータ

### Kubernetesにおける設定管理の選択肢

Kubernetesでは、設定を外部化する2つの主要なリソースを提供しています：

| リソース | 用途 | 暗号化 | 適用例 |
|---------|------|--------|--------|
| **ConfigMap** | 非機密情報の設定 | なし | アプリケーション設定、接続文字列、ポート番号 |
| **Secret** | 機密情報 | Base64エンコード（注意：暗号化ではない） | パスワード、APIキー、TLS証明書 |

それでは、実際にConfigMapとSecretを使ってみましょう。

## ConfigMapで設定を外部化 - YAMLマニフェストと使い方

### ConfigMapとは

**ConfigMap**は、キーと値のペアとして設定データを保存するKubernetesリソースです。Podから切り離されているため、同じConfigMapを複数のPodで共有できます。

### ConfigMapの作成方法

ConfigMapを作成する方法は主に3つあります：

#### 方法1: リテラル値から作成（コマンドライン）

```bash
# 単純なキー・バリューペアから作成
kubectl create configmap app-config \
  --from-literal=app.env=production \
  --from-literal=log.level=info \
  --from-literal=max.connections=100

# 作成されたConfigMapを確認
kubectl get configmap app-config -o yaml
```

出力例：

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
data:
  app.env: production
  log.level: info
  max.connections: "100"  # 注意: 数値も文字列として保存される
```

#### 方法2: ファイルから作成

まず、設定ファイルを用意します：

```bash
# app.properties ファイルを作成
cat > app.properties <<EOF
app.env=production
log.level=info
max.connections=100
EOF

# ファイルからConfigMapを作成
kubectl create configmap app-config-from-file \
  --from-file=app.properties

# 作成確認
kubectl get configmap app-config-from-file -o yaml
```

出力例：

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config-from-file
data:
  app.properties: |
    app.env=production
    log.level=info
    max.connections=100
```

#### 方法3: YAMLマニフェストから作成（推奨）

最も管理しやすい方法は、YAMLマニフェストを書くことです：

```yaml
# configmap-app.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config
  namespace: default
data:
  # シンプルなキー・バリューペア
  app.env: "production"
  log.level: "info"
  max.connections: "100"
  
  # 複数行の設定ファイル
  nginx.conf: |
    server {
      listen 80;
      server_name example.com;
      
      location / {
        proxy_pass http://backend:8080;
        proxy_set_header Host $host;
      }
    }
  
  # JSON形式の設定
  database.json: |
    {
      "host": "db.example.com",
      "port": 5432,
      "database": "myapp",
      "pool": {
        "min": 2,
        "max": 10
      }
    }
```

```bash
# マニフェストから作成
kubectl apply -f configmap-app.yaml

# 詳細確認
kubectl describe configmap app-config
```

### ConfigMapのベストプラクティス

**1. 名前付け規則を統一する**

```yaml
# 良い例: 目的が明確
metadata:
  name: myapp-config
  name: myapp-nginx-config
  name: myapp-db-config

# 悪い例: 何の設定か不明
metadata:
  name: config1
  name: settings
  name: data
```

**2. namespaceを明示する**

```yaml
metadata:
  name: app-config
  namespace: production  # 明示的に指定
```

**3. サイズ制限に注意（1MB以下）**

ConfigMapは1MB未満に制限されています。大きな設定ファイルはPersistentVolumeを使用してください。

## Secretで機密情報を管理 - Base64エンコードと注意点

### Secretとは

**Secret**は、パスワード、トークン、SSHキー、TLS証明書などの機密情報を保存するためのKubernetesリソースです。ConfigMapと似ていますが、機密情報の扱いに特化しています。

### Secretの作成方法

#### 方法1: リテラル値から作成

```bash
# 機密情報をコマンドラインで指定
kubectl create secret generic db-credentials \
  --from-literal=username=admin \
  --from-literal=password=P@ssw0rd123

# 確認（値はBase64エンコードされている）
kubectl get secret db-credentials -o yaml
```

出力例：

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: db-credentials
type: Opaque
data:
  username: YWRtaW4=        # "admin" のBase64
  password: UEBzc3cwcmQxMjM=  # "P@ssw0rd123" のBase64
```

**Base64エンコードを確認:**

```bash
# エンコード
echo -n "admin" | base64
# 出力: YWRtaW4=

# デコード
echo "YWRtaW4=" | base64 -d
# 出力: admin
```

#### 方法2: ファイルから作成

```bash
# SSHキーをSecretとして保存
kubectl create secret generic ssh-key \
  --from-file=ssh-privatekey=/path/to/.ssh/id_rsa \
  --from-file=ssh-publickey=/path/to/.ssh/id_rsa.pub

# TLS証明書を保存（特殊なタイプ）
kubectl create secret tls my-tls-secret \
  --cert=/path/to/tls.crt \
  --key=/path/to/tls.key
```

#### 方法3: YAMLマニフェストから作成

```yaml
# secret-db.yaml
apiVersion: v1
kind: Secret
metadata:
  name: db-credentials
  namespace: default
type: Opaque
data:
  # Base64エンコードされた値
  username: YWRtaW4=
  password: UEBzc3cwcmQxMjM=
```

**重要: YAMLに書く前に手動でBase64エンコード**

```bash
# エンコード方法
echo -n "admin" | base64
echo -n "P@ssw0rd123" | base64

# マニフェスト適用
kubectl apply -f secret-db.yaml
```

### stringDataを使った平文指定（開発時のみ）

開発環境では、`stringData`フィールドを使うと平文で指定できます：

```yaml
# secret-dev.yaml （開発環境のみ！）
apiVersion: v1
kind: Secret
metadata:
  name: db-credentials-dev
type: Opaque
stringData:  # Base64エンコード不要
  username: "admin"
  password: "P@ssw0rd123"
```

```bash
kubectl apply -f secret-dev.yaml

# 確認すると自動的にBase64エンコードされている
kubectl get secret db-credentials-dev -o yaml
# data:
#   username: YWRtaW4=
#   password: UEBzc3cwcmQxMjM=
```

### Secretの重要な注意点

**1. Base64は暗号化ではない**

```bash
# 簡単にデコードできる
kubectl get secret db-credentials -o jsonpath='{.data.password}' | base64 -d
# 出力: P@ssw0rd123

# → Base64は単なるエンコード、暗号化ではない！
```

**2. etcdでの保存**

Secretはデフォルトでは**etcd（Kubernetesのデータストア）に平文で保存**されます。

**セキュリティを強化する方法:**

```bash
# etcdの暗号化を有効化（クラスタ管理者が設定）
# /etc/kubernetes/manifests/kube-apiserver.yaml に追加:
# --encryption-provider-config=/path/to/encryption-config.yaml
```

**3. Gitにコミットしない**

```bash
# .gitignore に追加
echo "secret-*.yaml" >> .gitignore
echo "*-secret.yaml" >> .gitignore

# 代わりに、sealed-secretsやExternal Secretsを使用
```

### Secretのタイプ

Kubernetesは複数のSecretタイプをサポートしています：

| タイプ | 用途 | 例 |
|--------|------|-----|
| `Opaque` | 汎用的な機密情報（デフォルト） | パスワード、APIキー |
| `kubernetes.io/tls` | TLS証明書とキー | Ingress用のTLS |
| `kubernetes.io/dockerconfigjson` | Dockerレジストリ認証情報 | プライベートイメージのpull |
| `kubernetes.io/basic-auth` | Basic認証 | ユーザー名とパスワード |
| `kubernetes.io/ssh-auth` | SSH認証 | GitリポジトリへのSSHアクセス |

```yaml
# TLSタイプの例
apiVersion: v1
kind: Secret
metadata:
  name: tls-secret
type: kubernetes.io/tls
data:
  tls.crt: LS0tLS1CRUdJTi...  # Base64エンコードされた証明書
  tls.key: LS0tLS1CRUdJTi...  # Base64エンコードされた秘密鍵
```

## 環境変数として注入 - envとenvFromの使い分け

ConfigMapとSecretを作成したら、それらをPodで使用します。最も一般的な方法は**環境変数として注入**することです。

### 方法1: 個別のキーを環境変数に（env）

特定のキーだけを環境変数として設定したい場合：

```yaml
# pod-with-env.yaml
apiVersion: v1
kind: Pod
metadata:
  name: myapp-pod
spec:
  containers:
  - name: myapp
    image: myapp:1.0
    env:
    # ConfigMapから値を取得
    - name: APP_ENV
      valueFrom:
        configMapKeyRef:
          name: app-config
          key: app.env
    
    - name: LOG_LEVEL
      valueFrom:
        configMapKeyRef:
          name: app-config
          key: log.level
    
    # Secretから値を取得
    - name: DB_USERNAME
      valueFrom:
        secretKeyRef:
          name: db-credentials
          key: username
    
    - name: DB_PASSWORD
      valueFrom:
        secretKeyRef:
          name: db-credentials
          key: password
```

```bash
# Podをデプロイ
kubectl apply -f pod-with-env.yaml

# 環境変数を確認
kubectl exec myapp-pod -- env | grep -E 'APP_ENV|LOG_LEVEL|DB_'
# 出力:
# APP_ENV=production
# LOG_LEVEL=info
# DB_USERNAME=admin
# DB_PASSWORD=P@ssw0rd123
```

### 方法2: ConfigMap/Secret全体を環境変数に（envFrom）

ConfigMap/Secretの全てのキーを一度に環境変数として設定したい場合：

```yaml
# pod-with-envfrom.yaml
apiVersion: v1
kind: Pod
metadata:
  name: myapp-pod-envfrom
spec:
  containers:
  - name: myapp
    image: myapp:1.0
    envFrom:
    # ConfigMapの全キーを環境変数に
    - configMapRef:
        name: app-config
    # Secretの全キーを環境変数に
    - secretRef:
        name: db-credentials
```

```bash
kubectl apply -f pod-with-envfrom.yaml

# 全ての環境変数を確認
kubectl exec myapp-pod-envfrom -- env
# 出力:
# app.env=production
# log.level=info
# max.connections=100
# username=admin
# password=P@ssw0rd123
```

### envとenvFromの使い分け

**envを使うべき場合:**

- 特定のキーだけが必要
- 環境変数名をカスタマイズしたい（`DB_PASSWORD`など）
- 複数のConfigMap/Secretから選択的に取得

**envFromを使うべき場合:**

- ConfigMap/Secretの全てのキーが必要
- キー名をそのまま環境変数名として使用できる
- シンプルで記述量を減らしたい

### プレフィックスの追加

`envFrom`では、環境変数名にプレフィックスを付けることができます：

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: myapp-pod-prefix
spec:
  containers:
  - name: myapp
    image: myapp:1.0
    envFrom:
    - configMapRef:
        name: app-config
      prefix: CONFIG_  # プレフィックスを追加
    - secretRef:
        name: db-credentials
      prefix: DB_
```

```bash
kubectl apply -f pod-with-envfrom.yaml
kubectl exec myapp-pod-prefix -- env | grep -E 'CONFIG_|DB_'
# 出力:
# CONFIG_app.env=production
# CONFIG_log.level=info
# CONFIG_max.connections=100
# DB_username=admin
# DB_password=P@ssw0rd123
```

### 環境変数の優先順位

複数の方法で同じ環境変数を定義した場合：

```yaml
env:
- name: LOG_LEVEL
  value: "debug"  # 1. 直接指定（最優先）
- name: LOG_LEVEL
  valueFrom:
    configMapKeyRef:
      name: app-config
      key: log.level  # 2. ConfigMapから（無視される）
```

**優先順位: 直接指定 > configMapKeyRef > secretKeyRef > envFrom**

## ファイルとしてマウント - Volumeを使った設定ファイル配置

環境変数として注入する以外に、**Volumeとして設定ファイルをマウント**する方法があります。設定ファイル（nginx.conf、application.ymlなど）をそのまま使いたい場合に便利です。

### ConfigMapをVolumeとしてマウント

```yaml
# configmap-nginx.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: nginx-config
data:
  nginx.conf: |
    events {
      worker_connections 1024;
    }
    
    http {
      server {
        listen 80;
        server_name localhost;
        
        location / {
          root /usr/share/nginx/html;
          index index.html;
        }
        
        location /api {
          proxy_pass http://backend:8080;
        }
      }
    }
```

```yaml
# pod-nginx-volume.yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx-with-config
spec:
  containers:
  - name: nginx
    image: nginx:1.26-alpine
    volumeMounts:
    - name: nginx-config-volume
      mountPath: /etc/nginx/nginx.conf  # ファイルとしてマウント
      subPath: nginx.conf  # ConfigMapの特定キーをマウント
  
  volumes:
  - name: nginx-config-volume
    configMap:
      name: nginx-config
```

```bash
# 作成
kubectl apply -f configmap-nginx.yaml
kubectl apply -f pod-nginx-volume.yaml

# マウントされたファイルを確認
kubectl exec nginx-with-config -- cat /etc/nginx/nginx.conf
# ConfigMapの内容が表示される
```

### ディレクトリ全体をマウント

`subPath`を使わない場合、ConfigMapの全キーがディレクトリ内にファイルとして配置されます：

```yaml
# configmap-multifile.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-multifile-config
data:
  application.yml: |
    server:
      port: 8080
    spring:
      datasource:
        url: jdbc:postgresql://db:5432/mydb
  
  logback.xml: |
    <configuration>
      <appender name="STDOUT" class="ch.qos.logback.core.ConsoleAppender">
        <encoder>
          <pattern>%d{HH:mm:ss.SSS} [%thread] %-5level %logger{36} - %msg%n</pattern>
        </encoder>
      </appender>
      <root level="info">
        <appender-ref ref="STDOUT" />
      </root>
    </configuration>
```

```yaml
# pod-multifile.yaml
apiVersion: v1
kind: Pod
metadata:
  name: app-with-multifile-config
spec:
  containers:
  - name: myapp
    image: myapp:1.0
    volumeMounts:
    - name: config-volume
      mountPath: /app/config  # ディレクトリとしてマウント
  
  volumes:
  - name: config-volume
    configMap:
      name: app-multifile-config
```

```bash
kubectl apply -f configmap-multifile.yaml
kubectl apply -f pod-multifile.yaml

# マウントされたファイルを確認
kubectl exec app-with-multifile-config -- ls -la /app/config
# 出力:
# total 8
# drwxrwxrwx 3 root root 4096 Dec  8 00:00 .
# drwxr-xr-x 1 root root 4096 Dec  8 00:00 ..
# lrwxrwxrwx 1 root root   24 Dec  8 00:00 application.yml -> ..data/application.yml
# lrwxrwxrwx 1 root root   21 Dec  8 00:00 logback.xml -> ..data/logback.xml

kubectl exec app-with-multifile-config -- cat /app/config/application.yml
# ConfigMapの内容が表示される
```

### Secretをファイルとしてマウント

Secretも同様にVolumeとしてマウントできます。機密ファイル（TLS証明書、SSHキーなど）を配置する場合に便利です：

```yaml
# pod-secret-volume.yaml
apiVersion: v1
kind: Pod
metadata:
  name: app-with-secret-files
spec:
  containers:
  - name: myapp
    image: myapp:1.0
    volumeMounts:
    - name: tls-certs
      mountPath: /etc/tls
      readOnly: true  # 読み取り専用でマウント（推奨）
  
  volumes:
  - name: tls-certs
    secret:
      secretName: my-tls-secret
      defaultMode: 0400  # ファイルパーミッションを設定
```

```bash
kubectl apply -f pod-secret-volume.yaml

# マウントされたファイルを確認
kubectl exec app-with-secret-files -- ls -la /etc/tls
# 出力:
# total 8
# drwxrwxrwt 3 root root  120 Dec  8 00:00 .
# drwxr-xr-x 1 root root 4096 Dec  8 00:00 ..
# -r-------- 1 root root 1234 Dec  8 00:00 tls.crt
# -r-------- 1 root root 1675 Dec  8 00:00 tls.key
```

### 環境変数 vs Volumeマウント - どちらを選ぶか

| 方法 | 適用ケース | メリット | デメリット |
|------|-----------|---------|----------|
| **環境変数** | シンプルなキー・バリュー設定 | アプリから簡単にアクセス可能 | 複雑な構造には不向き、サイズ制限 |
| **Volumeマウント** | 設定ファイル（nginx.conf、application.yml） | ファイル形式をそのまま使用可能、動的更新が可能 | アプリがファイルパスを知る必要がある |

**実践的な使い分け:**

```yaml
# 推奨パターン: 両方を組み合わせる
spec:
  containers:
  - name: myapp
    image: myapp:1.0
    env:
    # シンプルな設定は環境変数で
    - name: APP_ENV
      valueFrom:
        configMapKeyRef:
          name: app-config
          key: app.env
    - name: DB_PASSWORD
      valueFrom:
        secretKeyRef:
          name: db-credentials
          key: password
    
    volumeMounts:
    # 複雑な設定ファイルはVolumeで
    - name: app-config-files
      mountPath: /app/config
  
  volumes:
  - name: app-config-files
    configMap:
      name: app-multifile-config
```

## 動的更新と注意点 - ConfigMapの更新とPodの再起動

### ConfigMapを更新するとどうなるか？

ConfigMapを更新した場合の挙動は、**環境変数**と**Volumeマウント**で大きく異なります。

#### 環境変数の場合（更新されない）

```bash
# 初期ConfigMapを作成
kubectl create configmap app-config --from-literal=version=1.0

# Podを作成
kubectl run myapp --image=busybox:1.36 --restart=Never \
  --env="APP_VERSION" \
  --overrides='
{
  "spec": {
    "containers": [{
      "name": "myapp",
      "image": "busybox:1.36",
      "command": ["sh", "-c", "while true; do echo APP_VERSION=$APP_VERSION; sleep 10; done"],
      "env": [{
        "name": "APP_VERSION",
        "valueFrom": {
          "configMapKeyRef": {
            "name": "app-config",
            "key": "version"
          }
        }
      }]
    }]
  }
}'

# ログを確認
kubectl logs myapp -f
# 出力: APP_VERSION=1.0

# ConfigMapを更新
kubectl create configmap app-config --from-literal=version=2.0 --dry-run=client -o yaml | kubectl apply -f -

# ログを再確認
kubectl logs myapp -f
# 出力: APP_VERSION=1.0  ← 変わらない！

# Podを再起動すると更新される
kubectl delete pod myapp
# → 新しいPodを作成すると APP_VERSION=2.0 になる
```

**環境変数は起動時に一度だけ設定されるため、ConfigMap更新後もPodを再起動しない限り更新されません。**

#### Volumeマウントの場合（自動更新される）

```bash
# ConfigMapを作成
kubectl create configmap nginx-config \
  --from-file=index.html=<(echo "<h1>Version 1.0</h1>")

# Podを作成
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: nginx-volume
spec:
  containers:
  - name: nginx
    image: nginx:1.26-alpine
    volumeMounts:
    - name: config
      mountPath: /usr/share/nginx/html
  volumes:
  - name: config
    configMap:
      name: nginx-config
EOF

# 初期コンテンツを確認
kubectl exec nginx-volume -- cat /usr/share/nginx/html/index.html
# 出力: <h1>Version 1.0</h1>

# ConfigMapを更新
kubectl create configmap nginx-config \
  --from-file=index.html=<(echo "<h1>Version 2.0</h1>") \
  --dry-run=client -o yaml | kubectl apply -f -

# 少し待つ（kubeletが同期するまで最大60秒）
sleep 70

# 更新されたコンテンツを確認
kubectl exec nginx-volume -- cat /usr/share/nginx/html/index.html
# 出力: <h1>Version 2.0</h1>  ← 自動的に更新された！
```

**Volumeマウントは自動的に更新されますが、最大60秒の遅延があります。**

### 動的更新の仕組み

Kubernetesの**kubelet**が定期的（デフォルト60秒）にConfigMapの変更を検知し、Volumeマウントされたファイルを更新します。

しかし、重要な注意点があります：

**1. アプリケーションが設定ファイルを再読み込みしない限り、変更は反映されない**

```bash
# nginx の例
kubectl exec nginx-volume -- cat /usr/share/nginx/html/index.html
# ファイルは更新されている

# しかし、nginxは自動的に再読み込みしない
# 手動でリロードが必要
kubectl exec nginx-volume -- nginx -s reload
```

**2. `subPath`を使うと動的更新されない**

```yaml
volumeMounts:
- name: config
  mountPath: /etc/nginx/nginx.conf
  subPath: nginx.conf  # subPathを使うと動的更新されない！
```

`subPath`はシンボリックリンクではなく、ファイルの直接マウントになるため、更新が反映されません。

### 実践的な更新戦略

**戦略1: Deploymentのローリングアップデート（推奨）**

ConfigMapを更新したら、Podを順次再起動してゼロダウンタイムで設定を反映：

```bash
# ConfigMapを更新
kubectl apply -f configmap-app.yaml

# Deploymentを再起動（ローリングアップデート）
kubectl rollout restart deployment/myapp

# 進行状況を確認
kubectl rollout status deployment/myapp
```

**戦略2: ConfigMapのバージョニング**

ConfigMap名にバージョン番号を含め、毎回新しいConfigMapを作成：

```yaml
# v1
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config-v1
data:
  version: "1.0"
---
# v2
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-config-v2
data:
  version: "2.0"
```

```yaml
# Deployment
spec:
  template:
    spec:
      volumes:
      - name: config
        configMap:
          name: app-config-v2  # バージョンを変更するだけ
```

この方法なら、Deploymentの更新だけで自動的にPodが再作成されます。

**戦略3: Reloaderなどのツールを使用**

外部ツール（Reloader、Stakater Reloader）を使うと、ConfigMap/Secret更新時に自動的にDeploymentを再起動できます：

```yaml
# Deployment にアノテーションを追加
metadata:
  annotations:
    reloader.stakater.com/auto: "true"
```

## セキュリティのベストプラクティス

ConfigMapとSecretを安全に運用するためのベストプラクティスをまとめます。

### 1. SecretをGitにコミットしない

```bash
# .gitignore に追加
echo "*-secret.yaml" >> .gitignore
echo "secret-*.yaml" >> .gitignore
echo "*.env" >> .gitignore

# 誤ってコミットしていないか確認
git log --all --full-history -- "*secret*"
```

### 2. RBAC（Role-Based Access Control）で権限を制限

```yaml
# secretへのアクセスを制限
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: secret-reader
  namespace: production
rules:
- apiGroups: [""]
  resources: ["secrets"]
  verbs: ["get", "list"]
  resourceNames: ["db-credentials"]  # 特定のSecretのみ
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: read-secrets
  namespace: production
subjects:
- kind: ServiceAccount
  name: myapp
  namespace: production
roleRef:
  kind: Role
  name: secret-reader
  apiGroup: rbac.authorization.k8s.io
```

### 3. etcdの暗号化を有効化

クラスタ管理者として、etcdでのSecret暗号化を必ず有効化してください：

```yaml
# /etc/kubernetes/enc/encryption-config.yaml
apiVersion: apiserver.config.k8s.io/v1
kind: EncryptionConfiguration
resources:
  - resources:
      - secrets
    providers:
      - aescbc:
          keys:
            - name: key1
              secret: <BASE64_ENCODED_SECRET>  # 32バイトのランダムキー
      - identity: {}
```

```bash
# kube-apiserver に設定を追加
--encryption-provider-config=/etc/kubernetes/enc/encryption-config.yaml
```

### 4. External Secretsを使用（推奨）

AWS Secrets Manager、Google Secret Manager、Azure Key Vaultなどの外部シークレットストアと統合：

```yaml
# External Secrets Operatorの例
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: db-credentials
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: aws-secrets-manager
    kind: SecretStore
  target:
    name: db-credentials
  data:
  - secretKey: password
    remoteRef:
      key: production/db/password
```

これにより、Kubernetes SecretはGitに保存せず、外部ストアから動的に取得されます。

### 5. Secretのライフサイクル管理

```bash
# 使わなくなったSecretは削除
kubectl delete secret old-api-key

# Secretの棚卸し（定期的に実行）
kubectl get secrets --all-namespaces

# 誰がSecretにアクセスできるか確認
kubectl auth can-i get secrets --as=system:serviceaccount:default:myapp
```

### 6. 最小権限の原則

```yaml
# Podに必要なSecretだけをマウント
spec:
  containers:
  - name: myapp
    image: myapp:1.0
    env:
    - name: DB_PASSWORD
      valueFrom:
        secretKeyRef:
          name: db-credentials
          key: password
    # APIキーは不要なのでマウントしない
```

### 7. 監査ログを有効化

```yaml
# Kubernetes監査ポリシーでSecret操作を記録
apiVersion: audit.k8s.io/v1
kind: Policy
rules:
- level: RequestResponse
  resources:
  - group: ""
    resources: ["secrets"]
  verbs: ["get", "list", "create", "update", "patch", "delete"]
```

## まとめと次回予告

第6回では、ConfigMapとSecretを使ったアプリケーション設定の管理方法を学びました。

**この記事で学んだこと:**

1. **Twelve-Factor Appの設定分離原則** - コードと設定を分離する重要性
2. **ConfigMapの作成と使用** - 非機密情報の外部化とYAMLマニフェスト
3. **Secretの作成と使用** - 機密情報の管理とBase64エンコードの注意点
4. **環境変数注入** - `env`と`envFrom`の使い分け
5. **Volumeマウント** - 設定ファイルをファイルシステムに配置
6. **動的更新** - ConfigMap更新時の挙動と再起動戦略
7. **セキュリティベストプラクティス** - RBACとetcd暗号化、External Secrets

**実践的なポイント:**

- ConfigMapは設定、Secretは機密情報と明確に使い分ける
- Base64はエンコードであり暗号化ではないことを理解する
- 環境変数は起動時のみ、Volumeマウントは動的更新可能
- 本番環境ではetcd暗号化とExternal Secretsを使用
- SecretをGitにコミットしない、RBACで権限制御

これで、アプリケーションの設定を環境ごとに適切に管理できるようになりました。しかし、まだ解決していない課題があります。それは、**データの永続化**です。

Podが再起動されるとコンテナ内のデータは消えてしまいます。データベースやファイルストレージなど、データを永続的に保存するにはどうすればよいのでしょうか？

**次回予告: 第7回 - PersistentVolumeでデータを永続化**

次回の記事では、以下のトピックを扱います：

- なぜPodのデータは消えてしまうのか（コンテナの揮発性）
- PersistentVolumeとPersistentVolumeClaimの関係
- StorageClassによる動的プロビジョニング
- 実際にMySQLのデータを永続化する手順
- StatefulSetとの組み合わせ
- バックアップとリストア戦略

データベースやステートフルアプリケーションを安全に運用するために、データ永続化の仕組みをしっかり理解しましょう！
