#!/usr/bin/env perl
# 第9回: 完成版 - 秘密のメッセンジャー
# Observer × Decorator × Command の3パターン統合
use v5.36;
use Moo;
use MIME::Base64 qw(encode_base64 decode_base64);
use namespace::clean;

#=============================================================================
# Encryptor::Role (Decorator パターン)
#=============================================================================
package Encryptor::Role {
    use Moo::Role;
    use namespace::clean;

    requires 'encrypt';
    requires 'decrypt';

    has 'wrapped' => (is => 'ro', predicate => 'has_wrapped');

    sub process_encrypt($self, $text) {
        my $result = $self->encrypt($text);
        return $self->has_wrapped ? $self->wrapped->process_encrypt($result) : $result;
    }

    sub process_decrypt($self, $text) {
        my $result = $self->has_wrapped ? $self->wrapped->process_decrypt($text) : $text;
        return $self->decrypt($result);
    }
}

package NullEncryptor {
    use Moo;
    with 'Encryptor::Role';
    use namespace::clean;
    sub encrypt($self, $text) {$text}
    sub decrypt($self, $text) {$text}
}

package XorEncryptor {
    use Moo;
    with 'Encryptor::Role';
    use namespace::clean;
    has 'key' => (is => 'ro', default => 42);

    sub encrypt($self, $text) {
        join '', map { chr(ord($_) ^ $self->key) } split //, $text;
    }
    sub decrypt($self, $text) { $self->encrypt($text) }
}

package Base64Encryptor {
    use Moo;
    with 'Encryptor::Role';
    use MIME::Base64 qw(encode_base64 decode_base64);
    use namespace::clean;
    sub encrypt($self, $text) { encode_base64($text, '') }
    sub decrypt($self, $text) { decode_base64($text) }
}

#=============================================================================
# Observer パターン
#=============================================================================
package Subject::Role {
    use Moo::Role;
    use namespace::clean;
    has 'observers' => (is => 'rw', default => sub { [] });
    sub attach($self, $o) { push $self->observers->@*, $o }

    sub detach($self, $o) {
        $self->observers([grep { $_ != $o } $self->observers->@*]);
    }
    sub notify($self, $event, @args) { $_->update($self, $event, @args) for $self->observers->@* }
}

package Observer::Role {
    use Moo::Role;
    use namespace::clean;
    requires 'update';
}

package ConsoleNotifier {
    use Moo;
    with 'Observer::Role';
    use namespace::clean;
    has 'name' => (is => 'ro', default => 'Console');

    sub update($self, $subject, $event, @args) {
        if ($event eq 'new_message') {
            my ($msg) = @args;
            say "[", $self->name, "] 📩 新着: ", $msg->sender;
        }
        elsif ($event eq 'message_deleted') {
            say "[", $self->name, "] 🗑️ メッセージ削除";
        }
    }
}

#=============================================================================
# Command パターン
#=============================================================================
package Command::Role {
    use Moo::Role;
    use namespace::clean;
    requires 'execute';
    requires 'undo';
    has 'description' => (is => 'ro', default => '');
}

package CommandHistory {
    use Moo;
    use namespace::clean;
    has 'history' => (is => 'rw', default => sub { [] });
    sub execute($self, $cmd) { $cmd->execute; push $self->history->@*, $cmd }
    sub undo($self)          { return unless $self->history->@*; (pop $self->history->@*)->undo }
    sub can_undo($self)      { scalar $self->history->@* > 0 }
    sub get_history($self)   { $self->history->@* }
}

#=============================================================================
# メッセージ関連クラス
#=============================================================================
package Message {
    use Moo;
    use namespace::clean;
    has 'sender'    => (is => 'ro', required => 1);
    has 'recipient' => (is => 'ro', required => 1);
    has 'body'      => (is => 'ro', required => 1);
    has 'timestamp' => (is => 'ro', default  => sub {time});

    sub format($self) {
        sprintf "[%s] %s: %s", scalar(localtime($self->timestamp)), $self->sender, $self->body;
    }
}

package SecretMessageBox {
    use Moo;
    with 'Subject::Role';
    use namespace::clean;

    has 'owner'     => (is => 'ro', required => 1);
    has 'messages'  => (is => 'rw', default  => sub { [] });
    has 'encryptor' => (is => 'ro', default  => sub { NullEncryptor->new });

    sub add($self, $msg) {
        my $encrypted_body = $self->encryptor->process_encrypt($msg->body);
        my $stored         = Message->new(
            sender    => $msg->sender,
            recipient => $msg->recipient,
            body      => $encrypted_body,
            timestamp => $msg->timestamp
        );
        push $self->messages->@*, $stored;
        $self->notify('new_message', $msg);
    }

    sub remove_last($self) {
        my $msg = pop $self->messages->@*;
        $self->notify('message_deleted') if $msg;
        return $msg;
    }

    sub remove_at($self, $idx) {
        my $msg = splice $self->messages->@*, $idx, 1;
        $self->notify('message_deleted') if $msg;
        return $msg;
    }

    sub insert_at($self, $idx, $msg) {
        splice $self->messages->@*, $idx, 0, $msg;
    }

    sub get_all($self) {
        my @decrypted;
        for my $msg ($self->messages->@*) {
            my $body = $self->encryptor->process_decrypt($msg->body);
            push @decrypted,
                Message->new(
                sender    => $msg->sender,
                recipient => $msg->recipient,
                body      => $body,
                timestamp => $msg->timestamp
                );
        }
        return @decrypted;
    }

    sub count($self) { scalar $self->messages->@* }
}

#=============================================================================
# Commandクラス
#=============================================================================
package SendCommand {
    use Moo;
    with 'Command::Role';
    use namespace::clean;
    has 'box'          => (is      => 'ro', required => 1);
    has 'message'      => (is      => 'ro', required => 1);
    has '+description' => (default => sub {'送信'});
    sub execute($self) { $self->box->add($self->message) }
    sub undo($self)    { $self->box->remove_last }
}

package DeleteCommand {
    use Moo;
    with 'Command::Role';
    use namespace::clean;
    has 'box'          => (is      => 'ro', required => 1);
    has 'index'        => (is      => 'ro', required => 1);
    has 'deleted_msg'  => (is      => 'rw');
    has '+description' => (default => sub {'削除'});
    sub execute($self) { $self->deleted_msg($self->box->remove_at($self->index)) }
    sub undo($self)    { $self->box->insert_at($self->index, $self->deleted_msg) }
}

#=============================================================================
# メインアプリケーション
#=============================================================================
package SecretMessenger {
    use Moo;
    use namespace::clean;

    has 'box'     => (is => 'ro', required => 1);
    has 'history' => (is => 'ro', default  => sub { CommandHistory->new });

    sub send($self, $sender, $body) {
        my $msg = Message->new(
            sender    => $sender,
            recipient => $self->box->owner,
            body      => $body
        );
        $self->history->execute(SendCommand->new(box => $self->box, message => $msg));
    }

    sub delete($self, $index) {
        $self->history->execute(DeleteCommand->new(box => $self->box, index => $index));
    }

    sub undo($self) {
        if ($self->history->can_undo) {
            $self->history->undo;
            say "↩️ Undo完了";
        }
        else {
            say "⚠️ Undoする操作がありません";
        }
    }

    sub show_inbox($self) {
        say "\n📬 ", $self->box->owner, " のメッセージボックス:";
        my @msgs = $self->box->get_all;
        if (@msgs) {
            for my $i (0 .. $#msgs) {
                say "  [$i] ", $msgs[$i]->format;
            }
        }
        else {
            say "  (空です)";
        }
    }

    sub show_history($self) {
        say "\n📋 操作履歴:";
        my @history = $self->history->get_history;
        if (@history) {
            say "  - ", $_->description for @history;
        }
        else {
            say "  (なし)";
        }
    }
}

#=============================================================================
# デモ
#=============================================================================
sub demo {
    say "=" x 60;
    say "🔐 秘密のメッセンジャー - 完成版デモ";
    say "=" x 60;

    # 暗号化チェーン: Base64 → XOR
    my $encryptor = Base64Encryptor->new(wrapped => XorEncryptor->new(key => 42));

    # Bobのメッセージボックス
    my $box = SecretMessageBox->new(
        owner     => 'Bob',
        encryptor => $encryptor
    );

    # 通知Observer
    $box->attach(ConsoleNotifier->new(name => 'Desktop'));

    # メッセンジャーアプリ
    my $app = SecretMessenger->new(box => $box);

    say "\n--- メッセージ送信 ---";
    $app->send('Alice',   'こんにちは、秘密のメッセージです！');
    $app->send('Charlie', 'Meeting at 3pm');
    $app->send('Diana',   'パスワード: secret123');

    $app->show_inbox;
    $app->show_history;

    say "\n--- 暗号化確認（内部データ）---";
    say "保存データ: ", $box->messages->[0]->body;

    say "\n--- 削除 & Undo ---";
    $app->delete(1);
    $app->show_inbox;

    $app->undo;
    $app->show_inbox;

    say "\n--- 3パターンの役割 ---";
    say "🔍 Observer: メッセージ到着/削除時に自動通知";
    say "🧅 Decorator: XOR→Base64の暗号化レイヤー";
    say "📝 Command: 送信/削除操作の履歴管理とUndo";
}

demo() unless caller;

1;
