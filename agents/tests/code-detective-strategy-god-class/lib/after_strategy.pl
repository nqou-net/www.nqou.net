#!/usr/bin/env perl
use v5.34;
use warnings;
use utf8;
use feature 'signatures';
no warnings "experimental::signatures";

# ==============================================================================
# After: Strategyパターンを適用し、God Classを分割した例
#
# それぞれのフォーマット変換処理を別々のStrategyオブジェクトとして抽出し、
# 共通のRole（インターフェース）を通じてContext（DataProcessor）から呼び出す。
# ==============================================================================

# ------------------------------
# 1. 共通インターフェース (Role)
# ------------------------------
package Processor::Role {
    use Moo::Role;
    requires 'process';
}

# ------------------------------
# 2. 具体的なStrategy群
# ------------------------------
package Processor::Csv {
    use Moo;
    with 'Processor::Role';
    
    sub process ($self, $data) {
        die "Missing 'name' for CSV" unless exists $data->{name};
        die "Missing 'age' for CSV"  unless exists $data->{age};
        
        my $csv_line = sprintf("%s,%s", $data->{name}, $data->{age});
        return "CSV Output: $csv_line";
    }
}

package Processor::Json {
    use Moo;
    with 'Processor::Role';
    
    sub process ($self, $data) {
        die "Missing 'id' for JSON" unless exists $data->{id};
        die "Missing 'value' for JSON" unless exists $data->{value};
        
        my $json_string = sprintf('{"id":%d,"value":"%s"}', $data->{id}, $data->{value});
        return "JSON Output: $json_string";
    }
}

package Processor::Xml {
    use Moo;
    with 'Processor::Role';
    
    sub process ($self, $data) {
        die "Missing 'root' for XML" unless exists $data->{root};
        die "Missing 'content' for XML" unless exists $data->{content};
        
        my $xml_string = sprintf('<%s>%s</%s>', $data->{root}, $data->{content}, $data->{root});
        return "XML Output: $xml_string";
    }
}

# ------------------------------
# 3. Context (利用側・メインロジック)
# ------------------------------
package DataProcessor {
    use Moo;
    
    # 実行時に適切なStrategyを注入し、すべての処理を委譲（Delegate）する
    # これにより、DataProcessor自身からは巨大な if 文が消滅する。
    sub execute ($self, $strategy, $data) {
        # Strategyが正しいRoleを持っているか軽くチェックするのも良い
        die "Invalid strategy" unless $strategy->DOES('Processor::Role');
        
        return $strategy->process($data);
    }
}

# 動作確認時のエントリーポイント
if (!caller) {
    my $processor = DataProcessor->new;
    
    say "【CSV処理】";
    my $csv_strategy = Processor::Csv->new;
    say $processor->execute($csv_strategy, { name => 'Watson', age => 28 });
    
    say "\n【JSON処理】";
    my $json_strategy = Processor::Json->new;
    say $processor->execute($json_strategy, { id => 101, value => 'Code Detective' });
}

1;
