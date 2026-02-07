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
> **シーンに応じて以下の参照画像を使い分けること:**
> - **キャラクター参照**: `static/public_images/code-doctor/doctor-and-nanako.jpg`（ドクター・ナナコの外見統一用）
> - **クリニック背景参照**: `static/public_images/code-doctor/clinic.jpg`（院内シーンの雰囲気統一用）

### 参照画像の使い分け

| シーン種別 | 使用する参照画像 |
|-----------|----------------|
| 院内シーン（キャラクター有） | `doctor-and-nanako.jpg` + `clinic.jpg` の**両方** |
| 院内シーン（キャラクター無し、ヘッダー等） | `clinic.jpg` のみ |
| 屋外シーン（往診等） | `doctor-and-nanako.jpg` のみ |

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

> [!CAUTION]
> **温度感の統一（必須）**: 同一シーン内でキャラクター間の服装が矛盾してはならない。
> - ❌ NG例: ナナコが半袖なのにドクターがコート → ナナコは寒い、ドクターは暑い
> - ✅ OK例: 院内シーンなら全員軽装（ジャケット＋ナース服）、冬の屋外なら全員コート。

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

## Step 0: 患者イメージの確定（必須）

> [!IMPORTANT]
> **画像生成前に必ず記事本文を読み、患者の特徴を抽出すること。**
> 患者の外見を全シーンで統一するため、以下の項目を確定させる。

### 抽出項目

| 項目 | 抽出元 | 例 |
|------|--------|----|
| **性別** | 一人称（私/僕/俺）、地の文の描写 | 男性 |
| **年齢層** | 職歴、立場の記述 | 30代（基盤チームリーダー） |
| **服装** | 職業、性格、シーン設定 | ビジネスカジュアル（ジャケット＋チノパン） |
| **表情傾向** | 来院理由、性格描写 | 疲弊、真面目、責任感 |
| **特徴的な持ち物** | ストーリー上の小道具 | ラップトップ、技術書 |

### プロファイル作成手順

1. 記事の導入部・来院セクションを読む
2. 患者の一人称、職業、立場を特定
3. 上記テンプレートに従ってプロファイルを作成
4. 全シーンでこのプロファイルを一貫して使用

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
2. **患者の一貫性**: Step 0で確定した患者プロファイルを全シーンで統一使用
3. **服装の温度感統一**: 同一シーン内で「半袖のナナコ」と「コートのドクター」のような矛盾は禁止
4. **テキスト禁止**: 画像内に文字を含めない（AI生成の文字は品質が低い）
5. **WebP推奨**: ファイルサイズ削減のため、最終保存はWebP形式

---

## 完了後

→ `/code-doctor-5-review` へ進む
