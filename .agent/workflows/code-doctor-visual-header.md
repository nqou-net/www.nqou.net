---
description: "コードドクターシリーズ：ヘッダー画像生成"
---

# Code Doctor: Header Image Generation

> **前提**: Phase 4（執筆）完了後に実行
> **対象**: 記事のヘッダー画像（扉絵）のみを生成

---

## 概要

記事の扉絵となるヘッダー画像を生成します。
**症状や処方を抽象化した空間**の中で、登場人物全員（ドクター、ナナコ、患者）がそれぞれの意思で行動しているシーンを描写します。

---

## 参照画像

> [!IMPORTANT]
> **ヘッダー画像は以下の2種類の参照画像を使用して生成すること。**

| 参照画像 | パス |
|----------|------|
| **ドクター＆ナナコ** | `static/public_images/code-doctor/doctor-and-nanako.jpg` |
| **患者** | `agents/code-doctor-series/{slug}/patient.png` |

> [!NOTE]
> 患者画像がない場合は、先に `/code-doctor-1-profile` で生成してください。

---

## スタイルプリセット: Code Doctor Series

### Base Style Definition

```
Style: Anime-inspired illustration with clean linework and soft coloring
Palette: Thematic colors based on symptom/cure metaphor (abstracted, symbolic)
Lighting: Ethereal or conceptual lighting that reinforces the theme
Atmosphere: Abstract symbolic space representing the pattern's essence
Characters: Anime-style figures with natural proportions, each performing distinct actions
Composition: Dynamic scene with characters engaged in purposeful activities
Constraints: No text, no logos, no UI elements, no clinic interior
```

---

## Step 1: プロファイルとプロットの読み込み

以下のファイルを読み、空間とキャラクター行動のコンセプトを把握する：

1. **`agents/code-doctor-series/{slug}/profile.md`**
   - Symptom（症状）: 問題の本質
   - Diagnosis（診断）: メタファー
   - Cure（処方）: 解決策のパターン

2. **`agents/code-doctor-series/{slug}/plot.md`**
   - 物語のトーン
   - 各キャラクターの役割
   - 象徴的なモチーフ

---

## Step 2: 抽象空間の設計

> [!IMPORTANT]
> **クリニックの画像は使用しない。**
> 症状または処方を抽象化した概念空間を設計する。

### 空間設計の指針

| 要素 | 説明 |
|------|------|
| **基盤** | 症状のメタファーを視覚化（例：多重人格→分裂した空間、無限ループ→螺旋構造） |
| **雰囲気** | 処方によって変化する可能性を示唆（希望と問題の共存） |
| **象徴物** | パターンを表すシンボリックなオブジェクト |

---

## Step 3: キャラクター行動の設計

> [!IMPORTANT]
> **各キャラクターは「配置される」のではなく「自分の意思で行動する」こと。**

### キャラクター行動の指針

| キャラクター | 役割 | 行動の方向性 |
|--------------|------|--------------|
| **ドクター** | 静かなる解決者 | 抽象空間内の「核心」に向かって何かを操作している、観察している、または指し示している |
| **ナナコ** | 橋渡し役・翻訳者 | 患者をサポートする、ドクターの意図を伝える仕草、または空間の一部を整理している |
| **患者** | 変化の主体 | 問題と向き合っている、発見している、または解決に向けて一歩踏み出している |

### 行動例（参考）

```
# 例：Singleton（多重人格症候群）の場合
- 空間：分裂した鏡の断片が浮遊する抽象空間、中央に一つの光源
- ドクター：光源（Single Source of Truth）の方向を無言で指している
- ナナコ：浮遊する鏡の破片を一つにまとめようとしている
- 患者：自分の複数の影（多重人格）を見て戸惑いながらも、光の方向に目を向けている
```

---

## Step 4: プロンプト作成

### プロンプト構造

```
[Abstract symbolic space: {症状/処方を表す抽象空間の描写}],

Doctor (black hair, dark jacket): {ドクターの具体的な行動},
Nanako (brown bob hair, white nurse uniform with navy trim): {ナナコの具体的な行動},
Patient (based on patient.png reference - {患者の特徴}): {患者の具体的な行動},

Each character acting with purpose and intention,
Anime-inspired illustration with clean linework,
{空間に合わせた色調パレット},
ethereal/conceptual lighting,
dynamic composition with characters in motion,
no text in image, no clinic interior
```

---

## Step 5: 画像生成

`generate_image` ツールで画像を生成。

### 実行パラメータ

```
ImageName: {slug}-header
ImagePaths: [
  "static/public_images/code-doctor/doctor-and-nanako.jpg",
  "agents/code-doctor-series/{slug}/patient.png"
]
Prompt: [Step 4で作成したプロンプト]
```

---

## Step 6: 画像の配置

### ディレクトリ構造

```
static/public_images/
└── {YYYY}/
    └── code-doctor-{slug}/
        └── header.webp
```

### 配置コマンド

// turbo
```bash
mkdir -p static/public_images/$(date +%Y)/code-doctor-{SLUG}

# 生成された画像をコピー（パスは実際のものに置換）
cp {GENERATED_IMAGE_PATH} static/public_images/$(date +%Y)/code-doctor-{SLUG}/header.webp
```

---

## Step 7: 記事への設定

記事のフロントマターにヘッダー画像を設定：

```yaml
image: /public_images/{YYYY}/code-doctor-{slug}/header.webp
```

---

## Step 8: 確認

// turbo
```bash
hugo server -D -F
# ブラウザで記事を確認
```

### チェックリスト

- [ ] ヘッダー画像がSNSプレビューで正しく表示される
- [ ] ドクター、ナナコ、患者の3人が全員写っている
- [ ] **各キャラクターが自分の意思で行動している**
- [ ] **抽象化された空間が症状/処方を象徴している**
- [ ] キャラクターの外見が参照画像と一致している
- [ ] 画像内にテキストがない
- [ ] **クリニック内部が描かれていない**

---

## 注意事項

1. **3人全員必須**: ヘッダー画像には必ずドクター、ナナコ、患者の3人を含める
2. **参照画像2枚**: `doctor-and-nanako.jpg` + `patient.png` を使用（clinic.jpgは使用しない）
3. **抽象空間**: クリニックではなく、症状/処方を象徴する概念空間で描写
4. **キャラクター行動**: 各キャラクターは静止ポーズではなく、意思ある行動をとる
5. **テキスト禁止**: 画像内に文字を含めない
6. **WebP推奨**: ファイルサイズ削減のため、最終保存はWebP形式

---

## 完了後

→ `/code-doctor-visual-scene` で本文挿絵を生成（別ワークフロー）
→ または `/code-doctor-5-review` へ進む
