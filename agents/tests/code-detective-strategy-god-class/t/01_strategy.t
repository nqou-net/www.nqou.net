#!/usr/bin/env perl
use v5.34;
use warnings;
use utf8;
use Test::More;
my $builder = Test::More->builder;
binmode $builder->output,         ":utf8";
binmode $builder->failure_output, ":utf8";
binmode $builder->todo_output,    ":utf8";
use FindBin;
use lib "$FindBin::Bin/../lib";

subtest 'コード例1 - 問題版 (God Class)' => sub {
    require 'before_god_class.pl';
    
    my $processor = DataProcessor->new;
    
    # CSVの正常系
    my $csv_out = eval { $processor->process_everything('csv', { name => 'Holmes', age => 35 }) };
    is $@, '', 'CSV処理が成功すること';
    is $csv_out, 'CSV Output: Holmes,35', 'CSVの出力内容が正しいこと';
    
    # JSONの正常系
    my $json_out = eval { $processor->process_everything('json', { id => 42, value => 'Mystery' }) };
    is $@, '', 'JSON処理が成功すること';
    is $json_out, 'JSON Output: {"id":42,"value":"Mystery"}', 'JSONの出力内容が正しいこと';

    # XMLの正常系
    my $xml_out = eval { $processor->process_everything('xml', { root => 'data', content => 'Secret' }) };
    is $@, '', 'XML処理が成功すること';
    is $xml_out, 'XML Output: <data>Secret</data>', 'XMLの出力内容が正しいこと';

    # 未知のフォーマット（異常系）
    eval { $processor->process_everything('yaml', { some => 'data' }) };
    like $@, qr/Unknown type: yaml/, '未知のフォーマットは例外が出ること';
};

subtest 'コード例2 - 改善版 (Strategy)' => sub {
    require 'after_strategy.pl';

    # 1. 各Strategyの単体テストが容易になることを示す
    subtest '各Strategy単体の動作確認' => sub {
        my $csv = Processor::Csv->new;
        is $csv->process({ name => 'Watson', age => 30 }), 'CSV Output: Watson,30', 'CSV単体の処理';
        
        my $json = Processor::Json->new;
        is $json->process({ id => 99, value => 'Code' }), 'JSON Output: {"id":99,"value":"Code"}', 'JSON単体の処理';
    };

    # 2. Contextを経由したテスト
    subtest 'DataProcessor(Context)の動作確認' => sub {
        my $processor = DataProcessor->new;
        my $xml = Processor::Xml->new;
        
        my $result = eval { $processor->execute($xml, { root => 'msg', content => 'Hello' }) };
        is $@, '', 'Context経由の実行が成功すること';
        is $result, 'XML Output: <msg>Hello</msg>', '出力結果が正しいこと';
    };
    
    # 3. 異常系（Roleを持たない無効なStrategy）
    subtest '無効なStrategyの拒絶' => sub {
        package InvalidStrategy { use Moo; sub process { return 1; } }
        
        my $processor = DataProcessor->new;
        my $invalid = InvalidStrategy->new;
        
        eval { $processor->execute($invalid, {}) };
        like $@, qr/Invalid strategy/, 'Processor::Roleを持たないオブジェクトは拒絶されること';
    };
};

done_testing;
