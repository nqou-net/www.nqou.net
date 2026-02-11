package Role::Builder;
use v5.36;
use Moo::Role;

requires 'build';
requires '_defaults';

sub _merge_deep($self, $base, $override) {
    my %merged = $base->%*;
    for my $key (keys $override->%*) {
        if (ref $merged{$key} eq 'HASH' && ref $override->{$key} eq 'HASH') {
            $merged{$key} = $self->_merge_deep($merged{$key}, $override->{$key});
        } else {
            $merged{$key} = $override->{$key};
        }
    }
    return \%merged;
}

1;
