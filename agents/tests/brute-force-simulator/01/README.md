# 第1回: 基本的なブルートフォース攻撃

## 概要

3重のforループを使った最もシンプルなブルートフォース攻撃の実装です。

## ファイル構成

- `lib/PasswordLock.pm` - 3桁のダイヤル錠を模したクラス
- `cracker_v1.pl` - 3重forループで000～999まで全探索するスクリプト
- `t/` - テストコード

## 実行方法

```bash
perl cracker_v1.pl
```

## テスト実行

```bash
prove -lv t/
```

## 学習ポイント

- Mooを使ったシンプルなクラス定義
- 3重forループによる全探索
- `experimental qw(signatures)` によるサブルーチンシグネチャの使用
