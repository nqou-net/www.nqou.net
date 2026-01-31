---
description: "記事ファイルのパスを渡すと、その記事を分析して効果的な挿絵を画像生成して埋め込むワークフロー"
---

# 記事の挿絵生成ワークフロー (Key Illustrations)

指定された記事ファイルを分析し、効果的な挿絵を生成して埋め込みます。

## 前提条件

- 対象の記事ファイルパスが指定されていること（またはアクティブなファイル）

---

## Step 1: 記事の分析とポイント特定

対象の記事ファイルを読み込み、挿絵が効果的な箇所を特定します。

> [!NOTE]
> ユーザーからファイルパスが渡されていない場合は、現在アクティブなファイルを使用するか、ユーザーにパスを問い合わせてください。

1. `read_file` などのツールで記事の内容を読み込む。
2. 以下の基準で挿絵を入れるべき箇所をリストアップする。

### 挿絵推奨箇所

| 箇所 | 目的 | 優先度 |
|------|------|--------|
| ヘッダー | 記事の第一印象（アイキャッチ） | 高 |
| 各章/セクションの先頭 | 内容の視覚的導入 | 中 |
| パターン/概念の説明 | 抽象概念の可視化 | 高 |
| まとめ/結論 | 読後感の演出 | 低 |

---

## Step 2: 画像生成

`generate_image` ツールを使用して挿絵を生成します。記事本文のメタファーやテーマを具体的に反映したプロンプトを作成してください。

### プロンプト作成フロー

1.  **文脈の抽出**: そのセクションの主要な概念やメタファー（例：「執事」「パズル」「宇宙船」など）を特定。
2.  **要素の構成**: 以下のテンプレートに当てはめる。
3.  **英語翻訳**: プロンプトは英語で作成する。

### プロンプトテンプレート

```
[Subject]: 記事のメタファーやコンセプトを具体的に描写（例：A pixel art butler holding a glowing blueprint）
[Style]: 記事のトーンに合わせる（例：Pixel art, Digital illustration, Oil painting）
[Lighting/Mood]: 記事の印象（例：Cyberpunk, Warm lighting, Dynamic shadows）
[Composition]: 視覚的な強調（例：Close-up, Wide shot, Minimalist background）
[Constraints]: No text in the image, Aspect Ratio 16:9
```

### 実行例

```javascript
generate_image({
  Prompt: "A friendly robot butler in pixel art style, wearing a traditional butler uniform and holding a digital tablet displaying code. Clean design on a cool cyan gradient background. No text in the image.",
  ImageName: "butler_implementation"
})
```

---

## Step 3: 画像の配置

生成した画像をプロジェクトの静的ファイルディレクトリに移動します。

1. 記事のパスや日付から、適切な公開用ディレクトリを決定する。
   - 例: `static/public_images/YYYY/MM/` や `static/public_images/YYYY/{SLUG}/`
2. ディレクトリが存在しない場合は作成する。
3. 生成された画像を移動する。

// turbo
```bash
# 例: 日付ディレクトリへの移動
# 記事の日付やスラッグに合わせて変更してください
mkdir -p static/public_images/$(date +%Y)/{SLUG}
cp {GENERATED_IMAGE_PATH} static/public_images/$(date +%Y)/{SLUG}/{IMAGE_NAME}.png
```

---

## Step 4: 画像のリサイズ（推奨）

Web表示用に画像を最適化します。

```bash
# sipsを使用（macOS）
sips -Z 640 {IMAGE_PATH} --out {OUTPUT_PATH}
```

---

## Step 5: 記事への埋め込み

マークダウンファイルに画像リンクを追記します。

```markdown
![画像の説明](/public_images/YYYY/{SLUG}/{IMAGE_NAME}.png)
```

### 埋め込み位置の目安
- **ヘッダー**: Frontmatterの直後
- **章の先頭**: 見出し（`##`）の直後
- **説明図**: 該当する段落の後

---

## Step 6: 検証

Hugoサーバーなどで表示を確認し、問題がないかチェックします。

### チェックリスト
- [ ] 画像が正しく表示されているか
- [ ] コンテキストに合った画像か
- [ ] サイズが適切か
