---
date: 2026-01-07T09:56:00+09:00
description: ChatGPT・GitHub Copilotで生成したコードをSOLID原則でリファクタリング。AI時代に必要な設計品質の保ち方を、実践的なコード例とレビュー観点で解説します。2026年最新版。
draft: true
epoch: 1736211360
image: /favicon.png
iso8601: 2026-01-07T09:56:00+09:00
tags:
  - solid-principles
  - ai-code-generation
  - github-copilot
  - perl
  - software-design
title: 'AI時代のSOLID原則 - Copilot・ChatGPT併用開発での設計品質の守り方'
---

## はじめに：AI時代になぜSOLID原則が重要なのか

GitHub CopilotやChatGPTが開発現場に浸透し、コード生成の速度は劇的に向上しました。しかし、AIが生成するコードは「動く」ことを優先し、長期的な保守性や拡張性を犠牲にしがちです。

AI支援開発が当たり前になった2026年、改めてSOLID原則の重要性が見直されています。本記事では、AI生成コードの典型的な問題点を指摘しながら、SOLID原則を活用して設計品質を維持する実践的な方法を、Perlのコード例とともに解説します。

### AI生成コードの典型的な問題点

AI（GitHub Copilot、ChatGPT）が生成するコードには、以下のような傾向がある

- 具体クラスへの直接依存が多く、テストや変更が困難（**密結合**）
- 1つのクラスに複数の関心事が詰め込まれる「神クラス」の生成（**責任の混在**）
- 拡張のたびにif文が増える、開放/閉鎖原則違反のコード（**if-else地獄**）
- 使わないメソッドまで実装を強制される設計（**太ったインターフェース**）
- is-a関係を無視した、リスコフ置換原則違反の継承階層（**継承の誤用**）

これらはいずれも「今すぐ動く」コードですが、数ヶ月後のメンテナンスで悪夢となります。

### 保守性・拡張性を犠牲にしない開発フロー

AI時代の開発フローは以下のように進化すべきです。

1. **粗削りな実装をAIに生成させる**（GitHub Copilot / ChatGPT）
2. **SOLID原則に照らしてレビュー**（人間の役割）
3. **設計の問題点をリファクタリング**（AI + 人間）
4. **静的解析・テストで品質確保**（自動化）

つまり、開発者の役割は「コーダー」から「アーキテクト」「レビュアー」へとシフトしています。AIにコードを書かせつつ、設計品質を守るのが現代のエンジニアリングです。

**AI生成コードの典型的な問題パターン**:

```mermaid
graph LR
    subgraph "AI生成コードの問題"
        P1[神クラス<br/>責任の混在]
        P2[if-else地獄<br/>条件分岐の増殖]
        P3[継承の誤用<br/>置換不可能]
        P4[太ったIF<br/>未使用メソッド]
        P5[密結合<br/>具象依存]
    end
    
    subgraph "SOLID原則での解決"
        S1[S: 単一責任<br/>クラス分割]
        S2[O: 開放/閉鎖<br/>Strategy適用]
        S3[L: リスコフ置換<br/>コンポジション]
        S4[I: IF分離<br/>Role細分化]
        S5[D: 依存性逆転<br/>DI導入]
    end
    
    P1 -.修正.-> S1
    P2 -.修正.-> S2
    P3 -.修正.-> S3
    P4 -.修正.-> S4
    P5 -.修正.-> S5
    
    style P1 fill:#ffcccc
    style P2 fill:#ffcccc
    style P3 fill:#ffcccc
    style P4 fill:#ffcccc
    style P5 fill:#ffcccc
    style S1 fill:#ccffcc
    style S2 fill:#ccffcc
    style S3 fill:#ccffcc
    style S4 fill:#ccffcc
    style S5 fill:#ccffcc
```

## SOLID原則の基礎知識

### 5つの原則の概要とAI時代の意義

SOLID原則は、Robert C. Martin（Uncle Bob）が2000年代初頭に体系化した、オブジェクト指向設計の5つの基本指針です。

| 原則 | 英名 | 要点 | AI時代の意義 |
|------|------|------|-------------|
| **S** | Single Responsibility | 1つの責任のみを持つ | AI生成の「神クラス」を分割 |
| **O** | Open/Closed | 拡張に開き、修正に閉じる | if-else地獄からの脱却 |
| **L** | Liskov Substitution | 派生クラスは基底クラスと置換可能 | AI生成継承階層の検証 |
| **I** | Interface Segregation | 使わないメソッドへの依存を排除 | 小さく特化したインターフェース |
| **D** | Dependency Inversion | 抽象に依存し、具象に依存しない | テスタブルで柔軟な設計 |

これらの原則は、**保守性**・**拡張性**・**テスト容易性**を高めるための指針であり、AIが生成したコードの品質を評価する基準としても機能します。

```mermaid
mindmap
  root((SOLID原則))
    S[単一責任原則<br/>Single Responsibility]
      1つのクラスは1つの責任
      変更理由は1つだけ
      神クラスを分割
    O[開放/閉鎖原則<br/>Open/Closed]
      拡張に開いている
      修正に閉じている
      Strategyパターン
    L[リスコフ置換原則<br/>Liskov Substitution]
      基底クラスと置換可能
      契約を守る
      継承よりコンポジション
    I[インターフェース分離<br/>Interface Segregation]
      小さく特化したRole
      使わないメソッド排除
      クライアント最適化
    D[依存性逆転原則<br/>Dependency Inversion]
      抽象に依存
      具象を注入
      テスタブル設計
```

### Robert C. Martinの設計思想と現代的解釈

Robert C. Martin（Uncle Bob）は、アジャイルソフトウェア開発やクリーンコード、クリーンアーキテクチャの提唱者としても知られています。彼の設計思想の核心は以下の点にあります。

- **変更の容易さ**: ソフトウェアは「変更されるもの」であり、変更コストを最小化する設計が重要
- **責任の分離**: 変更理由（アクター）ごとにモジュールを分割
- **抽象化の力**: 詳細ではなく抽象に依存することで、柔軟性を確保

2026年の現代では、マイクロサービスやクラウドネイティブ開発においても、これらの思想は色あせていません。特に、サービス境界の設計において単一責任原則が、APIの設計においてインターフェース分離原則が重視されています。

## AI生成コードとSOLID原則【実践編】

### S：単一責任の原則

#### GitHub Copilotが生成する「神クラス」の問題

GitHub Copilotは文脈から「それっぽいコード」を生成しますが、複数の責任を1つのクラスに詰め込みがちです。

**AI生成コードの典型例（悪い例）**:

```perl
# Perl 5.38+, Moo 2.005+
package UserManager;
use Moo;
use Email::Sender::Simple qw(sendmail);
use Email::Simple;
use DBI;

has 'dbh' => (is => 'ro', required => 1);

# ユーザー作成
sub create_user {
    my ($self, $username, $email) = @_;
    
    # DB操作
    my $sth = $self->dbh->prepare(
        'INSERT INTO users (username, email) VALUES (?, ?)'
    );
    $sth->execute($username, $email);
    
    # ログ出力
    warn "User created: $username\n";
    
    # ウェルカムメール送信
    my $message = Email::Simple->create(
        header => [
            To      => $email,
            From    => 'noreply@example.com',
            Subject => 'Welcome!',
        ],
        body => "Welcome, $username!",
    );
    sendmail($message);
    
    # 監査ログ記録
    $self->_log_audit("USER_CREATED", $username);
    
    return 1;
}

sub _log_audit {
    my ($self, $action, $target) = @_;
    # 監査ログをファイルに記録...
}

1;
```

このクラスは以下の責任を持っている

- ユーザーデータの永続化（DB操作）
- メール送信
- ログ出力
- 監査記録

これらはそれぞれ**異なる変更理由**（アクター）を持つ。DBスキーマ変更、メールテンプレート変更、ログフォーマット変更、監査要件変更のいずれかが発生すると、このクラスを修正しなければならない。

#### ChatGPTへの適切なプロンプト例

ChatGPTに単一責任原則を守らせるには、以下のようなプロンプトが有効です。

```
Perlで、UserRepositoryクラスを作成してください。
要件:
- 単一責任原則に従うこと
- ユーザーデータの永続化のみを担当
- Mooを使用
- メール送信やログ出力は含めない
```

このように**明示的に制約を与える**ことで、AIは焦点を絞ったコードを生成します。

#### リファクタリング実践（Perl例）

上記のコードを単一責任原則に従ってリファクタリングします。

**改善後のコード**:

```perl
# Perl 5.38+, Moo 2.005+

# 1. ユーザーデータの永続化のみを担当
package UserRepository;
use Moo;

has 'dbh' => (is => 'ro', required => 1);

sub create {
    my ($self, $username, $email) = @_;
    
    my $sth = $self->dbh->prepare(
        'INSERT INTO users (username, email) VALUES (?, ?)'
    );
    $sth->execute($username, $email);
    
    return 1;
}

1;

# 2. メール送信のみを担当
package EmailService;
use Moo;
use Email::Sender::Simple qw(sendmail);
use Email::Simple;

sub send_welcome_email {
    my ($self, $email, $username) = @_;
    
    my $message = Email::Simple->create(
        header => [
            To      => $email,
            From    => 'noreply@example.com',
            Subject => 'Welcome!',
        ],
        body => "Welcome, $username!",
    );
    
    sendmail($message);
}

1;

# 3. 監査ログのみを担当
package AuditLogger;
use Moo;

has 'log_file' => (is => 'ro', default => '/var/log/audit.log');

sub log_action {
    my ($self, $action, $target) = @_;
    
    open my $fh, '>>', $self->log_file or die $!;
    print $fh "[" . localtime() . "] $action: $target\n";
    close $fh;
}

1;

# 4. ユースケースの調整（Application Service）
package UserRegistrationService;
use Moo;

has 'user_repository' => (is => 'ro', required => 1);
has 'email_service'   => (is => 'ro', required => 1);
has 'audit_logger'    => (is => 'ro', required => 1);

sub register_user {
    my ($self, $username, $email) = @_;
    
    # 各責任を持つオブジェクトに委譲
    $self->user_repository->create($username, $email);
    $self->email_service->send_welcome_email($email, $username);
    $self->audit_logger->log_action('USER_CREATED', $username);
    
    return 1;
}

1;
```

これで各クラスは**単一の変更理由**のみを持つようになった

- `UserRepository`: DBスキーマ変更時のみ修正
- `EmailService`: メールテンプレート変更時のみ修正
- `AuditLogger`: 監査要件変更時のみ修正
- `UserRegistrationService`: ユーザー登録フロー変更時のみ修正

**クラス構造の比較図**:

```mermaid
graph TB
    subgraph "改善前：単一責任原則違反"
        UM[UserManager<br/>神クラス]
        UM -->|責任1| DB[(DB操作)]
        UM -->|責任2| MAIL[メール送信]
        UM -->|責任3| LOG[ログ出力]
        UM -->|責任4| AUDIT[監査記録]
    end
    
    subgraph "改善後：責任の分離"
        URS[UserRegistrationService<br/>ユースケース調整]
        UR[UserRepository<br/>DB操作]
        ES[EmailService<br/>メール送信]
        AL[AuditLogger<br/>監査記録]
        
        URS -->|委譲| UR
        URS -->|委譲| ES
        URS -->|委譲| AL
    end
    
    style UM fill:#ffcccc
    style URS fill:#ccffcc
    style UR fill:#e6f3ff
    style ES fill:#e6f3ff
    style AL fill:#e6f3ff
```

### O：開放/閉鎖の原則

#### AI生成のif-else地獄からStrategyパターンへ

GitHub CopilotやChatGPTは、条件分岐を多用したコードを生成しがちです。

**AI生成コードの典型例（悪い例）**:

```perl
# Perl 5.38+, Moo 2.005+
package DiscountCalculator;
use Moo;

sub calculate {
    my ($self, $customer_type, $price) = @_;
    
    if ($customer_type eq 'regular') {
        return $price;
    } elsif ($customer_type eq 'premium') {
        return $price * 0.9;  # 10% off
    } elsif ($customer_type eq 'vip') {
        return $price * 0.8;  # 20% off
    } elsif ($customer_type eq 'student') {
        return $price * 0.85; # 15% off
    }
    
    return $price;
}

1;
```

新しい顧客タイプを追加するたびに、このクラスを修正する必要がある（**修正に開いている**）。テスト済みのコードを変更するリスクがある。

#### 拡張可能な設計のプロンプト戦略

ChatGPTに開放/閉鎖原則を守らせるプロンプト例です。

```
Perlで割引計算システムを作成してください。
要件:
- 開放/閉鎖原則に従うこと
- 新しい割引タイプを既存コードの修正なしで追加できること
- Strategyパターンを使用
- Moo/Roleを活用
```

#### Perl実装例（Moo/Role）

Strategyパターンで開放/閉鎖原則を実現します。

**改善後のコード**:

```perl
# Perl 5.38+, Moo 2.005+, Role::Tiny 2.002+

# 1. 割引戦略のインターフェース（Role）
package DiscountStrategy;
use Moo::Role;

requires 'calculate';  # 実装クラスが必ず提供すべきメソッド

1;

# 2. 具体的な割引戦略
package RegularDiscount;
use Moo;
with 'DiscountStrategy';

sub calculate {
    my ($self, $price) = @_;
    return $price;  # 割引なし
}

1;

package PremiumDiscount;
use Moo;
with 'DiscountStrategy';

sub calculate {
    my ($self, $price) = @_;
    return $price * 0.9;  # 10% off
}

1;

package VIPDiscount;
use Moo;
with 'DiscountStrategy';

sub calculate {
    my ($self, $price) = @_;
    return $price * 0.8;  # 20% off
}

1;

# 3. 新しい割引タイプは新しいクラスとして追加するだけ（既存コード不変）
package StudentDiscount;
use Moo;
with 'DiscountStrategy';

sub calculate {
    my ($self, $price) = @_;
    return $price * 0.85;  # 15% off
}

1;

# 4. 計算機（コンテキスト）
package DiscountCalculator;
use Moo;

has 'strategy' => (
    is       => 'ro',
    does     => 'DiscountStrategy',  # Roleに依存
    required => 1,
);

sub calculate {
    my ($self, $price) = @_;
    return $self->strategy->calculate($price);
}

1;

# 使用例
use DBI;
my $calculator = DiscountCalculator->new(
    strategy => VIPDiscount->new,
);
my $final_price = $calculator->calculate(10000);  # 8000円
```

これで**拡張には開き、修正には閉じている**設計が実現できた。新しい割引ルール（例: `SeasonalDiscount`）を追加する際、既存のクラスを一切触る必要がない。

**Strategyパターンの構造図**:

```mermaid
classDiagram
    class DiscountStrategy {
        <<Role>>
        +calculate(price) int
    }
    
    class RegularDiscount {
        +calculate(price) int
    }
    
    class PremiumDiscount {
        +calculate(price) int
    }
    
    class VIPDiscount {
        +calculate(price) int
    }
    
    class StudentDiscount {
        +calculate(price) int
    }
    
    class DiscountCalculator {
        -DiscountStrategy strategy
        +calculate(price) int
    }
    
    DiscountStrategy <|.. RegularDiscount : implements
    DiscountStrategy <|.. PremiumDiscount : implements
    DiscountStrategy <|.. VIPDiscount : implements
    DiscountStrategy <|.. StudentDiscount : implements
    DiscountCalculator o-- DiscountStrategy : uses
    
    note for DiscountStrategy "新しい割引タイプは<br/>新しいクラスとして追加<br/>（既存コード変更なし）"
```

### L：リスコフの置換原則

#### AI生成継承階層の罠

ChatGPTやCopilotは、一見論理的に見える継承階層を生成しますが、リスコフの置換原則（LSP）を満たさないことがあります。

**AI生成コードの典型例（悪い例）**:

```perl
# Perl 5.38+, Moo 2.005+
package Rectangle;
use Moo;

has 'width'  => (is => 'rw', required => 1);
has 'height' => (is => 'rw', required => 1);

sub area {
    my $self = shift;
    return $self->width * $self->height;
}

1;

package Square;
use Moo;
extends 'Rectangle';

# 正方形なので、幅と高さを同期させる
around 'width' => sub {
    my ($orig, $self, $value) = @_;
    $self->$orig($value);
    $self->height($value) if defined $value;
    return $self->$orig();
};

around 'height' => sub {
    my ($orig, $self, $value) = @_;
    $self->$orig($value);
    $self->width($value) if defined $value;
    return $self->$orig();
};

1;
```

これは古典的な**Rectangle/Square問題**です。以下のコードが期待通りに動作しません。

```perl
sub set_rectangle_size {
    my $rect = shift;
    $rect->width(5);
    $rect->height(4);
    # 期待: area = 20
}

my $square = Square->new(width => 3, height => 3);
set_rectangle_size($square);
warn $square->area;  # 16（期待の20ではない！）
```

`Square`は`Rectangle`と**置換不可能**であり、LSP違反です。

#### 契約を守る設計のレビューポイント

AI生成の継承階層をレビューする際のチェックリスト

- 事前条件を強化していないか（親より厳しい引数制約）
- 事後条件を弱化していないか（親より緩い戻り値保証）
- 不変条件を破っていないか
- 親で定義されていない例外を投げていないか

**is-a関係が本当に成立するか**を常に問う必要がある。数学的には「正方形は長方形」だが、**振る舞いの観点では異なるクラス**である。

#### Perl実装例

LSPを守る設計に修正します。

**改善後のコード**:

```perl
# Perl 5.38+, Moo 2.005+, Role::Tiny 2.002+

# 1. 共通インターフェース（Role）
package Shape;
use Moo::Role;

requires 'area';  # 面積計算メソッド

1;

# 2. Rectangle（独立したクラス）
package Rectangle;
use Moo;
with 'Shape';

has 'width'  => (is => 'ro', required => 1);
has 'height' => (is => 'ro', required => 1);

sub area {
    my $self = shift;
    return $self->width * $self->height;
}

1;

# 3. Square（独立したクラス）
package Square;
use Moo;
with 'Shape';

has 'side' => (is => 'ro', required => 1);

sub area {
    my $self = shift;
    return $self->side * $self->side;
}

1;

# 使用例（多態性の実現）
sub print_area {
    my $shape = shift;  # Shape Roleを実装したオブジェクト
    warn "Area: " . $shape->area . "\n";
}

my $rect   = Rectangle->new(width => 5, height => 4);
my $square = Square->new(side => 3);

print_area($rect);    # Area: 20
print_area($square);  # Area: 9
```

これで`Rectangle`と`Square`は**契約（Shape Role）に従った置換可能なオブジェクト**になった。継承ではなく**コンポジション**（Roleによる合成）を使うことで、LSPを自然に満たせる。

**継承 vs コンポジションの比較図**:

```mermaid
graph TB
    subgraph "❌ LSP違反：継承の誤用"
        R1[Rectangle<br/>width, height]
        S1[Square<br/>継承]
        R1 -->|extends| S1
        S1 -.->|問題| PROB1["width/heightを同期<br/>契約違反<br/>置換不可能"]
    end
    
    subgraph "✅ LSP準拠：コンポジション"
        SHAPE[Shape Role<br/>area]
        R2[Rectangle<br/>width, height<br/>area]
        S2[Square<br/>side<br/>area]
        
        SHAPE -->|with| R2
        SHAPE -->|with| S2
        R2 -.->|利点| OK["独立したクラス<br/>契約を守る<br/>置換可能"]
    end
    
    style PROB1 fill:#ffcccc
    style OK fill:#ccffcc
    style SHAPE fill:#e6f3ff
```

### I：インターフェース分離の原則

#### 太ったインターフェースの自動生成問題

AI（特にChatGPT）は、「できることを全部詰め込んだ」インターフェースを生成しがちです。

**AI生成コードの典型例（悪い例）**:

```perl
# Perl 5.38+, Moo 2.005+
package Printer;
use Moo::Role;

requires 'print_document';
requires 'scan_document';
requires 'fax_document';
requires 'staple_document';

1;

# 単機能プリンターも全メソッドを実装しなければならない
package SimplePrinter;
use Moo;
with 'Printer';

sub print_document {
    my ($self, $doc) = @_;
    warn "Printing: $doc\n";
}

# 使わない機能も実装を強制される
sub scan_document  { die "Not supported!" }
sub fax_document   { die "Not supported!" }
sub staple_document { die "Not supported!" }

1;
```

これは**インターフェース分離原則（ISP）違反**です。クライアント（`SimplePrinter`）は、使わないメソッド（`scan_document`など）への依存を強制されています。

#### AIに小さなインターフェースを生成させる方法

ChatGPTへのプロンプト例:

```
Perlでプリンターシステムを設計してください。
要件:
- インターフェース分離原則に従うこと
- 印刷、スキャン、FAXの機能を分離
- 単機能デバイスは必要なインターフェースのみ実装
- Moo::Roleを活用
```

#### Perl実装例（Role::Tiny）

小さく特化したRoleに分割します。

**改善後のコード**:

```perl
# Perl 5.38+, Moo 2.005+, Role::Tiny 2.002+

# 1. 小さく特化したRole
package Printable;
use Moo::Role;
requires 'print_document';
1;

package Scannable;
use Moo::Role;
requires 'scan_document';
1;

package Faxable;
use Moo::Role;
requires 'fax_document';
1;

# 2. 単機能プリンター（必要なRoleのみ）
package SimplePrinter;
use Moo;
with 'Printable';

sub print_document {
    my ($self, $doc) = @_;
    warn "Printing: $doc\n";
}

1;

# 3. スキャナー専用機
package Scanner;
use Moo;
with 'Scannable';

sub scan_document {
    my ($self, $doc) = @_;
    warn "Scanning: $doc\n";
}

1;

# 4. 複合機（複数のRoleを組み合わせ）
package MultiFunctionDevice;
use Moo;
with 'Printable', 'Scannable', 'Faxable';

sub print_document {
    my ($self, $doc) = @_;
    warn "MFD Printing: $doc\n";
}

sub scan_document {
    my ($self, $doc) = @_;
    warn "MFD Scanning: $doc\n";
}

sub fax_document {
    my ($self, $doc) = @_;
    warn "MFD Faxing: $doc\n";
}

1;

# 使用例
sub use_printer {
    my $printer = shift;  # Printable Roleを持つオブジェクト
    $printer->print_document("report.pdf");
}

use_printer(SimplePrinter->new);          # OK
use_printer(MultiFunctionDevice->new);    # OK
# use_printer(Scanner->new);              # コンパイルエラー（Printableなし）
```

各クライアントは**必要最小限のインターフェースにのみ依存**する。これにより、変更の影響範囲が限定され、疎結合が実現できる。

**インターフェース分離の構造図**:

```mermaid
classDiagram
    class Printable {
        <<Role>>
        +print_document(doc)
    }
    
    class Scannable {
        <<Role>>
        +scan_document(doc)
    }
    
    class Faxable {
        <<Role>>
        +fax_document(doc)
    }
    
    class SimplePrinter {
        +print_document(doc)
    }
    
    class Scanner {
        +scan_document(doc)
    }
    
    class MultiFunctionDevice {
        +print_document(doc)
        +scan_document(doc)
        +fax_document(doc)
    }
    
    Printable <|.. SimplePrinter : implements
    Scannable <|.. Scanner : implements
    Printable <|.. MultiFunctionDevice : implements
    Scannable <|.. MultiFunctionDevice : implements
    Faxable <|.. MultiFunctionDevice : implements
    
    note for SimplePrinter "必要なRoleのみ実装<br/>使わないメソッドなし"
    note for MultiFunctionDevice "複数Roleを組み合わせ<br/>全機能を提供"
```

### D：依存性逆転の原則

#### 依存性注入をAIに理解させる

AIは具体クラスに直接依存するコードを生成しがちです。

**AI生成コードの典型例（悪い例）**:

```perl
# Perl 5.38+, Moo 2.005+
package OrderProcessor;
use Moo;
use MySQLOrderRepository;  # 具体クラスに依存

has 'repository' => (
    is      => 'ro',
    default => sub { MySQLOrderRepository->new },  # ハードコーディング
);

sub process_order {
    my ($self, $order) = @_;
    $self->repository->save($order);
}

1;
```

この設計では以下の問題がある

- `MySQLOrderRepository`以外への切り替えが困難
- テスト時にモックへ置き換え不可
- 高レベル（`OrderProcessor`）が低レベル（`MySQLOrderRepository`）に依存

#### テスタブルなコードのためのプロンプト

ChatGPTへのプロンプト例:

```
Perlで注文処理システムを作成してください。
要件:
- 依存性逆転原則に従うこと
- リポジトリはインターフェース（Role）を通じて注入
- テスト時にモックへ置き換え可能
- Mooのコンストラクタ注入を使用
```

#### Perl実装例（コンストラクタ注入）

抽象（Role）に依存し、具象をコンストラクタで注入します。

**改善後のコード**:

```perl
# Perl 5.38+, Moo 2.005+, Role::Tiny 2.002+

# 1. 抽象インターフェース（Role）
package OrderRepository;
use Moo::Role;

requires 'save';
requires 'find_by_id';

1;

# 2. MySQL実装（低レベルモジュール）
package MySQLOrderRepository;
use Moo;
with 'OrderRepository';

has 'dbh' => (is => 'ro', required => 1);

sub save {
    my ($self, $order) = @_;
    # MySQL固有の保存処理
    $self->dbh->do('INSERT INTO orders ...');
}

sub find_by_id {
    my ($self, $id) = @_;
    # 検索処理
}

1;

# 3. PostgreSQL実装（別の低レベルモジュール）
package PostgreSQLOrderRepository;
use Moo;
with 'OrderRepository';

has 'dbh' => (is => 'ro', required => 1);

sub save {
    my ($self, $order) = @_;
    # PostgreSQL固有の保存処理
    $self->dbh->do('INSERT INTO orders ...');
}

sub find_by_id {
    my ($self, $id) = @_;
    # 検索処理
}

1;

# 4. 高レベルモジュール（抽象に依存）
package OrderProcessor;
use Moo;

has 'repository' => (
    is       => 'ro',
    does     => 'OrderRepository',  # 抽象（Role）に依存
    required => 1,                  # コンストラクタ注入
);

sub process_order {
    my ($self, $order) = @_;
    
    # ビジネスロジック
    $order->{processed_at} = time;
    
    # リポジトリに委譲（どの実装かは知らない）
    $self->repository->save($order);
}

1;

# 使用例（本番環境）
use DBI;
my $dbh = DBI->connect('dbi:mysql:orders', 'user', 'pass');
my $processor = OrderProcessor->new(
    repository => MySQLOrderRepository->new(dbh => $dbh),
);
$processor->process_order({ id => 123, amount => 5000 });

# テスト用モック
package MockOrderRepository;
use Moo;
with 'OrderRepository';

has 'saved_orders' => (is => 'ro', default => sub { [] });

sub save {
    my ($self, $order) = @_;
    push @{$self->saved_orders}, $order;
}

sub find_by_id { ... }

1;

# テストコード
use Test::More;
my $mock = MockOrderRepository->new;
my $processor = OrderProcessor->new(repository => $mock);

$processor->process_order({ id => 999, amount => 1000 });
is scalar @{$mock->saved_orders}, 1, 'Order was saved';
ok $mock->saved_orders->[0]{processed_at}, 'Processed timestamp set';
done_testing;
```

これで以下が実現できた

- **高レベル**（`OrderProcessor`）と**低レベル**（`MySQLOrderRepository`）の両方が**抽象**（`OrderRepository` Role）に依存
- 依存性は外部から注入（依存性注入）
- テスト時に簡単にモックへ置き換え可能
- DB実装の切り替えが容易

**依存性逆転の原則の図解**:

```mermaid
graph TB
    subgraph "❌ 依存性逆転原則違反"
        HL1[OrderProcessor<br/>高レベル]
        LL1[MySQLOrderRepository<br/>低レベル]
        HL1 -->|直接依存| LL1
        LL1 -.->|問題| PROB["テスト困難<br/>DB実装変更時に修正<br/>密結合"]
    end
    
    subgraph "✅ 依存性逆転原則準拠"
        HL2[OrderProcessor<br/>高レベル]
        ABS[OrderRepository Role<br/>抽象インターフェース]
        LL2A[MySQLOrderRepository<br/>低レベル]
        LL2B[PostgreSQLOrderRepository<br/>低レベル]
        MOCK[MockOrderRepository<br/>テスト用]
        
        HL2 -->|依存| ABS
        ABS <-.実装.-|implements| LL2A
        ABS <-.実装.-|implements| LL2B
        ABS <-.実装.-|implements| MOCK
        HL2 -.->|利点| OK["テスタブル<br/>実装切り替え容易<br/>疎結合"]
    end
    
    style PROB fill:#ffcccc
    style OK fill:#ccffcc
    style ABS fill:#e6f3ff
```

## AI支援開発でSOLIDを守るワークフロー

**AI支援開発のワークフロー図**:

```mermaid
flowchart TD
    START([開発開始]) --> COPILOT[GitHub Copilot/<br/>ChatGPTで<br/>初期コード生成]
    COPILOT --> HUMAN_REVIEW{人間による<br/>SOLIDレビュー}
    
    HUMAN_REVIEW -->|S違反| FIX_S[責任を分離<br/>クラス分割]
    HUMAN_REVIEW -->|O違反| FIX_O[Strategyパターン<br/>適用]
    HUMAN_REVIEW -->|L違反| FIX_L[継承を<br/>コンポジションへ]
    HUMAN_REVIEW -->|I違反| FIX_I[Roleを<br/>小さく分割]
    HUMAN_REVIEW -->|D違反| FIX_D[依存性注入<br/>導入]
    HUMAN_REVIEW -->|OK| STATIC[静的解析<br/>Perl::Critic]
    
    FIX_S --> REFACTOR[AI支援<br/>リファクタリング]
    FIX_O --> REFACTOR
    FIX_L --> REFACTOR
    FIX_I --> REFACTOR
    FIX_D --> REFACTOR
    
    REFACTOR --> HUMAN_REVIEW
    
    STATIC --> TEST[テスト実行<br/>カバレッジ確認]
    TEST -->|失敗| HUMAN_REVIEW
    TEST -->|成功| COMMIT[コミット]
    COMMIT --> CI[CI/CD<br/>パイプライン]
    CI --> END([リリース])
    
    style START fill:#e1f5e1
    style END fill:#e1f5e1
    style HUMAN_REVIEW fill:#fff4e6
    style REFACTOR fill:#e6f3ff
    style COMMIT fill:#ccffcc
```

### GitHub Copilot使用時のチェックリスト

GitHub Copilotが生成したコードを受け入れる前に、以下をチェックする

- [ ] **S**: このクラスは1つの責任（変更理由）のみを持っているか
- [ ] **O**: 新機能追加時に既存コードを修正する必要があるか
- [ ] **L**: 継承階層で親クラスと置換可能か、契約を守っているか
- [ ] **I**: 使わないメソッドへの依存を強制されていないか
- [ ] **D**: 具体クラスに直接依存していないか、テスト可能か

特に、以下のパターンに注意

| 生成されたパターン | 疑うべき原則違反 | 対処法 |
|------------------|----------------|--------|
| 1つのクラスが肥大化 | SRP | 責任ごとにクラス分割 |
| if/elsif/elseが連続 | OCP | Strategyパターンへ |
| extends多用 | LSP | Roleによるコンポジションへ |
| 大きなRole/Interface | ISP | 小さなRoleに分割 |
| `new ClassName` | DIP | コンストラクタ注入へ |

### ChatGPTコードレビュープロンプト集

ChatGPTにコードレビューを依頼する際の効果的なプロンプト集です。

**1. SOLID原則の総合レビュー**

```
以下のPerlコードをSOLID原則の観点からレビューしてください。
特に注目すべき点:
- 単一責任原則: 各クラスの責任は1つか？
- 開放/閉鎖原則: 拡張時に既存コード修正が必要か？
- リスコフ置換原則: 継承階層に問題はないか？
- インターフェース分離原則: 使わないメソッドへの依存はないか？
- 依存性逆転原則: 具体クラスへの直接依存はないか？

[コードを貼り付け]
```

**2. リファクタリング提案**

```
以下のPerlコードを、SOLID原則に従ってリファクタリングしてください。
使用技術: Moo, Role::Tiny
出力形式: 修正前/修正後のコード比較

[コードを貼り付け]
```

**3. 特定原則の深掘り**

```
以下のPerlコードが単一責任原則に違反していないか検証してください。
もし違反している場合、責任ごとにクラスを分割したコードを提示してください。

[コードを貼り付け]
```

**4. テスタビリティの確認**

```
以下のPerlコードは依存性注入を使用してテスタブルか評価してください。
もしテスト困難な場合、依存性逆転原則に従った修正案を提示してください。

[コードを貼り付け]
```

これらのプロンプトを活用することで、ChatGPTを「設計レビュアー」として活用できる。

### 静的解析ツールとの組み合わせ

SOLID原則の遵守を自動的にチェックするツールとの組み合わせが効果的です。

**Perl用の静的解析ツール**

1. **Perl::Critic**:
   - コーディング規約違反を検出
   - カスタムポリシーでSOLID原則チェック可能

```bash
# インストール
cpanm Perl::Critic

# 実行
perl-critic --severity 3 lib/
```

2. **Devel::Cover**:
   - テストカバレッジを計測
   - 依存性注入が適切ならカバレッジ向上

```bash
cpanm Devel::Cover
cover -test
```

3. **Test::Class::Moose**:
   - クラスごとのテスト整理
   - SRPを守っていれば、テストも整理しやすい

**ワークフローへの組み込み**

```yaml
# .github/workflows/ci.yml
name: CI
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Setup Perl
        uses: shogo82148/actions-setup-perl@v1
      - name: Install dependencies
        run: cpanm --installdeps .
      - name: Run Perl::Critic
        run: perl-critic --severity 3 lib/
      - name: Run tests with coverage
        run: cover -test
```

AI生成コード → 静的解析 → 人間レビュー → リファクタリング、という流れで品質を確保する。

## まとめ：AI×SOLID原則で持続可能な開発を

### 設計品質を維持するための5つのポイント

1. **AIは「ドラフト生成ツール」と割り切る**
   - GitHub CopilotやChatGPTは、初期実装の高速化には優れている
   - しかし設計品質は人間がレビュー・リファクタリングで担保

2. **明示的なプロンプトでAIをガイドする**
   - 「SOLID原則に従って」「依存性注入を使用して」など、設計制約を明示
   - AIは指示がない限り、最短ルートで「動くコード」を生成する

3. **レビュー基準としてSOLIDを活用**
   - コードレビュー時のチェックリストに組み込む
   - 各原則違反のパターンを認識できるようにする

4. **静的解析・テストで継続的に検証**
   - Perl::Critic、テストカバレッジで自動チェック
   - CI/CDパイプラインに組み込み、品質の劣化を防ぐ

5. **過度なエンジニアリングを避ける**
   - SOLID原則は**ツール**であり**ルール**ではない
   - プロジェクトの規模・期間・チーム構成に応じて適用度合いを調整

### 次に学ぶべきこと

SOLID原則をマスターしたら、以下のテーマに進むことをお勧めします。

- **デザインパターン**: SOLID原則を実現する具体的な設計パターン（Strategy、Factory、Observerなど）
- **クリーンアーキテクチャ**: より大規模なシステム設計への適用
- **テスト駆動開発（TDD）**: SOLID原則を自然に守れる開発手法
- **ドメイン駆動設計（DDD）**: ビジネスロジックと設計の整合性

関連記事

- {{< linkcard "https://www.nqou.net/2025/12/30/163810" >}}（Mooで覚えるオブジェクト指向プログラミング）

## 参考文献

- Robert C. Martin, "Agile Software Development, Principles, Patterns, and Practices" (2002)
- {{< amazon asin="4048930591" title="Clean Architecture 達人に学ぶソフトウェアの構造と設計" >}}
- {{< linkcard "https://docs.github.com/en/copilot/tutorials/review-ai-generated-code" >}}（GitHub Copilot公式ドキュメント）
- {{< linkcard "https://metacpan.org/pod/Moo" >}}（Moo - Minimalist Object Orientation）
- {{< linkcard "https://metacpan.org/pod/Role::Tiny" >}}（Role::Tiny - Roles: a nouvelle cuisine portion size slice of Moose）

---

AI時代だからこそ、設計原則の重要性が増しています。SOLID原則を武器に、保守性の高いコードを書き続けましょう！
