---
title: "Kubernetesを完全に理解した（第11回）- Probeでヘルスチェック"
draft: true
tags:
- kubernetes
- health-check
- liveness-probe
- readiness-probe
- reliability
description: "アプリケーションの健全性を自動監視し、問題を早期発見・自動修復する仕組みを構築。適切なプローブ設計の重要性を学びます。"
---

## はじめに - 第10回の振り返りと第11回で学ぶこと

前回の第10回では、Ingressを使ったHTTPルーティングについて学びました。複数のWebアプリケーションを一つのLoadBalancerで効率的に公開し、ホスト名やURLパスに基づいた柔軟なルーティング、そしてHTTPS/TLS対応の実装方法を理解できました。

今回の第11回では、**Probe（プローブ）を使ったヘルスチェック** について学びます。本番環境でアプリケーションを安定稼働させるために不可欠な、自動的な健全性監視と問題の早期発見・自動修復の仕組みを実践します。

本記事で学ぶ内容：

- Liveness Probe、Readiness Probe、Startup Probeの違いと使い分け
- httpGet、tcpSocket、execの実装方法
- 適切なヘルスチェック設計の原則
- タイムアウトとリトライパラメータのチューニング
- トラブルシューティングと実践パターン

## Probeの基本概念

### なぜヘルスチェックが必要なのか

アプリケーションは様々な理由で異常状態に陥ります：

```
よくある問題：
- メモリリークによるハング
- デッドロック状態
- 外部サービスへの接続失敗
- 初期化処理の遅延
- 一時的なリソース不足
```

**Probeがない場合の問題：**

```bash
# 異常なPodが動き続ける例
kubectl get pods
# NAME          READY   STATUS    RESTARTS   AGE
# myapp-abc12   1/1     Running   0          5m
# ↑ Runningだが、実際はデッドロック状態で応答なし

# トラフィックが異常なPodに送られる
curl http://myapp-service
# タイムアウト... 何も応答がない
```

**Probeを設定した場合：**

```bash
# 自動的に問題を検出・修復
kubectl get pods
# NAME          READY   STATUS    RESTARTS   AGE
# myapp-abc12   0/1     Running   1          5m
# ↑ Liveness Probeが失敗を検出し、Podを自動再起動

# 異常なPodはトラフィックから除外される
# → 正常なPodのみがリクエストを処理
```

### 3つのProbeの役割

Kubernetesには3種類のProbeがあります：

**1. Liveness Probe（生存確認）**

```yaml
目的: コンテナが生きているか確認
失敗時の動作: コンテナを再起動
使用例: デッドロック検出、ハング検出
```

**2. Readiness Probe（準備確認）**

```yaml
目的: トラフィックを受け入れる準備ができているか確認
失敗時の動作: Serviceのエンドポイントから除外（再起動はしない）
使用例: 依存サービスの接続待ち、初期化処理の完了確認
```

**3. Startup Probe（起動確認）**

```yaml
目的: コンテナが起動完了したか確認
失敗時の動作: タイムアウトまで待ち、失敗したらコンテナを再起動
使用例: 起動に時間がかかるレガシーアプリケーション
```

**Probeの実行順序：**

```
1. Pod起動
   ↓
2. Startup Probe実行（設定されている場合）
   - 成功するまでLiveness/Readiness Probeは実行されない
   ↓
3. Startup Probe成功（または設定なし）
   ↓
4. Liveness ProbeとReadiness Probeが並行実行
   - Liveness: 異常時に再起動
   - Readiness: 準備完了までトラフィック除外
```

## Liveness Probe - 生存確認

### 基本設定

```yaml
# liveness-example.yaml
apiVersion: v1
kind: Pod
metadata:
  name: liveness-demo
spec:
  containers:
  - name: app
    image: nginx:1.21
    ports:
    - containerPort: 80
    livenessProbe:
      httpGet:
        path: /healthz
        port: 80
      initialDelaySeconds: 30  # 起動後30秒待つ
      periodSeconds: 10        # 10秒ごとにチェック
      timeoutSeconds: 5        # タイムアウト5秒
      failureThreshold: 3      # 3回連続失敗で再起動
      successThreshold: 1      # 1回成功で正常
```

**デプロイと動作確認：**

```bash
kubectl apply -f liveness-example.yaml

# Pod状態を監視
kubectl get pods liveness-demo -w

# 正常時:
# NAME            READY   STATUS    RESTARTS   AGE
# liveness-demo   1/1     Running   0          1m

# Probe失敗時（アプリが異常状態になった場合）:
# liveness-demo   1/1     Running   0          5m
# liveness-demo   1/1     Running   1          5m05s  ← RESTARTS増加
```

### アプリケーション側の実装

**Go言語でのヘルスチェックエンドポイント実装：**

```go
// main.go
package main

import (
    "net/http"
    "sync/atomic"
)

var healthy int32 = 1  // 1=健全, 0=異常

func healthzHandler(w http.ResponseWriter, r *http.Request) {
    if atomic.LoadInt32(&healthy) == 1 {
        w.WriteHeader(http.StatusOK)
        w.Write([]byte("OK"))
    } else {
        w.WriteHeader(http.StatusServiceUnavailable)
        w.Write([]byte("Unhealthy"))
    }
}

// デッドロックを検出する例
func watchdog() {
    // 定期的にアプリケーションの状態をチェック
    // 異常を検出したら healthy = 0 にする
}

func main() {
    http.HandleFunc("/healthz", healthzHandler)
    http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
        w.Write([]byte("Hello, World!"))
    })
    
    go watchdog()
    http.ListenAndServe(":8080", nil)
}
```

### Liveness Probeの設計原則

**❌ 悪い例：重い処理を含む**

```go
func badHealthzHandler(w http.ResponseWriter, r *http.Request) {
    // 全データベースをスキャン（遅い！）
    rows, _ := db.Query("SELECT * FROM users")
    defer rows.Close()
    
    // 外部APIを呼ぶ（依存が増える）
    resp, _ := http.Get("https://external-api.example.com/status")
    
    w.WriteHeader(http.StatusOK)
}
```

**✅ 良い例：軽量なチェック**

```go
func goodHealthzHandler(w http.ResponseWriter, r *http.Request) {
    // 自分自身の状態のみ確認
    // 処理時間: < 10ms
    w.WriteHeader(http.StatusOK)
    w.Write([]byte("alive"))
}
```

## Readiness Probe - 準備確認

### Livenessとの違い

| 項目 | Liveness Probe | Readiness Probe |
|-----|----------------|-----------------|
| 目的 | 生きているか | 準備できているか |
| 失敗時の動作 | **再起動** | **トラフィック除外** |
| チェック内容 | 軽量（自分の状態のみ） | 重め（依存サービス含む） |
| 厳格さ | 寛容（誤検知を避ける） | 厳格（確実に準備完了を確認） |

### 基本設定

```yaml
# readiness-example.yaml
apiVersion: v1
kind: Pod
metadata:
  name: readiness-demo
spec:
  containers:
  - name: app
    image: myapp:1.0
    ports:
    - containerPort: 8080
    readinessProbe:
      httpGet:
        path: /ready
        port: 8080
      initialDelaySeconds: 5   # 起動後5秒待つ
      periodSeconds: 3         # 3秒ごとにチェック
      timeoutSeconds: 3        # タイムアウト3秒
      successThreshold: 2      # 2回連続成功で準備完了
      failureThreshold: 2      # 2回連続失敗で未準備
```

### アプリケーション側の実装

```go
// データベース接続を含む準備確認
func readyHandler(w http.ResponseWriter, r *http.Request) {
    // データベース接続確認
    ctx, cancel := context.WithTimeout(r.Context(), 2*time.Second)
    defer cancel()
    
    if err := db.PingContext(ctx); err != nil {
        w.WriteHeader(http.StatusServiceUnavailable)
        w.Write([]byte(fmt.Sprintf("DB not ready: %v", err)))
        return
    }
    
    // Redis接続確認
    if err := redisClient.Ping(ctx).Err(); err != nil {
        w.WriteHeader(http.StatusServiceUnavailable)
        w.Write([]byte(fmt.Sprintf("Redis not ready: %v", err)))
        return
    }
    
    // 全ての依存サービスが準備完了
    w.WriteHeader(http.StatusOK)
    w.Write([]byte("ready"))
}
```

### Readiness Probeの実践例

**ローリングアップデート時の無停止更新：**

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: myapp
spec:
  replicas: 3
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxUnavailable: 1
      maxSurge: 1
  template:
    spec:
      containers:
      - name: app
        image: myapp:v2.0
        readinessProbe:
          httpGet:
            path: /ready
            port: 8080
          periodSeconds: 2
          failureThreshold: 3
```

**動作の流れ：**

```
1. 新しいPod（v2.0）が起動
   ↓
2. Readiness Probeが実行される
   ↓
3. Probe成功 → ServiceのEndpointsに追加
   ↓
4. 新しいPodがトラフィックを受け始める
   ↓
5. 古いPod（v1.0）を削除
   ↓
6. 全てのPodが新バージョンに置き換わる（無停止）
```

## Startup Probe - 起動確認

### なぜStartup Probeが必要か

起動に時間がかかるアプリケーション（レガシーシステム、大量のデータ読み込みが必要なアプリなど）では、Liveness Probeだけだと問題が発生します。

**Startup Probeがない場合の問題：**

```yaml
# 悪い例：起動に2分かかるアプリ
livenessProbe:
  httpGet:
    path: /healthz
    port: 8080
  initialDelaySeconds: 120  # 2分待つしかない
  periodSeconds: 10
  failureThreshold: 3

# 問題点：
# - 起動後も2分間ヘルスチェックが始まらない
# - 起動後に異常が発生しても検出が遅れる
```

**Startup Probeを使った解決：**

```yaml
# 良い例：Startup Probeを使う
apiVersion: v1
kind: Pod
metadata:
  name: slow-startup-app
spec:
  containers:
  - name: app
    image: legacy-app:1.0
    startupProbe:
      httpGet:
        path: /startup
        port: 8080
      initialDelaySeconds: 0
      periodSeconds: 10
      failureThreshold: 30     # 最大5分待つ（10秒 × 30回）
    
    livenessProbe:
      httpGet:
        path: /healthz
        port: 8080
      initialDelaySeconds: 0   # Startup成功後すぐ開始
      periodSeconds: 10
      failureThreshold: 3
```

**動作の流れ：**

```
時刻  イベント
0:00  Pod起動
      ↓
0:00  Startup Probe開始（10秒ごと）
0:10  Startup Probe失敗（起動中...）
0:20  Startup Probe失敗（起動中...）
...
2:00  Startup Probe成功！
      ↓
2:00  Liveness Probeが有効化（即座に開始）
2:00  Readiness Probeが有効化
      ↓
2:00~ 通常運用開始
```

## Probe実装方法の選択

### httpGet - HTTP GETリクエスト（推奨）

```yaml
livenessProbe:
  httpGet:
    path: /healthz
    port: 8080
    httpHeaders:
    - name: X-Custom-Header
      value: "health-check"
    scheme: HTTP  # または HTTPS
  periodSeconds: 10
```

**メリット：**
- 標準的で実装が容易
- ステータスコードで成功/失敗を判断（200-399: 成功）
- デバッグが簡単（curlで手動テスト可能）

### tcpSocket - TCPポート接続確認

```yaml
livenessProbe:
  tcpSocket:
    port: 3306  # MySQLポート
  periodSeconds: 10
```

**メリット：**
- HTTP実装不要
- 最も軽量
- データベースやメッセージキュー向け

**デメリット：**
- ポート開放のみ確認（内部状態は不明）

### exec - コマンド実行

```yaml
livenessProbe:
  exec:
    command:
    - cat
    - /tmp/healthy
  periodSeconds: 5
```

**実用例：**

```yaml
# PostgreSQL
readinessProbe:
  exec:
    command:
    - pg_isready
    - -U
    - postgres
  periodSeconds: 5

# Redis
livenessProbe:
  exec:
    command:
    - redis-cli
    - ping
  periodSeconds: 10
```

**メリット：**
- 柔軟なチェック可能
- HTTP実装不要

**デメリット：**
- オーバーヘッドが大きい
- デバッグが難しい

## パラメータチューニング

### 重要なパラメータ

```yaml
livenessProbe:
  httpGet:
    path: /healthz
    port: 8080
  initialDelaySeconds: 30  # 起動後の待機時間
  periodSeconds: 10        # チェック間隔
  timeoutSeconds: 5        # タイムアウト
  failureThreshold: 3      # 連続失敗回数
  successThreshold: 1      # 連続成功回数（Livenessは常に1）
```

### 適切な値の決定方法

**1. initialDelaySecondsの決定：**

```bash
# アプリケーションの起動時間を計測
kubectl logs my-pod --timestamps | head -1
# 2024-12-08T03:00:00.000Z Starting application...

kubectl logs my-pod --timestamps | grep "Ready"
# 2024-12-08T03:00:25.000Z Ready to serve requests

# 起動時間: 25秒
# → initialDelaySeconds: 30 に設定（余裕を持たせる）
# または Startup Probe を使う（推奨）
```

**2. periodSecondsとfailureThresholdの決定：**

```yaml
# 検出時間の計算
failureThreshold × periodSeconds = 検出時間

例1: 早期検出
periodSeconds: 5
failureThreshold: 2
→ 10秒後に再起動（5秒 × 2回）

例2: 誤検知防止
periodSeconds: 10
failureThreshold: 3
→ 30秒後に再起動（10秒 × 3回）
```

### 完全な設定例

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: production-app
spec:
  replicas: 3
  template:
    spec:
      containers:
      - name: app
        image: myapp:v1.0
        ports:
        - containerPort: 8080
        
        # 起動プローブ（起動に時間がかかる場合）
        startupProbe:
          httpGet:
            path: /startup
            port: 8080
          initialDelaySeconds: 0
          periodSeconds: 10
          failureThreshold: 30    # 最大5分待つ
        
        # 生存プローブ
        livenessProbe:
          httpGet:
            path: /healthz
            port: 8080
          initialDelaySeconds: 0  # Startup成功後すぐ開始
          periodSeconds: 10
          timeoutSeconds: 5
          failureThreshold: 3
        
        # 準備プローブ
        readinessProbe:
          httpGet:
            path: /ready
            port: 8080
          initialDelaySeconds: 0
          periodSeconds: 5
          timeoutSeconds: 3
          failureThreshold: 2
          successThreshold: 2     # 2回連続成功で安全
        
        resources:
          requests:
            cpu: "200m"
            memory: "256Mi"
          limits:
            cpu: "500m"
            memory: "512Mi"
```

## トラブルシューティング

### よくある問題と解決策

**問題1: Podが頻繁に再起動される**

```bash
# 症状確認
kubectl get pods
# NAME          READY   STATUS    RESTARTS   AGE
# myapp-abc12   1/1     Running   15         5m  ← 高いRESTARTS

# 原因調査
kubectl describe pod myapp-abc12
# Events:
#   Warning  Unhealthy  1m  kubelet  Liveness probe failed: HTTP probe failed

# 原因: initialDelaySecondsが短すぎる
# 解決策: Startup Probeを使う、またはinitialDelaySecondsを増やす
```

**問題2: Readiness Probeが常に失敗**

```bash
# デバッグ
kubectl exec myapp-abc12 -- curl -v http://localhost:8080/ready
# * Trying 127.0.0.1:8080...
# * connect to 127.0.0.1 port 8080 failed: Connection refused

# 原因: ポート番号が間違っている
# 解決策: アプリケーションの実際のポートを確認
kubectl exec myapp-abc12 -- netstat -tlnp
```

**問題3: タイムアウトが頻発**

```yaml
# 原因: Probeエンドポイントの処理が遅い
readinessProbe:
  httpGet:
    path: /ready
    port: 8080
  timeoutSeconds: 1  # タイムアウト1秒だが処理に3秒かかる

# 解決策:
# 1. timeoutSecondsを延長
readinessProbe:
  timeoutSeconds: 5

# 2. アプリケーション側で処理を最適化
#    - キャッシュ導入
#    - 並列チェック
#    - 不要なチェック削除
```

## 実践パターン

### グレースフルシャットダウンとの連携

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: graceful-shutdown
spec:
  terminationGracePeriodSeconds: 30
  containers:
  - name: app
    image: myapp:1.0
    lifecycle:
      preStop:
        exec:
          command:
          - sh
          - -c
          - |
            # Readiness Probeを失敗させる
            touch /tmp/shutdown-in-progress
            # 既存リクエストの完了を待つ
            sleep 15
    readinessProbe:
      exec:
        command:
        - sh
        - -c
        - "[ ! -f /tmp/shutdown-in-progress ]"
      periodSeconds: 1
    livenessProbe:
      httpGet:
        path: /healthz
        port: 8080
      periodSeconds: 10
```

**動作の流れ：**

```
1. Pod削除指示
   ↓
2. preStop実行 → /tmp/shutdown-in-progress 作成
   ↓
3. Readiness Probe失敗 → Serviceから除外
   ↓
4. 15秒待機（既存リクエスト完了）
   ↓
5. SIGTERM送信
   ↓
6. アプリケーション終了
```

## まとめ

### 今回学んだこと

1. **3つのProbeの違い**
   - Liveness: 異常時に再起動
   - Readiness: 準備完了までトラフィック除外
   - Startup: 起動完了を待つ

2. **実装方法の選択**
   - httpGet: Webアプリ向け（推奨）
   - tcpSocket: データベース向け
   - exec: 柔軟なチェック

3. **設計原則**
   - Livenessは軽量に、外部依存なし
   - Readinessは依存サービス含む
   - 適切なタイムアウト設定

### ベストプラクティス

- 常にReadiness Probeを設定
- 本番環境ではStartup Probeを検討
- Probeエンドポイントは専用に実装
- タイムアウトは余裕を持って設定
- 定期的にProbe動作を監視

## 次回予告

次回の第12回では、**リソース管理の鍵** について学びます。CPU・メモリのRequestsとLimits、QoS（Quality of Service）クラス、そして効率的なクラスタリソース配分について実践します。お楽しみに！
