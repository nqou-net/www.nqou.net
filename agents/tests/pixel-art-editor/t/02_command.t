#!/usr/bin/env perl
# t/02_command.t - Command パターンのテスト
use v5.36;
use Test::More;
use lib 'lib';

use_ok('CanvasMemento');
use_ok('Canvas');
use_ok('DrawCommand');
use_ok('EraseCommand');

subtest 'DrawCommand execute' => sub {
    my $canvas = Canvas->new(width => 8, height => 8);
    my $cmd = DrawCommand->new(
        canvas => $canvas, 
        x => 3, 
        y => 3, 
        color => 'red'
    );
    
    is($canvas->get_pixel(3, 3), ' ', 'pixel initially empty');
    $cmd->execute();
    is($canvas->get_pixel(3, 3), 'red', 'pixel set to red');
};

subtest 'DrawCommand undo' => sub {
    my $canvas = Canvas->new(width => 8, height => 8);
    $canvas->set_pixel(3, 3, 'blue');
    
    my $cmd = DrawCommand->new(
        canvas => $canvas, 
        x => 3, 
        y => 3, 
        color => 'red'
    );
    
    $cmd->execute();
    is($canvas->get_pixel(3, 3), 'red', 'pixel changed to red');
    
    $cmd->undo();
    is($canvas->get_pixel(3, 3), 'blue', 'pixel restored to blue');
};

subtest 'EraseCommand execute' => sub {
    my $canvas = Canvas->new(width => 8, height => 8);
    $canvas->set_pixel(3, 3, 'red');
    
    my $cmd = EraseCommand->new(canvas => $canvas, x => 3, y => 3);
    
    is($canvas->get_pixel(3, 3), 'red', 'pixel initially red');
    $cmd->execute();
    is($canvas->get_pixel(3, 3), ' ', 'pixel erased');
};

subtest 'EraseCommand undo' => sub {
    my $canvas = Canvas->new(width => 8, height => 8);
    $canvas->set_pixel(3, 3, 'green');
    
    my $cmd = EraseCommand->new(canvas => $canvas, x => 3, y => 3);
    
    $cmd->execute();
    is($canvas->get_pixel(3, 3), ' ', 'pixel erased');
    
    $cmd->undo();
    is($canvas->get_pixel(3, 3), 'green', 'pixel restored to green');
};

subtest 'DrawCommand description' => sub {
    my $canvas = Canvas->new(width => 8, height => 8);
    my $cmd = DrawCommand->new(
        canvas => $canvas, 
        x => 5, 
        y => 7, 
        color => 'yellow'
    );
    
    is($cmd->description(), 'Draw yellow at (5, 7)', 'description is correct');
};

done_testing();
