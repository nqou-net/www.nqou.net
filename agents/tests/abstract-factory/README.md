# Abstract Factory Pattern Series - テスト

## 概要

「Perlで作る注文フローの国別キット」シリーズ（全8回）のコード検証用ディレクトリ。

## テスト実行方法

```bash
# 各回のテスト実行
perl agents/tests/abstract-factory/01/main.pl  # 第1回
perl agents/tests/abstract-factory/02/main.pl  # 第2回
# ... 以下同様

# 全回一括実行
for i in 01 02 03 04 05 06 07 08; do
  echo "=== Episode $i ===" && perl agents/tests/abstract-factory/$i/main.pl
done
```

## 検証結果

| 回 | テーマ | 結果 |
|----|--------|------|
| 01 | 国内注文処理 | ✅ PASS |
| 02 | 海外対応・if/else分岐 | ✅ PASS |
| 03 | 組み合わせミス（意図的バグ） | ✅ PASS |
| 04 | Abstract Factory導入 | ✅ PASS |
| 05 | 国内/海外Factory実装 | ✅ PASS |
| 06 | OrderProcessor・DI | ✅ PASS |
| 07 | EU市場追加・OCP確認 | ✅ PASS |
| 08 | 返品フロー追加・限界検証 | ✅ PASS |

## 検証日

2026-01-22

## 検証環境

- Perl v5.42.0
- Moo (CPANモジュール)
