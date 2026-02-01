````markdown
# ワークフロー知見ベース（統合版）

> 最終更新: 2026-02-01
> 総エントリ数: 5件

このファイルは各ワークフローの実行時に蓄積される知見を記録します。
各実行の最後に、得られた気づきをここに追記してください。

---

## カテゴリ別インデックス

| カテゴリ | 件数 | 説明 |
|----------|------|------|
| 成功パターン | 1 | うまくいったアプローチ |
| 失敗パターン | 2 | 避けるべきアプローチ |
| 新しい発見 | 1 | 予想外だった効果的な手法 |
| ユーザーフィードバック | 1 | 選定理由から得た洞察 |
| 改善提案 | 0 | ワークフロー自体への改善案 |

---

## ワークフロー別インデックス

| ワークフロー | 件数 |
|--------------|------|
| planning-v2 | 1 |
| series-unified-code | 2 |
| series-unified-write | 1 |
| series-unified-visual | 1 |
| series-unified-review | 0 |

---

## 知見エントリのテンプレート

```markdown
## YYYY-MM-DD: <コンテンツ名>

### ワークフロー: <planning-v2/series-unified-code/series-unified-write/series-unified-visual/series-unified-review>

### 知見タイプ: <成功/失敗/発見/フィードバック/改善>

**コンテキスト**: <状況の説明>

**知見**: <学んだこと>

**適用場面**: <今後どんな場面で活用できるか>
```

---

## エントリ一覧

<!-- 以下に知見エントリを追記 -->

## 2026-01-31: ダンジョンマスター（3パターン統合）

### ワークフロー: planning-v2

### 知見タイプ: フィードバック

**コンテキスト**: 3パターン（Strategy × Factory × Template Method）を組み合わせた「手で覚える」シリーズの構造案を3つ提案。推薦案Aは実務性重視、ユーザーはゲーム性重視の案Bを選択。

**知見**: 推薦案と異なる選択がされた場合、ユーザーの重視するポイント（実用性 vs 楽しさ）を事前に確認する価値がある。「デザインパターン学習」のコンテキストでは、「楽しさ」「ゲーム性」が重要な選択基準になりうる。

**適用場面**: 複数案の提示時、推薦理由に「実用性」「楽しさ」「ハッキング的魅力」などの軸を明示し、ユーザーの優先順位を確認する一言を添える。


## 2026-02-01: Secret Messenger (Observer × Decorator × Command)

### ワークフロー: series-unified-visual

### 知見タイプ: 失敗と改善

**コンテキスト**: Generated images using `generate_image` and attempted to resize using `sips -Z 640`.

**知見**: `sips` command failed with "Cannot write to file" error on MacOS for generated artifacts. Switched to `magick` (ImageMagick) which worked perfectly.

**適用場面**: Future image resizing steps in workflows should prefer `magick` if available or ensure file permissions/paths are correct for `sips`.


## 2026-02-01: タイムトラベル冒険ゲーム（Chain of Responsibility × State × Memento）

### ワークフロー: series-unified-code

### 知見タイプ: 失敗

**コンテキスト**: Perlコードで日本語コマンド（「北」「調べる」等）を処理するテストを作成。テスト実行時にパターンマッチが失敗。

**知見**: 日本語を含むPerlコードでは以下の3点が必須:
1. `use utf8;` をファイル冒頭に追加
2. `binmode STDOUT, ':utf8';` と `binmode STDIN, ':utf8';` を追加
3. 日本語をハッシュキーとして使用する場合はクォートで囲む（`{ '北' => ... }` 形式）

**適用場面**: Perlコード実装時、日本語を含む場合は最初からUTF-8対応を組み込む。テストファイルにも同様の対応が必要。


## 2026-02-01: タイムトラベル冒険ゲーム（続き）

### ワークフロー: series-unified-code

### 知見タイプ: 失敗

**コンテキスト**: `adventure.pl` 内で `GameMemento` パッケージを定義し、`SaveManager.pm` から参照しようとしたが、 `Can't locate GameMemento.pm` エラーが発生。

**知見**: Perlで複数パッケージを1ファイルにまとめる場合:
1. `require '...' ` で読み込む側はファイルパスを指定
2. 読み込まれる側（`adventure.pl`）で `use Storable qw(dclone);` を**パッケージ内**で行う必要がある
3. 別ファイルから `use GameMemento;` はできない（.pm ファイルが必要）

**適用場面**: 統合版コード（1ファイルに複数パッケージ）作成時は、依存関係の読み込み順序に注意。必要に応じてパッケージを独立ファイルに分割。


## 2026-02-01: タイムトラベル冒険ゲーム（統合記事）

### ワークフロー: series-unified-write

### 知見タイプ: 成功

**コンテキスト**: 全8章（約1200行）の統合版記事を作成。各章に「動く→破綻→完成」の流れを適用。

**知見**: 統合版記事作成のベストプラクティス:
1. 各章の「今回の目標」「今回のポイント」を明確にする
2. Mermaid図を適切に配置（状態遷移図、クラス図、シーケンス図）
3. `> [!TIP]` や `> [!IMPORTANT]` でパターンの本質を強調
4. コードブロックは重要部分のみ抽出し、全体は参照先を示す

**適用場面**: 統合版記事作成時、章構成テンプレートを適用し、図と強調ボックスを効果的に配置。

````

