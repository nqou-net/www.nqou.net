package JsonAdapter;

# 第3回: Adapterでデータソースを統一
# JsonAdapter.pm - JSONデータのAdapter

use v5.36;
use warnings;
use utf8;
use Moo;
use JSON::PP;
use Encode qw(decode);

with 'WhiskySourceRole';

has json_data => (
    is       => 'ro',
    required => 1,
);

has '_cache' => (
    is      => 'lazy',
    builder => '_build_cache',
);

sub _build_cache($self) {
    my $json_text = $self->json_data;

    # UTF-8バイト列ならデコード
    $json_text = decode('UTF-8', $json_text) unless utf8::is_utf8($json_text);
    my $obj = JSON::PP->new->utf8(0)->decode($json_text);
    my @whiskies;

    for my $w ($obj->{whiskies}->@*) {

        # JSONの独自構造 → 統一構造へ変換
        push @whiskies,
            {
            id     => $w->{whisky_id},
            name   => $w->{whisky_name},
            region => $w->{origin}{region},
            age    => $w->{specs}{age_years},
            abv    => $w->{specs}{alcohol_percentage},
            nose   => $w->{tasting_notes}{aroma},
            palate => $w->{tasting_notes}{taste},
            finish => $w->{tasting_notes}{after},
            rating => $w->{score},
            };
    }

    return {map { $_->{id} => $_ } @whiskies};
}

sub get_whisky($self, $id) {
    return $self->_cache->{$id};
}

sub get_all($self) {
    return values $self->_cache->%*;
}

sub source_name($self) {'JSON'}

1;

__END__

=head1 NAME

JsonAdapter - JSONデータを統一インターフェースで提供するAdapter

=head1 SYNOPSIS

    my $adapter = JsonAdapter->new(json_data => $json_string);
    my $whisky = $adapter->get_whisky('W002');
    my @all = $adapter->get_all();

=head1 DESCRIPTION

異なる構造を持つJSONデータを、WhiskySourceRoleの
統一インターフェースに変換するAdapter。

=cut
