# agent-skills

Single source of truth for **agent skills** and **default MCP server entries** used across projects. Each skill is a directory with `SKILL.md` (YAML frontmatter + Markdown), plus any supporting files. MCP defaults are defined in `mcps/servers.json` and merged into each target project’s Cursor and/or Claude Code config.

**Repository:** [github.com/DrivestreamInc/agent-skills](https://github.com/DrivestreamInc/agent-skills)

```bash
git clone https://github.com/DrivestreamInc/agent-skills.git
```

**Install into another project without cloning:** scripts download a GitHub archive to a temp directory, run the normal installer, then delete the temp files (unless you opt in to keep them).

| Path | Purpose |
|------|---------|
| `skills/<skill-name>/` | Canonical skills copied into targets |
| `mcps/servers.json` | Canonical MCP entries merged into targets (`docs-langchain`, `browser-use`) |
| `tools/install-from-github.ps1` | **No clone (Windows):** download repo from GitHub, then install skills |
| `tools/install-from-github.sh` | **No clone (Unix):** same, for Bash |
| `tools/install-mcps-from-github.ps1` | **No clone (Windows):** download repo, then merge MCP defaults |
| `tools/install-mcps-from-github.sh` | **No clone (Unix):** same, for Bash |
| `tools/install-agent-skills.ps1` | Local skills installer (used after clone or by the GitHub bootstrap) |
| `tools/install-agent-skills.sh` | Local skills installer (Bash) |
| `tools/install-agent-mcps.ps1` | Local MCP merger (used after clone or by `install-mcps-from-github`) |
| `tools/install-agent-mcps.sh` | Local MCP merger (Bash; requires `python3` for JSON merge) |
| `tools/validate-skills.ps1` | Validates `skills/*/SKILL.md` frontmatter |
| `tools/validate-mcps.ps1` | Validates `mcps/servers.json` |
| `bin/agent-skills.cmd` | Windows PATH shim → [`install-agent-skills.ps1`](tools/install-agent-skills.ps1) (needs a checkout; same interactive prompts as the script when `-Flavor` is omitted) |
| `bin/agent-skills` | macOS / Linux / Git Bash / WSL PATH shim → [`install-agent-skills.sh`](tools/install-agent-skills.sh) (**executable in git** on Unix; same interactive prompts when `--flavor` is omitted) |
| `bin/agent-mcps.cmd` | Windows PATH shim → [`install-agent-mcps.ps1`](tools/install-agent-mcps.ps1) |
| `bin/agent-mcps` | Unix PATH shim → [`install-agent-mcps.sh`](tools/install-agent-mcps.sh) |

## Interactive install (local and bootstrap)

This applies on **all platforms:** **PowerShell on Windows** (including bootstrap and local install) and **Bash on macOS, Linux, Git Bash, and WSL**.

When you run **`install-agent-skills`**, **`install-from-github`**, **`install-agent-mcps`**, or **`install-mcps-from-github`** in a **terminal** and you **do not** pass a flavor (`--flavor` / `-Flavor`), the script asks whether to install for **Cursor**, **Claude**, or **both** (skills go under `.cursor/skills` / `.claude/skills`; MCP entries merge into `.cursor/mcp.json` / `.mcp.json`). Piped or redirected input (for example `curl … | bash`, or PowerShell with redirected stdin) is **not** a TTY, so the installer **defaults to both** with no prompt.

To skip the menu in a terminal without passing a flavor, use **`--no-interactive`** (Bash) or **`-NoInteractive`** (PowerShell), or set **`AGENT_SKILLS_NONINTERACTIVE=1`**.

## Where files land in another project

| Tool | Project-local path |
|------|---------------------|
| Cursor | `<project>/.cursor/skills/<skill-name>/` |
| Claude Code | `<project>/.claude/skills/<skill-name>/` |

Claude Code also supports `~/.claude/skills/`. These installers default to the **project** root so you can commit the result. If you use `CLAUDE_CONFIG_DIR`, resolve paths relative to that layout. When no flavor is specified and input is **not** interactive, they default to installing **both** Cursor and Claude paths.

## Where MCP defaults land in another project

The MCP installer **merges** into existing JSON: it only adds or updates the **`docs-langchain`** and **`browser-use`** entries under `mcpServers`. Any other servers you already had stay as-is.

| Tool | Project-local path |
|------|---------------------|
| Cursor | `<project>/.cursor/mcp.json` |
| Claude Code | `<project>/.mcp.json` |

| Server ID | Purpose |
|-----------|---------|
| `docs-langchain` | LangChain / LangGraph / LangSmith documentation ([docs](https://docs.langchain.com/use-these-docs)) |
| `browser-use` | Browser Use cloud automation ([docs](https://docs.browser-use.com/cloud/guides/mcp-server)) — set a real API key from [Browser Use settings](https://cloud.browser-use.com/settings?tab=api-keys&new=1) (replace `YOUR_API_KEY` in the merged file). **Do not commit live secrets;** keep placeholders in shared repos or use a local-only override workflow your team agrees on. |

Both servers use remote **HTTP** MCP (`url`); no `npx` or Node.js is required for this bundle.

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

### MCP defaults without cloning (separate bootstrap)

These commands pull **`main`** and merge [`mcps/servers.json`](mcps/servers.json) into the **current directory** (your other repo). They do **not** change the skills-only bootstrap scripts.

**PowerShell** (examples use **`-Flavor Both`** for deterministic copy-paste):

```powershell
$i = "$env:TEMP\agent-mcps-install-from-github.ps1"
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/DrivestreamInc/agent-skills/main/tools/install-mcps-from-github.ps1" -OutFile $i -UseBasicParsing
powershell -NoProfile -ExecutionPolicy Bypass -File $i -Repository "DrivestreamInc/agent-skills" -TargetProject . -Flavor Both
```

Dry run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File $i -Repository "DrivestreamInc/agent-skills" -TargetProject . -Flavor Both -DryRun
```

**Bash:**

```bash
curl -fsSL "https://raw.githubusercontent.com/DrivestreamInc/agent-skills/main/tools/install-mcps-from-github.sh" | bash -s -- --repo "DrivestreamInc/agent-skills" --target . --flavor both
```

Use **`AGENT_SKILLS_GITHUB_REPO`**, **`-Ref`**, **`-KeepDownload`** / **`--keep-download`**, and **`AGENT_SKILLS_NONINTERACTIVE=1`** the same way as the skills bootstrap.

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

**MCP merge from a local clone**

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "$env:USERPROFILE\agent-skills\tools\install-agent-mcps.ps1" -TargetProject . -Flavor Both
```

```bash
"$HOME/agent-skills/tools/install-agent-mcps.sh" --target . --flavor both
```

Add **`bin`** to **`PATH`** to run **`agent-mcps`** or **`agent-mcps.cmd`** (same flavor menu when `--flavor` / `-Flavor` is omitted in an interactive terminal).

---

## Updating skills in a project

Re-run the **without cloning** command above; each run fetches the latest **`main`** from GitHub and overwrites `.cursor/skills` / `.claude/skills` in the target project. If you use a local clone instead, `git pull` there and re-run `install-agent-skills`.

For **MCP defaults**, re-run **`install-mcps-from-github`** or **`install-agent-mcps`** the same way; each run re-merges **`docs-langchain`** and **`browser-use`** from the repo’s `mcps/servers.json` into `.cursor/mcp.json` and/or `.mcp.json`.

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

**MCP manifest**

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "tools\validate-mcps.ps1"
```

```bash
pwsh -NoProfile -File ./tools/validate-mcps.ps1
```

---

## Layout notes

- **`skills/`** holds canonical skills; Cursor and Claude Code both consume the same skill directories from there.
- **`mcps/servers.json`** holds the canonical MCP entries merged by `install-agent-mcps`.
