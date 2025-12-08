---
title: "Probeで実現するヘルスチェック - アプリケーションの可用性を守る（技術詳細）"
draft: true
tags:
- kubernetes
- health-check
- liveness-probe
- readiness-probe
- startup-probe
description: "Kubernetes Probeの完全ガイド。Liveness、Readiness、Startupプローブの違いと適切な設計方法、httpGet/tcpSocket/execの使い分けを実践的に解説。"
---

## はじめに

Kubernetesでアプリケーションを本番運用する上で、ヘルスチェックは極めて重要です。本記事では、Liveness、Readiness、Startupの3つのProbeを使った適切なヘルスチェック設計について、実践的なコード例とともに解説します。

## 1. 3つのProbeの役割と違い

### 1.1 Liveness Probe - アプリケーションの生存確認

**目的**: コンテナが生きているか（デッドロックやハングしていないか）を確認

```yaml
# liveness-example.yaml
apiVersion: v1
kind: Pod
metadata:
  name: liveness-demo
spec:
  containers:
  - name: app
    image: myapp:1.0
    livenessProbe:
      httpGet:
        path: /healthz
        port: 8080
      initialDelaySeconds: 30  # 起動後30秒待つ
      periodSeconds: 10        # 10秒ごとにチェック
      timeoutSeconds: 5        # タイムアウト5秒
      failureThreshold: 3      # 3回連続失敗で再起動
```

**動作**:
```bash
# デプロイ
kubectl apply -f liveness-example.yaml

# Probeが失敗するとPodが再起動される
kubectl get pods -w
# NAME            READY   STATUS    RESTARTS   AGE
# liveness-demo   1/1     Running   0          30s
# liveness-demo   1/1     Running   1          45s  ← 再起動カウントが増加

# イベント確認
kubectl describe pod liveness-demo
# Events:
#   Warning  Unhealthy  1m  kubelet  Liveness probe failed: HTTP probe failed with statuscode: 500
#   Normal   Killing    1m  kubelet  Container app failed liveness probe, will be restarted
```

**使用例**:
- アプリケーションのデッドロック検出
- メモリリークによるハング検出
- 内部状態の破損検出

### 1.2 Readiness Probe - トラフィック受信準備の確認

**目的**: コンテナがトラフィックを受け入れる準備ができているかを確認

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
    readinessProbe:
      httpGet:
        path: /ready
        port: 8080
      initialDelaySeconds: 5   # 起動後5秒待つ
      periodSeconds: 3         # 3秒ごとにチェック
      successThreshold: 2      # 2回連続成功でReady
      failureThreshold: 2      # 2回連続失敗でNot Ready
```

**Livenessとの違い**:

| 項目 | Liveness Probe | Readiness Probe |
|-----|----------------|-----------------|
| 失敗時の動作 | Podを**再起動** | Serviceから**除外** |
| チェック内容 | 生存確認 | トラフィック受入準備 |
| 厳格さ | より寛容 | より厳格 |

```bash
# Readiness Probe失敗時の挙動
kubectl get pods
# NAME              READY   STATUS    RESTARTS   AGE
# readiness-demo    0/1     Running   0          20s  ← READY が 0/1

# Endpointsから除外される
kubectl get endpoints my-service
# NAME         ENDPOINTS           AGE
# my-service   10.1.0.5:8080       5m  ← readiness-demoは除外されている
```

**使用例**:
- データベース接続待ち
- キャッシュのウォームアップ
- 依存サービスの起動待ち
- ローリングアップデート時のトラフィック制御

### 1.3 Startup Probe - 起動時間が長いアプリケーション用

**目的**: 起動に時間がかかるアプリケーションの初回起動を待つ

```yaml
# startup-example.yaml
apiVersion: v1
kind: Pod
metadata:
  name: startup-demo
spec:
  containers:
  - name: slow-app
    image: legacy-app:1.0  # 起動に2分かかるレガシーアプリ
    ports:
    - containerPort: 8080
    
    startupProbe:
      httpGet:
        path: /startup
        port: 8080
      initialDelaySeconds: 0
      periodSeconds: 10        # 10秒ごとにチェック
      failureThreshold: 30     # 30回 × 10秒 = 5分間待つ
    
    livenessProbe:
      httpGet:
        path: /healthz
        port: 8080
      periodSeconds: 10
      failureThreshold: 3      # startupProbe成功後に有効化
    
    readinessProbe:
      httpGet:
        path: /ready
        port: 8080
      periodSeconds: 5
```

**動作の流れ**:
```
1. Pod起動
   ↓
2. startupProbeが繰り返しチェック（最大5分）
   ↓
3. startupProbe成功
   ↓
4. livenessProbeとreadinessProbeが有効化
   ↓
5. 通常運用
```

**Startup Probe登場前の問題**:
```yaml
# 悪い例: Startup Probeがない場合
livenessProbe:
  httpGet:
    path: /healthz
    port: 8080
  initialDelaySeconds: 120  # 起動を考慮して2分待つ
  periodSeconds: 10
  failureThreshold: 3
# 問題: 起動後も2分間ヘルスチェックが開始されない
```

```yaml
# 良い例: Startup Probeを使う
startupProbe:
  httpGet:
    path: /startup
    port: 8080
  periodSeconds: 10
  failureThreshold: 12      # 最大2分待つ

livenessProbe:
  httpGet:
    path: /healthz
    port: 8080
  initialDelaySeconds: 0    # 即座に開始
  periodSeconds: 10
  failureThreshold: 3
# メリット: 起動後は即座にヘルスチェック開始
```

## 2. Probe実装方法の選択

### 2.1 httpGet - HTTP GETリクエスト（最も一般的）

```yaml
livenessProbe:
  httpGet:
    path: /healthz         # エンドポイント
    port: 8080             # ポート番号
    httpHeaders:           # カスタムヘッダー（オプション）
    - name: X-Health-Check
      value: "liveness"
    scheme: HTTP           # HTTP または HTTPS
  initialDelaySeconds: 30
  periodSeconds: 10
  timeoutSeconds: 5
```

**アプリケーション側の実装例（Go）**:

```go
// main.go
package main

import (
    "database/sql"
    "net/http"
    "time"
)

var db *sql.DB

// Liveness Probe: 基本的な生存確認
func healthzHandler(w http.ResponseWriter, r *http.Request) {
    // 軽量なチェックのみ
    w.WriteHeader(http.StatusOK)
    w.Write([]byte("OK"))
}

// Readiness Probe: 依存サービスも含めた準備確認
func readyHandler(w http.ResponseWriter, r *http.Request) {
    // データベース接続確認
    ctx, cancel := context.WithTimeout(r.Context(), 2*time.Second)
    defer cancel()
    
    if err := db.PingContext(ctx); err != nil {
        w.WriteHeader(http.StatusServiceUnavailable)
        w.Write([]byte("Database not ready"))
        return
    }
    
    // その他の依存サービス確認...
    
    w.WriteHeader(http.StatusOK)
    w.Write([]byte("Ready"))
}

// Startup Probe: 初期化完了確認
var initialized = false

func startupHandler(w http.ResponseWriter, r *http.Request) {
    if !initialized {
        w.WriteHeader(http.StatusServiceUnavailable)
        w.Write([]byte("Still initializing"))
        return
    }
    w.WriteHeader(http.StatusOK)
    w.Write([]byte("Started"))
}

func main() {
    // 初期化処理（時間がかかる）
    go func() {
        time.Sleep(60 * time.Second) // 例: 1分かかる初期化
        initialized = true
    }()
    
    http.HandleFunc("/healthz", healthzHandler)
    http.HandleFunc("/ready", readyHandler)
    http.HandleFunc("/startup", startupHandler)
    
    http.ListenAndServe(":8080", nil)
}
```

**ステータスコードの解釈**:
```
200-399: 成功
400-599: 失敗
その他: 失敗
```

### 2.2 tcpSocket - TCPポート接続確認

```yaml
livenessProbe:
  tcpSocket:
    port: 3306  # MySQLポート
  initialDelaySeconds: 15
  periodSeconds: 10
```

**使用例**:
```yaml
# データベースコンテナ
apiVersion: v1
kind: Pod
metadata:
  name: mysql-pod
spec:
  containers:
  - name: mysql
    image: mysql:8.0
    ports:
    - containerPort: 3306
    livenessProbe:
      tcpSocket:
        port: 3306
      initialDelaySeconds: 30
      periodSeconds: 10
    readinessProbe:
      exec:
        command:
        - mysqladmin
        - ping
        - -h
        - localhost
      initialDelaySeconds: 5
      periodSeconds: 5
```

**メリット**:
- HTTP実装不要
- 最も軽量
- データベースやメッセージキュー向け

**デメリット**:
- ポート開放のみ確認（内部状態は不明）

### 2.3 exec - コマンド実行

```yaml
livenessProbe:
  exec:
    command:
    - cat
    - /tmp/healthy
  initialDelaySeconds: 5
  periodSeconds: 5
```

**実用例**:

```yaml
# PostgreSQL
readinessProbe:
  exec:
    command:
    - sh
    - -c
    - pg_isready -U postgres -h localhost
  initialDelaySeconds: 5
  periodSeconds: 5

# Redis
livenessProbe:
  exec:
    command:
    - redis-cli
    - ping
  periodSeconds: 10

# カスタムスクリプト
livenessProbe:
  exec:
    command:
    - /bin/sh
    - -c
    - /app/scripts/health_check.sh
  periodSeconds: 10
  timeoutSeconds: 5
```

**health_check.shの例**:
```bash
#!/bin/bash
# 複雑なヘルスチェックロジック

# メモリ使用率チェック
MEMORY_USAGE=$(free | grep Mem | awk '{print ($3/$2) * 100.0}')
if (( $(echo "$MEMORY_USAGE > 90" | bc -l) )); then
    echo "Memory usage too high: $MEMORY_USAGE%"
    exit 1
fi

# ディスク容量チェック
DISK_USAGE=$(df -h /data | tail -1 | awk '{print $5}' | sed 's/%//')
if [ "$DISK_USAGE" -gt 85 ]; then
    echo "Disk usage too high: $DISK_USAGE%"
    exit 1
fi

# プロセス確認
if ! pgrep -f myapp > /dev/null; then
    echo "Application process not found"
    exit 1
fi

echo "Health check passed"
exit 0
```

**メリット**:
- 柔軟なチェック可能
- HTTP実装不要

**デメリット**:
- オーバーヘッドが大きい
- デバッグが難しい

### 2.4 実装方法の選択ガイド

| 状況 | 推奨実装 | 理由 |
|-----|---------|-----|
| Webアプリケーション | httpGet | 標準的、実装容易 |
| データベース | tcpSocket + exec | ポート確認とクエリ実行 |
| メッセージキュー | tcpSocket | 軽量で十分 |
| バッチ処理 | exec | プロセス状態確認 |
| レガシーアプリ | exec | 既存スクリプト活用 |

## 3. 適切なヘルスチェック設計

### 3.1 Liveness Probeの設計原則

**原則1: 軽量に保つ**
```go
// 悪い例: 重い処理を含む
func badHealthzHandler(w http.ResponseWriter, r *http.Request) {
    // 全データベースレコードをスキャン（遅い！）
    rows, err := db.Query("SELECT * FROM users")
    if err != nil {
        w.WriteHeader(500)
        return
    }
    defer rows.Close()
    
    // 複雑な計算
    for rows.Next() {
        // ...
    }
    w.WriteHeader(200)
}

// 良い例: 最小限のチェック
func goodHealthzHandler(w http.ResponseWriter, r *http.Request) {
    // 単純な生存確認のみ
    w.WriteHeader(http.StatusOK)
    w.Write([]byte("alive"))
}
```

**原則2: 外部依存を含めない**
```go
// 悪い例: 外部APIを呼ぶ
func badHealthzHandler(w http.ResponseWriter, r *http.Request) {
    // 外部API呼び出し（NGパターン）
    resp, err := http.Get("https://external-api.example.com/status")
    if err != nil || resp.StatusCode != 200 {
        w.WriteHeader(500) // 外部サービスの問題で自Podが再起動される
        return
    }
    w.WriteHeader(200)
}

// 良い例: 自分自身の状態のみ
func goodHealthzHandler(w http.ResponseWriter, r *http.Request) {
    // 自プロセスの健全性のみ確認
    if appState.IsDeadlocked() {
        w.WriteHeader(500)
        return
    }
    w.WriteHeader(200)
}
```

### 3.2 Readiness Probeの設計原則

**原則1: 依存サービスを含める**
```go
func readyHandler(w http.ResponseWriter, r *http.Request) {
    // データベース確認
    if err := checkDatabase(); err != nil {
        w.WriteHeader(503)
        w.Write([]byte(fmt.Sprintf("DB not ready: %v", err)))
        return
    }
    
    // Redis確認
    if err := checkRedis(); err != nil {
        w.WriteHeader(503)
        w.Write([]byte(fmt.Sprintf("Redis not ready: %v", err)))
        return
    }
    
    // 必須の外部API確認
    if err := checkCriticalAPI(); err != nil {
        w.WriteHeader(503)
        w.Write([]byte(fmt.Sprintf("Critical API not ready: %v", err)))
        return
    }
    
    w.WriteHeader(200)
    w.Write([]byte("ready"))
}

func checkDatabase() error {
    ctx, cancel := context.WithTimeout(context.Background(), 2*time.Second)
    defer cancel()
    return db.PingContext(ctx)
}
```

**原則2: タイムアウトを適切に設定**
```yaml
readinessProbe:
  httpGet:
    path: /ready
    port: 8080
  initialDelaySeconds: 5
  periodSeconds: 5
  timeoutSeconds: 3      # Probe自体のタイムアウト
  successThreshold: 1    # 1回成功でReady
  failureThreshold: 3    # 3回連続失敗でNot Ready
```

### 3.3 パラメータチューニング

#### initialDelaySeconds の決定

```yaml
# 計測してから設定
# 1. Podの起動時間を計測
kubectl logs my-pod --timestamps | head -1
# 2024-12-08T03:00:00.123456Z Starting application...

kubectl logs my-pod --timestamps | grep "Ready to serve"
# 2024-12-08T03:00:25.789012Z Ready to serve requests

# 起動に約26秒 → initialDelaySeconds: 30 に設定
```

#### periodSeconds の決定

```yaml
# 目標復旧時間と検出時間のバランス
livenessProbe:
  periodSeconds: 10
  failureThreshold: 3
# 検出時間 = 10秒 × 3回 = 30秒後に再起動

# より早く検出したい場合
livenessProbe:
  periodSeconds: 5
  failureThreshold: 2
# 検出時間 = 5秒 × 2回 = 10秒後に再起動
```

#### 完全な設定例

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
        
        # 起動プローブ（レガシーアプリ向け）
        startupProbe:
          httpGet:
            path: /startup
            port: 8080
          initialDelaySeconds: 0
          periodSeconds: 10
          failureThreshold: 30    # 最大5分待つ
          successThreshold: 1
        
        # 生存プローブ
        livenessProbe:
          httpGet:
            path: /healthz
            port: 8080
            httpHeaders:
            - name: X-Probe-Type
              value: "liveness"
          initialDelaySeconds: 0  # startupProbe後すぐ開始
          periodSeconds: 10
          timeoutSeconds: 5
          failureThreshold: 3
          successThreshold: 1
        
        # 準備確認プローブ
        readinessProbe:
          httpGet:
            path: /ready
            port: 8080
            httpHeaders:
            - name: X-Probe-Type
              value: "readiness"
          initialDelaySeconds: 0
          periodSeconds: 5
          timeoutSeconds: 3
          failureThreshold: 2     # より厳格
          successThreshold: 2     # 2回連続成功で安全
```

## 4. 実践的なパターン

### 4.1 データベース接続待ちパターン

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: app-with-db
spec:
  containers:
  - name: app
    image: myapp:1.0
    env:
    - name: DB_HOST
      value: mysql-service
    readinessProbe:
      exec:
        command:
        - sh
        - -c
        - |
          nc -z ${DB_HOST} 3306 && \
          curl -f http://localhost:8080/ready
      initialDelaySeconds: 5
      periodSeconds: 5
```

### 4.2 グレースフルシャットダウンとの連携

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: graceful-shutdown
spec:
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
  terminationGracePeriodSeconds: 30
```

**動作の流れ**:
```
1. Pod削除指示
   ↓
2. preStop実行 → /tmp/shutdown-in-progress 作成
   ↓
3. Readiness Probe失敗 → Serviceから除外（新規トラフィック停止）
   ↓
4. 15秒待機（既存リクエスト完了）
   ↓
5. SIGTERM送信
   ↓
6. アプリケーション終了
```

### 4.3 複数コンテナのProbe設計

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: multi-container
spec:
  containers:
  # メインアプリケーション
  - name: app
    image: myapp:1.0
    ports:
    - containerPort: 8080
    readinessProbe:
      httpGet:
        path: /ready
        port: 8080
      periodSeconds: 5
    livenessProbe:
      httpGet:
        path: /healthz
        port: 8080
      periodSeconds: 10
  
  # サイドカー: ログ転送
  - name: log-forwarder
    image: fluentd:v1.0
    livenessProbe:
      exec:
        command:
        - pgrep
        - -f
        - fluentd
      periodSeconds: 30
  
  # サイドカー: メトリクス収集
  - name: metrics
    image: prometheus-exporter:v1.0
    ports:
    - containerPort: 9090
    livenessProbe:
      httpGet:
        path: /metrics
        port: 9090
      periodSeconds: 10
```

## 5. トラブルシューティング

### 5.1 Probe失敗の原因調査

```bash
# イベント確認
kubectl describe pod my-pod
# Events:
#   Warning  Unhealthy  2m  kubelet  Liveness probe failed: Get "http://10.1.0.5:8080/healthz": dial tcp 10.1.0.5:8080: connect: connection refused

# ログ確認
kubectl logs my-pod

# 手動でProbeを実行
kubectl exec my-pod -- curl http://localhost:8080/healthz

# タイムアウト確認
kubectl exec my-pod -- time curl http://localhost:8080/ready
# real    0m3.456s  ← 3.4秒かかっている

# Probeのタイムアウトが3秒なら失敗する
```

### 5.2 よくある問題と解決策

**問題1: Podが頻繁に再起動される**

```yaml
# 原因: initialDelaySecondsが短すぎる
livenessProbe:
  httpGet:
    path: /healthz
    port: 8080
  initialDelaySeconds: 5  # アプリ起動に20秒かかるのに5秒
  periodSeconds: 10
  failureThreshold: 3

# 解決策1: initialDelaySecondsを増やす
livenessProbe:
  initialDelaySeconds: 30  # 十分な余裕を持たせる

# 解決策2: startupProbeを使う（推奨）
startupProbe:
  httpGet:
    path: /startup
    port: 8080
  periodSeconds: 10
  failureThreshold: 6  # 60秒待つ

livenessProbe:
  httpGet:
    path: /healthz
    port: 8080
  initialDelaySeconds: 0
  periodSeconds: 10
```

**問題2: Readiness Probeが常に失敗**

```bash
# デバッグ
kubectl exec my-pod -- curl -v http://localhost:8080/ready
# * Trying 127.0.0.1:8080...
# * connect to 127.0.0.1 port 8080 failed: Connection refused

# ポート確認
kubectl exec my-pod -- netstat -tlnp
# Proto  Local Address   State       PID/Program name
# tcp    0.0.0.0:3000    LISTEN      1/node

# 原因: ポート番号が間違っている（8080→3000）
```

**問題3: タイムアウトが頻発**

```yaml
# 原因: Probeエンドポイントが重い処理をしている
readinessProbe:
  httpGet:
    path: /ready
    port: 8080
  timeoutSeconds: 1  # タイムアウト1秒だが、処理に3秒かかる

# 解決策: タイムアウトを増やす & 処理を軽量化
readinessProbe:
  timeoutSeconds: 5  # タイムアウトを延長

# アプリ側で処理を最適化
# - キャッシュ導入
# - 並列チェック
# - 不要なチェック削除
```

## まとめ

### 学んだこと

1. **3つのProbeの違い**
   - Liveness: 再起動すべきか判断
   - Readiness: トラフィック受入可否判断
   - Startup: 起動完了を待つ

2. **実装方法の選択**
   - httpGet: Webアプリ向け（推奨）
   - tcpSocket: データベース向け
   - exec: 柔軟なチェック

3. **設計原則**
   - Livenessは軽量に、外部依存なし
   - Readinessは依存サービス含む
   - 適切なタイムアウト設定

4. **パラメータチューニング**
   - initialDelaySecondsは計測して決定
   - periodSecondsは検出時間と負荷のバランス
   - failureThresholdは誤検知防止

### ベストプラクティス

- 常にReadiness Probeを設定
- 本番環境ではStartup Probeを検討
- Probeエンドポイントは専用に実装
- タイムアウトは余裕を持って設定
- 定期的にProbe動作を監視

## 参考リンク

- {{< linkcard "https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/" >}}
- {{< linkcard "https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle/" >}}
