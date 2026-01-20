#!/usr/bin/env perl
use v5.36;
use Test::More;
use JSON qw(decode_json);

package Response {
    use Moo;
    use JSON qw(encode_json);

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
my $success = SuccessScenario->new;
ok($success, 'SuccessScenario instance created');
isa_ok($success, 'Scenario', 'SuccessScenario extends Scenario');

my $success_text = $success->execute;
ok($success_text, 'Success response received');
like($success_text, qr/HTTP\/1\.1 200 OK/, 'Success status is correct');

my ($success_body) = $success_text =~ /\n\n(.+)$/s;
my $success_data = decode_json($success_body);
is($success_data->{success}, JSON::true, 'Success flag is true');

my $not_found = NotFoundScenario->new;
ok($not_found, 'NotFoundScenario instance created');
isa_ok($not_found, 'Scenario', 'NotFoundScenario extends Scenario');

my $not_found_text = $not_found->execute;
ok($not_found_text, 'NotFound response received');
like($not_found_text, qr/HTTP\/1\.1 404 Not Found/, 'NotFound status is correct');

my ($not_found_body) = $not_found_text =~ /\n\n(.+)$/s;
my $not_found_data = decode_json($not_found_body);
is($not_found_data->{success}, JSON::false, 'Success flag is false for error');
is($not_found_data->{code}, 'NOT_FOUND', 'Error code is correct');

# Scenarioクラスのcreate_responseが実装されていないことを確認
my $base = Scenario->new;
eval { $base->create_response };
ok($@, 'Base Scenario dies when create_response is called');
like($@, qr/must be implemented by subclass/, 'Error message is correct');

done_testing();
