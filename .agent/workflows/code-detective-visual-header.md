---
description: "コード探偵シリーズ：扉絵（ヘッダー画像）生成"
---

# Code Detective: Header Image Generation

> **前提**: Phase 3（執筆）完了後に実行
> **対象**: 記事の扉絵となるヘッダー画像のみを生成

---

## スタイルプリセット: Code Detective Series

> [!IMPORTANT]
> **既存3作品のビジュアルを踏襲すること。** テキストプロンプトのみで生成する（参照画像不使用）。

```
View: Isometric (3/4 top-down perspective)
Palette: Dark navy base (#0a1628) with cyan/teal accent glow (#00d4ff, #14b8a6)
Style: Clean linework, flat vector illustration with subtle gradients
Lighting: Monitor glow, neon accent lighting, dim ambient
Atmosphere: Noir × Tech — detective office meets hacker den
Constraints: No text, no logos, no UI elements, square aspect ratio
```

---

## Step 1: 記事・構造案の読み込み

以下を読み、エピソードの核心を把握：

1. **記事本文** (`content/post/YYYY/MM/DD/NNNNNN.md`)
   - タイトル、アンチパターン、デザインパターン
   - ワトソン君のプロファイル（性別、人数、職種）
   - 物語の雰囲気・フック

2. **構造案** (`agents/structure/code-detective-*.md`)（存在する場合）

---

## Step 2: モードの確認（モードB固定）

エピソードの内容にかかわらず、ヘッダー画像は原則 **モードB（パターン概念図）** に統一する。
※生成のたびに事務所（モードA）の家具配置や間取りが変わってしまい、シリーズの連続性を損なうのを防ぐため。

| モード | 説明 | 選択基準 |
|--------|------|----------|
| **B: パターン概念図** | アンチパターン/デザインパターンを象徴的にアイソメトリックで視覚化 | **ヘッダー画像の標準モード**。パターンのメカニズム自体を印象づける |
| (非推奨) A: 事務所シーン | LCI事務所内のアイソメトリック図 | ヘッダー画像としては使用しない（間取りのブレを防ぐため） |

> [!NOTE]
> 常に「ダークネイビー × シアンアクセント」のカラーパレットを使用すること。

---

## Step 3: シーン／概念の設計

### モードA: 事務所シーンの場合

LCI事務所の要素から、エピソードに合ったシーンを設計する。

| 固定要素 | 説明 |
|----------|------|
| **デスク** | 複数モニター、散乱したエナジードリンク缶、キーボード |
| **トレンチコート** | 椅子にかかっている、またはロックが着用 |
| **窓** | 雑居ビルの窓から見える夜の街並み |
| **雰囲気** | 暗い室内にモニターのシアン光が映える |

#### 変動要素（エピソードごとに調整）

- **人物の有無と配置**: 無人、ロックのみ、ワトソン君込み、等
- **モニター表示**: エピソードのアンチパターンを暗示するコード/図
- **小道具**: ワトソン君の特徴を反映した物品（ホワイトボード、書類等）
- **照明色の微調整**: エピソードのトーンに合わせた色温度

### モードB: パターン概念図の場合

アンチパターンとデザインパターンの本質を、象徴的なオブジェクトで表現する。

| 設計要素 | 説明 |
|----------|------|
| **中心オブジェクト** | デザインパターンの核心を象徴する構造物（塔、装置、機械等） |
| **周囲オブジェクト** | パターンの参加者（Observer群、Strategy群等）を表す小型構造物 |
| **破壊/問題の象徴** | アンチパターンの害を視覚化（壊れた鎖、絡まった線、崩壊等） |
| **接続線/信号** | オブジェクト間の関係性を示す光の線や波動 |

---

## Step 4: プロンプト作成

### モードA テンプレート

```
Isometric view of a dimly lit detective office in a run-down building at night.
{事務所内の具体的な描写: モニター、デスク、小道具等},
{人物の配置と行動（存在する場合）},
{エピソード固有のディテール},
scattered energy drink cans, a trench coat draped over the chair,
multiple monitors casting cyan glow on the desk,
dark navy color scheme (#0a1628) with cyan/teal accent lighting (#00d4ff),
clean linework, flat vector illustration style,
noir tech atmosphere, no text in image
```

### モードB テンプレート

```
Isometric view of an abstract technical diagram visualizing {パターン名}.
{中心オブジェクトの描写},
{周囲オブジェクトの描写},
{アンチパターンの問題を象徴する破壊や混沌の描写},
{接続線や信号の描写},
dark navy background (#0a1628) with cyan/teal glowing elements (#00d4ff, #14b8a6),
clean linework, flat vector illustration,
technical noir aesthetic, no text in image
```

---

## Step 5: 画像生成

`generate_image` ツールで画像を生成。

```
generate_image({
  Prompt: [Step 4で作成したプロンプト],
  ImageName: "code-detective-{slug}-header"
})
```

> [!NOTE]
> 参照画像（ImagePaths）は使用しない。テキストプロンプトのみで生成する。

---

## Step 6: 画像の配置

// turbo
```bash
mkdir -p static/public_images/$(date +%Y)/code-detective-{SLUG}

# 生成された画像をコピー
cp {GENERATED_IMAGE_PATH} static/public_images/$(date +%Y)/code-detective-{SLUG}/header.webp
```

### ディレクトリ構造

```
static/public_images/
└── {YYYY}/
    └── code-detective-{slug}/
        └── header.webp
```

---

## Step 7: フロントマターへの設定

記事のフロントマターにヘッダー画像を設定：

```yaml
image: /public_images/{YYYY}/code-detective-{slug}/header.webp
```

---

## Step 8: 確認

// turbo
```bash
hugo server -D -F
# ブラウザで記事を確認
```

### チェックリスト

- [ ] ヘッダー画像が正しく表示される
- [ ] **アイソメトリック構図** になっている
- [ ] **ダークネイビー × シアン** のカラーパレットが守られている
- [ ] コードドクターシリーズの画像と**見分けがつく**（アニメ調ではない）
- [ ] 既存3作品と並べたときに **同じシリーズに見える**
- [ ] 画像内にテキストがない
- [ ] SNSプレビューで正しく表示される

---

## 注意事項

1. **参照画像は使わない**: テキストプロンプトのみで生成し、シリーズの一貫性を保つ
2. **カラーパレット厳守**: ダークネイビー基調 + シアン/ティールのアクセント光
3. **アイソメトリック必須**: 全ヘッダー画像は斜め俯瞰のアイソメトリック構図
4. **テキスト禁止**: 画像内に文字を含めない
5. **WebP推奨**: 新規作成分はWebP形式で保存
6. **正方形アスペクト比**: 既存画像に合わせた正方形構図

---

## 完了後

→ `/series-unified-visual` で本文挿絵を生成
→ または `/series-unified-review` へ進む
