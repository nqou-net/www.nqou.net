package Article;
use v5.36;
use parent 'Role::Subject';

sub new ($class, %args) {
    bless {%args}, $class;
}

sub title ($self) { $self->{title} }

sub publish ($self) {
    say "Processing publish: " . $self->title;

    # 記事の保存などのメインロジック...
    $self->save_to_db;

    # ここ！ 通知ロジックが消え、単に「起きたこと」を伝えるだけになった。
    $self->notify_observers;
}

sub save_to_db ($self) {
    say "(Saved to DB)";
}

1;
