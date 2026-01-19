# 第5回：イベント発生元を管理しよう

## 概要
Observerリストを保持し、イベント発生時に全Observerへ通知するGameEventEmitterを作成。attach/detach/notifyの実装方法を解説。

## 検証結果

### ✅ 構文チェック
```
game.pl syntax OK
```

### ✅ 実行結果
```
=== ダンジョン探索開始 ===

[LOG] スライムを倒した！
[ACHIEVEMENT] 実績解除: はじめての勝利
[SOUND] victory.wav を再生

[LOG] 薬草を手に入れた！
[SOUND] pickup.wav を再生

[LOG] レベルが5になった！
[ACHIEVEMENT] 実績解除: 成長
[SOUND] levelup.wav を再生

=== 解除した実績 ===
- はじめての勝利
- 成長
```

## 新機能
**GameEventEmitter（Subject/Observable）の導入**:

1. **attach**: Observerを登録
2. **detach**: Observerを解除  
3. **notify**: 全Observerに通知

## 使用されているクラス
- `GameEvent`: イベントを表現
- `GameEventObserver`: Observer共通インターフェース
- `LogObserver`: ログ出力
- `AchievementObserver`: 実績管理
- `SoundObserver`: サウンドエフェクト
- `GameEventEmitter`: イベント発生元（新規）

## コードの改善点
以前は：
```perl
for my $event (@events) {
    $log_observer->update($event);
    $achievement_observer->update($event);
    $sound_observer->update($event);
}
```

今は：
```perl
for my $event (@events) {
    $emitter->notify($event);  # 一回の呼び出しで全Observerに通知！
}
```

## 検証者のコメント
Observerパターンの核心部分が完成しました！`GameEventEmitter`が全Observerを管理し、`notify`一回で全てに通知できます。新しいObserverを追加する際も、`attach`するだけで済みます。これぞ「開放閉鎖原則」の実践です！
