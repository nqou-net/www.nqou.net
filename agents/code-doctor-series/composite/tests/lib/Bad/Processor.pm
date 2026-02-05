package Bad::Processor;
use v5.36;
use experimental qw(builtin class);
use builtin      qw(blessed);

sub new ($class) {
    bless {}, $class;
}

sub process_backup ($self, $node, $backup_path) {
    my @logs;

    # 症状: Nodeの種類によって処理を完全に分けている
    # しかも再帰処理の中に条件分岐が散らばっている
    my $type = blessed($node);

    if ($type eq 'Bad::File') {

        # ファイルならコピー
        push @logs, $node->copy_to($backup_path);
    }
    elsif ($type eq 'Bad::Directory') {

        # ディレクトリなら作成して潜る
        push @logs, $node->make_new($backup_path);

        # 子要素の処理
        foreach my $child ($node->children) {

            # 再帰呼び出し
            # パス結合ロジックもここに混ざってしまっている
            my $new_path = "$backup_path/" . $node->name;
            push @logs, $self->process_backup($child, $new_path);
        }
    }
    else {
        die "Unknown type: $type";
    }

    return \@logs;
}

1;
