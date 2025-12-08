---
title: "Kubernetesを完全に理解した（第18回）- Pod Securityで安全なコンテナ"
draft: true
tags:
- kubernetes
- security
- pod-security
- container-security
- hardening
description: "コンテナ実行環境を強化し、攻撃者の権限昇格を防ぐ方法。セキュリティのベストプラクティスに準拠したPod設定を学びます。"
---

## はじめに - 第17回の振り返りと第18回で学ぶこと

前回の第17回では、NetworkPolicyによるネットワーク隔離について学びました。Ingress/Egressルールを使って、Pod間の通信を細かく制御し、マイクロセグメンテーションを実現する方法を理解できました。

今回の第18回では、**Pod Securityで安全なコンテナ** について学びます。適切なPod設定は、コンテナ脱獄、権限昇格、ホストへの不正アクセスなどのリスクを大幅に削減します。PodSecurityStandardsの3つのレベルから、SecurityContext、Seccomp、AppArmorまで実践的に解説します。

本記事で学ぶ内容：

- PodSecurityStandards（PSS）の3レベル
- SecurityContextの設定（Pod/Containerレベル）
- Privileged/Baseline/Restrictedレベルの実装
- runAsNonRootとreadOnlyRootFilesystem
- Seccomp（Secure Computing Mode）
- Linux Capabilitiesの制御

## PodSecurityStandards（PSS）の概要

### PodSecurityStandardsとは

**PodSecurityStandards（PSS）** は、Podのセキュリティレベルを定義する標準仕様です：

```
┌──────────────────────────────────────────┐
│     PodSecurityStandards の3レベル       │
├──────────────────────────────────────────┤
│ Privileged (特権)                        │
│ └─ 制限なし（デフォルト）                 │
│    - 全ての権限を許可                    │
│    - システムコンテナ向け                │
│                                          │
│ Baseline (基本)                          │
│ └─ 既知の特権エスカレーションを防止       │
│    - 危険な機能を制限                    │
│    - 一般的なアプリケーション向け         │
│                                          │
│ Restricted (制限)                        │
│ └─ セキュリティのベストプラクティス強制   │
│    - 最も厳格                            │
│    - セキュアなワークロード向け           │
└──────────────────────────────────────────┘
```

### PodSecurityAdmission

Namespaceにラベルを付けてPodSecurityStandardsを適用します：

```yaml
# namespace-pss-labels.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: production
  labels:
    # enforce: 違反したPodを拒否
    pod-security.kubernetes.io/enforce: restricted
    pod-security.kubernetes.io/enforce-version: v1.28
    
    # audit: 違反をログに記録（許可はする）
    pod-security.kubernetes.io/audit: restricted
    pod-security.kubernetes.io/audit-version: v1.28
    
    # warn: 違反を警告（許可はする）
    pod-security.kubernetes.io/warn: restricted
    pod-security.kubernetes.io/warn-version: v1.28
```

**3つのモード**:
- `enforce`: 違反したPodの作成を拒否
- `audit`: 監査ログに記録（作成は許可）
- `warn`: kubectl利用者に警告表示（作成は許可）

### 各レベルの比較

| 機能 | Privileged | Baseline | Restricted |
|-----|-----------|----------|------------|
| hostNetwork | ✅ 許可 | ❌ 禁止 | ❌ 禁止 |
| hostPID/hostIPC | ✅ 許可 | ❌ 禁止 | ❌ 禁止 |
| privileged | ✅ 許可 | ❌ 禁止 | ❌ 禁止 |
| hostPath volumes | ✅ 許可 | ❌ 禁止 | ❌ 禁止 |
| runAsNonRoot | - | - | ✅ 必須 |
| seccomp | - | - | ✅ 必須 |
| allowPrivilegeEscalation | ✅ 許可 | ✅ 許可 | ❌ 禁止 |

## SecurityContextの設定

### Podレベルの SecurityContext

```yaml
# pod-security-context.yaml
apiVersion: v1
kind: Pod
metadata:
  name: secure-pod
  namespace: production
spec:
  securityContext:
    # Podを非rootユーザーで実行することを強制
    runAsNonRoot: true
    runAsUser: 1000
    runAsGroup: 3000
    
    # 補助グループID
    supplementalGroups: [4000]
    
    # fsGroupで作成されるファイルのグループ所有権
    fsGroup: 2000
    
    # Seccompプロファイル
    seccompProfile:
      type: RuntimeDefault
  
  containers:
  - name: app
    image: myapp:1.0
    securityContext:
      # コンテナレベルで上書き可能
      allowPrivilegeEscalation: false
      capabilities:
        drop:
        - ALL
      readOnlyRootFilesystem: true
```

### Containerレベルの SecurityContext

マルチコンテナPodでは、各コンテナに異なるSecurityContextを設定できます：

```yaml
# container-security-context.yaml
apiVersion: v1
kind: Pod
metadata:
  name: multi-container-pod
  namespace: production
spec:
  securityContext:
    runAsNonRoot: true
    runAsUser: 1000
  
  containers:
  # アプリケーションコンテナ（最小権限）
  - name: app
    image: myapp:1.0
    securityContext:
      allowPrivilegeEscalation: false
      runAsNonRoot: true
      runAsUser: 1000
      capabilities:
        drop:
        - ALL
      readOnlyRootFilesystem: true
      seccompProfile:
        type: RuntimeDefault
    volumeMounts:
    - name: tmp
      mountPath: /tmp
    - name: cache
      mountPath: /app/cache
  
  # ログ転送サイドカー（読み取り専用）
  - name: log-forwarder
    image: fluent/fluent-bit:2.0
    securityContext:
      allowPrivilegeEscalation: false
      runAsNonRoot: true
      runAsUser: 2000
      capabilities:
        drop:
        - ALL
      readOnlyRootFilesystem: true
  
  volumes:
  - name: tmp
    emptyDir: {}
  - name: cache
    emptyDir: {}
```

## Baselineレベルの実装

**Baseline** レベルは、既知の特権エスカレーションを防止しつつ、一般的なアプリケーションを動作させられます：

```yaml
# baseline-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: baseline-app
  namespace: production
spec:
  replicas: 3
  selector:
    matchLabels:
      app: baseline-app
  template:
    metadata:
      labels:
        app: baseline-app
    spec:
      securityContext:
        runAsUser: 1000
        fsGroup: 2000
      
      containers:
      - name: app
        image: myapp:1.0
        securityContext:
          allowPrivilegeEscalation: false
          capabilities:
            drop:
            - ALL
            add:
            - NET_BIND_SERVICE  # ポート80/443のバインドのみ許可
        ports:
        - containerPort: 8080
```

**Baselineで許可される機能**:
- 非特権コンテナ（privileged: falseまたは未設定）
- 一部のcapabilitiesの追加（NET_BIND_SERVICEなど）
- allowPrivilegeEscalation: true（デフォルト）

## Restrictedレベルの実装

**Restricted** レベルは、最も厳格なセキュリティベストプラクティスを強制します：

```yaml
# restricted-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: restricted-app
  namespace: production
spec:
  replicas: 3
  selector:
    matchLabels:
      app: restricted-app
  template:
    metadata:
      labels:
        app: restricted-app
    spec:
      securityContext:
        runAsNonRoot: true
        runAsUser: 1000
        fsGroup: 2000
        seccompProfile:
          type: RuntimeDefault
      
      containers:
      - name: app
        image: myapp:1.0
        securityContext:
          allowPrivilegeEscalation: false
          runAsNonRoot: true
          capabilities:
            drop:
            - ALL
          readOnlyRootFilesystem: true
          seccompProfile:
            type: RuntimeDefault
        
        ports:
        - containerPort: 8080
        
        volumeMounts:
        - name: tmp
          mountPath: /tmp
        - name: cache
          mountPath: /app/cache
      
      volumes:
      - name: tmp
        emptyDir: {}
      - name: cache
        emptyDir: {}
```

**Restrictedで必須の設定**:
- `runAsNonRoot: true`
- `allowPrivilegeEscalation: false`
- `capabilities.drop: [ALL]`
- `seccompProfile.type: RuntimeDefault` または `Localhost`

## runAsNonRootとreadOnlyRootFilesystem

### runAsNonRootの実装

非rootユーザーでコンテナを実行することで、攻撃者が権限昇格を試みても影響を最小化できます：

```yaml
# run-as-non-root.yaml
apiVersion: v1
kind: Pod
metadata:
  name: non-root-pod
  namespace: production
spec:
  securityContext:
    runAsNonRoot: true  # Podレベルで強制
    runAsUser: 1000     # UID 1000で実行
    runAsGroup: 3000    # GID 3000で実行
  
  containers:
  - name: app
    image: myapp:1.0
    securityContext:
      runAsNonRoot: true  # コンテナレベルでも明示
```

**Dockerfileでの対応**:
```dockerfile
FROM node:18-alpine

# 非rootユーザーを作成
RUN addgroup -g 1000 appgroup && \
    adduser -D -u 1000 -G appgroup appuser

# アプリケーションファイルをコピー
WORKDIR /app
COPY --chown=appuser:appgroup . .

# 依存関係のインストール
RUN npm ci --only=production

# 非rootユーザーに切り替え
USER appuser

# アプリケーション起動
CMD ["node", "server.js"]
```

### readOnlyRootFilesystemの実装

ルートファイルシステムを読み取り専用にすることで、マルウェアの永続化を防ぎます：

```yaml
# readonly-root-fs.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: readonly-app
  namespace: production
spec:
  replicas: 3
  selector:
    matchLabels:
      app: readonly-app
  template:
    metadata:
      labels:
        app: readonly-app
    spec:
      securityContext:
        runAsNonRoot: true
        runAsUser: 1000
        fsGroup: 2000
      
      containers:
      - name: app
        image: myapp:1.0
        securityContext:
          readOnlyRootFilesystem: true  # ルートFSを読み取り専用に
          allowPrivilegeEscalation: false
          capabilities:
            drop:
            - ALL
        
        # 書き込みが必要なディレクトリはemptyDirをマウント
        volumeMounts:
        - name: tmp
          mountPath: /tmp
        - name: var-cache
          mountPath: /var/cache
        - name: var-log
          mountPath: /var/log
      
      volumes:
      - name: tmp
        emptyDir: {}
      - name: var-cache
        emptyDir: {}
      - name: var-log
        emptyDir: {}
```

**メリット**:
- マルウェアの永続化を防止
- コンテナイメージの改ざんを防止
- 攻撃者の活動を制限

## Seccomp（Secure Computing Mode）

### Seccompプロファイルの種類

```
Seccompプロファイルの種類:

1. Unconfined（制限なし）
   └─ 全てのシステムコールを許可（デフォルト）

2. RuntimeDefault
   └─ ランタイム（containerd/CRI-O）のデフォルトプロファイル
   └─ 危険なシステムコールをブロック

3. Localhost
   └─ カスタムプロファイルをNode上に配置
   └─ 最も細かい制御が可能
```

### RuntimeDefaultプロファイルの使用

```yaml
# seccomp-runtime-default.yaml
apiVersion: v1
kind: Pod
metadata:
  name: seccomp-pod
  namespace: production
spec:
  securityContext:
    seccompProfile:
      type: RuntimeDefault  # ランタイムのデフォルトプロファイル
  
  containers:
  - name: app
    image: myapp:1.0
    securityContext:
      allowPrivilegeEscalation: false
      capabilities:
        drop:
        - ALL
```

**RuntimeDefaultでブロックされる主なシステムコール**:
- `mount`, `reboot`, `swapon`, `swapoff`
- `create_module`, `delete_module`, `init_module`
- `kexec_load`, `kexec_file_load`
- `ptrace`, `setns`, `unshare`
- その他多数の危険なシステムコール

## Linux Capabilitiesの制御

### Capabilitiesの一覧

主要なLinux Capabilities:

| Capability | 説明 | 推奨 |
|-----------|------|-----|
| CAP_CHOWN | ファイル所有権の変更 | ❌ Drop |
| CAP_DAC_OVERRIDE | ファイル許可の上書き | ❌ Drop |
| CAP_FOWNER | ファイル所有者チェックのバイパス | ❌ Drop |
| CAP_SETUID | UID変更 | ❌ Drop |
| CAP_SETGID | GID変更 | ❌ Drop |
| CAP_NET_BIND_SERVICE | 1024未満のポートバインド | ⚠️  必要なら許可 |
| CAP_NET_RAW | RAWソケット使用 | ❌ Drop |
| CAP_SYS_ADMIN | システム管理操作 | ❌ Drop |
| CAP_SYS_MODULE | カーネルモジュールロード | ❌ Drop |
| CAP_SYS_PTRACE | プロセストレース | ❌ Drop |

### Capabilitiesのドロップ

全てのCapabilityをドロップすることを推奨：

```yaml
# drop-capabilities.yaml
apiVersion: v1
kind: Pod
metadata:
  name: drop-caps-pod
  namespace: production
spec:
  securityContext:
    runAsNonRoot: true
    runAsUser: 1000
  
  containers:
  - name: app
    image: myapp:1.0
    securityContext:
      allowPrivilegeEscalation: false
      capabilities:
        drop:
        - ALL  # 全てのCapabilityをドロップ
```

### 特定Capabilityの追加

ポート80/443をバインドする必要がある場合のみ、NET_BIND_SERVICEを追加：

```yaml
# add-net-bind-service.yaml
apiVersion: v1
kind: Pod
metadata:
  name: web-server
  namespace: production
spec:
  securityContext:
    runAsNonRoot: true
    runAsUser: 1000
  
  containers:
  - name: nginx
    image: nginx:alpine
    securityContext:
      allowPrivilegeEscalation: false
      capabilities:
        drop:
        - ALL
        add:
        - NET_BIND_SERVICE  # ポート80/443をバインドするため
    ports:
    - containerPort: 80
    - containerPort: 443
```

## PodSecurityPolicyからの移行

Kubernetes 1.25でPodSecurityPolicyは削除されました。PodSecurityAdmissionへの移行手順：

```bash
# ステップ1: 現在のPodSecurityPolicyを確認
kubectl get psp

# ステップ2: Namespaceに対応するレベルを決定
# - システムNamespace → privileged
# - 一般アプリケーション → baseline
# - セキュアなワークロード → restricted

# ステップ3: まず warn と audit モードで適用
kubectl label namespace production \
  pod-security.kubernetes.io/warn=restricted \
  pod-security.kubernetes.io/audit=restricted

# ステップ4: 違反を確認・修正
kubectl get events -n production | grep "violates PodSecurity"

# ステップ5: enforce モードに切り替え
kubectl label namespace production \
  pod-security.kubernetes.io/enforce=restricted \
  --overwrite
```

## まとめ

### 今回（第18回）学んだこと

1. **PodSecurityStandards**
   - Privileged/Baseline/Restrictedの3レベル
   - enforce/audit/warnの3モード
   - Namespaceラベルでの適用

2. **SecurityContext**
   - runAsNonRoot、readOnlyRootFilesystem
   - allowPrivilegeEscalation: false
   - Capabilitiesのドロップ

3. **高度なセキュリティ機能**
   - Seccomp: RuntimeDefault/カスタムプロファイル
   - Linux Capabilities: 最小権限の原則

4. **移行と運用**
   - PodSecurityPolicyからPodSecurityAdmissionへ
   - 段階的適用（warn → audit → enforce）

### ベストプラクティス

- 本番環境ではRestrictedレベルを推奨
- runAsNonRoot: trueは必須
- readOnlyRootFilesystem: trueで改ざん防止
- capabilities.drop: [ALL]で全ドロップ
- seccompProfile.type: RuntimeDefaultを設定
- 段階的適用（warn → audit → enforce）

### 次回予告

次回の第19回では、**イメージスキャンとサプライチェーンセキュリティ** について学びます。コンテナイメージに潜む脆弱性を検出し、信頼できるイメージのみをデプロイする仕組みを構築します。Trivyによる脆弱性スキャン、イメージ署名と検証、AdmissionWebhookによる安全なイメージ運用を実践しましょう！
