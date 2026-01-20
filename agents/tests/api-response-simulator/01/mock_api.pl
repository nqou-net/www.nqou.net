#!/usr/bin/env perl
use v5.36;

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

my $api = MockApi->new;
say $api->send_request;
