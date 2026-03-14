#!/usr/bin/env perl
use v5.36;
use warnings;

# ===========================================
# Before コード: Inappropriate Intimacy
# UserReportGenerator が UserProfile の内部構造に直接アクセスしている
# ===========================================

package UserProfile {
    use Moo;

    # 内部データ（本来は外部から直接触るべきではない）
    has '_data' => (
        is      => 'ro',
        default => sub {
            {
                name       => '',
                email      => '',
                department => '',
                role       => '',
            }
        },
    );

    sub BUILD {
        my ($self, $args) = @_;
        my $data = $self->_data;
        $data->{name}       = $args->{name}       // '';
        $data->{email}      = $args->{email}      // '';
        $data->{department} = $args->{department} // '';
        $data->{role}       = $args->{role}       // '';
    }
}

package UserReportGenerator {
    use Moo;

    # 💥 Inappropriate Intimacy: 他クラスの内部ハッシュに直接アクセス！
    sub generate {
        my ($self, $profile) = @_;
        # _data の内部構造を「知っている」前提でアクセスしている
        my $data = $profile->_data;

        my $name = $data->{name};
        my $email = $data->{email};
        my $dept = $data->{department};
        my $role = $data->{role};

        return <<"REPORT";
=== ユーザーレポート ===
名前: $name
メール: $email
部署: $dept
役職: $role
=======================
REPORT
    }

    # 💥 内部キーに依存した検索ロジック
    sub find_admins {
        my ($self, @profiles) = @_;
        my @admins;
        for my $profile (@profiles) {
            # 内部ハッシュの 'role' キーに直接アクセス
            if ($profile->_data->{role} eq 'admin') {
                push @admins, $profile->_data->{name};
            }
        }
        return @admins;
    }
}

# --- テスト用のエントリポイント ---
sub run_demo {
    my $profile = UserProfile->new(
        name       => '田中太郎',
        email      => 'tanaka@example.com',
        department => '開発部',
        role       => 'admin',
    );

    my $generator = UserReportGenerator->new;
    my $report = $generator->generate($profile);
    print $report;

    my @admins = $generator->find_admins($profile);
    say "管理者: " . join(', ', @admins);

    return 1;
}

run_demo() unless caller;
1;
