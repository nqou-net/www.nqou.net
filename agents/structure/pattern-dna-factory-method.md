# パターンDNA解析: Factory Method

> 適用ワークフロー: [/code-doctor-series](../../.agent/workflows/code-doctor-series.md)

---

## 症状カタログ

| # | 症状名 | 説明 | 重症度 | 処方候補 |
|---|--------|------|--------|---------|
| 1 | **生成ロジック散乱症** | オブジェクト生成のコードが複数箇所に散らばっている | 中症 | Factory Method |
| 2 | **コンストラクタ過負荷症** | コンストラクタに大量のパラメータやif文が混入している | 重症 | Factory Method |
| 3 | **具体クラス依存症** | クライアントコードが具体的なクラス名に強く依存している | 重症 | Factory Method |

---

## DNA解析マップ

### パターン: Factory Method
- **適応症状**:
    - オブジェクト生成ロジックが複雑で、クライアントコードを汚染している
    - 生成すべきクラスが実行時まで不明確
    - フレームワークやライブラリで、ユーザーがクラスを拡張できるようにしたい
- **禁忌**:
    - 生成ロジックが単純で、将来的にも変更の予定がない場合（YAGNI原則違反）
    - クラス数がこれ以上増えることが許容されない環境
- **副作用**:
    - クラス数が増加する（CreatorとProductの階層が必要になるため）
    - コードの追跡が少し難しくなる（間接層が増えるため）

---

## 競合・内部リンク分析

- **既存記事**: `factory-method-pattern-series-structure.md` (APIレスポンスシミュレーター)
    - 違い: 既存記事は標準的なチュートリアル。本記事は「コードドクター」による医療メタファーを用いたストーリー形式。
    - 差別化: 「通知システム」という新しい題材で、なぜ `new` を直接書くと問題が起きるのかを「手術による治療」として描く。

---

## 処方箋設計（統合版）

### 採用案: 案A（標準治療）

**テーマ**: マルチチャネル通知システムの救済

**ストーリー**:
- **患者**: マルチチャネル通知システムの開発者
- **症状**: 新しい通知チャネル（メール、Slack、SMS等）を追加するたびに、メインの `NotificationService` クラスを修正し、巨大な `if-elsif` 文に追記している。
- **診断**: 「具体クラス依存症」および「開放閉鎖原則違反（OCP不全）」
- **手術**:
    1. 通知チャネルを `Notifier` インターフェース（Product）として抽象化
    2. 各チャネルを具体的な `Notifier` クラスとして分離
    3. `NotifierFactory` クラス（Creator）を導入し、生成ロジックを委譲
    4. クライアントコードから具体クラス名への依存を排除

### 患者プロファイル

- **名前**: 佐藤（女性）
- **ペルソナ**: Type B（どうしようもなく疲れ切っている）
- **背景**: スタートアップの通知システム担当。ユーザーからの要望で、毎週新しい通知チャネルを追加させられている。
- **口癖**: 「また追加ですか…」「もう限界です…」

---

## 連載構造案（統合版構成）

| 章 | タイトル | 内容 |
|----|--------|------|
| 1 | **急患搬送** | 疲れ切った佐藤さんが来院。巨大な `if-elsif` 文を抱えている。ドクターの診断「具体クラス依存症」。 |
| 2 | **問診と検査** | なぜ具体クラスに依存すると問題なのか？ 変更のリスクを説明。「このコードは毎回触る必要がある」 |
| 3 | **手術: 患部摘出** | `if-elsif` 文を解体。各チャネルを独立した `Notifier` クラスに分離する。 |
| 4 | **術後経過** | 新しい通知チャネル（SMS）を追加してみる。既存コードを触らずに追加できることを確認。 |
| 5 | **退院指導** | Simple Factory と Factory Method の違い。いつどちらを使うべきかのガイダンス。 |

---

## メトリクス設計 (Before -> After)

- **行数**: `NotificationService` の行数が劇的に減少（各チャネルクラスに分散）
- **複雑度**: `send_notification` の循環的複雑度が 5 → 1 に低下
- **結合度**: `NotificationService` は具体的な `EmailNotifier` や `SlackNotifier` に依存しなくなる

---

## コード設計

### Before（問題のあるコード）

```perl
package NotificationService;

sub new {
    my ($class) = @_;
    return bless {}, $class;
}

sub send_notification {
    my ($self, $type, $message, $recipient) = @_;
    
    if ($type eq 'email') {
        # メール送信ロジック
        print "【Email to $recipient】$message\n";
    }
    elsif ($type eq 'slack') {
        # Slack送信ロジック
        print "【Slack to $recipient】$message\n";
    }
    elsif ($type eq 'sms') {
        # SMS送信ロジック
        print "【SMS to $recipient】$message\n";
    }
    else {
        die "Unknown type: $type";
    }
}
```

### After（Factory Methodパターン適用後）

```perl
# Product インターフェース
package Notifier;
sub send { die "Override me!" }

# Concrete Products
package EmailNotifier;
use parent -norequire, 'Notifier';
sub send {
    my ($self, $message, $recipient) = @_;
    print "【Email to $recipient】$message\n";
}

package SlackNotifier;
use parent -norequire, 'Notifier';
sub send {
    my ($self, $message, $recipient) = @_;
    print "【Slack to $recipient】$message\n";
}

package SMSNotifier;
use parent -norequire, 'Notifier';
sub send {
    my ($self, $message, $recipient) = @_;
    print "【SMS to $recipient】$message\n";
}

# Creator クラス
package NotifierFactory;
sub new {
    my ($class) = @_;
    return bless {}, $class;
}

# Factory Method（サブクラスでオーバーライド可能）
sub create_notifier { die "Override me!" }

sub send_notification {
    my ($self, $message, $recipient) = @_;
    my $notifier = $self->create_notifier();
    $notifier->send($message, $recipient);
}

# Concrete Creators
package EmailNotifierFactory;
use parent -norequire, 'NotifierFactory';
sub create_notifier { return bless {}, 'EmailNotifier' }

package SlackNotifierFactory;
use parent -norequire, 'NotifierFactory';
sub create_notifier { return bless {}, 'SlackNotifier' }

package SMSNotifierFactory;
use parent -norequire, 'NotifierFactory';
sub create_notifier { return bless {}, 'SMSNotifier' }
```

---

## タグ

`code-doctor`, `design-patterns`, `factory-method`, `refactoring`, `object-oriented-programming`
