use strict;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

package ContractPdf {
    use Moo;
    has content => ( is => 'ro', required => 1 );

    sub render ($self) {
        my $c = $self->content;
        my $out = "[PDF] === 契約書 ===\n";
        $out .= "甲: $c->{party_a}\n";
        $out .= "乙: $c->{party_b}\n";
        $out .= join("\n", map { "第${_}条: $c->{clauses}[$_ - 1]" }
                               1 .. scalar $c->{clauses}->@*) . "\n";
        $out .= "[署名欄] ___________\n";
        return $out;
    }
}

package ContractHtml {
    use Moo;
    has content => ( is => 'ro', required => 1 );

    sub render ($self) {
        my $c = $self->content;
        my $clauses = join('', map { "<li>$_</li>" } $c->{clauses}->@*);
        my $out = "<h1>契約書</h1>\n";
        $out .= "<p>甲: $c->{party_a}</p>\n";
        $out .= "<p>乙: $c->{party_b}</p>\n";
        $out .= "<ol>$clauses</ol>\n";
        $out .= "<div class='signature'>署名欄</div>\n";
        return $out;
    }
}

package ContractMarkdown {
    use Moo;
    has content => ( is => 'ro', required => 1 );

    sub render ($self) {
        my $c = $self->content;
        my $out = "# 契約書\n\n";
        $out .= "**甲**: $c->{party_a}\n\n";
        $out .= "**乙**: $c->{party_b}\n\n";
        $out .= join("\n", map { "1. $_" } $c->{clauses}->@*) . "\n\n";
        $out .= "---\n署名: ___________\n";
        return $out;
    }
}

package InvoicePdf {
    use Moo;
    has content => ( is => 'ro', required => 1 );

    sub render ($self) {
        my $c = $self->content;
        my $tax   = int($c->{amount} * 0.1);
        my $total = $c->{amount} + $tax;
        my $out = "[PDF] === 請求書 ===\n";
        $out .= "請求先: $c->{client}\n";
        $out .= "小計: ¥$c->{amount}\n";
        $out .= "消費税(10%): ¥$tax\n";
        $out .= "合計: ¥$total\n";
        return $out;
    }
}

package InvoiceHtml {
    use Moo;
    has content => ( is => 'ro', required => 1 );

    sub render ($self) {
        my $c = $self->content;
        my $tax   = int($c->{amount} * 0.1);
        my $total = $c->{amount} + $tax;
        my $out = "<h1>請求書</h1>\n";
        $out .= "<p>請求先: $c->{client}</p>\n";
        $out .= "<p>小計: ¥$c->{amount}</p>\n";
        $out .= "<p>消費税(10%): ¥$tax</p>\n";
        $out .= "<p>合計: ¥$total</p>\n";
        return $out;
    }
}

package InvoiceMarkdown {
    use Moo;
    has content => ( is => 'ro', required => 1 );

    sub render ($self) {
        my $c = $self->content;
        my $tax   = int($c->{amount} * 0.1);
        my $total = $c->{amount} + $tax;
        my $out = "# 請求書\n\n";
        $out .= "**請求先**: $c->{client}\n\n";
        $out .= "**小計**: ¥$c->{amount}\n\n";
        $out .= "**消費税(10%)**: ¥$tax\n\n";
        $out .= "**合計**: ¥$total\n\n";
        return $out;
    }
}

package ReportPdf {
    use Moo;
    has content => ( is => 'ro', required => 1 );

    sub render ($self) {
        my $c = $self->content;
        my $out = "[PDF] === $c->{title} ===\n";
        $out .= "期間: $c->{period}\n";
        $out .= join("\n", map { "  ・$_" } $c->{findings}->@*) . "\n";
        return $out;
    }
}

package ReportHtml {
    use Moo;
    has content => ( is => 'ro', required => 1 );

    sub render ($self) {
        my $c = $self->content;
        my $items = join('', map { "<li>$_</li>" } $c->{findings}->@*);
        my $out = "<h1>$c->{title}</h1>\n";
        $out .= "<p>期間: $c->{period}</p>\n";
        $out .= "<ol>$items</ol>\n";
        return $out;
    }
}

package ReportMarkdown {
    use Moo;
    has content => ( is => 'ro', required => 1 );

    sub render ($self) {
        my $c = $self->content;
        my $out = "# $c->{title}\n\n";
        $out .= "**期間**: $c->{period}\n\n";
        $out .= join("\n", map { "1. $_" } $c->{findings}->@*) . "\n\n";
        return $out;
    }
}

# コピペバグ: InvoicePdf から作った ProposalPdf
package ProposalPdf {
    use Moo;
    has content => ( is => 'ro', required => 1 );

    sub render ($self) {
        my $c = $self->content;
        my $tax   = int($c->{amount} * 0.1);  # ← 請求書から混入！
        my $total = $c->{amount} + $tax;
        my $out = "[PDF] === ご提案書 ===\n";
        $out .= "提案先: $c->{client}\n";
        $out .= "概算費用: ¥$c->{amount}\n";
        $out .= "消費税(10%): ¥$tax\n";       # ← 提案書に消費税！
        $out .= "合計: ¥$total\n";
        return $out;
    }
}

1;
