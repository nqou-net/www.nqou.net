#!/usr/bin/env perl
# t/01_canvas.t - Canvas クラスのテスト
use v5.36;
use Test::More;
use lib 'lib';

use_ok('CanvasMemento');
use_ok('Canvas');

subtest 'Canvas creation' => sub {
    my $canvas = Canvas->new(width => 8, height => 8);
    ok($canvas, 'Canvas created');
    is($canvas->width, 8, 'width is 8');
    is($canvas->height, 8, 'height is 8');
};

subtest 'set_pixel and get_pixel' => sub {
    my $canvas = Canvas->new(width => 8, height => 8);
    $canvas->set_pixel(3, 3, 'red');
    is($canvas->get_pixel(3, 3), 'red', 'pixel set correctly');
    is($canvas->get_pixel(0, 0), ' ', 'unset pixel is space');
};

subtest 'boundary check' => sub {
    my $canvas = Canvas->new(width => 8, height => 8);
    $canvas->set_pixel(-1, 0, 'red');  # should be ignored
    $canvas->set_pixel(0, -1, 'red');  # should be ignored
    $canvas->set_pixel(8, 0, 'red');   # should be ignored
    $canvas->set_pixel(0, 8, 'red');   # should be ignored
    is($canvas->get_pixel(-1, 0), ' ', 'out of bounds returns space');
    is($canvas->get_pixel(0, 0), ' ', 'in bounds is space');
};

subtest 'erase_pixel' => sub {
    my $canvas = Canvas->new(width => 8, height => 8);
    $canvas->set_pixel(3, 3, 'red');
    is($canvas->get_pixel(3, 3), 'red', 'pixel is red');
    $canvas->erase_pixel(3, 3);
    is($canvas->get_pixel(3, 3), ' ', 'pixel erased');
};

subtest 'memento creation and restoration' => sub {
    my $canvas = Canvas->new(width => 8, height => 8);
    $canvas->set_pixel(2, 2, 'blue');
    
    my $memento = $canvas->create_memento();
    ok($memento, 'memento created');
    isa_ok($memento, 'CanvasMemento');
    
    $canvas->set_pixel(2, 2, 'green');
    is($canvas->get_pixel(2, 2), 'green', 'pixel changed to green');
    
    $canvas->restore_memento($memento);
    is($canvas->get_pixel(2, 2), 'blue', 'pixel restored to blue');
};

done_testing();
