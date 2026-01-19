# 「Perlでハニーポット侵入レーダーを作ろう」テストコードについて

このディレクトリには、シリーズ記事から抽出したコードを検証用に保存しています。

## 構成

```
honeypot-intrusion-radar/
├── 01/  # 第1回: 侵入ログを光らせろ
│   ├── test_single_event.pl
│   └── test_multiple_events.pl
├── 03/  # 第3回: 通知係を分離しよう
│   └── observers_separated.pl
└── 09/  # 第9回: 完成！侵入レーダー司令室
    └── complete_radar.pl
```

## 検証結果

✅ すべてのコードが Perl v5.42.0 で正常動作
✅ 警告（Warning）なし
✅ 期待通りの出力を確認

## 実行方法

各ディレクトリに移動して実行:

```bash
cd 01
perl test_single_event.pl
perl test_multiple_events.pl

cd ../03
perl observers_separated.pl

cd ../09
perl complete_radar.pl
```

## 注意事項

- Moo モジュールが必要です（`cpanm Moo` でインストール）
- Perl v5.36 以上が必要です
