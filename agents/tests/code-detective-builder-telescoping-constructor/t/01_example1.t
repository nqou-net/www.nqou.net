#!/usr/bin/env perl
use v5.36;
use warnings;
use utf8;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";

# Campaign クラスは problem.pl と solution.pl で共通のため、先に読み込む
require 'example1_problem.pl';

subtest 'Problem: Telescoping Constructor' => sub {
    # 全引数を指定して正しく生成できることを確認
    my $campaign = Campaign->new(
        title          => 'Spring Campaign',
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

    is($campaign->title, 'Spring Campaign', 'title should match');
    is($campaign->budget, 100000, 'budget should match');
    is($campaign->platform, 'mobile', 'platform should match');
    is($campaign->ad_format, 'video', 'ad_format should match');
    like(
        $campaign->summary(),
        qr/Spring Campaign/,
        'summary should contain the title'
    );

    # Default values
    my $minimal = Campaign->new(
        title      => 'Test',
        budget     => 1000,
        start_date => '2026-01-01',
        end_date   => '2026-01-31',
    );
    is($minimal->target_age_min, 0, 'default age_min should be 0');
    is($minimal->target_age_max, 99, 'default age_max should be 99');
    is($minimal->platform, 'all', 'default platform should be all');
    is($minimal->region, 'JP', 'default region should be JP');

    # PROBLEM: no validation - invalid values are silently accepted
    my $invalid = Campaign->new(
        title      => '',
        budget     => -500,
        start_date => '2026-12-31',
        end_date   => '2026-01-01',
    );
    is($invalid->budget, -500, 'PROBLEM: negative budget is accepted without validation');
};

subtest 'Solution: Builder Pattern' => sub {
    require 'example1_solution.pl';

    # Fluent method chain
    my $campaign = CampaignBuilder->new
        ->title('Spring Campaign')
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

    is($campaign->title, 'Spring Campaign', 'title should match via builder');
    is($campaign->budget, 100000, 'budget should match via builder');
    is($campaign->platform, 'mobile', 'platform should match via builder');
    is($campaign->ad_format, 'video', 'ad_format should match via builder');
    like(
        $campaign->summary(),
        qr/Spring Campaign/,
        'summary should contain the title via builder'
    );

    # Minimal build with defaults
    my $minimal = CampaignBuilder->new
        ->title('Minimal Test')
        ->budget(1000)
        ->start_date('2026-01-01')
        ->end_date('2026-01-31')
        ->build();
    is($minimal->target_age_min, 0, 'default age_min should be 0');
    is($minimal->region, 'JP', 'default region should be JP');

    # Validation: missing title
    eval {
        CampaignBuilder->new
            ->budget(1000)
            ->start_date('2026-01-01')
            ->end_date('2026-01-31')
            ->build();
    };
    like($@, qr/title is required/, 'should reject missing title');

    # Validation: non-positive budget
    eval {
        CampaignBuilder->new
            ->title('Test')
            ->budget(-500)
            ->start_date('2026-01-01')
            ->end_date('2026-01-31')
            ->build();
    };
    like($@, qr/budget is required/, 'should reject non-positive budget');

    # Validation: end_date before start_date
    eval {
        CampaignBuilder->new
            ->title('Test')
            ->budget(1000)
            ->start_date('2026-12-31')
            ->end_date('2026-01-01')
            ->build();
    };
    like($@, qr/end_date must be after start_date/, 'should reject invalid date range');

    # Validation: age range
    eval {
        CampaignBuilder->new
            ->title('Test')
            ->budget(1000)
            ->start_date('2026-01-01')
            ->end_date('2026-01-31')
            ->target_age_min(50)
            ->target_age_max(20)
            ->build();
    };
    like($@, qr/target_age_max must be >= target_age_min/, 'should reject invalid age range');
};

done_testing;
