package LogReader;
use Moo;
use strict;
use warnings;
use experimental qw(signatures);
use namespace::clean;

# 読み込むファイル名（必須）
has filename => (
    is       => 'ro',
    required => 1,
);

# ファイルハンドル（内部用）
has _fh => (
    is      => 'rw',
    default => undef,
);

# インスタンス生成後に自動実行されるメソッド
sub BUILD ($self, $args) {
    my $filename = $self->filename;
    open my $fh, '<', $filename or die "Cannot open file $filename: $!";
    $self->_fh($fh);
}

# 次の1行を返すメソッド
sub next_line ($self) {
    my $fh = $self->_fh;
    
    # 完全に読み終わっていたらundefを返す
    return undef unless defined $fh;

    my $line = <$fh>;
    
    # ファイル末尾に達したら閉じる（行が取得できなかった場合）
    unless (defined $line) {
        close $fh;
        $self->_fh(undef); # ハンドルをクリア
        return undef;
    }

    chomp $line;
    return $line;
}

1;
