# VueJS 3 Development Instructions

## Project Context
- Vue 3.x with Composition API as default
- TypeScript for type safety
- Single File Components (`.vue`) with `<script setup>` syntax
- Modern build tooling (Vite recommended)
- Pinia for application state management

## Development Standards

### Architecture
- Favor the Composition API over the Options API
- Organize components and composables by feature or domain
- Separate UI-focused components from logic-focused components
- Extract reusable logic into composables in `composables/`

### TypeScript Integration
- Enable `strict` mode in `tsconfig.json`
- Use `defineProps` and `defineEmits` with proper types

### Component Design
- Adhere to single responsibility for components
- Use PascalCase for component names and kebab-case for file names
- Keep components small and focused

### Styling
- Use `<style scoped>` or CSS Modules for component styles
- Use utility frameworks (Tailwind) or BEM for class naming

### Performance
- Lazy-load components with dynamic imports
- Use `<Suspense>` and `defineAsyncComponent` for async components

### Data Fetching
- Use composables like `useFetch` or libraries like Vue Query
- Cancel stale requests on component unmount

### Testing
- Use Vue Test Utils and Jest for unit tests
- Add E2E tests with Cypress or Playwright

### Accessibility
- Use semantic HTML and ARIA attributes
- Ensure keyboard navigation and focus management

---
description: 'VueJS 3 development standards and best practices with Composition API and TypeScript'
applyTo: '**/*.vue, **/*.ts, **/*.js, **/*.scss'
