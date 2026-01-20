use v5.36;

package Editor {
    use Moo;

    has text => (
        is      => 'rw',
        default => '',
    );
}

package Command::Role {
    use Moo::Role;

    requires 'execute';
    requires 'undo';
}

package InsertCommand {
    use Moo;
    with 'Command::Role';

    has editor => (
        is       => 'ro',
        required => 1,
    );

    has position => (
        is       => 'ro',
        required => 1,
    );

    has string => (
        is       => 'ro',
        required => 1,
    );

    sub execute ($self) {
        my $editor   = $self->editor;
        my $position = $self->position;
        my $string   = $self->string;

        my $current  = $editor->text;
        my $new_text = substr($current, 0, $position)
                     . $string
                     . substr($current, $position);
        $editor->text($new_text);
    }

    sub undo ($self) {
        my $editor   = $self->editor;
        my $position = $self->position;
        my $length   = length($self->string);

        my $current  = $editor->text;
        my $new_text = substr($current, 0, $position)
                     . substr($current, $position + $length);
        $editor->text($new_text);
    }
}

package DeleteCommand {
    use Moo;
    with 'Command::Role';

    has editor => (
        is       => 'ro',
        required => 1,
    );

    has position => (
        is       => 'ro',
        required => 1,
    );

    has length => (
        is       => 'ro',
        required => 1,
    );

    has _deleted_string => (
        is      => 'rw',
        default => '',
    );

    sub execute ($self) {
        my $editor   = $self->editor;
        my $position = $self->position;
        my $length   = $self->length;

        my $current = $editor->text;
        my $deleted = substr($current, $position, $length);
        $self->_deleted_string($deleted);

        my $new_text = substr($current, 0, $position)
                     . substr($current, $position + $length);
        $editor->text($new_text);
    }

    sub undo ($self) {
        my $editor   = $self->editor;
        my $position = $self->position;
        my $deleted  = $self->_deleted_string;

        my $current  = $editor->text;
        my $new_text = substr($current, 0, $position)
                     . $deleted
                     . substr($current, $position);
        $editor->text($new_text);
    }
}

package MacroCommand {
    use Moo;
    with 'Command::Role';

    has commands => (
        is      => 'ro',
        default => sub { [] },
    );

    sub add_command ($self, $command) {
        push $self->commands->@*, $command;
    }

    sub execute ($self) {
        for my $cmd ($self->commands->@*) {
            $cmd->execute;
        }
    }

    sub undo ($self) {
        for my $cmd (reverse $self->commands->@*) {
            $cmd->undo;
        }
    }
}

package History {
    use Moo;

    has undo_stack => (
        is      => 'ro',
        default => sub { [] },
    );

    has redo_stack => (
        is      => 'ro',
        default => sub { [] },
    );

    sub execute_command ($self, $command) {
        $command->execute;
        push $self->undo_stack->@*, $command;
        $self->redo_stack->@* = ();
    }

    sub undo ($self) {
        return unless $self->undo_stack->@*;

        my $command = pop $self->undo_stack->@*;
        $command->undo;
        push $self->redo_stack->@*, $command;
    }

    sub redo ($self) {
        return unless $self->redo_stack->@*;

        my $command = pop $self->redo_stack->@*;
        $command->execute;
        push $self->undo_stack->@*, $command;
    }
}

sub show_text ($editor) {
    say "テキスト: '" . $editor->text . "'";
}

sub do_insert ($editor, $history) {
    print "挿入位置: ";
    my $pos_input = <STDIN>;
    return unless defined $pos_input;
    chomp $pos_input;

    if ($pos_input !~ /\A-?\d+\z/) {
        say "エラー: 位置は数値で指定してください";
        return;
    }

    my $position = int($pos_input);
    my $max_pos  = length($editor->text);

    if ($position < 0 || $position > $max_pos) {
        say "エラー: 位置は0〜$max_posの範囲で指定してください";
        return;
    }

    print "挿入文字列: ";
    my $string = <STDIN>;
    return unless defined $string;
    chomp $string;

    if ($string eq '') {
        say "エラー: 挿入文字列が空です";
        return;
    }

    my $cmd = InsertCommand->new(
        editor   => $editor,
        position => $position,
        string   => $string,
    );
    $history->execute_command($cmd);
    show_text($editor);
}

sub do_delete ($editor, $history) {
    if ($editor->text eq '') {
        say "エラー: テキストが空です";
        return;
    }

    print "削除開始位置: ";
    my $pos_input = <STDIN>;
    return unless defined $pos_input;
    chomp $pos_input;

    if ($pos_input !~ /\A-?\d+\z/) {
        say "エラー: 位置は数値で指定してください";
        return;
    }

    my $position = int($pos_input);
    my $max_pos  = length($editor->text) - 1;

    if ($position < 0 || $position > $max_pos) {
        say "エラー: 位置は0〜$max_posの範囲で指定してください";
        return;
    }

    print "削除文字数: ";
    my $len_input = <STDIN>;
    return unless defined $len_input;
    chomp $len_input;

    if ($len_input !~ /\A-?\d+\z/) {
        say "エラー: 削除文字数は数値で指定してください";
        return;
    }

    my $length     = int($len_input);
    my $max_length = length($editor->text) - $position;

    if ($length < 1 || $length > $max_length) {
        say "エラー: 削除文字数は1〜$max_lengthの範囲で指定してください";
        return;
    }

    my $cmd = DeleteCommand->new(
        editor   => $editor,
        position => $position,
        length   => $length,
    );
    $history->execute_command($cmd);
    show_text($editor);
}

sub do_undo ($editor, $history) {
    if ($history->undo_stack->@* == 0) {
        say "Undoする操作がありません";
        return;
    }

    $history->undo;
    say "Undo実行";
    show_text($editor);
}

sub do_redo ($editor, $history) {
    if ($history->redo_stack->@* == 0) {
        say "Redoする操作がありません";
        return;
    }

    $history->redo;
    say "Redo実行";
    show_text($editor);
}

sub main {
    say "=== 簡易テキストエディタ ===";
    say "コマンド: i(挿入), d(削除), u(undo), r(redo), p(表示), q(終了)";
    say "";

    my $editor  = Editor->new;
    my $history = History->new;

    while (1) {
        print "> ";
        my $input = <STDIN>;
        last unless defined $input;

        chomp $input;
        my $cmd = lc($input);

        if ($cmd eq 'q') {
            say "終了します。";
            last;
        }
        elsif ($cmd eq 'p') {
            show_text($editor);
        }
        elsif ($cmd eq 'i') {
            do_insert($editor, $history);
        }
        elsif ($cmd eq 'd') {
            do_delete($editor, $history);
        }
        elsif ($cmd eq 'u') {
            do_undo($editor, $history);
        }
        elsif ($cmd eq 'r') {
            do_redo($editor, $history);
        }
        else {
            say "不明なコマンド: '$input'" if $input ne '';
        }
    }
}

1;
