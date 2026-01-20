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

    sub create_response($self, $scenario) {
        if ($scenario eq 'success') {
            return Response->new(
                status => '200 OK',
                body   => {
                    success => JSON::true,
                    message => 'リクエストが正常に処理されました',
                    data    => { id => 1, name => 'サンプルアイテム' },
                },
            );
        }
        elsif ($scenario eq 'not_found') {
            return Response->new(
                status => '404 Not Found',
                body   => {
                    success => JSON::false,
                    error   => 'リソースが見つかりません',
                    code    => 'NOT_FOUND',
                },
            );
        }
        elsif ($scenario eq 'unauthorized') {
            return Response->new(
                status => '401 Unauthorized',
                body   => {
                    success => JSON::false,
                    error   => '認証が必要です',
                    code    => 'UNAUTHORIZED',
                },
            );
        }
        elsif ($scenario eq 'validation_error') {
            return Response->new(
                status => '400 Bad Request',
                body   => {
                    success => JSON::false,
                    error   => '入力データが不正です',
                    code    => 'VALIDATION_ERROR',
                    details => [
                        { field => 'email', message => 'メールアドレスの形式が正しくありません' },
                    ],
                },
            );
        }
        elsif ($scenario eq 'server_error') {
            return Response->new(
                status => '500 Internal Server Error',
                body   => {
                    success => JSON::false,
                    error   => 'サーバー内部エラーが発生しました',
                    code    => 'INTERNAL_ERROR',
                },
            );
        }
        else {
            die "Unknown scenario: $scenario";
        }
    }

    sub send_request($self, $scenario = 'success') {
        my $response = $self->create_response($scenario);
        return $response->render;
    }
}

my $api = MockApi->new;
for my $scenario (qw(success not_found unauthorized validation_error server_error)) {
    say "=== $scenario ===";
    say $api->send_request($scenario);
    say "";
}
