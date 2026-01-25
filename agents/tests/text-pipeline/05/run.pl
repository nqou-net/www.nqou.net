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

# === TopNFilter ===
package TopNFilter {
    use Moo;
    use experimental qw(signatures);
    extends 'Filter';

    has n => (
        is      => 'ro',
        default => 10,
    );

    sub _clone_attributes ($self) {
        return (n => $self->n);
    }

    sub apply ($self, $lines) {
        my $n = $self->n;
        my @top = @$lines[0 .. ($n < @$lines ? $n - 1 : $#$lines)];
        return \@top;
    }
}

# === AccessLogParser ===
package AccessLogParser {
    use Moo;
    use experimental qw(signatures);
    extends 'Filter';

    my $LOG_PATTERN = qr{
        ^
        (\S+)           # IP
        \s+\S+\s+\S+    # ident, user
        \s+\[(.+?)\]    # datetime
        \s+"(\S+)\s+(\S+)\s+\S+"  # method, path
        \s+(\d+)        # status
        \s+(\d+|-)      # size
    }x;

    sub apply ($self, $lines) {
        my @result;
        
        for my $line (@$lines) {
            if ($line =~ $LOG_PATTERN) {
                push @result, {
                    ip       => $1,
                    datetime => $2,
                    method   => $3,
                    path     => $4,
                    status   => $5,
                    size     => $6 eq '-' ? 0 : $6,
                    raw      => $line,
                };
            }
        }
        
        return \@result;
    }
}

# === FieldFilter ===
package FieldFilter {
    use Moo;
    use experimental qw(signatures);
    extends 'Filter';

    has field => (
        is       => 'ro',
        required => 1,
    );

    sub _clone_attributes ($self) {
        return (field => $self->field);
    }

    sub apply ($self, $records) {
        my $field = $self->field;
        return [map { $_->{$field} } @$records];
    }
}

# === StatusFilter ===
package StatusFilter {
    use Moo;
    use experimental qw(signatures);
    extends 'Filter';

    has status => (
        is       => 'ro',
        required => 1,
    );

    sub _clone_attributes ($self) {
        return (status => $self->status);
    }

    sub apply ($self, $records) {
        my $status = $self->status;
        
        if ($status =~ /x/) {
            my $pattern = $status;
            $pattern =~ s/x/\\d/g;
            return [grep { $_->{status} =~ /^$pattern$/ } @$records];
        }
        
        return [grep { $_->{status} eq $status } @$records];
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

    sub parse_access_log ($self) {
        push $self->_filters->@*, AccessLogParser->new();
        return $self;
    }

    sub field ($self, $name) {
        push $self->_filters->@*, FieldFilter->new(field => $name);
        return $self;
    }

    sub status ($self, $code) {
        push $self->_filters->@*, StatusFilter->new(status => $code);
        return $self;
    }

    sub stats ($self) {
        push $self->_filters->@*, StatsFilter->new();
        return $self;
    }

    sub top ($self, $n = 10) {
        push $self->_filters->@*, TopNFilter->new(n => $n);
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
    my @access_log = (
        '192.168.1.1 - - [30/Jan/2026:10:00:01 +0900] "GET /index.html HTTP/1.1" 200 1234',
        '192.168.1.2 - - [30/Jan/2026:10:00:02 +0900] "GET /api/users HTTP/1.1" 200 567',
        '192.168.1.3 - - [30/Jan/2026:10:00:03 +0900] "GET /index.html HTTP/1.1" 200 1234',
        '192.168.1.1 - - [30/Jan/2026:10:00:04 +0900] "GET /api/users HTTP/1.1" 200 567',
        '192.168.1.2 - - [30/Jan/2026:10:00:05 +0900] "POST /api/login HTTP/1.1" 401 89',
        '192.168.1.4 - - [30/Jan/2026:10:00:06 +0900] "GET /index.html HTTP/1.1" 200 1234',
        '192.168.1.3 - - [30/Jan/2026:10:00:07 +0900] "GET /api/products HTTP/1.1" 500 0',
        '192.168.1.1 - - [30/Jan/2026:10:00:08 +0900] "GET /index.html HTTP/1.1" 200 1234',
        '192.168.1.5 - - [30/Jan/2026:10:00:09 +0900] "GET /api/users HTTP/1.1" 200 567',
        '192.168.1.2 - - [30/Jan/2026:10:00:10 +0900] "GET /favicon.ico HTTP/1.1" 404 0',
    );

    # Top 10 URL
    my $top_urls = PipelineBuilder->new()
        ->parse_access_log()
        ->field('path')
        ->stats()
        ->top(10)
        ->build();

    say "=== Top 10 URL ===";
    say $_ for $top_urls->process(\@access_log)->@*;

    say "";

    # IP別アクセス数
    my $top_ips = PipelineBuilder->new()
        ->parse_access_log()
        ->field('ip')
        ->stats()
        ->build();

    say "=== IP別アクセス数 ===";
    say $_ for $top_ips->process(\@access_log)->@*;

    say "";

    # 4xxエラー
    my $client_errors = PipelineBuilder->new()
        ->parse_access_log()
        ->status('4xx')
        ->field('path')
        ->stats()
        ->build();

    say "=== 4xx クライアントエラー ===";
    say $_ for $client_errors->process(\@access_log)->@*;
}
