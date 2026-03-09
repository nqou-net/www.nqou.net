---
date: 2026-03-10T07:07:05+09:00
description: コード探偵ロックの事件簿 第N話「偽造された身分証（Primitive Obsession）とValue Objectによる解決」の構造案
title: '連載構造案 - コード探偵ロックの事件簿【Value Object】'
---

# 連載構造案：コード探偵ロックの事件簿【Value Object】統合版

## 前提情報

- **シリーズ名**: コード探偵ロックの事件簿
- **テーマ**: レガシーコード・アンチパターンの解決 × 設計技法
- **技術スタック**: Perl (Mooを利用, JSON::XS もしくは JSON::MaybeXS)
- **今回のアンチパターン**: Primitive Obsession（プリミティブ型への執着）
- **今回の解決策**: Value Object（値オブジェクト）
- **形式**: 統合版（1つの完結した記事）

## 登場人物

- **ロック**: 主人公。ホームズ気取りのコード探偵。Perlの泥臭いレガシーコード愛好家。
- **ワトソン君（依頼人）**: 今回の語り手。几帳面な若手プログラマー（女性）。最近、型に厳密な別システムのAPI連携を担当することになったが、JSONの型変換の罠にハマり発狂寸前。

## ストーリー構成（探偵メタファー）

### I. 依頼（事務所への来客）
- **状況**: 依頼人（ワトソン君）が「レガシー・コード・インベスティゲーション（LCI）」に半泣きで駆け込んでくる。
- **主訴**: 「Perlから別システムへ会員データ（電話番号や年齢など）をJSONで連携したんですが、日によって『年齢が文字列になっている』『電話番号が数値になっていて先頭の0が消えた』と連携先から怒られるんです！ 私は何もしてないのに型が勝手に変わるんです！」

### II. 現場検証（コードの指紋）
- **Beforeコード提示**: `$user->{age}` や `$user->{phone}` がただのスカラー変数（文字列や数値の区別が曖昧）で持ち回されている。途中で `+ 0` される計算があったり、ログ出力のために `.` で文字列結合されたりしているため、Perlの内部フラグ（IV/NV/PV）が変化している。
- **ロックの推理**: JSONモジュールは変数の内部フラグを見て型を決める性質を指摘。「変数をただの入れ物として扱うから、中身の『意味』がブレるのだよ。裸のまま街（システム）を歩かせるから、誰でも簡単に偽装できる紙切れのような身分証になってしまうのさ」

### III. 推理披露（鮮やかなリファクタリング）
- **解説と処置**: ロックがValue Objectへのリファクタリングを実演する。
- **解決へのアプローチ（Value Objectの適用）**:
  1. 「彼らに絶対脱げない『制服（Value Object）』を着せた前」。`PhoneNumber` や `Age` といった専用クラスをMooで作る。
  2. 生成時（`BUILD`）に厳格なバリデーションを行うことで、不正な値の混入を防ぐ。
  3. `TO_JSON` メソッド（JSONモジュールがオブジェクトをシリアライズする際に呼ぶ）を実装し、出力時の型（数値なのか文字列なのか）をクラス自身の責任として固定する。
- **ワトソン君の驚き**: 「どこでどう使われようと、JSONに出力される時は必ず正しい型とフォーマットになる…！ これならもう、別のシステムを落とさずに済みます！」

### IV. 解決（事件の終わり）
- **結果**: API連携は安定し、不正なデータがDBに入ることもなくなった。
- **ロックの締め言葉**: 「プリミティブ型は便利だが、それは無法地帯の便利さだよ。意味のあるデータには、意味のある名前（型）を与え給え」
- **オチ**: ワトソン君の几帳面な性格が暴走し、「なるほど！じゃあこの『名前』も、この『フラグ』も、『備考欄』も！ 全部 Value Object のクラスを作っちゃえば完璧ですね！！」と目を輝かせる。ロックは頭を抱え「……極端から極端へ走るのは君の悪い癖だ、ワトソン君」と呆れる。

### V. 探偵の調査報告書
- **表**: Primitive Obsession（容疑） -> Value Object（真実） -> 型の保証とバリデーションの集約（証拠）
- **推理のステップ**:
  1. ドメインの概念（電話番号、年齢など）を見つけ出す
  2. 専用のクラス（Value Object）を定義し、生成時にバリデーションを行う
  3. 不変（Immutable）な性質を持たせ、シリアライズ（JSON化など）の振る舞いをカプセル化する
- **ロックからのメッセージ**: 「何事にも限度というものがある。すべての路地裏に信号機を立てる必要はないのだよ」

## 実装計画 (Code Design)

### Before (レガシーなJSONエンコード)
```perl
use JSON::MaybeXS;

my $user = {
    id    => 12345,  # DB等でauto_incrementの数値として取得されることが多いが...
    age   => '25',     # 文字列として取得
    phone => '09012345678',
};

# どこかの処理で数値として扱われると内部フラグが変わる
$user->{age} += 1;

# どこかの処理で文字列結合されると内部フラグが変わる
my $log_msg = "User ID: " . $user->{id};

my $json = encode_json($user);
# 結果として、ageは数値(26)に、idは文字列("12345")になる場合もあれば、
# 処理の順序や暗黙の変換によって予期せぬ型で出力されてしまう。
```

### After (Value Object適用)

Value Objectの定義:
```perl
package User::Age;
use Moo;
use Types::Standard qw(Int);

has value => (
    is       => 'ro',
    isa      => Int,
    required => 1,
);

sub BUILD {
    my ($self) = @_;
    die "Age must be positive" if $self->value < 0;
}

# JSON::MaybeXS (convert_blessed) などで呼ばれる
sub TO_JSON {
    my ($self) = @_;
    return $self->value + 0; # 確実に数値として出力
}
1;

package User::PhoneNumber;
use Moo;
use Types::Standard qw(Str);

has value => (
    is       => 'ro',
    isa      => Str,
    required => 1,
);

sub BUILD {
    my ($self) = @_;
    die "Invalid phone number" unless $self->value =~ /^\d{10,11}$/;
}

sub TO_JSON {
    my ($self) = @_;
    return "" . $self->value; # 確実に文字列として出力
}
1;
```

Contextの簡略化と安定化:
```perl
use JSON::MaybeXS;

# オブジェクトとして生成（バリデーションも同時に実行される）
my $user = {
    id    => 12345, # これはプリミティブのままでも、適切に扱うかID用VOを作る
    age   => User::Age->new(value => 25),
    phone => User::PhoneNumber->new(value => '09012345678'),
};

# JSON化時に convert_blessed を有効にする
my $coder = JSON::MaybeXS->new(convert_blessed => 1);
my $json = $coder->encode($user);
# age は必ず数値、phone は必ず文字列として、安全に出力される
```

## メタデータ・構成情報
- **slug**: `code-detective-value-object-primitive-obsession`
- **カテゴリ**: [tech]
- **タグ**: [design-pattern, perl, moo, value-object, primitive-obsession, refactoring, code-detective]
