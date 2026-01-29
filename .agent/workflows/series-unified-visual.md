---
description: "連載構造案から統合記事を作成する汎用ワークフロー（Phase 5: 挿絵生成）"
---

# Phase 5: 挿絵生成（汎用）

> 前: `/series-unified-write` | 次: `/series-unified-review`

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

`generate_image` ツールを使用して挿絵を生成：

### プロンプトのガイドライン

```
[スタイル]: pixel art / illustration / diagram
[被写体]: 主題を具体的に記述
[雰囲気]: friendly / professional / technical
[背景]: simple / gradient / themed
[注意]: No text in the image
```

### 例

```
A friendly robot butler in pixel art style, wearing a traditional 
butler uniform with a bow tie. Clean design on a light gray background. 
No text in the image.
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

## 完了後

→ `/series-unified-review` へ進む

---

## 注意事項

- 画像生成は時間がかかる場合あり
- 生成画像は `~/.gemini/antigravity/brain/` に一時保存される
- 最終的には `static/public_images/` にコピーする
- 画像ファイル名は小文字・ハイフン区切りを推奨
