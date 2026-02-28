use v5.36;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";

use PawsHeart::Animal::Dog;
use PawsHeart::Animal::Cat;
use PawsHeart::Animal::Bird;
use PawsHeart::Clinic;

my $clinic = PawsHeart::Clinic->new;

# --- 犬のテスト ---
my $dog = PawsHeart::Animal::Dog->new(
    name => 'ポチ', breed => '柴犬', weight => 10
);
{
    my $report = $clinic->generate_report($dog);
    like($report, qr/犬: ポチ/, '犬の診察レポートが生成される');
    like($report, qr/柴犬/, '犬種が含まれる');

    my $schedule = $clinic->calc_vaccine_schedule($dog);
    is($schedule->{animal}, 'ポチ', '犬のワクチンスケジュール');
    is(scalar $schedule->{vaccines}->@*, 2, '犬は2種のワクチン');

    my $diet = $clinic->generate_diet_plan($dog);
    like($diet, qr/200g/, '体重10kgの犬には200gのフード');
}

# --- 猫のテスト ---
my $cat = PawsHeart::Animal::Cat->new(
    name => 'タマ', breed => 'スコティッシュフォールド', is_indoor => 1
);
{
    my $report = $clinic->generate_report($cat);
    like($report, qr/猫: タマ/, '猫の診察レポートが生成される');
    like($report, qr/室内飼い/, '室内飼いが反映される');

    my $schedule = $clinic->calc_vaccine_schedule($cat);
    is(scalar $schedule->{vaccines}->@*, 1, '猫は1種のワクチン');

    my $diet = $clinic->generate_diet_plan($cat);
    like($diet, qr/60g/, '室内飼いの猫には60gのフード');
}

# --- 鳥のテスト ---
my $bird = PawsHeart::Animal::Bird->new(
    name => 'ピーちゃん', species => 'セキセイインコ', can_fly => 1
);
{
    my $report = $clinic->generate_report($bird);
    like($report, qr/鳥: ピーちゃん/, '鳥の診察レポートが生成される');
    like($report, qr/飛行可能/, '飛行能力が反映される');

    my $schedule = $clinic->calc_vaccine_schedule($bird);
    is(scalar $schedule->{vaccines}->@*, 0, '鳥はワクチン不要');
    like($schedule->{note}, qr/糞便検査/, '鳥には糞便検査推奨');

    my $diet = $clinic->generate_diet_plan($bird);
    like($diet, qr/シード類/, '鳥はシード類中心');
}

# --- 未対応の動物でエラー ---
{
    my $unknown = bless {}, 'PawsHeart::Animal::Hamster';
    eval { $clinic->generate_report($unknown) };
    like($@, qr/未対応の動物/, '未対応の動物はエラーになる');
}

done_testing;
