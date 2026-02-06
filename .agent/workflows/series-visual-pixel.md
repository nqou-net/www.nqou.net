---
description: "連載構造案から統合記事を作成する汎用ワークフロー（Phase 5: 挿絵生成 - Pixel Art）"
---

# Phase 5: 挿絵生成（Pixel Art）

> 前: `/series-unified-write` | 次: `/series-unified-review`

---

## Step 1: スタイルの定義

**Style: Pixel Art**

> [!IMPORTANT]
> **全ての画像生成に以下のスタイル定義を使用すること。**

```
16-bit pixel art style, retro game atmosphere, vivid colors, dithering, detailed sprite work, no text
```

---

## Step 2: 画像のポイント特定

記事を分析し、挿絵が効果的な箇所を特定：

### 挿絵推奨箇所

| 箇所 | 目的 | 優先度 |
|------|------|--------|
| 各章/セクションの先頭 | 内容の視覚的導入 | 中 |
| パターン/概念の説明 | 抽象概念の可視化 | 高 |
| 完成時 | 達成感の演出 | 中 |

---

## Step 3: 画像生成

Step 1で定義したスタイルと、記事の内容を組み合わせて画像を生成します。

### プロンプト作成のフロー

1.  **文脈の抽出**: その章で語られている主要な概念やメタファーを特定する。
2.  **スタイルの適用**: Step 1の「スタイル定義」をプロンプトの末尾に追加する。
3.  **英語翻訳**: 最終的なプロンプトは英語にする。

### プロンプトの構成要素

```
[被写体 (Subject)]: 記事の具体的なシーン（例：A robot butler holding a blueprint）
[スタイル定型文]: Step 1で決めたスタイル定義（例：16-bit pixel art style...）
[制約 (Constraints)]: No text in the image
```

### 実行例

```javascript
// ツールの呼び出し例
generate_image({
  Prompt: "A friendly robot butler in 16-bit pixel art style, holding a scroll. Vivid colors, retro game atmosphere. No text in the image.",
  ImageName: "butler_implementation"
})
```

---

## Step 4: 画像の配置

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
        ├── chapter1.png
        ├── chapter2.png
        └── ...
```

---

## Step 5: 記事への埋め込み

Markdown形式で画像を埋め込み：

```markdown
![画像の説明](/public_images/2026/{SLUG}/chapter1.png)
```

### 埋め込み位置

1. **章画像**: 各章のタイトル直後（`---` と `## 第N章` の間）
2. **概念図**: 説明テキストの後

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
