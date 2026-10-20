# Agent skills

`manifest.txt` lists the skills that must exist in `~/.agents/skills/` after a
bootstrap. `opencode/skills.sh` installs them and `--verify` reports what is
missing (the CachyOS test suite runs that check).

Two sources:

- `skills/<name>/` in this repo — vendored skills, symlinked into
  `~/.agents/skills/` (only when nothing is there yet, so a distro-provided
  skill is never clobbered).
- the [UI/UX Pro Max](https://github.com/nextlevelbuilder/ui-ux-pro-max-skill)
  CLI, which installs `ui-ux-pro-max` plus its bundled design skills
  (`banner-design`, `brand`, `design`, `design-system`, `slides`,
  `ui-styling`) into the agent-standard `~/.agents/skills/` directory.

`diagnose-crash/` is vendored from the omarchy package (MIT, omarchy 4.0.4):
the crash-diagnosis workflow is distro-agnostic, but the package that ships it
is not installed everywhere.

Superpowers ([obra/superpowers](https://github.com/obra/superpowers)) is **not**
listed here: for OpenCode it is a plugin, not a `~/.agents/skills` bundle. It
is declared in the `plugins` array of `opencode/opencode.json` and installed by
`opencode/install.sh`; the plugin registers the skills itself.
