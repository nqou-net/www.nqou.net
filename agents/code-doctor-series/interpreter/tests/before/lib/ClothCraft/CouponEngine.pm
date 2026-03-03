package ClothCraft::CouponEngine;
use v5.36;

# 桐山のコード: 2年間マーケ部門に感謝されてきた最強のルールエンジン
# 管理画面からルール文字列を入力 → evalで動的に評価
# 「コード変更なしにルール追加！ 最強じゃないすか？」

sub new ($class) {
    return bless {
        rules => [],
    }, $class;
}

# ルールを追加
# format: { name => "ルール名", condition => "Perl式の文字列", discount => 500 }
sub add_rule ($self, %rule) {
    push $self->{rules}->@*, \%rule;
    return $self;
}

# カート情報からルールを評価して適用可能な割引を返す
# $context = { cart_total => 5000, member_rank => "gold", is_first_purchase => 0, ... }
sub evaluate ($self, $context) {
    my @applicable;

    for my $rule ($self->{rules}->@*) {
        my $condition = $rule->{condition};

        # 正規表現でコンテキスト変数を埋め込む
        # TODO: なんか不安だけど2年間動いてるから大丈夫...だろ
        my $expr = $condition;
        for my $key (keys $context->%*) {
            my $val = $context->{$key};
            if ($val =~ /^[0-9]+$/) {
                $expr =~ s/\b$key\b/$val/g;
            } else {
                $expr =~ s/\b$key\b/"$val"/g;  # 文字列はクォートで囲む
            }
        }

        # evalで評価！ これが俺の最強の武器
        my $result = eval $expr;  ## no critic -- 桐山は気にしない
        if ($@) {
            # エラーは「条件不一致」として処理
            # FIXME: ログくらい出したほうがいい気がするけど...まあいいか
            next;
        }

        if ($result) {
            push @applicable, {
                name     => $rule->{name},
                discount => $rule->{discount},
            };
        }
    }

    return \@applicable;
}

# 最大割引ルールを1つ返す（複数適用は考えない。桐山式シンプル設計）
sub best_discount ($self, $context) {
    my $applicable = $self->evaluate($context);
    return undef unless $applicable->@*;

    my @sorted = sort { $b->{discount} <=> $a->{discount} } $applicable->@*;
    return $sorted[0];
}

1;
