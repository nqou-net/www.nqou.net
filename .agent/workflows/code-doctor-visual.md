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
> **キャラクター（ドクター、ナナコ）が登場する画像には、必ず参照画像 `static/public_images/2026/clinic-and-docktor-and-nanako.jpg` を使用すること。**

### Base Style Definition

```
Style: Anime-inspired illustration with clean linework and soft coloring
Palette: Industrial muted tones (concrete gray, warm wood, cream, navy accents, cool blue monitors)
Lighting: Fluorescent overhead lights mixed with monitor glow, indoor basement atmosphere
Atmosphere: Compact underground clinic with tech-forward aesthetic, exposed pipes and certificates on concrete walls
Setting: Small basement-style clinic with 3 monitors on wooden desk, metal filing cabinets, bookshelf, examination bed
Characters: Anime-style figures with natural proportions, expressive but not exaggerated
Composition: Detailed background with focus on character interaction
Constraints: No text, no logos, no UI elements
```

### キャラクター描写ガイド

> [!NOTE]
> ドクターとナナコの外見は参照画像を基準とし、服装のみシーンに合わせて調整する。
> **季節・場所に応じた服装**: 真冬の屋外シーンでは半袖NG、コート着用など常識的な服装とすること。

| キャラクター | 固定の視覚的特徴 | 服装（基本/調整可） |
|-------------|-----------------|-------------------|
| **ドクター** | 黒髪短髪、眼鏡なし、真剣な表情、無愛想だが有能な雰囲気 | 基本: 黒/ダークグレーのジャケット。冬の屋外: コート追加。診察中: そのままでOK |
| **ナナコ（助手）** | 茶髪ショートボブ（肩につかない長さ）、優しい笑顔、タブレット端末を持つことが多い | 基本: 白ナース服（紺トリム）+ 紺パンツ。冬の屋外: カーディガンやコート追加 |
| **患者** | カジュアル服、困惑やほっとした表情（記事により変化） | シーンに応じて自由に設定 |

#### 服装調整の例

| シーン | ドクター | ナナコ |
|--------|---------|--------|
| 院内（通常） | 黒ジャケット | 白ナース服 + 紺パンツ |
| 往診（春〜秋） | 黒ジャケット + 医療バッグ | 白ナース服 + カーディガン |
| 往診（真冬） | ダークコート + マフラー | コート + 暖かい服装 |
| 緊急対応 | ジャケットのまま | 同上 |

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
Anime-inspired illustration with clean linework, industrial muted tones (concrete gray, warm wood, navy accents),
fluorescent lighting mixed with monitor glow, compact underground clinic aesthetic,
exposed pipes on walls, anime-style figures with natural proportions, no text in image
```

### 具体例

#### ヘッダー画像（Factory Method の例）

```
A vintage factory machine with colorful product shapes emerging from assembly line,
Anime-inspired illustration style, industrial muted color palette (gray, wood tones, navy),
cool blue accent lighting, clean composition, no characters, industrial-medical atmosphere,
no text in image
```

#### 来院シーン

```
A confused programmer entering a compact basement clinic, greeted by a cheerful assistant with short brown bob hair holding tablet in white nurse uniform with navy trim, while a stern-looking doctor with short black hair in dark jacket sits at triple-monitor desk,
Anime-inspired illustration, industrial muted tones, fluorescent overhead lighting,
concrete walls with certificates, anime-style figures, no text in image
```

#### 診断シーン

```
A doctor with short black hair in dark jacket pointing at code diagram on one of three monitors while nurse assistant with brown bob hair explains to worried patient,
Anime-inspired illustration, industrial muted tones, monitor glow lighting,
basement clinic interior with exposed pipes, anime-style figures, no text in image
```

#### 退院シーン

```
A relieved patient receiving advice from smiling nurse assistant with brown bob hair in white uniform while doctor with black hair nods approvingly at desk,
Anime-inspired illustration, industrial muted tones, warm fluorescent lighting,
compact basement clinic atmosphere, anime-style figures, no text in image
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
  Prompt: "A confused programmer entering a compact basement clinic...[full prompt]...",
  ImageName: "factory_method_scene_1",
  ImagePaths: ["/Users/nobu/local/src/github.com/nqou-net/www.nqou.net/static/public_images/2026/clinic-and-docktor-and-nanako.jpg"]
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
