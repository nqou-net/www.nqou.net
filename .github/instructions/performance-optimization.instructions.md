# Performance Optimization Best Practices

## Introduction
Performance isn't just a buzzword—it's the difference between a product people love and one they abandon. This guide covers frontend, backend, and database layers, with practical advice, checklists, and examples.

## General Principles
- Measure first, optimize second. Use profilers and monitoring tools.
- Optimize the common case.
- Avoid premature optimization.
- Minimize resource usage and prefer simplicity.
- Document performance assumptions and automate performance tests.

## Frontend
- Minimize DOM manipulations.
- Use virtual DOM frameworks efficiently and stable keys in lists.
- Defer non-critical rendering and use CSS animations.
- Asset optimization: image compression, modern formats, lazy loading.
- Network optimization: reduce requests, use HTTP/2/3, set caching headers.

## Backend
- Use efficient algorithms and data structures.
- Use asynchronous I/O and worker pools for CPU-bound tasks.
- Cache expensive computations and avoid N+1 queries.

## Database Performance
- Index appropriately, avoid SELECT *, and analyze query plans.
- Use pagination and streaming for large datasets.

## Profiling and Benchmarking
- Use language-specific profilers and microbenchmarks.
- Continuous performance testing and set performance budgets.

## Code Review Checklist for Performance
- Are there algorithmic inefficiencies?
- Are data structures appropriate?
- Are large payloads paginated and assets optimized?
- Are there automated tests or benchmarks for performance-critical code?

---
applyTo: '*'
description: 'The most comprehensive, practical, and engineer-authored performance optimization instructions.'
