---
date: 2026-03-29T18:00:00+09:00
description: 'Middle Man（コードスメル / アンチパターン）に関する調査結果'
staleness_category: stable
tags:
  - research
  - middle-man
  - code-smell
  - delegation
  - law-of-demeter
  - refactoring
  - perl
  - moo
  - handles
title: Middle Man（コードスメル）調査ドキュメント
---

# Middle Man（コードスメル / アンチパターン）— 調査レポート

**調査日**: 2026年3月29日
**技術スタック**: Perl / Moo

---

## 1. 公式・権威ある定義

### 1.1 Martin Fowler による定義（Refactoring, 第2版）

**【事実】** Martin Fowler は著書 *Refactoring: Improving the Design of Existing Code*（初版1999年、第2版2018年）で Middle Man を **Couplers**（結合度に関するスメル）カテゴリのコードスメルとして定義しています。

Fowler の定義の核心：
> 「委譲（delegation）はカプセル化の手段として有用だが、行き過ぎることがある。あるクラスのインターフェースの半分以上のメソッドが、別のクラスに委譲しているだけなら、そのクラスは Middle Man である」

**出典**: Martin Fowler, *Refactoring: Improving the Design of Existing Code*, 2nd Edition, Addison-Wesley, 2018

### 1.2 Refactoring Guru による定義

**【事実】** Refactoring Guru（refactoring.guru）では Middle Man を以下のように説明しています：

- **分類**: Couplers（結合度スメル）— Feature Envy, Inappropriate Intimacy, Message Chains と同カテゴリ
- **兆候と症状**: 「クラスがただ一つのアクション — 別クラスへの委譲 — だけを行っているなら、そのクラスはなぜ存在するのか？」
- **原因**: Message Chains（メッセージチェーン）の**過剰な排除**の結果として発生する。あるいは、有用な処理が徐々に他のクラスに移動された結果、空の殻だけが残ることで発生する
- **治療法**: Remove Middle Man リファクタリング
- **効果**: コードの冗長さが減少する

**出典**: https://refactoring.guru/smells/middle-man

### 1.3 例外（Middle Man を除去すべきでないケース）

**【事実】** Refactoring Guru は以下の場合に Middle Man を維持すべきとしています：

- クラス間の**依存関係を回避する**目的で意図的に作られた Middle Man
- **Proxy パターン**や **Decorator パターン**など、設計パターンとして意図的に作られた Middle Man

**出典**: https://refactoring.guru/smells/middle-man

### 1.4 Wiki C2（Portland Pattern Repository）

**【事実】** Wiki C2 では以下の議論が記録されています：

- Middle Man は **Mediator パターン**や **Facade パターン**と混同されやすい
- Mediator/Facade が「チョークポイント」（制御の集約点）としてアスペクト的な役割を果たしている場合は、Middle Man ではない
- 「プログラムの機能に見えない（invisible）サイドアスペクトをカバーしているなら、そのコードは Middle Man に見えても実はそうではない。Middle Man を使ってアスペクトを実装した瞬間に、スメルは消える」

**出典**: https://wiki.c2.com/?MiddleMan

---

## 2. Middle Man と Message Chains の双対関係

### 2.1 Hide Delegate と Remove Middle Man の往復

**【事実】** Refactoring Guru は Hide Delegate と Remove Middle Man を**対になるリファクタリング手法**として位置づけています。

```
Message Chains スメル
    ↓ 治療: Hide Delegate（委譲を隠す）
    ↓ ※ やりすぎると…
Middle Man スメル
    ↓ 治療: Remove Middle Man（中間者を除去）
    ↓ ※ やりすぎると…
Message Chains スメル（振り出しに戻る）
```

**Hide Delegate**:
- **問題**: クライアントがオブジェクト A のフィールドからオブジェクト B を取得し、B のメソッドを呼ぶ
- **解決**: A に新しいメソッドを作り、B への呼び出しを委譲する
- **利点**: クライアントはオブジェクト B を知る必要がなくなる
- **欠点**: 「過剰な数の委譲メソッドを作ると、サーバークラスが不要な仲介者（Middle Man）になってしまう」

**出典**: https://refactoring.guru/hide-delegate

**Message Chains**:
- **兆候**: `$a->b()->c()->d()` のような連鎖的呼び出し
- **治療**: Hide Delegate を適用
- **注意**: 「過度に攻撃的な委譲の隠蔽は、機能が実際にどこで発生しているかが分かりにくいコードを生む。つまり Middle Man スメルを避けよ」

**出典**: https://refactoring.guru/smells/message-chains

### 2.2 振り子のジレンマ

**【推論】** この構造から以下が導けます：

1. Hide Delegate と Remove Middle Man は **スペクトルの両端** に位置する
2. どちらかの極端に振れると、対応するコードスメルが発生する
3. 適切なバランスポイントは **コンテキスト依存** であり、機械的には決定できない
4. これは本質的に **Law of Demeter の遵守** と **Middle Man の回避** のトレードオフと同一の問題です

---

## 3. Law of Demeter との関係 — 委譲の「やりすぎ」vs「やらなさ」

### 3.1 Law of Demeter の要約

**【事実】** Law of Demeter（LoD, 1987年）は以下を規定するガイドラインです：

> メソッド `m` が呼び出せるメソッドは以下に限定される：
> 1. 自身（`$self`）のメソッド
> 2. `m` のパラメータのメソッド
> 3. `m` 内で生成されたオブジェクトのメソッド
> 4. `$self` の属性（直接保持するオブジェクト）のメソッド
> 5. `m` のスコープ内でアクセス可能なグローバル変数のメソッド

簡潔に言えば「ドットを1つだけ使え」— `$a->m()->n()` は LoD 違反だが `$a->m()` は違反ではない。

**出典**: https://en.wikipedia.org/wiki/Law_of_Demeter

### 3.2 Law of Demeter の利点と欠点

**【事実】** Wikipedia の LoD 記事は、1996年の Basili らの実験結果を引用しています：

- **利点**: RFC（Response For a Class）が低くなるとバグ発生確率が低下する。LoD 遵守は RFC を下げる
- **欠点**: WMC（Weighted Methods per Class）が増加するとバグ発生確率が上昇する。LoD 遵守は WMC を**上げうる**
- LoD に従うと「多くの小さなラッパーメソッドを書かなければならず、顕著な時間・空間オーバーヘッドを追加する可能性がある」

**出典**: https://en.wikipedia.org/wiki/Law_of_Demeter (Basili et al., 1996; Appleton, "Introducing Demeter and its Laws")

### 3.3 トレードオフの核心

**【推論】** LoD と Middle Man の関係を図示すると：

```
委譲しない（LoD違反 / Message Chains）
  ← ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ →
                              委譲しすぎ（Middle Man）

$order->customer->address->city    $order->customer_city
  ↑ LoD違反: 3つのドット              ↑ しかしこれを全メソッドに
                                       やると Middle Man に
```

- **LoD 違反側**: 連鎖呼び出しが多く、内部構造の変更がクライアントに波及する
- **Middle Man 側**: 委譲メソッドが大量に生まれ、クラスが「パススルー」だけの空っぽの殻になる

**【推論】** 判断基準は以下のように整理できます：

| 状況 | 推奨アプローチ |
|------|--------------|
| クライアントが常に同じチェーンを辿る | Hide Delegate（委譲メソッド追加） |
| 委譲先のほぼ全メソッドを委譲している | Remove Middle Man（直接アクセス許可） |
| 委譲先が頻繁に変更される | Hide Delegate（変更を吸収） |
| 委譲クラスが独自のロジックを持たない | Inline Class（クラス自体を統合）を検討 |
| セキュリティ/ACL 的な制御が必要 | Middle Man を維持（Proxy パターン） |

---

## 4. 「いつ Middle Man を除去すべきか」の判断基準

### 4.1 定量的指標

**【推論】** 以下の経験則が導けます（Fowler の「半分以上」ルールに基づく）：

1. **50%ルール**: クラスのメソッドの過半数が単純な委譲（引数もロジックも追加しない `$self->delegate->method(@_)` のパターン）なら、Middle Man の兆候
2. **値を追加しているか**: 委譲メソッドが引数の変換、バリデーション、ロギング、キャッシュなどの**追加価値**を提供しているなら、それは Middle Man ではない
3. **変更の頻度**: 委譲先に新しいメソッドが追加されるたびに、自動的に委譲メソッドも追加しなければならないなら、Middle Man のサイン

### 4.2 質的判断基準

**【推論】** 以下の質問に「はい」が多いほど、Remove Middle Man を検討すべきです：

- [ ] このクラスに委譲以外のロジックはあるか？ → **ない**なら Middle Man
- [ ] 委譲先のインターフェースが変わるとき、このクラスも変えなければならないか？ → **はい**なら Middle Man
- [ ] クライアントが結局このクラスを「透明」と見なしているか？ → **はい**なら Middle Man
- [ ] このクラスが存在しない場合、クライアントコードはどれだけ複雑になるか？ → **ほぼ同じ**なら Middle Man

### 4.3 除去すべきでないケース（再掲・補足）

**【事実】** 以下のケースでは Middle Man を維持するべきです：

1. **Proxy パターン**: アクセス制御、遅延初期化、リモートプロキシ
2. **Decorator パターン**: 機能の動的追加
3. **Facade パターン**: 複雑なサブシステムの簡略化インターフェース
4. **Adapter パターン**: インターフェースの変換
5. **アスペクト的関心事**: ロギング、トランザクション管理、セキュリティチェック

---

## 5. Remove Middle Man — 具体的な手順

### 5.1 Refactoring Guru の手順

**【事実】** Remove Middle Man の手順は以下のとおりです：

1. 委譲先オブジェクト（delegate）へのアクセサ（getter）を **サーバークラス** に作成する
2. サーバークラス内の委譲メソッドの呼び出しを、**委譲先への直接呼び出し**に置き換える
3. 不要になった委譲メソッドを削除する

**出典**: https://refactoring.guru/remove-middle-man

### 5.2 Perl/Moo での具体的手順

**【推論】** Moo で Remove Middle Man を行う場合の手順：

#### Before（Middle Man 状態）:

```perl
package Order;
use Moo;

has customer => (
    is      => 'ro',
    handles => [qw(
        name
        email
        phone
        address
        city
        zip_code
        country
        credit_score
        loyalty_points
        preferred_language
    )],
);

# Order クラスは Customer の全メソッドを委譲しているだけ
# → Middle Man スメル
```

#### Step 1: 委譲先へのアクセサを公開する

```perl
package Order;
use Moo;

has customer => (
    is      => 'ro',
    # handles を削除（または必要なものだけに絞る）
);
```

#### Step 2: クライアント側を修正

```perl
# Before（Middle Man 経由）
my $name = $order->name;
my $city = $order->city;

# After（直接アクセス）
my $name = $order->customer->name;
my $city = $order->customer->address->city;  # ← ただし連鎖が深い場合は注意
```

#### Step 3: 必要な委譲だけを残す

```perl
package Order;
use Moo;

has customer => (
    is      => 'ro',
    handles => [qw(name email)],  # ビジネスロジックで頻繁に使う最小限だけ
);
```

---

## 6. Perl/Moo における `handles` と Middle Man

### 6.1 Moo の `handles` オプションの仕様

**【事実】** Moo の `handles` は以下の3形式をサポートします：

```perl
# 形式1: ロール名（ロールのインターフェース全体を委譲）
has robot => (
    is      => 'ro',
    handles => 'RobotRole',
);

# 形式2: 配列（メソッド名をそのまま委譲）
has delegate => (
    is      => 'ro',
    handles => [qw(one two three)],
);

# 形式3: ハッシュ（メソッド名を変換して委譲）
has delegate => (
    is      => 'ro',
    handles => {
        my_method => 'their_method',
    },
);
```

**注意**: Moose と異なり、Moo は正規表現 (`qr/.../`) による handles をサポートしません。これは意図的な設計判断です。

**出典**: https://metacpan.org/pod/Moo#handles

### 6.2 Moose::Manual::Delegation の知見

**【事実】** Moose の公式ドキュメントは委譲を以下のように説明しています：

> 「Delegation は "has-a" 関係の複雑なセットを簡略化し、1つのクラスから統一されたAPIを提示する機能である。委譲によって、クラスの利用者はそのクラスが含む全オブジェクトを知る必要がなくなり、学ぶべき API の量が減る」

Moose は以下の委譲形式をサポートします：
- 配列参照（メソッド名リスト）
- ハッシュ参照（メソッド名マッピング）
- 正規表現（`qr/^(?:host|path|query.*)/`）
- ロール名（ロールのメソッド一覧から自動生成）
- コード参照（カスタムマッピング生成）

**出典**: https://metacpan.org/pod/Moose::Manual::Delegation

### 6.3 `handles` の過剰使用が問題になる理由

**【推論】** 以下の観点から `handles` の全委譲パターンは問題です：

#### パターン1: ロール名による全委譲（危険度: 高）

```perl
# 危険: ロールの全メソッドが自動的に委譲される
has engine => (
    is      => 'ro',
    handles => 'EngineRole',
);
```

**問題点**:
- ロールにメソッドが追加されると、**暗黙的に**委譲メソッドも増える
- クラスのインターフェースが制御不能になる
- 何が委譲されているか、コードを読んだだけでは分からない

#### パターン2: 大量の配列委譲（危険度: 中）

```perl
# 問題: ほぼ全メソッドを委譲している
has database => (
    is      => 'ro',
    handles => [qw(
        connect disconnect query execute
        begin_transaction commit rollback
        prepare bind_param fetch fetchrow
        tables columns primary_key
        # ...20個以上のメソッド
    )],
);
```

**問題点**:
- このクラスは DBI のラッパーに過ぎない
- クライアントに `$obj->database` を直接使わせた方が明快
- DBI に新しいメソッドが必要になるたびに handles リストを更新する必要がある

#### パターン3: 選択的委譲（推奨）

```perl
# 良い: 必要最小限のメソッドだけを委譲
has database => (
    is      => 'ro',
    handles => {
        run_query => 'execute',  # 名前を変換して意味を明確化
    },
);

# ビジネスロジックを追加する委譲は価値がある
sub find_active_users {
    my ($self) = @_;
    return $self->run_query(
        'SELECT * FROM users WHERE active = ?', [1]
    );
}
```

### 6.4 Moo 特有の注意点

**【事実】** Moo は Moose と異なり以下の制約があります：

1. **正規表現 handles なし**: `handles => qr/.../` は使えない（Moose のみ）。これは実は Middle Man 防止に寄与する — 意図せず大量のメソッドを委譲するリスクが減る
2. **Native Delegation なし**: Moose の `traits => ['Array']` のようなネイティブ委譲は Moo 単体ではサポートされない（`Sub::HandlesVia` モジュールで代替可能）
3. **メタプロトコルなし**: Moo は軽量であるため、委譲の内省（introspection）が限定的。これにより「何が委譲されているか」を**プログラム的に**把握しにくい

### 6.5 Moo での Middle Man 回避ベストプラクティス

**【推論】** 以下のガイドラインを提案します：

1. **handles は10メソッド以下**: 経験則として、1つの属性の handles に10を超えるメソッドを列挙している場合は設計を見直す
2. **名前変換を活用**: ハッシュ形式の handles でメソッド名を変換することで、「このクラスが提供するインターフェース」を明確にする
3. **ロジック追加の委譲は OK**: 委譲メソッドがバリデーション、変換、ログ記録などの追加価値を提供するなら Middle Man ではない
4. **「このクラスは何の責任を持つのか」を問う**: 答えが「委譲先への橋渡し」だけなら、Middle Man の疑いあり

---

## 7. 類似パターンとの比較・使い分け

### 7.1 比較表

**【推論】** 以下の比較は定義に基づく分析です：

| パターン | 目的 | Middle Man か？ |
|---------|------|---------------|
| **Proxy** | アクセス制御・遅延初期化 | ✗ — 付加価値がある |
| **Decorator** | 機能の動的追加 | ✗ — 振る舞いを変更している |
| **Adapter** | インターフェース変換 | ✗ — 互換性を提供している |
| **Facade** | 複雑なサブシステムの簡略化 | △ — 場合による |
| **Mediator** | オブジェクト間通信の集約 | ✗ — 調整ロジックがある |
| **純粋な委譲クラス** | ただの横流し | ✓ — Middle Man |

### 7.2 Facade との微妙な違い

**【推論】** Facade と Middle Man の境界は曖昧です：

- **Facade**: 複数のサブシステムを束ね、**簡略化された統一インターフェース**を提供する。サブシステムの組み合わせ方に「知性」がある
- **Middle Man**: 1つの委譲先に対して、ほぼ**そのまま**メソッドを転送する。追加価値がない

```perl
# Facade（OK）: 複数のオブジェクトを組み合わせている
sub place_order {
    my ($self, $items) = @_;
    $self->inventory->reserve($items);
    $self->payment->charge($self->customer);
    $self->shipping->schedule($self->customer->address);
}

# Middle Man（スメル）: ただの転送
sub reserve    { shift->inventory->reserve(@_) }
sub charge     { shift->payment->charge(@_) }
sub schedule   { shift->shipping->schedule(@_) }
```

---

## 8. 最新の議論・批判・再評価

### 8.1 LoD の「ラッパーメソッド問題」

**【事実】** Wikipedia の Law of Demeter の Disadvantages セクションおよび外部文献で指摘されている批判：

> 「LoD に従うと、コンポーネントへの呼び出しを伝播するための多くの小さなラッパーメソッドを書かなければならず、顕著な時間・空間オーバーヘッドが追加される可能性がある」
> — Brad Appleton, "Introducing Demeter and its Laws"

> 「欠点は、委譲やコンテナ走査以外にほとんど何もしない小さなラッパーメソッドを大量に書くことになることだ。トレードオフは、そのコストと高いクラス結合度の間にある」
> — The Pragmatic Programmers, "Tell, Don't Ask"

**出典**: https://en.wikipedia.org/wiki/Law_of_Demeter (参考文献 9, 10)

### 8.2 Poor Design vs LoD の区別

**【事実】** Wikipedia は、LoD による「拡大されたインターフェース」の問題は LoD 自体の帰結ではなく**設計の不備**であると指摘しています：

> 「ラッパーメソッドが使われているなら、それはラッパー経由で呼ばれているオブジェクトが、呼び出し元クラスの依存関係であるべきだということを意味する」

つまり、ラッパーが過剰に感じるなら、そもそものクラス構造（依存関係の方向）が間違っている可能性がある。

**出典**: https://en.wikipedia.org/wiki/Law_of_Demeter

### 8.3 アスペクト指向プログラミングとの関係

**【事実】** LoD の提唱者 Karl Lieberherr は、LoD の欠点を AOP（Aspect-Oriented Programming）で解決するアプローチを提案しています。Wiki C2 でも「Middle Man を使ってアスペクトを実装した瞬間にスメルは消える」と述べられています。

**出典**: Lieberherr et al., "Aspect-oriented programming with adaptive methods", 2001; https://wiki.c2.com/?MiddleMan

---

## 9. まとめ — Middle Man の構造的理解

### 9.1 スメルの位置づけ

```
         Message Chains          Middle Man
  コードスメル ←───────────────────→ コードスメル
              |                    |
              | Hide Delegate      | Remove Middle Man
              | (委譲メソッド追加)    | (委譲メソッド除去)
              ↓                    ↓
              適切なバランスポイント
              （コンテキスト依存）
```

### 9.2 Moo での実践的チェックリスト

**【推論】** 記事執筆に向けた実践的チェックリスト：

- [ ] `handles` のメソッド数が属性あたり5〜10以下か
- [ ] 各委譲メソッドは**追加価値**（バリデーション、変換、ログ等）を提供しているか
- [ ] クラスが委譲以外の**固有のビジネスロジック**を持っているか
- [ ] ロール名を handles に使っている場合、ロールのメソッド数を把握しているか
- [ ] 委譲先にメソッドが追加されたとき、自動的にこのクラスも変更が必要か
- [ ] クライアントが委譲先を直接使う場合と比べて、複雑さが軽減されているか

### 9.3 記事での核心メッセージ

**【仮定】** 記事のテーマとして以下のメッセージが有効と考えます：

> 「委譲はカプセル化の剣だが、両刃である。Law of Demeter を守るために振るい過ぎると、Middle Man という別の傷を負う。剣の長さ — つまり handles リストの長さ — が『このクラスは何者か』を問うシグナルになる」

---

## 出典一覧

| # | 出典 | URL | 区分 |
|---|------|-----|------|
| 1 | Refactoring Guru - Middle Man | https://refactoring.guru/smells/middle-man | 一次情報 |
| 2 | Refactoring Guru - Remove Middle Man | https://refactoring.guru/remove-middle-man | 一次情報 |
| 3 | Refactoring Guru - Hide Delegate | https://refactoring.guru/hide-delegate | 一次情報 |
| 4 | Refactoring Guru - Message Chains | https://refactoring.guru/smells/message-chains | 一次情報 |
| 5 | Wikipedia - Law of Demeter | https://en.wikipedia.org/wiki/Law_of_Demeter | 二次情報 |
| 6 | Wiki C2 - MiddleMan | https://wiki.c2.com/?MiddleMan | コミュニティ |
| 7 | MetaCPAN - Moo | https://metacpan.org/pod/Moo | 一次情報 |
| 8 | MetaCPAN - Moose::Manual::Delegation | https://metacpan.org/pod/Moose::Manual::Delegation | 一次情報 |
| 9 | Martin Fowler, *Refactoring*, 2nd Ed., 2018 | （書籍） | 一次情報 |
| 10 | Basili et al., IEEE TSE, 1996 | https://doi.org/10.1109/32.544352 | 学術論文 |
