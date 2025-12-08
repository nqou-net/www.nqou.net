---
title: "99.9999%を実現する完全構成 - シリーズ完結編（技術詳細）"
draft: true
tags:
- kubernetes
- high-availability
- six-nines
- multi-region
- sre
- production
description: "Kubernetesで99.9999%（シックスナイン）可用性を実現する完全ガイド。マルチリージョン+マルチAZ構成、SLO設定、コスト最適化、全25回シリーズの集大成。"
---

## はじめに

このシリーズの最終章では、これまでに学んだすべての技術を統合し、**99.9999%（シックスナイン）の可用性**を実現する完全なKubernetes構成を設計します。99.9999%は年間わずか**31.5秒**のダウンタイムしか許容しない、極めて高い可用性目標です。本記事では、マルチリージョン+マルチAZ構成、SLO設定、コスト最適化、パフォーマンスチューニング、そしてこの25回シリーズ全体の振り返りをお届けします。

## 1. 可用性の理解

### 1.1 可用性レベルとダウンタイム

```
可用性レベル別の許容ダウンタイム:

┌────────────┬───────────┬──────────┬──────────┬──────────┐
│ 可用性     │ 年間      │ 月間     │ 週間     │ 日次     │
├────────────┼───────────┼──────────┼──────────┼──────────┤
│ 90%        │ 36.5日    │ 72時間   │ 16.8時間 │ 2.4時間  │
│ 95%        │ 18.25日   │ 36時間   │ 8.4時間  │ 1.2時間  │
│ 99%        │ 3.65日    │ 7.2時間  │ 1.68時間 │ 14.4分   │
│ 99.9%      │ 8.76時間  │ 43.2分   │ 10.1分   │ 1.44分   │
│ 99.95%     │ 4.38時間  │ 21.6分   │ 5.04分   │ 43.2秒   │
│ 99.99%     │ 52.6分    │ 4.32分   │ 1.01分   │ 8.64秒   │
│ 99.999%    │ 5.26分    │ 25.9秒   │ 6.05秒   │ 0.86秒   │
│ 99.9999%   │ 31.5秒    │ 2.59秒   │ 0.605秒  │ 0.086秒  │ ← 目標
└────────────┴───────────┴──────────┴──────────┴──────────┘

99.9999%を達成するには:
✅ 単一障害点の完全排除
✅ 自動フェイルオーバー（秒単位）
✅ 複数リージョン・複数AZ構成
✅ カオスエンジニアリングによる継続的検証
✅ 完全自動化された運用
```

### 1.2 障害の種類と対策

```
障害レベル別の対策:

1. コンポーネント障害（Pod/Container）
   対策: Liveness/Readiness Probe、HPA、PDB
   復旧時間: 秒〜数十秒

2. ノード障害
   対策: マルチAZ配置、Node Auto-repair
   復旧時間: 数十秒〜数分

3. AZ障害
   対策: マルチAZ構成、TopologySpreadConstraints
   復旧時間: 数秒（自動）

4. リージョン障害
   対策: マルチリージョン構成、Global Load Balancing
   復旧時間: 数秒〜数十秒（自動フェイルオーバー）

5. クラウドプロバイダー障害
   対策: マルチクラウド構成（高コスト）
   復旧時間: 数分〜数十分

6. アプリケーションバグ
   対策: カナリアデプロイ、自動ロールバック
   復旧時間: 数秒〜数分
```

## 2. 完全アーキテクチャ設計

### 2.1 グローバルアーキテクチャ

```
99.9999%対応グローバル構成:

┌─────────────────────────────────────────────────────────────────────┐
│ Global Layer                                                        │
│ ┌─────────────────────────────────────────────────────────────────┐ │
│ │ Route 53 / Cloud DNS                                            │ │
│ │ - Geolocation Routing                                           │ │
│ │ - Health Checks (30秒間隔)                                       │ │
│ │ - Failover Policy (10秒以内)                                     │ │
│ └──────────────────┬──────────────────┬───────────────────────────┘ │
└────────────────────┼──────────────────┼─────────────────────────────┘
                     │                  │
        ┌────────────┴──────┐    ┌─────┴──────────┐
        │                   │    │                │
┌───────▼─────────┐  ┌──────▼────────┐  ┌────────▼────────┐
│ Region: Tokyo   │  │ Region: Ireland│  │ Region: Virginia│
│ ap-northeast-1  │  │ eu-west-1      │  │ us-east-1       │
├─────────────────┤  ├────────────────┤  ├─────────────────┤
│ ┌─────────────┐ │  │ ┌────────────┐ │  │ ┌─────────────┐ │
│ │  AZ: 1a     │ │  │ │  AZ: 1a    │ │  │ │  AZ: 1a     │ │
│ │  Nodes: 3   │ │  │ │  Nodes: 3  │ │  │ │  Nodes: 3   │ │
│ │  Pods: 5    │ │  │ │  Pods: 3   │ │  │ │  Pods: 4    │ │
│ └─────────────┘ │  │ └────────────┘ │  │ └─────────────┘ │
│ ┌─────────────┐ │  │ ┌────────────┐ │  │ ┌─────────────┐ │
│ │  AZ: 1c     │ │  │ │  AZ: 1b    │ │  │ │  AZ: 1b     │ │
│ │  Nodes: 3   │ │  │ │  Nodes: 3  │ │  │ │  Nodes: 3   │ │
│ │  Pods: 5    │ │  │ │  Pods: 3   │ │  │ │  Pods: 4    │ │
│ └─────────────┘ │  │ └────────────┘ │  │ └─────────────┘ │
│ ┌─────────────┐ │  │ ┌────────────┐ │  │ ┌─────────────┐ │
│ │  AZ: 1d     │ │  │ │  AZ: 1c    │ │  │ │  AZ: 1c     │ │
│ │  Nodes: 3   │ │  │ │  Nodes: 3  │ │  │ │  Nodes: 3   │ │
│ │  Pods: 5    │ │  │ │  Pods: 3   │ │  │ │  Pods: 4    │ │
│ └─────────────┘ │  │ └────────────┘ │  │ └─────────────┘ │
│                 │  │                │  │                 │
│ Total: 9 Nodes  │  │ Total: 9 Nodes │  │ Total: 9 Nodes  │
│ Total: 15 Pods  │  │ Total: 9 Pods  │  │ Total: 12 Pods  │
└─────────────────┘  └────────────────┘  └─────────────────┘
         │                   │                    │
         └───────────────────┼────────────────────┘
                             │
                    ┌────────▼────────┐
                    │ Data Layer      │
                    │ - RDS Multi-AZ  │
                    │ - Aurora Global │
                    │ - S3 CRR        │
                    │ - DynamoDB GT   │
                    └─────────────────┘

総リソース:
- 合計27ノード（各リージョン9ノード）
- 合計36 Pods（各リージョン最低9 Pods）
- 9つのAZ（各リージョン3 AZ）
- 3つのリージョン
```

### 2.2 完全マニフェスト（統合版）

```yaml
# production-complete-deployment.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app
  namespace: production
  labels:
    app: web
    tier: frontend
    criticality: high
  annotations:
    # GitOps管理
    argocd.argoproj.io/sync-wave: "2"
    # Fluxイメージ自動更新
    fluxcd.io/automated: "true"
spec:
  # レプリカ数（HPA管理）
  replicas: 15  # 各リージョンの初期値
  
  # 更新戦略
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 2
      maxUnavailable: 0  # ゼロダウンタイム
  
  # Revision履歴
  revisionHistoryLimit: 10
  
  selector:
    matchLabels:
      app: web
      tier: frontend
  
  template:
    metadata:
      labels:
        app: web
        tier: frontend
        version: v1.0.0
      annotations:
        # Prometheusメトリクス
        prometheus.io/scrape: "true"
        prometheus.io/port: "8080"
        prometheus.io/path: "/metrics"
        # Istio sidecar注入
        sidecar.istio.io/inject: "true"
    
    spec:
      # TopologySpreadConstraints（AZ分散）
      topologySpreadConstraints:
      # AZ間での均等分散（必須）
      - maxSkew: 1
        topologyKey: topology.kubernetes.io/zone
        whenUnsatisfiable: DoNotSchedule
        labelSelector:
          matchLabels:
            app: web
      
      # ノード間での分散（推奨）
      - maxSkew: 2
        topologyKey: kubernetes.io/hostname
        whenUnsatisfiable: ScheduleAnyway
        labelSelector:
          matchLabels:
            app: web
      
      # PodAntiAffinity（追加の分離）
      affinity:
        podAntiAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 100
            podAffinityTerm:
              labelSelector:
                matchLabels:
                  app: web
              topologyKey: kubernetes.io/hostname
        
        # Node Affinity（本番環境ノードのみ）
        nodeAffinity:
          requiredDuringSchedulingIgnoredDuringExecution:
            nodeSelectorTerms:
            - matchExpressions:
              - key: node-role.kubernetes.io/production
                operator: In
                values:
                - "true"
              - key: topology.kubernetes.io/zone
                operator: In
                values:
                - ap-northeast-1a
                - ap-northeast-1c
                - ap-northeast-1d
      
      # ServiceAccount（最小権限）
      serviceAccountName: web-app-sa
      automountServiceAccountToken: false
      
      # セキュリティコンテキスト
      securityContext:
        runAsNonRoot: true
        runAsUser: 1000
        fsGroup: 1000
        seccompProfile:
          type: RuntimeDefault
      
      # init Container（起動前チェック）
      initContainers:
      - name: wait-for-dependencies
        image: busybox:1.36
        command:
        - sh
        - -c
        - |
          echo "Waiting for dependencies..."
          until nc -z database-service 5432; do
            echo "Waiting for database..."
            sleep 2
          done
          until nc -z redis-service 6379; do
            echo "Waiting for Redis..."
            sleep 2
          done
          echo "Dependencies ready"
        securityContext:
          allowPrivilegeEscalation: false
          runAsNonRoot: true
          runAsUser: 1000
          capabilities:
            drop:
            - ALL
      
      containers:
      - name: web
        image: myregistry/web-app:1.0.0
        imagePullPolicy: IfNotPresent
        
        ports:
        - name: http
          containerPort: 8080
          protocol: TCP
        - name: metrics
          containerPort: 9090
          protocol: TCP
        
        # 環境変数
        env:
        - name: PORT
          value: "8080"
        - name: ENVIRONMENT
          value: "production"
        - name: LOG_LEVEL
          value: "info"
        - name: REGION
          valueFrom:
            fieldRef:
              fieldPath: metadata.labels['topology.kubernetes.io/region']
        - name: POD_NAME
          valueFrom:
            fieldRef:
              fieldPath: metadata.name
        - name: POD_NAMESPACE
          valueFrom:
            fieldRef:
              fieldPath: metadata.namespace
        - name: NODE_NAME
          valueFrom:
            fieldRef:
              fieldPath: spec.nodeName
        
        # Secretからの環境変数
        envFrom:
        - secretRef:
            name: app-secrets
        - configMapRef:
            name: app-config
        
        # リソース設定（保証と制限）
        resources:
          requests:
            cpu: 500m
            memory: 512Mi
            ephemeral-storage: 1Gi
          limits:
            cpu: 2000m
            memory: 2Gi
            ephemeral-storage: 2Gi
        
        # Liveness Probe（プロセス生存確認）
        livenessProbe:
          httpGet:
            path: /healthz
            port: http
            httpHeaders:
            - name: X-Health-Check
              value: liveness
          initialDelaySeconds: 30
          periodSeconds: 10
          timeoutSeconds: 5
          successThreshold: 1
          failureThreshold: 3
        
        # Readiness Probe（トラフィック受信準備確認）
        readinessProbe:
          httpGet:
            path: /ready
            port: http
            httpHeaders:
            - name: X-Health-Check
              value: readiness
          initialDelaySeconds: 5
          periodSeconds: 5
          timeoutSeconds: 3
          successThreshold: 1
          failureThreshold: 2
        
        # Startup Probe（起動時の猶予）
        startupProbe:
          httpGet:
            path: /startup
            port: http
          initialDelaySeconds: 0
          periodSeconds: 5
          timeoutSeconds: 3
          successThreshold: 1
          failureThreshold: 30  # 最大150秒（5秒 × 30回）
        
        # ライフサイクルフック
        lifecycle:
          preStop:
            exec:
              command:
              - /bin/sh
              - -c
              - |
                # Graceful Shutdown
                echo "Received SIGTERM, sleeping for 10s to drain connections..."
                sleep 10
        
        # セキュリティコンテキスト
        securityContext:
          allowPrivilegeEscalation: false
          readOnlyRootFilesystem: true
          runAsNonRoot: true
          runAsUser: 1000
          capabilities:
            drop:
            - ALL
        
        # ボリュームマウント
        volumeMounts:
        - name: tmp
          mountPath: /tmp
        - name: cache
          mountPath: /app/cache
        - name: config
          mountPath: /app/config
          readOnly: true
        - name: secrets
          mountPath: /app/secrets
          readOnly: true
      
      # 終了猶予期間
      terminationGracePeriodSeconds: 30
      
      # DNS設定
      dnsPolicy: ClusterFirst
      dnsConfig:
        options:
        - name: ndots
          value: "1"
        - name: timeout
          value: "2"
        - name: attempts
          value: "2"
      
      # ボリューム
      volumes:
      - name: tmp
        emptyDir:
          sizeLimit: 1Gi
      - name: cache
        emptyDir:
          sizeLimit: 2Gi
      - name: config
        configMap:
          name: app-config
          defaultMode: 0444
      - name: secrets
        secret:
          secretName: app-secrets
          defaultMode: 0400
---
# HorizontalPodAutoscaler（自動スケーリング）
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: web-app-hpa
  namespace: production
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: web-app
  
  minReplicas: 15  # 最低15 Pods（各AZに5つ）
  maxReplicas: 60  # 最大60 Pods（スパイク対応）
  
  metrics:
  # CPU使用率ベース
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  
  # メモリ使用率ベース
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
  
  # カスタムメトリクス（リクエスト数）
  - type: Pods
    pods:
      metric:
        name: http_requests_per_second
      target:
        type: AverageValue
        averageValue: "1000"
  
  # スケーリング挙動
  behavior:
    scaleDown:
      stabilizationWindowSeconds: 300  # 5分間の安定化
      policies:
      - type: Percent
        value: 10
        periodSeconds: 60
      - type: Pods
        value: 2
        periodSeconds: 60
      selectPolicy: Min
    scaleUp:
      stabilizationWindowSeconds: 0  # 即座にスケールアップ
      policies:
      - type: Percent
        value: 50
        periodSeconds: 15
      - type: Pods
        value: 5
        periodSeconds: 15
      selectPolicy: Max
---
# PodDisruptionBudget（停止数制限）
apiVersion: policy/v1
kind: PodDisruptionBudget
metadata:
  name: web-app-pdb
  namespace: production
spec:
  minAvailable: 12  # 最低12 Podsは常時稼働
  selector:
    matchLabels:
      app: web
      tier: frontend
---
# Service（ClusterIP）
apiVersion: v1
kind: Service
metadata:
  name: web-service
  namespace: production
  labels:
    app: web
  annotations:
    # Prometheus監視
    prometheus.io/scrape: "true"
    prometheus.io/port: "8080"
spec:
  type: ClusterIP
  sessionAffinity: None
  
  selector:
    app: web
    tier: frontend
  
  ports:
  - name: http
    protocol: TCP
    port: 80
    targetPort: http
  - name: metrics
    protocol: TCP
    port: 9090
    targetPort: metrics
  
  # トラフィックポリシー
  internalTrafficPolicy: Local
---
# Ingress（ALB/NLB統合）
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: web-ingress
  namespace: production
  annotations:
    # AWS Load Balancer Controller
    alb.ingress.kubernetes.io/scheme: internet-facing
    alb.ingress.kubernetes.io/target-type: ip
    alb.ingress.kubernetes.io/listen-ports: '[{"HTTP": 80}, {"HTTPS": 443}]'
    alb.ingress.kubernetes.io/ssl-redirect: "443"
    alb.ingress.kubernetes.io/certificate-arn: arn:aws:acm:ap-northeast-1:123456789012:certificate/xxx
    alb.ingress.kubernetes.io/healthcheck-path: /healthz
    alb.ingress.kubernetes.io/healthcheck-interval-seconds: "15"
    alb.ingress.kubernetes.io/healthcheck-timeout-seconds: "5"
    alb.ingress.kubernetes.io/healthy-threshold-count: "2"
    alb.ingress.kubernetes.io/unhealthy-threshold-count: "2"
    
    # WAF
    alb.ingress.kubernetes.io/wafv2-acl-arn: arn:aws:wafv2:ap-northeast-1:123456789012:global/webacl/xxx
    
    # External DNS
    external-dns.alpha.kubernetes.io/hostname: tokyo.example.com
spec:
  ingressClassName: alb
  rules:
  - host: tokyo.example.com
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

## 3. SLO/SLI設定

### 3.1 完全なSLO定義

```yaml
# slo-complete-definition.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: slo-definitions
  namespace: monitoring
data:
  slo.yaml: |
    version: 1
    service: web-app
    
    slos:
      # 1. 可用性SLO: 99.9999% (年間31.5秒ダウンタイム)
      - name: availability
        description: Service availability (6 nines)
        objective: 0.999999
        window: 30d
        
        sli:
          type: availability
          query: |
            sum(rate(http_requests_total{job="web-app",code!~"5.."}[5m]))
            /
            sum(rate(http_requests_total{job="web-app"}[5m]))
        
        error_budget:
          total: 2.592  # 31.5秒 / 30日
          alerts:
            - threshold: 0.5  # 50%消費で警告
              severity: warning
            - threshold: 0.8  # 80%消費でクリティカル
              severity: critical
      
      # 2. レイテンシSLO: P95 < 100ms
      - name: latency-p95
        description: 95th percentile latency under 100ms
        objective: 0.100  # 100ms
        window: 30d
        
        sli:
          type: latency
          percentile: 0.95
          query: |
            histogram_quantile(0.95,
              rate(http_request_duration_seconds_bucket{job="web-app"}[5m])
            )
        
        error_budget:
          total: 0.01  # 1%のリクエストが100ms超過可能
      
      # 3. レイテンシSLO: P99 < 200ms
      - name: latency-p99
        description: 99th percentile latency under 200ms
        objective: 0.200
        window: 30d
        
        sli:
          type: latency
          percentile: 0.99
          query: |
            histogram_quantile(0.99,
              rate(http_request_duration_seconds_bucket{job="web-app"}[5m])
            )
      
      # 4. エラー率SLO: < 0.01% (99.99%成功率)
      - name: error-rate
        description: Error rate below 0.01%
        objective: 0.0001
        window: 30d
        
        sli:
          type: error_rate
          query: |
            sum(rate(http_requests_total{job="web-app",code=~"5.."}[5m]))
            /
            sum(rate(http_requests_total{job="web-app"}[5m]))
      
      # 5. スループットSLO: 最低10,000 req/s
      - name: throughput
        description: Minimum 10,000 requests per second
        objective: 10000
        window: 30d
        
        sli:
          type: throughput
          query: |
            sum(rate(http_requests_total{job="web-app"}[5m]))
---
# PrometheusRule（アラート定義）
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: slo-alerts
  namespace: monitoring
spec:
  groups:
  - name: slo
    interval: 30s
    rules:
    # 可用性アラート
    - alert: AvailabilitySLOBreach
      expr: |
        (
          sum(rate(http_requests_total{job="web-app",code!~"5.."}[5m]))
          /
          sum(rate(http_requests_total{job="web-app"}[5m]))
        ) < 0.999999
      for: 1m
      labels:
        severity: critical
        slo: availability
      annotations:
        summary: "Availability SLO breached (current: {{ $value }})"
        description: "Service availability is below 99.9999% for more than 1 minute"
    
    # レイテンシP95アラート
    - alert: LatencyP95SLOBreach
      expr: |
        histogram_quantile(0.95,
          rate(http_request_duration_seconds_bucket{job="web-app"}[5m])
        ) > 0.100
      for: 5m
      labels:
        severity: warning
        slo: latency-p95
      annotations:
        summary: "P95 latency SLO breached (current: {{ $value }}s)"
        description: "95th percentile latency is above 100ms for more than 5 minutes"
    
    # レイテンシP99アラート
    - alert: LatencyP99SLOBreach
      expr: |
        histogram_quantile(0.99,
          rate(http_request_duration_seconds_bucket{job="web-app"}[5m])
        ) > 0.200
      for: 5m
      labels:
        severity: warning
        slo: latency-p99
      annotations:
        summary: "P99 latency SLO breached (current: {{ $value }}s)"
    
    # エラー率アラート
    - alert: ErrorRateSLOBreach
      expr: |
        (
          sum(rate(http_requests_total{job="web-app",code=~"5.."}[5m]))
          /
          sum(rate(http_requests_total{job="web-app"}[5m]))
        ) > 0.0001
      for: 2m
      labels:
        severity: critical
        slo: error-rate
      annotations:
        summary: "Error rate SLO breached (current: {{ $value }})"
    
    # Error Budget消費率アラート
    - alert: ErrorBudgetBurnRateHigh
      expr: |
        (
          1 - (
            sum(rate(http_requests_total{job="web-app",code!~"5.."}[1h]))
            /
            sum(rate(http_requests_total{job="web-app"}[1h]))
          )
        ) / 0.000001 > 14.4  # 1時間で10%のバジェット消費
      for: 5m
      labels:
        severity: critical
      annotations:
        summary: "Error budget burning too fast"
        description: "At current rate, error budget will be exhausted in < 2 days"
```

## 4. コスト最適化

### 4.1 リソース最適化

```yaml
# vertical-pod-autoscaler.yaml
apiVersion: autoscaling.k8s.io/v1
kind: VerticalPodAutoscaler
metadata:
  name: web-app-vpa
  namespace: production
spec:
  targetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: web-app
  
  # 更新モード
  updatePolicy:
    updateMode: "Off"  # 推奨値のみ提供（自動更新なし）
  
  # リソース推奨ポリシー
  resourcePolicy:
    containerPolicies:
    - containerName: web
      minAllowed:
        cpu: 100m
        memory: 128Mi
      maxAllowed:
        cpu: 4000m
        memory: 8Gi
      controlledResources:
      - cpu
      - memory
      mode: Auto
```

```bash
# VPA推奨値の確認
kubectl describe vpa web-app-vpa -n production

# 出力例:
# Recommendation:
#   Container Recommendations:
#     Container Name:  web
#     Lower Bound:
#       Cpu:     450m
#       Memory:  400Mi
#     Target:
#       Cpu:     550m
#       Memory:  520Mi
#     Uncapped Target:
#       Cpu:     550m
#       Memory:  520Mi
#     Upper Bound:
#       Cpu:     1100m
#       Memory:  1040Mi

# 推奨値を基にDeploymentを更新
kubectl patch deployment web-app -n production -p '{
  "spec": {
    "template": {
      "spec": {
        "containers": [{
          "name": "web",
          "resources": {
            "requests": {
              "cpu": "550m",
              "memory": "520Mi"
            },
            "limits": {
              "cpu": "1100m",
              "memory": "1040Mi"
            }
          }
        }]
      }
    }
  }
}'
```

### 4.2 Spot/プリエンプティブインスタンスの活用

```yaml
# nodepool-spot-instances.yaml (GKE例)
apiVersion: container.cnrm.cloud.google.com/v1beta1
kind: ContainerNodePool
metadata:
  name: web-app-spot-pool
  namespace: production
spec:
  clusterRef:
    name: production-cluster
  
  # Spot VM使用
  nodeConfig:
    preemptible: true
    machineType: n2-standard-4
    diskSizeGb: 100
    diskType: pd-standard
    
    metadata:
      disable-legacy-endpoints: "true"
    
    oauthScopes:
    - "https://www.googleapis.com/auth/cloud-platform"
    
    taints:
    - key: cloud.google.com/gke-preemptible
      value: "true"
      effect: NO_SCHEDULE
  
  # オートスケーリング
  autoscaling:
    enabled: true
    minNodeCount: 3
    maxNodeCount: 20
  
  # ノード数
  initialNodeCount: 3
  
  management:
    autoRepair: true
    autoUpgrade: true
```

```yaml
# deployment-with-spot-toleration.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app-background
  namespace: production
spec:
  replicas: 5
  selector:
    matchLabels:
      app: web-background
  template:
    metadata:
      labels:
        app: web-background
    spec:
      # Spot/Preemptibleノードを許容
      tolerations:
      - key: cloud.google.com/gke-preemptible
        operator: Equal
        value: "true"
        effect: NoSchedule
      - key: node.kubernetes.io/not-ready
        operator: Exists
        effect: NoExecute
        tolerationSeconds: 10
      
      # 優先的にSpotインスタンスへ
      affinity:
        nodeAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 100
            preference:
              matchExpressions:
              - key: cloud.google.com/gke-preemptible
                operator: In
                values:
                - "true"
      
      containers:
      - name: app
        image: myregistry/web-app:1.0.0
```

### 4.3 コスト分析ダッシュボード

```yaml
# cost-analysis-dashboard.yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: cost-dashboard
  namespace: monitoring
data:
  dashboard.json: |
    {
      "dashboard": {
        "title": "Kubernetes Cost Analysis",
        "panels": [
          {
            "title": "Cost per Namespace",
            "targets": [
              {
                "expr": "sum(kube_pod_container_resource_requests{resource='cpu'} * on(node) group_left() node_cpu_hourly_cost) by (namespace)",
                "legendFormat": "{{ namespace }}"
              }
            ]
          },
          {
            "title": "Spot vs On-Demand Cost Savings",
            "targets": [
              {
                "expr": "(sum(node_cpu_hourly_cost{instance_lifecycle='spot'}) / sum(node_cpu_hourly_cost)) * 100",
                "legendFormat": "Spot Savings %"
              }
            ]
          },
          {
            "title": "Resource Utilization Efficiency",
            "targets": [
              {
                "expr": "(sum(rate(container_cpu_usage_seconds_total[5m])) / sum(kube_pod_container_resource_requests{resource='cpu'})) * 100",
                "legendFormat": "CPU Utilization %"
              },
              {
                "expr": "(sum(container_memory_working_set_bytes) / sum(kube_pod_container_resource_requests{resource='memory'})) * 100",
                "legendFormat": "Memory Utilization %"
              }
            ]
          }
        ]
      }
    }
```

## 5. パフォーマンスチューニング

### 5.1 ネットワーク最適化

```yaml
# network-policy-optimized.yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: web-app-network-policy
  namespace: production
spec:
  podSelector:
    matchLabels:
      app: web
  
  policyTypes:
  - Ingress
  - Egress
  
  ingress:
  # Ingressからのトラフィックのみ許可
  - from:
    - namespaceSelector:
        matchLabels:
          name: ingress-nginx
    ports:
    - protocol: TCP
      port: 8080
  
  # 同一Namespace内の通信許可
  - from:
    - podSelector: {}
    ports:
    - protocol: TCP
      port: 8080
  
  egress:
  # DNSクエリ
  - to:
    - namespaceSelector:
        matchLabels:
          name: kube-system
    ports:
    - protocol: UDP
      port: 53
  
  # データベース
  - to:
    - podSelector:
        matchLabels:
          app: database
    ports:
    - protocol: TCP
      port: 5432
  
  # Redis
  - to:
    - podSelector:
        matchLabels:
          app: redis
    ports:
    - protocol: TCP
      port: 6379
  
  # 外部API（HTTPS）
  - to:
    - namespaceSelector: {}
    ports:
    - protocol: TCP
      port: 443
```

### 5.2 キャッシュ戦略

```yaml
# redis-cluster.yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: redis-cluster
  namespace: cache
spec:
  serviceName: redis-cluster
  replicas: 6  # 3 masters + 3 replicas
  selector:
    matchLabels:
      app: redis
  
  template:
    metadata:
      labels:
        app: redis
    spec:
      # TopologySpreadConstraints
      topologySpreadConstraints:
      - maxSkew: 1
        topologyKey: topology.kubernetes.io/zone
        whenUnsatisfiable: DoNotSchedule
        labelSelector:
          matchLabels:
            app: redis
      
      containers:
      - name: redis
        image: redis:7-alpine
        command:
        - redis-server
        - /conf/redis.conf
        ports:
        - containerPort: 6379
          name: client
        - containerPort: 16379
          name: gossip
        
        resources:
          requests:
            cpu: 1000m
            memory: 4Gi
          limits:
            cpu: 2000m
            memory: 8Gi
        
        volumeMounts:
        - name: conf
          mountPath: /conf
        - name: data
          mountPath: /data
      
      volumes:
      - name: conf
        configMap:
          name: redis-cluster-config
  
  volumeClaimTemplates:
  - metadata:
      name: data
    spec:
      accessModes: ["ReadWriteOnce"]
      storageClassName: fast-ssd
      resources:
        requests:
          storage: 100Gi
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: redis-cluster-config
  namespace: cache
data:
  redis.conf: |
    # クラスタモード有効化
    cluster-enabled yes
    cluster-config-file /data/nodes.conf
    cluster-node-timeout 5000
    
    # AOF無効化（パフォーマンス優先）
    appendonly no
    
    # RDB設定（定期的なスナップショット）
    save 900 1
    save 300 10
    save 60 10000
    
    # メモリ最大値
    maxmemory 7gb
    maxmemory-policy allkeys-lru
    
    # ネットワーク設定
    tcp-backlog 511
    timeout 0
    tcp-keepalive 300
```

## 6. 25回シリーズ完全振り返り

### 6.1 シリーズ全体の構成

```
第1-5回: Kubernetes基礎
├─ 第1回: Kubernetesアーキテクチャ
├─ 第2回: Pod設計パターン
├─ 第3回: ネットワーキング基礎
├─ 第4回: ストレージ管理
└─ 第5回: ConfigMapとSecret

第6-10回: ワークロード管理
├─ 第6回: Deployment戦略
├─ 第7回: StatefulSet
├─ 第8回: DaemonSetとJob
├─ 第9回: HPA/VPA
└─ 第10回: Resource Management

第11-15回: ネットワークと外部公開
├─ 第11回: Service詳細
├─ 第12回: Ingress
├─ 第13回: Network Policy
├─ 第14回: Service Mesh (Istio)
└─ 第15回: DNS/CoreDNS

第16-20回: セキュリティ
├─ 第16回: RBAC
├─ 第17回: Pod Security
├─ 第18回: NetworkPolicy応用
├─ 第19回: イメージスキャン
└─ 第20回: Secret暗号化とKMS

第21-25回: 高可用性（本章）
├─ 第21回: マルチAZ構成 ←
├─ 第22回: マルチリージョン ←
├─ 第23回: カオスエンジニアリング ←
├─ 第24回: GitOps ←
└─ 第25回: 99.9999%完全構成 ← 今ここ
```

### 6.2 学習の旅の総まとめ

```
達成したこと:

✅ アーキテクチャ理解
   - Control Plane / Data Plane
   - etcd, API Server, Scheduler, Controller Manager
   - kubelet, kube-proxy, Container Runtime

✅ リソース管理マスター
   - Pod, Deployment, StatefulSet, DaemonSet
   - ConfigMap, Secret, PV, PVC
   - HPA, VPA, Resource Quotas

✅ ネットワーキング完全理解
   - ClusterIP, NodePort, LoadBalancer, Ingress
   - Network Policy, Service Mesh
   - DNS解決、CoreDNS設定

✅ セキュリティ強化
   - RBAC（最小権限の原則）
   - Pod Security Standards
   - イメージスキャン、脆弱性管理
   - Secret暗号化（KMS統合）

✅ 高可用性実現
   - マルチAZ/リージョン構成
   - TopologySpreadConstraints
   - Global Load Balancing
   - カオスエンジニアリング
   - GitOps運用

✅ 運用自動化
   - ArgoCD/Flux
   - CI/CDパイプライン
   - Progressive Delivery
   - 監視・アラート
```

### 6.3 次のステップへ

```
さらなる学習へ:

1. 実践プロジェクト
   ├─ 実際に本番環境構築
   ├─ カオス実験の定期実施
   └─ SLO/SLIの継続的改善

2. 専門分野深掘り
   ├─ eBPF/Cilium（高度なネットワーキング）
   ├─ Kubernetes Operators開発
   ├─ Multi-tenancy設計
   └─ Edge Computing (K3s, KubeEdge)

3. コミュニティ参加
   ├─ KubeCon/CloudNativeConカンファレンス
   ├─ CNCF Projects貢献
   ├─ Kubernetes SIG参加
   └─ ブログ/登壇での知見共有

4. 認定資格取得
   ├─ CKA (Certified Kubernetes Administrator)
   ├─ CKAD (Certified Kubernetes Application Developer)
   ├─ CKS (Certified Kubernetes Security Specialist)
   └─ Cloud Provider資格 (AWS/GCP/Azure)
```

## まとめ

### 本記事で学んだこと

1. **99.9999%可用性の実現**
   - 年間31.5秒のダウンタイム制約
   - マルチリージョン+マルチAZ構成
   - 完全な冗長化と自動フェイルオーバー

2. **完全アーキテクチャ**
   - 3リージョン × 3AZ × 9ノード構成
   - Global Load Balancing
   - データレプリケーション

3. **SLO/SLI定義**
   - 可用性、レイテンシ、エラー率
   - Error Budget管理
   - 自動アラート

4. **コスト最適化**
   - VPAによるリソース最適化
   - Spot/プリエンプティブインスタンス活用
   - コスト可視化

5. **パフォーマンスチューニング**
   - ネットワーク最適化
   - キャッシュ戦略
   - リソース効率化

### 最終チェックリスト

#### インフラストラクチャ
- ✅ 最低3リージョン構成
- ✅ 各リージョンに最低3 AZ
- ✅ 各AZに最低3ノード
- ✅ Global Load Balancing
- ✅ 自動フェイルオーバー（<10秒）

#### アプリケーション
- ✅ TopologySpreadConstraints設定
- ✅ PodDisruptionBudget定義
- ✅ HPA/VPA設定
- ✅ Liveness/Readiness Probe
- ✅ Graceful Shutdown実装

#### セキュリティ
- ✅ RBAC（最小権限）
- ✅ Pod Security Standards
- ✅ Network Policy
- ✅ Secret暗号化（KMS）
- ✅ イメージスキャン

#### 運用
- ✅ GitOps（ArgoCD/Flux）
- ✅ 自動化されたCI/CD
- ✅ Progressive Delivery
- ✅ カオスエンジニアリング
- ✅ 監視・アラート（SLO/SLI）

#### データ
- ✅ マルチリージョンレプリケーション
- ✅ 自動バックアップ
- ✅ ポイントインタイムリカバリ
- ✅ RTO/RPO定義

### 感謝とエールを込めて

25回にわたるKubernetesシリーズ、ここまでお付き合いいただき、本当にありがとうございました。

Kubernetesは複雑で奥深い技術ですが、その本質は「宣言的な状態管理」と「自動化」です。このシリーズを通じて、その理念を理解し、実践できる力を身につけていただけたなら、筆者としてこれ以上の喜びはありません。

99.9999%の可用性は、単なる技術的目標ではなく、ユーザーへの信頼の証です。あなたが構築するシステムが、世界中のユーザーに安定したサービスを提供し続けることを心から願っています。

**Keep Learning, Keep Building, Keep Shipping!** 🚀

## 参考リンク

- {{< linkcard "https://kubernetes.io/docs/" >}}
- {{< linkcard "https://sre.google/books/" >}}
- {{< linkcard "https://www.cncf.io/" >}}
- {{< linkcard "https://landscape.cncf.io/" >}}

---

**Kubernetesマスターシリーズ（全25回）完結**

これまでの旅、お疲れさまでした。あなたの次のプロジェクトが、素晴らしいものになりますように！
