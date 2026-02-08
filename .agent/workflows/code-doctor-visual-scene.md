---
description: "コードドクターシリーズ：本文挿絵生成"
---

# Code Doctor: Scene Illustrations

> **前提**: Phase 4（執筆）完了後に実行
> **対象**: 本文に挿入する挿絵（3枚程度）

---

## 概要

記事本文に挿入する挿絵を生成します。
ストーリーの流れに沿った場面を視覚化し、読者の没入感を高めます。

---

## 参照画像

> [!IMPORTANT]
> **キャラクターを含むシーンでは、必ず該当する参照画像を使用すること。**

| 参照画像 | パス | 使用場面 |
|----------|------|----------|
| **ドクター＆ナナコ** | `static/public_images/code-doctor/doctor-and-nanako.jpg` | 院内・屋外問わず |
| **クリニック背景** | `static/public_images/code-doctor/clinic.jpg` | 院内シーン |
| **クリニック入り口** | `static/public_images/code-doctor/clinic-facade.jpg` | 来院シーン（廊下から見た入り口） |
| **患者** | `agents/code-doctor-series/{slug}/patient.png` | 患者登場シーン |

---

## スタイルプリセット

```
Style: Anime-inspired illustration with clean linework and soft coloring
Palette: Industrial muted tones (concrete gray, warm wood, cream, navy accents)
Lighting: Scene-appropriate (clinic: fluorescent + monitor glow, outdoor: natural)
Constraints: No text, no logos, no UI elements
```

---

## Step 1: 記事の読み込みと埋め込み位置の決定

1. 記事本文を読み、挿絵を入れるべき箇所を判断
2. 挿絵の枚数と各シーンの内容を決定
3. 記事内にプレースホルダーを配置：

```markdown
![シーン1の説明](/public_images/{YYYY}/code-doctor-{slug}/scene-1.webp)
```

---

## Step 2: 各シーンのプロンプト作成

シーンごとに登場キャラクターと状況を特定し、プロンプトを作成。

### 参照画像の選択

| シーン条件 | 使用する参照画像 |
|-----------|----------------|
| ドクター/ナナコ登場 + 院内 | `doctor-and-nanako.jpg` + `clinic.jpg` |
| ドクター/ナナコ登場 + 屋外 | `doctor-and-nanako.jpg` のみ |
| 来院シーン（廊下） | `clinic-facade.jpg` |
| 患者登場 | 上記に加えて `patient.png` |

---

## Step 3: 画像生成

`generate_image` ツールで各シーンを生成。

### 命名規則

```
{slug}-scene-{N}.png     # N は連番（1, 2, 3...）
```

---

## Step 4: 画像の配置

// turbo
```bash
mkdir -p static/public_images/$(date +%Y)/code-doctor-{SLUG}

# 生成された画像をコピー
cp {GENERATED_IMAGE_PATH} static/public_images/$(date +%Y)/code-doctor-{SLUG}/scene-{N}.webp
```

---

## Step 5: 確認

// turbo
```bash
hugo server -D -F
```

### チェックリスト

- [ ] 本文挿絵が正しく配置されている
- [ ] キャラクターの外見が参照画像と一致している
- [ ] 画像のaltテキストが日本語で記述されている
- [ ] 画像内にテキストがない

---

## 注意事項

1. **参照画像必須**: キャラクター登場時は必ず該当する参照画像を使用
2. **服装の温度感統一**: 同一シーン内でキャラクター間の服装が矛盾しないこと
3. **テキスト禁止**: 画像内に文字を含めない
4. **WebP推奨**: 最終保存はWebP形式

---

## 完了後

→ `/code-doctor-5-review` へ進む
