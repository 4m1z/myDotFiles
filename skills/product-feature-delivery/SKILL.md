---
name: product-feature-delivery
description: >
  Deliver a product feature end to end: turn a requirement into a plan with
  acceptance criteria, build it as a vertical slice (UI + API + data + tests),
  define the analytics events that measure it, and verify it before it is
  called done. Use when starting a new feature or fixing a user-facing gap:
  "build X", "add feature X", "implement the requirement", "ship X", "this
  feature needs analytics". Not for pure refactors, docs-only work, or
  infrastructure changes with no user-facing behaviour.
---

# Product Feature Delivery

Ship the smallest complete slice of the feature that a user can actually use,
with the instrumentation and the tests that prove it works.

## 1. Frame the requirement

Before touching code, write down (in the repo, not only in chat):

- **Problem** — who has it, what they do today, why it hurts. Not the solution.
- **Success signal** — the metric or event that tells us this worked.
- **Acceptance criteria** — observable, testable statements. "User sees the
  last 20 notes, newest first, and the empty state links to the PWA" — not
  "the notes list works".
- **Non-goals** — what this explicitly does *not* include.

If the requirement is ambiguous, use the `brainstorming` skill before
designing. If it is already a written spec, skip straight to step 2.

## 2. Plan

Use `writing-plans` (or `executing-plans` if a plan already exists). The plan
lists, per task: the file paths to touch, the behaviour to add, and how to
verify it. Keep tasks 2–5 minutes of work; each one must leave the tree green.

State the stack before planning: framework, data store, auth model, test
runner, deploy target. If the repo is unfamiliar, read the existing patterns
first — match the codebase's conventions over your own preferences.

## 3. Design the UI (only if there is a UI)

Use `ui-ux-pro-max` for visual decisions (layout, type scale, colour, spacing,
accessibility) and `web-design-guidelines` / `vercel-react-best-practices` for
implementation quality. Reuse the project's existing components and tokens
before adding new ones.

## 4. Build a vertical slice

One slice = one user-visible path, end to end:

- data (schema/migration, then query)
- server (validation, authorization, the handler)
- client (state, loading, error, empty states)
- test at the seam (unit for logic, integration for the handler)

Do not build "the API first, the UI later": a slice that cannot be exercised
by a user is not a slice. Migrations ship with the code that uses them, in the
same change.

## 5. Instrumentation

Define the events with the feature, not afterwards. For each event record:

| Field | Meaning |
|---|---|
| name | `snake_case`, past tense (`note_created`) |
| trigger | the exact user action that fires it |
| properties | the minimum needed to segment (ids, source, variant) — no PII |
| owner | which dashboard/funnel consumes it |

Reuse the project's existing event names and naming convention. If the project
has no analytics, say so explicitly and state the manual check that stands in
for it.

## 6. Verify before claiming done

Run, in this order:

1. the tests you added (and the full suite if it is fast)
2. the app: the new path in the real UI — `playwright-cli` for browser
   verification (navigate, interact, screenshot, assert)
3. `verification-before-completion` for the final evidence check

Then report: what changed, which acceptance criteria are met (with the command
output or screenshot as evidence), what is still open.

## Boundaries

- Not a substitute for `systematic-debugging` when something is broken.
- Not a substitute for `production-readiness` before a release; that is a
  separate pass over the whole service.
- Do not add analytics, flags, or abstractions the requirement does not need.
- If the requirement needs a schema change, plan the migration and the
  backfill explicitly.
