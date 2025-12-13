---
title: "Podの生と死 - コンテナオーケストレーションの基本概念(技術詳細)"
draft: true
tags:
- kubernetes
- pod
- kubectl
- yaml
- basics
description: "Kubernetesの最小単位であるPodの概念を徹底解説。kubectlコマンドの実践的な使い方、Podのライフサイクル、障害時の挙動、YAMLマニフェストの書き方まで完全網羅。"
---

## はじめに

本記事では、Kubernetesの最も基本的で重要な概念である**Pod**について、徹底的に深掘りします。Podとは何か、なぜコンテナではなくPodという単位が必要なのか、Podのライフサイクル、kubectlでの操作方法、YAMLマニフェストの書き方、そして障害時の挙動まで、実践的なコマンド例とともに解説します。

## 1. Podとは何か

### 1.1 Podの定義 - コンテナとの決定的な違い

**Pod**は、Kubernetesにおける**最小のデプロイ可能な単位**です。重要なポイント:

- ❌ Kubernetes = コンテナを管理するシステム
- ✅ Kubernetes = **Podを管理するシステム**
- ✅ Pod = **1つ以上のコンテナを含むグループ**

```yaml
# シングルコンテナPod(最も一般的)
apiVersion: v1
kind: Pod
metadata:
  name: simple-nginx
spec:
  containers:
  - name: nginx
    image: nginx:1.25-alpine
```

### 1.2 なぜPodという単位が必要なのか

#### 理由1: 密結合なコンテナのグループ化

```yaml
# Webアプリ + ログ収集サイドカー
apiVersion: v1
kind: Pod
metadata:
  name: web-with-sidecar
spec:
  containers:
  - name: nginx          # メインコンテナ
    image: nginx:1.25-alpine
    volumeMounts:
    - name: logs
      mountPath: /var/log/nginx
      
  - name: log-shipper   # サイドカー
    image: fluent/fluentd:v1.16-1
    volumeMounts:
    - name: logs
      mountPath: /var/log/nginx
      readOnly: true
      
  volumes:
  - name: logs
    emptyDir: {}
```

#### 理由2: ネットワーク名前空間の共有

Pod内のコンテナは:
- 同じIPアドレスを共有
- `localhost`で相互通信可能

```bash
# nginxコンテナからapp-serverにアクセス
kubectl exec web-pod -c nginx -- curl http://localhost:8080
```

### 1.3 マルチコンテナPodの実践パターン

**サイドカーパターン**: メインコンテナを補助
**アンバサダーパターン**: 外部サービスへのプロキシ
**アダプターパターン**: 出力を標準化

## 2. Podのライフサイクル

### 2.1 Podのフェーズ

| フェーズ | 意味 |
|---------|------|
| `Pending` | イメージpull中、スケジューリング待ち |
| `Running` | 少なくとも1つのコンテナが実行中 |
| `Succeeded` | 全コンテナが正常終了 |
| `Failed` | 少なくとも1つが失敗終了 |
| `Unknown` | 状態を取得できない |

```bash
# リアルタイムでフェーズ遷移を観察
kubectl get pods -w

# 別のターミナルで
kubectl apply -f nginx-pod.yaml

# 出力:
# NAME        STATUS              AGE
# nginx-pod   Pending             0s
# nginx-pod   ContainerCreating   1s
# nginx-pod   Running             3s
```

### 2.2 コンテナの状態

- `Waiting`: 起動準備中
- `Running`: 実行中
- `Terminated`: 終了済み

```bash
# コンテナ状態の確認
kubectl describe pod my-pod
```

## 3. kubectl基本コマンド

### 3.1 kubectl get pods

```bash
# 基本形
kubectl get pods

# 詳細表示(-o wide)
kubectl get pods -o wide
# IP, ノード名も表示

# YAML形式で取得
kubectl get pod nginx-pod -o yaml

# リアルタイム監視
kubectl get pods -w

# ラベルでフィルタ
kubectl get pods -l app=nginx

# 全Namespace
kubectl get pods -A
```

### 3.2 kubectl describe pod

トラブルシューティングに最重要!

```bash
kubectl describe pod nginx-pod
```

重要セクション:
- **Events**: 問題のほとんどはここに記録
- **State**: コンテナの現在状態
- **Restart Count**: 再起動回数(多いと問題)

### 3.3 kubectl logs

```bash
# 基本形
kubectl logs nginx-pod

# リアルタイム追跡
kubectl logs -f nginx-pod

# 前回のログ(再起動時)
kubectl logs nginx-pod --previous

# マルチコンテナ時はコンテナ指定
kubectl logs multi-pod -c nginx

# 最新50行のみ
kubectl logs --tail=50 nginx-pod

# タイムスタンプ付き
kubectl logs --timestamps nginx-pod
```

### 3.4 kubectl exec

```bash
# インタラクティブシェル
kubectl exec -it nginx-pod -- sh

# 1行コマンド実行
kubectl exec nginx-pod -- ls -la /usr/share/nginx/html

# デバッグ例
kubectl exec nginx-pod -- ping -c 3 8.8.8.8
kubectl exec nginx-pod -- ps aux
kubectl exec nginx-pod -- env
```

## 4. YAMLマニフェストの書き方

### 4.1 必須フィールド

```yaml
apiVersion: v1      # APIバージョン
kind: Pod           # リソース種類
metadata:           # メタデータ
  name: my-pod
spec:               # 仕様
  containers:
  - name: nginx
    image: nginx:1.25
```

### 4.2 完全な実践例

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: production-app
  namespace: production
  labels:
    app: webapp
    tier: frontend
    version: v1.0
  annotations:
    description: "Production web application"
    
spec:
  # 再起動ポリシー
  restartPolicy: Always  # Always|OnFailure|Never
  
  containers:
  - name: webapp
    image: myapp:v1.0
    imagePullPolicy: IfNotPresent
    
    # ポート定義
    ports:
    - name: http
      containerPort: 8080
      protocol: TCP
      
    # 環境変数
    env:
    - name: ENV
      value: "production"
    - name: DB_HOST
      valueFrom:
        configMapKeyRef:
          name: app-config
          key: database.host
    - name: DB_PASSWORD
      valueFrom:
        secretKeyRef:
          name: db-secret
          key: password
          
    # リソース制限(本番環境では必須!)
    resources:
      requests:
        memory: "256Mi"
        cpu: "500m"
      limits:
        memory: "512Mi"
        cpu: "1000m"
        
    # Liveness Probe
    livenessProbe:
      httpGet:
        path: /health
        port: 8080
      initialDelaySeconds: 30
      periodSeconds: 10
      
    # Readiness Probe
    readinessProbe:
      httpGet:
        path: /ready
        port: 8080
      initialDelaySeconds: 10
      periodSeconds: 5
      
    # ボリュームマウント
    volumeMounts:
    - name: app-logs
      mountPath: /var/log/app
      
  volumes:
  - name: app-logs
    emptyDir:
      sizeLimit: 1Gi
```

## 5. Podの障害と挙動

### 5.1 kubectl deleteしたときの挙動

```
1. kubectl delete pod 実行
2. STATUS が Terminating に変更
3. SIGTERMシグナル送信
4. 猶予期間(30秒)待つ
5. SIGKILL で強制終了
6. Pod削除完了
```

### 5.2 再起動ポリシー

#### restartPolicy: Always (デフォルト)

```yaml
spec:
  restartPolicy: Always  # 常に再起動
```

クラッシュすると何度でも再起動。`CrashLoopBackOff`になることも。

#### restartPolicy: OnFailure

```yaml
spec:
  restartPolicy: OnFailure  # 失敗時のみ
```

- `exit 0`: 再起動しない (Completed)
- `exit 1`: 再起動する

#### restartPolicy: Never

```yaml
spec:
  restartPolicy: Never  # 絶対に再起動しない
```

失敗しても`Error`のまま。

### 5.3 ImagePullBackOff

原因:
1. **イメージ名が間違っている**
2. **プライベートレジストリの認証不足**
3. **ネットワーク問題**

```bash
# 詳細確認
kubectl describe pod image-error-pod

# Events:
#   Warning  Failed  Failed to pull image "ngins:latest"
```

対処法:
```yaml
# シークレット作成
kubectl create secret docker-registry my-registry-secret   --docker-server=myregistry.example.com   --docker-username=user   --docker-password=pass

# Pod で指定
spec:
  imagePullSecrets:
  - name: my-registry-secret
```

### 5.4 CrashLoopBackOff

繰り返しクラッシュしている状態。

原因:
1. **アプリケーションエラー**
2. **設定ミス**(環境変数など)
3. **Liveness Probeの設定ミス**

```bash
# ログ確認
kubectl logs crashloop-pod
kubectl logs crashloop-pod --previous

# describe で詳細確認
kubectl describe pod crashloop-pod

# Events:
#   Warning  BackOff  Back-off restarting failed container
```

## 6. 初心者がつまづきやすいポイント

### 6.1 Podとコンテナの混同

❌ 間違い: "コンテナを作成する"
✅ 正しい: "Podを作成する(その中にコンテナが含まれる)"

### 6.2 YAMLのインデントエラー

YAMLは**インデント**が命!

```yaml
# ❌ 間違い(インデント不正)
spec:
containers:   # ←インデントが足りない
- name: nginx
  image: nginx:1.25

# ✅ 正しい
spec:
  containers:  # ←2スペースインデント
  - name: nginx
    image: nginx:1.25
```

### 6.3 イメージタグの理解 - `latest`の罠

```yaml
# ❌ 避けるべき
image: nginx:latest

# ✅ 推奨
image: nginx:1.25-alpine
```

`latest`の問題:
- 常に最新版を取得→予期しない動作変更
- 再現性がない
- ロールバックが困難

### 6.4 リソース制限の未設定

```yaml
# ❌ リソース制限なし(本番環境では危険!)
spec:
  containers:
  - name: app
    image: myapp:1.0
    # resources: なし

# ✅ 適切に設定
spec:
  containers:
  - name: app
    image: myapp:1.0
    resources:
      requests:
        memory: "256Mi"
        cpu: "500m"
      limits:
        memory: "512Mi"
        cpu: "1000m"
```

### 6.5 Liveness vs Readiness Probeの混同

- **Liveness Probe**: 生きているか? → 失敗で**再起動**
- **Readiness Probe**: 準備完了か? → 失敗で**Serviceから除外**

```yaml
# 起動が遅いアプリには startupProbe も
startupProbe:
  httpGet:
    path: /health
    port: 8080
  periodSeconds: 5
  failureThreshold: 30  # 最大150秒待つ
```

## まとめ

この記事で学んだこと:

1. **Podとは**: Kubernetesの最小単位、コンテナのグループ
2. **Podライフサイクル**: Pending→Running→Succeeded/Failed
3. **kubectlコマンド**: get, describe, logs, exec
4. **YAMLマニフェスト**: 必須フィールドと実践的な設定
5. **障害と挙動**: ImagePullBackOff, CrashLoopBackOff
6. **つまづきポイント**: インデント、latest、リソース制限

## 次のステップ

次回の記事「アプリケーションを守るReplicaSet - 自動復旧の仕組み」では:

- なぜPod単体では不十分なのか
- ReplicaSetによる冗長化
- Podが死んだときの自動復旧
- セレクタとラベルの活用

を学習します。

## 参考リンク

{{< linkcard "https://kubernetes.io/docs/concepts/workloads/pods/" >}}
{{< linkcard "https://kubernetes.io/docs/reference/kubectl/cheatsheet/" >}}
