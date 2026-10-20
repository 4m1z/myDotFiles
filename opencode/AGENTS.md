# Global engineering rules

Applies to every project. Keep it short: a rule that is not actionable is noise.

## Working style

- **Read before you write.** Match the codebase's existing patterns, naming, and
  structure. Do not introduce a framework, abstraction, or dependency the task
  does not need.
- **Smallest complete change.** Include the callers, tests, fixtures, and
  config a change breaks. Do not leave "for later" scaffolding.
- **Follow the project's design.** When Figma designs are linked or connected,
  inspect the relevant frames, components, tokens, and assets before UI work.
  Use them and the project's existing design system as the source of truth;
  design skills help implement it, not replace it. If access or a required
  state is missing, ask for the design/access instead of inventing a redesign.
- **Ask first** for destructive, privileged, production-affecting, or
  security-sensitive actions, and for anything that spends money or touches
  production data.
- **Never commit secrets.** Credentials live in the environment or a local
  `.env` that is git-ignored; reference them, never inline them.
- **Do not run untrusted remote scripts** (`curl | bash`) without reading them
  first.

## Verification discipline

- Evidence before assertions: run the test, show the output, then claim it
  passes. "Should work" is not a result.
- Verify in the real thing: a UI change is verified in a browser
  (`playwright-cli`), a CLI change is verified by running it.
- When a check cannot be run, say so explicitly instead of implying success.
- Never claim a task is complete while a known failure remains.

## Delivery workflow

Pick the skills that match the phase; do not load everything.

| Phase | Skills |
|---|---|
| Requirement / design | `brainstorming`, `product-marketing` |
| Plan | `writing-plans`, `product-feature-delivery` |
| UI/UX | `ui-ux-pro-max`, `web-design-guidelines` |
| Implementation | `test-driven-development`, `vercel-react-best-practices`, `vercel-composition-patterns`, `supabase-postgres-best-practices` |
| Debugging | `systematic-debugging`, `diagnose-crash` |
| Code review | `requesting-code-review`, `differential-review` |
| Browser verification | `playwright-cli` |
| Security / supply chain | `differential-review`, `semgrep`, `supply-chain-risk-auditor` |
| Pre-release | `production-readiness`, `api-design-review` |
| Growth / measurement | `analytics`, `ab-testing`, `onboarding`, `pricing`, `seo-audit` |
| Property tests | `property-based-testing` |

## Environment

- This machine is Arch-based: `pacman` for packages, `mise` for runtimes
  (node, bun, go, python), `uv` for python tooling.
- The OpenCode config, plugins, themes, and vendored skills are **managed by a
  dotfiles repository**. Edit their repository sources through the existing
  symlinks. Ecosystem and design skills are installed copies, updated by their
  CLIs; do not assume all of `~/.agents/skills/` is linked into the repository.
- The dotfiles repo keeps two installers (`cachyos/install.sh`,
  `opencode/install.sh`); both are idempotent and must stay that way.
- System paths owned by packages (e.g. `/usr/share/<package>`) are read-only:
  read them, never edit them.

## Skill hygiene

- Skills live in `~/.agents/skills/` (portable, all harnesses) or in a
  project's `.agents/skills/` (stack-specific). Do not copy a skill into both.
- Install and update ecosystem skills with the `skills` CLI
  (`npx skills add <owner/repo> -g -a opencode -s <skill>`), never by hand.
- If a skill does not fit the task, skip it — a skill that fires wrongly costs
  more than a missing one.
