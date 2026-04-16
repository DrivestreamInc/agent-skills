<#
  Copies canonical skills from this repository into a target project's
  .cursor/skills and/or .claude/skills.
#>
[CmdletBinding()]
param(
    [Parameter()]
    [string] $SourceRoot = "",

    [Parameter()]
    [string] $TargetProject = ".",

    [Parameter()]
    [string] $Flavor,

    [Parameter()]
    [switch] $NoInteractive,

    [Parameter()]
    [switch] $DryRun
)

$ErrorActionPreference = "Stop"

function Test-AgentSkillsInteractiveHost {
    try {
        return -not [System.Console]::IsInputRedirected
    } catch {
        return $false
    }
}

function Read-FlavorSelection {
    Write-Host "Where should skills be installed?"
    Write-Host "  1) Cursor  (.cursor/skills)"
    Write-Host "  2) Claude  (.claude/skills)"
    Write-Host "  3) Both"
    while ($true) {
        $c = Read-Host "Choice [1-3] (default 3)"
        if ([string]::IsNullOrWhiteSpace($c)) {
            return "Both"
        }
        switch ($c.Trim()) {
            "1" { return "Cursor" }
            "2" { return "Claude" }
            "3" { return "Both" }
            default { Write-Host "Invalid choice: enter 1, 2, or 3." }
        }
    }
}

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not $SourceRoot) {
    $SourceRoot = Split-Path -Parent $ScriptDir
}

if ($env:AGENT_SKILLS_NONINTERACTIVE -eq "1") {
    $NoInteractive = $true
}

if ($PSBoundParameters.ContainsKey("Flavor")) {
    $resolvedFlavor = $Flavor
} elseif (-not $NoInteractive -and (Test-AgentSkillsInteractiveHost)) {
    $resolvedFlavor = Read-FlavorSelection
} else {
    $resolvedFlavor = "Both"
}

$valid = @("Cursor", "Claude", "Both")
if ($resolvedFlavor -notin $valid) {
    Write-Error "Invalid flavor: $resolvedFlavor (use Cursor, Claude, or Both)"
    exit 1
}

$skillsSource = Join-Path $SourceRoot "skills"
if (-not (Test-Path -LiteralPath $skillsSource)) {
    Write-Error "skills directory not found: $skillsSource"
    exit 1
}

if (-not (Test-Path -LiteralPath $TargetProject)) {
    if ($DryRun) {
        Write-Error "Target project path does not exist: $TargetProject (create it first, or omit -DryRun to create missing directories)"
        exit 1
    }
    New-Item -ItemType Directory -Force -Path $TargetProject | Out-Null
}
try {
    $resolvedTarget = (Resolve-Path -LiteralPath $TargetProject).Path
} catch {
    Write-Error "Target project path does not exist or is not reachable: $TargetProject"
    exit 1
}

function Copy-Tree {
    param(
        [string] $From,
        [string] $To
    )
    if ($DryRun) {
        Write-Host "[dry-run] $From -> $To"
        return
    }
    if (Test-Path -LiteralPath $To) {
        Remove-Item -LiteralPath $To -Recurse -Force
    }
    $parent = Split-Path -Parent $To
    if ($parent -and -not (Test-Path -LiteralPath $parent)) {
        New-Item -ItemType Directory -Force -Path $parent | Out-Null
    }
    Copy-Item -LiteralPath $From -Destination $To -Recurse -Force
}

function Install-Skills {
    param([string] $RelativeDest)

    $destRoot = Join-Path $resolvedTarget $RelativeDest
    Get-ChildItem -LiteralPath $skillsSource -Directory | ForEach-Object {
        $name = $_.Name
        $dest = Join-Path $destRoot $name
        if ($DryRun) {
            Write-Host "[dry-run] copy skill '$name' -> $dest"
        } else {
            if (-not (Test-Path -LiteralPath $destRoot)) {
                New-Item -ItemType Directory -Force -Path $destRoot | Out-Null
            }
            Copy-Tree -From $_.FullName -To $dest
        }
    }
}

switch ($resolvedFlavor) {
    "Cursor" { Install-Skills -RelativeDest (Join-Path ".cursor" "skills") }
    "Claude" { Install-Skills -RelativeDest (Join-Path ".claude" "skills") }
    "Both" {
        Install-Skills -RelativeDest (Join-Path ".cursor" "skills")
        Install-Skills -RelativeDest (Join-Path ".claude" "skills")
    }
}

if (-not $DryRun) {
    Write-Host "Done. Skills installed under target: $resolvedTarget"
}
