#!/usr/bin/env perl
use v5.36;
use Test::More;
use JSON qw(decode_json);

package ResponseRole {
    use Moo::Role;
    requires 'render';
}

package Response {
    use Moo;
    use JSON qw(encode_json);
    with 'ResponseRole';

    has status => (is => 'ro', required => 1);
    has content_type => (is => 'ro', default => sub { 'application/json' });
    has body => (is => 'ro', required => 1);

    sub render($self) {
        my $json_body = encode_json($self->body);
        return sprintf(
            "HTTP/1.1 %s\nContent-Type: %s\n\n%s",
            $self->status, $self->content_type, $json_body,
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
        return Response->new(
            status => '200 OK',
            body   => {
                success => JSON::true,
                message => 'リクエストが正常に処理されました',
                data    => { id => 1, name => 'サンプルアイテム' },
            },
        );
    }
}

package NotFoundScenario {
    use Moo;
    extends 'Scenario';

    sub create_response($self) {
        return Response->new(
            status => '404 Not Found',
            body   => {
                success => JSON::false,
                error   => 'リソースが見つかりません',
                code    => 'NOT_FOUND',
            },
        );
    }
}

# テスト開始
my $response = Response->new(
    status => '200 OK',
    body   => { test => 'data' },
);

ok($response->does('ResponseRole'), 'Response does ResponseRole');
can_ok($response, 'render');

my $success = SuccessScenario->new;
my $success_text = $success->execute;
ok($success_text, 'Success response received');

my $not_found = NotFoundScenario->new;
my $not_found_text = $not_found->execute;
ok($not_found_text, 'NotFound response received');

done_testing();
