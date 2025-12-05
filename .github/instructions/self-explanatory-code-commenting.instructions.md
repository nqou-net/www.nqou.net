# Self-explanatory Code Commenting

## Core Principle
Write code that speaks for itself. Comment only when necessary to explain WHY, not WHAT.

## Commenting Guidelines

### ❌ AVOID These Comment Types
**Obvious Comments**
```javascript
// Bad: States the obvious
let counter = 0; // Initialize counter to zero
```

**Redundant Comments**

**Outdated Comments**

### ✅ WRITE These Comment Types
**Complex Business Logic** — explain the reasoning and why a choice was made.

**Non-obvious Algorithms** — explain algorithm choice and tradeoffs.

**Regex Patterns** — explain what the regex matches and why.

**API Constraints or Gotchas** — document external constraints.

## Decision Framework
Before writing a comment, ask:
1. Is the code self-explanatory? If yes, no comment.
2. Would a better name eliminate the need? Refactor.
3. Does this explain WHY, not WHAT? Good comment.
4. Will this help future maintainers? Good comment.

## Anti-Patterns to Avoid
- Dead code commented out.
- Changelog entries in comments.
- Decorative divider comments.

## Quality Checklist
- [ ] Explain WHY, not WHAT
- [ ] Grammar and clarity
- [ ] Accurate as code evolves
- [ ] Adds value to maintainers

---
applyTo: '**'
description: 'Guidelines for GitHub Copilot to write comments to achieve self-explanatory code with less comments.'
