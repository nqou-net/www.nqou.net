---
title: "Kubernetesを完全に理解した（第20回）- SecretとKMS統合"
draft: true
tags:
- kubernetes
- security
- encryption
- kms
- secrets-management
description: "Secretを徹底的に保護する高度な暗号化技術。クラウドKMSと統合し、企業レベルのセキュリティ要件を満たす方法を習得します。"
---

## はじめに - 第19回の振り返りと第20回で学ぶこと

前回の第19回では、イメージスキャンとサプライチェーンセキュリティについて学びました。Trivyによる脆弱性スキャン、Cosignによるイメージ署名、AdmissionWebhookによる検証を通じて、信頼できるイメージのみを実行する仕組みを理解できました。

今回の第20回は、シリーズ最終回として **SecretとKMS統合** について学びます。Kubernetesの`Secret`はデフォルトでは暗号化されておらず、重大なセキュリティリスクとなります。etcdの保管時暗号化、クラウドKMSとの統合、Sealed Secrets、External Secretsなど、Secretを安全に管理する方法を徹底的に実践します。

本記事で学ぶ内容：

- Secretのセキュリティリスクとデフォルトの問題点
- etcdの保管時暗号化（Encryption at Rest）
- KMS統合（AWS KMS、GCP KMS、Azure Key Vault）
- Sealed Secretsによる安全なGit管理
- External Secrets Operatorによる外部Secret管理
- Secretのローテーション
- 監査とアクセス制御

## Secretのセキュリティリスク

### デフォルトのSecretの問題点

Kubernetesの`Secret`はデフォルトでは**Base64エンコードされるだけ**で、暗号化されていません：

```
Secretのデフォルト動作:

┌─────────────────────────────────────────┐
│ kubectl create secret                   │
│         ↓                               │
│ API Server                              │
│         ↓                               │
│ etcd (Base64エンコードのみ)              │
│         ↓                               │
│ ⚠️ 平文で保存！                          │
└─────────────────────────────────────────┘

リスク:
❌ etcdのバックアップが漏洩すれば全Secret流出
❌ etcdへの直接アクセスで全Secret取得可能
❌ Gitにコミットすれば履歴に永続化
```

### Secretへのアクセス経路

```
Secretへのアクセス経路:

1. kubectl get secret
   → RBAC権限があれば誰でも取得可能

2. etcdctl直接アクセス
   → etcdへのアクセス権があれば取得可能

3. Podからのマウント
   → Pod内プロセスから読み取り可能

4. バックアップファイル
   → 暗号化されていなければ流出リスク
```

## etcdの保管時暗号化

### 暗号化設定の基本

etcd内のSecretを暗号化する設定：

```yaml
# /etc/kubernetes/encryption-config.yaml
apiVersion: apiserver.config.k8s.io/v1
kind: EncryptionConfiguration
resources:
- resources:
  - secrets
  - configmaps  # 必要に応じて
  providers:
  # AESCBCで暗号化（推奨）
  - aescbc:
      keys:
      - name: key1
        secret: YourBase64EncodedSecretKey==  # 32バイトのランダムキー
  
  # 古いデータはidentityで読める（移行期間用）
  - identity: {}
```

暗号化キーの生成：

```bash
# 32バイトのランダムキーを生成
head -c 32 /dev/urandom | base64
# 出力例: r3mEkL2xN9qP8vT5wY0zH6jC4fG1bK7nM3sA9dF8eV==
```

### kube-apiserverの設定

```yaml
# /etc/kubernetes/manifests/kube-apiserver.yaml
apiVersion: v1
kind: Pod
metadata:
  name: kube-apiserver
  namespace: kube-system
spec:
  containers:
  - command:
    - kube-apiserver
    - --encryption-provider-config=/etc/kubernetes/encryption-config.yaml
    # ... 他のオプション
    
    volumeMounts:
    - name: encryption-config
      mountPath: /etc/kubernetes/encryption-config.yaml
      readOnly: true
  
  volumes:
  - name: encryption-config
    hostPath:
      path: /etc/kubernetes/encryption-config.yaml
      type: File
```

### 既存Secretの再暗号化

設定後、既存のSecretを再暗号化する必要があります：

```bash
# 全Secretを再暗号化
kubectl get secrets --all-namespaces -o json | kubectl replace -f -

# 確認: etcdから直接読み取り
ETCDCTL_API=3 etcdctl \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/etc/kubernetes/pki/etcd/ca.crt \
  --cert=/etc/kubernetes/pki/etcd/server.crt \
  --key=/etc/kubernetes/pki/etcd/server.key \
  get /registry/secrets/default/my-secret | hexdump -C

# 暗号化されている場合は以下で始まる:
# 00000000  6b 38 73 3a 65 6e 63 3a  61 65 73 63 62 63 3a 76  |k8s:enc:aescbc:v|
```

### 暗号化プロバイダーの種類

| プロバイダー | 暗号化強度 | パフォーマンス | 推奨 |
|------------|----------|--------------|-----|
| `aescbc` | 高（AES-CBC） | 中 | ✅ 推奨 |
| `aesgcm` | 高（AES-GCM） | 高 | ✅ 推奨 |
| `secretbox` | 高（XSalsa20-Poly1305） | 高 | ✅ 推奨 |
| `kms` | 最高（外部KMS） | 低 | ✅ 本番環境推奨 |
| `identity` | なし（平文） | 最高 | ❌ 非推奨 |

## KMS統合

### AWS KMSとの統合

```yaml
# /etc/kubernetes/encryption-config-kms.yaml
apiVersion: apiserver.config.k8s.io/v1
kind: EncryptionConfiguration
resources:
- resources:
  - secrets
  providers:
  # AWS KMSを使用
  - kms:
      name: aws-kms
      endpoint: unix:///var/run/kmsplugin/socket.sock
      cachesize: 1000
      timeout: 3s
  
  # フォールバック（KMS障害時用）
  - identity: {}
```

AWS KMS Pluginのインストール：

```bash
# aws-encryption-provider のインストール
wget https://github.com/kubernetes-sigs/aws-encryption-provider/releases/download/v0.5.0/aws-encryption-provider_0.5.0_linux_amd64.tar.gz
tar -xzf aws-encryption-provider_0.5.0_linux_amd64.tar.gz
sudo mv aws-encryption-provider /usr/local/bin/

# SystemdサービスとしてデプロイメントLexer error
cat > /etc/systemd/system/aws-encryption-provider.service << 'EOF'
[Unit]
Description=AWS Encryption Provider for Kubernetes
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/aws-encryption-provider \
  --key=arn:aws:kms:ap-northeast-1:123456789012:key/12345678-1234-1234-1234-123456789012 \
  --region=ap-northeast-1 \
  --listen=/var/run/kmsplugin/socket.sock
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# サービス起動
sudo systemctl daemon-reload
sudo systemctl enable aws-encryption-provider
sudo systemctl start aws-encryption-provider
```

IAMロールの設定：

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "kms:Encrypt",
        "kms:Decrypt",
        "kms:DescribeKey"
      ],
      "Resource": "arn:aws:kms:ap-northeast-1:123456789012:key/12345678-1234-1234-1234-123456789012"
    }
  ]
}
```

## Sealed Secrets

### Sealed Secretsとは

**Sealed Secrets** は、公開鍵暗号化を使ってSecretを安全にGit管理できる仕組みです：

```
Sealed Secretsの仕組み:

開発者マシン:
1. 平文Secret作成
2. kubesealで暗号化 → SealedSecret（公開鍵暗号化）
3. SealedSecretをGitにコミット ✅ 安全

クラスタ:
1. SealedSecretをapply
2. Sealed Secrets Controller が復号化（秘密鍵使用）
3. 通常のSecretとしてクラスタに保存
```

### Sealed Secretsのインストール

```bash
# Sealed Secrets Controllerのインストール
kubectl apply -f https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.24.0/controller.yaml

# インストール確認
kubectl get pods -n kube-system | grep sealed-secrets
# sealed-secrets-controller-xxx   1/1   Running   0   30s

# kubesealクライアントのインストール
wget https://github.com/bitnami-labs/sealed-secrets/releases/download/v0.24.0/kubeseal-0.24.0-linux-amd64.tar.gz
tar -xzf kubeseal-0.24.0-linux-amd64.tar.gz
sudo mv kubeseal /usr/local/bin/

# 公開鍵の取得
kubeseal --fetch-cert > sealed-secrets-public-key.pem
# この公開鍵は開発者に配布可能
```

### Sealed Secretの作成

```bash
# 通常のSecretマニフェストを作成
kubectl create secret generic my-secret \
  --from-literal=username=admin \
  --from-literal=password='SuperSecret123!' \
  --dry-run=client -o yaml > secret.yaml

# SealedSecretに変換
kubeseal -f secret.yaml -w sealed-secret.yaml

# SealedSecretをGitにコミット（安全）
git add sealed-secret.yaml
git commit -m "Add sealed secret"
git push

# クラスタにapply
kubectl apply -f sealed-secret.yaml

# 自動的にSecretが作成される
kubectl get secret my-secret
# NAME        TYPE     DATA   AGE
# my-secret   Opaque   2      10s

# Secretの内容確認（復号化されている）
kubectl get secret my-secret -o jsonpath='{.data.password}' | base64 -d
# SuperSecret123!
```

### スコープの使い分け

```bash
# Namespaceスコープ（デフォルト）: 特定Namespaceでのみ使用可能
kubeseal -f secret.yaml -w sealed-secret.yaml --scope namespace-wide

# クラスタスコープ: 全Namespaceで使用可能
kubeseal -f secret.yaml -w sealed-secret.yaml --scope cluster-wide

# Strict（デフォルト）: Name + Namespace が一致する必要がある
kubeseal -f secret.yaml -w sealed-secret.yaml --scope strict
```

## External Secrets Operator

### External Secrets Operatorとは

外部のSecret管理システムとKubernetesを同期する仕組み：

```
External Secrets Operatorの仕組み:

外部Secret管理:
AWS Secrets Manager / GCP Secret Manager / Azure Key Vault / HashiCorp Vault
           ↓
External Secrets Operator（同期）
           ↓
KubernetesのSecret（自動作成・更新）
           ↓
Pod（通常通り使用）
```

### インストール

```bash
# Helm経由でインストール
helm repo add external-secrets https://charts.external-secrets.io
helm repo update

helm install external-secrets \
  external-secrets/external-secrets \
  -n external-secrets-system \
  --create-namespace

# インストール確認
kubectl get pods -n external-secrets-system
# NAME                                                READY   STATUS    RESTARTS   AGE
# external-secrets-xxx                                1/1     Running   0          1m
# external-secrets-cert-controller-xxx                1/1     Running   0          1m
# external-secrets-webhook-xxx                        1/1     Running   0          1m
```

### AWS Secrets Managerとの統合

```yaml
# aws-secretstore.yaml
apiVersion: external-secrets.io/v1beta1
kind: SecretStore
metadata:
  name: aws-secretstore
  namespace: production
spec:
  provider:
    aws:
      service: SecretsManager
      region: ap-northeast-1
      auth:
        jwt:
          serviceAccountRef:
            name: external-secrets-sa
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: external-secrets-sa
  namespace: production
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::123456789012:role/ExternalSecretsRole
```

IAMロールの設定：

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret"
      ],
      "Resource": "arn:aws:secretsmanager:ap-northeast-1:123456789012:secret:*"
    }
  ]
}
```

ExternalSecretの作成：

```yaml
# external-secret.yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: database-credentials
  namespace: production
spec:
  refreshInterval: 1h  # 1時間ごとに同期
  
  secretStoreRef:
    name: aws-secretstore
    kind: SecretStore
  
  target:
    name: db-credentials  # 作成されるSecretの名前
    creationPolicy: Owner
  
  data:
  # AWS Secrets Managerのキーとマッピング
  - secretKey: username
    remoteRef:
      key: production/database
      property: username
  
  - secretKey: password
    remoteRef:
      key: production/database
      property: password
```

適用と確認：

```bash
# 適用
kubectl apply -f aws-secretstore.yaml
kubectl apply -f external-secret.yaml

# 自動的にSecretが作成される
kubectl get secret db-credentials -n production
# NAME              TYPE     DATA   AGE
# db-credentials    Opaque   2      30s

# ExternalSecretの状態確認
kubectl describe externalsecret database-credentials -n production
# Status:
#   Conditions:
#     Status:  True
#     Type:    Ready
#   Refresh Time:  2024-12-08T03:00:00Z
#   Sync Status:   SecretSynced
```

## Secretのローテーション

### 自動ローテーション

```yaml
# auto-rotation-externalsecret.yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: rotated-secret
  namespace: production
spec:
  refreshInterval: 5m  # 5分ごとに同期（ローテーション検出）
  
  secretStoreRef:
    name: aws-secretstore
    kind: SecretStore
  
  target:
    name: app-secret
    creationPolicy: Owner
    template:
      metadata:
        annotations:
          # アノテーションで変更を検知
          reloader.stakater.com/match: "true"
  
  data:
  - secretKey: api-key
    remoteRef:
      key: production/api-key
      property: value
```

Reloaderの導入（Secret変更時にPodを再起動）：

```bash
# Reloaderのインストール
kubectl apply -f https://raw.githubusercontent.com/stakater/Reloader/master/deployments/kubernetes/reloader.yaml

# Deploymentにアノテーション追加
kubectl patch deployment myapp -n production -p \
  '{"spec":{"template":{"metadata":{"annotations":{"reloader.stakater.com/auto":"true"}}}}}'
```

## Secretの監査とアクセス制御

### RBACによるアクセス制限

```yaml
# secret-reader-role.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: secret-reader
  namespace: production
rules:
# 特定のSecretのみ読み取り可能
- apiGroups: [""]
  resources: ["secrets"]
  resourceNames: ["app-config", "db-readonly-credentials"]
  verbs: ["get"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: secret-reader-binding
  namespace: production
subjects:
- kind: ServiceAccount
  name: app-sa
  namespace: production
roleRef:
  kind: Role
  name: secret-reader
  apiGroup: rbac.authorization.k8s.io
```

### 監査ログでSecretアクセスを追跡

```yaml
# audit-policy-secrets.yaml
apiVersion: audit.k8s.io/v1
kind: Policy
rules:
# Secretへの全アクセスを記録
- level: RequestResponse
  resources:
  - group: ""
    resources: ["secrets"]

# SealedSecretsとExternalSecretsも記録
- level: RequestResponse
  resources:
  - group: "bitnami.com"
    resources: ["sealedsecrets"]
  - group: "external-secrets.io"
    resources: ["externalsecrets"]
```

監査ログからSecretアクセスを抽出：

```bash
# 監査ログからSecretアクセスを抽出
sudo cat /var/log/kubernetes/audit.log | \
  jq 'select(.objectRef.resource=="secrets") | 
      {user: .user.username, verb: .verb, name: .objectRef.name, namespace: .objectRef.namespace, time: .requestReceivedTimestamp}'

# 出力例:
# {
#   "user": "system:serviceaccount:production:app-sa",
#   "verb": "get",
#   "name": "db-credentials",
#   "namespace": "production",
#   "time": "2024-12-08T03:00:00.000000Z"
# }
```

## Secretのベストプラクティス

### 環境変数 vs ボリュームマウント

```yaml
# ❌ 環境変数（推奨しない）
apiVersion: v1
kind: Pod
metadata:
  name: app-env
spec:
  containers:
  - name: app
    image: myapp:1.0
    env:
    - name: DATABASE_PASSWORD
      valueFrom:
        secretKeyRef:
          name: db-credentials
          key: password
    # リスク: プロセスリスト（ps aux）で見える可能性

# ✅ ボリュームマウント（推奨）
apiVersion: v1
kind: Pod
metadata:
  name: app-volume
spec:
  containers:
  - name: app
    image: myapp:1.0
    volumeMounts:
    - name: secret-volume
      mountPath: /etc/secrets
      readOnly: true
    # アプリケーション内で /etc/secrets/password を読み取る
  
  volumes:
  - name: secret-volume
    secret:
      secretName: db-credentials
      defaultMode: 0400  # 所有者のみ読み取り可能
```

### Secret管理のチェックリスト

- ✅ etcdの保管時暗号化を有効化（KMS推奨）
- ✅ RBACで最小権限の原則を適用
- ✅ Secretを環境変数ではなくボリュームマウント推奨
- ✅ External Secretsで外部Secret管理システムと統合
- ✅ Sealed Secretsでマニフェストの安全なGit管理
- ✅ 定期的なSecretローテーション
- ✅ 監査ログでアクセス追跡
- ✅ 本番/開発環境で異なるSecretを使用
- ✅ SecretをコードやDockerイメージに含めない
- ❌ Base64エンコードを暗号化と誤解しない

## まとめ

### 今回（第20回）学んだこと

1. **etcd保管時暗号化**
   - EncryptionConfigurationの設定
   - AESCBC/AESGCM/Secretboxプロバイダー
   - 既存Secretの再暗号化

2. **KMS統合**
   - AWS KMS/GCP KMS/Azure Key Vault
   - KMSプラグインの設定
   - 外部キー管理による高度なセキュリティ

3. **Sealed Secrets**
   - 公開鍵暗号化によるGit管理
   - kubesealでの暗号化
   - スコープの使い分け

4. **External Secrets Operator**
   - 外部Secret管理システムとの同期
   - 自動更新とローテーション
   - マルチクラウド対応

5. **運用ベストプラクティス**
   - RBACによるアクセス制御
   - 監査ログでの追跡
   - ボリュームマウント推奨

### ベストプラクティス

- etcd保管時暗号化は必須（KMS推奨）
- External SecretsでクラウドKMSと統合
- Sealed SecretsでGit管理を安全に
- 定期的なSecretローテーション
- 最小権限の原則（RBAC）
- 監査ログで全アクセス追跡
- 環境変数よりボリュームマウント
- Secretを絶対にコードにハードコードしない

## シリーズ全体の総括

全20回のシリーズを通じて、Kubernetesの基礎から本番運用、そしてセキュリティまで学びました：

**基礎編（第1-5回）**:
- Kubernetesの基本概念とアーキテクチャ
- Pod、Deployment、Serviceの理解
- ConfigMapとSecretによる設定管理
- PersistentVolumeによる永続化
- Namespaceによる環境分離

**実践編（第6-10回）**:
- StatefulSetによるステートフルアプリ
- DaemonSetとJobの活用
- Ingressによる外部公開
- リソース管理とQoS
- HPAによる自動スケーリング

**運用編（第11-15回）**:
- Probeによるヘルスチェック
- ログ収集とメトリクス監視
- Prometheus/Grafanaによる可視化
- アラート設定と対応
- バックアップとDR

**セキュリティ編（第16-20回）**:
- RBACによるアクセス制御
- NetworkPolicyによるネットワーク隔離
- Pod Securityによるコンテナ強化
- イメージスキャンとサプライチェーン
- SecretとKMS統合

### これからのステップ

Kubernetesの学習はここで終わりではありません：

**次のステップ：**
1. 実際のプロジェクトで実践
2. CKA（Certified Kubernetes Administrator）取得
3. Kubernetes Operators開発
4. Service Mesh（Istio、Linkerd）
5. GitOps（ArgoCD、Flux）

**継続的な学習：**
- Kubernetesの最新機能を追う
- コミュニティに参加
- ブログやQiitaで知見を共有

## おわりに

全20回のシリーズをお読みいただき、ありがとうございました。このシリーズが、皆さんのKubernetes学習と実践の一助となれば幸いです。

Kubernetesは日々進化し続けています。本シリーズで学んだ基礎を土台に、これからも継続的に学び、実践し、知見を共有していきましょう。

Happy Kubernetes Learning! 🚀
