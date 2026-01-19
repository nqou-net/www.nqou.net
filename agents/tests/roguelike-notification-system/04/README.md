# 第4回：通知を受け取る約束を決めよう

## 概要
全Observerがupdateメソッドを持つ約束をMoo::Roleで定義。requiresでインターフェースを設計し、統一的な通知の仕組みを構築します。

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
1. **Moo::Roleの導入**:
   - `GameEventObserver`: `requires 'update'`でインターフェースを定義
   - 実装漏れがあるとクラスロード時にエラーになる

2. **新しいObserver追加**:
   - `SoundObserver`: サウンドエフェクトを再生

## 使用されているクラス
- `GameEvent`: イベントを表現
- `GameEventObserver`: Observer共通インターフェース（Moo::Role）
- `LogObserver`: ログ出力
- `AchievementObserver`: 実績管理
- `SoundObserver`: サウンドエフェクト（新規）

## Moo::Roleのメリット
- **契約の明示**: 「Observerは必ずupdateを持つ」という約束が明確
- **早期エラー発見**: 実装漏れがあればクラスロード時にエラー
- **ドキュメント効果**: Roleをwithすれば Observer になれるとわかる
- **拡張の安全性**: 新しいObserverを追加するときの指針になる

## 検証者のコメント
Perlらしいエレガントな設計！`Moo::Role`の`requires`を使うことで、型安全性が高まりました。新しい`SoundObserver`を追加する際も、`with 'GameEventObserver'`と`update`メソッドの実装を忘れない限り、安全に拡張できます。
