---
title: "Secretの暗号化とKMS統合 - 機密情報の安全な管理（技術詳細）"
draft: true
tags:
- kubernetes
- security
- secrets
- encryption
- kms
- external-secrets
- sealed-secrets
description: "Kubernetes Secretの完全セキュリティガイド。etcdの保管時暗号化、AWS KMS/GCP KMS/Azure Key Vault統合、Sealed Secrets、External Secretsまで実践的に解説。"
---

## はじめに

Kubernetesの`Secret`はデフォルトではetcd内にBase64エンコードされた状態で保存されるだけで、暗号化されていません。これは重大なセキュリティリスクとなります。本記事では、etcdの保管時暗号化（Encryption at Rest）、クラウドKMSとの統合、Sealed Secrets、External Secretsなど、Secretを安全に管理する方法を徹底解説します。

## 1. Secretのセキュリティリスク

### 1.1 デフォルトのSecretの問題点

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

### 1.2 Secretへのアクセス経路

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

## 2. etcdの保管時暗号化（Encryption at Rest）

### 2.1 暗号化設定の基本

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

**暗号化キーの生成**:
```bash
# 32バイトのランダムキーを生成
head -c 32 /dev/urandom | base64
# 出力例: r3mEkL2xN9qP8vT5wY0zH6jC4fG1bK7nM3sA9dF8eV==
```

### 2.2 kube-apiserverの設定

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

```bash
# kube-apiserverの再起動（自動で再起動される）
# manifestファイルを編集すると自動的に反映

# 確認
kubectl get pods -n kube-system | grep kube-apiserver
# kube-apiserver-xxx   1/1   Running   0   30s
```

### 2.3 既存Secretの再暗号化

```bash
# 全Secretを再暗号化（既存データは暗号化されていないため）
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
#                k  8  s  :  e  n  c  :  a  e  s  c  b  c  :  v
```

### 2.4 暗号化プロバイダーの種類

| プロバイダー | 暗号化強度 | パフォーマンス | 推奨 |
|------------|----------|--------------|-----|
| `aescbc` | 高（AES-CBC） | 中 | ✅ 推奨 |
| `aesgcm` | 高（AES-GCM） | 高 | ✅ 推奨 |
| `secretbox` | 高（XSalsa20-Poly1305） | 高 | ✅ 推奨 |
| `kms` | 最高（外部KMS） | 低 | ✅ 本番環境推奨 |
| `identity` | なし（平文） | 最高 | ❌ 非推奨 |

## 3. KMS統合（Cloud Provider KMS）

### 3.1 AWS KMSとの統合

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

**AWS KMS Pluginのインストール**:
```bash
# aws-encryption-provider のインストール
wget https://github.com/kubernetes-sigs/aws-encryption-provider/releases/download/v0.5.0/aws-encryption-provider_0.5.0_linux_amd64.tar.gz
tar -xzf aws-encryption-provider_0.5.0_linux_amd64.tar.gz
sudo mv aws-encryption-provider /usr/local/bin/

# SystemdサービスとしてデプロイメLexer error
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

**IAMロールの設定**:
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

### 3.2 GCP KMSとの統合

```yaml
# /etc/kubernetes/encryption-config-gcp-kms.yaml
apiVersion: apiserver.config.k8s.io/v1
kind: EncryptionConfiguration
resources:
- resources:
  - secrets
  providers:
  - kms:
      name: gcp-kms
      endpoint: unix:///var/run/kmsplugin/socket.sock
      cachesize: 1000
      timeout: 3s
```

```bash
# GCP KMS Pluginのインストール
wget https://github.com/GoogleCloudPlatform/k8s-cloudkms-plugin/releases/download/v0.3.0/k8s-cloudkms-plugin_0.3.0_linux_amd64.tar.gz
tar -xzf k8s-cloudkms-plugin_0.3.0_linux_amd64.tar.gz
sudo mv k8s-cloudkms-plugin /usr/local/bin/

# サービスアカウントキーを配置
# /var/run/kmsplugin/service-account.json

# 起動
/usr/local/bin/k8s-cloudkms-plugin \
  --project-id=my-gcp-project \
  --location=asia-northeast1 \
  --key-ring=kubernetes \
  --key-name=etcd-encryption \
  --credentials-file=/var/run/kmsplugin/service-account.json \
  --listen=/var/run/kmsplugin/socket.sock
```

### 3.3 Azure Key Vaultとの統合

```yaml
# /etc/kubernetes/encryption-config-azure-kms.yaml
apiVersion: apiserver.config.k8s.io/v1
kind: EncryptionConfiguration
resources:
- resources:
  - secrets
  providers:
  - kms:
      name: azure-kms
      endpoint: unix:///var/run/kmsplugin/socket.sock
      cachesize: 1000
      timeout: 3s
```

```bash
# Azure Key Vault Providerのインストール
helm repo add csi-secrets-store-provider-azure https://azure.github.io/secrets-store-csi-driver-provider-azure/charts
helm install csi-secrets-store-provider-azure/csi-secrets-store-provider-azure \
  --namespace kube-system \
  --set secrets-store-csi-driver.syncSecret.enabled=true

# KMS Pluginの設定
cat > /etc/kubernetes/azure-kms-config.yaml << 'EOF'
tenantId: "your-tenant-id"
subscriptionId: "your-subscription-id"
resourceGroup: "your-resource-group"
vaultName: "your-keyvault-name"
keyName: "etcd-encryption-key"
EOF
```

## 4. Sealed Secrets

### 4.1 Sealed Secretsとは

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

### 4.2 Sealed Secretsのインストール

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

### 4.3 Sealed Secretの作成

```bash
# 通常のSecretマニフェストを作成
kubectl create secret generic my-secret \
  --from-literal=username=admin \
  --from-literal=password='SuperSecret123!' \
  --dry-run=client -o yaml > secret.yaml

# cat secret.yaml
# apiVersion: v1
# kind: Secret
# metadata:
#   name: my-secret
# data:
#   username: YWRtaW4=  # Base64エンコードのみ
#   password: U3VwZXJTZWNyZXQxMjMh

# SealedSecretに変換
kubeseal -f secret.yaml -w sealed-secret.yaml

# cat sealed-secret.yaml
# apiVersion: bitnami.com/v1alpha1
# kind: SealedSecret
# metadata:
#   name: my-secret
#   namespace: default
# spec:
#   encryptedData:
#     username: AgBi8F7N...（暗号化された長い文字列）
#     password: AgCx9K2M...（暗号化された長い文字列）

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

### 4.4 Namespace/クラスタスコープのSealed Secrets

```bash
# Namespaceスコープ（デフォルト）: 特定Namespaceでのみ使用可能
kubeseal -f secret.yaml -w sealed-secret.yaml --scope namespace-wide

# クラスタスコープ: 全Namespaceで使用可能
kubeseal -f secret.yaml -w sealed-secret.yaml --scope cluster-wide

# Strict（デフォルト）: Name + Namespace が一致する必要がある
kubeseal -f secret.yaml -w sealed-secret.yaml --scope strict
```

## 5. External Secrets Operator

### 5.1 External Secrets Operatorとは

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

### 5.2 インストール

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

### 5.3 AWS Secrets Managerとの統合

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

**IAMロールの設定**:
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
      key: production/database  # AWS Secrets Managerのシークレット名
      property: username
  
  - secretKey: password
    remoteRef:
      key: production/database
      property: password
```

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

### 5.4 GCP Secret Managerとの統合

```yaml
# gcp-secretstore.yaml
apiVersion: external-secrets.io/v1beta1
kind: SecretStore
metadata:
  name: gcp-secretstore
  namespace: production
spec:
  provider:
    gcpsm:
      projectID: my-gcp-project
      auth:
        workloadIdentity:
          clusterLocation: asia-northeast1
          clusterName: my-gke-cluster
          serviceAccountRef:
            name: external-secrets-sa
---
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: app-config
  namespace: production
spec:
  refreshInterval: 30m
  
  secretStoreRef:
    name: gcp-secretstore
    kind: SecretStore
  
  target:
    name: app-config-secret
  
  data:
  - secretKey: api-key
    remoteRef:
      key: projects/123456789/secrets/production-api-key/versions/latest
```

### 5.5 HashiCorp Vaultとの統合

```yaml
# vault-secretstore.yaml
apiVersion: external-secrets.io/v1beta1
kind: SecretStore
metadata:
  name: vault-secretstore
  namespace: production
spec:
  provider:
    vault:
      server: "https://vault.example.com"
      path: "secret"
      version: "v2"
      auth:
        kubernetes:
          mountPath: "kubernetes"
          role: "external-secrets"
          serviceAccountRef:
            name: external-secrets-sa
---
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: vault-secret
  namespace: production
spec:
  refreshInterval: 15m
  
  secretStoreRef:
    name: vault-secretstore
    kind: SecretStore
  
  target:
    name: vault-app-secret
  
  data:
  - secretKey: database-url
    remoteRef:
      key: production/database
      property: url
  
  - secretKey: database-password
    remoteRef:
      key: production/database
      property: password
```

## 6. Secretのローテーション

### 6.1 自動ローテーション（External Secrets）

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

**Reloaderの導入**:
```bash
# Reloaderのインストール（Secret変更時にPodを再起動）
kubectl apply -f https://raw.githubusercontent.com/stakater/Reloader/master/deployments/kubernetes/reloader.yaml

# Deploymentにアノテーション追加
kubectl patch deployment myapp -n production -p \
  '{"spec":{"template":{"metadata":{"annotations":{"reloader.stakater.com/auto":"true"}}}}}'
```

### 6.2 手動ローテーション

```bash
# AWS Secrets Managerでシークレットをローテーション
aws secretsmanager rotate-secret \
  --secret-id production/database \
  --rotation-lambda-arn arn:aws:lambda:ap-northeast-1:123456789012:function:SecretsManagerRotation

# External Secretsが自動的に同期
# RefreshIntervalに応じてSecretが更新される

# 即座に同期したい場合
kubectl annotate externalsecret database-credentials \
  force-sync=$(date +%s) \
  -n production
```

## 7. Secretの監査とアクセス制御

### 7.1 RBAC によるアクセス制限

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

### 7.2 監査ログでSecret アクセスを追跡

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

## 8. Secretのベストプラクティス

### 8.1 Secret管理のチェックリスト

- ✅ etcdの保管時暗号化を有効化（KMS推奨）
- ✅ RBAC で最小権限の原則を適用
- ✅ Secretを環境変数ではなくボリュームマウント推奨
- ✅ External Secretsで外部Secret管理システムと統合
- ✅ Sealed Secretsでマニフェストの安全なGit管理
- ✅ 定期的なSecretローテーション
- ✅ 監査ログでアクセス追跡
- ✅ 本番/開発環境で異なるSecretを使用
- ✅ SecretをコードやDockerイメージに含めない
- ❌ Base64エンコードを暗号化と誤解しない

### 8.2 環境変数 vs ボリュームマウント

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

### 8.3 init Containerでのシークレット検証

```yaml
# validate-secrets-init.yaml
apiVersion: v1
kind: Pod
metadata:
  name: app-with-validation
spec:
  initContainers:
  # Secretの検証
  - name: validate-secrets
    image: busybox
    command:
    - /bin/sh
    - -c
    - |
      # 必須ファイルの存在確認
      if [ ! -f /etc/secrets/password ]; then
        echo "Error: password secret not found"
        exit 1
      fi
      
      # パスワードの長さチェック
      if [ $(wc -c < /etc/secrets/password) -lt 8 ]; then
        echo "Error: password too short"
        exit 1
      fi
      
      echo "Secret validation passed"
    volumeMounts:
    - name: secret-volume
      mountPath: /etc/secrets
      readOnly: true
  
  containers:
  - name: app
    image: myapp:1.0
    volumeMounts:
    - name: secret-volume
      mountPath: /etc/secrets
      readOnly: true
  
  volumes:
  - name: secret-volume
    secret:
      secretName: db-credentials
```

## まとめ

### 学んだこと

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

## 参考リンク

- {{< linkcard "https://kubernetes.io/docs/tasks/administer-cluster/encrypt-data/" >}}
- {{< linkcard "https://github.com/bitnami-labs/sealed-secrets" >}}
- {{< linkcard "https://external-secrets.io/" >}}
- {{< linkcard "https://www.vaultproject.io/docs/platform/k8s" >}}
