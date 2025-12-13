---
title: "PodSecurityStandardsで安全なPod - コンテナセキュリティの実装（技術詳細）"
draft: true
tags:
- kubernetes
- security
- pod-security
- seccomp
- apparmor
- security-context
description: "Kubernetes PodSecurityStandardsの完全ガイド。Privileged/Baseline/Restrictedレベル、runAsNonRoot、seccomp、AppArmorまで実践的に解説。"
---

## はじめに

Podのセキュリティ設定は、Kubernetesクラスタ全体のセキュリティを左右する重要な要素です。適切なPodSecurityStandardsを適用することで、特権エスカレーション、コンテナ脱獄、ホストへの不正アクセスなどのリスクを大幅に削減できます。本記事では、PodSecurityStandardsの3つのレベルから、seccomp、AppArmorなどの高度なセキュリティ機能まで徹底解説します。

## 1. PodSecurityStandards (PSS) の概要

### 1.1 PodSecurityStandardsとは

**PodSecurityStandards (PSS)**: Podのセキュリティレベルを定義する標準仕様

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

### 1.2 PodSecurityAdmission

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

### 1.3 各レベルの比較

| 機能 | Privileged | Baseline | Restricted |
|-----|-----------|----------|------------|
| hostNetwork | ✅ 許可 | ❌ 禁止 | ❌ 禁止 |
| hostPID/hostIPC | ✅ 許可 | ❌ 禁止 | ❌ 禁止 |
| privileged | ✅ 許可 | ❌ 禁止 | ❌ 禁止 |
| capabilities (ALL) | ✅ 許可 | ❌ 禁止 | ❌ 禁止 |
| hostPath volumes | ✅ 許可 | ❌ 禁止 | ❌ 禁止 |
| hostPort | ✅ 許可 | ⚠️  制限 | ❌ 禁止 |
| runAsNonRoot | - | - | ✅ 必須 |
| seccomp | - | - | ✅ 必須 |
| allowPrivilegeEscalation | ✅ 許可 | ✅ 許可 | ❌ 禁止 |
| readOnlyRootFilesystem | - | - | ⚠️  推奨 |

## 2. Security Context の設定

### 2.1 Pod レベルの Security Context

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

### 2.2 Container レベルの Security Context

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

## 3. Privileged / Baseline / Restricted レベルの実装

### 3.1 Privileged レベル（制限なし）

```yaml
# privileged-pod.yaml
# ⚠️ システムコンテナ（DaemonSetなど）のみ使用
apiVersion: v1
kind: Pod
metadata:
  name: privileged-pod
  namespace: kube-system
spec:
  hostNetwork: true
  hostPID: true
  hostIPC: true
  
  containers:
  - name: privileged-container
    image: system-tool:1.0
    securityContext:
      privileged: true
      capabilities:
        add:
        - ALL
    volumeMounts:
    - name: host-root
      mountPath: /host
  
  volumes:
  - name: host-root
    hostPath:
      path: /
      type: Directory
```

**使用例**: CNI、CSI、監視エージェント、ログ収集など

### 3.2 Baseline レベル（基本的な制限）

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

### 3.3 Restricted レベル（最も厳格）

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

## 4. runAsNonRoot と readOnlyRootFilesystem

### 4.1 runAsNonRoot の実装

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

### 4.2 readOnlyRootFilesystem の実装

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

## 5. Seccomp（Secure Computing Mode）

### 5.1 Seccompプロファイルの種類

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

### 5.2 RuntimeDefault プロファイルの使用

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
- `acct`, `add_key`, `bpf`
- `clock_adjtime`, `clock_settime`
- `create_module`, `delete_module`
- `finit_module`, `init_module`
- `kcmp`, `kexec_file_load`, `kexec_load`
- `keyctl`, `lookup_dcookie`
- `mount`, `move_pages`
- `name_to_handle_at`, `open_by_handle_at`
- `perf_event_open`, `pivot_root`
- `process_vm_readv`, `process_vm_writev`
- `ptrace`, `reboot`
- `setns`, `settimeofday`
- `swapon`, `swapoff`
- `syslog`, `unshare`
- `uselib`, `userfaultfd`, `ustat`
- `vm86`, `vm86old`

### 5.3 カスタム Seccomp プロファイル

```json
// /var/lib/kubelet/seccomp/custom-profile.json
{
  "defaultAction": "SCMP_ACT_ERRNO",
  "defaultErrnoRet": 1,
  "architectures": [
    "SCMP_ARCH_X86_64",
    "SCMP_ARCH_X86",
    "SCMP_ARCH_X32"
  ],
  "syscalls": [
    {
      "names": [
        "accept",
        "accept4",
        "access",
        "arch_prctl",
        "bind",
        "brk",
        "capget",
        "capset",
        "chdir",
        "chmod",
        "chown",
        "clone",
        "close",
        "connect",
        "dup",
        "dup2",
        "dup3",
        "epoll_create",
        "epoll_create1",
        "epoll_ctl",
        "epoll_pwait",
        "epoll_wait",
        "execve",
        "exit",
        "exit_group",
        "fcntl",
        "fstat",
        "futex",
        "getcwd",
        "getdents",
        "getdents64",
        "getegid",
        "geteuid",
        "getgid",
        "getgroups",
        "getpeername",
        "getpgrp",
        "getpid",
        "getppid",
        "getrlimit",
        "getsockname",
        "getsockopt",
        "gettid",
        "getuid",
        "listen",
        "lseek",
        "madvise",
        "mkdir",
        "mmap",
        "mprotect",
        "munmap",
        "open",
        "openat",
        "pipe",
        "pipe2",
        "poll",
        "pread64",
        "pwrite64",
        "read",
        "recvfrom",
        "recvmsg",
        "rename",
        "rt_sigaction",
        "rt_sigprocmask",
        "rt_sigreturn",
        "sched_getaffinity",
        "sched_yield",
        "select",
        "sendmsg",
        "sendto",
        "set_robust_list",
        "set_tid_address",
        "setgid",
        "setsockopt",
        "setuid",
        "shutdown",
        "sigaltstack",
        "socket",
        "socketpair",
        "stat",
        "statfs",
        "tgkill",
        "uname",
        "unlink",
        "wait4",
        "write"
      ],
      "action": "SCMP_ACT_ALLOW"
    }
  ]
}
```

```yaml
# seccomp-custom-profile.yaml
apiVersion: v1
kind: Pod
metadata:
  name: custom-seccomp-pod
  namespace: production
spec:
  securityContext:
    seccompProfile:
      type: Localhost
      localhostProfile: custom-profile.json
  
  containers:
  - name: app
    image: myapp:1.0
```

## 6. AppArmor

### 6.1 AppArmor プロファイルの作成

```bash
# AppArmor プロファイルをNode上に配置
# /etc/apparmor.d/k8s-apparmor-example

#include <tunables/global>

profile k8s-apparmor-example flags=(attach_disconnected,mediate_deleted) {
  #include <abstractions/base>

  # ファイルアクセス制御
  /app/** r,
  /tmp/** rw,
  /var/log/** w,
  
  # ネットワークアクセス制御
  network inet tcp,
  network inet udp,
  
  # プロセス実行制御
  /usr/bin/node ix,
  /bin/sh ix,
  
  # 機能の拒否
  deny /proc/sys/** w,
  deny /sys/** w,
  deny capability sys_admin,
  deny capability sys_module,
}
```

```bash
# AppArmorプロファイルをロード
sudo apparmor_parser -r -W /etc/apparmor.d/k8s-apparmor-example

# プロファイルの確認
sudo aa-status | grep k8s-apparmor-example
```

### 6.2 Pod での AppArmor 使用

```yaml
# apparmor-pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: apparmor-pod
  namespace: production
  annotations:
    # AppArmorプロファイルを指定
    container.apparmor.security.beta.kubernetes.io/app: localhost/k8s-apparmor-example
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
        - ALL
```

```bash
# Podの作成
kubectl apply -f apparmor-pod.yaml

# AppArmorが適用されているか確認
kubectl exec apparmor-pod -n production -- cat /proc/self/attr/current
# k8s-apparmor-example (enforce)
```

## 7. Capabilities の制御

### 7.1 Linux Capabilities の一覧

主要なCapabilities:

| Capability | 説明 | 推奨 |
|-----------|------|-----|
| CAP_CHOWN | ファイル所有権の変更 | ❌ Drop |
| CAP_DAC_OVERRIDE | ファイル許可の上書き | ❌ Drop |
| CAP_FOWNER | ファイル所有者チェックのバイパス | ❌ Drop |
| CAP_FSETID | SetUID/SetGID ビット設定 | ❌ Drop |
| CAP_KILL | シグナル送信 | ❌ Drop |
| CAP_SETGID | GID変更 | ❌ Drop |
| CAP_SETUID | UID変更 | ❌ Drop |
| CAP_NET_BIND_SERVICE | 1024未満のポートバインド | ⚠️  必要なら許可 |
| CAP_NET_RAW | RAWソケット使用 | ❌ Drop |
| CAP_SYS_ADMIN | システム管理操作 | ❌ Drop |
| CAP_SYS_CHROOT | chroot実行 | ❌ Drop |
| CAP_SYS_MODULE | カーネルモジュールロード | ❌ Drop |
| CAP_SYS_PTRACE | プロセストレース | ❌ Drop |
| CAP_SYS_TIME | システム時刻変更 | ❌ Drop |

### 7.2 Capabilities のドロップ

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

### 7.3 特定 Capability の追加

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

## 8. PodSecurityPolicy から PodSecurityAdmission への移行

### 8.1 PodSecurityPolicy（非推奨）

```yaml
# ⚠️ Kubernetes 1.25で削除済み
# 参考として記載
apiVersion: policy/v1beta1
kind: PodSecurityPolicy
metadata:
  name: restricted-psp
spec:
  privileged: false
  allowPrivilegeEscalation: false
  requiredDropCapabilities:
  - ALL
  volumes:
  - configMap
  - emptyDir
  - projected
  - secret
  - downwardAPI
  - persistentVolumeClaim
  runAsUser:
    rule: MustRunAsNonRoot
  seLinux:
    rule: RunAsAny
  fsGroup:
    rule: RunAsAny
  readOnlyRootFilesystem: true
```

### 8.2 移行手順

```bash
# ステップ1: 現在のPodSecurityPolicyを確認
kubectl get psp

# ステップ2: Namespaceに対応するPodSecurityStandardsレベルを決定
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

## 9. セキュリティ検証と監視

### 9.1 Pod セキュリティスキャン

```bash
# kubescapeでセキュリティスキャン
curl -s https://raw.githubusercontent.com/kubescape/kubescape/master/install.sh | /bin/bash
kubescape scan framework nsa --exclude-namespaces kube-system

# trivyでイメージスキャン
trivy image myapp:1.0

# polaris でベストプラクティスチェック
kubectl apply -f https://github.com/FairwindsOps/polaris/releases/latest/download/dashboard.yaml
kubectl port-forward -n polaris svc/polaris-dashboard 8080:80
```

### 9.2 OPA Gatekeeper でポリシー強制

```yaml
# require-run-as-nonroot.yaml
apiVersion: templates.gatekeeper.sh/v1
kind: ConstraintTemplate
metadata:
  name: k8srequirerunasnonroot
spec:
  crd:
    spec:
      names:
        kind: K8sRequireRunAsNonRoot
  targets:
  - target: admission.k8s.gatekeeper.sh
    rego: |
      package k8srequirerunasnonroot
      
      violation[{"msg": msg}] {
        not input.review.object.spec.securityContext.runAsNonRoot
        msg := "Pod must set runAsNonRoot to true"
      }
      
      violation[{"msg": msg}] {
        container := input.review.object.spec.containers[_]
        not container.securityContext.runAsNonRoot
        msg := sprintf("Container %v must set runAsNonRoot to true", [container.name])
      }
---
apiVersion: constraints.gatekeeper.sh/v1beta1
kind: K8sRequireRunAsNonRoot
metadata:
  name: require-run-as-nonroot
spec:
  match:
    kinds:
    - apiGroups: [""]
      kinds: ["Pod"]
    namespaces:
    - production
```

## まとめ

### 学んだこと

1. **PodSecurityStandards**
   - Privileged/Baseline/Restrictedの3レベル
   - enforce/audit/warnの3モード
   - Namespaceラベルでの適用

2. **SecurityContext**
   - runAsNonRoot、readOnlyRootFilesystem
   - allowPrivilegeEscalation: false
   - Capabilities のドロップ

3. **高度なセキュリティ機能**
   - Seccomp: RuntimeDefault/カスタムプロファイル
   - AppArmor: プロセス単位のアクセス制御
   - Capabilities: 最小権限の原則

4. **移行と運用**
   - PodSecurityPolicyからPodSecurityAdmissionへ
   - セキュリティスキャンツールの活用
   - OPA Gatekeeperでポリシー強制

### ベストプラクティス

- 本番環境ではRestrictedレベルを推奨
- runAsNonRoot: trueは必須
- readOnlyRootFilesystem: trueで改ざん防止
- capabilities.drop: [ALL]で全ドロップ
- seccompProfile.type: RuntimeDefaultを設定
- 段階的適用（warn → audit → enforce）
- 継続的なセキュリティスキャン

## 参考リンク

- {{< linkcard "https://kubernetes.io/docs/concepts/security/pod-security-standards/" >}}
- {{< linkcard "https://kubernetes.io/docs/concepts/security/pod-security-admission/" >}}
- {{< linkcard "https://kubernetes.io/docs/tutorials/security/seccomp/" >}}
- {{< linkcard "https://kubernetes.io/docs/tutorials/security/apparmor/" >}}
