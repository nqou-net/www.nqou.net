---
description: 記事の要所（章の最初や転換点）に挿絵を生成・追加するワークフロー
---

# 記事挿絵生成 (Key Illustrations)

> 対象: シリーズ記事、単体記事
> 目的: 記事の要所（章の冒頭、転換点など）を視覚化し、読者の理解を助ける

---

## Step 1: 対象とポイントの特定

1. **対象記事の特定**:
   - 編集中の Markdown ファイル (`content/post/...`) を確認
   - 記事の年号 (`%Y`) とスラッグ (`<series-slug>` または `<article-slug>`) を特定

2. **挿絵ポイントの抽出**:
   - 記事を読み、以下のタイミングを特定する:
     - 章（見出し）の直後
     - 話の転換点（「しかし」「ここで登場するのが」など）
     - 複雑な概念の説明が必要な箇所
   - 具体例:
     - **Before**: 問題が山積している混沌とした状況
     - **Concept**: パターン構造図、クラス図、フローチャート
     - **After**: 完成イメージ、整然としたコードの世界

3. **トピック名 (<topic>) の決定**:
   - 各ポイントの内容を表す短い英数字 (kebab-case)
   - 例: `problem-chaos`, `mediator-pattern`, `final-architecture`

---

## Step 2: 画像生成 (Generate)

1. **`generate_image` ツールを実行**:
   - `Prompt`: 記事の文脈を反映し、具体的かつ魅力的な指示を与える。
     - *Style*: 記事のトーンに合わせる（テクニカル、親しみやすい、RPG風など）
     - *Content*: 抽象的すぎず、何が描かれているか伝わるようにする
   - `ImageName`: `<series-slug>-<topic>` (一時保存用)

2. **生成画像の確認**:
   - Artifact として保存された画像を確認し、必要であればリテイク（再生成）

---

## Step 3: 配置と埋め込み (Deploy)

1. **保存ディレクトリの準備**:
   - `static/public_images/%Y/` (記事の公開年)
   - 存在しない場合は作成 (`mkdir -p`)

2. **ファイルの移動**:
   - リサイズ (推奨: 長辺640px, JPEG):
     - `sips -Z 640 -s format jpeg <artifact_path>` (macOS)
     - 大きすぎる画像は記事の読み込みを遅くするため、適切なサイズに調整する。

   - 生成された Artifact 画像を保存先へ移動
   - 命名規則: `static/public_images/%Y/<series-slug>-<topic>.jpg`
   - コマンド例: `mv <artifact_path> static/public_images/2026/<series-slug>-<topic>.jpg`

3. **記事への埋め込み**:
   - Markdown ファイルの該当箇所（Step 1 で特定したポイント）に画像リンクを追加
   - 書式:
     ```markdown
     ![<Alt Text>](/public_images/%Y/<series-slug>-<topic>.jpg)
     ```
   - `<Alt Text>` には画像の内容や、記事内での役割（「図1: パターン構造」など）を記述

---

## Step 4: 最終確認

1. **プレビュー確認**:
   - 生成された画像が記事の文脈と合致しているか
   - 画像リンクが正しく機能しているか（パス間違いがないか）
