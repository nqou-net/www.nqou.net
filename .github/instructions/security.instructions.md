---
applyTo: "**/*"
description: "Security best practices"
---

# Security Guidelines

- Never store secrets, tokens, or credentials in the repository. Use CI secrets or external secret stores.
- Validate external links and user-controlled inputs when rendering templates.
- Prefer read-only permissions for automation where possible; flag any requested elevation for human review.
- Encourage dependency updates and security scanning as part of normal maintenance.
- Prompt human review for any change that modifies deployment, CI, or secret handling.
