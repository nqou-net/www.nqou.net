---
description: "コードドクターシリーズ：挿絵生成 (オプショナル)"
---

# Code Doctor: Visual Enhancement

> **前提**: Phase 4（執筆）完了後に実行
> **スキップ条件**: ユーザー指示に `挿絵: なし` がある場合はこのフェーズをスキップ

---

## 概要

記事にヘッダー画像 + 本文挿絵3枚を追加します。
シリーズ全体で統一された世界観を保つため、**スタイルプリセット**を使用します。

---

## スタイルプリセット: Code Doctor Series

> [!IMPORTANT]
> **全ての画像生成に以下のベーススタイルを適用すること。**

### Base Style Definition

```
Style: Soft watercolor illustration with gentle textures
Palette: Muted medical tones (sage green, cream, dusty rose, pale blue)
Lighting: Warm, diffused, like morning light in a clinic
Atmosphere: Professional yet cozy, like a small-town doctor's office
Characters: Simple anime-inspired figures, minimal facial details
Composition: Clean, uncluttered, focus on central subject
Constraints: No text, no logos, no UI elements
```

### キャラクター描写ガイド

| キャラクター | 視覚的特徴 |
|-------------|-----------|
| **ドクター** | 白衣、眼鏡なし、短髪（黒）、無表情、腕組み姿勢が多い |
| **ナナコ（助手）** | ナース服（クリーム色）、ポニーテール（茶）、笑顔、クリップボード |
| **患者** | カジュアル服、困惑やほっとした表情（記事により変化） |

---

## Step 1: 画像構成の決定

### 必須画像（4枚）

| # | 用途 | 配置場所 | 内容ガイド |
|---|------|---------|-----------|
| 1 | **ヘッダー画像** | フロントマター `image:` | パターンの象徴的シーン（道具、診療風景など） |
| 2 | **導入（来院/往診）** | 第1章直後 | 患者とドクター・助手の出会い |
| 3 | **診断/処置** | 第2〜3章境界 | ドクターが問題を指摘、助手が説明する場面 |
| 4 | **退院/予後** | 記事末尾付近 | 解決後の安堵感、別れの場面 |

---

## Step 2: プロンプト作成

### プロンプトテンプレート

```
[Scene Description], [Character Action/Pose],
Soft watercolor illustration style, muted medical color palette (sage green, cream, dusty rose),
warm diffused lighting, clean composition, cozy clinic atmosphere,
anime-inspired simple figures, no text in image
```

### 具体例

#### ヘッダー画像（Factory Method の例）

```
A vintage factory machine with colorful product shapes emerging from assembly line,
Soft watercolor illustration style, muted medical color palette (sage green, cream, dusty rose),
warm diffused lighting, clean composition, no characters, symbolic medical-industrial atmosphere,
no text in image
```

#### 来院シーン

```
A confused programmer entering a small cozy clinic, greeted by a cheerful nurse with ponytail and a stern doctor in white coat crossing arms,
Soft watercolor illustration style, muted medical tones, warm morning light,
anime-inspired simple figures, no text in image
```

#### 診断シーン

```
A doctor pointing at a tangled spaghetti-like code diagram on whiteboard while nurse explains to worried patient,
Soft watercolor illustration style, muted medical color palette,
warm diffused lighting, clinic interior, anime-inspired figures, no text in image
```

#### 退院シーン

```
A relieved patient receiving a prescription note from smiling nurse while doctor nods in background,
Soft watercolor illustration style, muted medical tones, warm afternoon light,
cozy clinic atmosphere, anime-inspired figures, no text in image
```

---

## Step 3: 画像生成

`generate_image` ツールで各画像を生成。

### 命名規則

```
{slug}-header.png      # ヘッダー画像
{slug}-scene-1.png     # 導入シーン
{slug}-scene-2.png     # 診断/処置シーン
{slug}-scene-3.png     # 退院シーン
```

### 実行例

```javascript
generate_image({
  Prompt: "A confused programmer entering a small cozy clinic...[full prompt]...",
  ImageName: "factory_method_scene_1"
})
```

---

## Step 4: 画像の配置

### ディレクトリ構造

```
static/public_images/
└── {YYYY}/
    └── code-doctor-{slug}/
        ├── header.webp
        ├── scene-1.webp
        ├── scene-2.webp
        └── scene-3.webp
```

### 配置コマンド

// turbo
```bash
mkdir -p static/public_images/$(date +%Y)/code-doctor-{SLUG}

# 生成された画像をコピー（パスは実際のものに置換）
cp {GENERATED_IMAGE_PATH} static/public_images/$(date +%Y)/code-doctor-{SLUG}/{IMAGE_NAME}.webp
```

---

## Step 5: 記事への埋め込み

### フロントマターのheader画像

```yaml
---
title: "コードドクター【Factory Method】..."
image: /public_images/2026/code-doctor-factory-method/header.webp
---
```

### 本文中の挿絵

```markdown
## 来院

![患者がコード診療所を訪れる様子](/public_images/2026/code-doctor-factory-method/scene-1.webp)

僕は恐る恐る、その小さな診療所のドアを開けた...
```

### 埋め込み位置ガイド

| 画像 | 推奨位置 |
|------|---------|
| scene-1 | 第1章（来院/往診）の見出し直後 |
| scene-2 | 第2〜3章（診断/処置）の境界 |
| scene-3 | 第4章（退院/予後）の冒頭または末尾 |

---

## Step 6: 確認

// turbo
```bash
hugo server -D -F
# ブラウザで記事を確認
```

### チェックリスト

- [ ] ヘッダー画像がSNSプレビューで表示される
- [ ] 本文挿絵3枚が正しく配置されている
- [ ] 画像のaltテキストが日本語で記述されている
- [ ] 全画像が統一されたスタイル（水彩調）になっている

---

## 注意事項

1. **一貫性優先**: 個別の「創造的な」スタイル変更より、シリーズ統一感を重視
2. **キャラクター固定**: ドクターとナナコの外見は常に同じ描写を使用
3. **テキスト禁止**: 画像内に文字を含めない（AI生成の文字は品質が低い）
4. **WebP推奨**: ファイルサイズ削減のため、最終保存はWebP形式

---

## 完了後

→ `/code-doctor-5-review` へ進む
