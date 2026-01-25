# 実装チェックリスト：新規パターン組み合わせシリーズ

**対象**: Slackボット指令センター、AST処理エンジン、マルウェア解析ラボ  
**作成日**: 2025-01-25

---

## 📋 Slackボット指令センター（第1優先）

### 技術スタック検証

#### 必須モジュール
- [x] **Mojolicious::Lite**: Webhook受信 → `cpanm Mojolicious`
- [x] **JSON**: Slack API通信 → コアモジュール（v5.36+）
- [x] **IPC::Run** or **Capture::Tiny**: コマンド実行 → `cpanm IPC::Run`
- [x] **Moo**: パターン実装 → `cpanm Moo`

#### 実装ステップ（見積もり：5日間）
1. **Day 1**: Webhook受信＋レスポンス確認
2. **Day 2**: Command パターン実装（3種類のコマンド）
3. **Day 3**: Mediator パターン実装（ルーティング）
4. **Day 4**: Observer パターン実装（通知・ログ）
5. **Day 5**: Undo/Redo 機能＋ドキュメント

#### デモ環境構築
```bash
# ngrokでローカルWebhook公開
ngrok http 3000

# Slackアプリ作成
# https://api.slack.com/apps
# - Slash Commands: /deploy, /status, /rollback
# - Request URL: https://<ngrok-id>.ngrok.io/slack/command
```

#### 記事構成案
```markdown
## 第1章：動機「Slackから全てを操りたい」
## 第2章：まず動かす（Webhook受信）
## 第3章：Commandパターンでコマンド化
## 第4章：Mediatorパターンでルーティング
## 第5章：Observerパターンで通知
## 第6章：Undo/Redo実装
## 第7章：拡張：新コマンド追加
## 第8章：本番運用の考慮事項
```

---

## 🌳 AST処理エンジン（第2優先）

### 技術スタック検証

#### 必須モジュール
- [x] **PPI**: Perl Parser → `cpanm PPI`
- [x] **Moo**: パターン実装 → `cpanm Moo`
- [x] **Data::Dumper**: デバッグ → コアモジュール

#### 実装ステップ（見積もり：7日間）
1. **Day 1**: PPI でAST取得＋ダンプ確認
2. **Day 2**: Composite パターンで独自AST構築
3. **Day 3**: Iterator パターンで走査実装
4. **Day 4**: Visitor パターン - 定数畳み込み
5. **Day 5**: Visitor パターン - 未使用変数削除
6. **Day 6**: Visitor パターン - ループ最適化
7. **Day 7**: コード生成＋テスト＋ドキュメント

#### サンプル入力コード
```perl
# 最適化前
my $unused = 42;
my $x = 2 + 3;  # 定数畳み込み可能
my $y = $x * 10;

for my $i (1..100) {
    # 不変式の持ち上げ可能
    my $const = 5 * 10;
    say $i + $const;
}
```

#### 期待される最適化結果
```perl
# 最適化後
my $x = 5;      # 定数畳み込み済み
my $y = 50;     # 伝播＋畳み込み

my $const = 50; # ループ外に移動
for my $i (1..100) {
    say $i + $const;
}
```

#### 記事構成案
```markdown
## 第1章：動機「Perlコードを最適化したい」
## 第2章：PPIでソース解析
## 第3章：Compositeパターンで独自AST
## 第4章：Iteratorパターンで走査
## 第5章：Visitorパターン - 定数畳み込み
## 第6章：Visitorパターン - 未使用変数削除
## 第7章：Visitorパターン - ループ最適化
## 第8章：コード生成
## 第9章：拡張：新パス追加方法
```

---

## 🔬 マルウェア解析ラボ（第3優先）

### 技術スタック検証

#### 必須モジュール
- [x] **Moo**: パターン実装 → `cpanm Moo`
- [ ] **Docker::API** or システムコマンド: コンテナ操作
- [x] **File::Temp**: 一時ディレクトリ → コアモジュール
- [x] **JSON**: 設定管理 → コアモジュール

#### 実装ステップ（見積もり：10日間）
1. **Day 1-2**: Abstract Factory パターン実装
2. **Day 3-4**: Builder パターン実装
3. **Day 5-6**: Prototype パターン実装
4. **Day 7**: Docker連携（コンテナ起動・停止）
5. **Day 8**: ログ収集・監視機能
6. **Day 9**: 自動クリーンアップ
7. **Day 10**: テスト＋ドキュメント

#### 安全性検証
```bash
# EICAR テストファイル（無害なマルウェア検体）
# 公式サイト: https://www.eicar.org/download-anti-malware-testfile/
# ※セキュリティスキャナーでの問題を避けるため、実際のテスト文字列は公式サイトから取得してください

# Docker隔離環境
docker run --rm --network none -v $(pwd):/samples ubuntu:22.04 bash -c "
  cd /samples
  file eicar.com
  strings eicar.com
"
```

#### 記事構成案
```markdown
## 第1章：動機「怪しいファイルを安全に調べたい」
## 第2章：安全性の考え方（サンドボックス設計）
## 第3章：Abstract Factoryで環境種別選択
## 第4章：Builderで段階的構築
## 第5章：Prototypeで設定複製
## 第6章：Docker連携
## 第7章：検体実行＋ログ監視
## 第8章：自動クリーンアップ
## 第9章：拡張：解析レポート自動生成
## 免責事項
```

---

## 🎯 共通実装ガイドライン

### コードスタイル
```perl
use v5.36;
use Moo;
use strict;
use warnings;

# パッケージ定義（ネスト）
package Pattern::Base {
    use Moo;
    # ...
}

package Pattern::Concrete {
    use Moo;
    extends 'Pattern::Base';
    # ...
}

# エントリーポイント
__PACKAGE__->run(@ARGV) unless caller;
```

### テストケース埋め込み
```perl
package Testing {
    use Test::More;
    
    sub run_tests {
        subtest 'Command Pattern' => sub {
            my $cmd = DeployCommand->new(params => {env => 'test'});
            my $result = $cmd->execute;
            ok $result->{success}, 'Command executed';
        };
        
        done_testing;
    }
}

# TEST_MODE=1 perl script.pl
Testing->run_tests if $ENV{TEST_MODE};
```

### 1ファイル完結のチェック
- [ ] 外部ファイル読み込みなし（設定もヒアドキュメントで埋め込み）
- [ ] CPANモジュールは最小限（Moo + 題材固有1〜2個）
- [ ] `chmod +x` で直接実行可能
- [ ] POD埋め込みで `perldoc script.pl` 可能

---

## 📊 記事公開前チェックリスト

### コンテンツ品質
- [ ] 動機・背景が明確
- [ ] 段階的実装（まず動く → パターン適用 → リファクタリング）
- [ ] UML図・シーケンス図を最低3つ
- [ ] コード全体を GitHub Gist で公開
- [ ] 実行デモのスクリーンショット or 動画

### 技術的正確性
- [ ] Perl v5.36+ で動作確認
- [ ] `perl -c script.pl` でシンタックスチェック
- [ ] `TEST_MODE=1 perl script.pl` でテスト全パス
- [ ] `perlcritic script.pl` で静的解析（warnings程度まで）

### SEO対策
- [ ] タイトルに「Perl デザインパターン <パターン名>」を含む
- [ ] メタディスクリプション140字以内
- [ ] 見出しにキーワード（Moo、GoF、実践）
- [ ] 内部リンク（既存シリーズへの相互リンク）

---

## 🚀 公開スケジュール案

### フェーズ1（1ヶ月目）
- **Week 1**: Slackボット実装＋記事執筆
- **Week 2**: Slackボット β版公開＋フィードバック収集
- **Week 3**: AST処理エンジン実装開始
- **Week 4**: AST処理エンジン記事執筆

### フェーズ2（2ヶ月目）
- **Week 1**: AST処理エンジン公開
- **Week 2**: マルウェア解析ラボ実装開始
- **Week 3**: マルウェア解析ラボ実装＋セキュリティ検証
- **Week 4**: マルウェア解析ラボ記事執筆

### フェーズ3（3ヶ月目）
- **Week 1**: マルウェア解析ラボ公開
- **Week 2-4**: 3本セットでのプロモーション＋有料化検討

---

## 💰 収益化オプション

### 無料版（ブログ記事）
- 基本実装＋解説
- 完全なソースコード公開（GitHub）

### 有料版（note/Zenn/Brain）
- 詳細設計ドキュメント（UML完全版）
- 拡張実装例（プラグインシステム等）
- 本番運用チェックリスト
- 1on1 質疑応答権（1回30分）

### 価格案
- 単品: ¥1,980 〜 ¥3,980
- 3本セット: ¥7,980（15%オフ）
- 企業ライセンス: ¥29,800（社内研修利用可）

---

## ✅ 最終確認項目

実装開始前に必ず確認：

1. [ ] 既存シリーズとの重複チェック完了
2. [ ] 技術スタック動作確認完了
3. [ ] 1ファイル完結可能性確認完了
4. [ ] 記事構成案レビュー完了
5. [ ] セキュリティ/倫理的問題なし確認完了

---

**作成者**: 調査・情報収集オタク  
**最終更新**: 2025-01-25  
**ステータス**: ✅ レビュー完了、実装開始可能
