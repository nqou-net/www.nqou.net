<!-- Copied and focused guidance for AI coding agents. Keep concise and actionable. -->
# GitHub Copilot instructions — repo-specific guidance

This file helps AI coding agents be productive in the `www.nqou.net` Hugo site repository. Keep suggestions precise, non-destructive, and aligned with human review expectations in `AGENTS.md`.

1) Big picture
- Site is a Hugo (module-based) static site using the Stack theme (see `README.md`).
- Source content: [content/](../content/) (posts under [content/post/](../content/post/)).
- Theme & layout: [layouts/], [partials/], [shortcodes/] and theme module configured in `config/_default/`.
- Generated site: [docs/] — do not edit generated files; change source under `content/`, `layouts/`, or `static/`.

2) Primary developer workflows (examples and commands)
- Local preview (human-run): `hugo server -D` (task: "Serve Drafts" is available in VS Code tasks).
- Build for publish (human-run): `hugo --minify` (task: "Build").
- Update theme manually: `hugo mod get -u github.com/CaiJimmy/hugo-theme-stack/v3` then `hugo mod tidy` (see `README.md`).
- There is a helper script `tools/build.pl`; do not run it without human review—confirm arguments first.

3) Project conventions you must follow
- Language: reply in Japanese by default (see `AGENTS.md`) unless user requests otherwise.
- Content front matter: YAML (`---`) with keys: `title`, `draft`, `tags`, `description`.
  - Example: `draft: true` while drafting.
  - Tags: lowercase + hyphen (e.g. `object-oriented`).
- Filenames: use slugs (e.g. `how-to-hugo.md`). Use `content/post/_template.md` as the template for new posts.
- Headings: use ATX style (`##` and deeper). H1 is set via front matter `title`.
- Images: place public images under `static/public_images/` or `static/images/`; for Hugo resource pipelines prefer `assets/` if processing is required.

4) What agents may / may not do
- May: propose content files (Markdown), snippets for `layouts/`/`partials/`/`shortcodes/`, small fixes to templates, and suggested PR descriptions and branch names.
- Must NOT: run system installs, run local builds, edit `docs/` (generated), or push directly to main without human sign-off.

5) Patterns & examples for code/content edits
- To add a post: create `content/post/<slug>.md` using [content/post/_template.md](../content/post/_template.md) front matter and `draft: true`.
- To change site config: prefer edits under `config/_default/` (e.g. `config/_default/config.toml`). Mention required Hugo/module version changes in PR description.
- To add a shortcode or partial: place files in [layouts/shortcodes/] or [layouts/partials/] and include usage examples in the PR body.

6) Integration points & external dependencies
- Theme module: configured via Hugo modules; updating the theme requires `hugo mod` commands (see `README.md`).
- CI / deploy: GitHub Actions deploy to GitHub Pages (do not alter workflow secrets in repo).
- External tools referenced: `linkinator`, `broken-link-checker` for link checks (human-run).

7) PR and commit conventions
- Branch names: `feature/...`, `fix/...` (examples: `feature/write-hugo-article`, `fix/images-optimization`).
- PR title prefix: `[post]` for content, `[site]` for site changes. Include short summary and list manual verification steps (e.g. "Ran `hugo --minify` locally").

+ Quick references (files to inspect when making changes)
+ - Content template: [content/post/_template.md](../content/post/_template.md)
+ - Agent rules: [AGENTS.md](../AGENTS.md)
+ - Site config: [config/_default/config.toml](../config/_default/config.toml)
+ - Static assets: [static/](../static/), generated site: [docs/](../docs/)
+ - Build helper: [tools/build.pl](../tools/build.pl)

9) If anything is ambiguous
- Ask the human reviewer which Hugo version, whether to process images via `assets/` pipelines, and whether the change touches CI/deploy.

---
If this file should include more detail (examples of shortcodes, common partial edits, or PR templates), tell me which area to expand.
