use strict;
use warnings;
use Plack::Request;
use JSON::PP;
use HTTP::Tiny;
use Data::Dumper;
use Digest::SHA qw(hmac_sha256_hex);

my $SLACK_BOT_TOKEN = $ENV{SLACK_BOT_TOKEN} // 'xoxb-dummy-token';
my $SLACK_SIGNING_SECRET = $ENV{SLACK_SIGNING_SECRET} // 'dummy-secret';

sub verify_signature {
    my ($req, $secret) = @_;
    my $signature = $req->header('X-Slack-Signature') || '';
    my $timestamp = $req->header('X-Slack-Request-Timestamp') || 0;
    my $body      = $req->content;

    if (abs(time - $timestamp) > 300) {
        return 0;
    }

    my $basestring = "v0:$timestamp:$body";
    my $my_signature = 'v0=' . hmac_sha256_hex($basestring, $secret);

    return $signature eq $my_signature;
}

sub send_slack_message {
    my ($channel, $text) = @_;
    my $ua = HTTP::Tiny->new;
    $ua->post(
        'https://slack.com/api/chat.postMessage',
        {
            headers => { 
                'Authorization' => "Bearer $SLACK_BOT_TOKEN",
                'Content-Type'  => 'application/json; charset=utf-8',
            },
            content => encode_json({
                channel => $channel,
                text    => $text,
            }),
        }
    );
}

my $app = sub {
    my $env = shift;
    my $req = Plack::Request->new($env);

    if ($req->method eq 'POST') {
        # 署名検証（本番では有効にする）
        # return [401, [], ['Unauthorized']] unless verify_signature($req, $SLACK_SIGNING_SECRET);

        my $json = $req->content;
        my $payload = eval { decode_json($json) };
        return [400, [], ['Bad Request']] unless $payload;

        # URL検証
        if ($payload->{type} && $payload->{type} eq 'url_verification') {
            return [200, ['Content-Type' => 'text/plain'], [ $payload->{challenge} ]];
        }

        # メッセージイベント処理
        if ($payload->{event} && $payload->{event}->{type} eq 'message' && !$payload->{event}->{bot_id}) {
            my $channel = $payload->{event}->{channel};
            my $text    = $payload->{event}->{text};
            send_slack_message($channel, "受け取りました: $text");
        }

        return [200, [], ['OK']];
    }

    return [404, [], ['Not Found']];
};
