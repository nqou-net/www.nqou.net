#!/usr/bin/env perl
use v5.36;
use warnings;

# ===========================================
# After コード: Proxy パターンで Inappropriate Intimacy を解消
# ===========================================

# -------------------------------------------
# 1. UserProfile (実体 / RealSubject)
#    内部構造は自由に変更可能。アクセサを提供する。
# -------------------------------------------
package UserProfile {
    use Moo;

    has 'name'       => (is => 'ro', required => 1);
    has 'email'      => (is => 'ro', required => 1);
    has 'department' => (is => 'ro', required => 1);
    has 'role'       => (is => 'ro', required => 1);

    sub is_admin {
        my ($self) = @_;
        return $self->role eq 'admin';
    }
}

# -------------------------------------------
# 2. Subject Role (共通インターフェース)
#    RealSubject と Proxy が共有する約束事
# -------------------------------------------
package UserProfile::Role {
    use Moo::Role;

    requires 'name';
    requires 'email';
    requires 'department';
    requires 'role';
    requires 'is_admin';
}

# -------------------------------------------
# 3. Proxy (代理人)
#    RealSubjectと同じインターフェースを持ち、
#    アクセス制御・キャッシュ・ログを透過的に追加
# -------------------------------------------
package UserProfile::Proxy {
    use Moo;
    with 'UserProfile::Role';

    has '_real_subject' => (is => 'ro', required => 1, init_arg => 'real_subject');
    has '_access_log'   => (is => 'rw', default  => sub { [] });
    has '_cache'        => (is => 'rw', default  => sub { {} });

    sub _log_access {
        my ($self, $field) = @_;
        push @{$self->_access_log}, {
            field     => $field,
            timestamp => time(),
        };
    }

    sub _cached_or_fetch {
        my ($self, $field) = @_;
        unless (exists $self->_cache->{$field}) {
            $self->_cache->{$field} = $self->_real_subject->$field();
        }
        $self->_log_access($field);
        return $self->_cache->{$field};
    }

    # Subject Role の実装（すべて Proxy 経由）
    sub name       { my ($self) = @_; $self->_cached_or_fetch('name') }
    sub email      { my ($self) = @_; $self->_cached_or_fetch('email') }
    sub department { my ($self) = @_; $self->_cached_or_fetch('department') }
    sub role       { my ($self) = @_; $self->_cached_or_fetch('role') }

    sub is_admin {
        my ($self) = @_;
        $self->_log_access('is_admin');
        return $self->_real_subject->is_admin;
    }

    # Proxy 固有の機能
    sub get_access_log { my ($self) = @_; return @{$self->_access_log} }
    sub access_count   { my ($self) = @_; return scalar @{$self->_access_log} }
}

# -------------------------------------------
# 4. UserReportGenerator (クライアント)
#    Proxy か RealSubject かを意識しない
# -------------------------------------------
package UserReportGenerator {
    use Moo;

    # インターフェースのみに依存（内部構造に一切触れない）
    sub generate {
        my ($self, $profile) = @_;
        my $name  = $profile->name;
        my $email = $profile->email;
        my $dept  = $profile->department;
        my $role  = $profile->role;

        return <<"REPORT";
=== ユーザーレポート ===
名前: $name
メール: $email
部署: $dept
役職: $role
=======================
REPORT
    }

    sub find_admins {
        my ($self, @profiles) = @_;
        my @admins;
        for my $profile (@profiles) {
            if ($profile->is_admin) {
                push @admins, $profile->name;
            }
        }
        return @admins;
    }
}

# --- テスト用のエントリポイント ---
sub run_demo {
    # RealSubject を作成
    my $real_profile = UserProfile->new(
        name       => '田中太郎',
        email      => 'tanaka@example.com',
        department => '開発部',
        role       => 'admin',
    );

    # Proxy で包む
    my $proxy = UserProfile::Proxy->new(real_subject => $real_profile);

    # クライアントは Proxy を RealSubject と同じように使える
    my $generator = UserReportGenerator->new;
    my $report = $generator->generate($proxy);
    print $report;

    # 管理者検索も Proxy 経由
    my @admins = $generator->find_admins($proxy);
    say "管理者: " . join(', ', @admins);

    # Proxy 固有の機能: アクセスログ
    say "\n--- アクセスログ ---";
    say "アクセス回数: " . $proxy->access_count;
    for my $log ($proxy->get_access_log) {
        say "  フィールド: $log->{field}";
    }

    return 1;
}

run_demo() unless caller;
1;
