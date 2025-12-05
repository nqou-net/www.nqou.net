# TanStack Start with Shadcn/ui Development Guide

## Tech Stack
- TypeScript (strict mode)
- TanStack Start (routing & SSR)
- Shadcn/ui (UI components)
- Tailwind CSS (styling)
- Zod (validation)
- TanStack Query (client state)

## Code Style Rules
- NEVER use `any` type - always use proper TypeScript types
- Prefer function components over class components
- Always validate external data with Zod schemas
- Include error and pending boundaries for all routes
- Follow accessibility best practices with ARIA attributes

## Component Patterns
- Use function components with proper TypeScript interfaces
- Use Shadcn/ui components when appropriate

## Data Fetching
- Use Route Loaders for initial page data
- Use React Query for frequently updating data

## Zod Validation
- Define schemas in `src/lib/schemas.ts` and safe-parse external data

## File Organization
- `src/components/ui/` — Shadcn/ui components
- `src/lib/schemas.ts` — Zod schemas
- `src/routes/` — file-based routes

---
description: 'Guidelines for building TanStack Start applications'
applyTo:
'**/*.ts, **/*.tsx, **/*.js, **/*.jsx, **/*.css, **/*.scss, **/*.json'
