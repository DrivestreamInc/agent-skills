# agent-skills

Single source of truth for **agent skills** used across projects. Each skill is a directory with `SKILL.md` (YAML frontmatter + Markdown), plus any supporting files.

**Repository:** [github.com/DrivestreamInc/agent-skills](https://github.com/DrivestreamInc/agent-skills)

```bash
git clone https://github.com/DrivestreamInc/agent-skills.git
```

**Install into another project without cloning:** scripts download a GitHub archive to a temp directory, run the normal installer, then delete the temp files (unless you opt in to keep them).

| Path | Purpose |
|------|---------|
| `skills/<skill-name>/` | Canonical skills copied into targets |
| `tools/install-from-github.ps1` | **No clone (Windows):** download repo from GitHub, then install |
| `tools/install-from-github.sh` | **No clone (Unix):** same, for Bash |
| `tools/install-agent-skills.ps1` | Local installer (used after clone or by the GitHub bootstrap) |
| `tools/install-agent-skills.sh` | Local installer (Bash) |
| `tools/validate-skills.ps1` | Validates `skills/*/SKILL.md` frontmatter |
| `bin/agent-skills.cmd` | Windows PATH shim → [`install-agent-skills.ps1`](tools/install-agent-skills.ps1) (needs a checkout; same interactive prompts as the script when `-Flavor` is omitted) |
| `bin/agent-skills` | macOS / Linux / Git Bash / WSL PATH shim → [`install-agent-skills.sh`](tools/install-agent-skills.sh) (**executable in git** on Unix; same interactive prompts when `--flavor` is omitted) |

## Interactive install (local and bootstrap)

This applies on **all platforms:** **PowerShell on Windows** (including bootstrap and local install) and **Bash on macOS, Linux, Git Bash, and WSL**.

When you run **`install-agent-skills`** or **`install-from-github`** in a **terminal** and you **do not** pass a flavor (`--flavor` / `-Flavor`), the script asks whether to install for **Cursor**, **Claude**, or **both**. Piped or redirected input (for example `curl … | bash`, or PowerShell with redirected stdin) is **not** a TTY, so the installer **defaults to both** with no prompt.

To skip the menu in a terminal without passing a flavor, use **`--no-interactive`** (Bash) or **`-NoInteractive`** (PowerShell), or set **`AGENT_SKILLS_NONINTERACTIVE=1`**.

## Where files land in another project

| Tool | Project-local path |
|------|---------------------|
| Cursor | `<project>/.cursor/skills/<skill-name>/` |
| Claude Code | `<project>/.claude/skills/<skill-name>/` |

Claude Code also supports `~/.claude/skills/`. These installers default to the **project** root so you can commit the result. If you use `CLAUDE_CONFIG_DIR`, resolve paths relative to that layout. When no flavor is specified and input is **not** interactive, they default to installing **both** Cursor and Claude paths.

---

## Install without cloning (recommended)

These commands pull **`main`** from `https://github.com/DrivestreamInc/agent-skills` and copy skills into the **current directory** (your other repo). They do **not** leave a permanent clone on disk (unless you pass keep flags).

### PowerShell (from the target project root)

In an **interactive** console, omit **`-Flavor`** to choose Cursor vs Claude vs both **before** downloading. The examples below pass **`-Flavor Both`** so copy-paste stays deterministic.

Download the bootstrap script once, then run it (works on locked-down machines where `iex irm` is discouraged):

```powershell
$i = "$env:TEMP\agent-skills-install-from-github.ps1"
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/DrivestreamInc/agent-skills/main/tools/install-from-github.ps1" -OutFile $i -UseBasicParsing
powershell -NoProfile -ExecutionPolicy Bypass -File $i -Repository "DrivestreamInc/agent-skills" -TargetProject . -Flavor Both
```

Dry run (target folder must already exist):

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File $i -Repository "DrivestreamInc/agent-skills" -TargetProject . -Flavor Both -DryRun
```

Optional: set **`AGENT_SKILLS_GITHUB_REPO`** to `DrivestreamInc/agent-skills` so you can omit `-Repository`:

```powershell
$env:AGENT_SKILLS_GITHUB_REPO = "DrivestreamInc/agent-skills"
powershell -NoProfile -ExecutionPolicy Bypass -File $i -TargetProject . -Flavor Both
```

Other switches: **`-Ref`** branch name (default `main`), **`-KeepDownload`** leaves the temp extract under `%TEMP%` for debugging.

### Bash (from the target project root)

In an **interactive** terminal, omit **`--flavor`** to choose Cursor vs Claude vs both **before** downloading. The examples below pass **`--flavor both`** so copy-paste stays deterministic.

```bash
curl -fsSL "https://raw.githubusercontent.com/DrivestreamInc/agent-skills/main/tools/install-from-github.sh" | bash -s -- --repo "DrivestreamInc/agent-skills" --target . --flavor both
```

Or set **`AGENT_SKILLS_GITHUB_REPO`** and omit **`--repo`**:

```bash
export AGENT_SKILLS_GITHUB_REPO="DrivestreamInc/agent-skills"
curl -fsSL "https://raw.githubusercontent.com/DrivestreamInc/agent-skills/main/tools/install-from-github.sh" | bash -s -- --target . --flavor both
```

Options: **`--ref`**, **`--dry-run`**, **`--keep-download`**, **`--no-interactive`**. Omit **`--flavor`** in an interactive terminal to choose Cursor vs Claude vs both **before** the archive is downloaded.

**Note:** `raw.githubusercontent.com` URLs resolve the `main` branch of [DrivestreamInc/agent-skills](https://github.com/DrivestreamInc/agent-skills). A piped `curl | bash` has no TTY, so with **`--flavor` omitted** the installer defaults to **both** without prompting.

---

## Optional: install from a local clone

If you already cloned `https://github.com/DrivestreamInc/agent-skills.git` (for example at `~/agent-skills` or `%USERPROFILE%\agent-skills`):

**PowerShell**

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "$env:USERPROFILE\agent-skills\tools\install-agent-skills.ps1" -TargetProject . -Flavor Both
```

**Bash**

```bash
"$HOME/agent-skills/tools/install-agent-skills.sh" --target . --flavor both
```

Add the clone’s **`bin`** folder to **`PATH`** so you can run the short commands **`agent-skills`** (macOS, Linux, Git Bash, WSL) or **`agent-skills.cmd`** (Windows). Both shims call the installers under `tools/` and show the **same** Cursor / Claude / both menu when you omit flavor in an interactive console.

**macOS / Linux / Git Bash / WSL** (adjust the path to your clone):

```bash
export PATH="$HOME/agent-skills/bin:$PATH"
cd /path/to/your-project
agent-skills
```

**Windows** (PowerShell; adjust the path to your clone):

```powershell
$env:Path = "$env:USERPROFILE\agent-skills\bin;$env:Path"
Set-Location C:\path\to\your-project
agent-skills.cmd
```

With no **`-Flavor`** / **`--flavor`** in a normal interactive terminal, **`agent-skills`** or **`agent-skills.cmd`** prompts for Cursor vs Claude vs both.

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
