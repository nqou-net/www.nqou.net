---
date: 2026-03-05T00:15:00+09:00
description: コード探偵ロックの事件簿 第3話「連続爆破の真犯人〜1箇所直すと3箇所壊れる呪い〜」の構造案
title: '連載構造案 - コード探偵ロックの事件簿【Observer】'
---

# 連載構造案：コード探偵ロックの事件簿【Observer】統合版

## 前提情報

- **シリーズ名**: コード探偵ロックの事件簿
- **テーマ**: レガシーコード・アンチパターンの解決 × GoFデザインパターン
- **技術スタック**: Perl (Mooを利用)
- **今回のアンチパターン**: Shotgun Surgery（散弾銃手術）— 1箇所の変更があちこちに波及
- **今回の解決策**: Observer パターン — 状態変化の通知を一元化
- **形式**: 統合版（1つの完結した記事）

## 登場人物

- **ロック**: 主人公。ホームズ気取りのコード探偵。
- **リン（ワトソン君A / 語り手）**: 後輩エンジニア。生真面目で責任感が強い。先輩のコードの問題に気づき、本人を連れてLCIへ来た。
- **タツヤ（ワトソン君B / 先輩）**: 自信過剰なエンジニア。腕は確かだが、リンの生真面目な指摘に弱い。ロックに対抗意識を持つ。

## ストーリー構成

### I. 依頼（不本意な来訪）
- **状況**: リンがタツヤを半ば引きずるようにLCIへ連れてくる。タツヤは「俺のコードに問題はない」と不機嫌。
- **描写**: ロックが2人を見て興味を示す。タツヤの「俺は探偵なんかに頼る必要はない」発言にロックが涼しい顔。
- **コメディ**: ロック「問題ない。2人ともワトソン君だ」→ タツヤ「誰がワトソンだ。俺はタツヤだ」→ ロック「いい名前だね、ワトソン君」
- **主訴**: リン「先輩が書いた在庫管理システムで、在庫数を更新するたびに、メール通知もログもダッシュボードも全部書き直さないといけないんです」 タツヤ「それは仕様だ。俺が全部ちゃんと書いてる」

### II. 現場検証（散弾銃の痕跡）
- **Beforeコード提示**: `StockManager`の`update_stock`に、メール送信・ログ書き込み・ダッシュボード更新が直書きされている。
- ロック「ほう、1つのメソッドが3つの仕事を知りすぎている。これは散弾銃手術（Shotgun Surgery）のにおいだ」
- タツヤ「知りすぎ？ 効率がいいんだよ。全部1箇所にまとめてるんだから」
- リンが正直に報告「でも先輩、先週Slack通知を追加したとき、メール通知が止まりましたよね？」→ タツヤ沈黙
- ロック「1発撃つと散弾が四方に飛ぶ。修正のたびに被害が広がる。これが『散弾銃手術』の正体さ」

### III. 推理披露（監視網の構築）
- **Step 1**: Observer Role（共通インターフェース）の定義 — 全ての「反応する側」が守る約束
- **Step 2**: 具体的なObserver群（EmailNotifier, Logger, Dashboard）の実装
- **Step 3**: Subject（StockManager）の再構築 — observerの登録/削除/通知メソッド
- **タツヤの抵抗と理解**:
  - タツヤ「Observer？ 監視カメラかよ。俺のコードは監視される必要はない」
  - リン「でも先輩、これなら新しい通知を追加しても既存コードに触らなくていいんですよね？」
  - タツヤ（渋々）「……まあ、確かにSlackの件は面倒だった」
- **ロックの解説**: 「在庫が変わったら『変わったぞ』と叫ぶだけ。誰が聞いているかは知らなくていい。これがObserverパターンだ」

### IV. 解決（静かになった現場）
- テストが全て通る。タツヤが黙って画面を見つめる。
- リン「先輩、新しいSlack通知もObserverを1つ追加するだけで……」
- タツヤ「……分かってる。俺だって、次からはこう書く」（素直に認める）
- ロックの報酬要求：「散弾銃のように炸裂するスパイスのカレーを一皿」
- タツヤ「探偵、お前……コードの腕は認めてやる。だがカレーの味は保証しない」

### V. 探偵の調査報告書
- **表**: Shotgun Surgery → Observer パターン → 疎結合・拡張性向上
- **推理のステップ**: Observer Role定義 → 具象Observer実装 → Subject側の通知一元化
- **ロックからのメッセージ**: 変化を恐れるな。ただし、変化の波及を制御する仕組みを持て。

## 実装計画

### Before（散弾銃手術）

```perl
package StockManager;
use Moo;

sub update_stock ($self, $item, $quantity) {
    # 在庫更新
    # ... 在庫ロジック ...

    # 以下、すべて直書き — 1箇所変えると全部壊れる
    $self->_send_email($item, $quantity);
    $self->_write_log($item, $quantity);
    $self->_refresh_dashboard($item, $quantity);
    # Slack通知を追加するには？ → ここにまた直書き → メール通知が壊れる
}
```

### After（Observer パターン適用）

```perl
package StockObserver::Role;
use Moo::Role;
requires 'on_stock_updated';

package StockObserver::Email { ... }
package StockObserver::Logger { ... }
package StockObserver::Dashboard { ... }

package StockManager;
use Moo;
has observers => (is => 'ro', default => sub { [] });

sub add_observer ($self, $observer) { push @{$self->observers}, $observer }
sub notify ($self, $item, $quantity) {
    $_->on_stock_updated($item, $quantity) for @{$self->observers};
}
sub update_stock ($self, $item, $quantity) {
    # 在庫更新ロジック
    $self->notify($item, $quantity);  # これだけ！
}
```

## メタデータ・構成情報
- **slug**: `code-detective-observer-shotgun-surgery`
- **カテゴリ**: [Design Patterns, Perl]
- **タグ**: [perl, moo, observer, refactoring, code-detective]
