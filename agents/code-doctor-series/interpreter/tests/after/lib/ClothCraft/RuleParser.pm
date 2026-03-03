package ClothCraft::RuleParser;
use v5.36;
use Carp qw(croak);

use ClothCraft::Expression::Literal;
use ClothCraft::Expression::Variable;
use ClothCraft::Expression::Comparison;
use ClothCraft::Expression::And;
use ClothCraft::Expression::Or;
use ClothCraft::Expression::Not;

# ルール文字列をトークン化し、Expression ツリーに変換するパーサー
# 文法:
#   expr     := or_expr
#   or_expr  := and_expr ( 'OR' and_expr )*
#   and_expr := not_expr ( 'AND' not_expr )*
#   not_expr := 'NOT' not_expr | primary
#   primary  := '(' expr ')' | comparison
#   comparison := value OP value
#   value    := NUMBER | QUOTED_STRING | IDENTIFIER(variable)
#   OP       := '>=' | '<=' | '>' | '<' | '==' | '!=' | 'eq' | 'ne'

sub new ($class) {
    return bless {}, $class;
}

sub parse ($self, $text) {
    my @tokens = _tokenize($text);
    my $pos = 0;
    my $expr = _parse_or(\@tokens, \$pos);
    croak "Unexpected token at position $pos: '$tokens[$pos]'"
        if $pos < scalar @tokens;
    return $expr;
}

sub _tokenize ($text) {
    my @tokens;
    while ($text =~ /\G\s*
        ( \( | \)
        | >= | <= | != | == | > | <
        | "([^"]*)"
        | \b(?:AND|OR|NOT|eq|ne)\b
        | [A-Za-z_]\w*
        | [0-9]+(?:\.[0-9]+)?
        )/gcx
    ) {
        my $token = $1;
        # クォート文字列はクォートを除去してマーキング
        if (defined $2) {
            push @tokens, qq{"$2"};
        } else {
            push @tokens, $token;
        }
    }
    croak "Unexpected character in rule: '" . substr($text, pos($text) // 0) . "'"
        if (pos($text) // 0) < length($text) && $text =~ /\G\s*\S/gc;
    return @tokens;
}

sub _parse_or ($tokens, $pos_ref) {
    my $left = _parse_and($tokens, $pos_ref);
    while ($$pos_ref < scalar @$tokens && $tokens->[$$pos_ref] eq 'OR') {
        $$pos_ref++;
        my $right = _parse_and($tokens, $pos_ref);
        $left = ClothCraft::Expression::Or->new($left, $right);
    }
    return $left;
}

sub _parse_and ($tokens, $pos_ref) {
    my $left = _parse_not($tokens, $pos_ref);
    while ($$pos_ref < scalar @$tokens && $tokens->[$$pos_ref] eq 'AND') {
        $$pos_ref++;
        my $right = _parse_not($tokens, $pos_ref);
        $left = ClothCraft::Expression::And->new($left, $right);
    }
    return $left;
}

sub _parse_not ($tokens, $pos_ref) {
    if ($$pos_ref < scalar @$tokens && $tokens->[$$pos_ref] eq 'NOT') {
        $$pos_ref++;
        my $expr = _parse_not($tokens, $pos_ref);
        return ClothCraft::Expression::Not->new($expr);
    }
    return _parse_primary($tokens, $pos_ref);
}

sub _parse_primary ($tokens, $pos_ref) {
    croak 'Unexpected end of expression' if $$pos_ref >= scalar @$tokens;

    # 括弧
    if ($tokens->[$$pos_ref] eq '(') {
        $$pos_ref++;
        my $expr = _parse_or($tokens, $pos_ref);
        croak "Expected ')'" unless $$pos_ref < scalar @$tokens && $tokens->[$$pos_ref] eq ')';
        $$pos_ref++;
        return $expr;
    }

    # comparison: value OP value
    my $left = _parse_value($tokens, $pos_ref);
    croak 'Expected comparison operator' if $$pos_ref >= scalar @$tokens;

    my $op = $tokens->[$$pos_ref];
    croak "Unknown operator: $op"
        unless $op =~ /\A(?:>=|<=|>|<|==|!=|eq|ne)\z/;
    $$pos_ref++;

    my $right = _parse_value($tokens, $pos_ref);
    return ClothCraft::Expression::Comparison->new($left, $op, $right);
}

sub _parse_value ($tokens, $pos_ref) {
    croak 'Unexpected end of expression' if $$pos_ref >= scalar @$tokens;
    my $token = $tokens->[$$pos_ref];
    $$pos_ref++;

    # クォート文字列
    if ($token =~ /\A"(.*)"\z/) {
        return ClothCraft::Expression::Literal->new($1);
    }
    # 数値
    if ($token =~ /\A[0-9]+(?:\.[0-9]+)?\z/) {
        return ClothCraft::Expression::Literal->new($token + 0);
    }
    # 変数名
    if ($token =~ /\A[A-Za-z_]\w*\z/) {
        return ClothCraft::Expression::Variable->new($token);
    }

    croak "Invalid value: $token";
}

1;
