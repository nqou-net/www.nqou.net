#!/usr/bin/env perl
use v5.36;
use lib 'agents/code-doctor-series/adapter/impl/lib';

use LegacyLogger;
use ModernLogger;
use LoggerAdapter;

# --- Legacy Client Code ---
# This class represents the thousands of lines of code we don't want to change.
package ClientApp;
use v5.36;

sub new($class, $logger) {
    return bless {logger => $logger}, $class;
}

sub do_work($self) {
    $self->{logger}->log("Starting work...");

    # ... complex logic ...
    $self->{logger}->log("Work finished.");
}

package main;

say "--- Case 1: Legacy System (Before) ---";
my $old_logger = LegacyLogger->new;
my $app_v1     = ClientApp->new($old_logger);
$app_v1->do_work;

say "\n--- Case 2: Modern System with Adapter (After) ---";

# We want to use ModernLogger, but ClientApp expects log($msg).
my $modern = ModernLogger->new;

# If we passed $modern directly:
# ClientApp->new($modern)->do_work; # CRASH! ModernLogger doesn't have log() method.

# So we use the Adapter:
my $adapter = LoggerAdapter->new($modern);
my $app_v2  = ClientApp->new($adapter);

# ClientApp logic remains perfectly untouched!
$app_v2->do_work;
