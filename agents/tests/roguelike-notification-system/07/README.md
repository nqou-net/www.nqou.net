# 第7回：型チェックでバグを防ごう

## 概要
間違ったオブジェクトがObserverとして登録されないよう、does制約で型チェック。PerlとMooでの安全な実装パターンを学びます。

## 検証結果

### ✅ 構文チェック
```
game.pl syntax OK
```

### ✅ 実行結果
```
=== ダンジョン探索 ===

[LOG] スライムを倒した！
[ACHIEVEMENT] 実績解除: はじめての勝利
[SOUND] ♪ サウンドエフェクト再生
```

## 新機能
**型チェックの追加**:

```perl
sub attach ($self, $observer) {
    unless ($observer->does('GameEventObserver')) {
        die "Error: ObserverはGameEventObserverを実装している必要があります";
    }
    push @{$self->observers}, $observer;
}
```

## 型チェックのメリット
- **早期エラー発見**: 登録時にエラーになるため、問題を即座に発見
- **デバッグが容易**: 「どこで間違えたか」がすぐにわかる
- **コードの意図が明確**: 「GameEventObserverが必要」という意図が伝わる
- **安全な拡張**: 新しいObserverを追加するときの指針になる

## 使用されているクラス
- `GameEvent`: イベントを表現
- `GameEventObserver`: Observer共通インターフェース
- `LogObserver`: ログ出力
- `AchievementObserver`: 実績管理
- `SoundObserver`: サウンドエフェクト
- `GameEventEmitter`: イベント発生元（型チェック機能を追加）

## 検証者のコメント
型チェックの導入で安全性が大幅に向上しました！間違ったオブジェクトを`attach`しようとすると、実行時の早い段階でエラーが発生します。Perlは動的型付け言語ですが、`does`メソッドを活用することで、Roleベースの型チェックを実現できます。これはPerl/Mooの強力な機能の一つです。
