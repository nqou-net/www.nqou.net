use strict;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';
use Test::More;

do './agents/tests/code-detective-pipeline/after/lib.pl' or die $@ || $!;

my @csv_lines = (
    "name,amount,date",
    "Alice, 1000, 2026-01-01",
    "Bob, 2000, 2026-01-02",
    "",
    "Charlie, 3000, 2026-01-03",
);

subtest 'After: 各フィルター単体テスト — SkipBlankLines' => sub {
    my $filter = Filter::SkipBlankLines->new;
    my $result = $filter->process(["hello", "", "  ", "world"]);
    is_deeply($result, ["hello", "world"], '空行が除去される');
};

subtest 'After: 各フィルター単体テスト — SkipHeader' => sub {
    my $filter = Filter::SkipHeader->new;
    my $result = $filter->process(["header", "row1", "row2"]);
    is_deeply($result, ["row1", "row2"], 'ヘッダーがスキップされる');
};

subtest 'After: 各フィルター単体テスト — ParseColumns' => sub {
    my $filter = Filter::ParseColumns->new;
    my $result = $filter->process(["a,b,c", "d,e,f"]);
    is_deeply($result, [["a","b","c"], ["d","e","f"]], 'カラムが分割される');
};

subtest 'After: 各フィルター単体テスト — ValidateColumnCount' => sub {
    my $filter = Filter::ValidateColumnCount->new(expected => 3);
    my $result = $filter->process([["a","b","c"], ["d","e"], ["f","g","h"]]);
    is(scalar @$result, 2, 'カラム数不正の行が除去される');
};

subtest 'After: 各フィルター単体テスト — TransformFields' => sub {
    my $filter = Filter::TransformFields->new;
    my $result = $filter->process([["  Alice  ", " 1000 ", "  2026-01-01  "]]);
    is($result->[0]{name}, 'Alice', '名前がトリムされる');
    is($result->[0]{amount}, 1000, '金額が数値化される');
    is($result->[0]{date}, '2026-01-01', '日付がトリムされる');
};

subtest 'After: 各フィルター単体テスト — ValidateAmount' => sub {
    my $filter = Filter::ValidateAmount->new;
    my $result = $filter->process([
        { name => 'A', amount => 100, date => '2026-01-01' },
        { name => 'B', amount => 0,   date => '2026-01-02' },
        { name => 'C', amount => 500, date => '2026-01-03' },
    ]);
    is(scalar @$result, 2, '金額0の行が除去される');
};

subtest 'After: 各フィルター単体テスト — CalculateTotal' => sub {
    my $filter = Filter::CalculateTotal->new;
    my $result = $filter->process([
        { name => 'A', amount => 100, date => '2026-01-01' },
        { name => 'B', amount => 200, date => '2026-01-02' },
    ]);
    is($result->{total}, 300, '合計が正しい');
    is(scalar @{ $result->{records} }, 2, 'レコードが保持される');
};

subtest 'After: パイプライン全体 — Before と同じ結果を返す' => sub {
    my $pipeline = CsvPipeline->new(filters => [
        Filter::SkipBlankLines->new,
        Filter::SkipHeader->new,
        Filter::ParseColumns->new,
        Filter::ValidateColumnCount->new,
        Filter::TransformFields->new,
        Filter::ValidateAmount->new,
        Filter::CalculateTotal->new,
    ]);

    my $result = $pipeline->execute(\@csv_lines);

    is(scalar @{ $result->{records} }, 3, 'レコードが3件');
    is($result->{records}[0]{name}, 'Alice', '名前がトリムされている');
    is($result->{records}[0]{amount}, 1000, '金額が数値化されている');
    is($result->{total}, 6000, '合計が正しい');
};

subtest 'After: フィルターの組み替えが容易' => sub {
    # 合計計算を省いたパイプライン
    my $pipeline = CsvPipeline->new(filters => [
        Filter::SkipBlankLines->new,
        Filter::SkipHeader->new,
        Filter::ParseColumns->new,
        Filter::ValidateColumnCount->new,
        Filter::TransformFields->new,
        Filter::ValidateAmount->new,
    ]);

    my $result = $pipeline->execute(\@csv_lines);

    is(ref($result), 'ARRAY', '合計計算なしのためARRAYが返る');
    is(scalar @$result, 3, 'レコードが3件');
};

subtest 'After: カスタムフィルターの追加が容易' => sub {
    # カラム数を4に変更したバリデーター
    my $pipeline = CsvPipeline->new(filters => [
        Filter::SkipBlankLines->new,
        Filter::SkipHeader->new,
        Filter::ParseColumns->new,
        Filter::ValidateColumnCount->new(expected => 4),
        Filter::TransformFields->new,
        Filter::ValidateAmount->new,
        Filter::CalculateTotal->new,
    ]);

    my $result = $pipeline->execute(\@csv_lines);

    is(scalar @{ $result->{records} }, 0, 'カラム数4を期待するため全行除去');
    is($result->{total}, 0, '合計は0');
};

done_testing;
