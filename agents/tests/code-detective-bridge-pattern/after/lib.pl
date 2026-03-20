use strict;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

# --- 出力形式の系譜（Renderer） ---

package Renderer {
    use Moo::Role;
    requires 'render_title';
    requires 'render_field';
    requires 'render_list';
    requires 'render_signature';
}

package PdfRenderer {
    use Moo;
    with 'Renderer';

    sub render_title ($self, $title)          { "[PDF] === $title ===\n" }
    sub render_field ($self, $label, $value)  { "$label: $value\n" }
    sub render_list  ($self, $items)          { join("\n", map { "  ・$_" } @$items) . "\n" }
    sub render_signature ($self)              { "[署名欄] ___________\n" }
}

package HtmlRenderer {
    use Moo;
    with 'Renderer';

    sub render_title ($self, $title)          { "<h1>$title</h1>\n" }
    sub render_field ($self, $label, $value)  { "<p>$label: $value</p>\n" }
    sub render_list  ($self, $items)          { "<ol>" . join('', map { "<li>$_</li>" } @$items) . "</ol>\n" }
    sub render_signature ($self)              { "<div class='signature'>署名欄</div>\n" }
}

package MarkdownRenderer {
    use Moo;
    with 'Renderer';

    sub render_title ($self, $title)          { "# $title\n\n" }
    sub render_field ($self, $label, $value)  { "**$label**: $value\n\n" }
    sub render_list  ($self, $items)          { join("\n", map { "1. $_" } @$items) . "\n\n" }
    sub render_signature ($self)              { "---\n署名: ___________\n" }
}

package WordRenderer {
    use Moo;
    with 'Renderer';

    sub render_title ($self, $title)          { "[DOCX] $title\n" }
    sub render_field ($self, $label, $value)  { "  $label\t$value\n" }
    sub render_list  ($self, $items)          { join("\n", map { "  □ $_" } @$items) . "\n" }
    sub render_signature ($self)              { "  [電子署名] ___________\n" }
}

# --- 文書の系譜（Document） ---

package Document {
    use Moo;
    has renderer => ( is => 'ro', required => 1 );
    has content  => ( is => 'ro', required => 1 );

    sub render ($self) { die "Subclass must implement render" }
}

package Contract {
    use Moo;
    extends 'Document';

    sub render ($self) {
        my ($r, $c) = ($self->renderer, $self->content);
        my $out = $r->render_title('契約書');
        $out .= $r->render_field('甲', $c->{party_a});
        $out .= $r->render_field('乙', $c->{party_b});
        $out .= $r->render_list($c->{clauses});
        $out .= $r->render_signature;
        return $out;
    }
}

package Invoice {
    use Moo;
    extends 'Document';

    sub render ($self) {
        my ($r, $c) = ($self->renderer, $self->content);
        my $tax   = int($c->{amount} * 0.1);
        my $total = $c->{amount} + $tax;
        my $out = $r->render_title('請求書');
        $out .= $r->render_field('請求先', $c->{client});
        $out .= $r->render_field('小計', "¥$c->{amount}");
        $out .= $r->render_field('消費税(10%)', "¥$tax");
        $out .= $r->render_field('合計', "¥$total");
        return $out;
    }
}

package Report {
    use Moo;
    extends 'Document';

    sub render ($self) {
        my ($r, $c) = ($self->renderer, $self->content);
        my $out = $r->render_title($c->{title});
        $out .= $r->render_field('期間', $c->{period});
        $out .= $r->render_list($c->{findings});
        return $out;
    }
}

package Proposal {
    use Moo;
    extends 'Document';

    sub render ($self) {
        my ($r, $c) = ($self->renderer, $self->content);
        my $out = $r->render_title('ご提案書');
        $out .= $r->render_field('提案先', $c->{client});
        $out .= $r->render_field('概算費用', "¥$c->{amount}");
        $out .= $r->render_list($c->{benefits});
        return $out;
    }
}

1;
