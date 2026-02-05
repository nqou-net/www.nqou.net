#!/usr/bin/env perl
use v5.36;
use lib 'lib';
use MyApp::PurchaseFacade;

# Doctor's Code: "Simple Interface"
# 処方: 複雑な裏側の処理は Facade にお任せ。
# クライアントは「何を買うか」だけに集中できる。

my $facade = MyApp::PurchaseFacade->new;

say "Processing purchase via Facade...";
$facade->purchase_item("admin", "item_A");
say "Purchase completed.";

say "Processing purchase via Facade...";
$facade->purchase_item("admin", "item_B");
say "Purchase completed.";
