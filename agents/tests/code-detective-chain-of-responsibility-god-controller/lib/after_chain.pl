# ===================================
# Chain of Responsibility パターン
# ===================================
use v5.34;
use warnings;
use feature 'signatures';
no warnings 'experimental::signatures';

# -----------------------------------
# 1. Handler Role (約束事)
# -----------------------------------
package Handler::Role {
    use Moo::Role;

    has 'next_handler' => (is => 'rw', default => sub { undef });

    # チェーンを構築するヘルパーメソッド
    sub set_next ($self, $handler) {
        $self->next_handler($handler);
        return $handler; # メソッドチェーン可能
    }

    # デフォルトの handle: 次のhandlerへ委譲
    sub handle ($self, $request) {
        if ($self->next_handler) {
            return $self->next_handler->handle($request);
        }
        # チェーン末端: すべてのチェックを通過した
        return { status => 200, body => "OK: Processed $request->{path}" };
    }
}

# -----------------------------------
# 2. 具体的なHandler群
# -----------------------------------
package Handler::MaintenanceCheck {
    use Moo;
    with 'Handler::Role';

    has 'maintenance_mode' => (is => 'rw', default => sub { 0 });

    sub handle ($self, $request) {
        if ($self->maintenance_mode) {
            return { status => 503, body => 'Service Unavailable: Maintenance' };
        }
        # 問題なければ次の関所へ
        return $self->next_handler ? $self->next_handler->handle($request) : { status => 200, body => "OK: Processed $request->{path}" };
    }
}

package Handler::IpFilter {
    use Moo;
    with 'Handler::Role';

    has 'blocked_ips' => (is => 'ro', default => sub { ['192.168.0.100', '10.0.0.99'] });

    sub handle ($self, $request) {
        my $ip = $request->{ip} // '';
        if (grep { $_ eq $ip } @{$self->blocked_ips}) {
            return { status => 403, body => "Forbidden: IP $ip is blocked" };
        }
        return $self->next_handler ? $self->next_handler->handle($request) : { status => 200, body => "OK: Processed $request->{path}" };
    }
}

package Handler::TokenVerifier {
    use Moo;
    with 'Handler::Role';

    has 'valid_token' => (is => 'ro', default => sub { 'valid-token-abc' });

    sub handle ($self, $request) {
        my $token = $request->{token} // '';
        if (!$token || $token ne $self->valid_token) {
            return { status => 401, body => 'Unauthorized: Invalid token' };
        }
        return $self->next_handler ? $self->next_handler->handle($request) : { status => 200, body => "OK: Processed $request->{path}" };
    }
}

package Handler::PermissionCheck {
    use Moo;
    with 'Handler::Role';

    sub handle ($self, $request) {
        my $path = $request->{path} // '';
        my $role = $request->{role} // '';
        if ($path =~ m{^/admin} && $role ne 'admin') {
            return { status => 403, body => 'Forbidden: Admin access required' };
        }
        return $self->next_handler ? $self->next_handler->handle($request) : { status => 200, body => "OK: Processed $request->{path}" };
    }
}

package Handler::ParamValidator {
    use Moo;
    with 'Handler::Role';

    sub handle ($self, $request) {
        my $path   = $request->{path}   // '';
        my $params = $request->{params} // {};
        if ($path eq '/api/orders' && !$params->{item_id}) {
            return { status => 400, body => 'Bad Request: item_id is required' };
        }
        return $self->next_handler ? $self->next_handler->handle($request) : { status => 200, body => "OK: Processed $request->{path}" };
    }
}

# -----------------------------------
# 3. チェーンビルダー（便利ユーティリティ）
# -----------------------------------
package Pipeline {
    use Moo;

    has 'first' => (is => 'rw');

    sub build ($self, @handlers) {
        return undef unless @handlers;
        $self->first($handlers[0]);
        for my $i (0 .. $#handlers - 1) {
            $handlers[$i]->set_next($handlers[$i + 1]);
        }
        return $self;
    }

    sub process ($self, $request) {
        return $self->first->handle($request);
    }
}

1;
