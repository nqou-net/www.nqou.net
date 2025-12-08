---
title: "Kubernetesを完全に理解した（第17回）- NetworkPolicyでネットワーク隔離"
draft: true
tags:
- kubernetes
- network-policy
- security
- networking
- segmentation
description: "ネットワークレベルでのセキュリティを強化する方法。必要な通信だけを許可し、侵害の横展開を防ぐ対策を実装します。"
---

## はじめに - 第16回の振り返りと第17回で学ぶこと

前回の第16回では、RBACによるアクセス制御について学びました。Role、RoleBinding、ServiceAccountを使って、誰が何をできるかを細かく制御する方法を理解できました。

今回の第17回では、**NetworkPolicyによるネットワーク隔離** について学びます。Kubernetesのデフォルト設定では全てのPod間通信が許可されていますが、これはセキュリティリスクとなります。NetworkPolicyを使ってネットワークレベルでのセキュリティを強化し、マイクロセグメンテーションを実現する方法を実践します。

本記事で学ぶ内容：

- NetworkPolicyの基本概念とデフォルト動作
- CNIプラグイン（Calico、Cilium）の選択
- Ingressルール（受信制御）の実装
- Egressルール（送信制御）の実装
- デフォルトDenyポリシーの重要性
- 3層アプリケーションのマイクロセグメンテーション

## NetworkPolicyの基本概念

### デフォルトの動作

Kubernetesのデフォルト設定では、**全てのPod間通信が許可** されています：

```
デフォルト（NetworkPolicyなし）:

┌─────────┐     ┌─────────┐     ┌─────────┐
│ Pod A   │────▶│ Pod B   │────▶│ Pod C   │
│         │◀────│         │◀────│         │
└─────────┘     └─────────┘     └─────────┘

✅ 全てのPod間通信が許可
✅ 全てのNamespace間通信が許可
✅ 外部からの通信も許可（Serviceを通じて）
⚠️  セキュリティリスクが高い
```

### NetworkPolicy適用後

NetworkPolicyを適用すると、明示的に許可された通信のみが可能になります：

```
NetworkPolicy適用後:

┌─────────┐     ┌─────────┐     ┌─────────┐
│ Pod A   │  ✅ │ Pod B   │  ❌ │ Pod C   │
│         │────▶│         │  X  │         │
└─────────┘     └─────────┘     └─────────┘

✅ 許可された通信のみ可能
❌ 明示的に許可されていない通信はブロック
🔒 マイクロセグメンテーション
```

### NetworkPolicyの構造

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: example-policy
  namespace: production
spec:
  podSelector:        # どのPodに適用するか
    matchLabels:
      app: myapp
  
  policyTypes:        # ポリシーの種類
  - Ingress          # 受信ルール
  - Egress           # 送信ルール
  
  ingress:           # 受信を許可する通信
  - from:
    - podSelector:
        matchLabels:
          role: frontend
    ports:
    - protocol: TCP
      port: 8080
  
  egress:            # 送信を許可する通信
  - to:
    - podSelector:
        matchLabels:
          role: database
    ports:
    - protocol: TCP
      port: 5432
```

## CNIプラグインとNetworkPolicy

### NetworkPolicy対応CNI

NetworkPolicyを使うには、対応したCNIプラグインが必要です：

| CNIプラグイン | NetworkPolicy対応 | 特徴 |
|------------|----------------|-----|
| **Calico** | ✅ Full | 高機能、GlobalNetworkPolicy、暗号化 |
| **Cilium** | ✅ Full | eBPF、L7ポリシー、可視化が優秀 |
| **Weave Net** | ✅ Full | シンプル、自動暗号化 |
| Flannel | ❌ 非対応 | シンプルだがNetworkPolicy不可 |

### Calicoのインストール

```bash
# Calicoのインストール
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.27.0/manifests/calico.yaml

# Podの確認
kubectl get pods -n kube-system | grep calico
# calico-kube-controllers-xxx   1/1     Running   0          1m
# calico-node-xxx               1/1     Running   0          1m
# calico-node-yyy               1/1     Running   0          1m

# Calicoの状態確認
kubectl get nodes -o wide
# NAME       STATUS   ROLES    CNI
# worker-1   Ready    <none>   calico
# worker-2   Ready    <none>   calico
```

## Ingressルール（受信制御）

### 基本的なIngressルール

フロントエンドからバックエンドへの通信を許可する例：

```yaml
# allow-from-frontend.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-from-frontend
  namespace: production
spec:
  podSelector:
    matchLabels:
      app: backend
      tier: api
  policyTypes:
  - Ingress
  ingress:
  # frontendからのHTTP通信を許可
  - from:
    - podSelector:
        matchLabels:
          app: frontend
    ports:
    - protocol: TCP
      port: 8080
```

適用と確認：

```bash
# 適用
kubectl apply -f allow-from-frontend.yaml

# 確認
kubectl get networkpolicy -n production
# NAME                  POD-SELECTOR        AGE
# allow-from-frontend   app=backend         10s

# 詳細確認
kubectl describe networkpolicy allow-from-frontend -n production
```

### 複数ソースからのIngress

データベースへの複数のアクセス元を許可する例：

```yaml
# allow-multiple-sources.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-multiple-sources
  namespace: production
spec:
  podSelector:
    matchLabels:
      app: database
  policyTypes:
  - Ingress
  ingress:
  # 同じNamespace内のbackendから
  - from:
    - podSelector:
        matchLabels:
          app: backend
    ports:
    - protocol: TCP
      port: 5432
  
  # monitoring NamespaceのPrometheusから
  - from:
    - namespaceSelector:
        matchLabels:
          name: monitoring
      podSelector:
        matchLabels:
          app: prometheus
    ports:
    - protocol: TCP
      port: 9187  # PostgreSQL exporter
```

### Namespace単位のIngress制御

特定のNamespaceからの全通信を許可：

```yaml
# allow-from-namespace.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-from-trusted-namespaces
  namespace: production
spec:
  podSelector: {}  # Namespace内の全Pod
  policyTypes:
  - Ingress
  ingress:
  # staging Namespaceから全て許可
  - from:
    - namespaceSelector:
        matchLabels:
          env: staging
  
  # development Namespaceからも許可
  - from:
    - namespaceSelector:
        matchLabels:
          env: development
```

### IPブロック（CIDR）によるIngress制御

特定のIPアドレスからのアクセスのみ許可：

```yaml
# allow-from-office.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-from-office
  namespace: production
spec:
  podSelector:
    matchLabels:
      app: admin-panel
  policyTypes:
  - Ingress
  ingress:
  # オフィスのIPアドレスからのみ許可
  - from:
    - ipBlock:
        cidr: 203.0.113.0/24  # オフィスのCIDR
        except:
        - 203.0.113.100/32    # 除外するIP
    ports:
    - protocol: TCP
      port: 443
```

## Egressルール（送信制御）

### 基本的なEgressルール

バックエンドからデータベースへの送信を許可：

```yaml
# allow-egress-to-db.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-egress-to-db
  namespace: production
spec:
  podSelector:
    matchLabels:
      app: backend
  policyTypes:
  - Egress
  egress:
  # データベースへの送信を許可
  - to:
    - podSelector:
        matchLabels:
          app: postgres
    ports:
    - protocol: TCP
      port: 5432
  
  # DNS解決を許可（重要！）
  - to:
    - namespaceSelector:
        matchLabels:
          name: kube-system
      podSelector:
        matchLabels:
          k8s-app: kube-dns
    ports:
    - protocol: UDP
      port: 53
```

**重要**: EgressルールでDNS解決を忘れると名前解決ができなくなります！

### 外部APIへのEgress制御

外部サービス（決済API等）への通信を許可：

```yaml
# allow-external-api.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-external-api
  namespace: production
spec:
  podSelector:
    matchLabels:
      app: payment-service
  policyTypes:
  - Egress
  egress:
  # DNS解決を許可
  - to:
    - namespaceSelector: {}
      podSelector:
        matchLabels:
          k8s-app: kube-dns
    ports:
    - protocol: UDP
      port: 53
  
  # HTTPSへの通信を許可
  - to:
    - ipBlock:
        cidr: 0.0.0.0/0
    ports:
    - protocol: TCP
      port: 443
  
  # HTTPも許可（リダイレクト用）
  - to:
    - ipBlock:
        cidr: 0.0.0.0/0
    ports:
    - protocol: TCP
      port: 80
```

## デフォルトポリシー

### デフォルトDeny（全拒否）

セキュリティのベストプラクティスとして、まずデフォルトDenyを適用します：

```yaml
# default-deny-all.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
  namespace: production
spec:
  podSelector: {}  # 全Podに適用
  policyTypes:
  - Ingress
  - Egress
# ingressもegressも定義しない = 全て拒否
```

**推奨パターン**: 
1. まず各Namespaceでdefault-denyを作成
2. その後、必要な通信のみ許可するポリシーを追加

### Egress DNSのみ許可

DNS解決だけは全Podに許可する便利なパターン：

```yaml
# default-allow-dns.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-allow-dns
  namespace: production
spec:
  podSelector: {}
  policyTypes:
  - Egress
  egress:
  # DNS解決のみ許可
  - to:
    - namespaceSelector:
        matchLabels:
          name: kube-system
    ports:
    - protocol: UDP
      port: 53
```

## マイクロセグメンテーション

### 3層アプリケーションの隔離

フロントエンド、バックエンド、データベースを完全に隔離する実践例：

```yaml
# three-tier-app-policies.yaml
---
# Frontend: Ingressからのみアクセス許可
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: frontend-policy
  namespace: production
spec:
  podSelector:
    matchLabels:
      tier: frontend
  policyTypes:
  - Ingress
  - Egress
  ingress:
  # Ingress Controllerからのみ
  - from:
    - namespaceSelector:
        matchLabels:
          name: ingress-nginx
    ports:
    - protocol: TCP
      port: 80
  egress:
  # BackendとDNSのみ
  - to:
    - podSelector:
        matchLabels:
          tier: backend
    ports:
    - protocol: TCP
      port: 8080
  - to:
    - namespaceSelector: {}
      podSelector:
        matchLabels:
          k8s-app: kube-dns
    ports:
    - protocol: UDP
      port: 53

---
# Backend: Frontendからのみアクセス許可
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: backend-policy
  namespace: production
spec:
  podSelector:
    matchLabels:
      tier: backend
  policyTypes:
  - Ingress
  - Egress
  ingress:
  # Frontendからのみ
  - from:
    - podSelector:
        matchLabels:
          tier: frontend
    ports:
    - protocol: TCP
      port: 8080
  egress:
  # DatabaseとDNSのみ
  - to:
    - podSelector:
        matchLabels:
          tier: database
    ports:
    - protocol: TCP
      port: 5432
  - to:
    - namespaceSelector: {}
      podSelector:
        matchLabels:
          k8s-app: kube-dns
    ports:
    - protocol: UDP
      port: 53

---
# Database: Backendからのみアクセス許可
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: database-policy
  namespace: production
spec:
  podSelector:
    matchLabels:
      tier: database
  policyTypes:
  - Ingress
  - Egress
  ingress:
  # Backendからのみ
  - from:
    - podSelector:
        matchLabels:
          tier: backend
    ports:
    - protocol: TCP
      port: 5432
  egress:
  # 外部通信なし（完全隔離）
  - to:
    - namespaceSelector: {}
      podSelector:
        matchLabels:
          k8s-app: kube-dns
    ports:
    - protocol: UDP
      port: 53
```

## NetworkPolicyのテストと検証

### 接続テスト用Pod

NetworkPolicyが正しく動作しているか確認：

```bash
# テスト用Podを起動
kubectl run test-pod \
  --image=nicolaka/netshoot \
  --rm -it \
  -n production \
  -- /bin/bash

# Pod内で接続テスト
# 成功する通信
curl http://allowed-service:8080
# HTTP/1.1 200 OK

# ブロックされる通信
curl http://blocked-service:8080 --max-time 5
# curl: (28) Connection timed out
```

### 複数Podからの接続テスト

異なるラベルを持つPodで接続をテスト：

```yaml
# network-test-pods.yaml
apiVersion: v1
kind: Pod
metadata:
  name: allowed-client
  namespace: production
  labels:
    role: frontend
spec:
  containers:
  - name: netshoot
    image: nicolaka/netshoot
    command: ["sleep", "3600"]
---
apiVersion: v1
kind: Pod
metadata:
  name: denied-client
  namespace: production
  labels:
    role: untrusted
spec:
  containers:
  - name: netshoot
    image: nicolaka/netshoot
    command: ["sleep", "3600"]
```

```bash
# テスト実行
kubectl apply -f network-test-pods.yaml

# 許可されたPodからテスト
kubectl exec -it allowed-client -n production -- curl http://backend:8080
# 成功

# 拒否されるPodからテスト
kubectl exec -it denied-client -n production -- curl http://backend:8080 --max-time 5
# タイムアウト
```

## 運用ベストプラクティス

### 段階的な適用

```bash
# ステップ1: まず監視モード（ログのみ）で動作確認
# Ciliumの場合
kubectl annotate pod myapp-pod policy.cilium.io/mode=audit -n production

# ステップ2: default-denyを適用
kubectl apply -f default-deny-all.yaml

# ステップ3: 必要な通信を一つずつ許可
kubectl apply -f allow-frontend-to-backend.yaml
kubectl apply -f allow-backend-to-db.yaml

# ステップ4: 検証
# 各Podからの通信をテスト

# ステップ5: 監視モードを解除
kubectl annotate pod myapp-pod policy.cilium.io/mode- -n production
```

## まとめ

### 今回（第17回）学んだこと

1. **NetworkPolicyの基本**
   - podSelector、namespaceSelector、ipBlock
   - Ingress/Egressルール
   - デフォルトDenyの重要性

2. **CNIプラグイン**
   - Calico: GlobalNetworkPolicy、Tiered Policy
   - Cilium: L7ポリシー、FQDNフィルタリング、可視化

3. **マイクロセグメンテーション**
   - 3層アーキテクチャの隔離
   - マイクロサービス間制御
   - ゼロトラストネットワーク

4. **運用**
   - 段階的適用
   - テストと検証
   - 継続的監視

### ベストプラクティス

- まずdefault-denyで全拒否、必要な通信のみ許可
- DNS解決を忘れずに許可
- Namespaceごとにポリシーを分離
- ラベルを使った柔軟な制御
- 定期的なポリシーレビュー
- 段階的な適用（監視モード → 強制モード）

### 次回予告

次回の第18回では、**Pod Securityで安全なコンテナ** について学びます。コンテナ実行環境を強化し、攻撃者の権限昇格を防ぐ方法を実践します。PodSecurityStandards、SecurityContext、Seccomp、AppArmorなど、コンテナのセキュリティベストプラクティスを習得しましょう！
