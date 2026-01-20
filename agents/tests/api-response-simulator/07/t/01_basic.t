#!/usr/bin/env perl
use v5.36;
use Test::More;
use JSON qw(decode_json);

package ResponseRole {
    use Moo::Role;
    requires 'render';
}

package SuccessResponse {
    use Moo;
    use JSON qw(encode_json);
    with 'ResponseRole';

    has data => (is => 'ro', required => 1);

    sub render($self) {
        my $body = encode_json({
            success => JSON::true,
            message => 'リクエストが正常に処理されました',
            data    => $self->data,
        });
        return "HTTP/1.1 200 OK\nContent-Type: application/json\n\n$body";
    }
}

package ErrorResponse {
    use Moo;
    use JSON qw(encode_json);
    with 'ResponseRole';

    has status     => (is => 'ro', required => 1);
    has error_code => (is => 'ro', required => 1);
    has message    => (is => 'ro', required => 1);

    sub render($self) {
        my $body = encode_json({
            success => JSON::false,
            error   => $self->message,
            code    => $self->error_code,
        });
        return sprintf(
            "HTTP/1.1 %s\nContent-Type: application/json\n\n%s",
            $self->status, $body,
        );
    }
}

package RateLimitResponse {
    use Moo;
    use JSON qw(encode_json);
    with 'ResponseRole';

    has retry_after => (is => 'ro', default => sub { 60 });

    sub render($self) {
        my $body = encode_json({
            success     => JSON::false,
            error       => 'リクエスト数が上限を超えました',
            code        => 'RATE_LIMIT_EXCEEDED',
            retry_after => $self->retry_after,
        });
        return sprintf(
            "HTTP/1.1 429 Too Many Requests\nContent-Type: application/json\nRetry-After: %d\n\n%s",
            $self->retry_after, $body,
        );
    }
}

package ServerErrorResponse {
    use Moo;
    use JSON qw(encode_json);
    with 'ResponseRole';

    has error_id => (is => 'ro', required => 1);

    sub render($self) {
        my $body = encode_json({
            success  => JSON::false,
            error    => 'サーバー内部エラーが発生しました',
            code     => 'INTERNAL_ERROR',
            error_id => $self->error_id,
        });
        return "HTTP/1.1 500 Internal Server Error\nContent-Type: application/json\n\n$body";
    }
}

package Scenario {
    use Moo;
    use Time::HiRes qw(gettimeofday tv_interval);

    sub create_response($self) {
        die "create_response must be implemented by subclass";
    }

    sub scenario_name($self) {
        my $class = ref($self);
        $class =~ s/Scenario$//;
        return $class;
    }

    sub log_request($self) {
        my $name = $self->scenario_name;
        my $timestamp = localtime();
        say STDERR "[$timestamp] Processing: $name";
    }

    sub log_complete($self, $elapsed) {
        my $name = $self->scenario_name;
        my $timestamp = localtime();
        say STDERR "[$timestamp] Completed: $name (${elapsed}ms)";
    }

    sub execute($self) {
        my $start = [gettimeofday];
        $self->log_request;
        my $response = $self->create_response;
        my $elapsed = int(tv_interval($start) * 1000);
        $self->log_complete($elapsed);
        return $response->render;
    }
}

package SuccessScenario {
    use Moo;
    extends 'Scenario';

    sub create_response($self) {
        return SuccessResponse->new(
            data => { id => 1, name => 'サンプルアイテム' },
        );
    }
}

package NotFoundScenario {
    use Moo;
    extends 'Scenario';

    sub create_response($self) {
        return ErrorResponse->new(
            status     => '404 Not Found',
            error_code => 'NOT_FOUND',
            message    => 'リソースが見つかりません',
        );
    }
}

package RateLimitScenario {
    use Moo;
    extends 'Scenario';

    has retry_after => (is => 'ro', default => sub { 60 });

    sub create_response($self) {
        return RateLimitResponse->new(
            retry_after => $self->retry_after,
        );
    }
}

package ServerErrorScenario {
    use Moo;
    extends 'Scenario';

    sub create_response($self) {
        my $error_id = sprintf("ERR-%06d", int(rand(1000000)));
        return ServerErrorResponse->new(error_id => $error_id);
    }
}

# テスト開始
my $rate_limit = RateLimitResponse->new(retry_after => 120);
ok($rate_limit, 'RateLimitResponse instance created');
my $rate_output = $rate_limit->render;
like($rate_output, qr/429 Too Many Requests/, 'RateLimitResponse has 429 status');
like($rate_output, qr/Retry-After: 120/, 'RateLimitResponse has Retry-After header');

my ($rate_body) = $rate_output =~ /\n\n(.+)$/s;
my $rate_data = decode_json($rate_body);
is($rate_data->{retry_after}, 120, 'retry_after is in body');

my $server_error = ServerErrorResponse->new(error_id => 'TEST-123');
ok($server_error, 'ServerErrorResponse instance created');
my $server_output = $server_error->render;
like($server_output, qr/500 Internal Server Error/, 'ServerErrorResponse has 500 status');

my ($server_body) = $server_output =~ /\n\n(.+)$/s;
my $server_data = decode_json($server_body);
is($server_data->{error_id}, 'TEST-123', 'error_id is in body');

for my $scenario_class (qw(RateLimitScenario ServerErrorScenario)) {
    my $scenario = $scenario_class->new;
    ok($scenario, "$scenario_class instance created");
    my $output = $scenario->execute;
    ok($output, "$scenario_class produces output");
}

done_testing();
