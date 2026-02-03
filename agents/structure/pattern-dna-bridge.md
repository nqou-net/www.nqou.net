# 構造案: コードドクター〜クラス爆発緊急手術（Bridge）

- **パターン**: Bridge
- **テーマ**: 万能レポート出力エンジンのリファクタリング
- **公開日時**: 2026-02-17T00:56:48+09:00
- **対象読者**: クラス継承を使いすぎて修正が大変になっている中級開発者

## ストーリーライン

### 1. 緊急搬送 (Introduction)
- **患者**: 社内システムのレポートツール担当者。
- **症状**: 「新しいレポート形式（JSON）」を追加しようとしたら、既存の「日報」「月報」「年報」...全ての組み合わせ分のクラスを作らなくてはならず、徹夜続きで倒れた。
- **搬送時の叫び**: 「もうクラスを作りたくない！掛け算で増えていくんだ！」

### 2. 診断 (Diagnosis)
- **ドクターの所見**: 「典型的な『多次元継承麻痺』だ。機能（レポートの種類）と実装（出力形式）が一つの継承ツリーに混在している」
- **助手の解説**: 「つまり、レポートの種類が増えるたびに、全フォーマット分を作らないといけないし、フォーマットが増えると全レポート分直さないといけない状態ですね」
- **Beforeコード**:
    - `Report` (基底)
        - `DailyReport`
            - `DailyReportText`
            - `DailyReportHTML`
        - `MonthlyReport`
            - `MonthlyReportText`
            - `MonthlyReportHTML`
    - 新たに `MonthlyReportJSON` などを追加しようとして破綻。

### 3. 処方 (Prescription)
- **処方箋**: Bridge パターン
- **ドクター**: 「『機能のクラス階層』と『実装のクラス階層』を分ける。二つの山を橋（Bridge）で繋ぐのだ」
- **助手**: 「継承ではなく、委譲（Aggregation）を使って解決しましょう」

### 4. 手術 (Surgery)
- **Step 1: 実装の分離 (Implementor Creation)**
    - 出力処理を担当する `Formatter` インターフェース（抽象クラス）を作成。
    - 具体的な `TextFormatter`, `HtmlFormatter` を実装。
- **Step 2: 橋の架設 (Bridge Construction)**
    - `Report` クラスに `Formatter` を持たせる（委譲）。
    - `print_report()` メソッドなどで `formatter->format(...)` を呼ぶように修正。
- **Step 3: 機能の拡張 (Refined Abstraction)**
    - `DailyReport`, `MonthlyReport` は `Report` を継承するが、フォーマットのことは気にしなくて良くなる。

### 5. 退院 (Discharge)
- **Afterコード**: すっきり整理され、新しいフォーマット（JSON）追加も `JsonFormatter` クラスを1つ作るだけで済むようになった。
- **ドクター**: 「これでクラスの増加は、掛け算（M × N）から足し算（M ＋ N）になった」
- **助手**: 「今後の拡張も怖くないですね。お大事に！」

## コード設計

### Before (Perl)
```perl
package Report;
sub print { die }

package DailyReport;
use parent 'Report';
# ...

package DailyReportText;
use parent 'DailyReport';
sub print { print "Daily Report (Text)...\n" }

package DailyReportHTML;
use parent 'DailyReport';
sub print { print "<html>Daily Report...</html>\n" }

# ... これが延々と続く
```

### After (Perl)
```perl
# Implementor
package Formatter;
sub format_header { die }
sub format_body { die }
sub format_footer { die }

# Concrete Implementors
package TextFormatter;
use parent 'Formatter';
# ...

package HtmlFormatter;
use parent 'Formatter';
# ...

# Abstraction
package Report;
sub new {
    my ($class, $formatter) = @_;
    return bless { formatter => $formatter }, $class;
}
sub display {
    my $self = shift;
    $self->{formatter}->format_header();
    $self->{formatter}->format_body($self->get_data());
    $self->{formatter}->format_footer();
}

# Refined Abstraction
package DailyReport;
use parent 'Report';
sub get_data { ... }
```

## 登場人物の動き
- **ドクター**: クラス図を見て「醜いスパゲッティだ」と一刀両断。
- **助手**: 継承関係でがんじがらめになっている患者のコードを、ホワイトボードで図解してあげる。
- **患者**: 「継承こそオブジェクト指向の華だと思っていたのに…」とショックを受けるが、Bridgeの柔軟性に感動する。

## 記事構成案
1. **プロローグ**: クラス増殖の悪夢
2. **診察室**: 掛け算で増えるクラス
3. **Bridgeパターンとは**: 機能と実装の分離
4. **緊急手術**: 委譲への切り替え
5. **術後経過**: 拡張性の確認
6. **エピローグ**: 橋を架けるということ
