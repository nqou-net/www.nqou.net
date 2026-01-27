# lib/DrawCommand.pm
package DrawCommand {
    use v5.36;
    use Moo;

    has canvas  => (is => 'ro', required => 1);
    has x       => (is => 'ro', required => 1);
    has y       => (is => 'ro', required => 1);
    has color   => (is => 'ro', required => 1);
    has memento => (is => 'rw');  # 実行前の状態を保存

    sub execute($self) {
        # 実行前の状態を保存
        $self->memento($self->canvas->create_memento());
        # 描画を実行
        $self->canvas->set_pixel($self->x, $self->y, $self->color);
    }

    sub undo($self) {
        # 保存した状態を復元
        if ($self->memento) {
            $self->canvas->restore_memento($self->memento);
        }
    }

    sub description($self) {
        return sprintf("Draw %s at (%d, %d)", $self->color, $self->x, $self->y);
    }
}

1;
