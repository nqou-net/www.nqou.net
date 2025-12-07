---
title: "Kubernetesを完全に理解した（第2回）- Podの生と死を理解する"
draft: true
tags:
- kubernetes
- pod
- kubectl
- yaml
- basics
description: "Kubernetesの最小単位であるPodの概念を徹底的に学習。kubectlを使った基本操作をハンズオンで習得します。"
---

## はじめに - 第1回の振り返りと第2回で学ぶこと

前回の記事では、従来の単一サーバー構成の課題を理解し、Dockerの基礎を学び、minikubeを使って初めてのPodをデプロイしました。

**第1回のおさらい:**

- 単一サーバー構成の限界（スケーリング、障害、デプロイの複雑さ）
- Dockerコンテナによる環境の一貫性
- minikubeでのローカルKubernetes環境構築
- 最もシンプルなnginx Podのデプロイ

第2回となる本記事では、Kubernetesの心臓部である**Pod**について、より深く掘り下げていきます。

**この記事で学ぶこと:**

- Podとコンテナの決定的な違い
- マルチコンテナPodの実践パターン
- Podのライフサイクルとフェーズ遷移
- kubectlコマンドの実践的な使い方
- YAMLマニフェストの段階的な書き方
- Podの障害時の挙動とトラブルシューティング

それでは、Podの世界へ深く潜っていきましょう！

## Podとは何か - コンテナとの決定的な違い

### Podの定義

**Pod**は、Kubernetesにおける**最小のデプロイ可能な単位**です。ここで重要なポイントがあります：

- ❌ Kubernetes = コンテナを管理するシステム
- ✅ Kubernetes = **Podを管理するシステム**
- ✅ Pod = **1つ以上のコンテナを含むグループ**

多くの初心者が「Kubernetesはコンテナを管理する」と考えがちですが、これは正確ではありません。Kubernetesは直接コンテナを扱うのではなく、**Pod**という抽象化された単位を通じてコンテナを管理します。

### シングルコンテナPod - 最も一般的なパターン

実際には、ほとんどのPodは1つのコンテナのみを含みます：

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: simple-nginx
spec:
  containers:
  - name: nginx
    image: nginx:1.25-alpine
```

このシンプルな構成でも、Podという単位を経由することで、後述する様々なKubernetesの機能を活用できます。

### なぜPodという単位が必要なのか

#### 理由1: 密結合なコンテナのグループ化

実際のアプリケーションでは、複数のコンテナが密接に連携して動作する必要があるケースがあります。

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
      
  - name: log-shipper   # サイドカーコンテナ
    image: fluent/fluentd:v1.16-1
    volumeMounts:
    - name: logs
      mountPath: /var/log/nginx
      readOnly: true
      
  volumes:
  - name: logs
    emptyDir: {}
```

この例では、nginxのログファイルを共有ボリューム経由でfluentdが収集し、外部のログ集約システムに送信します。

#### 理由2: ネットワーク名前空間の共有

Pod内のコンテナは同じネットワーク名前空間を共有します：

- 同じIPアドレスを持つ
- `localhost`で相互通信が可能
- ポート番号の競合に注意が必要

```bash
# nginxコンテナからapp-serverにlocalhostでアクセス可能
kubectl exec web-pod -c nginx -- curl http://localhost:8080
```

これにより、マイクロサービス間の通信が簡単になります。

### マルチコンテナPodの実践パターン

マルチコンテナPodには、以下の代表的なデザインパターンがあります：

#### サイドカーパターン

メインコンテナを補助するコンテナを追加します。

**用途例:**
- ログ収集
- メトリクス収集
- 設定ファイルの動的更新

#### アンバサダーパターン

外部サービスへのプロキシとして機能するコンテナを追加します。

**用途例:**
- データベースプロキシ
- キャッシュプロキシ
- ロードバランシング

#### アダプターパターン

メインコンテナの出力を標準化するコンテナを追加します。

**用途例:**
- ログフォーマットの変換
- メトリクスの正規化
- APIレスポンスの変換

## Podのライフサイクル - フェーズと状態遷移

### Podのフェーズ

Podは以下の5つのフェーズを持ちます：

| フェーズ | 意味 |
|---------|------|
| `Pending` | イメージpull中、またはスケジューリング待ち |
| `Running` | 少なくとも1つのコンテナが実行中 |
| `Succeeded` | 全コンテナが正常終了（再起動しない） |
| `Failed` | 少なくとも1つのコンテナが失敗終了 |
| `Unknown` | Podの状態を取得できない（ノードとの通信失敗等） |

### リアルタイムでフェーズ遷移を観察

実際にPodのフェーズ遷移を観察してみましょう：

```bash
# ターミナル1: リアルタイムでPodを監視
kubectl get pods -w

# ターミナル2: 新しいPodを作成
kubectl run nginx --image=nginx:1.25-alpine

# ターミナル1の出力例:
# NAME    READY   STATUS              RESTARTS   AGE
# nginx   0/1     Pending             0          0s
# nginx   0/1     ContainerCreating   0          1s
# nginx   1/1     Running             0          3s
```

`-w`（watch）オプションを使うと、リアルタイムで状態変化を追跡できます。

### コンテナの状態

Pod全体のフェーズとは別に、各コンテナは以下の3つの状態を持ちます：

- `Waiting`: 起動準備中（イメージのpull、ボリュームのマウント待ち等）
- `Running`: 正常に実行中
- `Terminated`: 終了済み（正常または異常）

```bash
# コンテナの詳細な状態を確認
kubectl describe pod nginx

# 出力例（抜粋）:
# Containers:
#   nginx:
#     State:          Running
#       Started:      Sun, 08 Dec 2025 10:00:05 +0000
#     Ready:          True
#     Restart Count:  0
```

## kubectl基本コマンド - 実践的な使い方

### kubectl get pods - Podの一覧表示

```bash
# 基本形: 現在のNamespaceのPod一覧
kubectl get pods

# 詳細表示（IPアドレス、ノード名も表示）
kubectl get pods -o wide
# 出力例:
# NAME    READY   STATUS    RESTARTS   AGE   IP           NODE       NOMINATED NODE   READINESS GATES
# nginx   1/1     Running   0          5m    10.244.0.5   minikube   <none>           <none>

# YAML形式で取得（全ての設定情報を確認）
kubectl get pod nginx -o yaml

# JSON形式で取得
kubectl get pod nginx -o json

# リアルタイム監視（変更をリアルタイムで表示）
kubectl get pods -w

# ラベルでフィルタリング
kubectl get pods -l app=nginx
kubectl get pods -l tier=frontend,version=v1.0

# 全NamespaceのPod一覧
kubectl get pods -A
# または
kubectl get pods --all-namespaces

# 特定のNamespaceのPod
kubectl get pods -n kube-system
```

### kubectl describe pod - トラブルシューティングに最重要

`describe`コマンドは、トラブルシューティングで最も重要なコマンドです：

```bash
kubectl describe pod nginx

# 出力例（重要セクション抜粋）:
# Name:             nginx
# Namespace:        default
# Node:             minikube/192.168.49.2
# Labels:           run=nginx
# Status:           Running
# IP:               10.244.0.5
# 
# Containers:
#   nginx:
#     Container ID:   docker://abc123...
#     Image:          nginx:1.25-alpine
#     State:          Running
#     Ready:          True
#     Restart Count:  0
# 
# Events:  # ← ★最も重要！問題のほとんどはここに記録される
#   Type    Reason     Age   From               Message
#   ----    ------     ----  ----               -------
#   Normal  Scheduled  5m    default-scheduler  Successfully assigned default/nginx to minikube
#   Normal  Pulling    5m    kubelet            Pulling image "nginx:1.25-alpine"
#   Normal  Pulled     4m    kubelet            Successfully pulled image
#   Normal  Created    4m    kubelet            Created container nginx
#   Normal  Started    4m    kubelet            Started container nginx
```

**重要セクション:**
- **Events**: エラーやワーニングが時系列で記録される
- **State**: コンテナの現在の状態
- **Restart Count**: 再起動回数（多い場合は問題あり）

### kubectl logs - ログの確認

```bash
# 基本形
kubectl logs nginx

# リアルタイムでログを追跡（tail -f相当）
kubectl logs -f nginx

# 前回起動時のログ（再起動した場合に重要）
kubectl logs nginx --previous

# マルチコンテナPodの場合はコンテナを指定
kubectl logs web-pod -c nginx
kubectl logs web-pod -c log-shipper

# 最新50行のみ表示
kubectl logs --tail=50 nginx

# タイムスタンプ付きで表示
kubectl logs --timestamps nginx

# 特定時間以降のログ（過去1時間）
kubectl logs --since=1h nginx

# 複数のPodのログを同時に表示（ラベル指定）
kubectl logs -l app=nginx --all-containers=true
```

### kubectl exec - Pod内でコマンド実行

```bash
# インタラクティブシェルに接続
kubectl exec -it nginx -- sh
# または bash が使える場合
kubectl exec -it nginx -- bash

# 1行コマンド実行
kubectl exec nginx -- ls -la /usr/share/nginx/html
kubectl exec nginx -- nginx -v
kubectl exec nginx -- cat /etc/nginx/nginx.conf

# デバッグ例
kubectl exec nginx -- ping -c 3 8.8.8.8
kubectl exec nginx -- ps aux
kubectl exec nginx -- env
kubectl exec nginx -- df -h
kubectl exec nginx -- netstat -tulpn

# マルチコンテナPodの場合
kubectl exec -it web-pod -c nginx -- sh
```

### その他の便利なkubectlコマンド

```bash
# Pod削除
kubectl delete pod nginx

# マニフェストファイルからPod作成
kubectl apply -f nginx-pod.yaml

# マニフェストファイルからPod削除
kubectl delete -f nginx-pod.yaml

# 強制削除（応答しない場合）
kubectl delete pod nginx --force --grace-period=0

# Podの編集（エディタが開く）
kubectl edit pod nginx

# Podをファイルに保存
kubectl get pod nginx -o yaml > nginx-backup.yaml

# port-forward（ローカルからPodへアクセス）
kubectl port-forward nginx 8080:80

# ラベルの追加
kubectl label pod nginx env=production

# ラベルの削除
kubectl label pod nginx env-
```

## YAMLマニフェスト - Podの完全な定義

### 必須フィールド

Podマニフェストには以下の4つのフィールドが必須です：

```yaml
apiVersion: v1      # APIバージョン（Podはv1）
kind: Pod           # リソースの種類
metadata:           # メタデータ
  name: my-pod      # Pod名（必須）
spec:               # Podの仕様
  containers:       # コンテナのリスト（必須）
  - name: nginx     # コンテナ名（必須）
    image: nginx:1.25  # イメージ（必須）
```

### シンプルな実用例

まずは、最小限の設定から始めましょう：

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: simple-nginx
  labels:
    app: nginx
spec:
  containers:
  - name: nginx
    image: nginx:1.25-alpine
    ports:
    - containerPort: 80
```

### より実践的な例

実際の運用を想定した設定例：

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: webapp-pod
  namespace: default
  labels:
    app: webapp
    tier: frontend
    version: v1.0
  annotations:
    description: "Production web application"
    
spec:
  # 再起動ポリシー
  restartPolicy: Always  # Always | OnFailure | Never
  
  containers:
  - name: webapp
    image: nginx:1.25-alpine
    imagePullPolicy: IfNotPresent  # Always | IfNotPresent | Never
    
    # ポート定義
    ports:
    - name: http
      containerPort: 80
      protocol: TCP
      
    # 環境変数
    env:
    - name: ENV
      value: "production"
    - name: LOG_LEVEL
      value: "info"
      
    # リソース制限（本番環境では必須！）
    resources:
      requests:
        memory: "128Mi"
        cpu: "100m"
      limits:
        memory: "256Mi"
        cpu: "200m"
```

### 本番環境向けの完全な例

本番環境で使用する完全な設定例：

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
    environment: production
  annotations:
    description: "Production web application"
    owner: "platform-team"
    
spec:
  restartPolicy: Always
  
  containers:
  - name: webapp
    image: myregistry.example.com/webapp:v1.0.0
    imagePullPolicy: IfNotPresent
    
    ports:
    - name: http
      containerPort: 8080
      protocol: TCP
      
    # 環境変数（ConfigMapから）
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
          
    # リソース制限
    resources:
      requests:
        memory: "256Mi"
        cpu: "500m"
      limits:
        memory: "512Mi"
        cpu: "1000m"
        
    # Liveness Probe（生存確認）
    livenessProbe:
      httpGet:
        path: /health
        port: 8080
      initialDelaySeconds: 30
      periodSeconds: 10
      timeoutSeconds: 5
      failureThreshold: 3
      
    # Readiness Probe（準備完了確認）
    readinessProbe:
      httpGet:
        path: /ready
        port: 8080
      initialDelaySeconds: 10
      periodSeconds: 5
      timeoutSeconds: 3
      successThreshold: 1
      failureThreshold: 3
      
    # ボリュームマウント
    volumeMounts:
    - name: app-logs
      mountPath: /var/log/app
    - name: config
      mountPath: /etc/app/config
      readOnly: true
      
  # ボリューム定義
  volumes:
  - name: app-logs
    emptyDir:
      sizeLimit: 1Gi
  - name: config
    configMap:
      name: app-config
      
  # プライベートレジストリの認証
  imagePullSecrets:
  - name: registry-secret
```

## Podの障害と挙動 - 実践的なトラブルシューティング

### kubectl delete実行時の挙動

Podを削除したとき、内部で何が起こっているのでしょうか：

```bash
# Pod削除を実行
kubectl delete pod nginx

# 内部の処理フロー:
# 1. kubectl delete pod 実行
# 2. APIサーバーがPodのSTATUSを "Terminating" に変更
# 3. kubeletがコンテナにSIGTERMシグナル送信
# 4. 猶予期間（デフォルト30秒）待つ
# 5. まだ終了していなければSIGKILLで強制終了
# 6. Pod削除完了

# リアルタイムで確認
kubectl get pods -w
# 別のターミナルで
kubectl delete pod nginx
```

猶予期間をカスタマイズする：

```bash
# 60秒の猶予期間を設定
kubectl delete pod nginx --grace-period=60

# 即座に強制削除（非推奨）
kubectl delete pod nginx --grace-period=0 --force
```

### 再起動ポリシー - restartPolicy

#### Always（デフォルト）

```yaml
spec:
  restartPolicy: Always  # 常に再起動
```

- コンテナがクラッシュしたら**常に再起動**
- 長時間アプリケーション向け（Webサーバー、APIサーバー等）
- 何度も失敗すると`CrashLoopBackOff`状態になる

```bash
# 動作確認
kubectl run crash-test --image=busybox --restart=Always -- sh -c "exit 1"
kubectl get pods -w
# 出力:
# crash-test   0/1     Error       0          5s
# crash-test   0/1     Running     1          6s
# crash-test   0/1     Error       1          7s
# crash-test   0/1     CrashLoopBackOff   1          20s
```

#### OnFailure

```yaml
spec:
  restartPolicy: OnFailure  # 失敗時のみ再起動
```

- `exit 0`（正常終了）: 再起動しない → `Completed`
- `exit 1`（異常終了）: 再起動する
- バッチ処理やジョブ向け

```bash
# 正常終了の例
kubectl run success-job --image=busybox --restart=OnFailure -- sh -c "echo done"
kubectl get pods
# 出力:
# success-job   0/1     Completed   0          10s
```

#### Never

```yaml
spec:
  restartPolicy: Never  # 絶対に再起動しない
```

- 失敗しても`Error`または`Failed`状態のまま
- 一度だけ実行したいタスク向け

```bash
kubectl run one-shot --image=busybox --restart=Never -- echo "hello"
kubectl get pods
# 出力:
# one-shot   0/1     Completed   0          5s
```

### ImagePullBackOff - イメージ取得の失敗

最も頻繁に遭遇するエラーの一つです。

#### 原因1: イメージ名の間違い

```bash
# 間違ったイメージ名でPod作成
kubectl run typo-pod --image=ngins:latest  # nginxのtypo

kubectl get pods
# 出力:
# typo-pod   0/1     ImagePullBackOff   0          30s

kubectl describe pod typo-pod
# Events:
#   Warning  Failed     Failed to pull image "ngins:latest": 
#            rpc error: code = Unknown desc = Error response from daemon: 
#            pull access denied for ngins, repository does not exist
```

**解決方法:** イメージ名を修正

```bash
kubectl delete pod typo-pod
kubectl run fixed-pod --image=nginx:latest
```

#### 原因2: プライベートレジストリの認証不足

```bash
# プライベートレジストリ用のシークレット作成
kubectl create secret docker-registry my-registry-secret \
  --docker-server=myregistry.example.com \
  --docker-username=myuser \
  --docker-password=mypassword \
  --docker-email=myemail@example.com

# Podマニフェストでシークレット指定
```yaml
spec:
  imagePullSecrets:
  - name: my-registry-secret
  containers:
  - name: myapp
    image: myregistry.example.com/myapp:v1.0
```

#### 原因3: ネットワーク問題

```bash
# minikube内からのネットワーク接続確認
minikube ssh
$ ping 8.8.8.8
$ nslookup registry-1.docker.io
$ exit
```

#### 原因4: Docker Hubのレート制限

Docker Hubは未認証ユーザーに対して厳しいレート制限を設けています。

```bash
# Docker Hub認証用シークレット作成
kubectl create secret docker-registry dockerhub \
  --docker-username=your-username \
  --docker-password=your-password \
  --docker-email=your-email@example.com

# 全てのPodで使用するデフォルトシークレットに設定
kubectl patch serviceaccount default -p '{"imagePullSecrets": [{"name": "dockerhub"}]}'
```

### CrashLoopBackOff - 繰り返しクラッシュ

アプリケーションが起動直後にクラッシュし続ける状態です。

#### 原因の特定

```bash
# Podの状態確認
kubectl get pods
# 出力:
# crash-app   0/1     CrashLoopBackOff   5          5m

# ログ確認（最も重要）
kubectl logs crash-app

# 前回の起動時のログ（より詳細）
kubectl logs crash-app --previous

# Pod詳細確認
kubectl describe pod crash-app
# Events:
#   Warning  BackOff  Back-off restarting failed container
```

#### よくある原因

**1. アプリケーションエラー**

```bash
# ログを確認して根本原因を特定
kubectl logs crash-app --previous
# 例: panic: runtime error: invalid memory address
```

**2. 設定ミス（環境変数など）**

```yaml
# 必須の環境変数が設定されていない
env:
- name: DATABASE_URL
  value: ""  # 空 → アプリがクラッシュ
```

**3. Liveness Probeの設定ミス**

```yaml
livenessProbe:
  httpGet:
    path: /health
    port: 8080
  initialDelaySeconds: 5  # ← 短すぎる！アプリ起動前にチェック
  periodSeconds: 3
  failureThreshold: 1  # ← 厳しすぎる！1回失敗で即再起動
```

**修正例:**

```yaml
livenessProbe:
  httpGet:
    path: /health
    port: 8080
  initialDelaySeconds: 30  # アプリ起動に十分な時間
  periodSeconds: 10
  failureThreshold: 3  # 3回失敗してから再起動
```

### Podがずっとpending状態

#### 原因1: リソース不足

```bash
kubectl describe pod pending-pod
# Events:
#   Warning  FailedScheduling  0/1 nodes are available: 1 Insufficient cpu.
```

**解決方法:** リソース要求を減らす

```yaml
resources:
  requests:
    memory: "64Mi"   # 256Mi → 64Mi に削減
    cpu: "50m"       # 500m → 50m に削減
```

#### 原因2: ノードセレクタの不一致

```bash
kubectl get nodes --show-labels
# ノードに必要なラベルがあるか確認

# ノードセレクタを削除または修正
kubectl edit pod pending-pod
```

## 初心者がつまづきやすいポイント

### ポイント1: Podとコンテナの混同

❌ **間違い:** "コンテナを作成する"
✅ **正しい:** "Podを作成する（その中にコンテナが含まれる）"

```bash
# Kubernetes用語として正しい
kubectl get pods    # ✅
kubectl get containers  # ❌ このコマンドは存在しない
```

### ポイント2: YAMLのインデントエラー

YAMLは**インデント**が命です！

```yaml
# ❌ 間違い（インデント不正）
spec:
containers:   # ← インデントが足りない
- name: nginx
  image: nginx:1.25

# ✅ 正しい
spec:
  containers:  # ← 2スペースインデント
  - name: nginx
    image: nginx:1.25
```

**デバッグ方法:**

```bash
# YAMLの検証
kubectl apply -f bad-pod.yaml --dry-run=client
# エラー:
# error: error parsing bad-pod.yaml: error converting YAML to JSON
```

### ポイント3: イメージタグの`latest`問題

```yaml
# ❌ 避けるべき
image: nginx:latest

# ✅ 推奨（具体的なバージョン指定）
image: nginx:1.25-alpine
```

**`latest`の問題点:**
- 常に最新版を取得 → 予期しない動作変更
- 再現性がない（異なる環境で異なるバージョン）
- ロールバックが困難
- 本番環境では**絶対に使わない**

### ポイント4: リソース制限の未設定

```yaml
# ❌ リソース制限なし（本番環境では危険！）
spec:
  containers:
  - name: app
    image: myapp:1.0
    # resources: なし → メモリリークでノード全体がダウンする可能性

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

### ポイント5: Liveness vs Readiness Probeの混同

- **Liveness Probe**: 生きているか? → 失敗で**Pod再起動**
- **Readiness Probe**: 準備完了か? → 失敗で**Serviceから除外**（再起動はしない）

```yaml
# 起動が遅いアプリケーションには startupProbe も
startupProbe:
  httpGet:
    path: /health
    port: 8080
  periodSeconds: 5
  failureThreshold: 30  # 最大150秒（5秒 × 30回）待つ
  
livenessProbe:
  httpGet:
    path: /health
    port: 8080
  periodSeconds: 10
  
readinessProbe:
  httpGet:
    path: /ready
    port: 8080
  periodSeconds: 5
```

## まとめ - この記事で学んだこと

本記事では、Podの本質を深く理解するため、以下の内容を学習しました：

1. **Podとは何か**
   - Kubernetesの最小デプロイ単位
   - コンテナではなくPodを管理
   - マルチコンテナPodのデザインパターン

2. **Podライフサイクル**
   - 5つのフェーズ（Pending → Running → Succeeded/Failed）
   - コンテナの3つの状態（Waiting, Running, Terminated）

3. **kubectlコマンド**
   - `get`, `describe`, `logs`, `exec`の実践的な使い方
   - トラブルシューティングの基本

4. **YAMLマニフェスト**
   - 必須フィールドから本番環境向けまで段階的に学習
   - Probe設定やリソース制限の重要性

5. **障害と挙動**
   - ImagePullBackOff, CrashLoopBackOffの原因と対処
   - 再起動ポリシーの使い分け

6. **つまづきポイント**
   - インデント、latest、リソース制限、Probeの設定

## 次回予告 - 第3回「ReplicaSet - アプリケーションを守る自動復旧の仕組み」

次回の記事では、以下を学習します：

- **なぜPod単体では不十分なのか** - 本番環境での課題
- **ReplicaSetによる冗長化** - 複数レプリカの管理
- **Podが死んだときの自動復旧** - 自己修復機能
- **セレクタとラベルの活用** - 柔軟なPod管理
- **スケーリングの基礎** - レプリカ数の増減

第2回ではPod単体の挙動を学びましたが、実際の本番環境では**単一のPodだけでは不十分**です。次回は、複数のPodを管理し、障害時に自動復旧する「ReplicaSet」の世界へ進みます！

ぜひ、実際に手を動かしながら学習を続けてください！
