#!/usr/bin/env perl
# 言語: perl
# バージョン: 5.36以上
# 依存: Moo

use v5.36;

# === GrepFilter ===
package GrepFilter {
    use Moo;
    use experimental qw(signatures);

    has pattern => (
        is       => 'ro',
        required => 1,
    );

    has next_filter => (
        is        => 'ro',
        predicate => 'has_next_filter',
    );

    sub process ($self, $lines) {
        my $pattern = $self->pattern;
        my @filtered = grep { /$pattern/ } @$lines;
        
        if ($self->has_next_filter) {
            return $self->next_filter->process(\@filtered);
        }
        return \@filtered;
    }
}

# === メイン処理 ===
package main {
    # サンプルデータ
    my @log_lines = (
        '2026-01-30 10:00:01 INFO: Application started',
        '2026-01-30 10:00:05 ERROR: Connection failed',
        '2026-01-30 10:00:10 INFO: Retrying connection',
        '2026-01-30 10:00:15 ERROR: Database timeout',
        '2026-01-30 10:00:20 INFO: Connection restored',
    );

    # 単一フィルターの例
    my $single = GrepFilter->new(pattern => 'ERROR');
    my $result1 = $single->process(\@log_lines);
    
    say "=== ERRORを含む行 ===";
    say $_ for @$result1;

    say "";

    # 2つのフィルターを繋げる例
    my $second_filter = GrepFilter->new(pattern => 'timeout');
    my $first_filter = GrepFilter->new(
        pattern     => 'ERROR',
        next_filter => $second_filter,
    );

    my $result2 = $first_filter->process(\@log_lines);
    
    say "=== ERRORかつtimeoutを含む行 ===";
    say $_ for @$result2;
}
