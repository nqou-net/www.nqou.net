# Plot Outline: Abstract Factory Pattern

## I. 導入 (Admission) - 来院

### 状況設定
平日の午後。元Webデザイナーの患者（32歳、女性、一人称「私」）がコード診療所を訪れる。手にはノートPC。営業部から「レポートをMarkdownでも出してほしい」と追加依頼を受けたが、対応した途端PDF出力まで崩壊した。廊下を歩きながら内心焦っている。

### 患者の心理状態
「PDFもHTMLも、出力は完璧に美しかったのに。Markdownを追加しただけなのに、なぜPDFのフッターにMarkdownの記法が混じるの？ 私はデザイナー出身だから、見た目には自信がある。でもコードの中身は…正直、自分でも何がどうなってるのかわからない」

### ドクター登場
診療所のドアを開けると、O'Reilly本の山が出迎える。受付カウンターの奥で、ナナコが微笑む。

- 患者：「あの、予約していた者ですが」
- ナナコ：「お待ちしておりました。レポート出力の不具合でしたね？」
- 患者：「はい。出力が…崩壊して」
- ドクター：（トリプルディスプレイから振り返りもせず）「……崩壊？」
- 患者：（声だけが聞こえる。不穏だ）

ドクターがゆっくりと椅子を回転させ、こちらを見る。目がコードを求めている。

- ドクター：「見せろ」
- ナナコ：「先生、まず挨拶を…。すみません、先生は口数が少ないだけで悪い方じゃないんですよ。コード、見せていただけますか？」

## II. 検査 (Examination) - 触診・画像診断

### 問題特定
患者がノートPCを開き、レポート生成コードを見せる。`ReportGenerator.pm` — すべてのフォーマットの出力処理が一つのモジュールに詰め込まれている。

```perl
# Before: ReportGenerator.pm
package ReportGenerator {
    use v5.36;
    use Moo;

    sub generate($self, $format, $data) {
        my $output = '';

        # タイトル生成
        if ($format eq 'pdf') {
            $output .= $self->_pdf_title($data->{title});
        } elsif ($format eq 'html') {
            $output .= $self->_html_title($data->{title});
        } elsif ($format eq 'markdown') {
            $output .= $self->_markdown_title($data->{title});
        }

        # テーブル生成
        if ($format eq 'pdf') {
            $output .= $self->_pdf_table($data->{rows});
        } elsif ($format eq 'html') {
            $output .= $self->_html_table($data->{rows});
        } elsif ($format eq 'markdown') {
            $output .= $self->_markdown_table($data->{rows});
        }

        # フッター生成
        if ($format eq 'pdf') {
            $output .= $self->_pdf_footer();
        } elsif ($format eq 'html') {
            $output .= $self->_html_footer();
        } elsif ($format eq 'markdown') {
            $output .= $self->_markdown_footer();
        }

        return $output;
    }

    # ここに各フォーマットのメソッドが30個以上並ぶ...
    # _pdf_title, _html_title, _markdown_title,
    # _pdf_table, _html_table, _markdown_table,
    # ...
}
```

ドクターがスクロールする。延々と続くif分岐。眉間にシワが寄る。

- ドクター：「……クロスマッチ」
- 患者：「え？」
- ナナコ：「先生がおっしゃっているのは、異なるフォーマットのパーツが混ざり合う危険性ですね。血液型でいうと、A型の患者さんにB型の血液を混ぜているような…あ、でも2人までは偶然うまくいっていたんですね」
- 患者：「そう！ PDFとHTMLの2つだけの時は問題なかったんです。でもMarkdownを追加したら——」
- ドクター：「3人目。免疫暴走」
- ナナコ：「3つ目のフォーマットを加えたことで、いわば拒絶反応が出たということですね。先生、これは……？」
- ドクター：「潜伏性クロスマッチ不全」

### 診断
ナナコがモニターを指し、症状を整理する。

> 1. **コンポーネント生成の散在**: タイトル・テーブル・フッターの生成が各所にif分岐で散らばっている
> 2. **ファミリーの不整合**: あるフォーマットのコンポーネントが別フォーマットの出力に混入する可能性
> 3. **追加時の全面改修**: 新フォーマット追加のたびに、全コンポーネントのif分岐を修正する必要がある

- ナナコ：「この症状、昨日来られた方（Factory Method）と似ているように見えますが、実はもっと深刻なんですよ。あちらは『同じ種類のモノをどこで作るか』の問題でしたが、こちらは『**関連するモノのセット全体**が混ざっている』んです」
- 患者：「セット…？」
- ナナコ：「PDFレポートを作るなら、タイトルもテーブルもフッターも、全部PDF用のものでなければなりません。一つでもHTML用のものが混じると——」
- ドクター：「拒絶反応」
- 患者：「まさにそれです…フッターだけMarkdown記法になってて…」

## III. 処置 (Surgery) - 外科手術

### 手術方針
ドクターが黙々とキーボードを叩き始める。ナナコが横で解説する。

- ナナコ：「先生は今から、フォーマットごとの『専用工場』を作ります。工場がセット一式を保証するので、もう血液型の不一致は起きませんよ」

### コード変換

**Step 1: コンポーネントのRole定義**

```perl
# lib/Role/ReportTitle.pm
package Role::ReportTitle {
    use v5.36;
    use Moo::Role;
    requires 'render';
}

# lib/Role/ReportTable.pm
package Role::ReportTable {
    use v5.36;
    use Moo::Role;
    requires 'render';
}

# lib/Role/ReportFooter.pm
package Role::ReportFooter {
    use v5.36;
    use Moo::Role;
    requires 'render';
}
```

- ナナコ：「まず臓器の規格書を作ります。タイトル・テーブル・フッターがそれぞれ『こう振る舞うべき』という契約です」

**Step 2: 具象コンポーネントの実装（PDF/HTML/Markdown各ファミリー）**

```perl
# lib/Report/Pdf/Title.pm
package Report::Pdf::Title {
    use v5.36;
    use Moo;
    with 'Role::ReportTitle';

    sub render($self, $text) {
        return "\\textbf{\\Large $text}\n\n";
    }
}

# lib/Report/Html/Title.pm
package Report::Html::Title {
    use v5.36;
    use Moo;
    with 'Role::ReportTitle';

    sub render($self, $text) {
        return "<h1>$text</h1>\n";
    }
}

# lib/Report/Markdown/Title.pm
package Report::Markdown::Title {
    use v5.36;
    use Moo;
    with 'Role::ReportTitle';

    sub render($self, $text) {
        return "# $text\n\n";
    }
}
```

- ナナコ：「同じ『タイトル』という臓器でも、体質（フォーマット）ごとに中身が違います。でも外から見た振る舞い——`render` を呼べるということは共通です」

**Step 3: Abstract Factory Role**

```perl
# lib/Role/ReportFactory.pm
package Role::ReportFactory {
    use v5.36;
    use Moo::Role;
    requires 'create_title';
    requires 'create_table';
    requires 'create_footer';
}
```

- ナナコ：「これが専用工場の設計図です。タイトル・テーブル・フッターをセットで作ることを保証します」
- 患者：「Factory Methodだと工場は1つのモノだけ作ってましたけど、こっちは…セット全部？」
- ナナコ：「その通りです！ それがAbstract Factoryの核心ですよ」

**Step 4: Concrete Factory 実装**

```perl
# lib/ReportFactory/Pdf.pm
package ReportFactory::Pdf {
    use v5.36;
    use Moo;
    with 'Role::ReportFactory';
    use Report::Pdf::Title;
    use Report::Pdf::Table;
    use Report::Pdf::Footer;

    sub create_title($self)  { Report::Pdf::Title->new }
    sub create_table($self)  { Report::Pdf::Table->new }
    sub create_footer($self) { Report::Pdf::Footer->new }
}

# lib/ReportFactory/Html.pm, ReportFactory/Markdown.pm も同様の構造
```

- ナナコ：「PDF工場からはPDFのパーツしか出てきません。絶対に。HTMLのフッターが紛れ込む余地がないんです」
- 患者：「なるほど…工場単位で血液型が決まっているから、不適合が起きない…！」

**Step 5: メインロジックの浄化**

```perl
# lib/ReportGenerator.pm (After)
package ReportGenerator {
    use v5.36;
    use Moo;

    has factory => (is => 'ro', required => 1);

    sub generate($self, $data) {
        my $title  = $self->factory->create_title;
        my $table  = $self->factory->create_table;
        my $footer = $self->factory->create_footer;

        return join('',
            $title->render($data->{title}),
            $table->render($data->{rows}),
            $footer->render(),
        );
    }
}
```

### カタルシスポイント
- 患者：「……え？ generate()の中にif文が一つもない」
- ナナコ：「はい。フォーマットの判断は工場の選択時に済んでいるので、ここではもう何も分岐する必要がないんですよ」
- ドクター：「……純粋」
- ナナコ：「先生は『純粋なロジック』と言いたいんだと思います。生成の責任を工場に完全に委譲したので、この関数はレポートの組み立てだけに集中できます」

使用側：
```perl
# 利用例
use ReportFactory::Pdf;
use ReportFactory::Html;
use ReportFactory::Markdown;

my $pdf_report = ReportGenerator->new(factory => ReportFactory::Pdf->new);
my $html_report = ReportGenerator->new(factory => ReportFactory::Html->new);
my $md_report = ReportGenerator->new(factory => ReportFactory::Markdown->new);

# どのフォーマットでも同じインターフェース
say $pdf_report->generate($data);
say $html_report->generate($data);
say $md_report->generate($data);
```

- 患者：「フォーマットを変えるのが……工場を差し替えるだけ？」
- ナナコ：「新しいフォーマットを足すときも同じです。新しい工場と部品を作るだけ。既存コードには一切触れません」

## IV. 予後 (Prognosis) - 術後経過・退院指導

### 改善確認
テストを実行。すべてグリーン。PDFにMarkdown記法は混入せず、各フォーマットで美しいレポートが出力される。

- 患者：「完璧…。PDFもHTMLもMarkdownも、それぞれ美しい…」
- ナナコ：「患者さんのデザインセンスはそのまま活かせますよ。各コンポーネントの見た目は自由にカスタマイズできます。ただし、同じ工場の中で」

### 勘違いシーン
ドクターが立ち上がり、患者のノートPCの画面をしばらく見つめる。そして、画面の端に貼られたカラーパレットのポストイットに手を伸ばし——剥がした。

- 患者：（え…？ 私のカラーパレットを…？ まさか、私のデザインセンスを認めて、記念に持ち帰るつもり？ いや、でも——）
- ドクター：（ポストイットをひっくり返し、何か書き始める）

裏面に走り書き：`Factory = Family`

- ドクター：（ポストイットをPCの元の場所に貼り直す）
- ナナコ：「先生、人のポストイットに書かないでください。……すみません、先生は裏が白いメモ用紙だと思ったんだと思います」
- 患者：「あ……いえ、その、大事に使います」（顔が赤い。なぜデザイナー的色彩感覚に感動してくれたかと一瞬でも思ったのだろう、私は）

### 別れ
- ドクター：（鞄を持って立ち上がる）「……整合性は、美学」
- ナナコ：「先生からの最高の褒め言葉ですよ。コードもデザインも、『ファミリーの整合性を保つ』という意味では同じですからね」
- 患者：「はい…。見た目だけじゃなくて、コードの中身も美しくします」

ドアが閉まる。私はPCに貼られた `Factory = Family` のメモを見つめた。

デザイナーとして培ってきた「統一感」へのこだわり。それはコードの世界でも武器になる——Abstract Factoryが教えてくれたのは、結局、私がずっと大切にしてきたことと同じだった。

---

# メモ: 勘違いシーン配置

- **配置**: IV. 予後
- **トリガー**: ドクターが患者のカラーパレットのポストイットを剥がす
- **誤解内容**: 「私のデザインセンスを認めて記念に持ち帰る」と勘違い（実は裏をメモ用紙に使った）
- **オチ**: ナナコの「人のポストイットに書かないで」で現実に戻る。さらに、走り書きの`Factory = Family`が物語のテーマを集約

# メモ: Factory Method との差別化ポイント

- **Factory Method（前日記事）**: 1種類のプロダクト（SyncClient）を工場で生成。癒着分離がテーマ
- **Abstract Factory（本記事）**: 複数種類のプロダクト群（Title, Table, Footer）をファミリーとして一括生成。クロスマッチ不全（ファミリー間の不整合）がテーマ
- **ナナコが作中でFactory Methodに言及**: 「昨日来られた方と似ているように見えますが、もっと深刻」という台詞で差別化を明確に
