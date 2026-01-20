# Iterator Pattern Test Suite

This directory contains automated tests for the Iterator pattern article series "本棚アプリで覚える集合体の巡回" (Bookshelf app - Learning aggregate traversal).

## Directory Structure

```
iterator-pattern/
├── 01/                          # Article 1: Book and BookShelf classes
│   ├── bookshelf.pl            # Complete working code
│   └── t/basic.t               # Test file
├── 02/                          # Article 2: For loop and encapsulation issues
│   ├── bookshelf.pl
│   └── t/basic.t
├── 03/                          # Article 3: BookIteratorRole and BookShelfIterator
│   ├── bookshelf.pl
│   └── t/basic.t
├── 04/                          # Article 4: iterator() method implementation
│   ├── bookshelf.pl
│   └── t/basic.t
├── 05/                          # Article 5: Final Iterator pattern with ReverseBookShelfIterator
│   ├── bookshelf.pl
│   └── t/basic.t
├── run_all_tests.pl            # Script to run all tests at once
└── README.md                   # This file
```

## Requirements

- Perl v5.36 or later
- Moo module (install with `sudo apt-get install libmoo-perl` or `cpanm Moo`)
- Test2::Suite module (install with `sudo apt-get install libtest2-suite-perl` or `cpanm Test2::Suite`)

## Running Tests

### Run All Tests

```bash
perl run_all_tests.pl
```

### Run Individual Tests

```bash
cd 01
prove -v t/basic.t
```

Or run the program directly:

```bash
cd 01
perl bookshelf.pl
```

## What Each Test Verifies

Each test file (`t/basic.t`) verifies:

1. **Output Correctness**: The output matches the expected "実行結果" from the article
2. **No Warnings**: The code runs without any warnings

## Test Implementation Notes

- Tests use Test2::V0 framework for modern Perl testing
- UTF-8 encoding is properly handled using `Encode::decode`
- Output is captured using `qx{}` (backticks) to ensure proper UTF-8 handling
- Warnings are captured separately using `local $SIG{__WARN__}`

## Article Series Summary

1. **第1回**: Basic BookShelf and Book classes
2. **第2回**: Two approaches for iterating (direct access vs. method access)
3. **第3回**: Introduction of BookIteratorRole and BookShelfIterator
4. **第4回**: Adding iterator() method to BookShelf
5. **第5回**: Complete Iterator pattern with reverse iteration support

## Expected Test Results

When all tests pass, you should see:

```
======================================================================
Running Iterator Pattern Test Suite
======================================================================

----------------------------------------------------------------------
Running test 01: .../01/t/basic.t
----------------------------------------------------------------------
✅ Test 01: PASSED

... (tests 02-05 similar) ...

======================================================================
Test Summary
======================================================================
Total tests: 5
Passed: 5
Failed: 0

🎉 All tests passed!
```

## Verification Date

All code extracted and verified: 2026-01-20

## License

Code examples from the nqou.net articles. Tests written to verify article code correctness.
