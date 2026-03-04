#!/usr/bin/env perl
use v5.34;
use warnings;
use utf8;
use feature 'signatures';
no warnings "experimental::signatures";

# ==============================================================================
# Before: 神オブジェクト（God Class）の例
#
# この DataProcessor クラスは、種類（csv, json, xml）に応じた
# 全てのバリデーションとフォーマット変換処理を1つのメソッド内に抱え込んでいる。
# ==============================================================================

package DataProcessor {
    use Moo;

    # すべての処理を一点で引き受ける「神のメソッド」
    sub process_everything ($self, $type, $data) {
        if ($type eq 'csv') {
            # CSV専用のバリデーション
            die "Missing 'name' for CSV" unless exists $data->{name};
            die "Missing 'age' for CSV"  unless exists $data->{age};
            
            # CSVフォーマットに変換
            my $csv_line = sprintf("%s,%s", $data->{name}, $data->{age});
            return "CSV Output: $csv_line";
            
        } elsif ($type eq 'json') {
            # JSON専用のバリデーション
            die "Missing 'id' for JSON" unless exists $data->{id};
            die "Missing 'value' for JSON" unless exists $data->{value};
            
            # 手動で簡易JSON風フォーマット生成（例なので簡略化）
            my $json_string = sprintf('{"id":%d,"value":"%s"}', $data->{id}, $data->{value});
            return "JSON Output: $json_string";
            
        } elsif ($type eq 'xml') {
            # XML専用のバリデーション
            die "Missing 'root' for XML" unless exists $data->{root};
            die "Missing 'content' for XML" unless exists $data->{content};
            
            # 簡易XML風フォーマット生成
            my $xml_string = sprintf('<%s>%s</%s>', $data->{root}, $data->{content}, $data->{root});
            return "XML Output: $xml_string";
            
        } else {
            die "Unknown type: $type";
        }
    }
}

# 動作確認時のエントリーポイント（モジュールとしてrequireされた場合は実行しない）
if (!caller) {
    my $processor = DataProcessor->new;
    
    say "【CSV処理】";
    say $processor->process_everything('csv', { name => 'Watson', age => 28 });
    
    say "\n【JSON処理】";
    say $processor->process_everything('json', { id => 101, value => 'Code Detective' });
}

1;
