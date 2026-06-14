---
name: blog-knowledge-summarizer
description: Use this project-local skill when the user asks Copilot to write, outline, expand, polish, or summarize a blog post from learning notes, demo projects, source code, experiments, screenshots, transcripts, or rough Chinese/English thoughts. Prefer a blog-length technical summary that extracts what was learned, explains why it matters, and connects the content to this repository's demos or blog workflow.
---

# Blog Knowledge Summarizer

## Purpose

Turn rough learning material into a publishable technical blog draft. The default output should help the user explain what they learned, what problem the demo or code solves, and what readers can reproduce.

Prefer a complete long-form blog draft over a short summary unless the user asks for brief notes.

## Input Sources

Use any relevant local context the user points to:

- source code, README files, docs, commit diffs, tests, scripts, and demo projects
- pasted notes, fragmented speech-to-text Chinese, meeting notes, screenshots, or transcripts
- terminal output, error logs, experiment results, and implementation decisions

If the user gives vague spoken Chinese, infer the likely intent conservatively and proceed. Ask only when the topic, audience, or source material cannot be identified from context.

## Repository Blog Layout

When creating or updating blog content in this repository, match the existing Jekyll structure used by `blog/_articles/simulator-log-capture.md`:

```text
blog/
  _articles/
    <slug>.md
  <slug>/
    assets/
      <asset-files>
```

Rules:

- Put the article body in `blog/_articles/<slug>.md`.
- Use a short lowercase kebab-case `<slug>` that matches the related demo directory when one exists, for example `simulator-log-capture`.
- Put article-specific images, screenshots, logs intended for display, and other web assets under `blog/<slug>/assets/`.
- Reference assets with Jekyll `relative_url`, for example `![Alt text]({{ '/<slug>/assets/image.png' | relative_url }})`.
- Keep raw demo outputs in the demo's own `result/`, `docs/`, or `samples/` directory when they are source evidence rather than web page assets. Link to them through `result_url` when useful.
- Do not add `layout` frontmatter for articles unless the site config changes. `blog/_config.yml` already assigns `layout: article` to the `articles` collection.

Use this frontmatter shape unless the article has a strong reason to differ:

```yaml
---
title: <Chinese article title>
description: <one-sentence page lead>
summary: <one-sentence index summary>
category: Investigation
tag: <topic tag>
date: YYYY-MM-DD
demo_url: <optional GitHub demo URL>
result_url: <optional raw result URL>
---
```

Use `category: Investigation` for experiment or research writeups. Pick a concise `tag`, such as `iOS Logs`, `SwiftData`, `XcodeBuildMCP`, or `Agentic Coding`.

## Default Blog Shape

Use this structure unless the user requests another format:

1. Title: concrete and searchable, not clever.
2. Opening: state the learning goal, problem, or confusion that motivated the work.
3. Background: explain the minimum concepts needed to follow the post.
4. Main walkthrough: organize by cause and effect, not by raw chronology.
5. Code or demo notes: cite important files, APIs, settings, or commands when available.
6. Key takeaways: distill what changed in the user's understanding.
7. Pitfalls and verification: include errors, tradeoffs, tests, builds, or reproducible checks.
8. Next steps: mention concrete follow-up experiments only when useful.

## Writing Rules

- Write primarily in Chinese when the user asks in Chinese or provides Chinese notes. Keep technical identifiers, API names, commands, and file paths in their original form.
- Preserve uncertainty. Do not invent facts, benchmark numbers, API behavior, or file names. Mark uncertain points as "待确认" or ask a focused question if the uncertainty blocks the draft.
- Explain concepts through the actual demo or code path when available. Avoid generic textbook summaries.
- Prefer precise engineering language: what changed, why it changed, how it was verified, and what failed before the fix.
- Keep paragraphs readable. Use headings, short paragraphs, and focused bullets where they improve scanning.
- When the source is a codebase, inspect relevant files before writing and include clickable file references in the final answer when possible.

## Long Blog Draft Workflow

1. Identify the blog topic, intended reader, and source material.
2. Read the smallest useful set of files or notes needed to ground the draft.
3. If writing into the repository, choose `<slug>` and create or update `blog/_articles/<slug>.md` plus `blog/<slug>/assets/` as needed.
4. Extract the learning path: initial question, experiments, implementation details, mistakes, final understanding.
5. Draft a coherent article with frontmatter, a title, and section headings.
6. Add a short "可继续补充" section only if important evidence or screenshots are missing.

## Output Modes

Choose the mode from the user's request:

- **Long blog draft**: default. Full article with publishable structure.
- **Outline first**: use when the user asks for a plan, framework, or table of contents.
- **Polish existing draft**: preserve the user's core argument and improve structure, clarity, and flow.
- **Skill or prompt summary**: when the user asks to summarize a reusable writing skill, produce concise instructions that can become or update a Copilot skill.

## Quality Bar

A good result should answer:

- What did I learn?
- What problem or misconception did this resolve?
- Which code, demo, command, or observation supports the conclusion?
- What should a reader try next to reproduce or deepen the lesson?
