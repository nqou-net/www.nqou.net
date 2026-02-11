---
description: "コードドクターシリーズ：挿絵スタイルプリセット（共通定義）"
---

# Code Doctor: Scene Style Preset

> **用途**: 各挿絵ワークフロー (`/code-doctor-visual-primary` 等) から参照される共通定義
> **単体実行不可** — このファイルはワークフローではありません

---

## スタイルプリセット

> [!IMPORTANT]
> **全ての挿絵生成に以下のスタイル定義を使用すること。**

```
Style: Anime-inspired illustration with clean linework and soft coloring
Palette: Industrial muted tones (concrete gray, warm wood, cream, navy accents)
Lighting: Scene-appropriate (clinic: fluorescent + monitor glow, outdoor: natural)
Constraints: No text, no logos, no UI elements
```

---

## 参照画像

> [!IMPORTANT]
> **キャラクターを含むシーンでは、必ず該当する参照画像を使用すること。**

| 参照画像 | パス | 使用場面 |
|----------|------|----------|
| **ドクター＆ナナコ（院内）** | `static/public_images/code-doctor/doctor-and-nanako-in-clinic.png` | 院内シーン（ドクター・ナナコ・クリニック背景を含む） |
| **ドクター＆ナナコ（屋外）** | `static/public_images/code-doctor/doctor-and-nanako.jpg` | 屋外シーン（ドクター・ナナコ・背景なし） |
| **クリニック入り口** | `static/public_images/code-doctor/clinic-facade.jpg` | 来院シーン（廊下から見た入り口） |
| **患者** | `agents/code-doctor-series/{slug}/patient.png` | 患者登場シーン |

### 参照画像の選択ルール

| シーン条件 | 使用する参照画像 |
|-----------|----------------|
| ドクター/ナナコ登場 + 院内 | `doctor-and-nanako-in-clinic.png` |
| ドクター/ナナコ登場 + 屋外 | `doctor-and-nanako.jpg` |
| 来院シーン（廊下） | `clinic-facade.jpg` |
| 患者登場 | 上記に加えて `patient.png` |

---

## ファイル命名規則

> [!IMPORTANT]
> **ファイル名は状況を示す英語ケバブケースで命名する。`scene-1` 等の連番は使用しない。**

```
# 良い例
diagnosis-at-monitors.webp
patient-arrives-at-clinic.webp
farewell-note-on-desk.webp
late-night-office-visit.webp

# 悪い例
scene-1.webp
scene-2.webp
```

### ImageName（generate_image 用）

```
{slug}-{ケバブケース名}
# 例: factory-method-diagnosis-at-monitors
```

### 配置先

```
static/public_images/{YYYY}/code-doctor-{slug}/{ケバブケース名}.webp
```

---

## プロンプト構成テンプレート

```
[シーン状況の描写: 場所、時間帯、雰囲気],

[登場キャラクターの描写と行動（参照画像の特徴を明記）],

Style: Anime-inspired illustration with clean linework and soft coloring
Palette: Industrial muted tones (concrete gray, warm wood, cream, navy accents)
Lighting: [シーンに適した照明]
Constraints: No text, no logos, no UI elements
```

---

## 注意事項

1. **参照画像必須**: キャラクター登場時は必ず該当する参照画像を使用
2. **服装の温度感統一**: 同一シーン内でキャラクター間の服装が矛盾しないこと
3. **テキスト禁止**: 画像内に文字を含めない
4. **WebP形式**: 最終保存はWebP形式
5. **generate_image の制約**: 参照画像は最大3枚まで
