package User {
    use v5.36;
    use Moo;
    has name => (is => 'ro');
    has email => (is => 'ro');
}

use Test::More;

use_ok('PointService::Role');
use_ok('PointService::Base');
use_ok('PointService::Decorator');
use_ok('PointService::WithLog');
use_ok('PointService::WithNotification');
use_ok('PointService::WithDoublePoint');

my $user = User->new(name => 'Haruka', email => 'haruka@example.com');

# 実行時の標準出力をキャプチャしてテストする
my $output = '';
open my $out_fh, '>', \$output;
my $old_fh = select $out_fh;

my $service = PointService::WithLog->new(
    inner => PointService::WithNotification->new(
        inner => PointService::WithDoublePoint->new(
            inner => PointService::Base->new()
        )
    )
);

$service->add_points($user, 100);

select $old_fh;
close $out_fh;

my $expected = <<'END_EXPECTED';
[LOG] Start adding points...
[CAMPAIGN] Points doubled: 100 -> 200
[SYSTEM] 200 points added to Haruka
[MAIL] Sent notification to haruka@example.com
[LOG] End adding points.
END_EXPECTED

is($output, $expected, "Output matches decorator order");

done_testing();
