---
date: <YYYY-MM-DDTHH:MM:SS+09:00>
description: <記事の要約（120〜160文字）>
draft: true
epoch: <Unix エポック秒>
image: /favicon.png
iso8601: <date と同じ値>
tags:
  - <tag-1>
  - <tag-2>
  - <tag-3>
title: <記事タイトル>
---

[@nqounet](https://x.com/nqounet)です。

<導入文: 記事の背景や目的を簡潔に説明します。>

## <H2 メインセクション1>

<セクションの本文を「です・ます調」で記述します。>

### <H3 サブセクション>

<詳細な説明を記述します。>

箇条書きの例:
- 項目1（だ・である調、末尾に句点なし）
- 項目2
- 項目3

### コード例

```perl
#!/usr/bin/env perl
# 言語: perl
# バージョン: 5.36以上
# 依存: Moo（cpanmでインストール）

use v5.36;
use Moo;

# サンプルコード
say "Hello, World!";
```

## <H2 メインセクション2>

<セクションの本文を記述します。>

### 外部リンクの参照例

参考になるリソースを紹介します。

{{< linkcard "https://www.example.com" >}}

### 書籍の参照例

{{< amazon asin="<ASIN>" title="<書籍のタイトル>" >}}

## まとめ

<記事全体の振り返りや次のステップを記述します。>

---

## テンプレート使用時のチェックリスト

1. [ ] フロントマターの日付が正しいか
2. [ ] タグが英語小文字・ハイフン形式か（例: `design-patterns`）
3. [ ] draft が true になっているか（公開前は true）
4. [ ] 本文が「です・ます調」で統一されているか
5. [ ] 箇条書きが「だ・である調」で末尾に句点がないか
6. [ ] コードブロックに言語タグ・バージョン・依存が明記されているか
7. [ ] 見出しが H2/H3 で適切に構造化されているか
8. [ ] 外部リンクに linkcard ショートコードを使用しているか
9. [ ] 太字（`**text**`）を使用していないか（極力使わない）


---

<このセクションはテンプレートの説明です。実際の記事作成時には削除してください。>

### タグの命名規則

- 英語小文字（例: `perl`, `moo`）
- ハイフン区切り（例: `design-patterns`, `object-oriented`）
- 5個以内を推奨

### よく使うタグ例

- `perl`, `moo`, `mojolicious`
- `design-patterns`, `gof-pattern`
- `tutorial`, `programming`
- `web`, `ai`, `copilot`

### コードブロックの言語タグ例

- `perl`, `bash`, `shell`
- `mermaid`, `yaml`, `json`
- `javascript`, `python`
