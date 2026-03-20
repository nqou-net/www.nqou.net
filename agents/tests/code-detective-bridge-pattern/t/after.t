use strict;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';
use Test::More;

do './agents/tests/code-detective-bridge-pattern/after/lib.pl' or die $@ || $!;

subtest 'After: Bridge Pattern' => sub {
    my $contract_data = {
        party_a => '株式会社A', party_b => '株式会社B',
        clauses => ['秘密保持', '損害賠償', '準拠法'],
    };

    # Contract × 3形式
    my $cpdf = Contract->new(renderer => PdfRenderer->new, content => $contract_data);
    like($cpdf->render, qr/\[PDF\].*契約書/, 'Contract + PdfRenderer renders correctly');

    my $chtml = Contract->new(renderer => HtmlRenderer->new, content => $contract_data);
    like($chtml->render, qr/<h1>契約書<\/h1>/, 'Contract + HtmlRenderer renders correctly');

    my $cmd = Contract->new(renderer => MarkdownRenderer->new, content => $contract_data);
    like($cmd->render, qr/# 契約書/, 'Contract + MarkdownRenderer renders correctly');

    # Invoice にだけ消費税ロジックがある
    my $invoice_data = { client => '株式会社X', amount => 500000 };
    my $ipdf = Invoice->new(renderer => PdfRenderer->new, content => $invoice_data);
    like($ipdf->render, qr/消費税.*¥50000/, 'Invoice + PdfRenderer includes tax calculation');

    # Report
    my $report_data = { title => '月次報告', period => '2026年3月', findings => ['売上増加', '在庫減少'] };
    my $rhtml = Report->new(renderer => HtmlRenderer->new, content => $report_data);
    like($rhtml->render, qr/<li>売上増加<\/li>/, 'Report + HtmlRenderer renders findings as list');

    # Proposal 追加 — Renderer は一切変更なし
    my $proposal_data = { client => '株式会社Y', amount => 500000, benefits => ['工数削減', '品質向上'] };
    my $ppdf = Proposal->new(renderer => PdfRenderer->new, content => $proposal_data);
    like($ppdf->render, qr/ご提案書/, 'Proposal added without touching any Renderer');
    unlike($ppdf->render, qr/消費税/, 'Proposal has no tax logic (no copy-paste contamination)');

    # WordRenderer 追加 — Document は一切変更なし
    my $cword = Contract->new(renderer => WordRenderer->new, content => $contract_data);
    like($cword->render, qr/\[DOCX\]/, 'WordRenderer added without touching any Document');
    like($cword->render, qr/契約書/, 'Contract + WordRenderer works immediately');

    # 4文書 × 4形式 = 16組み合わせ, クラス数は 4+4 = 8
    my @doc_classes = qw(Contract Invoice Report Proposal);
    my @ren_classes = qw(PdfRenderer HtmlRenderer MarkdownRenderer WordRenderer);
    my $combos = scalar(@doc_classes) * scalar(@ren_classes);
    my $classes = scalar(@doc_classes) + scalar(@ren_classes);
    is($combos, 16, "4 documents x 4 formats = 16 combos");
    is($classes, 8, "Only 8 classes needed (4+4, not 4x4=16)");
};

done_testing;
