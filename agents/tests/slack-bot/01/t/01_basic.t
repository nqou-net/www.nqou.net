use strict;
use warnings;
use Test::More;
use Plack::Test;
use HTTP::Request::Common;
use JSON::PP;

# Load the app
my $app = do './app.psgi' or die "Could not load app.psgi: $@";

test_psgi $app, sub {
    my $cb = shift;

    # Case 1: URL Verification
    my $res = $cb->(POST '/', 
        Content_Type => 'application/json',
        Content => encode_json({
            type => 'url_verification',
            challenge => 'challenge-code-123',
        })
    );
    is $res->code, 200, 'URL Verification status 200';
    is $res->content, 'challenge-code-123', 'URL Verification challenge returned';

    # Case 2: Message Event
    # Note: send_slack_message uses HTTP::Tiny to make external request.
    # We are not mocking it here, so it will fail or try to connect. 
    # For this verification, we just check if it runs without crashing.
    # To truly test, we should mock HTTP::Tiny, but this is a simple verification.
    
    # We can mock HTTP::Tiny locally
    no warnings 'redefine';
    local *HTTP::Tiny::post = sub { return { success => 1 } };
    
    $res = $cb->(POST '/',
        Content_Type => 'application/json',
        Content => encode_json({
            event => {
                type => 'message',
                text => 'Hello',
                channel => 'C123',
            }
        })
    );
    is $res->code, 200, 'Message Event status 200';
};

done_testing;
