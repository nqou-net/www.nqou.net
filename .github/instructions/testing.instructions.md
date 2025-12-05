---
applyTo: "**/*test*,**/tests/**,**/*.spec.*"
description: "Testing standards and practices"
---

# Testing Guidelines

Based on: https://github.com/github/awesome-copilot/tree/main

- Define a testing strategy: unit tests for small helpers, integration tests for critical flows, and manual end-to-end checks for site builds.
- Keep tests fast and deterministic; prefer small fixtures and mocks for external dependencies.
- For content and templates, prefer snapshot or rendering checks to catch layout regressions.
- Document how to run tests and linters in the README; recommend `go test ./...` for Go modules and explain any site-specific validation steps.
- Require human review for tests that touch production content or publishing workflows.
