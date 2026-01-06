---
date: 2026-01-07T04:00:29+09:00
description: オブジェクト指向入門者向けにSOLID原則の定義・誤解・実践ポイント・具体例・参考リンクを整理した調査メモ
draft: false
epoch: 1767726029
image: /favicon.png
iso8601: 2026-01-07T04:00:29+09:00
tags:
  - solid
  - object-oriented
  - design-principles
  - software-design
  - best-practices
title: SOLID原則 調査メモ
---

# SOLID原則 調査メモ

## 調査概要

- **調査日**: 2026-01-07
- **目的**: SRP/OCP/LSP/ISP/DIP の定義・目的・よくある誤解・実践ポイント・具体例（コード例候補）を整理し、入門者向けの重要ポイントを明確化すること
- **適用対象**: オブジェクト指向初学者（Java / C# / TypeScript / Python などクラスベース言語を想定）

## 要点と根拠（信頼度付き）

- 要点: SOLID は「変更理由の分離」「拡張で適応」「契約の遵守」「最小限のインターフェース」「抽象への依存」を通じて変更耐性を高める設計原則
  - 根拠: Robert C. Martin『Agile Software Development, Principles, Patterns, and Practices』、Clean Architecture の原則整理
  - 仮定: プロダクトは将来の仕様変更や機能追加が想定される
  - 出典: {{< linkcard "https://en.wikipedia.org/wiki/SOLID" >}}
  - 信頼度: 高（原典および広く引用される二次資料）

## 各原則の俯瞰（概要表）

| 原則 | 定義・目的 | よくある誤解 | 実践ポイント | コード例候補 |
|---|---|---|---|---|
| SRP | 1クラス/モジュールにつき「変更理由」は1つ | 「メソッドが1つならOK」「物理ファイルが1つならOK」 | 変更理由（利用者/データ源/業務規約）を列挙し、混在を分離 | ログ出力クラスとDB保存クラスを分ける（Python/TypeScript） |
| OCP | 既存コードを改変せず振る舞いを拡張 | 「if を増やせば拡張」 | 抽象化（interface/抽象クラス）＋ポリモーフィズムで分岐を外出し | 戦略パターンで課金計算のバリエーションを切替（Java/C#） |
| LSP | サブタイプは代替可能であるべき | 「継承すれば自動的にOK」 | 契約（事前条件の緩和・事後条件の強化・例外型の互換性）を確認 | 四角形/長方形問題、リポジトリモック差し替え（TypeScript） |
| ISP | クライアント固有の最小インターフェースを提供 | 「メソッドを減らすだけ」 | 呼び出しパターンで分割し、Fat Interfaceを複数のロールに分ける | Reader/Writer/Closer を分ける設計（Go/TypeScript） |
| DIP | 具象ではなく抽象に依存し、依存方向を内側へ | 「DIコンテナを使うこと」 | ポートとアダプタの分離、コンストラクタ注入で安定依存を形成 | EmailSenderをインターフェース経由で注入（C#/Java） |

## 原則別メモ（定義・誤解・実践・例）

### SRP（Single Responsibility Principle）

- 定義/目的: モジュールは単一の変更理由だけを持つように分割し、影響範囲を局所化する
- よくある誤解: 「メソッド数が少なければ満たす」「表示と保存を同じクラスに置いても小さければOK」
- 実践ポイント:
  - 変更理由（UI、永続化、ドメインルール、外部API）を列挙し、異なるものは別モジュールに分離する
  - ログ、バリデーション、永続化を責務ごとに切り出し、合成で組み立てる
  - ロギングなど横断関心はデコレータやミドルウェアで注入する
- 簡易例（TypeScript）
```typescript
// 責務分離の例: ログ記録と通知送信を分割
interface Sender { send(message: string): Promise<void>; }
class Notifier {
  constructor(private sender: Sender) {}
  async send(message: string) {
    await this.sender.send(message);
  }
}
class ConsoleLogger { log(msg: string) { console.log(`[log] ${msg}`); } }
// 変更理由（通知手段の増減）とログ記録を分けているシンプルな例
```

### OCP（Open/Closed Principle）

- 定義/目的: 既存コードを改変せずに新しい振る舞いを追加できる構造を目指す
- よくある誤解: `if` 分岐を増やすだけで対応すること、抽象化がないまま列挙型スイッチを増やし続けること
- 実践ポイント:
  - ポリモーフィズムで分岐を外出しし、登録型/プラグイン型の拡張ポイントを用意する
  - デフォルト実装をインターフェース越しに差し替えられるようにする
  - テストは新しい具体型を追加したときの契約遵守を確認する
- 簡易例（Python）
```python
from abc import ABC, abstractmethod

class Pricing(ABC):
    @abstractmethod
    def amount(self, usage: int) -> int: ...

class BasicPricing(Pricing):
    def amount(self, usage: int) -> int:
        return 1000 + usage * 10

class PremiumPricing(Pricing):
    def amount(self, usage: int) -> int:
        return 2000 + usage * 8

def calc_invoice(pricing: Pricing, usage: int) -> int:
    return pricing.amount(usage)
# 新プラン追加時は新しい Pricing 実装を追加するだけ
```

### LSP（Liskov Substitution Principle）

- 定義/目的: 派生型は基底型の契約（事前条件は厳しくしない、事後条件は緩めない、例外互換を保つ）を破らずに代替可能であるべき
- よくある誤解: 継承して動けばよい、派生型で例外を増やしても問題ないという考え
- 実践ポイント:
  - 期待される不変条件（例: コレクションは順序を保持する）をテストで明文化する
  - 破壊的なメソッドを禁止する場合は別インターフェースに切り出す
  - モック/スタブも同じ契約で動くかを検証する
- 簡易例（TypeScript）
```typescript
type Entity = { id: string };
interface Repository {
  find(id: string): Promise<Entity | null>;
}
class CachingRepository implements Repository {
  constructor(private origin: Repository, private cache = new Map<string, Entity | null>()) {}
  async find(id: string) {
    if (this.cache.has(id)) return this.cache.get(id)!;
    const result = await this.origin.find(id);
    this.cache.set(id, result);
    return result; // 見つからなければ null をそのまま返し契約を維持
  }
}
// 例外契約や戻り値のnull許容性を守ることで代替可能性を維持する
```

### ISP（Interface Segregation Principle）

- 定義/目的: クライアントが使わないメソッドを強制しないよう、役割ごとに小さなインターフェースへ分割する
- よくある誤解: 大きなインターフェースからメソッドを雑に削除するだけ、あるいは1クラス=1インターフェースに固定すること
- 実践ポイント:
  - 呼び出し側の使用パターンでグルーピングし、ロールごとにインターフェースを分割する
  - Goの`io.Reader`/`io.Writer`のように役割単位で分け、合成して使う
  - 単体テストではモック作成コストが下がるかを指標にする
- 簡易例（TypeScript）
```typescript
import { readFileSync, writeFileSync } from "fs"; // Node.js環境の例
interface Reader { read(): string; }
interface Writer { write(data: string): void; }
class FileStream implements Reader, Writer {
  constructor(private path: string) {}
  read(): string { return readFileSync(this.path, "utf8"); }
  write(data: string): void { writeFileSync(this.path, data); }
}
// クライアントは必要なロール（Reader/Writer）のみを依存対象にできる
```

### DIP（Dependency Inversion Principle）

- 定義/目的: 安定した抽象に依存し、具象への依存を外側へ押し出して結合度を下げる
- よくある誤解: 「DIコンテナを導入すれば自動的に満たす」「すべてのクラスをインターフェース化する」
- 実践ポイント:
  - ポート（インターフェース）とアダプタ（実装）を分け、ドメイン層はポートだけを見る
  - コンストラクタ/ファクトリ注入を使い、newを隠蔽してテスト差し替えを容易にする
  - 抽象の所有権を内側（ドメイン側）に置き、インフラ層はそれを実装する
- 簡易例（C#）
```csharp
using System.Net.Mail;
using System.Threading.Tasks;

public interface IEmailSender { Task SendAsync(string to, string body); }
public class SmtpEmailSender : IEmailSender {
    private readonly SmtpClient _client;
    public SmtpEmailSender(SmtpClient client) { _client = client; }
    public Task SendAsync(string to, string body) {
        var message = new MailMessage("noreply@example.com", to, "Notice", body);
        return _client.SendMailAsync(message);
    }
}
public class OrderService {
    private readonly IEmailSender _sender;
    public OrderService(IEmailSender sender) { _sender = sender; }
    public Task NotifyAsync(string to, string body) => _sender.SendAsync(to, body);
}
// OrderService は抽象に依存し、具象は外側で注入する
```

## 競合・参考記事の概要

- Refactoring.Guru「SOLID Principles」: イラストと多言語コード例で直感的であり初心者に有用。信頼度: 高 {{< linkcard "https://refactoring.guru/design-patterns/solid" >}}
- Wikipedia「SOLID (object-oriented design)」: 用語の原典と歴史がまとまる。信頼度: 中（編集ベースだが更新頻度高）{{< linkcard "https://en.wikipedia.org/wiki/SOLID" >}}
- Qiita/Dev.to 初学者向け記事（例: 各原則を図解するまとめ記事）: 日本語の入門理解に役立つが品質ばらつきあり。信頼度: 中
- 書籍『Clean Architecture』: DIP/OCPの背景を深掘りし設計思想を補強。信頼度: 高 {{< amazon asin="4048930656" title="Clean Architecture 達人に学ぶソフトウェアの構造と設計" >}}

## 内部リンク候補（/content/post 配下）

- /2026/01/02/233311/（「Mooで覚えるオブジェクト指向プログラミング」シリーズ目次）
- /2025/12/11/000000/（Moo/MooseによるモダンOOP解説）
- /2025/12/12/214754/（OOP入門記事内でSRPに触れている節あり）
- /2026/01/04/011451/（Todoアプリ設計でSRP/DIPに触れる）
- /2026/01/07/223623/（SOLID原則に言及する連載回）
- /2026/01/08/003031/（カプセル化・インターフェース分割の実践）

## 書き方の着眼点（入門者向け重要ポイント）

- 4つの視点で整理すると理解しやすいです: 「目的」「アンチパターン（誤解）」「実践チェックリスト」「拡張例」
- コード例は1つの概念に1つの責務だけを持たせ、差し替えやすい構造を示すと読者が試せます。
- 「テストしやすさ」を評価軸に入れるとSRP/ISP/DIPの価値が伝わりやすいです。

## 参考リンクカード

- {{< linkcard "https://refactoring.guru/design-patterns/solid" >}}
- {{< linkcard "https://en.wikipedia.org/wiki/SOLID" >}}
- {{< amazon asin="4048930656" title="Clean Architecture 達人に学ぶソフトウェアの構造と設計" >}}

## 記事アウトライン案（Step2）

### 案A: 全体像→各原則の目的と誤解→実践チェック

- 1行要約: SOLID全体の狙いを俯瞰しつつ、各原則の目的とありがちな誤解を整理して入門者が迷わない道筋を示します。
- 推奨タグ: `solid`, `object-oriented-design`, `design-principles`, `software-design`, `clean-code`
- 想定見出し:
  - H2: SOLID原則は何を解決するのか
    - H3: 変更に強くするための5つの視点
    - H3: 初学者がつまずきやすいポイント
  - H2: 5原則をまとめてつかむショートノート
    - H3: SRP（単一責任）と「変更理由」の見つけ方
    - H3: OCP（開放閉鎖）と拡張ポイントの置き方
    - H3: LSP（リスコフ置換）と契約の守り方
    - H3: ISP（インターフェース分離）とモジュール分割
    - H3: DIP（依存性逆転）と抽象への依存
  - H2: ありがちな誤解とすぐ試せる修正例
    - H3: if文増殖 vs 戦略パターンへの置き換え
    - H3: Fat Interface をロールに分ける小手調べ
  - H2: 明日から使うためのチェックリスト
    - H3: テストしやすさで振り返る5問

### 案B: 1原則1ユースケースで理解を定着させる構成

- 1行要約: 各原則に1つずつ具体ユースケースを割り当て、ビフォー/アフターで変化を見せて学びを定着させます。
- 推奨タグ: `solid`, `clean-architecture`, `object-oriented`, `refactoring`, `design-patterns`
- 想定見出し:
  - H2: 学び方のガイド（5分で流れを把握）
    - H3: 本記事の読み方と到達目標
  - H2: SRP—ログと保存を分けて影響範囲を狭める
    - H3: ビフォーコード（混在例）
    - H3: アフターコード（責務分離）
  - H2: OCP—料金プラン追加をifなしで拡張する
    - H3: 戦略パターンで拡張点を外出し
  - H2: LSP—モック置換で破れない契約を作る
    - H3: 期待する不変条件をテストで明文化
  - H2: ISP—Fat Interfaceをロールに分ける
    - H3: Reader/Writer分離の小さなリファクタ
  - H2: DIP—メール送信を抽象に寄せて差し替え自在に
    - H3: ポートとアダプタの分離手順
  - H2: まとめと次の一歩
    - H3: どの原則から適用するかの優先順位

### 案C: 学習の落とし穴を避ける「誤解→正解→実践」導線

- 1行要約: よくある誤解を起点に正しい理解と実践手順を並べ、失敗しにくい学習ルートを提案します。
- 推奨タグ: `solid`, `oop-beginner`, `software-quality`, `best-practices`, `clean-code`
- 想定見出し:
  - H2: まず押さえる「SOLIDが難しく感じる理由」
    - H3: 用語の多さと抽象度への対処法
  - H2: 誤解から入る5原則の正しい読み替え
    - H3: SRP「クラスを細かく分ければOK」への反例
    - H3: OCP「ifが増えても拡張と言える？」の検証
    - H3: LSP「動けば代替可能」にならない理由
    - H3: ISP「メソッドを減らすだけでは不十分」
    - H3: DIP「DIコンテナ導入＝正解」ではない
  - H2: 誤解を正すための小さな実験
    - H3: 変更理由を書き出して責務を分割するワーク
    - H3: 抽象インターフェースを挟んで拡張点を固定するワーク
  - H2: 次に読む・試すリソース
    - H3: 参考リンクと社内コードへの適用ヒント
