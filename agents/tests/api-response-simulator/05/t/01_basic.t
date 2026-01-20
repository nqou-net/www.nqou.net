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

package Scenario {
    use Moo;

    sub create_response($self) {
        die "create_response must be implemented by subclass";
    }

    sub execute($self) {
        my $response = $self->create_response;
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

package UnauthorizedScenario {
    use Moo;
    extends 'Scenario';

    sub create_response($self) {
        return ErrorResponse->new(
            status     => '401 Unauthorized',
            error_code => 'UNAUTHORIZED',
            message    => '認証が必要です',
        );
    }
}

# テスト開始
my $success_resp = SuccessResponse->new(data => { test => 1 });
ok($success_resp->does('ResponseRole'), 'SuccessResponse does ResponseRole');
like($success_resp->render, qr/200 OK/, 'SuccessResponse renders 200');

my $error_resp = ErrorResponse->new(
    status => '404 Not Found',
    error_code => 'NOT_FOUND',
    message => 'テスト',
);
ok($error_resp->does('ResponseRole'), 'ErrorResponse does ResponseRole');
like($error_resp->render, qr/404 Not Found/, 'ErrorResponse renders 404');

for my $scenario_class (qw(SuccessScenario NotFoundScenario UnauthorizedScenario)) {
    my $scenario = $scenario_class->new;
    ok($scenario, "$scenario_class instance created");
    my $output = $scenario->execute;
    ok($output, "$scenario_class produces output");
    like($output, qr/HTTP\/1\.1/, "$scenario_class output has HTTP status line");
}

done_testing();
