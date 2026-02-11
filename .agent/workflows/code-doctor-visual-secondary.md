---
description: "コードドクターシリーズ：挿絵生成（Secondary — 準重要シーン）"
---

# Code Doctor: Secondary Scene Illustration

> **前提**: Primary シーン生成後に実行
> **対象**: 物語の導入や展開を描く準重要シーン **1枚**
> **優先度**: 🟡 Secondary（推奨）

---

## 概要

物語の流れを補強するシーンを1枚生成します。
通常は**来院・問診・初見** など導入に関わる場面です。

### Secondary シーンの選定基準

| 基準 | 説明 |
|------|------|
| **物語の導入** | 患者が来院する、症状を訴える、初対面の瞬間 |
| **状況の可視化** | 問題のあるコードを前にした困惑の表情、散らかったデスク等 |
| **雰囲気の構築** | クリニックの空気感、深夜のオフィス等 |

---

## Step 1: プリセットの確認

`code-doctor-visual-scene-preset.md` を読み、以下を把握：
- スタイル定義
- 参照画像と選択ルール
- ファイル命名規則
- プロンプト構成テンプレート

---

## Step 2: 記事の読み込みとシーン選定

1. 記事本文を読み、Primary で選んだシーンとは **異なる場面** を選定
2. 導入・展開のシーンからインパクトのある1シーンを決定：

```
シーン: [状況の簡潔な説明]
登場人物: [ドクター / ナナコ / 患者]
ファイル名: {ケバブケース名}.webp（例: patient-arrives-at-clinic.webp）
```

---

## Step 3: プロンプト作成

プリセットのテンプレートに従い、英語プロンプトを作成。
プロンプトはファイルとして保存してください。（agents/code-doctor-series/{slug}/secondary-image-{ケバブケース名}.txt）

### 参照画像の選択

プリセットの「参照画像の選択ルール」に従い、シーンに適した画像を選択。

---

## Step 4: 画像生成

```
generate_image({
  Prompt: [Step 3で作成したプロンプト],
  ImageName: "{slug}-{ケバブケース名}",
  ImagePaths: [選択した参照画像（最大3枚）]
})
```

---

## Step 5: 画像の配置

// turbo
```bash
mkdir -p static/public_images/$(date +%Y)/code-doctor-{SLUG}

# 生成された画像をコピー
cp {GENERATED_IMAGE_PATH} static/public_images/$(date +%Y)/code-doctor-{SLUG}/{ケバブケース名}.webp
```

---

## Step 6: 記事への埋め込み

記事本文の該当箇所に画像リンクを挿入：

```markdown
![シーンの説明（日本語）](/public_images/{YYYY}/code-doctor-{slug}/{ケバブケース名}.webp)
```

---

## Step 7: 確認

// turbo
```bash
hugo server -D -F
```

### チェックリスト

- [ ] 画像が正しく配置・表示されている
- [ ] キャラクターの外見が参照画像と一致している
- [ ] 画像のaltテキストが日本語で記述されている
- [ ] 画像内にテキストがない
- [ ] ファイル名がケバブケースになっている
- [ ] Primary シーンと重複していない

---

## 完了後

→ `/code-doctor-visual-tertiary` で次の挿絵を生成
→ または `/code-doctor-5-review` へ進む
