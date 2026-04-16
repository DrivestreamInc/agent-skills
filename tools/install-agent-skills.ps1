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
    [ValidateSet("Cursor", "Claude", "Both")]
    [string] $Flavor = "Both",

    [Parameter()]
    [switch] $DryRun
)

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not $SourceRoot) {
    $SourceRoot = Split-Path -Parent $ScriptDir
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

switch ($Flavor) {
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
