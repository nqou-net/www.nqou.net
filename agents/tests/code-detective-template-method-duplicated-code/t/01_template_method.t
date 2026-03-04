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

subtest 'コード例1 - 問題版 (Duplicated Code)' => sub {
    require 'before_duplicated.pl';

    my $user_csv  = UserCsvExporter->new->export;
    my $order_csv = OrderCsvExporter->new->export;

    # ユーザーCSVの出力確認
    like $user_csv, qr/^name,email/, 'ユーザーCSVのヘッダーが正しいこと';
    like $user_csv, qr/Aoi,aoi\@example\.com/, 'ユーザーデータが含まれること';

    # 注文CSVの出力確認
    like $order_csv, qr/^order_id,product,price/, '注文CSVのヘッダーが正しいこと';
    like $order_csv, qr/1001,Keyboard,8500/, '注文データが含まれること';
};

subtest 'コード例2 - 改善版 (Template Method)' => sub {
    require 'after_template_method.pl';

    subtest '各サブクラスの単体テスト' => sub {
        my $user_csv = CsvExporter::User->new->export;
        like $user_csv, qr/^name,email/, 'ユーザーCSVのヘッダーが正しいこと';
        like $user_csv, qr/Aoi,aoi\@example\.com/, 'ユーザーデータが含まれること';

        my $order_csv = CsvExporter::Order->new->export;
        like $order_csv, qr/^order_id,product,price/, '注文CSVのヘッダーが正しいこと';
        like $order_csv, qr/1002,Trackball,6200/, '注文データが含まれること';
    };

    subtest '基底クラスを直接使うとエラーになること' => sub {
        my $base = CsvExporter::Base->new;
        eval { $base->export };
        like $@, qr/must be overridden/, '基底クラスのexportは抽象メソッドをdie';
    };

    subtest 'Before版とAfter版の出力が一致すること' => sub {
        is UserCsvExporter->new->export, CsvExporter::User->new->export,
            'ユーザーCSVの出力がBefore/Afterで一致';
        is OrderCsvExporter->new->export, CsvExporter::Order->new->export,
            '注文CSVの出力がBefore/Afterで一致';
    };
};

done_testing;
