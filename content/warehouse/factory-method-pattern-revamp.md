---
date: 2026-01-16T00:00:00+09:00
description: 'Factory Methodパターン改善版連載のための調査結果 - Perl/Moo実装と連載設計の基礎'
draft: true
epoch: 1768489200
image: /favicon.png
iso8601: 2026-01-16T00:00:00+09:00
tags:
  - design-patterns
  - factory-method
  - creational-patterns
  - perl
  - moo
title: Factory Methodパターン改善版調査ドキュメント
---

# Factory Methodパターン改善版調査ドキュメント

## 調査目的

Factory Methodパターンの連載企画を設計するために、基礎定義、Perl/Mooでの実装要点、利用シーン、利点・欠点、既存記事の状況を整理する。

- **調査対象**: Factory Methodパターンの定義、構造、適用場面、関連パターンとの差分
- **想定読者**: Perl入学式卒業レベルでMooによるOOP入門を完了した読者
- **調査実施日**: 2026年1月16日

---

## 1. 概要

### 1.1 Factory Methodパターンの定義

**要点**:

- GoF（Gang of Four）の生成パターンの1つである
- オブジェクト生成のインターフェースを定義し、どのクラスを生成するかはサブクラスに委ねる
- 生成の責務をサブクラスに移譲することで、拡張時の既存コード修正を減らす（OCP）
- 生成対象の差し替えをクライアントから隠蔽できる

**根拠**:

- GoF原典および複数の技術解説サイトで定義が一致
- Refactoring Guruは「生成責務の遅延」と「サブクラスによる選択」を中心に説明している

**出典**:

- GoF原典: "Design Patterns: Elements of Reusable Object-Oriented Software"
- Refactoring Guru: https://refactoring.guru/design-patterns/factory-method
- Wikipedia: https://en.wikipedia.org/wiki/Factory_method_pattern
- Baeldung: https://www.baeldung.com/cs/factory-method-vs-factory-vs-abstract-factory

**信頼度**: 9/10（原典 + 複数の信頼性ある技術サイト）

---

### 1.2 Perl/Moo実装での基本構成

**要点**:

- Productインターフェースは `Moo::Role` の `requires` で表現できる
- Creatorは基底クラスとして `extends` で継承し、ファクトリメソッドをオーバーライドする
- `factory_method` はProductを返す契約を明示し、`does` で型チェックを行える

**根拠**:

- MooはRoleによるインターフェース宣言と継承による差し替えが可能
- GoFの構造（Creator/ConcreteCreator/Product/ConcreteProduct）と一致

**出典**:

- MetaCPAN: Moo https://metacpan.org/pod/Moo
- MetaCPAN: Moo::Role https://metacpan.org/pod/Moo::Role
- 内部資料: /content/warehouse/factory-method-pattern.md

**信頼度**: 8/10（公式ドキュメントと内部資料）

---

### 1.3 生成パターンの位置づけ

**要点**:

- Factory Methodは生成パターンの1つで、単一製品の生成に焦点を当てる
- Simple FactoryはGoFパターンではなく、if/elseによる分岐がOCPに弱い
- Abstract Factoryは複数製品（ファミリー）を扱い、Factory Methodより粒度が大きい

**根拠**:

- GoFの分類と技術解説サイトの比較表で一致

**出典**:

- GeeksforGeeks: https://www.geeksforgeeks.org/system-design/creational-design-pattern/
- Refactoring Guru: https://refactoring.guru/design-patterns/factory-method
- 内部資料: /content/warehouse/design-patterns-overview.md

**信頼度**: 8/10

---

## 2. 用途

### 2.1 具体的な利用シーン

**要点**:

| 利用シーン | 説明 | 具体例 |
|-----------|------|--------|
| プラグイン機構 | 実装差し替えをサブクラスで管理 | フォーマット出力プラグイン |
| 生成の切り替え | 生成するオブジェクト種別を追加しやすい | CSV/JSON/YAMLの出力クラス生成 |
| インフラ抽象化 | 環境差し替えを隠蔽 | DBドライバ生成、APIクライアント生成 |

**根拠**:

- フレームワーク設計でFactory Methodが頻出する
- 生成責務の分離が拡張性を担保するため

**出典**:

- Refactoring Guru: https://refactoring.guru/design-patterns/factory-method
- Baeldung: https://www.baeldung.com/cs/factory-method-vs-factory-vs-abstract-factory

**信頼度**: 8/10

---

## 3. サンプルコード

### 3.1 基本的な実装例

**要点**:

Product RoleとCreator基底クラス、ConcreteCreatorの最小構成を示す。

```perl
# 言語: perl
# バージョン: 5.36以上
# 依存: Moo

package Document;
use v5.36;
use Moo::Role;

requires 'render';

package ReportCreator;
use v5.36;
use Moo;

sub create_document ($self) {
    die 'override required';
}

sub export ($self) {
    my $doc = $self->create_document;
    return $doc->render;
}

package MonthlyReportCreator;
use v5.36;
use Moo;

extends 'ReportCreator';

sub create_document ($self) {
    return MonthlyReport->new;
}

package MonthlyReport;
use v5.36;
use Moo;

with 'Document';

sub render ($self) {
    return 'monthly report';
}

1;
```

**根拠**:

- Creatorが共通処理（export）を持ち、生成だけをサブクラスで差し替える
- GoFのCreator/ConcreteCreator/Product/ConcreteProduct構成と対応

**出典**:

- Refactoring Guru: https://refactoring.guru/design-patterns/factory-method
- 内部資料: /content/warehouse/factory-method-pattern.md

**信頼度**: 8/10

---

## 4. 利点・欠点

### 4.1 メリット

**要点**:

| メリット | 説明 | 具体例 |
|---------|------|--------|
| 拡張しやすい | 新しい生成対象をサブクラス追加で対応 | 新しい出力形式クラスを追加 |
| 生成責務を分離 | クライアントが具体クラスを知らずに済む | exportメソッドが共通化される |

**根拠**:

- OCPに沿った拡張が可能

**出典**:

- Refactoring Guru: https://refactoring.guru/design-patterns/factory-method

**信頼度**: 8/10

---

### 4.2 デメリット

**要点**:

| デメリット | 説明 | 影響 | 対策 |
|-----------|------|------|------|
| クラス数が増える | 生成対象ごとにCreator/ConcreteCreatorが増える | 規模が大きくなる | 生成対象が少ない場合はSimple Factoryを検討 |
| 継承前提の設計 | 継承が不要な場面では過剰 | 理解コストが増える | 設計目的を明確化 |

**根拠**:

- GoF原典や解説サイトでクラス爆発が指摘されている

**出典**:

- Wikipedia: https://en.wikipedia.org/wiki/Factory_method_pattern

**信頼度**: 7/10

---

## 5. 関連記事・内部リンク

### 5.1 関連する既存記事

| 記事タイトル | リンク | 関連性 |
|-------------|--------|--------|
| PerlとMooでレポートジェネレーターを作ってみよう（目次） | /2026/01/12/230702/ | Factory Methodを扱う既存連載の目次 |
| 第10回-最終回-これがFactory Methodパターンだ！ | /2026/01/12/230459/ | Factory Methodの解説記事 |
| デザインパターン概要 | /2025/12/25/234500/ | GoF全体像の参照 |
| 第12回-これがデザインパターンだ！ - ディスパッチャー | /2026/01/03/001541/ | Strategyパターンとの比較に有用 |

**要点**:

- Factory Methodを扱う既存連載と比較対象記事がすでに公開されている
- StrategyパターンやGoF全体像の記事と相互参照が可能

**根拠**:

- `/content/post` 配下の該当記事をgrepで確認

**出典**:

- /content/post/2026/01/12/230702.md
- /content/post/2026/01/12/230459.md
- /content/post/2025/12/25/234500.md
- /content/post/2026/01/03/001541.md

**信頼度**: 9/10（リポジトリ内の既存記事）

---

## 調査まとめ

### 主要な発見

1. Factory Methodは生成責務をサブクラスに委譲することで拡張性を確保する
2. Perl/MooではRoleとextendsでGoF構造を素直に再現できる
3. Factory Methodを扱う既存連載が存在する

---

**作成日**: 2026年1月16日  
**担当エージェント**: copilot  
**保存先**: `content/warehouse/factory-method-pattern-revamp.md`

---

## テンプレート使用時のチェックリスト

1. [ ] 各セクションに「要点」「根拠」「出典」「信頼度」が記載されているか
2. [ ] 出典URLが有効であるか
3. [ ] 信頼度の根拠が明確か（1-10の10段階評価）
4. [ ] 仮定がある場合は明記されているか
5. [ ] 内部リンク候補が調査されているか（grep で content/post を検索）
6. [ ] タグが英語小文字・ハイフン形式か
7. [ ] **提案・次のステップ・記事構成案・テーマ提案が含まれていないか**（調査ドキュメントは事実情報のみを記録し、提案は禁止）
