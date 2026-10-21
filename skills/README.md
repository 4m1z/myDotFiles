# Agent skills

`manifest.txt` is the single source of truth: one `<skill-name> <source>` per
line. `opencode/skills.sh` installs missing skills. `--verify` requires a
readable, nonempty `SKILL.md` for every entry and the working Playwright CLI
command interface (the CachyOS test suite runs that check).

Three sources:

- `<owner/repo>` — installed by the [`skills` CLI](https://skills.sh) (the open
  agent skills ecosystem). It copies the skill into `~/.agents/skills/`, the
  agent-standard directory every harness reads. Refresh with
  `npx skills update -g`.
- `ui-ux-pro-max` — installed by the
  [UI/UX Pro Max](https://github.com/nextlevelbuilder/ui-ux-pro-max-skill) CLI
  (`ui-ux-pro-max` plus its bundled design skills). The bundle is generated in
  a temporary HOME; only missing/invalid skills are copied into place. Normal
  bootstrap never force-refreshes existing design skills.
- `vendored` — a directory in this repo, symlinked into `~/.agents/skills/`
  (existing usable skills, including distro-provided ones, are preserved).

Invalid skill entries are moved to timestamped directories under
`${XDG_STATE_HOME:-~/.local/state}/mydotfiles/skills-backups/` before repair.
Back up customized skills before explicitly refreshing them with an upstream
CLI; ecosystem updates are separate from bootstrap.

The installer also provisions the official `@playwright/cli` in
`${XDG_DATA_HOME:-~/.local/share}/mydotfiles/playwright-cli/`. Its repo-managed
launcher is linked as `~/.local/bin/playwright-cli` (an existing command is
backed up alongside it). Node tooling falls back to the global mise runtime
when it is not on PATH. Browser binaries are managed by Playwright; use
`playwright-cli install-browser` if no supported browser is installed.

`opencode/verify-plugins.sh` checks that graph-live, tmux-status, ponytail, and
Superpowers actually appear in the runtime plugin list. Installers fail if
skill/tool verification or runtime plugin verification fails.

Vendored here:

- `diagnose-crash/` — adapted from the omarchy package (MIT, omarchy 4.0.4): the
  crash-diagnosis workflow is distro-agnostic, the package is not. The
  upstream-filing appendix (Omarchy-specific) was dropped; everything else is
  verbatim.
- `api-design-review/`, `product-feature-delivery/`, `production-readiness/` —
  the product-engineering skills, written for this setup because no upstream
  skill covers them.

Superpowers ([obra/superpowers](https://github.com/obra/superpowers)) is **not**
listed here: for OpenCode it is a plugin, not a `~/.agents/skills` bundle. It
is declared in the `plugins` array of `opencode/opencode.json` and installed by
`opencode/install.sh`; the plugin registers the skills itself.
