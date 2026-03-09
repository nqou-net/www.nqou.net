use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/lib";

use MyCompany::Database;
use MyCompany::ReportGeneratorLegacy;
use MyCompany::ReportGeneratorRefactored;
use MockDatabase;

subtest 'Before (Singleton): 状態の漏洩（テスト間での干渉）' => sub {
    my $generator = MyCompany::ReportGeneratorLegacy->new();
    
    # 正常な利用
    my $report1 = $generator->generate(1);
    is $report1, "Report for Alice", "Normally fetches Alice";
    
    # 並列で走るバッチ処理や他の不吉なテストコードが、Singletonの状態を汚染したと仮定
    my $db = MyCompany::Database->get_instance();
    $db->overwrite_data({ 1 => { name => "Hacked Alice" } });
    
    # その後、全く関係ないはずのジェネレータの出力がおかしくなる（グローバル変数の恐怖）
    my $report2 = $generator->generate(1);
    is $report2, "Report for Hacked Alice", "Singleton state leaked! Output is corrupted.";
};

subtest 'After (Dependency Injection): モックによる独立した安全なテスト' => sub {
    # 1. 本番用の（ように振る舞う）DBを渡すケース
    my $real_db_like = bless { data => { 1 => { name => "Alice" } } }, 'MyCompany::Database';
    my $generator1 = MyCompany::ReportGeneratorRefactored->new(db => $real_db_like);
    is $generator1->generate(1), "Report for Alice", "Generator works with real DB instance";
    
    # 2. テスト用に完全に独立したMockDBを渡すケース
    # 完全に隔離されているため、並列テストでも絶対に状態が混ざらない
    my $mock_db = MockDatabase->new(mock_data => { 99 => { name => "Test User" } });
    my $generator2 = MyCompany::ReportGeneratorRefactored->new(db => $mock_db);
    
    is $generator2->generate(99), "Report for Test User", "Generator successfully uses isolated Mock DB!";
};

done_testing();
