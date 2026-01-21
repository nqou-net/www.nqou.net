# 第4回: ポリモーフィズムを活用したブルートフォース攻撃

## 概要

ポリモーフィズムを活用して、複数の攻撃手法（ブルートフォース・辞書攻撃）を
統一的なインターフェースで扱える実装です。

## ファイル構成

- `lib/PasswordLock.pm` - 3桁のダイヤル錠を模したクラス
- `lib/BruteForceIterator.pm` - ブルートフォース用のIteratorクラス
- `lib/DictionaryIterator.pm` - 辞書攻撃用のIteratorクラス
- `cracker_poly.pl` - ポリモーフィズムを活用したスクリプト
- `t/` - テストコード

## 実行方法

```bash
# ブルートフォースモード（デフォルト）
perl cracker_poly.pl --mode=brute

# 辞書攻撃モード
perl cracker_poly.pl --mode=dict
```

## テスト実行

```bash
prove -lv t/
```

## 学習ポイント

- ポリモーフィズムの活用（Duck Typing）
- 同じインターフェース（`next`メソッド）を持つ異なるクラス
- `Getopt::Long` を使ったコマンドライン引数処理
- ファイルハンドリングとリソース管理（DEMOLISH）

## 設計の利点

- 新しい攻撃手法を簡単に追加できる
- 攻撃手法の切り替えが容易
- それぞれのIteratorが独立してテスト可能
