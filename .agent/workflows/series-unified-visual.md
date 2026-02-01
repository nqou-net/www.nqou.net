---
description: "連載構造案から統合記事を作成する汎用ワークフロー（Phase 5: 挿絵生成）"
---

# Phase 5: 挿絵生成（汎用）

> 前: `/series-unified-write` | 次: `/series-unified-review`
> 知見ベース: [workflow-insights.md](../../agents/knowledge/workflow-insights.md)

---

## Step 0: 知見の読み込み

// turbo
1. 知見ファイルの確認:
   ```bash
   grep -A 20 "series-unified-visual" agents/knowledge/workflow-insights.md 2>/dev/null
   ```
2. 関連する知見を抽出し、今回の挿絵生成に活かす
3. 特に「失敗パターン」に注目（画像リサイズの問題など）

---

## 前提条件

以下がPhase 3で完了済み：

- 記事本文の作成
- Mermaid図の埋め込み

---

## Step 1: 挿絵のポイント特定

記事を分析し、挿絵が効果的な箇所を特定：

### 挿絵推奨箇所

| 箇所 | 目的 | 優先度 |
|------|------|--------|
| ヘッダー | 記事の第一印象 | 高 |
| 各章/セクションの先頭 | 内容の視覚的導入 | 中 |
| パターン/概念の説明 | 抽象概念の可視化 | 高 |
| 完成時 | 達成感の演出 | 中 |

---

## Step 2: 画像生成

`generate_image` ツールを使用して挿絵を生成。記事本文のイメージ（メタファー、技術的テーマ、章の要点）を具体的に反映したプロンプトを作成する。

### プロンプト作成のフロー

1.  **文脈の抽出**: その章で語られている主要な概念や使用されているメタファー（例：「執事」「パズル」「宇宙船」など）を特定する。
2.  **要素の構成**: 抽出した文脈を以下のテンプレートに当てはめる。
3.  **英語翻訳**: AIの精度を高めるため、最終的なプロンプトは英語にする。

### プロンプトの構成要素

```
[被写体 (Subject)]: 記事のメタファーやコンセプトを具体的に描写（例：A pixel art butler holding a glowing blueprint）
[スタイル (Style)]: 記事のトーンに合わせる（例：Pixel art, Digital illustration, Oil painting）
[照明・雰囲気 (Lighting/Mood)]: 記事の印象（例：Cyberpunk, Warm lighting, Dynamic shadows）
[構図 (Composition)]: 視覚的な強調（例：Close-up, Wide shot, Minimalist background）
[制約 (Constraints)]: No text in the image
```

### 良い例と悪い例

*   **悪い例**: `ソフトウェアの設計図` (抽象的すぎて一貫性がない)
*   **良い例**: `A detailed technical blueprint of a clockwork mechanism, vintage steampunk style, soft parchment background, high detail, no text.` (記事が「設計」や「メカニズム」を扱っている場合)

### 実行例

```javascript
// ツールの呼び出し例
generate_image({
  Prompt: "A friendly robot butler in pixel art style, wearing a traditional butler uniform and holding a digital tablet displaying code. Clean design on a cool cyan gradient background. No text in the image.",
  ImageName: "butler_implementation"
})
```

---

## Step 3: 画像の配置

生成した画像を静的ファイルディレクトリに配置：

// turbo
```bash
# ディレクトリ作成
mkdir -p static/public_images/$(date +%Y)/{SLUG}

# 画像をコピー（{SOURCE}と{DEST}は実際のパスに置き換え）
cp {GENERATED_IMAGE_PATH} static/public_images/$(date +%Y)/{SLUG}/{IMAGE_NAME}.png
```

### ディレクトリ構造

```
static/public_images/
└── 2026/
    └── {SLUG}/
        ├── header.png
        ├── chapter1.png
        ├── chapter2.png
        └── ...
```

---

## Step 4: 画像のリサイズ（オプション）

大きすぎる画像をリサイズ：

```bash
# sipsを使用（macOS）
sips -Z 640 {IMAGE_PATH} --out {OUTPUT_PATH}

# ImageMagickを使用（クロスプラットフォーム）
convert {IMAGE_PATH} -resize 640x {OUTPUT_PATH}
```

---

## Step 5: 記事への埋め込み

Markdown形式で画像を埋め込み：

```markdown
![画像の説明](/public_images/2026/{SLUG}/header.png)
```

### 埋め込み位置

1. **ヘッダー画像**: frontmatter直後、本文開始前
2. **章画像**: 各章のタイトル直後（`---` と `## 第N章` の間）
3. **概念図**: 説明テキストの後

---

## Step 6: 画像の確認

Hugoサーバーで画像の表示を確認：

// turbo
```bash
hugo server -D -F
# ブラウザで記事を開き、画像の表示を確認
```

### チェックリスト

- [ ] 全画像が正しく表示される
- [ ] 画像サイズが適切（横幅640px以下推奨）
- [ ] 画像の配置が記事の流れに合っている
- [ ] altテキストが適切に設定されている

---

## Step 7: PLANNING_STATUS.md を更新

挿絵生成が正常に完了したら、`PLANNING_STATUS.md` の該当記事の挿絵列を更新：

1. `PLANNING_STATUS.md` を開く
2. 公開済みセクションで該当する記事の行を見つける
3. 挿絵列を「-」から「✓」に更新

### 更新例

**変更前:**
```markdown
| [structure.md](path) | タイトル | 統合版 | 2026-02-01 | - | [記事](/path/) |
```

**変更後:**
```markdown
| [structure.md](path) | タイトル | 統合版 | 2026-02-01 | ✓ | [記事](/path/) |
```

> [!NOTE]
> 挿絵列がないテーブル形式の場合は、この更新をスキップしてください。

---

## 完了後

→ `/series-unified-review` へ進む

---

## 注意事項

- 画像生成は時間がかかる場合あり
- 生成画像は `~/.gemini/antigravity/brain/` に一時保存される
- 最終的には `static/public_images/` にコピーする
- 画像ファイル名は小文字・ハイフン区切りを推奨

---

## Step 8: 知見の記録

今回の挿絵生成で得た気づきを `agents/knowledge/workflow-insights.md` に追記:

```markdown
## YYYY-MM-DD: <コンテンツ名>

### ワークフロー: series-unified-visual

### 知見タイプ: <成功/失敗/発見/フィードバック/改善>

**コンテキスト**: <状況の説明>

**知見**: <学んだこと>

**適用場面**: <今後どんな場面で活用できるか>
```

### 記録すべき典型例

- 画像リサイズツールの選択（sips vs magick）
- 効果的なプロンプトの書き方
- ファイルパーミッションの問題

> [!NOTE]
> 知見がない場合はこのステップをスキップ可能

