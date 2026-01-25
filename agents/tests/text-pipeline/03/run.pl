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
        '2026-01-30 10:00:15 ERROR: Database timeout',
        '2026-01-30 10:00:05 ERROR: Connection failed',
        '2026-01-30 10:00:15 ERROR: Database timeout',
        '2026-01-30 10:00:20 INFO: Connection restored',
        '2026-01-30 10:00:05 ERROR: Connection failed',
    );

    my $pipeline = PipelineBuilder->new()
        ->grep('ERROR')
        ->sort()
        ->uniq()
        ->build();

    my $result = $pipeline->process(\@log_lines);

    say "=== ERROR行をソートして重複除去 ===";
    say $_ for @$result;
}
