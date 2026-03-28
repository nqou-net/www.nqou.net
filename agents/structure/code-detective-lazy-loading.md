# 構造案: コード探偵ロックの事件簿【Lazy Loading】

## メタ情報

| 項目 | 内容 |
|------|------|
| タイトル | コード探偵ロックの事件簿【Lazy Loading】開かずの重荷物〜読まない調書が押し潰す証拠庫〜 |
| パターン | Lazy Loading |
| アンチパターン | Eager Loading（過剰な事前読み込み）——オブジェクト生成時に関連データをすべて即座に読み込み、使わないデータにまでコストを払う |
| slug | lazy-loading |
| 公開日時 | 2026-04-15T07:07:05+09:00 |
| ファイルパス | content/post/2026/04/15/070705.md |

---

## 語り部プロファイル（依頼人）

| 項目 | 内容 |
|------|------|
| 名前 | 園田 航平（そのだ こうへい） |
| 年齢 | 27歳 |
| 職種 | 社内業務システムのバックエンド開発者 |
| 一人称 | 僕 |
| 性格 | おおらかで楽観的だが、パフォーマンスに対する危機感が薄い。「とりあえず動けばOK」精神で来たが、ついに限界が来た |
| 背景 | 社内の人事管理システムを担当。社員一覧画面が異常に遅い。社員オブジェクトを生成する際に、部署情報・勤怠履歴・評価記録をすべて即座に読み込んでいる。一覧表示に必要なのは名前とIDだけなのに、100人分の全関連データが一括ロードされる |

---

## コード設計

### Beforeコード（アンチパターン: Eager Loading）

```perl
package DataStore;
use Moo;
use Types::Standard qw(HashRef);

has _data => (is => 'ro', isa => HashRef, default => sub { {} });

our $TOTAL_QUERIES = 0;

sub register {
    my ($self, $key, $value) = @_;
    $self->_data->{$key} = $value;
}

sub query {
    my ($self, $key) = @_;
    $TOTAL_QUERIES++;
    return $self->_data->{$key};
}

sub reset_counter { $TOTAL_QUERIES = 0 }
```

```perl
package Employee;
use Moo;
use Types::Standard qw(Str Int ArrayRef HashRef Object);

has id         => (is => 'ro', isa => Int, required => 1);
has name       => (is => 'ro', isa => Str, required => 1);
has store      => (is => 'ro', isa => Object, required => 1);

# Eager Loading: 生成時に即座にすべて読み込む
has department => (is => 'ro', isa => HashRef, lazy => 0,
                   builder => '_build_department');
has attendance => (is => 'ro', isa => ArrayRef, lazy => 0,
                   builder => '_build_attendance');
has evaluations => (is => 'ro', isa => ArrayRef, lazy => 0,
                    builder => '_build_evaluations');

sub _build_department {
    my ($self) = @_;
    return $self->store->query("dept:" . $self->id) // {};
}

sub _build_attendance {
    my ($self) = @_;
    return $self->store->query("attendance:" . $self->id) // [];
}

sub _build_evaluations {
    my ($self) = @_;
    return $self->store->query("evaluations:" . $self->id) // [];
}
```

**問題点**:
- `Employee->new` でインスタンス生成時に department, attendance, evaluations がすべて即座に読み込まれる
- 一覧表示で名前とIDだけ使う場合でも、3回のクエリが走る
- 100人分で300回の無駄なクエリが発生

### Afterコード（Lazy Loading パターン）

```perl
package Employee;
use Moo;
use Types::Standard qw(Str Int ArrayRef HashRef Object);

has id         => (is => 'ro', isa => Int, required => 1);
has name       => (is => 'ro', isa => Str, required => 1);
has store      => (is => 'ro', isa => Object, required => 1);

# Lazy Loading: アクセスされた時点で初めて読み込む
has department => (is => 'lazy', isa => HashRef);
has attendance => (is => 'lazy', isa => ArrayRef);
has evaluations => (is => 'lazy', isa => ArrayRef);

sub _build_department {
    my ($self) = @_;
    return $self->store->query("dept:" . $self->id) // {};
}

sub _build_attendance {
    my ($self) = @_;
    return $self->store->query("attendance:" . $self->id) // [];
}

sub _build_evaluations {
    my ($self) = @_;
    return $self->store->query("evaluations:" . $self->id) // [];
}
```

**改善点**:
- `is => 'lazy'` により、各属性は最初にアクセスされるまで builder が実行されない
- 一覧表示で name と id だけ使う場合、クエリはゼロ
- department を表示する画面では department だけが読み込まれる
- 必要なデータだけが必要な時に読み込まれる

---

## 5幕プロット

### I. 依頼（事務所への来客）

- 場面: LCI事務所。ロックは机の上に大量の未読書籍を積み上げている（「読むべき資料は手元に置く主義だ」と言いつつ、大半は開いてもいない）
- 園田が「社員一覧画面が重くて、表示に十秒以上かかるんです」と訪問
- ロック「開かずの重荷物だね。事件のたびに証拠品を全件倉庫から引き出す捜査官がいるかね？」
- 園田「証拠品？　社員データの話なんですが」

### II. 現場検証（コードの指紋）

- ロックが Employee クラスを精読
- 「生成時に department, attendance, evaluations をすべて読み込んでいる。100人の一覧表示で300回のクエリだ」
- 園田「でも、どの画面でどのデータを使うか分からないので、念のため全部読み込んでおけば——」
- ロック「念のため、が300回のクエリを生んでいる。初歩的なにおいだよ。**Eager Loading**——使うかどうか分からないデータを先に全部読む過剰な事前読み込みだ」

### III. 推理披露（鮮やかなリファクタリング）

- ロック「解決策は **Lazy Loading** だ。Moo の `is => 'lazy'` を使う」
- `lazy` の仕組み（builder が最初のアクセスまで遅延される）を解説
- Before と After の差分がわずか3行の変更であることを強調
- 園田「たった3箇所の変更で……？」
- ロック「必要な証人だけ呼べばいい。全員を法廷に連れてくる必要はない」

### IV. 解決（平和なビルド）

- テスト実行。Eager は100人で300クエリ、Lazy は100人で0クエリ（一覧表示の場合）
- 園田「一覧表示のクエリが300回からゼロに……！」
- ロック「報酬は、削減したクエリ数の百分の一杯のコーヒーでいい」
- 園田（心の中）：「三杯か……まあ妥当だ」

### V. 報告書（探偵の調査報告書）

---

## フロントマター（予定）

```yaml
title: "コード探偵ロックの事件簿【Lazy Loading】開かずの重荷物〜読まない調書が押し潰す証拠庫〜"
date: "2026-04-15T07:07:05+09:00"
draft: false
categories: [tech]
tags:
  - design-pattern
  - perl
  - moo
  - lazy-loading
  - eager-loading
  - refactoring
  - code-detective
```
