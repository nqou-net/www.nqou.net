# PerlとMooでドキュメント変換ツールを作ってみよう

Visitorパターンのテストコード

## 構成

- `01/` - 第1回: 基本のElementクラスとパース処理
- `02/` - 第2回: 継承による要素クラスの分離
- `03/` - 第3回: if/else分岐の肥大化
- `04/` - 第4回: Converterクラスへの処理委譲
- `05/` - 第5回: accept/visitによるDouble Dispatch
- `06/` - 第6回: OCPの実践（TextConverter追加）
- `07/` - 第7回: 複数Visitorの共存
- `08/` - 第8回: Visitorパターンの正体

## 実行方法

```bash
perl 01/main.pl
perl 02/main.pl
# ...
perl 08/main.pl
```

## 検証結果

- 全回のコードが警告なしで正常動作
- 検証日: 2026-01-23
