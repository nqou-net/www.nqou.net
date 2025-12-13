---
title: "Kubernetesを完全に理解した（第15回）- バックアップとDR"
draft: true
tags:
- kubernetes
- backup
- disaster-recovery
- velero
- etcd
description: "万が一の障害に備えたバックアップ体制を構築。データ損失リスクを最小化し、迅速な復旧を可能にする方法を学びます。"
---

## はじめに - 第14回の振り返りと第15回で学ぶこと

前回の第14回では、監視とログ基盤について学びました。FluentBitによるログ収集、Prometheus/Grafanaによるメトリクス監視、そしてアラート設定を通じて、システムの健全性を常に把握する仕組みを理解できました。

今回の第15回では、シリーズ最終回として **バックアップとDR（災害復旧）** について学びます。本番環境で最も重要な、万が一の障害に備えたバックアップ体制と復旧計画の構築方法を実践します。

本記事で学ぶ内容：

- バックアップすべき対象とRPO/RTO
- etcdバックアップの実践
- Veleroによるアプリケーションバックアップ
- 災害復旧計画の策定
- 定期的なバックアップテストと演習

## バックアップ戦略の全体像

### バックアップすべき対象

```
┌──────────────────────────────────────┐
│  Kubernetesクラスタのバックアップ   │
├──────────────────────────────────────┤
│ 1. etcd（クラスタ状態）              │
│    - リソース定義（Deployment等）    │
│    - ConfigMap、Secret               │
│    - RBAC設定                        │
│                                      │
│ 2. PersistentVolume（永続データ）   │
│    - データベース                    │
│    - アプリケーションデータ          │
│    - ユーザーアップロードファイル    │
│                                      │
│ 3. アプリケーション設定              │
│    - YAMLマニフェスト                │
│    - Helmチャート                    │
│    - CI/CD設定                       │
└──────────────────────────────────────┘
```

### RPOとRTOの定義

**RPO（Recovery Point Objective）**: どの時点までのデータを復旧するか  
**RTO（Recovery Time Objective）**: どのくらいの時間で復旧するか

| サービスレベル | RPO | RTO | バックアップ頻度 |
|-------------|-----|-----|----------------|
| Critical | 15分 | 1時間 | 15分ごと |
| High | 1時間 | 4時間 | 1時間ごと |
| Medium | 1日 | 1日 | 毎日 |
| Low | 1週間 | 3日 | 毎週 |

## etcdバックアップ

### etcdの役割と重要性

**etcd**: Kubernetesの全ての状態を保存する分散KVS

```
etcdに保存されるデータ:
- 全てのリソース定義（Pods、Services等）
- ConfigMap、Secret
- RBAC設定
- クラスタの設定情報
```

**etcd喪失時の影響：**

```
❌ クラスタ全体が復旧不可能
❌ 全てのリソース定義が失われる
❌ アプリケーションの再デプロイが必要
```

### etcdctl を使った手動バックアップ

**バックアップの実行：**

```bash
# etcd Pod確認
kubectl get pods -n kube-system | grep etcd
# etcd-minikube   1/1   Running   0   10d

# バックアップ作成
kubectl exec -n kube-system etcd-minikube -- sh -c \
  "ETCDCTL_API=3 etcdctl \
  --endpoints=https://127.0.0.1:2379 \
  --cacert=/var/lib/minikube/certs/etcd/ca.crt \
  --cert=/var/lib/minikube/certs/etcd/server.crt \
  --key=/var/lib/minikube/certs/etcd/server.key \
  snapshot save /var/lib/etcd/snapshot.db"

# 出力:
# Snapshot saved at /var/lib/etcd/snapshot.db

# バックアップファイルをローカルにコピー
kubectl cp -n kube-system etcd-minikube:/var/lib/etcd/snapshot.db \
  ./etcd-backup-$(date +%Y%m%d-%H%M%S).db

# バックアップの検証
ETCDCTL_API=3 etcdctl snapshot status etcd-backup-20241208-030000.db --write-out=table
# +----------+----------+------------+------------+
# |   HASH   | REVISION | TOTAL KEYS | TOTAL SIZE |
# +----------+----------+------------+------------+
# | 12ab34cd |   123456 |       5678 |     10 MB  |
# +----------+----------+------------+------------+
```

### 自動バックアップのCronJob

```yaml
# etcd-backup-cronjob.yaml
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
              
              echo "Backup completed: ${BACKUP_NAME}"
          restartPolicy: OnFailure
```

**デプロイ：**

```bash
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

## Veleroによるアプリケーションバックアップ

### Veleroとは

**Velero**: Kubernetesリソース + PersistentVolumeのバックアップ/リストアツール

```
Veleroの機能:
✅ Namespace単位のバックアップ
✅ リソース選択的バックアップ
✅ PersistentVolumeのスナップショット
✅ スケジュールバックアップ
✅ クラスタ間移行
✅ DR（災害復旧）
```

### Veleroのインストール

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

### バックアップの作成

**全Namespaceのバックアップ：**

```bash
# 全てのリソースをバックアップ
velero backup create full-backup --wait

# バックアップ状況確認
velero backup describe full-backup

# 出力例:
# Name:         full-backup
# Namespace:    velero
# Phase:        Completed
# 
# Namespaces:
#   Included:  *
# 
# Started:    2024-12-08 03:00:00 +0000 UTC
# Completed:  2024-12-08 03:02:15 +0000 UTC
# 
# Total items to be backed up:  1234
# Items backed up:              1234
```

**特定Namespaceのバックアップ：**

```bash
# productionのみバックアップ
velero backup create production-backup \
  --include-namespaces production \
  --wait

# 確認
velero backup get
# NAME                STATUS      CREATED                         EXPIRES
# production-backup   Completed   2024-12-08 03:00:00 +0000 UTC   29d
# full-backup         Completed   2024-12-08 02:00:00 +0000 UTC   29d
```

**PersistentVolumeを含むバックアップ：**

```bash
# PVCのスナップショットも取得
velero backup create db-backup \
  --include-namespaces database \
  --snapshot-volumes=true \
  --wait

# バックアップの詳細確認
velero backup describe db-backup --details
# Persistent Volumes:
#   pvc-abc123:
#     Snapshot ID:        snap-0123456789abcdef0
#     Type:               gp3
#     Availability Zone:  ap-northeast-1a
```

### スケジュールバックアップ

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
# NAME            STATUS    CREATED                         SCHEDULE      BACKUP TTL
# daily-backup    Enabled   2024-12-08 03:00:00 +0000 UTC   0 3 * * *     720h0m0s
# hourly-backup   Enabled   2024-12-08 03:00:00 +0000 UTC   @every 1h     24h0m0s
```

### バックアップからの復元

**全体復元：**

```bash
# 最新のバックアップから復元
velero restore create --from-backup production-backup --wait

# 復元状況確認
velero restore describe production-backup-20241208030000

# ログ確認
velero restore logs production-backup-20241208030000
```

**特定Namespaceのみ復元：**

```bash
# productionのみ復元
velero restore create \
  --from-backup full-backup \
  --include-namespaces production \
  --wait
```

**別のNamespaceに復元：**

```bash
# productionからstagingに復元
velero restore create \
  --from-backup production-backup \
  --namespace-mappings production:staging \
  --wait
```

## 災害復旧（DR）計画

### DR戦略の種類

| 戦略 | RPO | RTO | コスト | 説明 |
|-----|-----|-----|--------|-----|
| Backup & Restore | 数時間 | 数時間 | 低 | 定期的にバックアップ、障害時に復元 |
| Pilot Light | 数分 | 数十分 | 中 | 最小限の環境を常時起動 |
| Warm Standby | 数秒 | 数分 | 高 | 縮小版の環境を常時起動 |
| Hot Standby | 0 | 0 | 最高 | 完全な複製環境を常時起動 |

### DR計画の策定

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
  
  recovery_procedures:
    etcd_failure:
      - step: "Identify failed etcd member"
        command: "kubectl get pods -n kube-system | grep etcd"
      
      - step: "Download latest backup"
        command: "aws s3 cp s3://my-etcd-backups/latest.db /tmp/"
      
      - step: "Restore etcd"
        command: "etcdctl snapshot restore /tmp/latest.db"
      
      - step: "Verify cluster health"
        command: "kubectl get nodes"
    
    namespace_deletion:
      - step: "List available backups"
        command: "velero backup get"
      
      - step: "Restore from backup"
        command: "velero restore create --from-backup <backup-name>"
      
      - step: "Verify restoration"
        command: "kubectl get all -n <namespace>"
  
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

### DR演習の実施

```bash
# DR演習シナリオ: Namespace削除からの復旧

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

### 定期的なバックアップテスト

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

## 実践的なバックアップ運用

### バックアップの監視

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

### コスト最適化

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

### シリーズ全体の振り返り

全15回のシリーズを通じて、Kubernetesの基礎から本番運用まで学びました：

**基礎編（第1-5回）：**
- Kubernetesの基本概念
- Pod、Deployment、Serviceの理解
- ConfigMapとSecretによる設定管理
- PersistentVolumeによる永続化

**実践編（第6-10回）：**
- StatefulSetによるステートフルアプリ
- DaemonSetとJobの活用
- RBACによるセキュリティ
- Namespaceによる環境分離
- Ingressによる外部公開

**運用編（第11-15回）：**
- Probeによるヘルスチェック
- リソース管理とQoS
- HPAによる自動スケーリング
- 監視とログ基盤
- バックアップとDR

### 今回（第15回）学んだこと

1. **etcdバックアップ**
   - etcdctlでスナップショット作成
   - CronJobで自動化
   - 復元手順の確立

2. **Veleroの活用**
   - Namespace単位のバックアップ
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
   - 定期的なテスト

### ベストプラクティス

- etcdバックアップは最低6時間ごと
- Veleroでアプリケーションレベルのバックアップ
- 定期的にリストア演習を実施
- バックアップの自動検証
- 複数リージョンへのレプリケーション

### これからのステップ

Kubernetesの基礎から本番運用まで学びましたが、学習はここで終わりではありません：

**次のステップ：**
1. 実際のプロジェクトで実践
2. CKA（Certified Kubernetes Administrator）取得
3. Kubernetes Operators開発
4. マルチクラスタ管理（Istio、Linkerd）
5. GitOps（ArgoCD、Flux）

**継続的な学習：**
- Kubernetesの最新機能を追う
- コミュニティに参加
- ブログやQiitaで知見を共有

## おわりに

全15回のシリーズをお読みいただき、ありがとうございました。このシリーズが、皆さんのKubernetes学習と実践の一助となれば幸いです。

Kubernetesは日々進化し続けています。本シリーズで学んだ基礎を土台に、これからも継続的に学び、実践し、知見を共有していきましょう。

Happy Kubernetes Learning! 🚀
