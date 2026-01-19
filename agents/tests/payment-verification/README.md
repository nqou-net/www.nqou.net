# 決済審査システム - Payment Verification System

架空ECサイト「ペルマート」で学ぶ決済審査システムの実装例

## Quick Start

### Article 1: 基本的な決済審査
```bash
cd 01
perl payment-check-01.pl
prove t/
```

### Article 2: 条件追加版
```bash
cd 02
perl payment-check-02.pl
prove t/
```

### Article 3: Chain of Responsibility版
```bash
cd 03
export PERL5LIB="$HOME/perl5/lib/perl5:$PERL5LIB"
perl payment-check-03.pl
prove t/
```

## 必要環境

- Perl v5.36以上
- Article 3のみ: Moo (CPAN)

## テスト結果

✅ **71/71 tests passing**
- Article 1: 12 tests
- Article 2: 16 tests  
- Article 3: 43 tests

## ファイル構成

```
01/
  payment-check-01.pl     # 基本版（金額・有効期限チェック）
  t/01-basic.t            # テスト

02/
  payment-check-02.pl     # 条件追加版（ブラックリスト・残高・不正検知）
  t/01-comprehensive.t    # テスト

03/
  payment-check-03.pl     # Chain of Responsibility版
  lib/                    # チェッカーモジュール
    PaymentChecker.pm     # 基底クラス
    LimitChecker.pm       # 金額チェッカー
    ExpiryChecker.pm      # 有効期限チェッカー
    BlacklistChecker.pm   # ブラックリストチェッカー
  t/                      # テスト
    01-modules.t          # モジュール単体テスト
    02-integration.t      # 統合テスト
```

## 学習内容

1. **Article 1**: シンプルな審査ロジック
2. **Article 2**: 要件増加による複雑化
3. **Article 3**: デザインパターンによる解決

詳細は [walkthrough.md](walkthrough.md) を参照してください。
