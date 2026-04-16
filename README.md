# agent-skills

Single source of truth for **agent skills** used across projects. Each skill is a directory with `SKILL.md` (YAML frontmatter + Markdown), plus any supporting files.

**Install into another project without cloning:** scripts download a GitHub archive to a temp directory, run the normal installer, then delete the temp files (unless you opt in to keep them).

Replace **`OWNER`** everywhere below with your GitHub user or organization (the segment in `https://github.com/OWNER/agent-skills`).

| Path | Purpose |
|------|---------|
| `skills/<skill-name>/` | Canonical skills copied into targets |
| `tools/install-from-github.ps1` | **No clone (Windows):** download repo from GitHub, then install |
| `tools/install-from-github.sh` | **No clone (Unix):** same, for Bash |
| `tools/install-agent-skills.ps1` | Local installer (used after clone or by the GitHub bootstrap) |
| `tools/install-agent-skills.sh` | Local installer (Bash) |
| `tools/validate-skills.ps1` | Validates `skills/*/SKILL.md` frontmatter |
| `bin/agent-skills.cmd` | PATH shim → local PowerShell installer (needs a checkout) |
| `bin/agent-skills` | PATH shim → local Bash installer (needs a checkout) |

## Where files land in another project

| Tool | Project-local path |
|------|---------------------|
| Cursor | `<project>/.cursor/skills/<skill-name>/` |
| Claude Code | `<project>/.claude/skills/<skill-name>/` |

Claude Code also supports `~/.claude/skills/`. These installers default to the **project** root so you can commit the result. If you use `CLAUDE_CONFIG_DIR`, resolve paths relative to that layout.

---

## Install without cloning (recommended)

These commands pull **`main`** from `https://github.com/OWNER/agent-skills` and copy skills into the **current directory** (your other repo). They do **not** leave a permanent clone on disk (unless you pass keep flags).

### PowerShell (from the target project root)

Download the bootstrap script once, then run it (works on locked-down machines where `iex irm` is discouraged):

```powershell
$i = "$env:TEMP\agent-skills-install-from-github.ps1"
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/OWNER/agent-skills/main/tools/install-from-github.ps1" -OutFile $i -UseBasicParsing
powershell -NoProfile -ExecutionPolicy Bypass -File $i -Repository "OWNER/agent-skills" -TargetProject . -Flavor Both
```

Dry run (target folder must already exist):

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File $i -Repository "OWNER/agent-skills" -TargetProject . -Flavor Both -DryRun
```

Optional: set **`AGENT_SKILLS_GITHUB_REPO`** to `OWNER/agent-skills` so you can omit `-Repository`:

```powershell
$env:AGENT_SKILLS_GITHUB_REPO = "OWNER/agent-skills"
powershell -NoProfile -ExecutionPolicy Bypass -File $i -TargetProject . -Flavor Both
```

Other switches: **`-Ref`** branch name (default `main`), **`-KeepDownload`** leaves the temp extract under `%TEMP%` for debugging.

### Bash (from the target project root)

```bash
curl -fsSL "https://raw.githubusercontent.com/OWNER/agent-skills/main/tools/install-from-github.sh" | bash -s -- --repo "OWNER/agent-skills" --target . --flavor both
```

Or set **`AGENT_SKILLS_GITHUB_REPO`** and omit **`--repo`**:

```bash
export AGENT_SKILLS_GITHUB_REPO="OWNER/agent-skills"
curl -fsSL "https://raw.githubusercontent.com/OWNER/agent-skills/main/tools/install-from-github.sh" | bash -s -- --target . --flavor both
```

Options: **`--ref`**, **`--dry-run`**, **`--keep-download`**.

**Note:** `raw.githubusercontent.com` URLs only work after this repository exists on GitHub with that owner/name and branch.

---

## Optional: install from a local clone

If you already cloned `https://github.com/OWNER/agent-skills.git` (for example at `~/agent-skills` or `%USERPROFILE%\agent-skills`):

**PowerShell**

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "$env:USERPROFILE\agent-skills\tools\install-agent-skills.ps1" -TargetProject . -Flavor Both
```

**Bash**

```bash
"$HOME/agent-skills/tools/install-agent-skills.sh" --target . --flavor both
```

Add the clone’s **`bin`** folder to **`PATH`** to use **`agent-skills.cmd`** / **`agent-skills`** shims (they call the local scripts under `tools/`).

---

## Updating skills in a project

Re-run the **without cloning** command above; each run fetches the latest **`main`** from GitHub and overwrites `.cursor/skills` / `.claude/skills` in the target project. If you use a local clone instead, `git pull` there and re-run `install-agent-skills`.

---

## Validate (maintainers / CI)

Requires a checkout or a downloaded copy of the repo. From the repository root:

**Windows**

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "tools\validate-skills.ps1"
```

**macOS / Linux** ([PowerShell / `pwsh`](https://github.com/PowerShell/PowerShell))

```bash
pwsh -NoProfile -File ./tools/validate-skills.ps1
```

---

## Layout notes

- **`skills/`** is the only bundled content; Cursor and Claude Code both consume the same skill directories from there.
