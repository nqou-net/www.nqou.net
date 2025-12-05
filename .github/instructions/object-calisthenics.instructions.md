# Object Calisthenics Rules

## Objective
This rule enforces the principles of Object Calisthenics to ensure clean, maintainable, and robust code in the backend, **primarily for business domain code**.

## Scope and Application
- **Primary focus**: Business domain classes (aggregates, entities, value objects, domain services)
- **Secondary focus**: Application layer services and use case handlers
- **Exemptions**: DTOs, API models/contracts, Configuration classes, Simple data containers without business logic, Infrastructure code where flexibility is needed

## Key Principles
1. **One Level of Indentation per Method**
2. **Don't Use the ELSE Keyword** — use early returns / fail-fast
3. **Wrapping All Primitives and Strings** — wrap primitives in meaningful types
4. **First Class Collections** — encapsulate collection behavior
5. **One Dot per Line** — limit method chaining in a single line
6. **Don't abbreviate** — use meaningful names
7. **Keep entities small** — limits on methods and lines
8. **No Classes with More Than Two Instance Variables**
9. **No Getters/Setters in Domain Classes** — prefer encapsulation and factories

## Implementation Guidelines
- Apply rules mainly to domain classes; DTOs can be more flexible.
- Enforce during code reviews and tests.

---
applyTo: '**/*.{cs,ts,java}'
description: Enforces Object Calisthenics principles for business domain code to ensure clean, maintainable, and robust code
