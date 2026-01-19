# 第8回：統計システムを追加しよう（OCP実践）

## 概要
敵撃破数やダメージ統計を記録するStatisticsObserverを追加。既存コードを変更せずに拡張する開放閉鎖原則（OCP）を体感します。

## 検証結果

### ✅ 構文チェック
```
game.pl syntax OK
```

### ✅ 実行結果（抜粋）
```
=== ダンジョン探索開始 ===

[LOG] スライムを倒した！
[ACHIEVEMENT] 実績解除: はじめての勝利
[SOUND] victory.wav を再生

...

=== ダンジョン探索終了 ===

=== 探索統計 ===
敵撃破数: 5
アイテム取得数: 2
レベルアップ回数: 1

=== 解除した実績 ===
- はじめての勝利
- ハンター見習い
```

## 新機能
**StatisticsObserver（統計管理）の追加**:

1. **stats**: 各イベント種類のカウントを保持
2. **update**: イベントを受け取ってカウントを増やす
3. **show_stats**: 統計を表示

## 開放閉鎖原則（OCP）の実践
既存コードを**一切変更せず**に新機能を追加：

- ✅ `GameEvent` - 変更なし
- ✅ `GameEventObserver` - 変更なし
- ✅ `LogObserver` - 変更なし
- ✅ `AchievementObserver` - 変更なし
- ✅ `SoundObserver` - 変更なし
- ✅ `GameEventEmitter` - 変更なし

変更したのは：
- 🆕 `StatisticsObserver` - 新規作成
- ➕ `main` - `attach`の呼び出しを追加

## 使用されているクラス
- `GameEvent`: イベントを表現
- `GameEventObserver`: Observer共通インターフェース
- `LogObserver`: ログ出力
- `AchievementObserver`: 実績管理
- `SoundObserver`: サウンドエフェクト
- `StatisticsObserver`: 統計記録（新規）
- `GameEventEmitter`: イベント発生元

## OCPのメリット
- **既存機能への影響なし**: 新機能追加で既存コードのバグリスクなし
- **テストの安定性**: 既存テストが失敗するリスクが低い
- **並行開発が容易**: チームメンバーが独立して新しいObserverを開発可能
- **ロールバックが簡単**: 新しいObserverを削除するだけで元に戻せる

## 検証者のコメント
これぞObserverパターンの真骨頂！新しい`StatisticsObserver`を追加する際、既存のどのクラスも変更していません。`with 'GameEventObserver'`して`update`メソッドを実装し、`attach`するだけで統合できました。これが「拡張に対して開かれ、修正に対して閉じられている」状態です。
