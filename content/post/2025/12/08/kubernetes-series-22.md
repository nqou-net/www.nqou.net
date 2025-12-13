---
title: "Kubernetesを完全に理解した(第22回) - マルチリージョン構成"
draft: true
tags:
- kubernetes
- multi-region
- disaster-recovery
- global-load-balancing
- federation
description: 地理的に離れた複数リージョンでクラスタを運用し、リージョン障害にも耐える究極の可用性を実現。グローバル展開の基礎を学びます。
---

## 前回の振り返り

第21回では、マルチゾーン構成を実装し、単一データセンター障害に対する耐性を獲得しました。Topology Spread Constraintsを使用してPodを複数のアベイラビリティゾーンに分散させることで、1つのゾーンが停止してもサービスを継続できる堅牢なシステムを構築しました。

しかし、大規模な災害(地震、台風、広域停電など)によってリージョン全体が影響を受ける可能性があります。また、グローバルにサービスを提供する場合、ユーザーに最も近いリージョンからサービスを提供することでレイテンシを大幅に改善できます。

今回は、地理的に離れた**複数のリージョン**でKubernetesクラスタを運用し、リージョン障害にも耐える究極の高可用性システムを構築します。

## マルチリージョンアーキテクチャの必要性

### リージョン障害のリアル

2021年のAWS us-east-1での大規模障害、2022年のGoogleの欧州リージョン障害など、リージョンレベルの障害も発生します。これらは数時間〜数日に及ぶこともあり、ビジネスに深刻な影響を与えます。

### グローバル展開のメリット

- **災害復旧**: リージョン全体の障害時でも他のリージョンで継続
- **レイテンシ削減**: ユーザーに最も近いリージョンからサービス提供
- **コンプライアンス**: 各国のデータ主権要件への対応
- **負荷分散**: 地理的にトラフィックを分散

### アーキテクチャパターン

**アクティブ-パッシブ構成**:
- プライマリリージョンで全トラフィックを処理
- セカンダリリージョンはスタンバイ
- 障害時に手動または自動でフェイルオーバー
- シンプルだがリソース効率が悪い

**アクティブ-アクティブ構成**:
- 複数リージョンで同時にトラフィックを処理
- 地理的に最適なリージョンへ自動ルーティング
- 高いリソース効率と低レイテンシ
- 運用の複雑さが増す

## Kubernetes Federation (KubeFed)

### Federationの概念

Kubernetes Federationは、複数のKubernetesクラスタを単一の論理的なクラスタとして管理する仕組みです。1つのマニフェストを複数のクラスタに展開できます。

### KubeFedのインストール

```bash
# Helm を使用してKubeFedをインストール
helm repo add kubefed-charts https://raw.githubusercontent.com/kubernetes-sigs/kubefed/master/charts
helm install kubefed kubefed-charts/kubefed \
  --namespace kube-federation-system \
  --create-namespace

# クラスタの登録
kubefedctl join us-east --cluster-context us-east-context \
  --host-cluster-context host-context

kubefedctl join eu-west --cluster-context eu-west-context \
  --host-cluster-context host-context

kubefedctl join ap-south --cluster-context ap-south-context \
  --host-cluster-context host-context
```

### Federated Deploymentの定義

```yaml
apiVersion: types.kubefed.io/v1beta1
kind: FederatedDeployment
metadata:
  name: web-app
  namespace: production
spec:
  template:
    spec:
      replicas: 3
      selector:
        matchLabels:
          app: web
      template:
        metadata:
          labels:
            app: web
        spec:
          containers:
          - name: web
            image: myapp:v1.0
  placement:
    clusters:
    - name: us-east
    - name: eu-west
    - name: ap-south
  overrides:
  - clusterName: us-east
    clusterOverrides:
    - path: "/spec/replicas"
      value: 5
  - clusterName: eu-west
    clusterOverrides:
    - path: "/spec/replicas"
      value: 3
```

この設定により、米国では5レプリカ、欧州では3レプリカ、アジアでは3レプリカが展開されます。

## グローバルロードバランシング

### DNSベースのルーティング

最もシンプルな方法は、DNSのGeolocation機能を使用して、ユーザーの地理的位置に基づいて最適なリージョンにルーティングすることです。

```yaml
# Route53 Geolocation routing (Terraformの例)
resource "aws_route53_record" "www_us" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "www.example.com"
  type    = "A"
  
  geolocation_routing_policy {
    continent = "NA"
  }
  
  alias {
    name                   = aws_lb.us_east.dns_name
    zone_id                = aws_lb.us_east.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "www_eu" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "www.example.com"
  type    = "A"
  
  geolocation_routing_policy {
    continent = "EU"
  }
  
  alias {
    name                   = aws_lb.eu_west.dns_name
    zone_id                = aws_lb.eu_west.zone_id
    evaluate_target_health = true
  }
}
```

### Anycast IPとグローバルアクセラレーター

AWS Global AcceleratorやCloudflare Load Balancingを使用すると、単一のAnycast IPアドレスで複数リージョンにトラフィックを分散できます。

```yaml
# Cloudflareの例
{
  "name": "k8s-global-lb",
  "default_pools": ["us-east-pool", "eu-west-pool", "ap-south-pool"],
  "steering_policy": "geo",
  "session_affinity": "cookie",
  "rules": [
    {
      "name": "US Traffic",
      "condition": "http.request.headers[\"cf-ipcountry\"] == \"US\"",
      "overrides": {
        "default_pools": ["us-east-pool"]
      }
    }
  ]
}
```

## クロスリージョンデータレプリケーション

### データベースのマルチリージョン構成

PostgreSQLやMySQLなどのリレーショナルデータベースでは、プライマリ-レプリカ構成でクロスリージョンレプリケーションを実現できます。

```yaml
# CloudNativePGでのクロスリージョンレプリカ
apiVersion: postgresql.cnpg.io/v1
kind: Cluster
metadata:
  name: postgres-replica-eu
  namespace: production
spec:
  instances: 3
  replica:
    enabled: true
    source: postgres-primary
    connectionParameters:
      host: "postgres-primary-rw.us-east.example.com"
      user: "replication_user"
      sslmode: "require"
```

### Redisのグローバル分散

Redis EnterpriseのActive-Active CRDBを使用すると、複数リージョンで書き込み可能なRedisクラスタを構築できます。

```yaml
apiVersion: app.redislabs.com/v1alpha1
kind: RedisEnterpriseDatabase
metadata:
  name: global-cache
spec:
  memorySize: 10GB
  activeActive:
    enabled: true
    participatingClusters:
    - name: us-east-cluster
      replicationEndpoint: redis-us-east.example.com:9443
    - name: eu-west-cluster
      replicationEndpoint: redis-eu-west.example.com:9443
    method: CRDT
```

CRDTアルゴリズムにより、複数リージョンで同時書き込みが可能で、最終的に一貫性が保たれます。

### オブジェクトストレージのレプリケーション

S3などのオブジェクトストレージは、クロスリージョンレプリケーション機能を提供しています。

```yaml
# S3 Cross-Region Replication (Terraform)
resource "aws_s3_bucket_replication_configuration" "replication" {
  bucket = aws_s3_bucket.source.id
  role   = aws_iam_role.replication.arn

  rule {
    id     = "replicate-to-eu"
    status = "Enabled"

    destination {
      bucket        = aws_s3_bucket.eu_west.arn
      storage_class = "STANDARD_IA"
      
      replication_time {
        status = "Enabled"
        time {
          minutes = 15
        }
      }
    }
  }
}
```

## バックアップと災害復旧

### Veleroによるマルチクラスタバックアップ

Veleroを使用すると、Kubernetesリソースとボリュームを定期的にバックアップし、別のクラスタにリストアできます。

```bash
# 各リージョンでVeleroをインストール
velero install \
  --provider aws \
  --plugins velero/velero-plugin-for-aws:v1.6.0 \
  --bucket velero-backups-global \
  --secret-file ./credentials-velero \
  --backup-location-config region=us-east-1

# 定期バックアップのスケジュール
velero schedule create daily-backup \
  --schedule="0 2 * * *" \
  --include-namespaces production,staging \
  --ttl 720h0m0s
```

### クロスリージョンリストア

```bash
# 別リージョンでバックアップを確認
velero backup get --context eu-west-context

# リストアの実行
velero restore create --from-backup daily-backup-20231201 \
  --namespace-mappings production:production-dr \
  --context eu-west-context
```

## モニタリングとアラート

### Prometheus Federation

各リージョンのPrometheusからメトリクスを集約し、グローバルな視点でシステムを監視します。

```yaml
# Global Prometheus configuration
scrape_configs:
- job_name: 'federate-us-east'
  scrape_interval: 60s
  honor_labels: true
  metrics_path: '/federate'
  params:
    'match[]':
      - '{job=~"kubernetes-.*"}'
  static_configs:
  - targets:
    - 'prometheus.us-east.example.com:9090'
    labels:
      region: 'us-east'

- job_name: 'federate-eu-west'
  scrape_interval: 60s
  honor_labels: true
  metrics_path: '/federate'
  static_configs:
  - targets:
    - 'prometheus.eu-west.example.com:9090'
    labels:
      region: 'eu-west'
```

### クロスリージョンアラート

```yaml
groups:
- name: multi-region-alerts
  rules:
  - alert: RegionDown
    expr: up{job="kubernetes-apiservers"} == 0
    for: 5m
    labels:
      severity: critical
    annotations:
      summary: "Region {{ $labels.region }} is down"
      
  - alert: CrossRegionLatencyHigh
    expr: |
      histogram_quantile(0.95,
        sum(rate(http_request_duration_seconds_bucket[5m]))
        by (source_region, destination_region, le)
      ) > 0.5
    for: 10m
    labels:
      severity: warning
```

## フェイルオーバー戦略

### 自動フェイルオーバー

リージョン障害を検知したら、DNSやロードバランサーの設定を自動的に変更してトラフィックを健全なリージョンにルーティングします。

```bash
#!/bin/bash
PRIMARY_REGION="us-east"
SECONDARY_REGION="eu-west"

check_region_health() {
  local region=$1
  curl -f -s --max-time 5 "https://api.${region}.example.com/health"
}

if ! check_region_health $PRIMARY_REGION; then
  if check_region_health $SECONDARY_REGION; then
    echo "Failing over to $SECONDARY_REGION"
    
    # DNSレコードを更新
    aws route53 change-resource-record-sets \
      --hosted-zone-id Z1234567890ABC \
      --change-batch file://failover-dns.json
    
    # セカンダリリージョンをスケールアップ
    kubectl --context $SECONDARY_REGION scale deployment/web-app --replicas=10
  fi
fi
```

### 段階的なフェイルバック

プライマリリージョンが復旧したら、段階的にトラフィックを戻します。

```bash
# トラフィックを徐々に戻す
for weight in 10 30 50 80 100; do
  echo "Setting primary region weight to $weight%"
  # ロードバランサーの重み付けを更新
  sleep 300  # 5分待機して監視
done
```

## コストの最適化

### リージョン選択の考慮事項

リージョンによってコンピューティングコストが異なります。主要市場に近く、かつコストが低いリージョンを選択します。

- **データ転送コスト**: リージョン間のデータ転送には課金される
- **ストレージコスト**: リージョンによって異なる
- **コンピューティングコスト**: 同じインスタンスタイプでもリージョンで価格差

### CDNの活用

CloudFrontやCloudflareなどのCDNを活用することで、静的コンテンツのレイテンシを削減しつつ、クロスリージョン通信を最小化できます。

## 実践的な構成例

### 3リージョン構成のグローバルサービス

```yaml
# 米国リージョン(プライマリ)
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app-us
  namespace: production
spec:
  replicas: 10
  template:
    spec:
      containers:
      - name: web
        image: myapp:v1.0
        env:
        - name: REGION
          value: "us-east-1"
        - name: DATABASE_HOST
          value: "postgres-us.example.com"
---
# 欧州リージョン(セカンダリ)
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app-eu
  namespace: production
spec:
  replicas: 5
  template:
    spec:
      containers:
      - name: web
        image: myapp:v1.0
        env:
        - name: REGION
          value: "eu-west-1"
        - name: DATABASE_HOST
          value: "postgres-eu.example.com"
---
# アジアリージョン(セカンダリ)
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app-ap
  namespace: production
spec:
  replicas: 5
  template:
    spec:
      containers:
      - name: web
        image: myapp:v1.0
        env:
        - name: REGION
          value: "ap-south-1"
        - name: DATABASE_HOST
          value: "postgres-ap.example.com"
```

## まとめ

マルチリージョン構成により、リージョン全体の障害にも耐えられる究極の高可用性を実現しました。Kubernetes Federationでクラスタを統合管理し、グローバルロードバランシングで最適なリージョンにトラフィックをルーティングし、データレプリケーションで各リージョンでデータを利用可能にしました。

次回は、**カオスエンジニアリング**に挑戦します。意図的に障害を起こしてシステムの弾力性を検証する革新的な手法で、本番環境で起きる前に弱点を発見します。

### 主要な学習ポイント

- Kubernetes Federationによる複数クラスタの統合管理
- GeoDNSとグローバルロードバランシング
- クロスリージョンデータレプリケーション戦略
- Veleroによるバックアップと災害復旧
- Prometheus Federationによるグローバル監視
- 自動フェイルオーバーとフェイルバックの実装

グローバルスケールのシステムで、世界中のユーザーに高速で信頼性の高いサービスを提供しましょう！
