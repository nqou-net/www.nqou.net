---
agent: 'software-engineer-agent-v1'
tools: ['codebase','search']
description: 'Generate test scaffolding or assertions for repository code'
---

Ask what area to test (Go helper, build script, template rendering). Produce a test scaffold with clear instructions for where to place the test and how to run it (`go test ./...`), but do not add heavy dependencies. Keep tests focused and fast.
