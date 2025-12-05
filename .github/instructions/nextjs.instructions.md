# Next.js Best Practices for LLMs (2025)

## 1. Project Structure & Organization
- Use the `app/` directory (App Router) for all new projects. Prefer it over the legacy `pages/` directory.
- Top-level folders: `app/`, `public/`, `lib/`, `components/`, `contexts/`, `styles/`, `hooks/`, `types/`.
- Colocation: Place files near where they are used but avoid deep nesting.

## 2.1 Server and Client Component Integration (App Router)
- Never use `next/dynamic` with `{ ssr: false }` inside a Server Component.
- Move client-only logic into Client Components with `'use client'`.

## Component Best Practices
- Component Types: Server Components for data fetching, Client Components for interactivity.
- Naming Conventions: PascalCase for components, camelCase for hooks, kebab-case for static assets.

## API Routes
- Prefer API Routes over Edge Functions unless needed.
- Location: `app/api/`.
- Use Web `Request` and `Response` APIs, validate and sanitize inputs.

## General Best Practices
- Use TypeScript with `strict` enabled.
- Use ESLint & Prettier, store secrets in `.env.local`.
- Testing: Jest, React Testing Library, or Playwright.
- Accessibility: semantic HTML and ARIA attributes.
- Performance: image/font optimization, Suspense, code-splitting.

---
applyTo: '**'
