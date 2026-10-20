# Agent skills

`manifest.txt` is the single source of truth: one `<skill-name> <source>` per
line. `opencode/skills.sh` installs them and `--verify` reports what is
missing (the CachyOS test suite runs that check).

Three sources:

- `<owner/repo>` — installed by the [`skills` CLI](https://skills.sh) (the open
  agent skills ecosystem). It copies the skill into `~/.agents/skills/`, the
  agent-standard directory every harness reads. Refresh with
  `npx skills update -g`.
- `ui-ux-pro-max` — installed by the
  [UI/UX Pro Max](https://github.com/nextlevelbuilder/ui-ux-pro-max-skill) CLI
  (`ui-ux-pro-max` plus its bundled design skills).
- `vendored` — a directory in this repo, symlinked into `~/.agents/skills/`
  (only when nothing is installed there yet, so a distro-provided skill is
  never clobbered).

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
