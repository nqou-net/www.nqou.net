# 調査サマリー：JSON-RPC 2.0 & Perl値オブジェクト実装

**調査日**: 2025-12-15  
**目的**: 「PerlでJSON-RPC 2.0のオブジェクトを値オブジェクトとして定義してみた」技術シリーズ記事のための情報収集

---

## 🎯 調査結果の重要ポイント

### 1. JSON-RPC 2.0仕様 ⭐⭐⭐⭐⭐

**公式仕様**: https://www.jsonrpc.org/specification (2013年1月4日版)

#### 重要な制約（記事で必ず言及すべき）

| オブジェクト | MUST制約 | MUST NOT制約 |
|------------|---------|-------------|
| Request | `jsonrpc: "2.0"` 必須<br>`method` 必須 | 通知の場合、`id`を含めてはならない |
| Response | 成功時: `result` 必須<br>エラー時: `error` 必須 | `result`と`error`の同時存在禁止 |
| Error | `code` (整数) 必須<br>`message` (文字列) 必須 | 予約済みコード範囲の不適切使用禁止 |

**標準エラーコード範囲**: -32768 ～ -32000 (予約済み)

---

### 2. 値オブジェクトパターン（DDD） ⭐⭐⭐⭐⭐

**権威ある定義**: Martin Fowler - https://martinfowler.com/bliki/ValueObject.html

#### 5つの本質的特性

1. **アイデンティティの欠如**: IDではなく属性で定義
2. **不変性 (Immutability)**: 構築後は変更不可
3. **値による等価性**: 全属性値が同じなら等価
4. **振る舞いのカプセル化**: ドメインロジックを内包
5. **交換可能性**: 同じ値なら自由に置換可能

#### 動的型付け言語（Perl）での注意点

- 言語レベルの不変性強制がない → 実装パターンと規約に依存
- テストが特に重要（コンパイル時チェックなし）
- 明示的な等価性メソッドの実装が必要

---

### 3. Perlでの値オブジェクト実装 ⭐⭐⭐⭐

#### 推奨CPANモジュール（優先度順）

| モジュール | 推奨度 | 特徴 | 用途 |
|-----------|-------|-----|------|
| **Class::Tiny::Immutable** | ★★★★★ | 真の不変性、軽量 | 軽量値オブジェクト |
| **Moose** | ★★★★★ | 強力、`is => 'ro'` | 大規模プロジェクト |
| **Moo** | ★★★★☆ | Moose互換、高速 | 中規模プロジェクト |
| **immutable** | ★★★★☆ | 不変データ構造 | 関数型スタイル |

**JSON-RPC実装**:
- **JSON::RPC2** (★★★★★): 最新のJSON-RPC 2.0実装、トランスポート非依存
- **JSON/JSON::XS**: JSONシリアライゼーション

#### 重要なブログリソース

**Curtis "Ovid" Poe** (Perlコミュニティの権威):
- Use Immutable Objects: https://dev.to/ovid/use-immutable-objects-4pbl
- 不変オブジェクトの実践的ガイダンス

---

### 4. TDDとTest::More ⭐⭐⭐⭐⭐

**公式ドキュメント**: https://perldoc.perl.org/Test::More

#### 値オブジェクトのテスト戦略

```perl
# 1. テストプラン
use Test::More;

# 2. 構築テスト
use_ok('JsonRpc::Request');
my $req = JsonRpc::Request->new(...);
isa_ok($req, 'JsonRpc::Request');

# 3. 等価性テスト（最重要）
is_deeply($obj1, $obj2, 'Value equality check');

# 4. サブテストで整理
subtest 'constructor' => sub { ... };
subtest 'equality' => sub { ... };

done_testing();
```

**重要メソッド**:
- `is_deeply`: 複雑なデータ構造の深い比較（値オブジェクトに最適）
- `subtest`: テストの階層化と整理
- `is`, `isa_ok`, `use_ok`: 基本的な検証

---

## 📚 記事執筆時の必須参照リソース（厳選10）

### 仕様・定義（必読）

1. **JSON-RPC 2.0 Specification** (公式) ⭐⭐⭐⭐⭐  
   https://www.jsonrpc.org/specification

2. **Value Object - Martin Fowler** ⭐⭐⭐⭐⭐  
   https://martinfowler.com/bliki/ValueObject.html

3. **JSON-RPC Error Codes Reference** ⭐⭐⭐⭐  
   https://json-rpc.dev/docs/reference/error-codes

### Perl実装（必読）

4. **Class::Tiny::Immutable - MetaCPAN** ⭐⭐⭐⭐⭐  
   https://metacpan.org/pod/Class::Tiny::Immutable

5. **JSON::RPC2 - GitHub** ⭐⭐⭐⭐  
   https://github.com/powerman/perl-JSON-RPC2

6. **Use Immutable Objects - Curtis "Ovid" Poe** ⭐⭐⭐⭐⭐  
   https://dev.to/ovid/use-immutable-objects-4pbl

### テスト（必読）

7. **Test::More - Perldoc** ⭐⭐⭐⭐⭐  
   https://perldoc.perl.org/Test::More

8. **Comparing complex data-structures using is_deeply - Perl Maven** ⭐⭐⭐⭐  
   https://perlmaven.com/comparing-complex-data-structures-with-is-deeply

### 理論・実装パターン（推奨）

9. **Implementing value objects - Microsoft Learn** ⭐⭐⭐⭐⭐  
   https://learn.microsoft.com/en-us/dotnet/architecture/microservices/microservice-ddd-cqrs-patterns/implement-value-objects

10. **Value Objects in Domain-Driven Design - GitHub** ⭐⭐⭐⭐  
    https://github.com/SAP/curated-resources-for-domain-driven-design/blob/main/knowledgebase/concepts/tactical-concepts/value-objects.md

---

## 📝 記事シリーズ構成案（全3回）

### 第1回：JSON-RPC 2.0とは何か？仕様を理解する

**内容**:
- JSON-RPC 2.0の概要（ステートレス、トランスポート非依存）
- Request、Response、Errorオブジェクトの詳細定義
- MUST/MUST NOT制約の重要性
- バッチリクエストと通知の仕組み

**重点リソース**:
- JSON-RPC 2.0 Specification (公式)
- JSON-RPC Error Codes Reference
- JSON-RPC Batch Requests Example

### 第2回：値オブジェクトパターンとPerlでの実装

**内容**:
- DDDにおける値オブジェクトの定義と特性
- 不変性、等価性、カプセル化の原則
- Perlでの実装選択肢（Moose vs Class::Tiny::Immutable）
- JSON-RPC 2.0オブジェクトを値オブジェクトとして定義する意義

**重点リソース**:
- Martin Fowlerの値オブジェクト解説
- Class::Tiny::Immutable ドキュメント
- Curtis "Ovid" Poeのブログ
- Microsoft Learn実装ガイド

### 第3回：TDDで作るJSON-RPC 2.0値オブジェクト

**内容**:
- Test::Moreによるテスト駆動開発
- Request、Response、Errorクラスの完全実装
- is_deeplyによる値の等価性テスト
- 実行可能な完全なコード例とテストスイート

**重点リソース**:
- Test::More公式ドキュメント
- Perl Mavenのis_deeplyガイド
- JSON::RPC2実装例

---

## ✅ 技術的正確性チェックリスト

記事執筆時に確認すべき項目:

### JSON-RPC 2.0仕様

- [ ] 公式仕様書（2013年1月4日版）からの引用
- [ ] MUST/MUST NOT制約の正確な記載
- [ ] 排他性（resultとerrorの相互排他）の説明
- [ ] 標準エラーコード範囲（-32768〜-32000）の明記
- [ ] 通知の特性（idなし、レスポンスなし）の説明

### 値オブジェクトパターン

- [ ] Martin Fowlerの定義を参照
- [ ] 5つの主要特性（アイデンティティ欠如、不変性、等価性、カプセル化、交換可能性）の説明
- [ ] 動的型付け言語特有の課題の言及
- [ ] DDDにおける位置づけの説明

### Perl実装

- [ ] 全コード例の動作確認済み
- [ ] CPANモジュールのバージョン明記
- [ ] 依存関係の明確な記載
- [ ] 代替実装方法の提示

### テスト

- [ ] Test::Moreの使用例
- [ ] is_deeplyによる等価性テストの実装
- [ ] サブテストによる整理
- [ ] done_testing()の使用

---

## 🔍 追加調査が必要な場合の候補

記事執筆中に必要に応じて調査:

1. **パフォーマンス比較**（必要であれば）
   - Moose vs Moo vs Class::Tiny::Immutable
   - ベンチマーク結果

2. **Perlバージョン互換性**
   - 最小要求バージョン
   - バージョン間の違い

3. **実際のプロダクション使用例**
   - GitHubでの実装例検索
   - CPANモジュールの依存関係グラフ

4. **エッジケース**
   - バッチリクエストの詳細処理
   - エラーハンドリングの実装パターン

---

## 💡 執筆時の推奨アプローチ

1. **段階的説明**: Why（なぜ） → What（何を） → How（どのように）
2. **実行可能なコード**: 全てのコード例をそのまま実行可能に
3. **一次資料優先**: 公式仕様・公式ドキュメントを最優先で引用
4. **信頼性の明示**: 引用元のURLと信頼性レベルを明記
5. **用語の統一**: 値オブジェクト、不変性、等価性等の日本語訳を統一

---

**詳細レポート**: `research-jsonrpc-value-object-perl.md` を参照  
**次のステップ**: 本サマリーを基に記事執筆を開始
