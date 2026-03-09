---
date: 2026-03-10T07:15:00+09:00
description: コード探偵ロックの事件簿 第N話「便利すぎる万能薬（Singletonの誤用）とDependency Injectionによる解決」の構造案
title: '連載構造案 - コード探偵ロックの事件簿【Singleton／DI】'
---

# 連載構造案：コード探偵ロックの事件簿【Singletonの誤用／DI】統合版

## 前提情報

- **シリーズ名**: コード探偵ロックの事件簿
- **テーマ**: レガシーコード・アンチパターンの解決 × 設計技法
- **技術スタック**: Perl (Mooを利用)
- **今回のアンチパターン**: Singletonの誤用（実質的なグローバル変数化、Ambient Context）
- **今回の解決策**: Dependency Injection（依存性の注入、コンストラクタインジェクション）
- **形式**: 統合版（1つの完結した記事）

## 登場人物

- **ロック**: 主人公。ホームズ気取りのコード探偵。Perlの泥臭いレガシーコード愛好家。
- **ワトソン君（依頼人）**: 今回の語り手。真面目で几帳面、プレッシャーを抱え込みがちな運用担当者。前任者の残した「超絶便利クラス」の挙動不審に怯えている。

## ストーリー構成（探偵メタファー）

### I. 依頼（事務所への来客）
- **状況**: 依頼人（ワトソン君）が「レガシー・コード・インベスティゲーション（LCI）」に、疲労困憊の顔でやってくる。
- **主訴**: 「前任者が『どこからでも呼べて超絶便利だから！』と言って残していったデータベース管理クラスがあるんです。でも、バッチ処理を複数回すとデータが混ざったり、テストを流すと本番DBのデータが上書きされたりするんです……！ 便利すぎて、これなしじゃシステムが動かないのに……」

### II. 現場検証（コードの指紋）
- **Beforeコード提示**: `MyCompany::Database->get_instance()` （Singleton）が、ドメインロジックのあちこちのメソッド内で直接呼び出されている。
- **ロックの推理**: 「『どこからでも呼べる』ということは、『どこからでも**書き換えられるし、影響を受ける**』ということだ。しかもシステム全体でたった1つしか存在しないなら、Aの処理が汚した状態をBの処理がそのまま読み込んでしまう。これは優れた設計（Singleton）などではない。単なる『**ガラの悪いグローバル変数**』だよ」

### III. 推理披露（鮮やかなリファクタリング）
- **解説と処置**: ロックがSingletonを解体し、Dependency Injection（依存性の注入）へのリファクタリングを実演する。
- **解決へのアプローチ**:
  1. クラスの奥底で自らインスタンスを取得（Pull）するのをやめる。
  2. 必要な部品（DBコネクションなど）は、生成時（コンストラクタ）に外から渡してあげる（Pushする = DI）設計に変更する。
  3. テスト時は「空のモックDB」を渡し、本番時は「本物のDB」を渡せるようになることを示す。
- **ワトソン君の驚き**: 「すごい！ 中のコードを一言も変えずに、外から渡すものを変えるだけで、テスト用と本番用を切り替えられるんですね！ これならデータが混ざるホラー現象も起きません！」

### IV. 解決（事件の終わり）
- **結果**: バッチ処理は安全になり、テスト環境も守られた。
- **ロックの締め言葉**: 「必要な道具は、隠れて持ち込むのではなく、堂々と玄関（コンストラクタ）から受け取りたまえ。それが信頼されるコードの作法だ」
- **オチ**: DI（外から渡すこと）の美しさと安全性に感動したワトソン君。これまでの不安から解放された反動で、今度は**「少しでもクラスの中で何かを決定したくない病（過剰な抽象化）」**に陥る。
  数日後、ただ現在時刻をログに出すだけの関数に `LoggerFactory` と `TimeProviderInterface` と `StringFormatterInterface` をコンストラクタで延々と要求する、重厚長大なJavaフレームワーク顔負けのコードを書き上げ、ロックに「……ただいまの時刻を知るために、時計職人とカレンダーの歴史からいちいち説明させるつもりか？」と呆れられる。

### V. 探偵の調査報告書
- **表**: Singletonの誤用・グローバル変数化（容疑） -> Dependency Injection（真実） -> テスタビリティの向上と依存の明示化（証拠）
- **推理のステップ**:
  1. クラス内で暗黙に取得している外部依存（DBやAPIクライアントなど）を特定する。
  2. その依存を自前で確保する（`new` や `get_instance` する）のをやめ、コンストラクタの引数（アトリビュート）として定義する。
  3. クラスを利用する側（呼び出し元）が、責任を持って適切な依存オブジェクトを注入（Inject）する。
- **ロックからのメッセージ**: 「設計とはトレードオフだ。疎結合を追い求めすぎて、コードを読むための地図が迷路になっては本末転倒だよ」

## 実装計画 (Code Design)

### Before (Singletonへの密結合)
```perl
package MyCompany::ReportGenerator;
use strict;
use warnings;
use MyCompany::Database; # Singletonクラス

sub new { bless {}, shift }

sub generate {
    my ($self, $user_id) = @_;
    # クラスの内部で直接Singletonを呼んでいる（依存が隠蔽されている）
    # テスト時にMyCompany::Databaseが本番を向いていると大惨事になる
    my $db = MyCompany::Database->get_instance();
    my $data = $db->fetch_user_data($user_id);
    
    return "Report for $data->{name}";
}
1;
```

### After (Dependency Injectionへのリファクタリング)

```perl
package MyCompany::ReportGenerator;
use Moo;
# データベース接続は外から受け取る
has db => (
    is       => 'ro',
    required => 1,
    # isa => Object  # 厳密にはRole(Interface)を指定するとよい
);

sub generate {
    my ($self, $user_id) = @_;
    # 注入されたDBオブジェクトを使用する（本物かモックかは気にしない）
    my $data = $self->db->fetch_user_data($user_id);
    
    return "Report for $data->{name}";
}
1;

# 利用側（本番コード）
# my $real_db = MyCompany::Database->new(...);
# my $generator = MyCompany::ReportGenerator->new(db => $real_db);

# 利用側（テストコード）
# my $mock_db = TestMockDB->new();
# my $generator = MyCompany::ReportGenerator->new(db => $mock_db);
```

## メタデータ・構成情報
- **slug**: `code-detective-singleton`
- **カテゴリ**: [tech]
- **タグ**: [design-pattern, perl, moo, singleton, dependency-injection, anti-pattern, testing, code-detective]
