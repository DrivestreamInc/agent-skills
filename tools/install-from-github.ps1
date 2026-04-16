<#
  Downloads this repository from GitHub (zip), extracts to a temp folder, and runs
  install-agent-skills.ps1 so you do not need a local clone.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string] $Repository = "",

    [Parameter()]
    [string] $Ref = "main",

    [Parameter()]
    [string] $TargetProject = ".",

    [Parameter()]
    [string] $Flavor,

    [Parameter()]
    [switch] $NoInteractive,

    [Parameter()]
    [switch] $DryRun,

    [Parameter()]
    [switch] $KeepDownload
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

if (-not $Repository) {
    $Repository = $env:AGENT_SKILLS_GITHUB_REPO
}
if (-not $Repository) {
    Write-Error "Pass -Repository OWNER/REPO (e.g. DrivestreamInc/agent-skills) or set environment variable AGENT_SKILLS_GITHUB_REPO."
    exit 1
}

if ($Repository -notmatch '^([^/]+)/([^/]+)$') {
    Write-Error "Repository must be OWNER/REPO with a single slash (got: $Repository)"
    exit 1
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

$owner = $Matches[1]
$repo = $Matches[2]
$refSegment = $Ref -replace '/', '%2F'
$zipUrl = "https://github.com/$owner/$repo/archive/refs/heads/$refSegment.zip"

$tmp = Join-Path ([System.IO.Path]::GetTempPath()) ("agent-skills-dl-" + [guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Force -Path $tmp | Out-Null
$zipPath = Join-Path $tmp "repo.zip"

try {
    Write-Host "Downloading $zipUrl"
    Invoke-WebRequest -Uri $zipUrl -OutFile $zipPath -UseBasicParsing
    Expand-Archive -LiteralPath $zipPath -DestinationPath $tmp -Force

    $extractRoot = Get-ChildItem -LiteralPath $tmp -Directory | Where-Object {
        Test-Path -LiteralPath (Join-Path $_.FullName "tools\install-agent-skills.ps1")
    } | Select-Object -First 1

    if (-not $extractRoot) {
        Write-Error "Archive did not contain expected layout (missing tools/install-agent-skills.ps1)."
        exit 1
    }

    $installScript = Join-Path $extractRoot.FullName "tools\install-agent-skills.ps1"
    $installArgs = @{
        SourceRoot    = $extractRoot.FullName
        TargetProject = $TargetProject
        Flavor        = $resolvedFlavor
        NoInteractive = $true
    }
    if ($DryRun) { $installArgs["DryRun"] = $true }
    & $installScript @installArgs
}
finally {
    if (-not $KeepDownload) {
        Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue
    } else {
        Write-Host "Kept download at: $tmp"
    }
}
