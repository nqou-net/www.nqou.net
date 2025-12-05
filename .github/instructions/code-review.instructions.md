---
applyTo: "**/*.md,**/*.html,**/*.go,**/*.pl,**/*.sh"
description: "Code review standards and PR guidelines"
---

# Code Review Guidelines

- PR titles: use `[post]` for content, `[site]` for structural/site changes, and short description.
- Request at least one reviewer for non-trivial changes; always require human approval for build or publish changes.
- Review checklist: frontmatter presence, image alt text, tag conventions (lowercase, hyphens), no changes to `docs/` directly.
- Keep PRs small and focused; prefer incremental improvements.
- Include a suggested commit message when Copilot proposes patches.
