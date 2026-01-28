#!/usr/bin/env perl
# t/03_history_manager.t - HistoryManager のテスト
use v5.36;
use Test::More;
use lib 'lib';

use_ok('CanvasMemento');
use_ok('Canvas');
use_ok('DrawCommand');
use_ok('EraseCommand');
use_ok('HistoryManager');

subtest 'HistoryManager execute' => sub {
    my $canvas = Canvas->new(width => 8, height => 8);
    my $history = HistoryManager->new();
    
    is($history->can_undo(), 0, 'no undo initially');
    is($history->can_redo(), 0, 'no redo initially');
    
    $history->execute(
        DrawCommand->new(canvas => $canvas, x => 3, y => 3, color => 'red')
    );
    
    is($canvas->get_pixel(3, 3), 'red', 'pixel set via history');
    is($history->can_undo(), 1, 'can undo after execute');
    is($history->can_redo(), 0, 'no redo after execute');
};

subtest 'HistoryManager undo' => sub {
    my $canvas = Canvas->new(width => 8, height => 8);
    my $history = HistoryManager->new();
    
    $history->execute(
        DrawCommand->new(canvas => $canvas, x => 3, y => 3, color => 'red')
    );
    
    $history->undo();
    is($canvas->get_pixel(3, 3), ' ', 'pixel restored after undo');
    is($history->can_undo(), 0, 'no more undo');
    is($history->can_redo(), 1, 'can redo after undo');
};

subtest 'HistoryManager redo' => sub {
    my $canvas = Canvas->new(width => 8, height => 8);
    my $history = HistoryManager->new();
    
    $history->execute(
        DrawCommand->new(canvas => $canvas, x => 3, y => 3, color => 'red')
    );
    $history->undo();
    $history->redo();
    
    is($canvas->get_pixel(3, 3), 'red', 'pixel restored after redo');
    is($history->can_undo(), 1, 'can undo after redo');
    is($history->can_redo(), 0, 'no more redo after redo');
};

subtest 'HistoryManager redo cleared after new execute' => sub {
    my $canvas = Canvas->new(width => 8, height => 8);
    my $history = HistoryManager->new();
    
    $history->execute(
        DrawCommand->new(canvas => $canvas, x => 3, y => 3, color => 'red')
    );
    $history->undo();
    is($history->can_redo(), 1, 'can redo');
    
    # 新しい操作を実行
    $history->execute(
        DrawCommand->new(canvas => $canvas, x => 4, y => 4, color => 'blue')
    );
    
    is($history->can_redo(), 0, 'redo cleared after new execute');
};

subtest 'HistoryManager multiple operations' => sub {
    my $canvas = Canvas->new(width => 8, height => 8);
    my $history = HistoryManager->new();
    
    $history->execute(
        DrawCommand->new(canvas => $canvas, x => 1, y => 1, color => 'red')
    );
    $history->execute(
        DrawCommand->new(canvas => $canvas, x => 2, y => 2, color => 'blue')
    );
    $history->execute(
        DrawCommand->new(canvas => $canvas, x => 3, y => 3, color => 'green')
    );
    
    is($history->status(), 'Undo: 3 / Redo: 0', 'status after 3 executes');
    
    $history->undo();
    $history->undo();
    
    is($canvas->get_pixel(1, 1), 'red', 'first pixel remains');
    is($canvas->get_pixel(2, 2), ' ', 'second pixel undone');
    is($canvas->get_pixel(3, 3), ' ', 'third pixel undone');
    is($history->status(), 'Undo: 1 / Redo: 2', 'status after 2 undos');
    
    $history->redo();
    is($canvas->get_pixel(2, 2), 'blue', 'second pixel redone');
    is($history->status(), 'Undo: 2 / Redo: 1', 'status after 1 redo');
};

done_testing();
