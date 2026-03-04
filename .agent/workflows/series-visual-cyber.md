---
description: "連載構造案から統合記事を作成する汎用ワークフロー（Phase 5: 挿絵生成 - Cyberpunk）"
---

# Phase 5: 挿絵生成（Cyberpunk）

> 前: `/series-unified-write` | 次: `/series-unified-review`

---

## Step 1: スタイルの定義

**Style: Cyberpunk**

> [!IMPORTANT]
> **全ての画像生成に以下のスタイル定義を使用すること。**

```
Cyberpunk digital art, neon lights (magenta, cyan), dark background, high contrast, futuristic glitch effects, no text
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
[スタイル定型文]: Step 1で決めたスタイル定義（例：Cyberpunk digital art...）
[制約 (Constraints)]: No text in the image
```

### 実行例

```javascript
// ツールの呼び出し例
generate_image({
  Prompt: "A friendly robot butler in cyberpunk style, neon lights, holding a holographic tablet. Dark background, high contrast. No text in the image.",
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

## Step 7: SKRのステータスを更新

挿絵生成が正常に完了したら、SKR上の該当記事のステータスを更新：

```bash
node ~/.agents/skills/semantic-knowledge-repository/scripts/save_knowledge.cjs "series-status-<slug>" '{"facts":["Title: <タイトル>","Structure File: agents/structure/<slug>.md","Visuals: Generated"],"keywords":["status:published","planning-status","<slug>","has-visuals"],"confidence_score":100,"summary":"Published article series with visuals: <タイトル>"}'
```

