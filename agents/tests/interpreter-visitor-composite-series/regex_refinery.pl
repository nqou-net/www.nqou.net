#!/usr/bin/env perl
use v5.36;

# ============================================
# 正規表現リファインリー（RegexRefinery）
# Interpreter × Visitor × Composite パターン
# ============================================

# === Visitor インターフェース ===
package Visitor {
    use Moo::Role;
    requires 'visit_literal';
    requires 'visit_concat';
    requires 'visit_alt';
    requires 'visit_star';
    requires 'visit_plus';
    requires 'visit_optional';
    requires 'visit_group';
}

# === Node インターフェース ===
package Node {
    use Moo::Role;
    requires 'to_string';
    requires 'accept';
}

# === MatchResult ===
package MatchResult {
    use Moo;
    has matched => (is => 'ro', required => 1);
    has consumed => (is => 'ro', default => 0);
}

# === Literal ===
package Literal {
    use Moo;
    with 'Node';
    has char => (is => 'ro', required => 1);
    
    sub to_string($self) { $self->char }
    sub accept($self, $v) { $v->visit_literal($self) }
    sub evaluate($self, $input, $pos) {
        if ($pos < length($input) && substr($input, $pos, 1) eq $self->char) {
            return MatchResult->new(matched => 1, consumed => 1);
        }
        return MatchResult->new(matched => 0);
    }
}

# === Concat ===
package Concat {
    use Moo;
    with 'Node';
    has children => (is => 'ro', default => sub { [] });
    
    sub to_string($self) {
        join('', map { $_->to_string } $self->children->@*);
    }
    sub accept($self, $v) { $v->visit_concat($self) }
    sub evaluate($self, $input, $pos) {
        my $p = $pos;
        for my $c ($self->children->@*) {
            my $r = $c->evaluate($input, $p);
            return MatchResult->new(matched => 0) unless $r->matched;
            $p += $r->consumed;
        }
        return MatchResult->new(matched => 1, consumed => $p - $pos);
    }
}

# === Alt ===
package Alt {
    use Moo;
    with 'Node';
    has left => (is => 'ro', required => 1);
    has right => (is => 'ro', required => 1);
    
    sub to_string($self) {
        $self->left->to_string . '|' . $self->right->to_string;
    }
    sub accept($self, $v) { $v->visit_alt($self) }
    sub evaluate($self, $input, $pos) {
        my $r = $self->left->evaluate($input, $pos);
        return $r if $r->matched;
        return $self->right->evaluate($input, $pos);
    }
}

# === Star ===
package Star {
    use Moo;
    with 'Node';
    has child => (is => 'ro', required => 1);
    
    sub to_string($self) {
        my $i = $self->child->to_string;
        length($i) > 1 ? "($i)*" : "$i*";
    }
    sub accept($self, $v) { $v->visit_star($self) }
    sub evaluate($self, $input, $pos) {
        my $p = $pos;
        while (1) {
            my $r = $self->child->evaluate($input, $p);
            last unless $r->matched && $r->consumed > 0;
            $p += $r->consumed;
        }
        return MatchResult->new(matched => 1, consumed => $p - $pos);
    }
}

# === Plus ===
package Plus {
    use Moo;
    with 'Node';
    has child => (is => 'ro', required => 1);
    
    sub to_string($self) {
        my $i = $self->child->to_string;
        length($i) > 1 ? "($i)+" : "$i+";
    }
    sub accept($self, $v) { $v->visit_plus($self) }
    sub evaluate($self, $input, $pos) {
        my $r = $self->child->evaluate($input, $pos);
        return MatchResult->new(matched => 0) unless $r->matched;
        my $p = $pos + $r->consumed;
        while (1) {
            $r = $self->child->evaluate($input, $p);
            last unless $r->matched && $r->consumed > 0;
            $p += $r->consumed;
        }
        return MatchResult->new(matched => 1, consumed => $p - $pos);
    }
}

# === Optional ===
package Optional {
    use Moo;
    with 'Node';
    has child => (is => 'ro', required => 1);
    
    sub to_string($self) {
        my $i = $self->child->to_string;
        length($i) > 1 ? "($i)?" : "$i?";
    }
    sub accept($self, $v) { $v->visit_optional($self) }
    sub evaluate($self, $input, $pos) {
        my $r = $self->child->evaluate($input, $pos);
        return $r->matched ? $r : MatchResult->new(matched => 1, consumed => 0);
    }
}

# === Group ===
package Group {
    use Moo;
    with 'Node';
    has child => (is => 'ro', required => 1);
    
    sub to_string($self) { '(' . $self->child->to_string . ')' }
    sub accept($self, $v) { $v->visit_group($self) }
    sub evaluate($self, $input, $pos) {
        $self->child->evaluate($input, $pos);
    }
}

# === RegexParser ===
package RegexParser {
    use Moo;
    has input => (is => 'ro', required => 1);
    has pos => (is => 'rw', default => 0);
    
    sub parse($self) {
        my $r = $self->_alternation;
        die "Parse error at " . $self->pos if $self->pos < length($self->input);
        return $r;
    }
    
    sub _char($self) {
        $self->pos < length($self->input) ? substr($self->input, $self->pos, 1) : undef;
    }
    sub _eat($self) { my $c = $self->_char; $self->pos($self->pos + 1); $c }
    
    sub _alternation($self) {
        my $l = $self->_concat;
        while (defined $self->_char && $self->_char eq '|') {
            $self->_eat;
            $l = Alt->new(left => $l, right => $self->_concat);
        }
        return $l;
    }
    
    sub _concat($self) {
        my @ch;
        while (defined $self->_char && $self->_char ne '|' && $self->_char ne ')') {
            push @ch, $self->_repetition;
        }
        return @ch == 1 ? $ch[0] : Concat->new(children => \@ch);
    }
    
    sub _repetition($self) {
        my $n = $self->_atom;
        if (defined $self->_char) {
            if ($self->_char eq '*') { $self->_eat; $n = Star->new(child => $n); }
            elsif ($self->_char eq '+') { $self->_eat; $n = Plus->new(child => $n); }
            elsif ($self->_char eq '?') { $self->_eat; $n = Optional->new(child => $n); }
        }
        return $n;
    }
    
    sub _atom($self) {
        if ($self->_char eq '(') {
            $self->_eat;
            my $i = $self->_alternation;
            die "Expected ')'" unless $self->_char eq ')';
            $self->_eat;
            return Group->new(child => $i);
        }
        return Literal->new(char => $self->_eat);
    }
}

# === PrettyPrinter Visitor ===
package PrettyPrinter {
    use Moo;
    with 'Visitor';
    has indent => (is => 'rw', default => 0);
    
    sub _pre($self) { "  " x $self->indent }
    sub visit_literal($self, $n) { $self->_pre . "Literal: '" . $n->char . "'\n" }
    sub visit_concat($self, $n) {
        my $r = $self->_pre . "Concat\n";
        $self->indent($self->indent + 1);
        $r .= $_->accept($self) for $n->children->@*;
        $self->indent($self->indent - 1);
        $r;
    }
    sub visit_alt($self, $n) {
        my $r = $self->_pre . "Alt\n";
        $self->indent($self->indent + 1);
        $r .= $n->left->accept($self) . $n->right->accept($self);
        $self->indent($self->indent - 1);
        $r;
    }
    sub visit_star($self, $n) {
        my $r = $self->_pre . "Star\n";
        $self->indent($self->indent + 1);
        $r .= $n->child->accept($self);
        $self->indent($self->indent - 1);
        $r;
    }
    sub visit_plus($self, $n) {
        my $r = $self->_pre . "Plus\n";
        $self->indent($self->indent + 1);
        $r .= $n->child->accept($self);
        $self->indent($self->indent - 1);
        $r;
    }
    sub visit_optional($self, $n) {
        my $r = $self->_pre . "Optional\n";
        $self->indent($self->indent + 1);
        $r .= $n->child->accept($self);
        $self->indent($self->indent - 1);
        $r;
    }
    sub visit_group($self, $n) {
        my $r = $self->_pre . "Group\n";
        $self->indent($self->indent + 1);
        $r .= $n->child->accept($self);
        $self->indent($self->indent - 1);
        $r;
    }
}

# === メイン処理 ===
package main;

my $regex = $ARGV[0] // 'a(b|c)*d';
say "=== 正規表現リファインリー ===";
say "入力: $regex";
say "";

my $parser = RegexParser->new(input => $regex);
my $ast = $parser->parse;

say "復元: " . $ast->to_string;
say "";

say "=== AST構造 ===";
print $ast->accept(PrettyPrinter->new);
say "";

say "=== マッチングテスト ===";
my @tests = ('ad', 'abd', 'acd', 'abcd', 'abbd', 'ax', 'abx');
for my $t (@tests) {
    my $r = $ast->evaluate($t, 0);
    my $ok = $r->matched && $r->consumed == length($t);
    say "  '$t' => " . ($ok ? "✓ マッチ" : "✗ 不一致");
}
