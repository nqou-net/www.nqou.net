---
date: 2025-12-31T23:10:00+09:00
description: Chain of Responsibilityパターンの概要、用途、実装サンプル、利点・欠点を整理した調査ドキュメント
draft: false
epoch: 1767190200
image: /favicon.png
iso8601: 2025-12-31T23:10:00+09:00
tags:
  - design-patterns
  - chain-of-responsibility
  - behavioral-patterns
  - gof
title: Chain of Responsibilityパターン調査ドキュメント
---

# Chain of Responsibilityパターン調査ドキュメント

## 調査目的

振る舞いパターンである**Chain of Responsibility**について、概要・用途・実装サンプル・利点と欠点を整理し、記事執筆時の基礎資料とする。

- 調査対象: Chain of Responsibilityパターンの定義と構造、適用シナリオ、コード例、メリット/デメリット
- 想定読者: デザインパターンを実務適用したいエンジニア
- 調査実施日: 2025年12月31日

---

## 1. 概要

### 1.1 定義

Chain of Responsibility（責務の連鎖）パターンは、**複数のハンドラを直列に連結し、リクエストを処理可能なハンドラに委譲する**振る舞いパターンです。送信者（クライアント）と受信者（ハンドラ）を疎結合にし、条件分岐の集中を避けます。

**要点**:

- ハンドラ（抽象または基底クラス）は次のハンドラへの参照を保持し、処理できなければ委譲する
- クライアントは最初のハンドラに渡すだけでよく、どのハンドラが処理するかを意識しない
- ハンドラの追加・差し替え・順序変更が容易で、Open/Closed原則を支援する
- 非同期処理にも応用できるが、同期チェーンが基本

**根拠**:

- GoF「Design Patterns」で振る舞いパターンの一つとして定義され、リクエスト送信者と受信者の結合度を下げる目的が示されている
- ミドルウェアパイプライン（HTTP、ロギング、バリデーション）など多数の実装例で同一の構造が採用されている

### 1.2 主な構成要素と流れ

- **Handler（抽象ハンドラ）**: 処理メソッドと「次ハンドラ」への参照を持つ
- **Concrete Handler（具体ハンドラ）**: 条件を満たしたときに処理し、そうでなければ次へ渡す
- **Client**: 最初のハンドラにリクエストを渡すだけで連鎖を開始する
- **終了条件**: いずれかが処理するか、末尾まで到達して未処理となるかを設計で決める

---

## 2. 用途（適用シナリオ）

- **HTTPミドルウェアのチェーン**: 認証→レート制限→ロギング→ハンドラの順で責務を分離する
- **入力バリデーションパイプライン**: フォーマットチェック→ドメインルール検証→権限確認の順で段階的に評価する
- **イベント処理/ロガーのフィルタリング**: 重要度やカテゴリに応じて適切なロガーが処理する
- **サポート問い合わせルーティング**: 一次対応→専門担当→マネージャーの順でエスカレーションする
- **ファイルシステムやUIのコマンド伝播**: 子→親コンポーネントにイベントをバブルさせ、処理者を見つける

---

## 3. サンプル実装（Perl 5.36+ / Moo）

以下はリクエスト種別に応じて処理を委譲する最小限の例です。Moo以外の外部依存はありません。シグネチャ構文はPerl 5.36以降の安定版を前提にしており、`use experimental 'signatures'`は不要です。ログ出力はデモ目的で`warn`を使用しているため、実運用では適切なロガーに置き換えます。

```perl
# Perl 5.36+ / Moo
package Handler {
  use Moo::Role;
  requires 'handle';
  requires 'set_next';
}

package BaseHandler {
  use Moo;
  with 'Handler';
  has next => (is => 'rw', predicate => 1);
  sub set_next ($self, $next) { $self->next($next); return $next; }
  sub _next_handler ($self) { return ($self->has_next && $self->next) ? $self->next : undef; }
  sub handle ($self, $req) {
    if (my $next = $self->_next_handler) { return $next->handle($req) }
    return "no handler";
  }
}

package AuthHandler {
  use Moo;
  extends 'BaseHandler';
  sub handle ($self, $req) {
    return "auth ok" if $req->{token};
    return $self->SUPER::handle($req);
  }
}

package LoggingHandler {
  use Moo;
  extends 'BaseHandler';
  sub handle ($self, $req) {
    # デモ目的でwarnを使用し、標準エラー出力に記録する
    warn "log: $req->{path}";
    # ログ出力後はパススルーで次のハンドラに委譲する
    return $self->SUPER::handle($req);
  }
}

my $chain = LoggingHandler->new;
$chain->set_next( AuthHandler->new );

say $chain->handle({ path => "/home" });             # STDERR: log: /home  / STDOUT: no handler
say $chain->handle({ path => "/home", token => 1 }); # STDERR: log: /home  / STDOUT: auth ok
```

---

## 4. 利点・欠点

**利点**:

- 条件分岐の集中を避け、責務を明確に分割できる
- ハンドラの追加・順序変更が容易で拡張性が高い
- クライアントは最初のハンドラに渡すだけでよく、疎結合になる
- 失敗時や未処理時のポリシーを差し替えやすい

**欠点**:

- どのハンドラが最終的に処理するかがコード上から直感しづらい
- チェーンが長い場合、デバッグが難しく、処理遅延を生む可能性がある
- 未処理リクエストの扱いを設計しないと、静かに破棄されるリスクがある
- ハンドラ間の共有状態を持たせると結合度が上がりやすい

---

## 5. 参考文献

{{< linkcard "https://en.wikipedia.org/wiki/Chain-of-responsibility_pattern" >}}
{{< linkcard "https://refactoring.guru/design-patterns/chain-of-responsibility" >}}
{{< linkcard "https://www.geeksforgeeks.org/chain-of-responsibility-design-pattern/" >}}
{{< linkcard "https://www.baeldung.com/chain-of-responsibility-pattern" >}}

---

## 6. レビューと改善ログ（3回）

- 第1版: 概要・用途・サンプル・利点欠点を初稿として整理
- 第2版: 用途を具体的なシナリオ列挙に拡充し、欠点にデバッグ難易度を追記
- 第3版（最終）: サンプルに外部依存の明示と未処理時の戻り値を補足し、参考文献を整理
