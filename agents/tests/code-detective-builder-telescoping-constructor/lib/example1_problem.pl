#!/usr/bin/env perl
use v5.36;
use warnings;
use utf8;

# --- 広告キャンペーン設定クラス（問題版: Telescoping Constructor） ---
package Campaign {
    use Moo;
    use Carp qw(croak);

    has title          => ( is => 'ro', required => 1 );
    has budget         => ( is => 'ro', required => 1 );
    has start_date     => ( is => 'ro', required => 1 );
    has end_date       => ( is => 'ro', required => 1 );
    has target_age_min => ( is => 'ro', default  => 0 );
    has target_age_max => ( is => 'ro', default  => 99 );
    has target_gender  => ( is => 'ro', default  => 'all' );
    has platform       => ( is => 'ro', default  => 'all' );
    has ad_format      => ( is => 'ro', default  => 'banner' );
    has daily_cap      => ( is => 'ro', default  => 0 );
    has region         => ( is => 'ro', default  => 'JP' );
    has priority       => ( is => 'ro', default  => 'normal' );

    sub summary ($self) {
        return sprintf(
            "[%s] budget=%d, period=%s~%s, age=%d-%d, gender=%s, platform=%s, format=%s, region=%s, priority=%s",
            $self->title, $self->budget,
            $self->start_date, $self->end_date,
            $self->target_age_min, $self->target_age_max,
            $self->target_gender, $self->platform,
            $self->ad_format, $self->region, $self->priority,
        );
    }
}

package main {
    if (!caller) {
        # 【問題点】
        # 呼び出し側から見ると、引数が何を意味しているのか分かりづらく、
        # 順番を間違えたり、デフォルト値の把握が困難になる。
        # さらにバリデーションが存在しないため、不正な値でも通ってしまう。
        my $campaign = Campaign->new(
            title          => '春の新生活キャンペーン',
            budget         => 100000,
            start_date     => '2026-04-01',
            end_date       => '2026-04-30',
            target_age_min => 20,
            target_age_max => 35,
            target_gender  => 'all',
            platform       => 'mobile',
            ad_format      => 'video',
            daily_cap      => 5000,
            region         => 'JP',
            priority       => 'high',
        );
        say $campaign->summary();
    }
}

1;
