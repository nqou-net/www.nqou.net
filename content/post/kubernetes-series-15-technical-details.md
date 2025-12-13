---
title: "Backupと災害復旧 - クラスタの可用性を守る（技術詳細）"
draft: true
tags:
- kubernetes
- backup
- disaster-recovery
- etcd
- velero
- business-continuity
description: "Kubernetes環境での完全なバックアップと災害復旧戦略ガイド。etcdバックアップ、Veleroの使い方、DR計画の策定を実践的に解説。"
---

## はじめに

本番環境のKubernetesクラスタでは、障害や人的ミスによるデータ損失に備えて、適切なバックアップと災害復旧（DR）計画が不可欠です。本記事では、etcdバックアップ、Veleroを使ったアプリケーションレベルのバックアップ、実践的なDR計画について徹底解説します。

## 1. バックアップ戦略の全体像

### 1.1 バックアップすべき対象

```
┌──────────────────────────────────────────┐
│    Kubernetesクラスタのバックアップ     │
├──────────────────────────────────────────┤
│ 1. etcd（クラスタ状態）                  │
│    - リソース定義（Deployment、Service等）│
│    - ConfigMap、Secret                   │
│    - RBAC設定                            │
│                                          │
│ 2. PersistentVolume（永続データ）       │
│    - データベース                        │
│    - アプリケーションデータ              │
│    - ユーザーアップロードファイル        │
│                                          │
│ 3. アプリケーション設定                  │
│    - Helmチャート                        │
│    - YAMLマニフェスト                    │
│    - CI/CDパイプライン設定               │
└──────────────────────────────────────────┘
```

### 1.2 RPO（Recovery Point Objective）とRTO（Recovery Time Objective）

**RPO**: どの時点までのデータを復旧するか
**RTO**: どのくらいの時間で復旧するか

| サービスレベル | RPO | RTO | バックアップ頻度 |
|-------------|-----|-----|----------------|
| Critical | 15分 | 1時間 | 15分ごと |
| High | 1時間 | 4時間 | 1時間ごと |
| Medium | 1日 | 1日 | 毎日 |
| Low | 1週間 | 3日 | 毎週 |

## 2. etcdバックアップ

### 2.1 etcdの役割と重要性

**etcd**: Kubernetesの全ての状態を保存する分散KVS

```
etcdに保存されるデータ:
- 全てのリソース定義（Pods、Services、Deploymentsなど）
- ConfigMap、Secret
- RBAC設定（Role、RoleBinding）
- クラスタの設定情報
```

**etcd喪失時の影響**:
```
❌ クラスタ全体が復旧不可能
❌ 全てのリソース定義が失われる
❌ アプリケーションの再デプロイが必要
```

### 2.2 etcdctl を使った手動バックアップ

#### 前提条件の確認

```bash
# etcdが動作しているPodを確認
kubectl get pods -n kube-system | grep etcd
# etcd-minikube   1/1   Running   0   10d

# etcdctlのバージョン確認
kubectl exec -n kube-system etcd-minikube -- etcdctl version
# etcdctl version: 3.5.9
# API version: 3.5
```

#### バックアップの実行

```bash
# etcd Pod内でバックアップを実行
kubectl exec -n kube-system etcd-minikube -- sh -c \
  "ETCDCTL_API=3 etcdctl \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/var/lib/minikube/certs/etcd/ca.crt \
  --cert=/var/lib/minikube/certs/etcd/server.crt \
  --key=/var/lib/minikube/certs/etcd/server.key \
  snapshot save /var/lib/etcd/snapshot.db"

# 出力:
# {"level":"info","ts":"2024-12-08T03:00:00.000Z","caller":"snapshot/v3_snapshot.go:65","msg":"created temporary db file","path":"/var/lib/etcd/snapshot.db.part"}
# {"level":"info","ts":"2024-12-08T03:00:00.123Z","caller":"snapshot/v3_snapshot.go:76","msg":"fetching snapshot","endpoint":"https://127.0.0.1:2379"}
# {"level":"info","ts":"2024-12-08T03:00:01.234Z","logger":"client","caller":"v3@v3.5.9/maintenance.go:212","msg":"opened snapshot stream; downloading"}
# Snapshot saved at /var/lib/etcd/snapshot.db

# バックアップファイルをローカルにコピー
kubectl cp -n kube-system etcd-minikube:/var/lib/etcd/snapshot.db ./etcd-backup-$(date +%Y%m%d-%H%M%S).db

# バックアップの検証
etcdctl --write-out=table snapshot status etcd-backup-20241208-030000.db
# +----------+----------+------------+------------+
# |   HASH   | REVISION | TOTAL KEYS | TOTAL SIZE |
# +----------+----------+------------+------------+
# | 12ab34cd |   123456 |       5678 |     10 MB  |
# +----------+----------+------------+------------+
```

### 2.3 自動バックアップのCronJob

```yaml
# etcd-backup-cronjob.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: etcd-backup
  namespace: kube-system
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: etcd-backup
rules:
- apiGroups: [""]
  resources: ["pods", "pods/exec"]
  verbs: ["get", "list", "create"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: etcd-backup
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: etcd-backup
subjects:
- kind: ServiceAccount
  name: etcd-backup
  namespace: kube-system
---
apiVersion: batch/v1
kind: CronJob
metadata:
  name: etcd-backup
  namespace: kube-system
spec:
  schedule: "0 */6 * * *"  # 6時間ごと
  successfulJobsHistoryLimit: 3
  failedJobsHistoryLimit: 1
  jobTemplate:
    spec:
      template:
        spec:
          serviceAccountName: etcd-backup
          containers:
          - name: backup
            image: bitnami/kubectl:latest
            command:
            - /bin/sh
            - -c
            - |
              set -e
              BACKUP_NAME="etcd-backup-$(date +%Y%m%d-%H%M%S).db"
              
              # etcdバックアップ実行
              kubectl exec -n kube-system etcd-minikube -- sh -c \
                "ETCDCTL_API=3 etcdctl \
                --endpoints=https://127.0.0.1:2379 \
                --cacert=/var/lib/minikube/certs/etcd/ca.crt \
                --cert=/var/lib/minikube/certs/etcd/server.crt \
                --key=/var/lib/minikube/certs/etcd/server.key \
                snapshot save /tmp/${BACKUP_NAME}"
              
              # S3にアップロード（AWS CLIが利用可能な場合）
              kubectl exec -n kube-system etcd-minikube -- \
                aws s3 cp /tmp/${BACKUP_NAME} s3://my-etcd-backups/${BACKUP_NAME}
              
              # 古いバックアップを削除（30日以上前）
              kubectl exec -n kube-system etcd-minikube -- \
                aws s3 ls s3://my-etcd-backups/ | \
                awk '{print $4}' | \
                while read file; do
                  if [ $(date -d "$(echo $file | cut -d'-' -f3-4)" +%s) -lt $(date -d '30 days ago' +%s) ]; then
                    aws s3 rm s3://my-etcd-backups/$file
                  fi
                done
              
              echo "Backup completed: ${BACKUP_NAME}"
          restartPolicy: OnFailure
```

```bash
# デプロイ
kubectl apply -f etcd-backup-cronjob.yaml

# 手動実行（テスト）
kubectl create job --from=cronjob/etcd-backup etcd-backup-manual -n kube-system

# ジョブの確認
kubectl get jobs -n kube-system
# NAME                  COMPLETIONS   DURATION   AGE
# etcd-backup-manual    1/1           45s        1m

# ログ確認
kubectl logs -n kube-system job/etcd-backup-manual
# Backup completed: etcd-backup-20241208-030000.db
```

### 2.4 etcdからの復旧

```bash
# 1. etcdを停止
kubectl delete pod -n kube-system etcd-minikube

# 2. バックアップから復元（etcd Podのコンテナ内で実行）
ETCDCTL_API=3 etcdctl snapshot restore etcd-backup-20241208-030000.db \
  --name minikube \
  --initial-cluster minikube=https://192.168.49.2:2380 \
  --initial-cluster-token etcd-cluster-1 \
  --initial-advertise-peer-urls https://192.168.49.2:2380 \
  --data-dir /var/lib/etcd-restored

# 3. etcdの設定を更新（data-dirを変更）
# /etc/kubernetes/manifests/etcd.yaml を編集
# --data-dir=/var/lib/etcd-restored

# 4. etcdを再起動（自動的に再起動される）

# 5. クラスタ状態確認
kubectl get nodes
kubectl get pods --all-namespaces
```

**注意点**:
- 本番環境では事前にリストア手順を検証すること
- マルチマスター構成では全てのetcdメンバーで復元が必要
- etcd復元後は全てのPodが再起動される

## 3. Veleroによるアプリケーションバックアップ

### 3.1 Veleroとは

**Velero**: Kubernetesリソース + PersistentVolumeのバックアップ/リストアツール

```
Veleroの機能:
✅ Namespace単位のバックアップ
✅ リソース選択的バックアップ（ラベルセレクタ）
✅ PersistentVolumeのスナップショット
✅ スケジュールバックアップ
✅ クラスタ間移行
✅ DR（災害復旧）
```

### 3.2 Veleroのインストール

```bash
# Velero CLIのインストール
wget https://github.com/vmware-tanzu/velero/releases/download/v1.12.0/velero-v1.12.0-linux-amd64.tar.gz
tar -xvf velero-v1.12.0-linux-amd64.tar.gz
sudo mv velero-v1.12.0-linux-amd64/velero /usr/local/bin/

# バージョン確認
velero version --client-only
# Client: v1.12.0

# AWS S3をバックアップ先に設定する場合
cat > credentials-velero << EOF
[default]
aws_access_key_id = YOUR_ACCESS_KEY
aws_secret_access_key = YOUR_SECRET_KEY
EOF

# Veleroをインストール
velero install \
  --provider aws \
  --plugins velero/velero-plugin-for-aws:v1.8.0 \
  --bucket my-velero-backups \
  --backup-location-config region=ap-northeast-1 \
  --snapshot-location-config region=ap-northeast-1 \
  --secret-file ./credentials-velero

# インストール確認
kubectl get pods -n velero
# NAME                      READY   STATUS    RESTARTS   AGE
# velero-7d8c9f5b6d-abc12   1/1     Running   0          1m

# BackupStorageLocationの確認
kubectl get backupstoragelocation -n velero
# NAME      PHASE       LAST VALIDATED   AGE
# default   Available   10s              1m
```

### 3.3 バックアップの作成

#### 全Namespaceのバックアップ

```bash
# 全てのリソースをバックアップ
velero backup create full-backup --wait

# バックアップ状況確認
velero backup describe full-backup

# 出力例:
# Name:         full-backup
# Namespace:    velero
# Labels:       velero.io/storage-location=default
# Phase:        Completed
# 
# Namespaces:
#   Included:  *
#   Excluded:  <none>
# 
# Resources:
#   Included:        *
#   Excluded:        <none>
#   Cluster-scoped:  auto
# 
# Backup Format Version:  1.1.0
# 
# Started:    2024-12-08 03:00:00 +0000 UTC
# Completed:  2024-12-08 03:02:15 +0000 UTC
# 
# Expiration:  2024-12-08 03:00:00 +0000 UTC
# 
# Total items to be backed up:  1234
# Items backed up:              1234
```

#### 特定Namespaceのバックアップ

```bash
# productionのみバックアップ
velero backup create production-backup \
  --include-namespaces production \
  --wait

# 確認
velero backup get
# NAME                STATUS      CREATED                         EXPIRES   STORAGE LOCATION   SELECTOR
# production-backup   Completed   2024-12-08 03:00:00 +0000 UTC   29d       default            <none>
# full-backup         Completed   2024-12-08 02:00:00 +0000 UTC   29d       default            <none>
```

#### ラベルセレクタを使ったバックアップ

```bash
# app=myappのリソースのみバックアップ
velero backup create myapp-backup \
  --selector app=myapp \
  --include-cluster-resources=false \
  --wait
```

#### PersistentVolumeを含むバックアップ

```bash
# PVCのスナップショットも取得
velero backup create db-backup \
  --include-namespaces database \
  --snapshot-volumes=true \
  --wait

# バックアップの詳細確認
velero backup describe db-backup --details
# Persistent Volumes:
#   pvc-abc123 (PersistentVolumeClaim: database/postgres-data):
#     Snapshot ID:        snap-0123456789abcdef0
#     Type:               gp3
#     Availability Zone:  ap-northeast-1a
#     IOPS:               3000
```

### 3.4 スケジュールバックアップ

```bash
# 毎日3時にバックアップ
velero schedule create daily-backup \
  --schedule="0 3 * * *" \
  --include-namespaces production,staging \
  --ttl 720h  # 30日間保持

# 毎時バックアップ（直近24時間のみ保持）
velero schedule create hourly-backup \
  --schedule="@every 1h" \
  --include-namespaces production \
  --ttl 24h

# スケジュール確認
velero schedule get
# NAME            STATUS    CREATED                         SCHEDULE      BACKUP TTL   LAST BACKUP   SELECTOR
# daily-backup    Enabled   2024-12-08 03:00:00 +0000 UTC   0 3 * * *     720h0m0s     10m ago       <none>
# hourly-backup   Enabled   2024-12-08 03:00:00 +0000 UTC   @every 1h     24h0m0s      5m ago        <none>

# 手動でスケジュールを実行
velero backup create --from-schedule daily-backup

# スケジュールの一時停止
velero schedule pause daily-backup

# スケジュールの再開
velero schedule unpause daily-backup
```

### 3.5 バックアップからの復元

#### 全体復元

```bash
# 最新のバックアップから復元
velero restore create --from-backup production-backup --wait

# 復元状況確認
velero restore describe production-backup-20241208030000

# ログ確認
velero restore logs production-backup-20241208030000
```

#### 特定Namespaceのみ復元

```bash
# productionのみ復元
velero restore create \
  --from-backup full-backup \
  --include-namespaces production \
  --wait
```

#### リソース種別を指定して復元

```bash
# ConfigMapとSecretのみ復元
velero restore create \
  --from-backup production-backup \
  --include-resources configmaps,secrets \
  --wait
```

#### 別のNamespaceに復元

```bash
# productionからstagingに復元
velero restore create \
  --from-backup production-backup \
  --namespace-mappings production:staging \
  --wait
```

### 3.6 クラスタ間移行

```bash
# クラスタA（移行元）でバックアップ
velero backup create migration-backup --wait

# クラスタB（移行先）でVeleroをインストール（同じS3バケット）
velero install \
  --provider aws \
  --plugins velero/velero-plugin-for-aws:v1.8.0 \
  --bucket my-velero-backups \
  --backup-location-config region=ap-northeast-1 \
  --secret-file ./credentials-velero

# クラスタBでバックアップを確認
velero backup get
# NAME               STATUS      CREATED                         EXPIRES   STORAGE LOCATION
# migration-backup   Completed   2024-12-08 03:00:00 +0000 UTC   29d       default

# クラスタBで復元
velero restore create --from-backup migration-backup --wait
```

## 4. 災害復旧（DR）計画

### 4.1 DR戦略の種類

| 戦略 | RPO | RTO | コスト | 説明 |
|-----|-----|-----|--------|-----|
| Backup & Restore | 数時間 | 数時間 | 低 | 定期的にバックアップ、障害時に復元 |
| Pilot Light | 数分 | 数十分 | 中 | 最小限の環境を常時起動 |
| Warm Standby | 数秒 | 数分 | 高 | 縮小版の環境を常時起動 |
| Hot Standby | 0 | 0 | 最高 | 完全な複製環境を常時起動 |

### 4.2 DR計画の策定

```yaml
# dr-plan.yaml - DR計画のドキュメント例
disaster_recovery_plan:
  version: "1.0"
  last_updated: "2024-12-08"
  
  contact:
    primary: "ops-team@example.com"
    secondary: "cto@example.com"
    on_call: "+81-90-1234-5678"
  
  rpo_rto:
    production:
      rpo: "15 minutes"
      rto: "1 hour"
    staging:
      rpo: "1 hour"
      rto: "4 hours"
  
  backup_schedule:
    etcd:
      frequency: "every 6 hours"
      retention: "30 days"
      location: "s3://my-etcd-backups/"
    
    application:
      frequency: "every 1 hour"
      retention: "7 days"
      location: "s3://my-velero-backups/"
    
    database:
      frequency: "every 15 minutes"
      retention: "7 days"
      location: "s3://my-db-backups/"
  
  recovery_procedures:
    etcd_failure:
      - step: "Identify failed etcd member"
        command: "kubectl get pods -n kube-system | grep etcd"
      
      - step: "Download latest backup"
        command: "aws s3 cp s3://my-etcd-backups/latest.db /tmp/"
      
      - step: "Restore etcd"
        command: "etcdctl snapshot restore /tmp/latest.db"
      
      - step: "Restart etcd"
        command: "systemctl restart etcd"
      
      - step: "Verify cluster health"
        command: "kubectl get nodes"
    
    namespace_deletion:
      - step: "List available backups"
        command: "velero backup get"
      
      - step: "Restore from backup"
        command: "velero restore create --from-backup <backup-name> --include-namespaces <namespace>"
      
      - step: "Verify restoration"
        command: "kubectl get all -n <namespace>"
    
    complete_cluster_loss:
      - step: "Provision new cluster"
        duration: "30 minutes"
      
      - step: "Install Velero"
        command: "velero install --provider aws ..."
      
      - step: "Restore etcd"
        command: "etcdctl snapshot restore ..."
      
      - step: "Restore applications"
        command: "velero restore create --from-backup full-backup"
      
      - step: "Verify all services"
        duration: "30 minutes"
  
  testing:
    frequency: "quarterly"
    last_test: "2024-09-01"
    next_test: "2024-12-01"
    
    test_scenarios:
      - "Single etcd member failure"
      - "Complete cluster loss"
      - "Accidental namespace deletion"
      - "PersistentVolume corruption"
```

### 4.3 DR演習の実施

```bash
# DR演習シナリオ1: Namespace削除からの復旧
# 1. テスト用Namespaceを作成
kubectl create namespace dr-test
kubectl run nginx --image=nginx -n dr-test
kubectl expose pod nginx --port=80 -n dr-test

# 2. バックアップ作成
velero backup create dr-test-backup --include-namespaces dr-test --wait

# 3. 意図的に削除（災害をシミュレート）
kubectl delete namespace dr-test

# 4. 復元
velero restore create --from-backup dr-test-backup --wait

# 5. 検証
kubectl get all -n dr-test
# NAME        READY   STATUS    RESTARTS   AGE
# pod/nginx   1/1     Running   0          30s

# 6. 復旧時間を計測・記録
```

### 4.4 定期的なバックアップテスト

```bash
# バックアップ検証スクリプト
cat > verify-backup.sh << 'EOF'
#!/bin/bash
set -e

BACKUP_NAME=$1

echo "Testing backup: ${BACKUP_NAME}"

# 1. テスト用Namespaceに復元
velero restore create test-restore-$(date +%s) \
  --from-backup ${BACKUP_NAME} \
  --namespace-mappings production:backup-test \
  --wait

# 2. 重要なリソースが存在するか確認
kubectl get deployments -n backup-test
kubectl get services -n backup-test
kubectl get configmaps -n backup-test

# 3. クリーンアップ
kubectl delete namespace backup-test

echo "Backup verification completed successfully"
EOF

chmod +x verify-backup.sh

# 実行
./verify-backup.sh production-backup
```

### 4.5 Multi-Region DR構成

```yaml
# multi-region-dr.yaml
apiVersion: velero.io/v1
kind: BackupStorageLocation
metadata:
  name: primary-region
  namespace: velero
spec:
  provider: aws
  objectStorage:
    bucket: velero-backups-ap-northeast-1
  config:
    region: ap-northeast-1
---
apiVersion: velero.io/v1
kind: BackupStorageLocation
metadata:
  name: dr-region
  namespace: velero
spec:
  provider: aws
  objectStorage:
    bucket: velero-backups-us-west-2
  config:
    region: us-west-2
---
apiVersion: velero.io/v1
kind: Schedule
metadata:
  name: cross-region-backup
  namespace: velero
spec:
  schedule: "0 */6 * * *"
  template:
    includedNamespaces:
    - production
    storageLocation: primary-region
    # プライマリリージョンにバックアップ後、
    # DRリージョンにレプリケート（S3のCross-Region Replication使用）
```

## 5. 実践的なバックアップ運用

### 5.1 バックアップの監視

```yaml
# backup-monitoring-alert.yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: velero-backup-alerts
  namespace: monitoring
spec:
  groups:
  - name: velero.rules
    interval: 30s
    rules:
    # バックアップ失敗
    - alert: VeleroBackupFailed
      expr: |
        increase(velero_backup_failure_total[1h]) > 0
      for: 5m
      labels:
        severity: critical
      annotations:
        summary: "Velero backup failed"
        description: "{{ $value }} backup(s) failed in the last hour"
    
    # バックアップが古い
    - alert: VeleroBackupTooOld
      expr: |
        time() - velero_backup_last_successful_timestamp > 86400
      for: 1h
      labels:
        severity: warning
      annotations:
        summary: "Velero backup is too old"
        description: "Last successful backup was {{ $value | humanizeDuration }} ago"
```

### 5.2 コスト最適化

```bash
# 古いバックアップの削除ポリシー
velero schedule create daily-backup \
  --schedule="0 3 * * *" \
  --ttl 168h  # 7日間保持

# S3ライフサイクルポリシー（Glacier移行）
aws s3api put-bucket-lifecycle-configuration \
  --bucket my-velero-backups \
  --lifecycle-configuration '{
    "Rules": [
      {
        "Id": "archive-old-backups",
        "Status": "Enabled",
        "Transitions": [
          {
            "Days": 30,
            "StorageClass": "GLACIER"
          }
        ],
        "Expiration": {
          "Days": 365
        }
      }
    ]
  }'
```

## まとめ

### 学んだこと

1. **etcdバックアップ**
   - etcdctlでスナップショット作成
   - CronJobで自動化
   - 復元手順の確立

2. **Veleroの活用**
   - Namespace/リソース単位のバックアップ
   - PersistentVolumeスナップショット
   - スケジュールバックアップ
   - クラスタ間移行

3. **DR計画**
   - RPO/RTOの定義
   - 復旧手順の文書化
   - 定期的な演習実施

4. **運用ベストプラクティス**
   - バックアップの監視とアラート
   - コスト最適化
   - Multi-Region構成

### ベストプラクティス

- etcdバックアップは最低6時間ごと
- Veleroでアプリケーションレベルのバックアップ
- 定期的にリストア演習を実施
- バックアップの自動検証
- 複数リージョンへのレプリケーション

## 参考リンク

- {{< linkcard "https://kubernetes.io/docs/tasks/administer-cluster/configure-upgrade-etcd/#backing-up-an-etcd-cluster" >}}
- {{< linkcard "https://velero.io/docs/" >}}
- {{< linkcard "https://github.com/vmware-tanzu/velero" >}}
