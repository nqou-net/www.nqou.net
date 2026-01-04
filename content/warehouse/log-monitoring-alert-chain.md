---
date: 2026-01-04T17:54:00+09:00
description: サーバーログ監視を題材にしたChain of Responsibilityパターン実装のための調査ドキュメント。if-elseスパゲッティから段階的なハンドラチェーンへの移行解説用の基礎資料
draft: false
epoch: 1735985640
image: /favicon.png
iso8601: 2026-01-04T17:54:00+09:00
tags:
  - chain-of-responsibility
  - design-patterns
  - log-monitoring
  - perl
  - moo
  - alert-routing
title: 調査ドキュメント - ログ監視と多段アラート判定（Chain of Responsibilityパターン）
---

# 調査ドキュメント：ログ監視と多段アラート判定

## 調査目的

サーバーログ監視を題材にした技術ブログシリーズのための調査。特定キーワードやエラー検知時のアラート発火を段階的に実装し、if-else スパゲッティから Chain of Responsibility パターンへの移行を解説する。

**調査実施日**: 2026年1月4日

---

## 1. ログ監視の基本概念

### 1.1 ログ監視とは

**要点**:

- システム・アプリケーション・ネットワーク機器が出力するログを定期的またはリアルタイムで監視する仕組み
- 主な目的：システム安定稼働、セキュリティインシデント早期発見、監査証跡の確保
- 障害発生前の兆候検知により被害拡大を防止
- 運用効率化と自動化の実現

**根拠**:

- 現代のシステム運用とセキュリティ対策の基盤として広く認知されている
- エラーログ・アクセスログ・アプリケーションログの適切な監視が不可欠

**出典**:

- https://www.lanscope.jp/blogs/it_asset_management_emcloud_blog/20250606_27594/
- https://srest.io/blog/what-is-log-monitoring
- https://aisecurity.co.jp/article/3006
- https://www.rworks.jp/monitoring/monitoring-column/monitoring-entry/27215/

**信頼度**: 高

---

### 1.2 ログの種類と監視ポイント

#### エラーログ

**要点**:

- システムやアプリケーションが異常を検出した際に記録するログ
- 例：サーバー落ち、プログラム内の例外、DB接続失敗
- 監視ポイント：特定エラーの連続発生、重大エラーメッセージの検出

#### アクセスログ

**要点**:

- ウェブサーバーやネットワーク機器でユーザーのアクセス履歴を記録
- 例：Apache/Nginxのリクエスト情報（IP・URL・タイムスタンプ・ステータスコード）
- 監視ポイント：異常なルートへの大量アクセス、管理画面アクセス、不審なIPからのアクセス

#### アプリケーションログ

**要点**:

- アプリケーションごとに定義される処理履歴、ユーザー操作、状態変化
- 監視ポイント：認証失敗の多発、権限昇格の操作履歴、例外発生などの重大イベント

**根拠**:

- 業界標準のログ分類として広く採用されている
- 各種監視ツールでも同様の分類で取り扱われている

**出典**:

- https://cyber-security-lab.jp/log-monitoring/
- https://aisecurity.co.jp/article/3006

**信頼度**: 高

---

### 1.3 ログレベルの詳細

**要点**:

- **ERROR**: 重大障害。処理が継続できない・すぐ対処が必要な内容のみを記録・通知
- **WARN**: 潜在的な問題や注意すべき事象。継続可能だが運用担当が後で調査できる程度
- **INFO**: 正常動作や通常通知のみ。アラートにはしない
- **DEBUG**: 詳細な技術データ。主に開発や障害調査時のみ有効

**根拠**:

- 標準的なログレベル定義として多くのロギングフレームワークで採用
- ERRORとWARNに絞ってアラート化することでノイズによる疲労を防止可能

**仮定**:

- ログレベルの使い分けと抑制がアラート疲労対策に不可欠
- INFOやDEBUGはディスク記録のみでアラート対象外とする運用が推奨

**出典**:

- https://zenduty.com/blog/log-levels/
- https://itpfdoc.hitachi.co.jp/manuals/link/cosmi_v0870/APWK/EU310568.HTM
- https://web100tips.hatenablog.jp/entry/2025/06/06/210000

**信頼度**: 高

---

### 1.4 リアルタイム監視 vs バッチ処理

**要点**:

- **リアルタイム監視**: ログ発生と同時に処理・判定を行う。即時性が必要な障害検知に最適
- **バッチ処理**: 一定期間のログをまとめて解析。統計分析や傾向把握に有効

**根拠**:

- リアルタイム監視はストリーミング処理（Fluentd, Logstash等）で実装
- バッチ処理は定期的なログ集計や日次レポート生成で使用

**仮定**:

- 重要度が高いエラーはリアルタイム監視でアラート
- 統計データや分析結果はバッチ処理で定期報告

**信頼度**: 中

---

## 2. アラート判定とルーティング

### 2.1 アラート条件の設定方法

**要点**:

- あらかじめ定めた条件（文字列一致、連続発生回数、短時間の集中アクセス等）でアラート自動通知
- 動的しきい値設定の活用：AIやトラフィックパターン学習により通常変動に適応
- 静的閾値（例：CPU使用率90%固定）は過剰アラートを発生させる可能性
- SLI・SLOベースの監視設計：ユーザー影響の基準値で真の問題に集中

**根拠**:

- 多くの監視ツールで設定可能な標準機能
- 動的しきい値により本当に異常なケースでのみアラート発生可能

**出典**:

- https://www.logicmonitor.jp/blog/network-monitoring-avoid-alert-fatigue
- https://ximix.niandc.co.jp/column/an-approach-to-getting-rid-of-alert-fatigue

**信頼度**: 高

---

### 2.2 アラート通知先（Slack, Email, PagerDuty等）

**要点**:

- **PagerDuty**: 中心的なアラートルーティングとエスカレーション管理
  - Escalation Policiesで通知順序と担当者を定義
  - イベントルールで関連アラートのみをインシデント化
  - アラートの重複排除機能

- **Slack統合**: リアルタイムで実行可能なアラート対応
  - 専用チャンネルでインシデント指揮を一元化
  - Slackから直接アクション（承認、エスカレート、解決、メモ追加）
  - 更新内容がリアルタイムで投稿される

- **Email**: 低優先度通知、事後報告、Slack外のステークホルダー向け
  - 非同期的な広範囲アラートに適する
  - PagerDutyフェイルオーバー時の補助手段

**根拠**:

- PagerDutyとSlackの統合は業界標準パターン
- 複数チャネルによる冗長性とコンテキスト最適化が重要

**出典**:

- https://support.pagerduty.com/main/docs/slack-integration-guide
- https://clearfeed.ai/blogs/pagerduty-slack-integration-guide
- https://www.thena.ai/post/pagerduty-slack-integration
- https://dohost.us/index.php/2025/10/22/integrating-alerts-with-notification-channels-email-slack-pagerduty/

**信頼度**: 高

---

### 2.3 エスカレーション機能

**要点**:

- 第一対応者が応答しない場合、次の担当者またはグループに自動転送
- 時間指定と24/7オンコールローテーション対応
- Slackチャンネルもエスカレーション通知対象に設定可能
- エスカレーションポリシーの定期監査が推奨

**根拠**:

- PagerDutyのエスカレーションポリシーが業界標準
- 適切な設計で確実な対応体制を構築

**出典**:

- https://www.mindfulchase.com/explore/troubleshooting-tips/devops-tools/troubleshooting-alert-routing-and-escalation-failures-in-pagerduty.html
- https://fastercapital.com/content/Pipeline-alerting--How-to-set-up-pipeline-alerts-and-notifications-using-tools-like-PagerDuty-and-Slack.html

**信頼度**: 高

---

### 2.4 アラート疲労（alert fatigue）と対策

**要点**:

- **定義**: 大量のアラートによって担当者が鈍感化・ストレス・生産性低下を起こし、重要なアラートを見逃すリスク
- **主な原因**: 不適切な閾値設定、ログレベルの誤用、静的閾値の濫用

**対策**:

1. **ログレベル運用の厳格化**
   - ERRORとWARNに絞ってアラート化
   - INFOやDEBUGはディスク記録のみ

2. **動的しきい値設定の活用**
   - 通常変動に適応した閾値で異常時のみアラート

3. **アラートの分類・重要度分け**
   - Critical/High/Medium/Lowで分類
   - 高優先度は即時通知、それ以外は定期通知やレポート
   - ロールベースのルーティングやAIによるグループ化

4. **SLI・SLOベースの監視設計**
   - ビジネスインパクト基準でアラート発生
   - 真の問題に集中し疲労と機会損失を削減

5. **定期的な見直しとチューニング**
   - 不要なルールや閾値の継続的改善
   - Reviewプロセスの確立

**根拠**:

- アラート疲労は運用チームだけでなく事業リスクにも直結
- 適切な管理で生産性向上とインシデント見逃しリスク低減を実現

**出典**:

- https://www.logicmonitor.jp/blog/network-monitoring-avoid-alert-fatigue
- https://www.atlassian.com/ja/incident-management/on-call/alert-fatigue
- https://www.ibm.com/jp-ja/think/topics/alert-fatigue
- https://ximix.niandc.co.jp/column/an-approach-to-getting-rid-of-alert-fatigue

**信頼度**: 高

---

## 3. Chain of Responsibility パターンの応用

### 3.1 パターン概要と適用理由

**要点**:

- 複数のハンドラを直列に連結し、リクエストを処理可能なハンドラに委譲する振る舞いパターン
- 送信者（クライアント）と受信者（ハンドラ）を疎結合にし、条件分岐の集中を避ける
- ハンドラの追加・差し替え・順序変更が容易でOpen/Closed原則を支援

**ログ監視・アラート判定での適用**:

- **ログフィルタリング**: 重要度に応じて段階的に処理
- **ログエンリッチメント**: 各ハンドラがログエントリを拡張・変換
- **アラートルーティング**: 異なるハンドラが異なる宛先に転送
- **多段処理**: スパムフィルタ→重要度フィルタ→通知ハンドラの順で処理

**根拠**:

- GoF「Design Patterns」で振る舞いパターンの一つとして定義
- ミドルウェアパイプライン（HTTP、ロギング、バリデーション）で広く採用

**出典**:

- https://www.nqou.net/warehouse/chain-of-responsibility-pattern/
- https://refactoring.guru/ja/design-patterns/chain-of-responsibility
- https://algomaster.io/learn/lld/chain-of-responsibility
- https://www.geeksforgeeks.org/system-design/chain-responsibility-design-pattern/

**信頼度**: 高

---

### 3.2 if-elseスパゲッティとの比較

**if-elseスパゲッティの問題点**:

```perl
sub process_log {
    my ($log) = @_;
    
    if ($log->{level} eq 'ERROR' && $log->{message} =~ /database/) {
        send_to_slack($log);
        send_to_pagerduty($log);
        save_to_db($log);
    } elsif ($log->{level} eq 'ERROR' && $log->{message} =~ /network/) {
        send_to_email($log);
        save_to_db($log);
    } elsif ($log->{level} eq 'WARN') {
        save_to_db($log);
    } elsif ($log->{level} eq 'INFO') {
        # 何もしない
    } else {
        # その他の処理
    }
}
```

**問題**:

- 条件分岐が集中し、可読性が低い
- 新しいケースの追加が困難（既存コードの修正が必要）
- テストが複雑化
- 責務が不明確

**Chain of Responsibilityによる改善**:

- 各ハンドラが単一の責務を持つ
- 新しいハンドラを追加するだけで拡張可能
- テストが容易（各ハンドラを独立してテスト）
- 処理フローが明確

**信頼度**: 高

---

### 3.3 複数ハンドラによる段階的処理

**典型的な処理フロー**:

1. **LogParserHandler** – 生ログを構造化エントリに変換
2. **SeverityFilterHandler** – 一定以上の重要度のみ通過
3. **AlertFilterHandler** – 重要アラートを検出してフラグ付け
4. **NotificationHandler** – 重要アラートを外部通知
5. **StorageHandler** – ログをファイル、DB、リモートサーバーに保存

**実装ポイント**:

- 各ハンドラは`handle(logEntry)`メソッドを実装
- 次のハンドラへの参照を保持
- 処理可能な場合は実行、そうでなければ次に委譲

**根拠**:

- パイプライン処理の標準的なパターン
- 責務の分離と拡張性の向上

**出典**:

- https://www.systemoverflow.com/learn/behavioral-patterns/chain-of-responsibility/chain-of-responsibility-real-world-variations-and-extensions
- https://gaetanopiazzolla.github.io/java/2025/06/24/spring-filter-chain-article.html

**信頼度**: 高

---

### 3.4 拡張性・保守性のメリット

**メリット**:

1. **条件分岐の集中を回避**: 責務を明確に分割
2. **ハンドラの追加・順序変更が容易**: 高い拡張性
3. **疎結合**: クライアントは最初のハンドラに渡すだけ
4. **失敗時・未処理時のポリシー差し替え**: 柔軟な設計

**デメリット**:

1. **処理者の特定が困難**: コード上から直感しづらい
2. **長いチェーンでのデバッグ難**: 処理遅延の可能性
3. **未処理リクエストのリスク**: 静かに破棄される可能性
4. **ハンドラ間の共有状態**: 結合度が上がりやすい

**対策**:

- トレース/ロギングをハンドラ内に実装してパイプライン可視化
- 設定やDIでチェーンを動的に組み立て
- 未処理時のデフォルト動作を明示的に定義

**信頼度**: 高

---

## 4. Perl/Mooでの実装パターン

### 4.1 Mooを使ったハンドラクラスの設計

**要点**:

- Mooは軽量で高速なPerlオブジェクト指向システム
- Mooseのサブセットを提供し、起動時間に最適化
- blessを直接使うより圧倒的に簡潔で分かりやすい

**基本ハンドラクラス**:

```perl
package Handler;
use Moo;

has next => (is => 'rw'); # 次のハンドラを保持

sub handle {
    my ($self, $request) = @_;
    if ($self->can_handle($request)) {
        $self->process($request);
    } elsif ($self->next) {
        $self->next->handle($request);
    } else {
        warn "No handler can process request: $request\n";
    }
}

sub can_handle {
    die "can_handle() must be implemented by subclass";
}

sub process {
    die "process() must be implemented by subclass";
}

1;
```

**根拠**:

- Mooの標準的な使い方に準拠
- 継承可能な基底クラスとして設計

**出典**:

- https://metacpan.org/pod/Moo
- https://perlmaven.com/oop-with-moo
- https://www.nqou.net/warehouse/moo-oop-series-research/

**信頼度**: 高

---

### 4.2 Moo::Roleでのインターフェース定義

**要点**:

- Moo::Roleで共通の振る舞いを定義
- `requires`で必須メソッドを指定
- `with`でロールを消費

**ロール定義例**:

```perl
package LogHandlerRole;
use Moo::Role;

requires 'handle_log';
requires 'set_next';

has next_handler => (
    is => 'rw',
    predicate => 'has_next_handler'
);

sub set_next {
    my ($self, $next) = @_;
    $self->next_handler($next);
    return $next;
}

sub _next_handler {
    my ($self) = @_;
    return ($self->has_next_handler && $self->next_handler) 
        ? $self->next_handler 
        : undef;
}

1;
```

**根拠**:

- ロールは「can-do」関係（振る舞いの共有）を表現
- 複数のクラスで共通の振る舞いを再利用可能

**出典**:

- https://metacpan.org/pod/Moo::Role
- https://theweeklychallenge.org/blog/roles-in-perl/

**信頼度**: 高

---

### 4.3 チェーン構築の実装例

**具体的なハンドラクラス**:

```perl
package SeverityFilterHandler;
use Moo;
extends 'Handler';

has min_severity => (is => 'ro', required => 1);

sub can_handle {
    my ($self, $log) = @_;
    return $log->{severity} >= $self->min_severity;
}

sub process {
    my ($self, $log) = @_;
    warn "SeverityFilter: passed $log->{message}\n";
    # ログを次のハンドラに渡す
    $self->next->handle($log) if $self->next;
}

1;
```

```perl
package NotificationHandler;
use Moo;
extends 'Handler';

has notifier => (is => 'ro', required => 1);

sub can_handle {
    my ($self, $log) = @_;
    return $log->{alert_flag};
}

sub process {
    my ($self, $log) = @_;
    $self->notifier->send($log);
    warn "Notification: sent $log->{message}\n";
}

1;
```

**チェーン構築**:

```perl
use SeverityFilterHandler;
use NotificationHandler;
use SlackNotifier;

my $chain = SeverityFilterHandler->new(
    min_severity => 3
);

$chain->next(
    NotificationHandler->new(
        notifier => SlackNotifier->new
    )
);

# 使用例
$chain->handle({ severity => 4, message => "Error", alert_flag => 1 });
```

**信頼度**: 高

---

### 4.4 実際のログファイル読み込みと判定

**要点**:

- ファイル読み込みとパース処理を分離
- ハンドラチェーンにパース済みデータを投入

**実装例**:

```perl
package LogProcessor;
use Moo;
use Path::Tiny;

has handler_chain => (is => 'ro', required => 1);

sub process_file {
    my ($self, $filepath) = @_;
    
    my @lines = path($filepath)->lines_utf8;
    
    for my $line (@lines) {
        my $log = $self->parse_line($line);
        $self->handler_chain->handle($log) if $log;
    }
}

sub parse_line {
    my ($self, $line) = @_;
    
    # 簡易的なパース（実際はより複雑）
    if ($line =~ /(\w+):\s*(.+)/) {
        my ($level, $message) = ($1, $2);
        return {
            level => $level,
            message => $message,
            severity => $self->level_to_severity($level),
            alert_flag => ($level eq 'ERROR') ? 1 : 0,
        };
    }
    return undef;
}

sub level_to_severity {
    my ($self, $level) = @_;
    my %map = (
        ERROR => 4,
        WARN  => 3,
        INFO  => 2,
        DEBUG => 1,
    );
    return $map{$level} // 0;
}

1;
```

**信頼度**: 高

---

## 5. 競合記事の分析

### 5.1 類似テーマの技術記事

| カテゴリ | タイトル | URL | 特徴 |
|---------|---------|-----|------|
| デザインパターン | Chain of Responsibility - refactoring.guru | https://refactoring.guru/ja/design-patterns/chain-of-responsibility | パターンの標準的な解説 |
| 実装例 | Java : Chain of Responsibility パターン | https://programming-tips.jp/archives/a3/64/index.html | Java実装の詳細 |
| 応用例 | How Spring Implements CoR | https://gaetanopiazzolla.github.io/java/2025/06/24/spring-filter-chain-article.html | フレームワーク実例 |
| システム設計 | GeeksforGeeks - CoR Design Pattern | https://www.geeksforgeeks.org/system-design/chain-responsibility-design-pattern/ | システム設計観点 |

**差別化ポイント**:

1. **Perl/Moo特化**: 他の記事はJava/PHP/Python中心
2. **実践的題材**: ログ監視という現実的なユースケース
3. **段階的説明**: スパゲッティコードからの移行プロセス
4. **日本語の詳細解説**: Mooでの実装例が少ない

**信頼度**: 高

---

### 5.2 ログ監視ツールの紹介記事

| ツール | 特徴 | URL |
|-------|------|-----|
| **Fluentd** | オープンソース、プラグイン豊富 | https://www.fluentd.org/ |
| **Logstash** | Elastic Stack統合 | https://www.elastic.co/logstash/ |
| **Splunk** | エンタープライズ向け | https://www.splunk.com/ |
| **Datadog** | クラウドネイティブ監視 | https://www.datadoghq.com/ |

**本シリーズとの関係**:

- これらのツールが内部的にChain of Responsibilityパターンを使用
- パターン理解により既存ツールのカスタマイズが容易に

**信頼度**: 高

---

## 6. 内部リンク候補

### 6.1 直接関連記事（デザインパターン）

| ファイルパス | タイトル | 内部リンク | 関連度 |
|-------------|---------|-----------|--------|
| `/content/warehouse/chain-of-responsibility-pattern.md` | Chain of Responsibilityパターン調査 | `/warehouse/chain-of-responsibility-pattern/` | **最高** |
| `/content/warehouse/design-patterns-overview.md` | デザインパターン概要 | `/warehouse/design-patterns-overview/` | 高 |
| `/content/warehouse/observer-pattern.md` | Observerパターン | `/warehouse/observer-pattern/` | 中 |
| `/content/warehouse/strategy-pattern-research.md` | Strategyパターン | `/warehouse/strategy-pattern-research/` | 中 |

### 6.2 Perl/Moo関連記事

| ファイルパス | タイトル | 内部リンク | 関連度 |
|-------------|---------|-----------|--------|
| `/content/warehouse/moo-oop-series-research.md` | Mooで覚えるOOP調査 | `/warehouse/moo-oop-series-research/` | **最高** |
| `/content/post/2021/10/31/191008.md` | 第1回-Mooで覚えるOOP | `/2021/10/31/191008/` | 高 |
| `/content/warehouse/moo-dispatcher-series-research.md` | Moo Dispatcher調査 | `/warehouse/moo-dispatcher-series-research/` | 高 |

### 6.3 ログ処理関連記事の候補

**注**: 現状では直接的なログ処理記事が少ないため、関連技術記事を候補とする

| ファイルパス | タイトル | 内部リンク | 関連度 |
|-------------|---------|-----------|--------|
| `/content/warehouse/mojolicious.md` | Mojolicious入門 | `/warehouse/mojolicious/` | 中 |
| `/content/warehouse/mojo-log-event-driven.md` | Mojo::Log イベント駆動 | `/warehouse/mojo-log-event-driven/` | 中 |
| `/content/warehouse/io-async.md` | IO::Async | `/warehouse/io-async/` | 低 |

---

## 7. 参考文献と出典まとめ

### 7.1 ログ監視・アラート関連

| タイトル | URL | 信頼度 |
|---------|-----|--------|
| ログ監視とは？ | https://www.lanscope.jp/blogs/it_asset_management_emcloud_blog/20250606_27594/ | 高 |
| ログ監視とは？目的とツール | https://aisecurity.co.jp/article/3006 | 高 |
| アラート疲労対策 | https://www.logicmonitor.jp/blog/network-monitoring-avoid-alert-fatigue | 高 |
| PagerDuty Slack統合 | https://support.pagerduty.com/main/docs/slack-integration-guide | 高 |
| Log Levels Explained | https://zenduty.com/blog/log-levels/ | 高 |

### 7.2 Chain of Responsibilityパターン

| タイトル | URL | 信頼度 |
|---------|-----|--------|
| Refactoring Guru - CoR | https://refactoring.guru/ja/design-patterns/chain-of-responsibility | 高 |
| GeeksforGeeks - CoR | https://www.geeksforgeeks.org/system-design/chain-responsibility-design-pattern/ | 高 |
| AlgoMaster - CoR | https://algomaster.io/learn/lld/chain-of-responsibility | 高 |
| Spring Filter Chain | https://gaetanopiazzolla.github.io/java/2025/06/24/spring-filter-chain-article.html | 高 |

### 7.3 Perl/Moo関連

| タイトル | URL | 信頼度 |
|---------|-----|--------|
| Moo公式ドキュメント | https://metacpan.org/pod/Moo | 高 |
| Moo::Role | https://metacpan.org/pod/Moo::Role | 高 |
| Perl Maven - OOP with Moo | https://perlmaven.com/oop-with-moo | 高 |
| Modern Perl OOP 2025 | https://islandinthenet.com/revisiting-perl-object-oriented-programming-oop-in-2025/ | 高 |

---

## 8. 調査結果のサマリー

### 8.1 主要な発見事項

1. **ログ監視の重要性**
   - システム安定性とセキュリティの基盤
   - 適切なログレベル運用がアラート疲労対策の鍵

2. **Chain of Responsibilityパターンの有効性**
   - if-elseスパゲッティからの脱却に最適
   - ログ処理パイプラインに自然にマッチ
   - 拡張性と保守性の向上

3. **Perl/Mooでの実装**
   - Mooの軽量性とシンプルさが実装を容易に
   - ロールによる柔軟な設計が可能
   - 既存のPerl資産との統合が容易

### 8.2 記事執筆への示唆

1. **段階的な説明アプローチ**
   - スパゲッティコードの問題点を具体的に示す
   - パターン適用前後の比較を明示
   - 実際のログファイル処理例で実践的に

2. **Mooの活用**
   - 初心者にも理解しやすいMooの構文
   - ロールとextends の使い分け
   - 実装の段階的な改善プロセス

3. **実用性の強調**
   - ログ監視という現実的な題材
   - 実際の運用で使えるコード例
   - パフォーマンスと可読性のバランス

### 8.3 今後の展開候補

1. **シリーズ記事化**
   - 第1回：if-elseスパゲッティの問題点
   - 第2回：Chain of Responsibilityパターン入門
   - 第3回：Mooでの基本実装
   - 第4回：実践的なログ監視システム構築

2. **発展的なトピック**
   - 非同期処理への対応
   - パフォーマンスチューニング
   - テスト戦略
   - 既存システムへの段階的導入

---

**調査完了**: 2026年1月4日  
**次のステップ**: 個別記事のアウトライン作成と執筆
