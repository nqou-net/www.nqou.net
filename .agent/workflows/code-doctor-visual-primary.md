---
description: "コードドクターシリーズ：挿絵生成（Primary — 最重要シーン）"
---

# Code Doctor: Primary Scene Illustration

> **前提**: Phase 4（執筆）完了後に実行
> **対象**: 記事の核心となる最重要シーン **1枚**
> **優先度**: 🔴 Primary（必須）

---

## 概要

記事の中で最もインパクトのあるシーンを1枚生成します。
通常は**診断・処方の核心**に関わる場面です。

### Primary シーンの選定基準

| 基準 | 説明 |
|------|------|
| **物語の転換点** | 診断が下される瞬間、処方が始まる瞬間 |
| **視覚的インパクト** | ドクターが何かを指し示す、コードが映る画面を囲む等 |
| **キャラクター全員登場** | 可能な限りドクター・ナナコ・患者の3人を含む |

---

## Step 1: プリセットの確認

`code-doctor-visual-scene-preset.md` を読み、以下を把握：
- スタイル定義
- 参照画像と選択ルール
- ファイル命名規則
- プロンプト構成テンプレート

---

## Step 2: 記事の読み込みとシーン選定

1. 記事本文を読み、**最も核心的な1シーン** を選定
2. シーンの状況・登場キャラクター・ファイル名を決定：

```
シーン: [状況の簡潔な説明]
登場人物: [ドクター / ナナコ / 患者]
ファイル名: {ケバブケース名}.webp（例: diagnosis-at-monitors.webp）
```

---

## Step 3: プロンプト作成

プリセットのテンプレートに従い、英語プロンプトを作成。

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

---

## 完了後

→ `/code-doctor-visual-secondary` で次の挿絵を生成
→ または `/code-doctor-5-review` へ進む
