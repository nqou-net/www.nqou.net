# AGENTS.md — Guidance for AI coding agents

This file is an agent-focused companion to `README.md`. It contains concrete, actionable instructions an automated agent needs to work effectively on this repository (a Hugo-based website: `www.nqou.net`). Follow the guidance at https://agents.md/ when updating this document.

---

**Project overview**

- Purpose: A Hugo-powered personal/technical blog, content in `content/` and built site available in `docs/`.
- Main technologies: Hugo (static site generator), plain Markdown for content, some helper scripts in `tools/` (Perl), and shell build helpers.
- Key directories:
  - `content/` — source content. Posts live under `content/post/` (timestamp or `YYYY/MM/DD` naming is used).
  - `layouts/`, `partials/`, `shortcodes/` — theme/layout code.
  - `static/` — static assets copied to the site root.
  - `resources/` — Hugo resource pipeline outputs.
  - `docs/` — generated site (already present in repo; often used for GitHub Pages publishing).

**Quick facts for agents**

- Preview locally: `hugo server -D`
- Build for production: `hugo --minify`
- VS Code tasks: `Serve Drafts` (runs `hugo server -D`) and `Build` (runs `hugo --minify`) are defined in workspace tasks.
- Content location: `content/post/` (new posts should follow existing naming conventions).
 - Important restrictions: agents MUST NOT run repository setup or system-level install commands in this environment (see "Setup" section). The `docs/` directory is generated and should be treated as read-only — do not modify files under `docs/`.

---

## Setup (commands an agent can run)

- Install Hugo (if not available): follow the platform-specific installer or use Homebrew on macOS:

WARNING — agents must NOT execute setup/install commands:

- Do NOT run setup or system-level install commands (for example `brew install`, package manager installs, or other environment provisioning) from an automated agent unless explicitly authorized by a human maintainer. These commands are marked in this file as examples for humans to run locally.

If you are an agent and need dependencies installed, add a comment or open an issue requesting the human operator run the installation.

Example human-only install (run locally):

```zsh
brew install hugo
```

- Start local preview (serves drafts):

```zsh
hugo server -D
```

- Build the site (production/minified):

```zsh
hugo --minify
```

- Helper scripts:
  - `build.pl` — legacy/perl build helpers (use with caution).

---

## Development workflow for agents

- Writing content:
  - Place posts in `content/post/`.
  - Use YAML front matter delimited with `---` (do not use TOML `+++`). Keep `draft: true` until ready to publish.
<<<<<<< HEAD
  - Filename convention: prefer using an epoch-second filename under `content/post/` (for example `1764720000.md`) to match the repository's existing posts and ensure predictable ordering. Alternatively the `YYYY/MM/DD/slug.md` structure is acceptable when appropriate.
=======
  - Filename convention: prefer using an epoch-second filename under `content/post/` (for example `1764720000.md`) to match the repository's existing posts and ensure predictable ordering.
>>>>>>> 62a401931 (update 作成される記事の調整(main))
  - Tags: use English, lowercase only (multi-word tags may use hyphens, e.g. `object-oriented`).
  - Headings: use ATX-style headings. H1 is the page title (from front matter); use `##` (H2) for top-level sections and `###`/`####`/`#####`/`######` for subsections.
  - For simple external reference links, prefer the site's `linkcard` shortcode: `{{< linkcard "https://example.com" >}}`.
  - Common front matter keys: `title`, `draft`, `tags`, `description`.
  - Do not include keys: `date`, `iso8601`.

- Previewing and editing:
  - Run `hugo server -D` and open `http://localhost:1313` to check rendering and shortcodes.
  - Verify images and shortcodes in `layouts/shortcodes/` behave as expected.

- Building and verifying:
  - Run `hugo --minify` and inspect output in `public/` or `docs/` depending on workflow.
  - Optionally run `build.pl` only after reviewing their code and arguments.

---

## Testing instructions

- This repository does not include an automated unit test suite for site content. Agents should:
  - Validate generated HTML by running `hugo --minify` and spot-check pages.
  - Check links with a link checker (example):

```zsh
# install a link checker then run it against the local server
# e.g. npm: 'npx broken-link-checker' or 'linkinator'
linkinator http://localhost:1313
```

- For CI: inspect `.github/workflows` for site build steps and replicate the same commands when validating locally.

---

## Code style & content conventions

- Markdown: use CommonMark-friendly Markdown; prefer fenced code blocks with language tags.
- Front matter: follow existing site conventions (TOML). Do not overwrite existing front matter without explicit permission.
 - Front matter: use YAML front matter (delimited with `---`). Do not overwrite existing front matter without explicit permission.
- Images: include meaningful `alt` text and small captions where appropriate. Use Hugo image processing via `resources` when resizing/optimizing.
- Shortcodes: prefer site-provided shortcodes in `layouts/shortcodes/` rather than ad-hoc HTML.

---

## Build and deployment

- Build command: `hugo --minify`.
- Output: by default `public/` (or site configured output). The repo contains `docs/` which may be the published output used for GitHub Pages.
- Deployment: follow repository's CI or GitHub Pages flow. Check `.github/workflows` for the exact pipeline and replicate its steps for local validation.

Note about `docs/` (read-only):

- The `docs/` directory is generated output (site build) and is treated as write-protected in normal workflows. Do not edit files under `docs/` from an agent — changes should be made in source content under `content/`, `layouts/`, `static/`, etc., then the site rebuilt by CI or a human-run build.

---

## Pull request & contribution guidelines

- Branch naming: use descriptive branch names, e.g. `feature/write-hugo-article`, `fix/images-optimization`.
- PR title format: `[post] Short description` or `[site] Short description` for infra changes.
- Required checks before PR:
  - Run `hugo server -D` to visually validate changes.
  - Run `hugo --minify` to ensure a successful build.
  - Ensure `draft` is `true` for drafts; set to `false` only when ready to publish.

---

## Security & secrets

- This repo does not store secrets in code. If secrets are needed for CI or deployment, use GitHub Secrets or an external secret manager.
- Avoid embedding credentials into front matter or content files.

---

## Troubleshooting & common gotchas

- If `hugo server` fails:
  - Ensure Hugo version matches site's required version (see `config/_default/config.toml` or module docs).
  - Look for errors from shortcodes or partials — missing params often cause build errors.

- If images are missing or broken:
  - Verify files under `assets/` and `static/images/` and the `featuredImage` paths in front matter.

- If content doesn't appear:
  - Ensure `draft` is `false` (or run `hugo server -D` to include drafts).

---

## Templates & prompts for agents (copyable)

- Draft generation (English/Japanese):

```
You are a skilled technical writer. From the brief: {brief}
Target reader: {audience}
Tone: {tone}
Output: Hugo-compatible Markdown using YAML front matter (delimited with `---`), include `draft: true` and a short `description` (<=120 chars). Do not include a `date` field. Use ATX headings (H2 for top-level sections). Use `linkcard` shortcode for simple external links.
```

- SEO checklist (automated): ensure `title`, `description` (<= 120 chars), `slug`, and `tags` exist in front matter.

---

## Where to add more agent docs

- For subproject-specific behavior (e.g., tooling in `tools/`), add `AGENTS.md` under that directory. The closest `AGENTS.md` to a file path takes precedence for agents operating in that folder.

---

## Custom agents (`.github/agents`)

This repository contains repository-specific agent definitions under `.github/agents/`. These are human-authored agent role/prompts intended to be referenced by humans or tooling that knows how to load them. Agents should read these files for custom behavior and not overwrite them.

Available agent files (informational):

- `.github/agents/task-planner.agent.md`
- `.github/agents/search-ai-optimization-expert.agent.md`
- `.github/agents/postgresql-dba.agent.md`
- `.github/agents/plan.agent.md`
- `.github/agents/implementation-plan.agent.md`
- `.github/agents/adr-generator.agent.md`
- `.github/agents/accessibility.agent.md`
- `.github/agents/specification.agent.md`
- `.github/agents/software-engineer-agent-v1.agent.md`
- `.github/agents/simple-app-idea-generator.agent.md`
- `.github/agents/prompt-engineer.agent.md`
- `.github/agents/hlbpa.agent.md`
- `.github/agents/lingodotdev-i18n.agent.md`
- `.github/agents/planner.agent.md`
- `.github/agents/microsoft_learn_contributor.agent.md`
- `.github/agents/playwright-tester.agent.md`
- `.github/agents/prompt-builder.agent.md`
- `.github/agents/technical-content-evaluator.agent.md`
- `.github/agents/meta-agentic-project-scaffold.agent.md`
- `.github/agents/task-researcher.agent.md`
- `.github/agents/monday-bug-fixer.agent.md`
- `.github/agents/mentor.agent.md`

If you want me to summarize or extract the instructions from any of these files, tell me which one(s) and I'll open them and add a short summary to this `AGENTS.md` or a separate helper file.

## Module / Package Announcement Posts (モジュール紹介記事)

When writing posts that introduce a library, module, or package (for example a CPAN/MetaCPAN module such as `JSON::RPC::Spec`), follow these additional guidelines to make the post useful for readers and reproducible:

- **Front matter:** include `title`, `draft: true`, `description` (<= 120 chars), and `tags` such as `perl`, `cpan`, and `module`.
- **Canonical links:** include the authoritative package page (MetaCPAN/CPAN) and the source repo. Use the `linkcard` shortcode for these references: `{{< linkcard "https://metacpan.org/pod/Your::Module" >}}`.
- **Install instructions:** show common install commands (`cpanm JSON::RPC::Spec`) and mention any non-obvious dependencies or platform notes.
- **Minimal example(s):** include a short, copy-pasteable example demonstrating the most common usage (synopsis). Prefer small, self-contained code snippets with language tag (e.g., ````perl```).
- **API caveats and compatibility:** briefly note supported versions (Perl version, any notable incompatibilities), debugging flags, and recommended runtime settings.
- **Testing & links:** point readers to test instructions, the module's test suite (if available), and CI status or badges when appropriate.
- **License & author:** show where to find license and author/contact info (link to MetaCPAN or repository).

Template (copyable):

```
---
title: "<ModuleName> — short summary"
draft: true
description: "<=120 chars: short summary of the module"
tags:
  - perl
  - cpan
  - module
---

## 概要

{{< linkcard "https://metacpan.org/pod/Your::Module" >}}

## インストール

```sh
cpanm Your::Module
```

## 使い方（最小例）

```perl
use Your::Module;
# ... example ...
```

## 参考・リンク

- ソースリポジトリ
- ドキュメント

```

Follow-up: when a module post is added, keep it `draft: true` until you (or the author) confirm accuracy of API examples and links.

## Appendix: original site-specific guidance

The previous `AGENTS.md` focused on blog-article generation and included Japanese templates and editorial workflows. That content has been preserved where relevant — if you need the original Japanese templates or a dedicated article authoring guide, ask and I will append them as a separate section.
