use strict;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

# === After: Pipeline（Pipes and Filters） ===
# 各処理ステップが独立したフィルタークラスとして分離され、
# パイプラインがフィルターのチェーンとしてデータを流す。

# --- CsvPipeline（パイプライン本体） ---
package CsvPipeline {
    use Moo;

    has filters => (is => 'ro', required => 1);

    sub execute ($self, $data) {
        my $result = $data;
        for my $filter (@{ $self->filters }) {
            $result = $filter->process($result);
        }
        return $result;
    }
}

# --- Filter::SkipBlankLines ---
package Filter::SkipBlankLines {
    use Moo;
    sub process ($self, $lines) {
        return [ grep { $_ !~ /^\s*$/ } @$lines ];
    }
}

# --- Filter::SkipHeader ---
package Filter::SkipHeader {
    use Moo;
    sub process ($self, $lines) {
        return [ @{$lines}[1 .. $#$lines] ];
    }
}

# --- Filter::ParseColumns ---
package Filter::ParseColumns {
    use Moo;
    sub process ($self, $lines) {
        return [ map { [ split /,/, $_ ] } @$lines ];
    }
}

# --- Filter::ValidateColumnCount ---
package Filter::ValidateColumnCount {
    use Moo;
    has expected => (is => 'ro', default => 3);
    sub process ($self, $rows) {
        return [ grep { scalar @$_ == $self->expected } @$rows ];
    }
}

# --- Filter::TransformFields ---
package Filter::TransformFields {
    use Moo;
    sub process ($self, $rows) {
        return [ map {
            my ($name, $amount, $date) = @$_;
            $name   =~ s/^\s+|\s+$//g;
            $amount =~ s/[^0-9]//g;
            $date   =~ s/^\s+|\s+$//g;
            { name => $name, amount => int($amount), date => $date };
        } @$rows ];
    }
}

# --- Filter::ValidateAmount ---
package Filter::ValidateAmount {
    use Moo;
    sub process ($self, $records) {
        return [ grep { $_->{amount} > 0 } @$records ];
    }
}

# --- Filter::CalculateTotal ---
package Filter::CalculateTotal {
    use Moo;
    sub process ($self, $records) {
        my $total = 0;
        $total += $_->{amount} for @$records;
        return { records => $records, total => $total };
    }
}

1;
