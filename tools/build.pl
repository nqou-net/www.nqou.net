#!/usr/bin/env perl
use utf8;
use strict;
use warnings;
use Path::Tiny qw(path);
use YAML ();
use Time::Moment ();

my $root = path(__FILE__)->absolute->parent(2);

# 出力先をクリーニングする
my $output_dir = path($root, 'docs');# config.tomlを変更したらここも変更すること
$output_dir->remove_tree if $output_dir->exists;

# 記事を取得
my $posts_dir = path($root, 'content', 'post');
my $iterator = $posts_dir->iterator(+{ recurse => 1 });

# タイムゾーンを取得
my $tm = Time::Moment->now;
my $offset = $tm->offset;
my $jp_offset = 540;

# 記事から時間を取得して、名称変更
while (my $post = $iterator->()) {
    next unless $post->is_file;
    print "Processing ", $post->stringify, "\n";
    my ($yaml, $after) = split /\n---/, $post->slurp_utf8, 2;
    my $info = YAML::Load($yaml);

    my $modified;
    unless (exists $info->{draft}) {
        $info->{draft} = 'true'
    }

    # ISO8601を持っていない場合はdateからISOを作成
    unless (exists $info->{iso8601}) {

        # 存在しなければ今書いたことにする
        if (!exists $info->{date}) {
            my $tm;
            while (1) {
                $tm = Time::Moment->now->with_precision(0);
                my $new_path = new_path_by_iso8601($tm->to_string);
                last unless $new_path->exists;
                sleep 1;
            }
            $info->{iso8601} = $tm->to_string;
        }

        # すでに変換済みであればそのまま渡す
        elsif (-1 < index($info->{date}, 'T')) {
            $info->{iso8601} = $info->{date};
        }

        # date があれば iso8601 を作成
        else {
            my $date = join('T', split(/\s/, $info->{date})) . 'Z';
            my $tm = Time::Moment->from_string($date);
            my $new_date = $tm->with_offset_same_local($offset);
            $info->{iso8601} = $new_date->to_string;
        }

        # date はURLのために日本時間へ統一
        my $tm = Time::Moment->from_string($info->{iso8601});
        my $url_date = $tm->with_offset_same_instant($jp_offset);
        $info->{date} = $url_date->to_string;
        $modified = 1;
    }

    # # comment は消す
    # if (exists $info->{comment}) {
    #     delete $info->{comment};
    #     $modified = 1;
    # }

    # # 本文に文字列が含まれていたらタグを追加
    # my $target = 'heroku';
    # my $tag    = 'heroku';
    # if ($after =~ /$target\b/i) {
    #     my $tags = $info->{tags};
    #
    #     # undef が含まれていたら削除する
    #     $tags = +[grep { $_ ne 'undef' and $_ ne $tag } @{$tags}];
    #     push @{$tags}, $tag;
    #     $info->{tags} = +[sort @{$tags}];
    #     $modified = 1;
    # }

    # 変更されていたら保存する
    if ($modified) {

        # 結合して出力
        my $dump_yaml = YAML::Dump($info);
        my $body = join qq{\n---}, $dump_yaml, $after;
        $post->spew_utf8($body);
    }

    # 公開する場合は時間でファイル名を変更
    if ($info->{draft} eq 'false') {
        my $new_path = new_path_by_iso8601($info->{iso8601});
        $new_path->parent->mkpath;
        $post->move($new_path->stringify);
    }
}

sub new_path_by_iso8601 {
    my $iso8601 = shift;
    my $tm = Time::Moment->from_string($iso8601)->with_offset_same_instant($jp_offset);
    my $path = $tm->strftime('%Y/%m/%d/%H%M%S');
    my $new_path = path($posts_dir, qq{$path.md})->absolute;
    return $new_path;
}
