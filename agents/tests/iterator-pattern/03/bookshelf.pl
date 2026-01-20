#!/usr/bin/env perl
# Perl v5.36以降 / Moo
use v5.36;

package Book {
    use Moo;

    has title  => (is => 'ro', required => 1);
    has author => (is => 'ro', required => 1);
}

package BookIteratorRole {
    use Moo::Role;

    requires 'has_next';
    requires 'next';
}

package BookShelf {
    use Moo;

    has books => (
        is      => 'ro',
        default => sub { [] },
    );

    sub add_book ($self, $book) {
        push $self->books->@*, $book;
    }

    sub get_book_at ($self, $index) {
        return $self->books->[$index];
    }

    sub get_length ($self) {
        return scalar $self->books->@*;
    }
}

package BookShelfIterator {
    use Moo;

    with 'BookIteratorRole';

    has bookshelf => (is => 'ro', required => 1);
    has index     => (is => 'rw', default  => 0);

    sub has_next ($self) {
        return $self->index < $self->bookshelf->get_length;
    }

    sub next ($self) {
        my $book = $self->bookshelf->get_book_at($self->index);
        $self->index($self->index + 1);
        return $book;
    }
}

package main;

# 本棚を作成
my $shelf = BookShelf->new;

# 本を追加
$shelf->add_book(Book->new(title => 'すぐわかるPerl', author => '深沢千尋'));
$shelf->add_book(Book->new(title => '初めてのPerl', author => 'Randal L. Schwartz'));
$shelf->add_book(Book->new(title => 'プログラミングPerl', author => 'Larry Wall'));

# イテレータを作成
my $iterator = BookShelfIterator->new(bookshelf => $shelf);

# イテレータを使って全ての本を表示
say "=== イテレータを使った走査 ===";
while ($iterator->has_next) {
    my $book = $iterator->next;
    say $book->title . " / " . $book->author;
}
