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

    sub with_next ($self, $next) {
        return ref($self)->new(
            $self->_clone_attributes(),
            next_filter => $next,
        );
    }

    sub _clone_attributes ($self) {
        return ();
    }

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

    sub _clone_attributes ($self) {
        return (pattern => $self->pattern);
    }

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

# === CountFilter ===
package CountFilter {
    use Moo;
    use experimental qw(signatures);
    extends 'Filter';

    sub apply ($self, $lines) {
        my $count = scalar @$lines;
        return ["$count lines"];
    }
}

# === StatsFilter ===
package StatsFilter {
    use Moo;
    use experimental qw(signatures);
    extends 'Filter';

    sub apply ($self, $lines) {
        my %count;
        $count{$_}++ for @$lines;
        
        my @result;
        for my $line (sort { $count{$b} <=> $count{$a} } keys %count) {
            push @result, sprintf("%4d %s", $count{$line}, $line);
        }
        
        return \@result;
    }
}

# === ExtractFilter ===
package ExtractFilter {
    use Moo;
    use experimental qw(signatures);
    extends 'Filter';

    has pattern => (
        is       => 'ro',
        required => 1,
    );

    sub _clone_attributes ($self) {
        return (pattern => $self->pattern);
    }

    sub apply ($self, $lines) {
        my $pattern = $self->pattern;
        my @result;
        
        for my $line (@$lines) {
            if ($line =~ /$pattern/) {
                push @result, $1 // $&;
            }
        }
        
        return \@result;
    }
}

# === PipelineBuilder ===
package PipelineBuilder {
    use Moo;
    use experimental qw(signatures);

    has _filters => (
        is      => 'ro',
        default => sub { [] },
    );

    sub grep ($self, $pattern) {
        push $self->_filters->@*, GrepFilter->new(pattern => $pattern);
        return $self;
    }

    sub sort ($self) {
        push $self->_filters->@*, SortFilter->new();
        return $self;
    }

    sub uniq ($self) {
        push $self->_filters->@*, UniqFilter->new();
        return $self;
    }

    sub count ($self) {
        push $self->_filters->@*, CountFilter->new();
        return $self;
    }

    sub stats ($self) {
        push $self->_filters->@*, StatsFilter->new();
        return $self;
    }

    sub extract ($self, $pattern) {
        push $self->_filters->@*, ExtractFilter->new(pattern => $pattern);
        return $self;
    }

    sub build ($self) {
        my @filters = $self->_filters->@*;
        return undef unless @filters;
        
        my $pipeline = pop @filters;
        while (my $filter = pop @filters) {
            $pipeline = $filter->with_next($pipeline);
        }
        
        return $pipeline;
    }
}

# === メイン処理 ===
package main {
    my @log_lines = (
        '2026-01-30 10:00:05 ERROR: Connection failed',
        '2026-01-30 10:00:10 INFO: Retrying connection',
        '2026-01-30 10:00:15 ERROR: Database timeout',
        '2026-01-30 10:00:20 ERROR: Connection failed',
        '2026-01-30 10:00:25 INFO: Connection restored',
        '2026-01-30 10:00:30 ERROR: Database timeout',
        '2026-01-30 10:00:35 ERROR: Database timeout',
    );

    # ERRORの行数をカウント
    my $count_pipeline = PipelineBuilder->new()
        ->grep('ERROR')
        ->count()
        ->build();

    say "=== ERROR行数 ===";
    say $_ for $count_pipeline->process(\@log_lines)->@*;

    say "";

    # エラーメッセージ部分だけを抽出して集計
    my $extract_pipeline = PipelineBuilder->new()
        ->grep('ERROR')
        ->extract('ERROR: (.+)')
        ->stats()
        ->build();

    say "=== エラー種類別集計 ===";
    say $_ for $extract_pipeline->process(\@log_lines)->@*;
}
