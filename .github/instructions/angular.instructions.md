# Angular Development

## Project Context
- Latest Angular version (use standalone components by default)
- TypeScript for type safety
- Angular CLI for project setup and scaffolding
- Follow Angular Style Guide (https://angular.dev/style-guide)
- Use Angular Material or other modern UI libraries for consistent styling (if specified)

## Development Standards

### Architecture
- Use standalone components unless modules are explicitly required
- Organize code by standalone feature modules or domains for scalability
- Implement lazy loading for feature modules to optimize performance
- Use Angular's built-in dependency injection system effectively
- Structure components with a clear separation of concerns (smart vs. presentational components)

### TypeScript
- Enable strict mode in `tsconfig.json` for type safety
- Define clear interfaces and types for components, services, and models
- Use type guards and union types for robust type checking
- Implement proper error handling with RxJS operators (e.g., `catchError`)

### Component Design
- Follow Angular's component lifecycle hooks best practices
- Use `OnPush` change detection where appropriate for performance
- Keep templates clean and logic in component classes or services
- Use Angular directives and pipes for reusable functionality

### Styling
- Use SCSS with consistent theming and variables
- Implement responsive design with Flexbox and CSS Grid

### State Management
- Use Signals or established state libraries as appropriate
- Keep state normalized for complex structures

### Testing
- Use Jasmine/Karma or Jest for unit tests
- Use Cypress or Playwright for E2E tests

---
description: 'Angular-specific coding standards and best practices'
applyTo:
'**/*.ts, **/*.html, **/*.scss, **/*.css'
