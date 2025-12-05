---
applyTo: "**/*.md,**/*.html,**/*.toml,**/*.go,**/*.yaml"
description: "Guidelines for Hugo content and site maintenance"
---

# Hugo / Static Site Guidelines

Based on: https://github.com/github/awesome-copilot/tree/main

- Use YAML frontmatter for content files; include `title`, `draft`, `tags`, and `description` keys.
- Keep drafts as `draft: true` until ready to publish; use `hugo server -D` for previewing drafts locally.
- Follow the repository's content structure: place posts in `content/post/` and site assets in `static/`.
- Prefer short, descriptive alt text for images and reference images from `static/` or Hugo `resources`.
- Keep layouts and partials small and composable; prefer existing shortcodes over raw HTML.
- Use semantic headings (H1 from frontmatter/title; top-level sections as `##`).
- Keep changes to generated `docs/` avoided; edit sources and rebuild instead.

Testing & Validation:
- Recommend human-run build steps: `hugo server -D` (preview) and `hugo --minify` (production).

Accessibility & SEO:
- Add meaningful `description` in frontmatter and sensible `tags` using lowercase and hyphens.
- Recommend checking images and link accessibility during preview.
