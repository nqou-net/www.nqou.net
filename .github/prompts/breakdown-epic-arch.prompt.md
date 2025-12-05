---
agent: 'agent'
description: 'Prompt for creating the high-level technical architecture for an Epic, based on a Product Requirements Document.'
---
# Epic

## Goal

Act as a Senior Software Architect. Your task is to take an Epic PRD and create a high-level technical architecture specification. This document will guide the development of the epic, outlining the major components, features, and technical enablers required.

## Context

Considerations

- The Epic PRD from the Product Manager.
- **Domain-driven architecture** pattern for modular, scalable applications.
- **Self-hosted and SaaS deployment** requirements.
- **Docker containerization** for all services.
- **TypeScript/Next.js** stack with App Router.
- **Turborepo monorepo** patterns.
- **tRPC** for type-safe APIs.
- **Stack Auth** for authentication.

**Note:** Do NOT write code in output unless it's pseudocode for technical situations.

## Output

Provide a comprehensive Epic Architecture Specification in Markdown format suitable to save to `/docs/ways-of-work/plan/{epic-name}/arch.md`.
