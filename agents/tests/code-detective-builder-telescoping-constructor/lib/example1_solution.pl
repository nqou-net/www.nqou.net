#!/usr/bin/env perl
use v5.36;
use warnings;
use utf8;

# --- 広告キャンペーン設定クラス（改善版: Builder パターン） ---
# Campaign クラスは example1_problem.pl で定義済み（テストから事前に読み込まれる）

# Builder クラス
package CampaignBuilder {
    use Moo;
    use Carp qw(croak);

    has _title          => ( is => 'rw', default => '' );
    has _budget         => ( is => 'rw', default => 0 );
    has _start_date     => ( is => 'rw', default => '' );
    has _end_date       => ( is => 'rw', default => '' );
    has _target_age_min => ( is => 'rw', default => 0 );
    has _target_age_max => ( is => 'rw', default => 99 );
    has _target_gender  => ( is => 'rw', default => 'all' );
    has _platform       => ( is => 'rw', default => 'all' );
    has _ad_format      => ( is => 'rw', default => 'banner' );
    has _daily_cap      => ( is => 'rw', default => 0 );
    has _region         => ( is => 'rw', default => 'JP' );
    has _priority       => ( is => 'rw', default => 'normal' );

    # 各設定メソッド（メソッドチェーン対応: $self を返す）
    sub title ($self, $val)          { $self->_title($val);          return $self; }
    sub budget ($self, $val)         { $self->_budget($val);         return $self; }
    sub start_date ($self, $val)     { $self->_start_date($val);     return $self; }
    sub end_date ($self, $val)       { $self->_end_date($val);       return $self; }
    sub target_age_min ($self, $val) { $self->_target_age_min($val); return $self; }
    sub target_age_max ($self, $val) { $self->_target_age_max($val); return $self; }
    sub target_gender ($self, $val)  { $self->_target_gender($val);  return $self; }
    sub platform ($self, $val)       { $self->_platform($val);       return $self; }
    sub ad_format ($self, $val)      { $self->_ad_format($val);      return $self; }
    sub daily_cap ($self, $val)      { $self->_daily_cap($val);      return $self; }
    sub region ($self, $val)         { $self->_region($val);         return $self; }
    sub priority ($self, $val)       { $self->_priority($val);       return $self; }

    # バリデーション付きの build メソッド
    sub build ($self) {
        # 必須項目のチェック
        croak "title is required"      unless $self->_title;
        croak "budget is required"     unless $self->_budget > 0;
        croak "start_date is required" unless $self->_start_date;
        croak "end_date is required"   unless $self->_end_date;

        # ビジネスルールのバリデーション
        croak "end_date must be after start_date"
            if $self->_end_date le $self->_start_date;
        croak "target_age_max must be >= target_age_min"
            if $self->_target_age_max < $self->_target_age_min;

        return Campaign->new(
            title          => $self->_title,
            budget         => $self->_budget,
            start_date     => $self->_start_date,
            end_date       => $self->_end_date,
            target_age_min => $self->_target_age_min,
            target_age_max => $self->_target_age_max,
            target_gender  => $self->_target_gender,
            platform       => $self->_platform,
            ad_format      => $self->_ad_format,
            daily_cap      => $self->_daily_cap,
            region         => $self->_region,
            priority       => $self->_priority,
        );
    }
}

package main {
    if (!caller) {
        # 【改善後】
        # メソッドチェーンで何を設定しているか一目瞭然！
        # build() でバリデーションも集約されている。
        my $campaign = CampaignBuilder->new
            ->title('春の新生活キャンペーン')
            ->budget(100000)
            ->start_date('2026-04-01')
            ->end_date('2026-04-30')
            ->target_age_min(20)
            ->target_age_max(35)
            ->platform('mobile')
            ->ad_format('video')
            ->daily_cap(5000)
            ->priority('high')
            ->build();

        say $campaign->summary();
    }
}

1;
