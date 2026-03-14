package ApiController;
use v5.34;
use warnings;
use Moo;
use feature 'signatures';
no warnings 'experimental::signatures';

# God Controller - すべてのセキュリティチェックを1つのメソッドに抱え込んでいる
sub dispatch ($self, $request) {
    my $ip     = $request->{ip}     // '';
    my $token  = $request->{token}  // '';
    my $role   = $request->{role}   // '';
    my $path   = $request->{path}   // '';
    my $params = $request->{params} // {};

    # 1. メンテナンスチェック
    if ($self->_is_maintenance_mode()) {
        return { status => 503, body => 'Service Unavailable: Maintenance' };
    }

    # 2. IP制限チェック
    my @blocked_ips = ('192.168.0.100', '10.0.0.99');
    if (grep { $_ eq $ip } @blocked_ips) {
        return { status => 403, body => "Forbidden: IP $ip is blocked" };
    }

    # 3. 認証トークンの検証
    if (!$token || $token ne 'valid-token-abc') {
        return { status => 401, body => 'Unauthorized: Invalid token' };
    }

    # 4. パーミッション（権限）チェック
    if ($path =~ m{^/admin} && $role ne 'admin') {
        return { status => 403, body => 'Forbidden: Admin access required' };
    }

    # 5. パラメータのバリデーション
    if ($path eq '/api/orders' && !$params->{item_id}) {
        return { status => 400, body => 'Bad Request: item_id is required' };
    }

    # --- ようやく本来の処理 ---
    return { status => 200, body => "OK: Processed $path" };
}

sub _is_maintenance_mode ($self) {
    return 0; # 通常は0、メンテ時に1
}

1;
