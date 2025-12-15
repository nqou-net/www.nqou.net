---
title: "Perlで始める値オブジェクト入門 | EmailAddressクラスのTDD実装例"
draft: true
tags:
- perl
- value-object
- design-pattern
- object-oriented
- refactoring
- tdd
- class-tiny
- email-validation
description: "Perlで値オブジェクトパターンを実装する方法をTDD形式で解説。EmailAddressクラスの実装例で、バリデーション分散とプリミティブ型依存の問題を解決します。"
---

## なぜメールアドレスのバリデーションがあちこちに散らばっているのか？

> **📚 シリーズ記事**: この記事は「Perl値オブジェクト実践シリーズ」の第1回です。
> - 📖 第1回：**値オブジェクト入門**（この記事）
> - 📖 第2回：[JSON-RPC 2.0のリクエスト/エラーオブジェクトをTDDで実装](../jsonrpc-value-object-outlines/)（予定）
> - 📖 第3回：レスポンスオブジェクトと型安全性（予定）

こんなコード、見覚えありませんか？

```perl
# ユーザー登録処理
sub register_user {
    my ($email, $name) = @_;
    
    if ($email !~ /^[\w\.\-]+@[\w\.\-]+\.\w+$/) {
        die "Invalid email address";
    }
    
    save_user($email, $name);
}

# メール送信処理
sub send_email {
    my ($email, $subject, $body) = @_;
    
    if ($email !~ /^[\w\.\-]+@[\w\.\-]+\.\w+$/) {
        die "Invalid email address";
    }
    
    deliver_email($email, $subject, $body);
}

# パスワードリセット処理 - 別の正規表現パターン！
sub reset_password {
    my ($email) = @_;
    
    if ($email !~ /\w+@\w+\.\w+/) {
        die "Invalid email";
    }
    
    process_reset($email);
}
```

この問題、どこが悪いのでしょうか？

1. **バリデーションロジックが重複**している
2. **正規表現のパターンが微妙に違う**（バグの温床）
3. **エラーメッセージが統一されていない**
4. **「文字列」という型情報しかない**ため、コードを読んでも何を表しているかわかりにくい
5. **変更が困難**（バリデーションルールを変えるときに全箇所を探し出す必要がある）

このような「プリミティブ型の呪縛」から解放してくれるのが、**値オブジェクト（Value Object）**パターンです。

## 値オブジェクトとは？ドメイン駆動設計の基本パターン

値オブジェクトは、ドメイン駆動設計（DDD）における基本的なビルディングブロックの一つです。

Martin Fowlerは、値オブジェクトを次のように定義しています：

{{< linkcard "https://martinfowler.com/bliki/ValueObject.html" >}}

> **値オブジェクトは、一意な識別子を持たず、属性値によってのみ識別されるオブジェクトである。**

もっと簡単に言えば、「**値そのもの**」を表現するオブジェクトです。

数値や文字列といったプリミティブ型に、ドメインの意味とルールを持たせたものと考えてください。

### 値オブジェクトの3つの特徴

値オブジェクトには、次の3つの重要な特徴がある：

#### 1. 不変性（Immutability）

一度作成されたら、その状態は変更できません。

変更が必要な場合は、新しいインスタンスを作ります。

#### 2. 等価性（Equality）

2つの値オブジェクトは、すべての属性値が同じであれば等価です。

オブジェクトのアイデンティティ（メモリアドレスなど）ではなく、値の内容で比較します。

#### 3. 自己バリデーション（Self-validation）

値オブジェクトは、自身の整合性を保証します。

不正な値を持つインスタンスは作成できません。

## 【実践】EmailAddress値オブジェクトの3ステップ実装

それでは、テスト駆動開発（TDD）の流れで、EmailAddress値オブジェクトを実装してみましょう。

### ステップ1：まずテストを書く

値オブジェクトを設計する前に、どう使いたいかを明確にします。テストコードから始めましょう。

```perl
# t/email_address.t
use strict;
use warnings;
use Test::More;

use_ok('EmailAddress');

# 正常系：有効なメールアドレス
subtest 'valid email addresses' => sub {
    my $email = EmailAddress->new('user@example.com');
    isa_ok($email, 'EmailAddress');
    is($email->value, 'user@example.com', 'stores email correctly');
};

# 異常系：不正なメールアドレス
subtest 'invalid email addresses' => sub {
    eval { EmailAddress->new('invalid-email') };
    like($@, qr/Invalid email address format/, 'rejects invalid format');
    
    eval { EmailAddress->new('') };
    like($@, qr/Email address cannot be empty/, 'rejects empty string');
    
    eval { EmailAddress->new(undef) };
    like($@, qr/Email address is required/, 'rejects undef');
};

# 等価性：同じ値なら等価
subtest 'equality' => sub {
    my $email1 = EmailAddress->new('user@example.com');
    my $email2 = EmailAddress->new('user@example.com');
    my $email3 = EmailAddress->new('other@example.com');
    
    ok($email1->equals($email2), 'same email addresses are equal');
    ok(!$email1->equals($email3), 'different email addresses are not equal');
};

done_testing();
```

このテストは、現時点では失敗します。まだ`EmailAddress`クラスを実装していないからです。これがTDDの「レッド（失敗）」フェーズです。

### ステップ2：Pure Perlで実装する

まずは、Perlの基本的な機能だけで実装してみましょう。

```perl
# lib/EmailAddress.pm
package EmailAddress;
use strict;
use warnings;

sub new {
    my ($class, $value) = @_;
    
    die "Email address is required" unless defined $value;
    die "Email address cannot be empty" if $value eq '';
    die "Invalid email address format: $value"
        unless $value =~ /^[\w\.\-]+@[\w\.\-]+\.\w{2,}$/;
    
    my $self = {
        _value => $value,
    };
    
    return bless $self, $class;
}

sub value {
    my ($self) = @_;
    return $self->{_value};
}

sub equals {
    my ($self, $other) = @_;
    return 0 unless ref($other) eq ref($self);
    return $self->value eq $other->value;
}

use overload '""' => sub { shift->value };

1;
```

この実装により、テストが通るようになります。これがTDDの「グリーン（成功）」フェーズです。

### ステップ3：Class::Tinyでリファクタリング

Pure Perlの実装は動作しますが、もっと簡潔に書けます。

`Class::Tiny`を使ってリファクタリングしましょう。

{{< linkcard "https://metacpan.org/pod/Class::Tiny" >}}

```perl
# lib/EmailAddress.pm (Class::Tiny版)
package EmailAddress;
use strict;
use warnings;
use Class::Tiny qw(value);

sub BUILD {
    my ($self) = @_;
    my $value = $self->value;
    
    die "Email address is required" unless defined $value;
    die "Email address cannot be empty" if $value eq '';
    die "Invalid email address format: $value"
        unless $value =~ /^[\w\.\-]+@[\w\.\-]+\.\w{2,}$/;
}

sub equals {
    my ($self, $other) = @_;
    return 0 unless ref($other) eq ref($self);
    return $self->value eq $other->value;
}

use overload '""' => sub { shift->value };

1;
```

`Class::Tiny`を使うことで、コンストラクタとアクセサが自動生成されます。

`BUILD`メソッドはオブジェクト構築後に自動的に呼ばれるため、バリデーションに最適です。

再度テストを実行して、すべて通ることを確認します。これがTDDの「リファクタリング」フェーズです。

## Before/After比較：値オブジェクトで変わるコード品質

では、最初の問題コードを値オブジェクトで書き直すとどうなるでしょうか？

### Before：プリミティブ型の呪縛

```perl
sub register_user {
    my ($email, $name) = @_;
    
    if ($email !~ /^[\w\.\-]+@[\w\.\-]+\.\w+$/) {
        die "Invalid email address";
    }
    
    save_user($email, $name);
}

sub send_email {
    my ($email, $subject, $body) = @_;
    
    if ($email !~ /^[\w\.\-]+@[\w\.\-]+\.\w+$/) {
        die "Invalid email address";
    }
    
    deliver_email($email, $subject, $body);
}
```

### After：値オブジェクトで表現

```perl
sub register_user {
    my ($email, $name) = @_;
    
    save_user($email->value, $name);
}

sub send_email {
    my ($email, $subject, $body) = @_;
    
    deliver_email($email->value, $subject, $body);
}

# 呼び出し側
my $email = EmailAddress->new('user@example.com');
register_user($email, 'John Doe');
send_email($email, 'Welcome', 'Hello!');
```

### 改善されたポイント

1. **バリデーションが1箇所に集約**された
2. **型情報が明確**（単なる文字列ではなくEmailAddressオブジェクト）
3. **不正な値を持つオブジェクトは存在し得ない**
4. **テストが容易**（EmailAddressクラスのテストだけで全体の品質が保証される）
5. **変更に強い**（バリデーションルールの変更はEmailAddressクラス1箇所で完結）

## 実践的なテストコード全体

完全なテストコードを示します。

これをベースに、自分のプロジェクトに合わせて拡張できます。

```perl
# t/email_address_complete.t
use strict;
use warnings;
use Test::More;

use_ok('EmailAddress');

subtest 'constructor validation' => sub {
    eval { EmailAddress->new(undef) };
    like($@, qr/required/, 'undef is rejected');
    
    eval { EmailAddress->new('') };
    like($@, qr/cannot be empty/, 'empty string is rejected');
    
    my @invalid_emails = (
        'no-at-sign',
        '@no-local-part.com',
        'no-domain@',
        'invalid@domain',
        'spaces in@email.com',
    );
    
    for my $invalid (@invalid_emails) {
        eval { EmailAddress->new($invalid) };
        like($@, qr/Invalid email/, "rejects: $invalid");
    }
};

subtest 'valid email addresses' => sub {
    my @valid_emails = (
        'simple@example.com',
        'user.name@example.com',
        'user-name@example.co.jp',
        'user_name@sub.example.com',
    );
    
    for my $valid (@valid_emails) {
        my $email = EmailAddress->new($valid);
        isa_ok($email, 'EmailAddress');
        is($email->value, $valid, "accepts: $valid");
    }
};

subtest 'equality' => sub {
    my $email1 = EmailAddress->new('test@example.com');
    my $email2 = EmailAddress->new('test@example.com');
    my $email3 = EmailAddress->new('other@example.com');
    
    ok($email1->equals($email2), 'equal values are equal');
    ok(!$email1->equals($email3), 'different values are not equal');
};

subtest 'string overload' => sub {
    my $email = EmailAddress->new('test@example.com');
    is("$email", 'test@example.com', 'stringifies correctly');
};

done_testing();
```

## 値オブジェクトの5つのメリット

EmailAddress値オブジェクトを実装したことで、次のような恩恵が得られます：

### 1. 型安全性の向上

```perl
# Before: 何でも受け入れてしまう
sub send_email {
    my ($to, $subject, $body) = @_;
}

# After: 型で保証される
sub send_email {
    my ($to, $subject, $body) = @_;
    # $toはEmailAddressオブジェクト、必ず有効
}
```

### 2. バリデーションの一元化

バリデーションロジックは`EmailAddress`クラスにのみ存在します。

アプリケーション全体で再利用されます。

### 3. ドメインルールの明示化

「メールアドレス」という概念が、単なる文字列ではなく独自のルールと振る舞いを持つドメインオブジェクトとして表現されます。

### 4. テストの容易さ

EmailAddressクラスのテストを書けば、メールアドレスに関するすべての振る舞いをテストできます。

アプリケーションコードでは、EmailAddressオブジェクトを使うだけでよくなります。

### 5. 変更への耐性

メールアドレスのバリデーションルールが変わっても、変更箇所は`EmailAddress`クラスの1箇所だけです。

## より厳密な不変性を求めるなら

今回の実装では`Class::Tiny`を使いましたが、より厳密な不変性が必要な場合は`Class::Tiny::Immutable`を使うことができます。

{{< linkcard "https://metacpan.org/pod/Class::Tiny::Immutable" >}}

```perl
package EmailAddress;
use strict;
use warnings;
use Class::Tiny::Immutable qw(value);

sub BUILD {
    my ($self) = @_;
    # 同じバリデーションロジック
}
```

`Class::Tiny::Immutable`を使うと、オブジェクト構築後に属性を変更しようとすると例外が発生します。

真の不変性が保証されます。

## まとめ

この記事では、プリミティブ型の呪縛から解放される手段として、値オブジェクトパターンを紹介しました。

### 値オブジェクトの3つの特徴

- **不変性**: 一度作ったら変わらない
- **等価性**: 値で比較する
- **自己バリデーション**: 不正な値を持たない

### TDDで実装する流れ

1. テストを先に書く（レッド）
2. 最小限の実装で通す（グリーン）
3. リファクタリングで改善する

### 値オブジェクトのメリット

- 型安全性の向上
- バリデーションの一元化
- ドメインルールの明示化
- テストの容易さ
- 変更への耐性

### 📚 次のステップ

値オブジェクトの基礎を理解したら、次は実際のAPI仕様に適用してみましょう：

👉 **[第2回：JSON-RPC 2.0のリクエスト/エラーをTDDで実装](../jsonrpc-value-object-outlines/)**
- JSON-RPC仕様を値オブジェクトで表現
- 複雑な仕様制約をテストコードに変換
- ファクトリパターンとの組み合わせ

### 🔗 関連リソース

**外部リンク**

- [Martin Fowler - Value Object](https://martinfowler.com/bliki/ValueObject.html)
- [Class::Tiny - MetaCPAN](https://metacpan.org/pod/Class::Tiny)
- [Class::Tiny::Immutable - MetaCPAN](https://metacpan.org/pod/Class::Tiny::Immutable)

**関連記事**（準備中）

- Perlのテスト駆動開発入門
- Class::Tinyで始めるモダンPerl
- ドメイン駆動設計とPerl
