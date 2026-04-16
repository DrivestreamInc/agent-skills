# agent-skills

This repository is the **single source of truth** for **agent skills** (Markdown skill packs with YAML frontmatter) and **default MCP server entries** used across projects. Skills live under `skills/<skill-name>/` as `SKILL.md` plus optional supporting files. MCP defaults are defined in `mcps/servers.json` and merged into each target’s Cursor and/or Claude Code configuration. The goal is one place to maintain conventions and tooling so agents and humans install the same bundles everywhere.

**Repository:** [github.com/DrivestreamInc/agent-skills](https://github.com/DrivestreamInc/agent-skills)

```bash
git clone https://github.com/DrivestreamInc/agent-skills.git
```

---

## Quick start

1. **Open a terminal at the root of the project** where you want skills (or MCP defaults) installed—not inside this repo unless you are developing here.
2. **Choose a path:**
   - **Skills only (no clone):** run the bootstrap for your shell ([PowerShell](#install-skills-without-cloning-powershell) or [Bash](#install-skills-without-cloning-bash)). Examples omit `--flavor` / `-Flavor` so you are prompted for Cursor vs Claude vs both on each run (in an interactive terminal; see [Interactive installs](#interactive-installs-and-non-interactive-defaults)).
   - **MCP defaults only:** follow [Install MCP defaults without cloning](#install-mcp-defaults-without-cloning).
   - **You already cloned this repo:** use [Install from a local clone](#install-from-a-local-clone) or add `bin/` to `PATH` and run the shims (`agent-skills`, `agent-mcps`).
3. **Re-run the same install command later** to refresh from `main` ([Updating skills and MCP defaults](#updating-skills-and-mcp-defaults)).

**Bootstrap without cloning:** installers download a GitHub archive to a temp directory, run the normal installer, then delete temp files (unless you opt in to keep them).

---

## Commands (reference)

| Command / script | Purpose |
|------------------|---------|
| `tools/install-from-github.ps1` | **Windows:** download repo from GitHub, install skills into a target project |
| `tools/install-from-github.sh` | **Unix:** same for Bash |
| `tools/install-mcps-from-github.ps1` | **Windows:** download repo, merge MCP defaults only |
| `tools/install-mcps-from-github.sh` | **Unix:** same |
| `tools/install-agent-skills.ps1` | Local skills installer (after clone or from bootstrap) |
| `tools/install-agent-skills.sh` | Local skills installer (Bash) |
| `tools/install-agent-mcps.ps1` | Local MCP merger |
| `tools/install-agent-mcps.sh` | Local MCP merger (Bash; needs `python3` for JSON merge) |
| `tools/validate-skills.ps1` | Validates `skills/*/SKILL.md` frontmatter |
| `tools/validate-mcps.ps1` | Validates `mcps/servers.json` |
| `bin/agent-skills.cmd` | Windows PATH shim → `install-agent-skills.ps1` (needs a checkout; same prompts as the script when `-Flavor` is omitted) |
| `bin/agent-skills` | Unix / Git Bash / WSL PATH shim → `install-agent-skills.sh` (executable on Unix; same prompts when `--flavor` is omitted) |
| `bin/agent-mcps.cmd` | Windows PATH shim → `install-agent-mcps.ps1` |
| `bin/agent-mcps` | Unix PATH shim → `install-agent-mcps.sh` |

---

## Architecture

| Area | Role |
|------|------|
| `skills/<skill-name>/` | Canonical skills copied into target projects |
| `mcps/servers.json` | Canonical MCP entries merged into targets (e.g. `docs-langchain`, `browser-use`) |
| `tools/` | Cross-platform installers and validators |

**Behavior:** installers copy or merge from this layout into `.cursor/skills`, `.claude/skills`, and/or MCP JSON files in the **target** project so teams can commit installed skills and server entries. The MCP installer **merges** JSON: it only adds or updates named entries (see [Where MCP defaults land](#where-mcp-defaults-land)); it does not remove unrelated servers.

---

## Interactive installs and non-interactive defaults

Applies everywhere: **PowerShell on Windows** and **Bash on macOS, Linux, Git Bash, and WSL**.

When you run `install-agent-skills`, `install-from-github`, `install-agent-mcps`, or `install-mcps-from-github` in a **terminal** and you **do not** pass a flavor (`--flavor` / `-Flavor`), the script asks whether to install for **Cursor**, **Claude**, or **both** (skills under `.cursor/skills` / `.claude/skills`; MCP entries merge into `.cursor/mcp.json` / `.mcp.json`).

**Piped or redirected stdin** (for example `curl … | bash`, or PowerShell with redirected stdin) is **not** a TTY, so the installer **defaults to both** with no prompt.

To skip the menu in a non-TTY context without passing a flavor, use **`--no-interactive`** (Bash), **`-NoInteractive`** (PowerShell), or **`AGENT_SKILLS_NONINTERACTIVE=1`**.

**Note:** A piped `curl | bash` has no TTY, so with **`--flavor` omitted** the installer defaults to **both** without prompting.

---

## Where skills land in the target project

| Tool | Path |
|------|------|
| Cursor | `<project>/.cursor/skills/<skill-name>/` |
| Claude Code | `<project>/.claude/skills/<skill-name>/` |

Claude Code also supports `~/.claude/skills/`. These installers default to the **project** root so you can commit the result. If you use `CLAUDE_CONFIG_DIR`, resolve paths relative to that layout. When no flavor is specified and input is **not** interactive, they default to installing **both** Cursor and Claude paths.

---

## Where MCP defaults land

The MCP installer **merges** into existing JSON: it only adds or updates the **`docs-langchain`** and **`browser-use`** entries under `mcpServers`. Any other servers you already had stay as-is.

| Tool | Path |
|------|------|
| Cursor | `<project>/.cursor/mcp.json` |
| Claude Code | `<project>/.mcp.json` |

| Server ID | Purpose |
|-----------|---------|
| `docs-langchain` | LangChain / LangGraph / LangSmith documentation ([docs](https://docs.langchain.com/use-these-docs)) |
| `browser-use` | Browser Use cloud automation ([docs](https://docs.browser-use.com/cloud/guides/mcp-server)) — set a real API key from [Browser Use settings](https://cloud.browser-use.com/settings?tab=api-keys&new=1) (replace `YOUR_API_KEY` in the merged file). **Do not commit live secrets;** keep placeholders in shared repos or use a local-only override workflow your team agrees on. |

Both servers use remote **HTTP** MCP (`url`); no `npx` or Node.js is required for this bundle.

**Cursor:** After install, these entries appear under **Settings → Tools & MCP** (or **Features → Model Context Protocol** in some versions), but **remote MCP servers are off until you turn them on**—that is [Cursor’s behavior](https://cursor.com/docs/context/mcp) for URL-based servers, not something this repo writes into JSON (there is no supported `mcp.json` field today that forces “enabled” on first open). Toggle each server **on** once; afterward Cursor usually remembers. From a terminal you can also run `agent mcp enable docs-langchain` and `agent mcp enable browser-use` ([Cursor CLI](https://cursor.com/docs/cli/mcp)).

---

## Install skills without cloning (recommended)

These commands pull **`main`** from `https://github.com/DrivestreamInc/agent-skills` and copy skills into the **current directory** (your other repo). They do **not** leave a permanent clone on disk (unless you pass keep flags).

### PowerShell

Run these in an **interactive** console so you are prompted for Cursor vs Claude vs both (**`-Flavor`** omitted). Download the bootstrap script once, then run it (works on locked-down machines where `iex irm` is discouraged):

```powershell
$i = "$env:TEMP\agent-skills-install-from-github.ps1"
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/DrivestreamInc/agent-skills/main/tools/install-from-github.ps1" -OutFile $i -UseBasicParsing
powershell -NoProfile -ExecutionPolicy Bypass -File $i -Repository "DrivestreamInc/agent-skills" -TargetProject .
```

Dry run (target folder must already exist):

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File $i -Repository "DrivestreamInc/agent-skills" -TargetProject . -DryRun
```

Optional: set **`AGENT_SKILLS_GITHUB_REPO`** to `DrivestreamInc/agent-skills` so you can omit `-Repository`:

```powershell
$env:AGENT_SKILLS_GITHUB_REPO = "DrivestreamInc/agent-skills"
powershell -NoProfile -ExecutionPolicy Bypass -File $i -TargetProject .
```

Other switches: **`-Ref`** branch name (default `main`), **`-KeepDownload`** leaves the temp extract under `%TEMP%` for debugging.

### Bash

**Download then run** in an interactive terminal so you get the Cursor / Claude / both prompt (**`--flavor`** omitted). A one-line `curl … | bash` is **not** a TTY and defaults to **both** without prompting—see [Interactive installs](#interactive-installs-and-non-interactive-defaults).

```bash
curl -fsSL "https://raw.githubusercontent.com/DrivestreamInc/agent-skills/main/tools/install-from-github.sh" -o /tmp/install-from-github.sh
bash /tmp/install-from-github.sh --repo "DrivestreamInc/agent-skills" --target .
```

Or set **`AGENT_SKILLS_GITHUB_REPO`** and omit **`--repo`**:

```bash
export AGENT_SKILLS_GITHUB_REPO="DrivestreamInc/agent-skills"
curl -fsSL "https://raw.githubusercontent.com/DrivestreamInc/agent-skills/main/tools/install-from-github.sh" -o /tmp/install-from-github.sh
bash /tmp/install-from-github.sh --target .
```

Options: **`--ref`**, **`--dry-run`**, **`--keep-download`**, **`--no-interactive`**. Pass **`--flavor`** only if you want to skip the menu in a script.

`raw.githubusercontent.com` URLs resolve the `main` branch of [DrivestreamInc/agent-skills](https://github.com/DrivestreamInc/agent-skills).

---

## Install MCP defaults without cloning

These commands pull **`main`** and merge [`mcps/servers.json`](mcps/servers.json) into the **current directory** (your other repo). They do **not** change the skills-only bootstrap scripts.

### PowerShell

Run in an **interactive** console (**`-Flavor`** omitted) so you are prompted each time:

```powershell
$i = "$env:TEMP\agent-mcps-install-from-github.ps1"
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/DrivestreamInc/agent-skills/main/tools/install-mcps-from-github.ps1" -OutFile $i -UseBasicParsing
powershell -NoProfile -ExecutionPolicy Bypass -File $i -Repository "DrivestreamInc/agent-skills" -TargetProject .
```

Dry run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File $i -Repository "DrivestreamInc/agent-skills" -TargetProject . -DryRun
```

### Bash

Download then run in an interactive terminal (**`--flavor`** omitted); same TTY note as [skills without cloning](#bash).

```bash
curl -fsSL "https://raw.githubusercontent.com/DrivestreamInc/agent-skills/main/tools/install-mcps-from-github.sh" -o /tmp/install-mcps-from-github.sh
bash /tmp/install-mcps-from-github.sh --repo "DrivestreamInc/agent-skills" --target .
```

Use **`AGENT_SKILLS_GITHUB_REPO`**, **`-Ref`**, **`-KeepDownload`** / **`--keep-download`**, and **`AGENT_SKILLS_NONINTERACTIVE=1`** the same way as the skills bootstrap.

---

## Install from a local clone

If you already cloned `https://github.com/DrivestreamInc/agent-skills.git` (for example at `~/agent-skills` or `%USERPROFILE%\agent-skills`):

**PowerShell**

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "$env:USERPROFILE\agent-skills\tools\install-agent-skills.ps1" -TargetProject .
```

**Bash**

```bash
"$HOME/agent-skills/tools/install-agent-skills.sh" --target .
```

Add the clone’s **`bin`** folder to **`PATH`** so you can run **`agent-skills`** (macOS, Linux, Git Bash, WSL) or **`agent-skills.cmd`** (Windows). Both shims call the installers under `tools/` and show the **same** Cursor / Claude / both menu when you omit flavor in an interactive console.

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

### MCP merge from a local clone

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File "$env:USERPROFILE\agent-skills\tools\install-agent-mcps.ps1" -TargetProject .
```

```bash
"$HOME/agent-skills/tools/install-agent-mcps.sh" --target .
```

Add **`bin`** to **`PATH`** to run **`agent-mcps`** or **`agent-mcps.cmd`** (same flavor menu when `--flavor` / `-Flavor` is omitted in an interactive terminal).

---

## Updating skills and MCP defaults

Re-run the **without cloning** command above; each run fetches the latest **`main`** from GitHub and overwrites `.cursor/skills` / `.claude/skills` in the target project. If you use a local clone instead, `git pull` there and re-run `install-agent-skills`.

For **MCP defaults**, re-run **`install-mcps-from-github`** or **`install-agent-mcps`** the same way; each run re-merges **`docs-langchain`** and **`browser-use`** from the repo’s `mcps/servers.json` into `.cursor/mcp.json` and/or `.mcp.json`.

---

## Validation (maintainers / CI)

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

## Contributing

Change skills under `skills/`, MCP defaults in `mcps/servers.json`, and keep installers in sync. Before opening a PR, run **`validate-skills.ps1`** and **`validate-mcps.ps1`** from a repo checkout.
