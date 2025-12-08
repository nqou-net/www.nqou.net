---
title: "イメージスキャンとサプライチェーンセキュリティ - コンテナの安全性確保（技術詳細）"
draft: true
tags:
- kubernetes
- security
- image-scanning
- supply-chain
- trivy
- admission-webhook
- sbom
description: "Kubernetes環境でのイメージスキャンとサプライチェーンセキュリティの完全ガイド。Trivyによる脆弱性スキャン、イメージ署名と検証、AdmissionWebhookまで実践的に解説。"
---

## はじめに

コンテナイメージの脆弱性は、Kubernetesクラスタ全体のセキュリティを脅かす最大のリスクの一つです。サプライチェーン攻撃も増加しており、信頼できないイメージの実行を防ぐことが重要です。本記事では、Trivyを使った脆弱性スキャン、イメージ署名・検証、AdmissionWebhookによる安全なイメージのみの実行強制まで徹底解説します。

## 1. コンテナイメージのセキュリティリスク

### 1.1 主要なリスク

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

### 1.2 脆弱性の深刻度レベル

| 深刻度 | CVSSスコア | 対応期限 | 対応方針 |
|-------|----------|---------|---------|
| **Critical** | 9.0-10.0 | 即座 | 即座にパッチ適用またはイメージ更新 |
| **High** | 7.0-8.9 | 1週間以内 | 優先的にパッチ適用 |
| **Medium** | 4.0-6.9 | 1ヶ月以内 | 計画的にパッチ適用 |
| **Low** | 0.1-3.9 | 四半期ごと | 定期メンテナンスで対応 |
| **Unknown** | - | 調査 | 詳細調査後に判断 |

## 2. Trivyによる脆弱性スキャン

### 2.1 Trivyのインストール

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

### 2.2 イメージスキャンの基本

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
# │ libssl3     │ CVE-2023-5678 │ CRITICAL │ 3.1.3-r0          │ 3.1.4-r0      │ openssl: Buffer overflow in... │
# │ busybox     │ CVE-2023-1234 │ HIGH     │ 1.36.1-r2         │ 1.36.1-r5     │ busybox: Command injection...  │
# └─────────────┴───────────────┴──────────┴───────────────────┴───────────────┴────────────────────────────────┘

# JSONフォーマットで出力
trivy image --format json --output result.json myapp:1.0

# 特定の深刻度以上のみ表示
trivy image --severity HIGH,CRITICAL myapp:1.0

# 脆弱性が見つかった場合に非ゼロで終了（CI/CD用）
trivy image --exit-code 1 --severity CRITICAL myapp:1.0
```

### 2.3 詳細スキャン

```bash
# OSパッケージと言語固有のパッケージをスキャン
trivy image --scanners vuln,secret,config myapp:1.0

# シークレット検出
trivy image --scanners secret myapp:1.0
# 検出例:
# - AWS Access Key
# - GitHub Token
# - Private Key

# 設定ミス検出
trivy image --scanners config myapp:1.0
# 検出例:
# - USER rootで実行
# - HEALTHCHECK未定義

# SBOMの生成
trivy image --format cyclonedx --output sbom.json myapp:1.0

# SBOMからスキャン
trivy sbom sbom.json
```

### 2.4 CI/CDへの統合

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

## 3. Trivyクラスタスキャン

### 3.1 Trivy Operatorのインストール

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
# clusterconfigauditreports.aquasecurity.github.io
```

### 3.2 脆弱性レポートの確認

```bash
# VulnerabilityReportの確認
kubectl get vulnerabilityreports -n production
# NAME                                    REPOSITORY      TAG     SCANNER   AGE
# replicaset-myapp-5d8f9c7b6d-myapp       myregistry      1.0     Trivy     5m
# replicaset-postgres-6c8d9f8c7d-postgres postgres        15      Trivy     5m

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

# JSONで出力
kubectl get vulnerabilityreport -n production -o json | jq .
```

### 3.3 ConfigAuditReportの確認

```bash
# ConfigAuditReportの確認
kubectl get configauditreports -n production

# 詳細確認
kubectl describe configauditreport -n production replicaset-myapp-5d8f9c7b6d

# 検出される設定ミス例:
# - Container 'myapp' should set 'securityContext.runAsNonRoot' to true
# - Container 'myapp' should drop all capabilities
# - Container 'myapp' should set 'securityContext.readOnlyRootFilesystem' to true
```

## 4. イメージ署名と検証

### 4.1 Cosignによるイメージ署名

```bash
# Cosignのインストール
wget https://github.com/sigstore/cosign/releases/download/v2.2.0/cosign-linux-amd64
chmod +x cosign-linux-amd64
sudo mv cosign-linux-amd64 /usr/local/bin/cosign

# 鍵ペアの生成
cosign generate-key-pair
# Enter password for private key: ********
# Enter password for private key again: ********
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

### 4.2 Keylessモード（Sigstore）

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

### 4.3 署名のメタデータ付加

```yaml
# signature-metadata.yaml
attestations:
  - name: sbom
    type: https://cyclonedx.org/bom
  - name: scan-result
    type: https://aquasecurity.github.io/trivy
  - name: build-provenance
    type: https://slsa.dev/provenance/v0.2
```

```bash
# SBOMの添付
trivy image --format cyclonedx --output sbom.json myapp:1.0
cosign attach sbom --sbom sbom.json myregistry/myapp:1.0

# スキャン結果の添付
trivy image --format json --output scan.json myapp:1.0
cosign attest --key cosign.key --predicate scan.json myregistry/myapp:1.0

# 検証時にattestationも確認
cosign verify-attestation --key cosign.pub myregistry/myapp:1.0
```

## 5. AdmissionWebhookによる検証

### 5.1 AdmissionWebhookの仕組み

```
Pod作成フロー:

kubectl create → API Server → Admission Controllers
                               ↓
                    ValidatingWebhook ←→ 外部Webhook Server
                               ↓         （署名検証、スキャン結果確認）
                    MutatingWebhook
                               ↓
                            Scheduler
```

### 5.2 Kyverno による署名検証

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

```yaml
# verify-image-signature.yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: verify-image-signature
spec:
  validationFailureAction: Enforce  # Audit or Enforce
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
      
      # 追加の検証
      required: true
```

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

### 5.3 脆弱性チェックポリシー

```yaml
# check-vulnerabilities.yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: check-vulnerabilities
spec:
  validationFailureAction: Enforce
  background: false
  
  rules:
  - name: check-critical-vulnerabilities
    match:
      any:
      - resources:
          kinds:
          - Pod
          namespaces:
          - production
    
    validate:
      message: "Image contains CRITICAL vulnerabilities"
      deny:
        conditions:
          all:
          - key: "{{ images.*.attestations.vulnerabilities[?severity=='CRITICAL'] | length(@) }}"
            operator: GreaterThan
            value: 0
```

## 6. OPA Gatekeeper によるポリシー強制

### 6.1 Gatekeeperのインストール

```bash
# Gatekeeperのインストール
kubectl apply -f https://raw.githubusercontent.com/open-policy-agent/gatekeeper/release-3.14/deploy/gatekeeper.yaml

# インストール確認
kubectl get pods -n gatekeeper-system
# NAME                                            READY   STATUS    RESTARTS   AGE
# gatekeeper-audit-xxx                            1/1     Running   0          1m
# gatekeeper-controller-manager-xxx               1/1     Running   0          1m
```

### 6.2 イメージレジストリ制限

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

```bash
# ポリシー適用
kubectl apply -f allowed-registries-template.yaml

# テスト: 許可されていないレジストリ
kubectl run nginx --image=nginx:latest -n production
# Error: Image 'nginx:latest' is not from allowed registry

# テスト: 許可されたレジストリ
kubectl run myapp --image=myregistry.io/myapp:1.0 -n production
# pod/myapp created
```

### 6.3 イメージタグ制限（latestタグの禁止）

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

## 7. プライベートレジストリの構築

### 7.1 Harbor のインストール

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
# harbor-portal-xxx                       1/1     Running   0          2m
# harbor-registry-xxx                     1/1     Running   0          2m
# harbor-trivy-xxx                        1/1     Running   0          2m
```

### 7.2 脆弱性スキャンの有効化

```bash
# Harbor UIでプロジェクト設定
# 1. プロジェクト作成: myproject
# 2. Configuration → Automatically scan images on push: ON
# 3. Configuration → Prevent vulnerable images from running: ON
# 4. Vulnerability severity: High, Critical

# イメージのプッシュ
docker tag myapp:1.0 harbor.example.com/myproject/myapp:1.0
docker push harbor.example.com/myproject/myapp:1.0

# 自動的にTrivyスキャンが実行される
# Harbor UIでスキャン結果を確認可能
```

### 7.3 イメージ署名の強制

```yaml
# harbor-notary-policy.yaml
# Harbor Notary を使用したイメージ署名検証
apiVersion: projectcontour.io/v1
kind: HTTPProxy
metadata:
  name: harbor-notary
  namespace: harbor
spec:
  virtualhost:
    fqdn: notary.harbor.example.com
  routes:
  - services:
    - name: harbor-notary-server
      port: 4443
```

```bash
# Notary を使った署名
export DOCKER_CONTENT_TRUST=1
export DOCKER_CONTENT_TRUST_SERVER=https://notary.harbor.example.com

docker push harbor.example.com/myproject/myapp:1.0
# Enter passphrase for root key with ID xxx:
# Enter passphrase for new repository key with ID yyy:
# Successfully signed harbor.example.com/myproject/myapp:1.0
```

## 8. SBOMとサプライチェーン管理

### 8.1 SBOMの生成

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

### 8.2 SBOMの管理

```yaml
# sbom-storage-job.yaml
apiVersion: batch/v1
kind: Job
metadata:
  name: sbom-generator
  namespace: ci-cd
spec:
  template:
    spec:
      containers:
      - name: syft
        image: anchore/syft:latest
        command:
        - /bin/sh
        - -c
        - |
          # 全イメージのSBOM生成
          for image in $(kubectl get pods --all-namespaces -o jsonpath='{.items[*].spec.containers[*].image}' | tr ' ' '\n' | sort -u); do
            echo "Generating SBOM for $image"
            syft $image -o cyclonedx-json > /sbom/${image//\//_}.json
          done
          
          # S3にアップロード
          aws s3 sync /sbom/ s3://my-sbom-bucket/$(date +%Y-%m-%d)/
        volumeMounts:
        - name: sbom
          mountPath: /sbom
      
      volumes:
      - name: sbom
        emptyDir: {}
      
      restartPolicy: Never
```

## 9. 継続的な脆弱性管理

### 9.1 定期スキャンの自動化

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
                  trivy image --severity HIGH,CRITICAL --format json --output /reports/${ns}_${image//\//_}.json $image
                done
              done
              
              # レポートをS3にアップロード
              aws s3 sync /reports/ s3://my-scan-reports/$(date +%Y-%m-%d)/
            volumeMounts:
            - name: reports
              mountPath: /reports
          
          volumes:
          - name: reports
            emptyDir: {}
          
          restartPolicy: OnFailure
```

### 9.2 アラートとレポート

```yaml
# vulnerability-alerts.yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: vulnerability-alerts
  namespace: monitoring
spec:
  groups:
  - name: vulnerability.rules
    interval: 1h
    rules:
    # Critical脆弱性の検出
    - alert: CriticalVulnerabilityDetected
      expr: |
        sum(trivy_vulnerability_count{severity="CRITICAL"}) > 0
      for: 5m
      labels:
        severity: critical
      annotations:
        summary: "Critical vulnerabilities detected in cluster"
        description: "{{ $value }} critical vulnerabilities found"
    
    # High脆弱性の増加
    - alert: HighVulnerabilityIncreased
      expr: |
        increase(trivy_vulnerability_count{severity="HIGH"}[24h]) > 5
      for: 1h
      labels:
        severity: warning
      annotations:
        summary: "High vulnerability count increased"
        description: "High vulnerabilities increased by {{ $value }} in 24h"
```

## まとめ

### 学んだこと

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
   - Notaryによる署名強制
   - SBOM管理

### ベストプラクティス

- 全イメージのスキャンをCI/CDで自動化
- CRITICAL/HIGH脆弱性は即座に対応
- イメージ署名を必須化
- latestタグの使用禁止
- プライベートレジストリの活用
- SBOMの継続的な管理
- 定期的な脆弱性レビュー

## 参考リンク

- {{< linkcard "https://aquasecurity.github.io/trivy/" >}}
- {{< linkcard "https://docs.sigstore.dev/cosign/overview/" >}}
- {{< linkcard "https://kyverno.io/docs/" >}}
- {{< linkcard "https://goharbor.io/" >}}
