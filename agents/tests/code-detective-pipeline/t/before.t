use strict;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';
use Test::More;

do './agents/tests/code-detective-pipeline/before/lib.pl' or die $@ || $!;

my @csv_lines = (
    "name,amount,date",
    "Alice, 1000, 2026-01-01",
    "Bob, 2000, 2026-01-02",
    "",
    "Charlie, 3000, 2026-01-03",
);

subtest 'Before: 正常系 — CSVインポートが正しく動作する' => sub {
    my $importer = CsvImporter->new;
    my $result   = $importer->import_csv(\@csv_lines);

    is(scalar @{ $result->{records} }, 3, 'レコードが3件');
    is($result->{records}[0]{name}, 'Alice', '名前がトリムされている');
    is($result->{records}[0]{amount}, 1000, '金額が数値化されている');
    is($result->{total}, 6000, '合計が正しい');
};

subtest 'Before: 空行とヘッダーがスキップされる' => sub {
    my $importer = CsvImporter->new;
    my $result   = $importer->import_csv(["name,amount,date", "", "Alice,500,2026-01-01"]);

    is(scalar @{ $result->{records} }, 1, '空行とヘッダーを除いて1件');
};

subtest 'Before: カラム数不正の行がスキップされる' => sub {
    my $importer = CsvImporter->new;
    my $result   = $importer->import_csv(["name,amount,date", "Alice,1000,2026-01-01", "Bad,Row"]);

    is(scalar @{ $result->{records} }, 1, 'カラム数不正の行はスキップ');
};

subtest 'Before: 金額0以下の行がスキップされる' => sub {
    my $importer = CsvImporter->new;
    my $result   = $importer->import_csv(["name,amount,date", "Alice,0,2026-01-01", "Bob,500,2026-01-02"]);

    is(scalar @{ $result->{records} }, 1, '金額0の行はスキップ');
    is($result->{records}[0]{name}, 'Bob', '有効な行だけが残る');
};

subtest 'Before: 問題点 — 個別のステップをテストできない' => sub {
    # 空行除去だけ、ヘッダースキップだけをテストする手段がない
    my $importer = CsvImporter->new;
    ok(!$importer->can('skip_blank_lines'), '空行除去メソッドが存在しない');
    ok(!$importer->can('skip_header'), 'ヘッダースキップメソッドが存在しない');
    ok(!$importer->can('validate'), 'バリデーションメソッドが存在しない');
};

done_testing;
