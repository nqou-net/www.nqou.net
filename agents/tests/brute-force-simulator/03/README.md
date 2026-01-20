# 第3回: Iteratorパターンを使ったブルートフォース攻撃

## 概要

Iteratorパターンを使って、探索ロジックとクラッキングロジックを分離した実装です。

## ファイル構成

- `lib/PasswordLock.pm` - 3桁のダイヤル錠を模したクラス（第1回と同じ）
- `lib/BruteForceIterator.pm` - ブルートフォース用のIteratorクラス
- `cracker_iterator.pl` - Iteratorを使ったスクリプト
- `t/` - テストコード

## 実行方法

```bash
perl cracker_iterator.pl
```

## テスト実行

```bash
prove -lv t/
```

## 学習ポイント

- Iteratorパターンの実装
- 関心の分離（探索ロジックとクラッキングロジックの分離）
- `lazy` 属性ビルダーの使用
- `sprintf` による0埋めフォーマット

## 設計の利点

- 探索アルゴリズムを簡単に交換できる
- テストが容易
- 再利用可能なコンポーネント
