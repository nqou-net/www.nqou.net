#!/usr/bin/env perl
# 言語: perl
# バージョン: 5.36以上
# 依存: Moo

use v5.36;
use File::Find qw(find);

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

# === Pipeline::PluginLoader ===
package Pipeline::PluginLoader {
    use Moo;
    use experimental qw(signatures);

    has plugin_dirs => (
        is      => 'ro',
        default => sub { ['./plugins'] },
    );

    has _loaded => (
        is      => 'ro',
        default => sub { {} },
    );

    sub load_all ($self) {
        my @plugins;
        
        for my $dir ($self->plugin_dirs->@*) {
            next unless -d $dir;
            
            find(sub {
                return unless /\.pm$/;
                my $file = $File::Find::name;
                push @plugins, $self->load_plugin($file);
            }, $dir);
        }
        
        return @plugins;
    }

    sub load_plugin ($self, $file) {
        return $self->_loaded->{$file} if exists $self->_loaded->{$file};
        
        my $package = $self->_file_to_package($file);
        
        eval { require $file };
        if ($@) {
            warn "Failed to load plugin $file: $@";
            return;
        }
        
        $self->_loaded->{$file} = $package;
        return $package;
    }

    sub _file_to_package ($self, $file) {
        my $package = $file;
        $package =~ s{^\./plugins/}{};
        $package =~ s{/}{::}g;
        $package =~ s{\.pm$}{};
        return "Pipeline::Plugin::$package";
    }
}

# === インラインプラグイン（デモ用） ===
package Pipeline::Plugin::JsonLogParser {
    use Moo;
    use experimental qw(signatures);
    use JSON::PP qw(decode_json);
    extends 'Filter';

    sub apply ($self, $lines) {
        my @result;
        
        for my $line (@$lines) {
            eval {
                my $data = decode_json($line);
                push @result, $data;
            };
            warn "Failed to parse JSON: $line" if $@;
        }
        
        return \@result;
    }
}

package Pipeline::Plugin::UpperCaseFilter {
    use Moo;
    use experimental qw(signatures);
    extends 'Filter';

    sub apply ($self, $lines) {
        return [map { uc($_) } @$lines];
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

    has plugin_loader => (
        is      => 'ro',
        lazy    => 1,
        builder => sub { Pipeline::PluginLoader->new() },
    );

    sub use_plugin ($self, $name, %args) {
        my $package = "Pipeline::Plugin::$name";
        
        eval "require $package" unless $package->can('new');
        die "Failed to load plugin $name: $@" if $@ && !$package->can('new');
        
        push $self->_filters->@*, $package->new(%args);
        return $self;
    }

    sub field ($self, $name) {
        push $self->_filters->@*, FieldFilter->new(field => $name);
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
    my @json_logs = (
        '{"timestamp": "2026-01-30T10:00:01", "level": "ERROR", "message": "Connection failed"}',
        '{"timestamp": "2026-01-30T10:00:02", "level": "INFO", "message": "Retrying"}',
        '{"timestamp": "2026-01-30T10:00:03", "level": "ERROR", "message": "Timeout"}',
    );

    my $pipeline = PipelineBuilder->new()
        ->use_plugin('JsonLogParser')
        ->field('message')
        ->use_plugin('UpperCaseFilter')
        ->build();

    my $result = $pipeline->process(\@json_logs);

    say "=== 大文字変換したメッセージ ===";
    say $_ for @$result;
}
