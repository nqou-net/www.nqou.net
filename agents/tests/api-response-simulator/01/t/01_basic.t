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

package MockApi {
    use Moo;

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

    sub send_request($self) {
        my $response = $self->create_response;
        return $response->render;
    }
}

# テスト開始
my $api = MockApi->new;
ok($api, 'MockApi instance created');

my $response_text = $api->send_request;
ok($response_text, 'Response received');

like($response_text, qr/HTTP\/1\.1 200 OK/, 'Status line is correct');
like($response_text, qr/Content-Type: application\/json/, 'Content-Type header is correct');

# JSONボディの検証
my ($body) = $response_text =~ /\n\n(.+)$/s;
my $data = decode_json($body);

is($data->{success}, JSON::true, 'Success flag is true');
is($data->{message}, 'リクエストが正常に処理されました', 'Message is correct');
is($data->{data}{id}, 1, 'Data ID is 1');
is($data->{data}{name}, 'サンプルアイテム', 'Data name is correct');

done_testing();
