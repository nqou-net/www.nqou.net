---
description: 連載構造案から1つの統合記事を作成するワークフロー（複数回の連載を1記事に統合）
---

# 連載構造案から統合記事を作成するワークフロー

> 参照: 汎用フェーズワークフロー `/series-unified-*`

---

## 概要

任意の連載構造案（全N回）を、1つの長編記事として統合するワークフロー。

- 連載の各回は「章」として構成
- 1章あたり1つの概念を導入（1記事1概念の原則を継承）
- ストーリー構成: 動く→破綻→パターン導入→完成

---

## Step 1: 構造案の指定

ユーザーに以下を確認：

1. **構造案ファイルパス**:
   ```
   agents/structure/<slug>.md
   ```
   例:
   - `agents/structure/hands-on-design-patterns-series-structure.md`
   - `agents/structure/oop-fp-hybrid-series-structure.md`

2. **利用可能な構造案を確認**:
   // turbo
   ```bash
   ls -la agents/structure/
   ```

---

## Step 2: 構造案の読み込み

構造案ファイルを読み込み、以下を確認：

1. シリーズ名・タイトル
2. 推薦案（案A/B/Cなど）
3. 連載構造表:
   - 回数、タイトル、新概念、ストーリー、コード例
4. 技術スタック、対象読者

---

## Step 3: 採用案の確認

構造案に複数の案がある場合：

1. 推薦順位を提示
2. ユーザーに採用案を確認
3. 技術スタック・依存関係を確認

---

## Step 4: フェーズ実行

以下のフェーズを順次実行：

| Phase | ワークフロー | 内容 |
|-------|-------------|------|
| 1 | `/series-unified-prepare` | 準備・公開日時決定 |
| 2 | `/series-unified-code` | コード実装・テスト |
| 3 | `/series-unified-write` | 原稿作成 |
| 5 | `/series-unified-visual` | 挿絵・Mermaid図 |
| 6 | `/series-unified-review` | レビュー・最終確認 |

→ `/series-unified-prepare` へ進む

---

## フェーズ詳細

### Phase 1: 準備（`/series-unified-prepare`）

- 構造案の読み込み・確認
- 採用案の決定
- 公開日時の決定
- 技術スタックの確認

### Phase 2: コード実装（`/series-unified-code`）

- テストディレクトリ作成
- 全コード例を先に実装
- テスト実行・警告なし確認
- 原稿作成前に全コードの動作を保証

### Phase 3: 原稿作成（`/series-unified-write`）

- N回分をN章構成の1記事に統合
- 章間の接続を滑らかに
- 導入部・まとめ章を追加

### Phase 5: 挿絵・図（`/series-unified-visual`）

- アイキャッチ画像を生成
- Mermaid図を追加
- 画像を記事に埋め込み

### Phase 6: レビュー（`/series-unified-review`）

- コード検証・記事との一致確認
- 構造・文体チェック
- frontmatter確認
- 最終ビジュアル確認

---

## 出力ファイル

| 種類 | 場所 |
|------|------|
| 記事 | `content/post/%Y/%m/%d/*.md` |
| コード | `agents/tests/<slug>/` |
| 画像 | `static/public_images/%Y/<slug>/` |

---

## シリーズ固有ショートカット

特定の構造案に対しては、パラメータを固定したショートカットワークフローを使用可能：

| ワークフロー | 構造案 |
|-------------|--------|
| `/hands-on-design-patterns` | デザインパターン実践 |
| `/oop-fp-hybrid` | OOP-FPハイブリッド設計 |

---

## チェックリスト

- [ ] 構造案ファイルを指定した
- [ ] 採用案を決定した
- [ ] 全フェーズを実行した
- [ ] コード検証に合格した
- [ ] レビューを完了した
