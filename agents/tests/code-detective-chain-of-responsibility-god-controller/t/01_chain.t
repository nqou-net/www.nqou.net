#!/usr/bin/env perl
use v5.34;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";

# ===================================
# Before: God Controller のテスト
# ===================================
subtest 'Before: God Controller - 全チェックが1メソッドに集中' => sub {
    require 'before_god_controller.pl';

    my $ctrl = ApiController->new;

    # 正常リクエスト
    my $res = $ctrl->dispatch({
        ip => '1.2.3.4', token => 'valid-token-abc',
        role => 'user', path => '/api/items', params => {},
    });
    is $res->{status}, 200, '正常リクエストは200';

    # IP制限
    $res = $ctrl->dispatch({
        ip => '192.168.0.100', token => 'valid-token-abc',
        role => 'user', path => '/api/items', params => {},
    });
    is $res->{status}, 403, 'ブロックIPは403';

    # 無効トークン
    $res = $ctrl->dispatch({
        ip => '1.2.3.4', token => 'bad-token',
        role => 'user', path => '/api/items', params => {},
    });
    is $res->{status}, 401, '無効トークンは401';

    # 権限不足
    $res = $ctrl->dispatch({
        ip => '1.2.3.4', token => 'valid-token-abc',
        role => 'user', path => '/admin/settings', params => {},
    });
    is $res->{status}, 403, '管理者権限不足は403';

    # パラメータ不足
    $res = $ctrl->dispatch({
        ip => '1.2.3.4', token => 'valid-token-abc',
        role => 'user', path => '/api/orders', params => {},
    });
    is $res->{status}, 400, 'パラメータ不足は400';
};

# ===================================
# After: Chain of Responsibility のテスト
# ===================================
subtest 'After: Chain of Responsibility - 各Handlerが独立' => sub {
    require 'after_chain.pl';

    # 標準チェーン（全Handler装備）
    my $pipeline = Pipeline->new;
    $pipeline->build(
        Handler::MaintenanceCheck->new,
        Handler::IpFilter->new,
        Handler::TokenVerifier->new,
        Handler::PermissionCheck->new,
        Handler::ParamValidator->new,
    );

    # 正常リクエスト
    my $res = $pipeline->process({
        ip => '1.2.3.4', token => 'valid-token-abc',
        role => 'user', path => '/api/items', params => {},
    });
    is $res->{status}, 200, '正常リクエストは200';

    # IP制限
    $res = $pipeline->process({
        ip => '192.168.0.100', token => 'valid-token-abc',
        role => 'user', path => '/api/items', params => {},
    });
    is $res->{status}, 403, 'ブロックIPは403';

    # 無効トークン
    $res = $pipeline->process({
        ip => '1.2.3.4', token => 'bad-token',
        role => 'user', path => '/api/items', params => {},
    });
    is $res->{status}, 401, '無効トークンは401';

    # 権限不足
    $res = $pipeline->process({
        ip => '1.2.3.4', token => 'valid-token-abc',
        role => 'user', path => '/admin/settings', params => {},
    });
    is $res->{status}, 403, '管理者権限不足は403';

    # パラメータ不足
    $res = $pipeline->process({
        ip => '1.2.3.4', token => 'valid-token-abc',
        role => 'user', path => '/api/orders', params => {},
    });
    is $res->{status}, 400, 'パラメータ不足は400';
};

# ===================================
# Chain of Responsibility の真骨頂: 柔軟なチェーン構成
# ===================================
subtest 'After: IP制限なしチェーン（特定APIのみIP制限スキップ）' => sub {
    # IP制限の関所を外したチェーンを構築
    my $open_pipeline = Pipeline->new;
    $open_pipeline->build(
        Handler::MaintenanceCheck->new,
        # Handler::IpFilter をスキップ！
        Handler::TokenVerifier->new,
        Handler::PermissionCheck->new,
    );

    # ブロックIPでもアクセスできる！
    my $res = $open_pipeline->process({
        ip => '192.168.0.100', token => 'valid-token-abc',
        role => 'user', path => '/api/public', params => {},
    });
    is $res->{status}, 200, 'IP制限スキップで200（ブロックIPでもOK）';
};

subtest 'After: メンテナンスモード' => sub {
    my $pipeline = Pipeline->new;
    $pipeline->build(
        Handler::MaintenanceCheck->new(maintenance_mode => 1),
        Handler::IpFilter->new,
        Handler::TokenVerifier->new,
    );

    my $res = $pipeline->process({
        ip => '1.2.3.4', token => 'valid-token-abc',
        role => 'user', path => '/api/items', params => {},
    });
    is $res->{status}, 503, 'メンテナンスモードで503';
};

done_testing;
