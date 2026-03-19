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

## Step 1: スタイルの定義

このワークフローで使用する「雰囲気（スタイル）」を以下で定義します。
新しい雰囲気をその場で作るか、以下のプリセットから選択してください。

### 現在のスタイル設定 (Default)

> **Tech / Modern**:
> `Flat vector illustration, minimalist design, isometric view, cool color palette (blue, cyan, white), clean background, no text`

### その他のスタイル例 (参照用)

| スタイル名 | プロンプト定義 |
|------------|----------------|
| **Warm / Cozy** | `Soft watercolor style, warm lighting, pastel colors, hand-drawn texture, cozy atmosphere` |
| **Cyberpunk** | `Cyberpunk digital art, neon lights, dark background, high contrast, futuristic glitch effects` |
| **Professional** | `Corporate memphis style, flat design, confidence blue and grey, professional vector art` |

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
[スタイル定型文]: Step 1で決めたスタイル定義（例：Flat vector illustration...）
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
cp {GENERATED_IMAGE_PATH} static/public_images/$(date +%Y)/{SLUG}/{IMAGE_NAME}.webp
```

### ディレクトリ構造

```
static/public_images/
└── 2026/
    └── {SLUG}/
        ├── chapter1.webp
        ├── chapter2.webp
        └── ...
```

---



## Step 4: 記事への埋め込み

Markdown形式で画像を埋め込み：

```markdown
![画像の説明](/public_images/2026/{SLUG}/chapter1.webp)
```

### 埋め込み位置

1. **章画像**: 各章のタイトル直後（`---` と `## 第N章` の間）
2. **概念図**: 説明テキストの後

---

## Step 5: 画像の確認

> [!NOTE]
> 画像の表示確認はユーザー側で行います。エージェントはサーバーの起動・ブラウザ確認を行いません。

### チェックリスト（ユーザー確認用）

- [ ] 全画像が正しく表示される
- [ ] 画像の配置が記事の流れに合っている
- [ ] altテキストが適切に設定されている

---

## Step 6: SKRのステータスを更新

挿絵生成が正常に完了したら、SKR上の該当記事のステータスを更新：

```bash
node ~/.agents/skills/semantic-knowledge-repository/scripts/save_knowledge.cjs "series-status-<slug>" '{"facts":["Title: <タイトル>","Structure File: agents/structure/<slug>.md","Visuals: Generated"],"keywords":["status:published","planning-status","<slug>","has-visuals"],"confidence_score":100,"summary":"Published article series with visuals: <タイトル>"}'
```

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

