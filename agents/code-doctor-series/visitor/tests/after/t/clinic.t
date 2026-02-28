use v5.36;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";

use PawsHeart::Animal::Dog;
use PawsHeart::Animal::Cat;
use PawsHeart::Animal::Bird;
use PawsHeart::Animal::Reptile;
use PawsHeart::Visitor::ReportVisitor;
use PawsHeart::Visitor::VaccineVisitor;
use PawsHeart::Visitor::DietVisitor;

# テストデータ
my $dog = PawsHeart::Animal::Dog->new(
    name => 'ポチ', breed => '柴犬', weight => 10
);
my $cat = PawsHeart::Animal::Cat->new(
    name => 'タマ', breed => 'スコティッシュフォールド', is_indoor => 1
);
my $bird = PawsHeart::Animal::Bird->new(
    name => 'ピーちゃん', species => 'セキセイインコ', can_fly => 1
);
my $reptile = PawsHeart::Animal::Reptile->new(
    name => 'カメ吉', species => 'ヒョウモントカゲモドキ', temperature => 28
);

# --- ReportVisitor ---
my $reporter = PawsHeart::Visitor::ReportVisitor->new;
{
    my $report = $dog->accept($reporter);
    like($report, qr/犬: ポチ/, '犬の診察レポート');
    like($report, qr/柴犬/, '犬種が含まれる');

    $report = $cat->accept($reporter);
    like($report, qr/猫: タマ/, '猫の診察レポート');
    like($report, qr/室内飼い/, '室内飼いが反映される');

    $report = $bird->accept($reporter);
    like($report, qr/鳥: ピーちゃん/, '鳥の診察レポート');
    like($report, qr/飛行可能/, '飛行能力が反映される');

    $report = $reptile->accept($reporter);
    like($report, qr/爬虫類: カメ吉/, '爬虫類の診察レポート（新種追加）');
    like($report, qr/28℃/, '適正温度が反映される');
}

# --- VaccineVisitor ---
my $vaccinator = PawsHeart::Visitor::VaccineVisitor->new;
{
    my $schedule = $dog->accept($vaccinator);
    is($schedule->{animal}, 'ポチ', '犬のワクチンスケジュール');
    is(scalar $schedule->{vaccines}->@*, 2, '犬は2種のワクチン');

    $schedule = $cat->accept($vaccinator);
    is(scalar $schedule->{vaccines}->@*, 1, '猫は1種のワクチン');

    $schedule = $bird->accept($vaccinator);
    is(scalar $schedule->{vaccines}->@*, 0, '鳥はワクチン不要');
    like($schedule->{note}, qr/糞便検査/, '鳥には糞便検査推奨');

    $schedule = $reptile->accept($vaccinator);
    is(scalar $schedule->{vaccines}->@*, 0, '爬虫類もワクチン不要');
    like($schedule->{note}, qr/寄生虫検査/, '爬虫類には寄生虫検査推奨');
}

# --- DietVisitor ---
my $dietitian = PawsHeart::Visitor::DietVisitor->new;
{
    my $diet = $dog->accept($dietitian);
    like($diet, qr/200g/, '体重10kgの犬には200gのフード');

    $diet = $cat->accept($dietitian);
    like($diet, qr/60g/, '室内飼いの猫には60gのフード');

    $diet = $bird->accept($dietitian);
    like($diet, qr/シード類/, '鳥はシード類中心');

    $diet = $reptile->accept($dietitian);
    like($diet, qr/28℃/, '爬虫類の適正温度が食事指導に含まれる');
}

# --- Visitor パターンの拡張性テスト ---
# 新しい操作を追加する場合: 新Visitorクラスを1つ足すだけ
# 既存の動物クラスは一切変更不要
{
    # 簡易的なHealthCheckVisitorをその場で定義
    my $checker = bless {}, 'HealthCheckVisitor';
    no strict 'refs';
    *{'HealthCheckVisitor::visit_dog'}     = sub ($self, $d) { 'healthy' };
    *{'HealthCheckVisitor::visit_cat'}     = sub ($self, $c) { 'healthy' };
    *{'HealthCheckVisitor::visit_bird'}    = sub ($self, $b) { 'needs_checkup' };
    *{'HealthCheckVisitor::visit_reptile'} = sub ($self, $r) { 'healthy' };
    use strict 'refs';

    is($dog->accept($checker), 'healthy', '新Visitorで犬をチェック');
    is($bird->accept($checker), 'needs_checkup', '新Visitorで鳥をチェック');
}

done_testing;
