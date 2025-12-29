# 調査報告: Mooで覚えるオブジェクト指向プログラミング（全12回連載）

## 調査概要

- **調査日**: 2025年12月29日
- **調査者**: investigative-research エージェント
- **目的**: 「Mooで覚えるオブジェクト指向プログラミング」連載（第2回〜第12回）作成のための情報収集
- **第1回**: 既存（/content/post/2021/10/31/191008.md）- blessの紹介とMooの基本的な使い方

## 想定読者像

- プログラミング初心者（スパゲティコードしか知らない）
- オブジェクト指向プログラミングの必要性がわからない人
- Perl=CGIのイメージを持っている人
- 掲示板（BBS）をスパゲティコードで実装している状態

## 連載の目標

情報量の少ないチャットから、属性を増やして多機能な掲示板へと成長させる過程で、オブジェクトを追加しながら継承や委譲についても学ぶ。

---

## 1. Moo（Perlのオブジェクトシステム）

### 1.1 公式ドキュメント・基本リソース

#### MetaCPAN - Moo公式ドキュメント
- **URL**: https://metacpan.org/pod/Moo
- **信頼性**: ★★★★★（公式）
- **要点**:
  - Mooは最小限のオブジェクト指向システム（Minimalist Object Orientation）
  - Mooseと互換性があり、必要に応じてMooseにアップグレード可能
  - 純粋Perl実装でXS依存なし
  - 起動時間が速い（約0.03秒）、メモリ使用量が少ない
- **引用**: "Moo is an extremely light-weight Object Oriented system. It allows one to concisely define objects and roles with a convenient syntax that avoids the details of Perl's object system."

#### Perl Maven - OOP with Moo
- **URL**: https://perlmaven.com/oop-with-moo
- **信頼性**: ★★★★☆（コミュニティ評価高）
- **要点**:
  - 初心者向けの実践的なチュートリアル
  - 具体的なコード例とエラーハンドリング
  - 段階的な説明で理解しやすい

#### Perl Beginners' Site - Object Oriented Programming
- **URL**: https://perl-begin.org/topics/object-oriented/
- **信頼性**: ★★★★☆
- **要点**:
  - Perlのオブジェクト指向エコシステム全体の概要
  - Moo、Moose、Mouseの比較リンク集
  - 初心者向けリソースのキュレーション

### 1.2 Mooの基本機能

#### has（属性定義）
- **is**: アクセサタイプ（'ro': 読み取り専用、'rw': 読み書き可能）
- **default**: デフォルト値（サブルーチンリファレンスまたはスカラー値）
- **lazy**: 遅延初期化（初回アクセス時に値を計算）
- **trigger**: 属性値がセットされた際に呼ばれるコールバック
- **builder**: 属性値生成に使うメソッド名（サブクラスでオーバーライド可能）
- **coerce**: 型変換を行うサブルーチン
- **isa**: 型制約（値の型を検証）

**コード例**:
```perl
has foo => (
    is      => 'rw',
    lazy    => 1,
    default => sub { 'default value' },
    trigger => sub { my ($self, $value) = @_; ... },
    builder => 'build_foo',
    coerce  => sub { uc shift },
    isa     => sub { die "Wrong type" unless $_[0] =~ /^\d+$/; },
);
```

**注意点**:
- Mooの`trigger`は新しい値のみを受け取る（Mooseは古い値と新しい値の両方）
- `default`と`coerce`の組み合わせは注意が必要（古いバージョンにはバグがあった）

#### 継承（Inheritance）
```perl
package Circle;
use Moo;
extends 'Point';  # Pointクラスを継承

has r => (is => 'rw');
```

#### ロール（Role）
- **URL**: https://mvp.kablamo.org/oo/roles/
- **概要**: 機能の再利用や合成を可能にする仕組み

```perl
package Printable;
use Moo::Role;

sub print_message {
    my ($self, $msg) = @_;
    print "$msg\n";
}

# クラスでロールを使用
package Document;
use Moo;
with 'Printable';
```

#### メソッド修飾子（Method Modifiers）
- **URL**: https://perlmaven.com/inheritance-and-method-modifiers-in-moo
- `before`: メソッド実行前に処理を追加
- `after`: メソッド実行後に処理を追加
- `around`: メソッド全体をラップ

### 1.3 Moose、Mouseとの違い

#### パフォーマンス比較
- **URL**: https://perlmaven.com/memory-usage-and-load-time-of-moo-and-moose
- **信頼性**: ★★★★☆（実測ベンチマーク）

| 特徴 | Moose | Moo | Mouse |
|------|-------|-----|-------|
| 起動時間 | 遅い（~0.25秒） | 速い（~0.03秒） | 最速（XS） |
| メモリ使用量 | 大（~35MB） | 小 | 小 |
| 機能 | 完全なOO + MOP | Mooseのサブセット | Moose風（MOPなし） |
| 互換性 | Mooseのみ | Mooseへアップグレード可 | Moose構文（Mooではない） |
| 最適な用途 | 大規模アプリ | CLI/CGI/プロトタイピング | パフォーマンス重視 |

**使い分けの推奨**:
- **Moo**: 新規プロジェクトのデフォルト推奨。軽量で十分な機能
- **Moose**: 高度なメタプログラミングや型制約が必要な大規模アプリ
- **Mouse**: レガシーコードやパフォーマンス最重視の場合

### 1.4 初心者向けMoo解説（日本語）

#### Moo/Moose - モダンなPerlオブジェクト指向プログラミング
- **URL**: https://www.nqou.net/2025/12/11/000000/
- **信頼性**: ★★★★☆（本サイトの記事）
- **要点**:
  - Mooの主要機能や基本構文が日本語でまとめられている
  - 属性定義の実例
  - ロールの使い方

---

## 2. オブジェクト指向プログラミングの基礎

### 2.1 基本概念

#### クラスとオブジェクト
- **URL**: https://techgym.jp/column/object-orient/
- **信頼性**: ★★★★☆

**要点**:
- **クラス**: 設計図（例: 動物クラス）
- **オブジェクト**: 実体・インスタンス（例: ライオン、パンダ）
- **属性**: データ・プロパティ（例: 名前、年齢、色）
- **メソッド**: 操作・関数（例: 食べる、眠る）

#### カプセル化（Encapsulation）
- **URL**: https://zenn.dev/homatsu_tech/articles/d712e0881c0cb2
- **要点**:
  - データと操作を一つにまとめる
  - 外部から直接アクセスできないようにする
  - 例: 銀行口座の残高をprivate変数にし、入出金は公開メソッドで

#### 継承（Inheritance）
- **URL**: https://engineer-job.com/2025/06/04/初心者でもわかる！オブジェクト指向の基本と用語を図解で解説
- **要点**:
  - 既存クラス（親）から新しいクラス（子）を作成
  - 親の特徴・機能を引き継ぐ
  - 例: 動物クラス → 犬クラス、猫クラス
  - **「is-a」関係**: 犬は動物である

#### ポリモーフィズム（Polymorphism）
- **URL**: https://tech.adseed.co.jp/object-oriented-explanation
- **要点**:
  - 異なるクラスに共通のインターフェースを提供
  - 同じ操作で異なる動作
  - 例: Shape.area() → Circle.area(), Rectangle.area()

#### 委譲（Delegation）
- **URL**: https://qiita.com/CRUD5th/items/da0742b815bc5d6cf067
- **URL**: https://zenn.dev/sousquared/articles/95bf8dbddf3756
- **要点**:
  - **「has-a」関係**: あるクラスが別のクラスの機能を持つ
  - 継承より疎結合で柔軟
  - 例: 車クラスがエンジンオブジェクトを持つ

**継承 vs 委譲の使い分け**:
- 「○○は△△である」→ 継承
- 「○○は△△を持っている/使う」→ 委譲
- 迷ったら委譲を優先（モダンな設計トレンド）

### 2.2 SOLID原則

#### 概要
- **URL**: https://carefree-life.blog/solid-principles/
- **URL**: https://zenn.dev/aya1357/articles/46664e30e51664
- **信頼性**: ★★★★☆

#### 5つの原則

1. **単一責任原則（SRP: Single Responsibility Principle）**
   - クラスは1つの責任だけを持つ
   - 例: ユーザー管理とメール送信は別々のクラスに

2. **開放/閉鎖原則（OCP: Open/Closed Principle）**
   - 機能追加には開かれ、既存コード修正には閉じている
   - 例: 新しい支払い方法は新クラスで追加

3. **リスコフの置換原則（LSP: Liskov Substitution Principle）**
   - サブクラスは親クラスと同じように使える
   - 例: 四角形と正方形の関係

4. **インターフェース分離原則（ISP: Interface Segregation Principle）**
   - クライアントは使わない機能に依存しない
   - 例: プリンタ機能とスキャン機能を分離

5. **依存性逆転原則（DIP: Dependency Inversion Principle）**
   - 具体より抽象に依存する
   - 例: 具体的なDBクラスではなく保存インターフェースに依存

### 2.3 初心者向け説明方法

#### 現実のモノとの対応
- **URL**: https://programmer-beginner-blog.com/object/
- **要点**:
  - クラス/オブジェクト: 「家電」「動物」など
  - 属性: 「色」「サイズ」
  - メソッド: 「動作」「機能」

#### OOPのメリット
- **再利用性**: 共通部分を親クラスにまとめる
- **保守性**: 機能がまとまっていて修正しやすい
- **拡張性**: 新機能の追加が容易
- **分業**: チームで分担可能

#### デメリット（注意点）
- **学習コスト**: 概念が多く慣れが必要
- **設計難易度**: 適切な設計をしないとメリットが活かせない

---

## 3. Perlでの掲示板（BBS）実装

### 3.1 古典的なCGI掲示板

#### とほほのWWW入門 - 掲示板をつくる
- **URL**: https://www.tohoho-web.com/perl/bbs.htm
- **信頼性**: ★★★★★（定番リソース）
- **要点**:
  - 1ファイル構成の最小限BBS
  - HTML直接出力
  - グローバル変数多用

#### Web Liberty - 掲示板の作成
- **URL**: http://www.web-liberty.net/improve/perl/bbs.html
- **信頼性**: ★★★☆☆
- **要点**:
  - タブ区切りでデータ保存
  - split関数で読み込み
  - 投稿フォーム・表示が一体化

#### GitHub - legacy_bbs
- **URL**: https://github.com/hoto17296/legacy_bbs
- **信頼性**: ★★★☆☆
- **要点**:
  - レガシーなPerlコードによる1行掲示板
  - スパゲティコードの典型例
  - 学習教材として有用

### 3.2 スパゲティコードの典型的パターン

**特徴**:
1. すべてメインルーチンに直書き
2. HTMLテンプレをPerlのprintで直接出力
3. グローバル変数、一切分離なし
4. エラーハンドリングも最低限
5. 投稿と表示のロジックが一体化

**サンプルコード（最小限BBS）**:
```perl
#!/usr/bin/perl
use strict;
use warnings;
use CGI;
my $cgi = CGI->new;

print $cgi->header(-charset=>'Shift_JIS');
print "<html><head><title>掲示板</title></head><body>";

# 投稿処理
if ($cgi->param('handle') && $cgi->param('message')) {
    open(my $fh, '>>', "bbs.txt");
    print $fh $cgi->param('handle') . "\t" . $cgi->param('message') . "\n";
    close($fh);
}

# 投稿フォーム表示
print <<'EOT';
<form method="post" action="bbs.cgi">
  ハンドルネーム: <input type="text" name="handle"><br>
  メッセージ: <input type="text" name="message"><br>
  <input type="submit" value="投稿">
</form>
EOT

# 投稿一覧表示
if (open(my $fh, '<', "bbs.txt")) {
    while (my $line = <$fh>) {
        my ($handle, $message) = split(/\t/, $line, 2);
        print "<hr><b>$handle</b>: $message<br>\n";
    }
    close($fh);
}

print "</body></html>";
```

### 3.3 掲示板の基本機能

#### 投稿機能
- フォームからの入力受け取り
- ファイルへの書き込み（追記モード `>>`）
- データ形式: タブ区切り、改行区切り

#### 表示機能
- ファイルの読み込み
- split関数でデータ分割
- HTML生成

#### 削除機能
- **URL**: https://ponk.jp/perl/bbs/bbs4
- 記事番号と削除キーで特定
- splice関数で配列から削除
- ファイルへ再保存

### 3.4 Perlでのファイル操作・データ永続化

#### 基本的なファイル操作
- **URL**: https://www.gi.ce.t.kyoto-u.ac.jp/user/susaki/perl/file_io.html
- **要点**:
  - `open(FH, '<', 'file.txt')`: 読み込み
  - `open(FH, '>>', 'file.txt')`: 追記
  - `flock(FH, 2)`: 排他ロック（同時アクセス対策）
  - `close(FH)`: ファイルクローズ

#### データ保存形式
1. **タブ区切り**: `$name\t$message\n`
2. **改行区切り**: 1行1レコード
3. **Storable**: Perlデータ構造の永続化
4. **JSON/YAML**: 構造化データ

---

## 4. 段階的な学習アプローチ

### 4.1 プログラミング教育の原則

#### スモールステップ学習
- **URL**: https://aoyamatech.com/blogs/learning-roadmap
- **URL**: https://jobs.qiita.com/programming-beginner/
- **信頼性**: ★★★★☆

**要点**:
1. **目標設定**: 何を作りたいかを明確に
2. **基礎から着実に**: 共通の基礎（変数、条件分岐、ループ）
3. **小さな成功体験**: 簡単な課題から始める
4. **手を動かす**: 理論だけでなく実際にコードを書く
5. **段階的な振り返り**: できたことを記録・共有

### 4.2 簡単なチャットアプリから多機能掲示板への発展

#### 段階的な機能追加例
- **URL**: https://note.com/yuu07120428/n/n0536c619ca47
- **URL**: https://nocoderi.co.jp/2025/04/06/チャットアプリ開発の完全ガイド

**初級**:
1. メッセージ投稿（名前とメッセージ）
2. 投稿一覧表示
3. データファイル保存

**中級**:
4. タイムスタンプ追加
5. 投稿者識別（ID）
6. 削除機能
7. 簡易認証

**上級**:
8. ユーザークラス導入
9. メッセージクラス導入
10. 投稿履歴管理クラス
11. 継承によるスレッド機能
12. 委譲による権限管理

### 4.3 各段階で導入する概念（1記事1概念）

#### 推奨する段階的学習パス

**第2回**: Mooの基本構文（has, is, rw/ro）
- メッセージクラスの作成
- 属性とアクセサ

**第3回**: デフォルト値とバリデーション（default, isa）
- 投稿日時の自動設定
- 入力値のチェック

**第4回**: 遅延初期化（lazy, builder）
- IDの自動生成
- 重い処理の最適化

**第5回**: メソッドの定義
- メッセージの整形
- データの取得

**第6回**: 継承（extends）
- 基本メッセージクラス → スレッド対応メッセージクラス
- 親クラスの機能拡張

**第7回**: メソッドのオーバーライド
- 親クラスのメソッドをカスタマイズ
- super相当の処理

**第8回**: ロール（Role）の導入
- 共通機能の分離（タイムスタンプ、ID生成）
- with による合成

**第9回**: 委譲（Delegation）
- ユーザー管理機能の分離
- has-a関係の実装

**第10回**: 複数クラスの連携
- メッセージ、ユーザー、掲示板クラスの統合
- オブジェクト間の関係

**第11回**: データの永続化
- Storableによる保存
- ファイルI/Oとオブジェクト

**第12回**: まとめとリファクタリング
- スパゲティコードとの比較
- オブジェクト指向のメリット再確認

### 4.4 コード例の適切な複雑さ（2例まで）

**原則**:
- 1記事あたり2つまでの完結したコード例
- 各例は10〜30行程度
- 段階的に機能を追加
- 前回のコードを改善する形式

**例（第2回）**:

**コード例1: 基本的なメッセージクラス**
```perl
package Message;
use Moo;

has name => (is => 'ro');
has text => (is => 'ro');

1;
```

**コード例2: 使用例**
```perl
use Message;

my $msg = Message->new(
    name => '太郎',
    text => 'こんにちは'
);

print $msg->name . ': ' . $msg->text . "\n";
```

### 4.5 「手を動かして理解する」学習方法

**推奨する実践方法**:
1. **まずコピペで動かす**: 動作確認
2. **写経**: 自分の手で書いてみる
3. **小さな変更**: 属性名やメッセージを変える
4. **機能追加**: 新しい属性を追加してみる
5. **エラー体験**: わざと間違えて、エラーメッセージを読む

---

## 5. 関連する技術書籍

### 5.1 オブジェクト指向に関する入門書

#### オブジェクト指向でなぜつくるのか 第3版
- **著者**: 平澤章
- **出版社**: 日経BP
- **ISBN-10**: 4296000187
- **ISBN-13**: 978-4296000183
- **ASIN**: 4296000187
- **信頼性**: ★★★★★
- **要点**:
  - オブジェクト指向の「なぜ？」を解説
  - 初心者でも理解しやすい
  - 基礎から応用まで体系的
- **URL**: https://www.amazon.co.jp/dp/4296000187

#### オブジェクト指向入門 第2版 原則・コンセプト
- **著者**: バートランド・メイヤー
- **出版社**: 翔泳社
- **ISBN-10**: 4798111110
- **ISBN-13**: 978-4798111117
- **ASIN**: 4798111110
- **信頼性**: ★★★★★（古典的名著）
- **要点**:
  - オブジェクト指向の理論的基礎
  - 原則とコンセプトに特化
- **URL**: https://www.amazon.co.jp/dp/4798111110

#### ちょうぜつソフトウェア設計入門――PHPで理解するオブジェクト指向の活用
- **著者**: 田中ひさてる
- **出版社**: 技術評論社
- **ISBN-13**: 978-4297126370
- **ASIN**: B0BNH1J2W2（Kindle版）
- **信頼性**: ★★★★☆
- **要点**:
  - PHPを使った実践的な解説
  - イラスト・図解が豊富
  - 初心者にわかりやすい

#### いちばんやさしいオブジェクト指向の本【第二版】
- **著者**: 井上樹
- **出版社**: 技術評論社
- **ISBN-13**: 978-4297132524
- **ASIN**: B0CC48XM3Y（Kindle版）
- **信頼性**: ★★★★☆
- **要点**:
  - 図解中心の入門書
  - オブジェクト指向が全く初めての人向け

### 5.2 Perlのオブジェクト指向に関する書籍

#### すぐわかる オブジェクト指向 Perl
- **著者**: 深沢千尋
- **出版社**: 技術評論社
- **ISBN-10**: 4774135046
- **ISBN-13**: 978-4774135045
- **ASIN**: 4774135046
- **発売日**: 2008年6月20日
- **ページ数**: 564ページ
- **信頼性**: ★★★★☆
- **要点**:
  - Perlのリファレンス、モジュール、パッケージ
  - オブジェクト指向の丁寧な解説
  - 実例・サンプルコードが豊富
  - 目次: モジュール利用、リファレンス、サブルーチン、package、use、CPAN、クラス設計、継承、オーバーロード、CGI
- **注意**: モダンPerl（Moo/Moose）の話題は少ない
- **URL**: https://www.amazon.co.jp/dp/4774135046
- **参考**: https://gihyo.jp/book/2008/978-4-7741-3504-5

#### オブジェクト指向Perlマスターコース
- **著者**: Damian Conway
- **ISBN-13**: 978-4894713000
- **信頼性**: ★★★★☆
- **要点**:
  - より本格的なオブジェクト指向設計
  - 上級者向けの内容も含む

### 5.3 参考情報源

#### 書籍ランキング・推薦記事
- 侍エンジニアブログ: https://www.sejuku.net/blog/258557
- 技術書ナビ: https://techbooknavi.com/tags/オブジェクト指向/
- Zenn（西暦2023年版）: https://zenn.dev/takahashim/articles/a968b62db39598

---

## 6. 内部リンク候補（このリポジトリ内の関連記事）

### 6.1 タグ検索結果

#### perlタグ
- /content/post/2021/10/31/191008.md（第1回）
- /content/post/2025/11/27/204639.md

#### programmingタグ
- /content/post/2025/11/27/204639.md

#### object-orientedタグ
- （該当なし - 新規タグとして追加する必要がある）

### 6.2 推奨する内部リンク戦略

1. **連載内の相互リンク**:
   - 各回の冒頭に「前回」「次回」へのリンク
   - 関連する回への参照（例: 第6回で継承を説明する際、第4回のbuilderに言及）

2. **既存記事へのリンク**:
   - Perl関連の他の記事
   - プログラミング一般の記事

3. **新規タグの提案**:
   - `moo`
   - `object-oriented`
   - `perl-oop`
   - `tutorial`
   - `bbs`

---

## 7. 追加調査項目

### 7.1 実装に役立つリソース

#### CPANモジュール
- **Moo**: https://metacpan.org/pod/Moo
- **Moo::Role**: https://metacpan.org/pod/Moo::Role
- **Type::Tiny**: 型制約（Mooと組み合わせて使用）
- **Storable**: データ永続化
- **Path::Tiny**: ファイル操作の簡素化

#### Perl公式ドキュメント
- **perlootut**: https://perldoc.perl.org/perlootut
  - Perlのオブジェクト指向チュートリアル
  - blessからMoo/Mooseへの流れ

### 7.2 コミュニティリソース

#### Perl入学式
- **URL**: https://github.com/perl-entrance-org/workshop-2015-01
- 初心者向けの環境構築手順
- 第1回で既に言及済み

#### Perl Mongers
- Perl鍋（https://perlnabe.connpass.com/）
- なにわPerl（https://naniwaperl.doorkeeper.jp/）
- 第1回で既に言及済み

---

## 8. 連載構成案（暫定）

### 推奨する12回の構成

| 回 | タイトル案 | 主要トピック | 導入するMoo機能 |
|----|-----------|-------------|---------------|
| 1 | ✓既存 | bless、Mooの基本 | use Moo, has, is |
| 2 | メッセージを作ろう | オブジェクトの作成と使用 | new, アクセサ |
| 3 | 属性に工夫を加える | デフォルト値と検証 | default, isa |
| 4 | 必要な時だけ計算する | 遅延初期化 | lazy, builder |
| 5 | オブジェクトに機能を付ける | メソッド定義 | sub |
| 6 | 掲示板を拡張する | 継承の基本 | extends |
| 7 | 親クラスをカスタマイズ | オーバーライド | メソッド再定義 |
| 8 | 共通機能を分離する | ロール | Moo::Role, with |
| 9 | 責任を分担する | 委譲 | has（オブジェクト） |
| 10 | クラスを協調させる | 複数オブジェクト連携 | 総合 |
| 11 | データを保存する | 永続化 | Storable |
| 12 | まとめ | リファクタリング | 総復習 |

### 各回の構成（テンプレート）

```
## はじめに
- 前回の復習
- 今回学ぶこと

## 問題提起
- スパゲティコードの課題
- オブジェクト指向での解決アプローチ

## 実装
- コード例1（基本）
- コード例2（応用）
- 解説

## 動かしてみよう
- 実行例
- 出力結果
- 試してほしいこと

## まとめ
- 学んだこと
- 次回予告
```

---

## 9. SEO・検索キーワード分析

### ターゲットキーワード

**主要キーワード**:
- Perl オブジェクト指向
- Moo Perl
- Perl 初心者 OOP
- Perl 掲示板 オブジェクト指向
- Perl CGI リファクタリング

**ロングテールキーワード**:
- Perl Moo 使い方
- Perl オブジェクト指向 入門
- Perl 継承 委譲
- Perl クラス 作り方
- Perl モダン オブジェクト指向

### 競合分析

**既存の日本語リソース**:
1. Perl公式ドキュメント（翻訳版は古い）
2. とほほのWWW入門（blessベース）
3. Qiita記事（断片的）
4. Perl入学式資料（基礎のみ）

**差別化ポイント**:
- 実践的な掲示板を題材にした連載
- スパゲティコードからの脱却ストーリー
- 段階的・体系的な学習パス
- 初心者が躓きやすいポイントのフォロー

---

## 10. まとめと次のステップ

### 調査完了項目

✅ Moo公式ドキュメント・チュートリアル
✅ Mooの基本機能（has, is, default, lazy, trigger, builder, coerce, isa）
✅ Moose、Mouseとの違い・使い分け
✅ 初心者向けMoo解説記事
✅ OOP基礎概念（クラス、オブジェクト、カプセル化、継承、ポリモーフィズム、委譲）
✅ SOLID原則
✅ 初心者向けOOP説明方法
✅ Perl CGI掲示板の実装例
✅ スパゲティコードのパターン
✅ 段階的学習アプローチ
✅ チャットから掲示板への発展
✅ 関連書籍（ASIN/ISBN）
✅ 内部リンク候補

### 推奨する次のアクション

1. **連載構成の最終決定**
   - 12回の各タイトルと内容を確定
   - 各回のコード例を具体化

2. **第2回の執筆**
   - メッセージクラスの作成
   - Mooの基本構文（has, is）の解説
   - 実際に動くコード例

3. **サンプルコードの準備**
   - GitHub等でサンプルコードを公開
   - 各回ごとのブランチまたはディレクトリ

4. **図表・イラストの準備**
   - クラス図
   - オブジェクト間の関係図
   - before/afterのコード比較図

### 注意事項

- **技術の正確性**: Mooの仕様は最新のCPANドキュメントで確認
- **初心者への配慮**: 専門用語には必ず説明を付ける
- **実行可能性**: すべてのコード例は実際に動作検証する
- **段階性**: 各回で導入する概念は1つに絞る
- **継続性**: 前回の知識を前提とするが、軽く復習する

---

## 参考文献一覧

### Moo関連
- MetaCPAN - Moo: https://metacpan.org/pod/Moo
- Perl Maven - OOP with Moo: https://perlmaven.com/oop-with-moo
- Perl Maven - Inheritance and Method Modifiers: https://perlmaven.com/inheritance-and-method-modifiers-in-moo
- Minimum Viable Perl - Roles: https://mvp.kablamo.org/oo/roles/

### OOP基礎
- テックジム - オブジェクト指向プログラミング: https://techgym.jp/column/object-orient/
- Zenn - オブジェクト指向解説: https://zenn.dev/homatsu_tech/articles/d712e0881c0cb2
- エンジニアジョブ - 図解で解説: https://engineer-job.com/2025/06/04/初心者でもわかる
- SOLID原則解説: https://carefree-life.blog/solid-principles/
- 継承vs委譲: https://qiita.com/CRUD5th/items/da0742b815bc5d6cf067

### Perl掲示板
- とほほのWWW入門: https://www.tohoho-web.com/perl/bbs.htm
- Web Liberty: http://www.web-liberty.net/improve/perl/bbs.html
- GitHub legacy_bbs: https://github.com/hoto17296/legacy_bbs

### 段階的学習
- プログラミング学習ロードマップ: https://aoyamatech.com/blogs/learning-roadmap
- Qiita Job Change: https://jobs.qiita.com/programming-beginner/
- チャットアプリ開発: https://note.com/yuu07120428/n/n0536c619ca47

### 書籍
- オブジェクト指向でなぜつくるのか（ASIN: 4296000187）
- すぐわかる オブジェクト指向 Perl（ASIN: 4774135046）

---

**調査完了日**: 2025年12月29日
**次回更新予定**: 連載構成確定後
