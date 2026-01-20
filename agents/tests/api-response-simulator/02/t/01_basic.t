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

# テスト開始
my $api = MockApi->new;
ok($api, 'MockApi instance created');

# 各シナリオをテスト
my @scenarios = (
    { name => 'success', status => '200 OK', has_data => 1 },
    { name => 'not_found', status => '404 Not Found', error_code => 'NOT_FOUND' },
    { name => 'unauthorized', status => '401 Unauthorized', error_code => 'UNAUTHORIZED' },
    { name => 'validation_error', status => '400 Bad Request', error_code => 'VALIDATION_ERROR' },
    { name => 'server_error', status => '500 Internal Server Error', error_code => 'INTERNAL_ERROR' },
);

for my $scenario (@scenarios) {
    my $name = $scenario->{name};
    my $response_text = $api->send_request($name);
    ok($response_text, "Response received for $name");
    
    like($response_text, qr/HTTP\/1\.1 $scenario->{status}/, "Status is correct for $name");
    
    my ($body) = $response_text =~ /\n\n(.+)$/s;
    my $data = decode_json($body);
    
    if ($scenario->{has_data}) {
        is($data->{success}, JSON::true, "Success flag is true for $name");
        ok(exists $data->{data}, "Data exists for $name");
    } else {
        is($data->{success}, JSON::false, "Success flag is false for $name");
        is($data->{code}, $scenario->{error_code}, "Error code is correct for $name");
    }
}

# 不正なシナリオでdieすることを確認
eval { $api->send_request('invalid_scenario') };
ok($@, 'Dies on invalid scenario');
like($@, qr/Unknown scenario/, 'Error message is correct');

done_testing();
