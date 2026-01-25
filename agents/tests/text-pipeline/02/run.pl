#!/usr/bin/env perl
# 言語: perl
# バージョン: 5.36以上
# 依存: Moo

use v5.36;

# === Filter（基底クラス） ===
package Filter {
    use Moo;
    use experimental qw(signatures);

    has next_filter => (
        is        => 'ro',
        predicate => 'has_next_filter',
    );

    sub process ($self, $lines) {
        my $result = $self->apply($lines);
        
        if ($self->has_next_filter) {
            return $self->next_filter->process($result);
        }
        return $result;
    }

    sub apply ($self, $lines) {
        return $lines;
    }
}

# === GrepFilter ===
package GrepFilter {
    use Moo;
    use experimental qw(signatures);
    extends 'Filter';

    has pattern => (
        is       => 'ro',
        required => 1,
    );

    sub apply ($self, $lines) {
        my $pattern = $self->pattern;
        return [grep { /$pattern/ } @$lines];
    }
}

# === SortFilter ===
package SortFilter {
    use Moo;
    use experimental qw(signatures);
    extends 'Filter';

    sub apply ($self, $lines) {
        return [sort @$lines];
    }
}

# === UniqFilter ===
package UniqFilter {
    use Moo;
    use experimental qw(signatures);
    extends 'Filter';

    sub apply ($self, $lines) {
        my %seen;
        return [grep { !$seen{$_}++ } @$lines];
    }
}

# === メイン処理 ===
package main {
    my @log_lines = (
        '2026-01-30 10:00:15 ERROR: Database timeout',
        '2026-01-30 10:00:05 ERROR: Connection failed',
        '2026-01-30 10:00:15 ERROR: Database timeout',
        '2026-01-30 10:00:20 INFO: Connection restored',
        '2026-01-30 10:00:05 ERROR: Connection failed',
    );

    # パイプライン構築（逆順に作成する必要がある）
    my $uniq = UniqFilter->new();
    my $sort = SortFilter->new(next_filter => $uniq);
    my $grep = GrepFilter->new(
        pattern     => 'ERROR',
        next_filter => $sort,
    );

    my $result = $grep->process(\@log_lines);

    say "=== ERROR行をソートして重複除去 ===";
    say $_ for @$result;
}
