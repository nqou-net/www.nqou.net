#!/usr/bin/env perl
# 第6回 コード例1: MessageSubjectロール - Observerパターンの基盤
use v5.36;
use Moo::Role;
use namespace::clean;

package Subject::Role {
    use Moo::Role;
    use namespace::clean;

    has 'observers' => (is => 'rw', default => sub { [] });

    sub attach($self, $observer) {
        push $self->observers->@*, $observer;
    }

    sub detach($self, $observer) {
        $self->observers([grep { $_ != $observer } $self->observers->@*]);
    }

    sub notify($self, $event, @args) {
        for my $observer ($self->observers->@*) {
            $observer->update($self, $event, @args);
        }
    }
}

package Observer::Role {
    use Moo::Role;
    use namespace::clean;

    requires 'update';
}

1;
