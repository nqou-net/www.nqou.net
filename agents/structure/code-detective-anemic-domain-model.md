---
date: 2026-03-11T07:07:05+09:00
description: コード探偵ロックの事件簿「奪われた自己決定権 〜全裸にされたデータたちと中央集権の悲劇〜」の構造案
title: '連載構造案 - コード探偵ロックの事件簿【Tell, Don'\''t Ask】'
---

# 連載構造案：コード探偵ロックの事件簿【Tell, Don't Ask】統合版

## 前提情報

- **シリーズ名**: コード探偵ロックの事件簿
- **テーマ**: レガシーコード・アンチパターンの解決 × オブジェクト指向の原則
- **技術スタック**: Perl (Mooを利用)
- **今回のアンチパターン**: Anemic Domain Model（貧弱なドメインモデル）— データを持つだけのクラスと、処理を吸い上げた巨大なサービスクラス
- **今回の解決策**: Tell, Don't Ask（情報をひん剥くな、振る舞いを持たせよ）— オブジェクト自身に判断と処理を行わせる
- **形式**: 統合版（1つの完結した記事）

## 登場人物

- **ロック**: 主人公。ホームズ気取りのコード探偵。「被害者（データクラス）は全裸で広場に立たされている」と呆れる。
- **ミサキ（ワトソン君 / 語り手）**: ECサイトの若手バックエンドエンジニア。前任者が残した「美しい分離アーキテクチャ（実は責務剥奪）」の保守に苦しんでいる。

## ストーリー構成

### I. 依頼（綺麗すぎる地獄）
- **状況**: ミサキが疲れ果てた様子でLCIを訪れる。
- **主訴**: 「前任者は『データ用クラス(Entity)と処理用クラス(Service)を完全に分離した美しいアーキテクチャだ』と豪語していました。でも、プレミアム会員の割引ルールが1つ増えるだけで、数千行の `OrderService` クラスのあちこちを修正しなきゃいけないんです」
- **ロックの反応**: 「ふむ。外見は綺麗に着飾っているが、中身は中央集権の独裁国家というわけだね、ワトソン君」

### II. 現場検証（奪われた自己決定権）
- **Beforeコード提示**: `Order`クラスは単なるゲッター/セッターの集合体。`OrderService`が `Order` から割引率、商品情報を「ひん剥いて（getして）」、Service内で計算し、再び `Order` に「着せている（setしている）」。
- **ロックの推理**: 「ああ、なんてむごい事件だ。被害者（Orderクラス）は全裸で広場に立たされ、他人に服を着せてもらうのを待っている状態だ。自らの身を守る術（ロジック）をすべて剥奪されている」
- **ミサキの疑問**: 「でも、データと処理を分けるのは良いことじゃないんですか？」

### III. 推理披露（反逆の自己決定）
- **Step 1**: `Order`クラスへの振る舞い（メソッド）の移譲 — `calculate_discounted_price` メソッド等の追加
- **Step 2**: 状態の隠蔽化 — `is_premium` や `amount` などのゲッターを減らし、判断をオブジェクト内部に閉じ込める
- **Step 3**: `OrderService` の解体と委譲 — Serviceは「計算しろ（Tell）」と命令するだけの薄い層になる
- **ロックの解説**: 「『情報を尋ねるな（Don't Ask）、命じよ（Tell）』だ。オブジェクトは自身のデータを使って自身の振る舞いを決定すべきだ。データだけを奪って他人が計算するのは、オブジェクト指向の名を借りた手続き型プログラミングでしかない」

### IV. 解決（自立したデータたち）
- テストが通り、`OrderService` がすっきりと短くなる。
- 新しい割引ルールを追加する際も、`Order` 自身のメソッドを追加・修正するだけで済むようになる。
- **ミサキ**: 「すごい…！ データクラスがただの入れ物じゃなくて、ちゃんと『仕事』をしている感じがします」
- **ロック**: 「そうだ、彼らは独立した主権を取り戻したのだよ。この尊い独立記念日に免じて、今日の報酬は特製のエスプレッソ（砂糖抜き）で手を打とう」

### V. 探偵の調査報告書
- **表**: Anemic Domain Model → Tell, Don't Ask → カプセル化による責務の適切な配置
- **推理のステップ**: データの所在確認 → 振る舞いのデータ側への移動 → サービスクラスの委譲化
- **ロックからのメッセージ**: データを剥き出しにするな。彼らに知性を与え、自ら行動させよ。

## 実装計画

### Before（貧弱なドメインモデル）

```perl
package Order;
use Moo;
# ゲッター/セッターしかない「全裸の」データクラス
has amount => (is => 'rw');
has user_type => (is => 'rw'); # 'normal', 'premium'

package OrderService;
use Moo;

sub calculate_total ($self, $order) {
    # データをひん剥いて（getして）外部で計算している
    my $amount = $order->amount;
    my $user_type = $order->user_type;
    
    my $discount = 0;
    if ($user_type eq 'premium') {
        if ($amount >= 10000) {
            $discount = $amount * 0.15;
        } else {
            $discount = $amount * 0.05;
        }
    }
    
    return $amount - $discount;
}
```

### After（Tell, Don't Ask）

```perl
package Order;
use Moo;
# データ（プロパティ）を隠蔽するか、読み取り専用にする
has _amount => (is => 'ro', init_arg => 'amount');
has _user_type => (is => 'ro', init_arg => 'user_type');

# 自分自身の状態を使って計算する（振る舞いを持つ）
sub calculate_total ($self) {
    return $self->_amount - $self->_calculate_discount;
}

sub _calculate_discount ($self) {
    return 0 unless $self->_user_type eq 'premium';
    return $self->_amount >= 10000 ? $self->_amount * 0.15 : $self->_amount * 0.05;
}

package OrderService;
use Moo;

sub process_order ($self, $order) {
    # オブジェクトに「計算しろ（Tell）」と命じるだけ。中は見ない（Don't Ask）
    my $total = $order->calculate_total;
    # 決済処理など他のフローへ続く...
    return $total;
}
```

## メタデータ・構成情報
- **slug**: `code-detective-anemic-domain-model`
- **カテゴリ**: [tech]
- **タグ**: [design-pattern, perl, moo, tell-dont-ask, anemic-domain-model, refactoring, code-detective]
