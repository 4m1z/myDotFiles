#!/usr/bin/env python3
"""Offline installer regressions. Stub package downloads, not filesystem changes."""
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest


REPO = Path(os.environ.get("DOTFILES_TEST_REPO", Path(__file__).resolve().parents[2]))
ROWS = "alpha example/skills\nbeta example/skills\nui-ux-pro-max ui-ux-pro-max\nbrand ui-ux-pro-max\nlocal vendored\n"
PACKAGE_TOOL = r'''#!/usr/bin/python3
import os, pathlib, sys
args = sys.argv[1:]
home = pathlib.Path.home()
def skill(root, name):
    target = root / name
    target.mkdir(parents=True, exist_ok=True)
    (target / 'SKILL.md').write_text('---\nname: ' + name + '\ndescription: fixture\n---\nUpstream\n')
if pathlib.Path(sys.argv[0]).name == 'npm':
    assert args[:2] == ['install', '--global'], args
    assert '@playwright/cli@latest' in args, args
    prefix = pathlib.Path(args[args.index('--prefix') + 1])
    cli = prefix / 'bin/playwright-cli'
    cli.parent.mkdir(parents=True, exist_ok=True)
    cli.write_text("#!/usr/bin/env node\nconsole.log('  snapshot  capture page\\n  goto <url>  navigate');\n")
    cli.chmod(0o755)
elif 'skills@latest' in args:
    assert pathlib.Path.cwd() == home, 'project runtime leaked into installation'
    names = args[args.index('-s') + 1:]
    for name in names:
        if name.startswith('-'): break
        skill(home / '.agents/skills', name)
elif 'ui-ux-pro-max-cli' in args:
    root = home / '.agents/skills'
    # Upstream skips the whole bundle when the main skill exists without --force.
    if not (root / 'ui-ux-pro-max/SKILL.md').exists() or '--force' in args:
        for name in ['ui-ux-pro-max', 'brand']: skill(root, name)
else:
    raise SystemExit('unexpected package invocation: ' + repr(args))
'''


class SetupTests(unittest.TestCase):
    @staticmethod
    def _find_node():
        """Locate a node runtime.

        The repo manages Node through mise (mise/config.toml), which does not
        put it on the global PATH, so a plain shutil.which() is not enough.
        """
        node = shutil.which("node")
        if node:
            return node
        mise = shutil.which("mise") or os.path.expanduser("~/.local/bin/mise")
        if os.path.exists(mise):
            for args in (["which", "node"], ["exec", "--", "which", "node"]):
                try:
                    out = subprocess.run([mise, *args], cwd=str(Path.home()),
                                         capture_output=True, text=True, timeout=120)
                except (OSError, subprocess.SubprocessError):
                    continue
                candidate = out.stdout.strip().splitlines()
                if candidate and os.path.exists(candidate[0]):
                    return candidate[0]
        return None

    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(prefix="setup-test-", dir=os.environ.get("TMPDIR"))
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        self.repo = self.root / "repo"
        shutil.copytree(REPO / "opencode", self.repo / "opencode", ignore=shutil.ignore_patterns("node_modules", "tests"))
        (self.repo / "skills/local").mkdir(parents=True)
        (self.repo / "skills/local/SKILL.md").write_text("---\nname: local\ndescription: fixture\n---\nLocal\n")
        (self.repo / "skills/manifest.txt").write_text(ROWS)
        self.home = self.root / "home"
        self.home.mkdir()
        self.bin = self.root / "bin"
        self.bin.mkdir()
        self.runtime = self.root / "runtime"
        self.runtime.mkdir()
        for name in ("bash", "sed", "awk", "sort", "tr", "dirname", "basename", "mkdir", "ln", "mv", "cp", "mktemp", "rm", "date", "readlink", "env", "grep", "cat", "sleep"):
            (self.bin / name).symlink_to(shutil.which(name))
        for name in ("npx", "npm"):
            tool = self.runtime / name
            tool.write_text(PACKAGE_TOOL)
            tool.chmod(0o755)
        node = self._find_node()
        if node is None:
            self.fail("no node runtime found: install Node (e.g. `mise install`) "
                      "or put it on PATH; the browser-CLI fixture needs it")
        (self.runtime / "node").symlink_to(node)
        self.env = {**os.environ, "HOME": str(self.home), "PATH": f"{self.runtime}:{self.bin}",
                    "XDG_CONFIG_HOME": str(self.home / ".config"), "XDG_DATA_HOME": str(self.home / ".local/share"),
                    "XDG_STATE_HOME": str(self.home / ".local/state"), "TMPDIR": str(self.root),
                    "PLUGIN_WAIT_SECONDS": "1", "PLUGIN_POLL_INTERVAL": "0.1"}

    def run_skills(self, *args):
        return subprocess.run(["/bin/bash", str(self.repo / "opencode/skills.sh"), *args],
                              cwd=self.repo, env=self.env, text=True, capture_output=True)

    def seed(self):
        for row in ROWS.splitlines():
            target = self.home / ".agents/skills" / row.split()[0]
            target.mkdir(parents=True, exist_ok=True)
            (target / "SKILL.md").write_text("---\nname: custom\ndescription: personal\n---\nKeep me\n")

    def test_empty_or_broken_skills_fail_verification(self):
        self.seed()
        for kind in ("empty-directory", "empty-file", "broken-link"):
            with self.subTest(kind=kind):
                target = self.home / ".agents/skills/alpha/SKILL.md"
                if target.exists() or target.is_symlink(): target.unlink()
                if kind == "empty-file": target.touch()
                if kind == "broken-link": target.symlink_to(self.root / "absent")
                result = self.run_skills("--verify")
                self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)
                self.assertIn("alpha", result.stderr)

    def test_mise_only_installs_ecosystem_skills_from_home(self):
        mise = self.bin / "mise"
        mise.write_text(f'#!/bin/bash\n[[ "$PWD" == "$HOME" ]] || exit 91\n[[ "$1 $2" == "exec --" ]] || exit 92\nshift 2\nexport PATH="{self.runtime}:$PATH"\nexec "$@"\n')
        mise.chmod(0o755)
        self.env["PATH"] = str(self.bin)
        result = self.run_skills()
        self.assertTrue((self.home / ".agents/skills/alpha/SKILL.md").is_file(), result.stdout + result.stderr)

    def test_install_preserves_custom_skills_while_repairing_missing_members(self):
        self.seed()
        skills = self.home / ".agents/skills"
        (skills / "beta/SKILL.md").unlink()
        (skills / "brand/SKILL.md").unlink()
        (skills / "brand/notes.txt").write_text("personal notes")
        for _ in range(2):
            result = self.run_skills()
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            for name in ("alpha", "ui-ux-pro-max"):
                self.assertIn("Keep me", (skills / name / "SKILL.md").read_text())
            for name in ("beta", "brand"):
                self.assertTrue((skills / name / "SKILL.md").is_file())
        notes = list((self.home / ".local/state").rglob("notes.txt"))
        self.assertTrue(notes, "invalid skill content must be backed up before repair")
        self.assertEqual(notes[0].read_text(), "personal notes")

    def test_official_browser_cli_replaces_old_command_with_backup(self):
        old = self.home / ".local/bin/playwright-cli"
        old.parent.mkdir(parents=True)
        old.write_text("#!/bin/bash\necho old-command\n")
        old.chmod(0o755)
        result = self.run_skills()
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        help_result = subprocess.run([str(old), "--help"], env=self.env, text=True, capture_output=True)
        self.assertEqual(help_result.returncode, 0, help_result.stderr)
        self.assertIn("snapshot", help_result.stdout)
        backups = list(old.parent.glob("playwright-cli.bak.*"))
        self.assertEqual(len(backups), 1)
        self.assertIn("old-command", backups[0].read_text())

    def test_plugin_verification_waits_for_runtime_registration(self):
        # A fresh service registers plugins asynchronously; the first list call
        # legitimately returns nothing while packages install.
        calls = self.root / "plugin-calls"
        binary = self.home / ".opencode/bin/opencode"
        binary.parent.mkdir(parents=True)
        binary.write_text(f'''#!/bin/bash
[[ "$*" == 'plugin list' ]] || exit 90
n=$(cat {calls} 2>/dev/null || echo 0); n=$((n+1)); echo "$n" > {calls}
if (( n < 3 )); then exit 0; fi
printf '%s\\n' 'ID VERSION SOURCE' 'graph-live 1 package' 'tmux-status 1 package' 'ponytail 1 package' 'superpowers 1 package'
''')
        binary.chmod(0o755)
        env = {**self.env, "PLUGIN_WAIT_SECONDS": "10", "PLUGIN_POLL_INTERVAL": "0.1"}
        result = subprocess.run(["/bin/bash", str(self.repo / "opencode/verify-plugins.sh")],
                                cwd=self.repo, env=env, text=True, capture_output=True)
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual(calls.read_text().strip(), "3")

    def test_plugin_verification_fails_when_registration_never_completes(self):
        binary = self.home / ".opencode/bin/opencode"
        binary.parent.mkdir(parents=True)
        binary.write_text('#!/bin/bash\n[[ "$*" == \'plugin list\' ]] || exit 90\n')
        binary.chmod(0o755)
        env = {**self.env, "PLUGIN_WAIT_SECONDS": "1", "PLUGIN_POLL_INTERVAL": "0.1"}
        result = subprocess.run(["/bin/bash", str(self.repo / "opencode/verify-plugins.sh")],
                                cwd=self.repo, env=env, text=True, capture_output=True)
        self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertIn("superpowers", result.stderr)

    def test_installer_requires_all_runtime_plugin_ids(self):
        binary = self.home / ".opencode/bin/opencode"
        binary.parent.mkdir(parents=True)
        binary.write_text('''#!/bin/bash
case "$*" in
  --version) echo 'opencode v2.0.7' ;;
  'service restart') exit 0 ;;
  'plugin list') printf '%s\\n' "$PLUGIN_OUTPUT" ;;
  *) exit 90 ;;
esac
''')
        binary.chmod(0o755)
        expected = ["graph-live", "tmux-status", "ponytail", "superpowers"]
        cases = [("all-loaded", expected, True), ("empty", [], False)]
        cases += [(f"missing-{name}", [p for p in expected if p != name], False) for name in expected]
        for label, plugins, success in cases:
            with self.subTest(label=label):
                self.env["PLUGIN_OUTPUT"] = "ID VERSION SOURCE\n" + "\n".join(f"{p} 1.0.0 package" for p in plugins)
                result = subprocess.run(["/bin/bash", str(self.repo / "opencode/install.sh")],
                                        cwd=self.repo, env=self.env, text=True, capture_output=True)
                self.assertEqual(result.returncode == 0, success, result.stdout + result.stderr)


if __name__ == "__main__":
    unittest.main()
