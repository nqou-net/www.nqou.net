# Slack Bot Bot Series Verification

## Overview
This directory contains verification scripts and extracted code for the series "PerlでSlackボット指令センターを作る".

## Structure
- `01/`: Vol 1 (Webhook Reception) - `app.psgi` verification
- `02/`: Vol 2 (Command Parsing) - `simple_bot.pl` logic verification
- `03/`: Vol 3 (Refactoring Motivation) - `spaghetti_bot.pl` anti-pattern check
- `04/`: Vol 4 (Command Pattern) - Class separation
- `05/`: Vol 5 (Mediator Pattern) - Mediator dispatch logic
- `06/`: Vol 6 (Observer Pattern) - Notification logic
- `07/`: Vol 7 (Integration) - Full architecture integration test
- `08/`: Vol 8 (Security & Error) - Timeout and error handling
- `09/`: Vol 9 (Final Demo) - Final directory structure and integration check

## Running Tests
To run all tests:

```bash
cd agents/tests/slack-bot
prove -r .
```

## Results
All episodes verified successfully with Perl v5.42.0.
