# 構造案: コード探偵ロックの事件簿【Dependency Injection】

## メタ情報

| 項目 | 内容 |
|------|------|
| タイトル | コード探偵ロックの事件簿【Dependency Injection】密室の共犯者たち〜硬直した依存関係を解き放て〜 |
| パターン | Dependency Injection（Constructor Injection） |
| アンチパターン | Hard-coded Dependencies（メソッド内で直接 new する密結合） |
| slug | dependency-injection |
| 公開日時 | 2026-04-10T07:07:05+09:00 |
| ファイルパス | content/post/2026/04/10/070705.md |

---

## 語り部プロファイル（依頼人）

| 項目 | 内容 |
|------|------|
| 名前 | 藤原 美咲（ふじわら みさき） |
| 年齢 | 28歳 |
| 職種 | Webアプリケーション開発者（バックエンド担当） |
| 一人称 | 私 |
| 性格 | 真面目で几帳面。テストを書きたいという意志は強いが、レガシーコードの壁に阻まれて焦りを感じている |
| 背景 | 社内の勤怠管理システムを保守している。前任者が書いたコードでは、各クラスのメソッド内で依存先を直接 `->new()` で生成しており、テスト時にモックへ差し替える手段がない。テストを書こうとするたびに本物のメール送信やDB接続が走ってしまい、テスト導入が完全に行き詰まっている |

---

## コード設計

### Beforeコード（アンチパターン: Hard-coded Dependencies）

`lib/AttendanceService.pm`（Before）

```perl
package AttendanceService;
use Moo;
use Database;
use NotificationService;

sub record_clock_in {
    my ($self, $employee_id) = @_;

    my $db = Database->new(dsn => 'dbi:Pg:dbname=attendance_prod');
    my $now = time;
    $db->insert('clock_events', {
        employee_id => $employee_id,
        event_type  => 'clock_in',
        timestamp   => $now,
    });

    my $notifier = NotificationService->new(
        smtp_host => 'smtp.company.internal',
    );
    $notifier->send(
        to      => 'hr@company.internal',
        subject => "Clock-in: Employee $employee_id",
        body    => "Employee $employee_id clocked in at $now",
    );

    return { employee_id => $employee_id, timestamp => $now };
}
```

**問題点**:
- メソッド内で `Database->new()` と `NotificationService->new()` を直接呼び出しており、密室に閉じ込められたように外部から差し替え不可能
- テストを実行すると本番DBに接続し、実際にメールが送信される
- 接続先やホスト名がハードコードされており、環境切り替えもできない
- クラスの依存関係がコンストラクタから見えない（隠れた共犯者）

### Afterコード（Dependency Injection: Constructor Injection）

`lib/AttendanceService.pm`（After）

```perl
package AttendanceService;
use Moo;

has db       => (is => 'ro', required => 1);
has notifier => (is => 'ro', required => 1);

sub record_clock_in {
    my ($self, $employee_id) = @_;

    my $now = time;
    $self->db->insert('clock_events', {
        employee_id => $employee_id,
        event_type  => 'clock_in',
        timestamp   => $now,
    });

    $self->notifier->send(
        to      => 'hr@company.internal',
        subject => "Clock-in: Employee $employee_id",
        body    => "Employee $employee_id clocked in at $now",
    );

    return { employee_id => $employee_id, timestamp => $now };
}
```

**改善点**:
- 依存がコンストラクタ（`has` 宣言）で明示的に宣言される——密室の扉が開かれた
- テスト時はモックオブジェクトを注入するだけで、本番DBやメールサーバーに触れない
- 環境ごとの切り替えは呼び出し側（組み立て側）の責務になり、クラス内のハードコードが消える
- 依存関係が一目瞭然で、クラスの責務が明確になる

---

## 5幕プロット

### I. 依頼（事務所への来客）

- 場面: 雑居ビルの一室「LCI」。ロックは飲みかけのエナジードリンク缶をピラミッド状に積み上げている
- 藤原が「テストを書くたびに本番のメールサーバーからメールが飛ぶんです」と青ざめた顔で駆け込む
- ロック「ほう。テストが本番を動かす——密室殺人のようだね。犯人は外から入れないはずの部屋の中にいる」
- 藤原「密室？ いえ、ただのPerlのクラスなんですが……」
- ロック「そのクラスこそが密室なんだよ、ワトソン君。中から鍵をかけて、誰も依存関係に触れさせない」

### II. 現場検証（コードの指紋）

- ロックが AttendanceService.pm を読み解く
- 「見たまえ。`Database->new(dsn => 'dbi:Pg:dbname=attendance_prod')`——犯人は堂々と本番DBの住所を名乗っているじゃないか」
- 藤原「これは前任者が書いたコードで、メソッドの中で直接 new しているんです」
- ロック「密室の中に共犯者が二人いる。Database と NotificationService だ。彼らはこのメソッドの中で生まれ、このメソッドの中でしか生きられない。外の世界——つまりテストコードから手を出す隙がない」
- Mermaid図でBefore の依存関係を可視化（AttendanceService → Database, NotificationService が内部で直結）
- 「初歩的なにおいだよ、ワトソン君。Hard-coded Dependencies——依存のハードコード。犯人の名前はこれだ」

### III. 推理披露（鮮やかなリファクタリング）

- ロック「密室を開く鍵は一つ。**Dependency Injection**——依存性の注入だ」
- 藤原「注入……？」
- ロック「犯人を密室の中で生まれさせるのではなく、外から送り込む。コンストラクタという正面玄関を作って、依存を堂々と渡すんだ」
- After の AttendanceService を実装・解説
- `has db => (is => 'ro', required => 1)` の意味を丁寧に解説
- 藤原「`required => 1` ってことは、依存を渡さないとインスタンスが作れない……つまり依存が隠せないんですね」
- ロック「その通り。密室の扉を開放して、共犯者を白日のもとに晒す。これがDIの本質だよ」

### IV. 解決（平和なビルド）

- テストを実行。InMemoryDB とモック通知サービスを注入し、本番環境に一切触れずにテスト通過
- 送信されたメールの内容もモック経由で検証可能に
- 藤原「本番DBにもメールサーバーにも触れていない……！ テストが安全に動いています」
- ロック「報酬は……そうだな、このメソッドにハードコードされていた接続文字列の文字数と同じミリ数のエスプレッソを頼む」
- 藤原（心の中）：「`dbi:Pg:dbname=attendance_prod` で32文字……32mlのエスプレッソって、ほぼ一口じゃ……」

### V. 報告書（探偵の調査報告書）

- 事件概要表（容疑: Hard-coded Dependencies → 真実: Dependency Injection → 証拠: テスト容易性・依存の明示化）
- 推理のステップ（リファクタリング手順: new の除去 → has 宣言の追加 → 呼び出し側の組み立て）
- ロックからワトソン君へのメッセージ

---

## フロントマター（予定）

```yaml
title: "コード探偵ロックの事件簿【Dependency Injection】密室の共犯者たち〜硬直した依存関係を解き放て〜"
date: "2026-04-10T07:07:05+09:00"
draft: false
categories: [tech]
tags:
  - design-pattern
  - perl
  - moo
  - dependency-injection
  - tight-coupling
  - refactoring
  - code-detective
```
