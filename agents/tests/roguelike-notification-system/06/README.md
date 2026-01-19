# 第6回：Observerを動的に追加・削除しよう

## 概要
ゲーム中にサウンドをON/OFFしたい！Observerを実行時に追加・削除できる仕組みを実装。動的な設定変更に対応するコードを書きます。

## 検証結果

### ✅ 構文チェック
```
game.pl syntax OK
```

### ✅ 実行結果
```
=== ダンジョン探索開始 ===

[LOG] スライムを倒した！

[SETTINGS] サウンドをONにしました

[LOG] ゴブリンを倒した！
[SOUND] ♪ サウンドエフェクト再生

[SETTINGS] サウンドをOFFにしました

[LOG] オークを倒した！
```

## 新機能
**GameSettings（設定管理クラス）の導入**:

1. **toggle_sound**: サウンドのON/OFFを切り替え
2. **sound_enabled**: サウンドの状態を保持
3. **sound_observer**: 内部でSoundObserverインスタンスを管理

## 動的管理のメリット
- **ユーザー設定の反映**: サウンドON/OFF等をリアルタイムに切り替え
- **リソースの節約**: 不要なObserverを削除してパフォーマンス向上
- **デバッグの容易さ**: デバッグ用Observerを一時的に追加
- **段階的な機能解放**: ゲームの進行に応じて新しいObserverを追加

## 使用されているクラス
- `GameEvent`: イベントを表現
- `GameEventObserver`: Observer共通インターフェース
- `LogObserver`: ログ出力
- `SoundObserver`: サウンドエフェクト
- `GameEventEmitter`: イベント発生元
- `GameSettings`: 設定管理（新規）

## 検証者のコメント
実行時の動的な管理が素晴らしい！`attach`/`detach`を活用することで、ゲームの状態に応じてObserverを追加・削除できます。特に設定管理を`GameSettings`クラスとして独立させたことで、責務が明確になりました。
