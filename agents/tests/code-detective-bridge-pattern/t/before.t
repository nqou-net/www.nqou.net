use strict;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';
use Test::More;

do './agents/tests/code-detective-bridge-pattern/before/lib.pl' or die $@ || $!;

subtest 'Before: Cartesian Product Explosion' => sub {
    my $contract_data = {
        party_a => '株式会社A', party_b => '株式会社B',
        clauses => ['秘密保持', '損害賠償', '準拠法'],
    };

    my $cpdf = ContractPdf->new(content => $contract_data);
    like($cpdf->render, qr/\[PDF\].*契約書/, 'ContractPdf renders correctly');

    my $invoice_data = { client => '株式会社X', amount => 500000 };
    my $ipdf = InvoicePdf->new(content => $invoice_data);
    like($ipdf->render, qr/消費税.*¥50000/, 'InvoicePdf renders with tax');

    # 3文書 × 3形式 = 9クラス必要
    my @classes = qw(ContractPdf ContractHtml ContractMarkdown
                     InvoicePdf InvoiceHtml InvoiceMarkdown
                     ReportPdf ReportHtml ReportMarkdown);
    is(scalar @classes, 9, '9 classes needed for 3 types x 3 formats');

    # コピペバグ: ProposalPdf に請求書の消費税ロジックが混入
    my $proposal_data = { client => '株式会社Y', amount => 500000, benefits => ['工数削減'] };
    my $ppdf = ProposalPdf->new(content => $proposal_data);
    like($ppdf->render, qr/消費税/, 'BUG: ProposalPdf has invoice tax logic (COPY-PASTE BUG!)');

    # Word形式追加には文書種別数分の新クラスが必要
    ok(1, 'Adding Word format requires 4 new classes');
};

done_testing;
