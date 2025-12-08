---
title: "Kubernetesを完全に理解した（第19回）- イメージスキャンとサプライチェーン"
draft: true
tags:
- kubernetes
- security
- image-scanning
- supply-chain
- trivy
description: "コンテナイメージに潜む脆弱性を検出し、信頼できるイメージのみをデプロイする仕組みを構築。サプライチェーン攻撃への対策を学びます。"
---

## はじめに - 第18回の振り返りと第19回で学ぶこと

前回の第18回では、Pod Securityについて学びました。PodSecurityStandardsの3つのレベル、SecurityContext、Seccomp、Capabilitiesを使って、コンテナ実行環境を強化する方法を理解できました。

今回の第19回では、**イメージスキャンとサプライチェーンセキュリティ** について学びます。コンテナイメージの脆弱性は、Kubernetesクラスタ全体のセキュリティを脅かす最大のリスクの一つです。Trivyを使った脆弱性スキャン、イメージ署名・検証、AdmissionWebhookによる安全なイメージ運用を実践します。

本記事で学ぶ内容：

- コンテナイメージのセキュリティリスク
- Trivyによる脆弱性スキャン
- Trivy Operatorでクラスタスキャン
- Cosignによるイメージ署名と検証
- AdmissionWebhookによる検証（Kyverno、OPA Gatekeeper）
- プライベートレジストリの構築（Harbor）
- SBOMとサプライチェーン管理

## コンテナイメージのセキュリティリスク

### 主要なリスク

```
┌──────────────────────────────────────────┐
│   コンテナイメージのセキュリティリスク    │
├──────────────────────────────────────────┤
│ 1. 既知の脆弱性 (CVE)                     │
│    - OSパッケージの脆弱性                │
│    - アプリケーション依存関係の脆弱性     │
│                                          │
│ 2. 設定ミス                              │
│    - rootユーザーでの実行                │
│    - 不要なCapabilitiesの保持            │
│    - シークレットのハードコード           │
│                                          │
│ 3. サプライチェーン攻撃                   │
│    - 改ざんされたベースイメージ           │
│    - マルウェアを含む依存パッケージ       │
│    - 信頼できないレジストリ               │
│                                          │
│ 4. ライセンス違反                         │
│    - GPL等の制限的ライセンス              │
│    - 商用利用禁止ライセンス               │
└──────────────────────────────────────────┘
```

### 脆弱性の深刻度レベル

| 深刻度 | CVSSスコア | 対応期限 | 対応方針 |
|-------|----------|---------|---------|
| **Critical** | 9.0-10.0 | 即座 | 即座にパッチ適用またはイメージ更新 |
| **High** | 7.0-8.9 | 1週間以内 | 優先的にパッチ適用 |
| **Medium** | 4.0-6.9 | 1ヶ月以内 | 計画的にパッチ適用 |
| **Low** | 0.1-3.9 | 四半期ごと | 定期メンテナンスで対応 |

## Trivyによる脆弱性スキャン

### Trivyのインストール

```bash
# Trivyのインストール（Linux）
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo apt-key add -
echo "deb https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | sudo tee -a /etc/apt/sources.list.d/trivy.list
sudo apt-get update
sudo apt-get install trivy

# バージョン確認
trivy --version
# Version: 0.48.0

# データベース更新
trivy image --download-db-only
```

### イメージスキャンの基本

```bash
# 基本的なイメージスキャン
trivy image myapp:1.0

# 出力例:
# myapp:1.0 (alpine 3.18.4)
# ==========================
# Total: 5 (UNKNOWN: 0, LOW: 1, MEDIUM: 2, HIGH: 1, CRITICAL: 1)
# 
# ┌─────────────┬───────────────┬──────────┬───────────────────┬───────────────┬────────────────────────────────┐
# │   Library   │ Vulnerability │ Severity │ Installed Version │ Fixed Version │            Title               │
# ├─────────────┼───────────────┼──────────┼───────────────────┼───────────────┼────────────────────────────────┤
# │ libcrypto3  │ CVE-2023-5678 │ CRITICAL │ 3.1.3-r0          │ 3.1.4-r0      │ openssl: Buffer overflow in... │
# │ busybox     │ CVE-2023-1234 │ HIGH     │ 1.36.1-r2         │ 1.36.1-r5     │ busybox: Command injection...  │
# └─────────────┴───────────────┴──────────┴───────────────────┴───────────────┴────────────────────────────────┘

# 特定の深刻度以上のみ表示
trivy image --severity HIGH,CRITICAL myapp:1.0

# 脆弱性が見つかった場合に非ゼロで終了（CI/CD用）
trivy image --exit-code 1 --severity CRITICAL myapp:1.0

# JSONフォーマットで出力
trivy image --format json --output result.json myapp:1.0
```

### CI/CDへの統合

GitHubActionsでの自動スキャン例：

```yaml
# .github/workflows/image-scan.yml
name: Container Image Scan

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  trivy-scan:
    runs-on: ubuntu-latest
    steps:
    - name: Checkout code
      uses: actions/checkout@v4
    
    - name: Build image
      run: docker build -t myapp:${{ github.sha }} .
    
    - name: Run Trivy vulnerability scanner
      uses: aquasecurity/trivy-action@master
      with:
        image-ref: myapp:${{ github.sha }}
        format: 'sarif'
        output: 'trivy-results.sarif'
        severity: 'CRITICAL,HIGH'
        exit-code: '1'  # CRITICALまたはHIGHがあればfail
    
    - name: Upload Trivy results to GitHub Security
      uses: github/codeql-action/upload-sarif@v2
      if: always()
      with:
        sarif_file: 'trivy-results.sarif'
    
    - name: Push image (if scan passed)
      if: success()
      run: |
        docker tag myapp:${{ github.sha }} myregistry/myapp:${{ github.sha }}
        docker push myregistry/myapp:${{ github.sha }}
```

## Trivyクラスタスキャン

### Trivy Operatorのインストール

クラスタ内で実行中の全イメージを自動スキャン：

```bash
# Helm経由でTrivy Operatorをインストール
helm repo add aqua https://aquasecurity.github.io/helm-charts/
helm repo update

helm install trivy-operator aqua/trivy-operator \
  --namespace trivy-system \
  --create-namespace \
  --set="trivy.ignoreUnfixed=true"

# インストール確認
kubectl get pods -n trivy-system
# NAME                              READY   STATUS    RESTARTS   AGE
# trivy-operator-5d8f9c7b6d-abc12   1/1     Running   0          1m

# CRDの確認
kubectl get crd | grep aquasecurity
# vulnerabilityreports.aquasecurity.github.io
# configauditreports.aquasecurity.github.io
```

### 脆弱性レポートの確認

```bash
# VulnerabilityReportの確認
kubectl get vulnerabilityreports -n production
# NAME                                    REPOSITORY      TAG     SCANNER   AGE
# replicaset-myapp-5d8f9c7b6d-myapp       myregistry      1.0     Trivy     5m

# 詳細確認
kubectl describe vulnerabilityreport -n production replicaset-myapp-5d8f9c7b6d-myapp

# 出力例:
# Summary:
#   Critical Count:  1
#   High Count:      3
#   Medium Count:    5
#   Low Count:       10
# 
# Vulnerabilities:
#   - Vulnerability ID:  CVE-2023-5678
#     Severity:          CRITICAL
#     Package:           openssl
#     Installed Version: 3.1.3
#     Fixed Version:     3.1.4
```

## イメージ署名と検証

### Cosignによるイメージ署名

```bash
# Cosignのインストール
wget https://github.com/sigstore/cosign/releases/download/v2.2.0/cosign-linux-amd64
chmod +x cosign-linux-amd64
sudo mv cosign-linux-amd64 /usr/local/bin/cosign

# 鍵ペアの生成
cosign generate-key-pair
# Enter password for private key: ********
# Private key written to cosign.key
# Public key written to cosign.pub

# イメージの署名
export COSIGN_PASSWORD="your-password"
cosign sign --key cosign.key myregistry/myapp:1.0
# Pushing signature to: myregistry/myapp:sha256-xxx.sig

# 署名の確認
cosign verify --key cosign.pub myregistry/myapp:1.0
# 
# Verification for myregistry/myapp:1.0 --
# The following checks were performed on each of these signatures:
#   - The cosign claims were validated
#   - The signatures were verified against the specified public key
```

### Keylessモード（Sigstore）

パスワード不要のOIDCベース署名：

```bash
# Keyless署名（OIDCベース）
cosign sign myregistry/myapp:1.0

# ブラウザが開き、GitHub/Google/Microsoftでログイン
# 署名が自動的にSigstore Transparency Logに記録される

# Keyless検証
cosign verify \
  --certificate-identity=user@example.com \
  --certificate-oidc-issuer=https://github.com/login/oauth \
  myregistry/myapp:1.0
```

## AdmissionWebhookによる検証

### Kyvernoによる署名検証

```bash
# Kyvernoのインストール
helm repo add kyverno https://kyverno.github.io/kyverno/
helm repo update

helm install kyverno kyverno/kyverno \
  --namespace kyverno \
  --create-namespace

# インストール確認
kubectl get pods -n kyverno
# NAME                       READY   STATUS    RESTARTS   AGE
# kyverno-xxxx               1/1     Running   0          1m
```

イメージ署名検証ポリシー：

```yaml
# verify-image-signature.yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: verify-image-signature
spec:
  validationFailureAction: Enforce
  background: false
  webhookTimeoutSeconds: 30
  
  rules:
  - name: verify-signature
    match:
      any:
      - resources:
          kinds:
          - Pod
          namespaces:
          - production
    
    verifyImages:
    - imageReferences:
      - "myregistry/*"
      
      attestors:
      - count: 1
        entries:
        - keys:
            publicKeys: |-
              -----BEGIN PUBLIC KEY-----
              MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAE...
              -----END PUBLIC KEY-----
      
      required: true
```

テスト：

```bash
# ポリシーの適用
kubectl apply -f verify-image-signature.yaml

# テスト: 署名されていないイメージ
kubectl run unsigned-pod --image=nginx:latest -n production
# Error: image verification failed: signature not found

# テスト: 署名されたイメージ
kubectl run signed-pod --image=myregistry/myapp:1.0 -n production
# pod/signed-pod created
```

### OPA Gatekeeperによるポリシー強制

イメージレジストリ制限：

```yaml
# allowed-registries-template.yaml
apiVersion: templates.gatekeeper.sh/v1
kind: ConstraintTemplate
metadata:
  name: k8sallowedregistries
spec:
  crd:
    spec:
      names:
        kind: K8sAllowedRegistries
      validation:
        openAPIV3Schema:
          type: object
          properties:
            registries:
              type: array
              items:
                type: string
  
  targets:
  - target: admission.k8s.gatekeeper.sh
    rego: |
      package k8sallowedregistries
      
      violation[{"msg": msg}] {
        container := input.review.object.spec.containers[_]
        not startswith(container.image, input.parameters.registries[_])
        msg := sprintf("Image '%v' is not from allowed registry", [container.image])
      }
---
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: K8sAllowedRegistries
metadata:
  name: allowed-registries
spec:
  match:
    kinds:
    - apiGroups: [""]
      kinds: ["Pod"]
    namespaces:
    - production
  
  parameters:
    registries:
    - "myregistry.io/"
    - "gcr.io/myproject/"
```

latestタグの禁止：

```yaml
# disallow-latest-tag.yaml
apiVersion: templates.gatekeeper.sh/v1
kind: ConstraintTemplate
metadata:
  name: k8sdisallowlatesttag
spec:
  crd:
    spec:
      names:
        kind: K8sDisallowLatestTag
  
  targets:
  - target: admission.k8s.gatekeeper.sh
    rego: |
      package k8sdisallowlatesttag
      
      violation[{"msg": msg}] {
        container := input.review.object.spec.containers[_]
        endswith(container.image, ":latest")
        msg := sprintf("Container '%v' uses ':latest' tag which is not allowed", [container.name])
      }
      
      violation[{"msg": msg}] {
        container := input.review.object.spec.containers[_]
        not contains(container.image, ":")
        msg := sprintf("Container '%v' does not specify image tag", [container.name])
      }
---
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: K8sDisallowLatestTag
metadata:
  name: disallow-latest-tag
spec:
  match:
    kinds:
    - apiGroups: [""]
      kinds: ["Pod"]
    namespaces:
    - production
```

## プライベートレジストリの構築

### Harborのインストール

```bash
# Harborのインストール（Helm）
helm repo add harbor https://helm.goharbor.io
helm repo update

helm install harbor harbor/harbor \
  --namespace harbor \
  --create-namespace \
  --set expose.type=ingress \
  --set expose.ingress.hosts.core=harbor.example.com \
  --set externalURL=https://harbor.example.com \
  --set persistence.enabled=true \
  --set harborAdminPassword="YourSecurePassword"

# インストール確認
kubectl get pods -n harbor
# NAME                                    READY   STATUS    RESTARTS   AGE
# harbor-core-xxx                         1/1     Running   0          2m
# harbor-database-xxx                     1/1     Running   0          2m
# harbor-jobservice-xxx                   1/1     Running   0          2m
# harbor-registry-xxx                     1/1     Running   0          2m
# harbor-trivy-xxx                        1/1     Running   0          2m
```

### 脆弱性スキャンの有効化

Harbor UIでプロジェクト設定：
1. プロジェクト作成: myproject
2. Configuration → Automatically scan images on push: ON
3. Configuration → Prevent vulnerable images from running: ON
4. Vulnerability severity: High, Critical

イメージのプッシュで自動的にスキャンが実行されます：

```bash
# イメージのプッシュ
docker tag myapp:1.0 harbor.example.com/myproject/myapp:1.0
docker push harbor.example.com/myproject/myapp:1.0

# 自動的にTrivyスキャンが実行される
# Harbor UIでスキャン結果を確認可能
```

## SBOMとサプライチェーン管理

### SBOMの生成

**SBOM（Software Bill of Materials）** は、ソフトウェアの構成部品リストです：

```bash
# Syftを使ったSBOM生成
curl -sSfL https://raw.githubusercontent.com/anchore/syft/main/install.sh | sh -s -- -b /usr/local/bin

# CycloneDX形式でSBOM生成
syft myapp:1.0 -o cyclonedx-json > sbom-cyclonedx.json

# SPDX形式でSBOM生成
syft myapp:1.0 -o spdx-json > sbom-spdx.json

# SBOMの内容確認
cat sbom-cyclonedx.json | jq '.components[] | {name, version, type}'
```

## 継続的な脆弱性管理

### 定期スキャンの自動化

```yaml
# scheduled-scan-cronjob.yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: image-scanner
  namespace: security
spec:
  schedule: "0 2 * * *"  # 毎日2時に実行
  jobTemplate:
    spec:
      template:
        spec:
          serviceAccountName: image-scanner
          containers:
          - name: trivy
            image: aquasec/trivy:latest
            command:
            - /bin/sh
            - -c
            - |
              # 全Namespaceのイメージをスキャン
              for ns in $(kubectl get ns -o jsonpath='{.items[*].metadata.name}'); do
                echo "Scanning namespace: $ns"
                for image in $(kubectl get pods -n $ns -o jsonpath='{.items[*].spec.containers[*].image}' | tr ' ' '\n' | sort -u); do
                  echo "Scanning image: $image"
                  trivy image --severity HIGH,CRITICAL $image
                done
              done
          restartPolicy: OnFailure
```

## まとめ

### 今回（第19回）学んだこと

1. **脆弱性スキャン**
   - Trivyによるイメージスキャン
   - CI/CDパイプラインへの統合
   - Trivy Operatorでクラスタスキャン

2. **イメージ署名と検証**
   - Cosignによる署名
   - Keylessモード（Sigstore）
   - SBOMとattestationの添付

3. **AdmissionWebhook**
   - Kyvernoによる署名検証
   - OPA Gatekeeperによるポリシー強制
   - レジストリとタグの制限

4. **プライベートレジストリ**
   - Harbor構築と脆弱性スキャン
   - SBOM管理

### ベストプラクティス

- 全イメージのスキャンをCI/CDで自動化
- CRITICAL/HIGH脆弱性は即座に対応
- イメージ署名を必須化
- latestタグの使用禁止
- プライベートレジストリの活用
- SBOMの継続的な管理
- 定期的な脆弱性レビュー

### 次回予告

次回の第20回では、シリーズ最終回として **SecretとKMS統合** について学びます。Secretを徹底的に保護する高度な暗号化技術、クラウドKMSと統合し、企業レベルのセキュリティ要件を満たす方法を習得します。etcdの保管時暗号化、Sealed Secrets、External Secrets Operatorなど、Secretの安全な管理を完全にマスターしましょう！
