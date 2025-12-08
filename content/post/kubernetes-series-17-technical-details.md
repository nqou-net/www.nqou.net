---
title: "NetworkPolicyでネットワーク隔離 - マイクロセグメンテーションの実装（技術詳細）"
draft: true
tags:
- kubernetes
- network-policy
- security
- cni
- microsegmentation
- zero-trust
description: "Kubernetes NetworkPolicyの完全ガイド。Ingress/Egressルールの詳細、マイクロセグメンテーション、CNIプラグインの選択まで実践的に解説。"
---

## はじめに

Kubernetesのデフォルト設定では、全てのPod間通信が許可されています。これは開発環境では便利ですが、本番環境ではセキュリティリスクとなります。NetworkPolicyを使うことで、Pod間のネットワーク通信を細かく制御し、ゼロトラストネットワークを実現できます。本記事では、NetworkPolicyの基本から実践的なマイクロセグメンテーションまで徹底解説します。

## 1. NetworkPolicyの基本概念

### 1.1 デフォルトの動作

```
Kubernetesのデフォルト（NetworkPolicyなし）:

┌─────────┐     ┌─────────┐     ┌─────────┐
│ Pod A   │────▶│ Pod B   │────▶│ Pod C   │
│         │◀────│         │◀────│         │
└─────────┘     └─────────┘     └─────────┘

✅ 全てのPod間通信が許可
✅ 全てのNamespace間通信が許可
✅ 外部からの通信も許可（Serviceを通じて）
⚠️  セキュリティリスクが高い
```

### 1.2 NetworkPolicy適用後

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

### 1.3 NetworkPolicyの構造

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

## 2. CNIプラグインとNetworkPolicy

### 2.1 NetworkPolicy対応CNI

| CNIプラグイン | NetworkPolicy対応 | 特徴 |
|------------|----------------|-----|
| **Calico** | ✅ Full | 高機能、GlobalNetworkPolicy、暗号化 |
| **Cilium** | ✅ Full | eBPF、L7ポリシー、可視化が優秀 |
| **Weave Net** | ✅ Full | シンプル、自動暗号化 |
| **Antrea** | ✅ Full | VMwareサポート、Traceflow |
| Flannel | ❌ 非対応 | シンプルだがNetworkPolicy不可 |
| kindnet | ❌ 非対応 | kind専用、NetworkPolicy不可 |

### 2.2 Calicoのインストール

```bash
# Calicoのインストール（マニフェスト方式）
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

# calicoctlのインストール
curl -L https://github.com/projectcalico/calico/releases/download/v3.27.0/calicoctl-linux-amd64 -o calicoctl
chmod +x calicoctl
sudo mv calicoctl /usr/local/bin/

# calicoctl動作確認
calicoctl get nodes
calicoctl get ippool
```

### 2.3 Ciliumのインストール

```bash
# Cilium CLIのインストール
CILIUM_CLI_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/cilium-cli/main/stable.txt)
curl -L --fail --remote-name-all https://github.com/cilium/cilium-cli/releases/download/${CILIUM_CLI_VERSION}/cilium-linux-amd64.tar.gz
sudo tar xzvfC cilium-linux-amd64.tar.gz /usr/local/bin

# Ciliumのインストール
cilium install --version 1.14.5

# インストール確認
cilium status --wait

# 出力例:
#     /¯¯\
#  /¯¯\__/¯¯\    Cilium:             OK
#  \__/¯¯\__/    Operator:           OK
#  /¯¯\__/¯¯\    Envoy DaemonSet:    disabled (using embedded mode)
#  \__/¯¯\__/    Hubble Relay:       disabled
#     \__/       ClusterMesh:        disabled

# Connectivity test
cilium connectivity test
```

## 3. Ingressルール（受信制御）

### 3.1 基本的なIngressルール

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

### 3.2 複数ソースからのIngress

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

### 3.3 Namespace単位のIngress制御

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

### 3.4 IPブロック（CIDR）によるIngress制御

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

## 4. Egressルール（送信制御）

### 4.1 基本的なEgressルール

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

### 4.2 外部APIへのEgress制御

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
  
  # 決済API（Stripe）への通信を許可
  - to:
    - ipBlock:
        cidr: 0.0.0.0/0  # 全てのIPを許可
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

### 4.3 特定ドメインへのEgress（Cilium拡張）

```yaml
# cilium-fqdn-policy.yaml
apiVersion: cilium.io/v2
kind: CiliumNetworkPolicy
metadata:
  name: allow-specific-domains
  namespace: production
spec:
  endpointSelector:
    matchLabels:
      app: backend
  egress:
  # 特定FQDNへのHTTPSのみ許可
  - toFQDNs:
    - matchName: "api.stripe.com"
    - matchPattern: "*.amazonaws.com"
  - toPorts:
    - ports:
      - port: "443"
        protocol: TCP
  
  # DNS解決を許可
  - toEndpoints:
    - matchLabels:
        k8s:io.kubernetes.pod.namespace: kube-system
        k8s-app: kube-dns
    toPorts:
    - ports:
      - port: "53"
        protocol: UDP
```

## 5. デフォルトポリシー

### 5.1 デフォルトDeny（全拒否）

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

**推奨パターン**: 各Namespaceでまずdefault-denyを作成し、その後必要な通信のみ許可

### 5.2 Ingress Denyのみ

```yaml
# default-deny-ingress.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-ingress
  namespace: production
spec:
  podSelector: {}
  policyTypes:
  - Ingress
# Ingressは全拒否、Egressは制限なし
```

### 5.3 Egress DNSのみ許可

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

## 6. マイクロセグメンテーション

### 6.1 3層アプリケーションの隔離

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

### 6.2 マイクロサービス間の通信制御

```yaml
# microservices-policies.yaml
---
# Order Service
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: order-service-policy
  namespace: production
spec:
  podSelector:
    matchLabels:
      app: order-service
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: api-gateway
    ports:
    - protocol: TCP
      port: 8080
  egress:
  # Payment ServiceとInventory Serviceのみ
  - to:
    - podSelector:
        matchLabels:
          app: payment-service
    ports:
    - protocol: TCP
      port: 8080
  - to:
    - podSelector:
        matchLabels:
          app: inventory-service
    ports:
    - protocol: TCP
      port: 8080
  # Database
  - to:
    - podSelector:
        matchLabels:
          app: postgres
    ports:
    - protocol: TCP
      port: 5432
  # DNS
  - to:
    - namespaceSelector: {}
      podSelector:
        matchLabels:
          k8s-app: kube-dns
    ports:
    - protocol: UDP
      port: 53

---
# Payment Service
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: payment-service-policy
  namespace: production
spec:
  podSelector:
    matchLabels:
      app: payment-service
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: order-service
    ports:
    - protocol: TCP
      port: 8080
  egress:
  # 外部決済API（Stripe）
  - to:
    - ipBlock:
        cidr: 0.0.0.0/0
    ports:
    - protocol: TCP
      port: 443
  # DNS
  - to:
    - namespaceSelector: {}
      podSelector:
        matchLabels:
          k8s-app: kube-dns
    ports:
    - protocol: UDP
      port: 53
```

## 7. NetworkPolicyのテストと検証

### 7.1 接続テスト用Pod

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

### 7.2 複数Podからの接続テスト

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

### 7.3 Ciliumの可視化機能

```bash
# Hubbleの有効化（Cilium使用時）
cilium hubble enable --ui

# Hubble UIへポートフォワード
cilium hubble ui

# ブラウザで http://localhost:12000 を開く

# CLIで通信を監視
hubble observe --namespace production

# 出力例:
# Dec  8 03:00:00.123: production/frontend-xxx -> production/backend-xxx (TCP:8080) FORWARDED
# Dec  8 03:00:01.456: production/untrusted-xxx -> production/backend-xxx (TCP:8080) DROPPED
```

## 8. 高度なNetworkPolicy（Calico拡張）

### 8.1 GlobalNetworkPolicy

```yaml
# global-default-deny.yaml
apiVersion: projectcalico.org/v3
kind: GlobalNetworkPolicy
metadata:
  name: global-default-deny
spec:
  order: 1000  # 低い値ほど優先度が高い
  selector: all()
  types:
  - Ingress
  - Egress
  # 全Namespaceで適用されるデフォルトDeny
```

### 8.2 階層化ポリシー（Tiered Policy）

```yaml
# tiered-security-policy.yaml
apiVersion: projectcalico.org/v3
kind: Tier
metadata:
  name: security
spec:
  order: 100  # 最優先
---
apiVersion: projectcalico.org/v3
kind: NetworkPolicy
metadata:
  name: block-malicious-ips
  namespace: production
spec:
  tier: security
  order: 10
  selector: all()
  types:
  - Ingress
  ingress:
  - action: Deny
    source:
      nets:
      - 192.0.2.0/24  # 既知の悪意あるIP
      - 203.0.113.0/24
```

### 8.3 L7ポリシー（Cilium拡張）

```yaml
# l7-http-policy.yaml
apiVersion: cilium.io/v2
kind: CiliumNetworkPolicy
metadata:
  name: l7-http-policy
  namespace: production
spec:
  endpointSelector:
    matchLabels:
      app: backend
  ingress:
  - fromEndpoints:
    - matchLabels:
        app: frontend
    toPorts:
    - ports:
      - port: "8080"
        protocol: TCP
      rules:
        http:
        # GETとPOSTのみ許可
        - method: "GET"
          path: "/api/.*"
        - method: "POST"
          path: "/api/orders"
        # DELETEは拒否
```

## 9. 運用ベストプラクティス

### 9.1 段階的な適用

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

### 9.2 NetworkPolicyの自動生成

```bash
# 既存の通信を観察してNetworkPolicyを生成
# （Ciliumのnetwork-policy-generator使用）
kubectl krew install cilium

# 通信を観察（1時間）
cilium hubble observe --namespace production --output json > traffic.json

# NetworkPolicyを生成
cilium-network-policy-generator \
  --input traffic.json \
  --output generated-policies/
```

### 9.3 継続的な監視

```yaml
# prometheus-networkpolicy-alerts.yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: networkpolicy-alerts
  namespace: monitoring
spec:
  groups:
  - name: networkpolicy.rules
    interval: 30s
    rules:
    # NetworkPolicyで拒否された通信が増加
    - alert: NetworkPolicyDenyIncreased
      expr: |
        rate(cilium_policy_verdict_total{verdict="deny"}[5m]) > 10
      for: 5m
      labels:
        severity: warning
      annotations:
        summary: "High rate of denied connections"
        description: "{{ $value }} connections/sec denied by NetworkPolicy"
```

## まとめ

### 学んだこと

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
- 可視化ツールの活用（Hubble UI）
- 段階的な適用（監視モード → 強制モード）

## 参考リンク

- {{< linkcard "https://kubernetes.io/docs/concepts/services-networking/network-policies/" >}}
- {{< linkcard "https://docs.tigera.io/calico/latest/about/" >}}
- {{< linkcard "https://cilium.io/get-started/" >}}
