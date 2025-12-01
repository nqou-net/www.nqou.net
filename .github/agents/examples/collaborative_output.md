# 協力型記事作成の出力例

このファイルは、専門家エージェントとblog-writerエージェントが協力して
ブログ記事を作成する過程を示す例です。

---

## ステップ1: 専門家（ruby-specialist）の原稿

### テーマ
Rubyのブロックとプロック（Proc）の違い

### 専門家による原稿（技術的に正確だが編集前）

```markdown
# ブロックとProcの違い

## ブロック

ブロックはRubyの重要な機能です。

```ruby
[1, 2, 3].each do |n|
  puts n
end
```

`do...end` または `{...}` で記述します。

## Proc

Procはブロックをオブジェクト化したものです。

```ruby
my_proc = Proc.new { |n| puts n }
my_proc.call(5)  # => 5
```

変数に代入できます。

## Lambda

Lambdaは厳密な引数チェックを行うProcです。

```ruby
my_lambda = lambda { |n| puts n }
my_lambda.call(5)  # => 5
```

引数の数が合わないとエラーになります。

## 違い

| 特徴 | Proc | Lambda |
|------|------|--------|
| 引数チェック | 緩い | 厳密 |
| return動作 | メソッドから抜ける | Procから抜ける |

## まとめ

用途によって使い分けます。

## バージョン情報

Ruby 2.7+で検証済み
```

---

## ステップ2: blog-writerによる編集後

### 編集後のブログ記事（読みやすく構成された完成形）

```markdown
---
title: "Rubyのブロック、Proc、Lambdaの違いを理解しよう"
description: "Rubyの重要な機能であるブロック、Proc、Lambdaの違いと使い分けを、実例を交えて分かりやすく解説します"
tags: [ruby, block, proc, lambda, programming]
draft: true
date: 2024-01-15
---

Rubyを書いていると、必ず出会うのが「ブロック」です。
`each` メソッドなどでお馴染みですよね。

でも、「Proc」や「Lambda」という似たような概念もあって、
「何が違うの？」と混乱したことはありませんか？

今回は、Rubyのブロック、Proc、Lambdaの違いを、
実例を交えて分かりやすく解説します。

## ブロックとは？

ブロックは、Rubyのメソッドに「処理の塊」を渡すための仕組みです。

最もよく見かけるのは、配列の `each` メソッドでの使用例でしょう：

```ruby
[1, 2, 3].each do |n|
  puts n
end
# 出力:
# 1
# 2
# 3
```

ブロックは `do...end` または `{...}` の2つの書き方があります：

```ruby
# do...end 形式（複数行向き）
array.each do |item|
  puts item
  puts "---"
end

# {...} 形式（1行向き）
array.each { |item| puts item }
```

**重要なポイント**: ブロック自体はオブジェクトではありません。
メソッドに「渡す」ことはできますが、変数に代入することはできません。

## Procとは？ - ブロックをオブジェクト化

「ブロックを変数に入れて再利用したい」
そんなときに使うのが **Proc**（プロック）です。

Procは、ブロックをオブジェクトにしたものです：

```ruby
# Procオブジェクトを作成
my_proc = Proc.new { |n| puts n }

# 好きなときに呼び出せる
my_proc.call(5)  # => 5
my_proc.call(10) # => 10
```

変数に代入できるので、メソッドの引数として渡したり、
配列に入れたりすることもできます：

```ruby
procs = [
  Proc.new { puts "Hello" },
  Proc.new { puts "World" }
]

procs.each { |p| p.call }
# 出力:
# Hello
# World
```

## Lambdaとは？ - 厳格なProc

Lambdaは、Procの一種ですが、より厳格な動作をします：

```ruby
# Lambdaの作成
my_lambda = lambda { |n| puts n }
# または、短縮記法（->）
my_lambda = ->(n) { puts n }

my_lambda.call(5)  # => 5
```

見た目はProcとほとんど同じですが、重要な違いが2つあります。

## ProcとLambdaの違い

### 違い1: 引数のチェック

**Lambda**: 引数の数が合わないとエラー

```ruby
my_lambda = lambda { |a, b| puts a + b }
my_lambda.call(1)      # ArgumentError!
my_lambda.call(1, 2)   # OK => 3
```

**Proc**: 引数の数が合わなくても動く（nilで補完）

```ruby
my_proc = Proc.new { |a, b| puts a.to_s + b.to_s }
my_proc.call(1)      # OK => "1" (bはnil)
my_proc.call(1, 2)   # OK => "12"
```

### 違い2: returnの動作

**Lambda**: Lambdaから抜けるだけ

```ruby
def test_lambda
  my_lambda = lambda { return "lambdaから抜ける" }
  my_lambda.call
  return "メソッドから抜ける"
end

test_lambda  # => "メソッドから抜ける"
```

**Proc**: メソッド全体から抜ける

```ruby
def test_proc
  my_proc = Proc.new { return "メソッドから抜ける" }
  my_proc.call
  return "ここは実行されない"
end

test_proc  # => "メソッドから抜ける"
```

### 違いのまとめ

| 特徴 | Proc | Lambda |
|------|------|--------|
| 引数チェック | 緩い（不足分はnil） | 厳密（不一致でエラー） |
| `return`動作 | メソッド全体から抜ける | Lambda自身から抜ける |
| 用途 | 柔軟な処理 | 関数的な処理 |

## 使い分けのガイドライン

- **ブロック**: メソッドに1回だけ処理を渡すとき
  - 例: `each`, `map`, `select` など
  
- **Proc**: ブロックを再利用したいとき、柔軟性が欲しいとき
  - 例: コールバック、設定のカスタマイズ
  
- **Lambda**: 関数的に使いたいとき、引数チェックが欲しいとき
  - 例: 小さな関数の定義、フィルタ処理

## 実践例：コールバック処理

```ruby
class DataProcessor
  def initialize
    @callbacks = []
  end
  
  def add_callback(&block)
    @callbacks << block
  end
  
  def process(data)
    puts "処理開始: #{data}"
    @callbacks.each { |callback| callback.call(data) }
    puts "処理完了"
  end
end

processor = DataProcessor.new

# コールバックを登録（ブロック形式）
processor.add_callback { |data| puts "  ログ出力: #{data}" }
processor.add_callback { |data| puts "  通知送信: #{data}" }

processor.process("重要なデータ")
# 出力:
# 処理開始: 重要なデータ
#   ログ出力: 重要なデータ
#   通知送信: 重要なデータ
# 処理完了
```

## まとめ

- **ブロック**: Rubyの基本機能、メソッドに処理を渡す
- **Proc**: ブロックをオブジェクト化、再利用可能
- **Lambda**: より厳格なProc、関数的な使い方に向く

それぞれの特性を理解して、状況に応じて使い分けましょう！

## 動作環境

この記事のコード例は Ruby 2.7+ で動作確認済みです。

## 参考資料

{{< linkcard url="https://docs.ruby-lang.org/ja/latest/class/Proc.html" >}}
```

---

## 改善ポイントの解説

### blog-writerが追加した要素

1. **魅力的な導入部**
   - 読者の共感を得る問いかけ
   - 記事を読む動機付け

2. **文章の補足説明**
   - 「ブロック自体はオブジェクトではありません」など
   - 専門家の原稿にあった情報を丁寧に説明

3. **実践的な例の追加**
   - コールバック処理の実例
   - より実用的なユースケース

4. **視覚的な構造化**
   - 適切な見出し階層
   - 表による比較の活用
   - コードコメントの充実

5. **読者への配慮**
   - 「重要なポイント」の明示
   - 段階的な説明の追加
   - まとめセクションでの振り返り

6. **メタデータの最適化**
   - SEOを意識したタイトル
   - 検索されやすいdescription
   - 適切なタグ付け

### 技術的正確性の維持

専門家（ruby-specialist）の技術的な内容は一切変更せず、
説明を追加・構造化することで読みやすさを向上させています。
