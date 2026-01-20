#!/usr/bin/env perl
# Run all Iterator pattern tests
use v5.36;
use File::Basename qw(dirname);
use Cwd qw(abs_path);

# Get the base directory
my $base_dir = dirname(abs_path($0));

say "=" x 70;
say "Running Iterator Pattern Test Suite";
say "=" x 70;
say "";

my @test_dirs = qw(01 02 03 04 05);
my $total_tests = 0;
my $passed_tests = 0;
my @failed_tests;

for my $test_dir (@test_dirs) {
    my $dir = "$base_dir/$test_dir";
    my $test_file = "$dir/t/basic.t";
    
    unless (-f $test_file) {
        say "❌ Test not found: $test_file";
        next;
    }
    
    say "-" x 70;
    say "Running test $test_dir: $test_file";
    say "-" x 70;
    
    # Change to test directory so relative paths work
    chdir $dir or die "Cannot chdir to $dir: $!";
    
    # Run the test
    my $result = system("prove", "-v", "t/basic.t");
    my $exit_code = $? >> 8;
    
    $total_tests++;
    if ($exit_code == 0) {
        $passed_tests++;
        say "✅ Test $test_dir: PASSED";
    } else {
        push @failed_tests, $test_dir;
        say "❌ Test $test_dir: FAILED (exit code: $exit_code)";
    }
    say "";
}

# Print summary
say "=" x 70;
say "Test Summary";
say "=" x 70;
say "Total tests: $total_tests";
say "Passed: $passed_tests";
say "Failed: " . scalar(@failed_tests);

if (@failed_tests) {
    say "\nFailed tests: " . join(", ", @failed_tests);
    exit 1;
} else {
    say "\n🎉 All tests passed!";
    exit 0;
}
