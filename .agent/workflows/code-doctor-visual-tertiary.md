---
description: "コードドクターシリーズ：挿絵生成（Tertiary — 補助シーン）"
---

# Code Doctor: Tertiary Scene Illustration

> **前提**: Secondary シーン生成後に実行
> **対象**: 余韻やエピローグを描く補助シーン **1枚**
> **優先度**: 🟢 Tertiary（任意）

---

## 概要

物語の余韻を残すシーンを1枚生成します。
通常は**術後経過・エピローグ・別れの場面** など結末に関わるシーンです。

### Tertiary シーンの選定基準

| 基準 | 説明 |
|------|------|
| **物語の結末** | 別れの挨拶、ドクターが去っていく、メモを残す |
| **変化の可視化** | 整理されたコード、安堵の表情、明るくなった空間 |
| **余韻の演出** | 振り返るナナコ、閉じられるドア、窓からの光 |

---

## Step 1: プリセットの確認

`code-doctor-visual-scene-preset.md` を読み、以下を把握：
- スタイル定義
- 参照画像と選択ルール
- ファイル命名規則
- プロンプト構成テンプレート

---

## Step 2: 記事の読み込みとシーン選定

1. 記事本文を読み、Primary・Secondary とは **異なる場面** を選定
2. 結末・余韻のシーンからインパクトのある1シーンを決定：

```
シーン: [状況の簡潔な説明]
登場人物: [ドクター / ナナコ / 患者]
ファイル名: {ケバブケース名}.webp（例: farewell-note-on-desk.webp）
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
- [ ] Primary・Secondary シーンと重複していない

---

## 完了後

→ `/code-doctor-5-review` へ進む
