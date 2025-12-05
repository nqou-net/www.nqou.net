---
applyTo: "**/*.html,**/*.css,**/*.js,assets/**"
description: "Performance and optimization guidelines"
---

# Performance Guidelines

- Optimize image sizes and use responsive images via Hugo `resources` where appropriate.
- Minify assets for production builds (`hugo --minify`).
- Keep templates efficient: avoid heavy loops in partials and prefer preprocessed resources.
- Suggest measuring page load with lightweight checks and by inspecting generated HTML for large assets.
- Encourage caching-friendly patterns and small bundle sizes for assets.
