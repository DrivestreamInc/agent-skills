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
    [ValidateSet("Cursor", "Claude", "Both")]
    [string] $Flavor = "Both",

    [Parameter()]
    [switch] $DryRun,

    [Parameter()]
    [switch] $KeepDownload
)

$ErrorActionPreference = "Stop"

if (-not $Repository) {
    $Repository = $env:AGENT_SKILLS_GITHUB_REPO
}
if (-not $Repository) {
    Write-Error "Pass -Repository OWNER/REPO (e.g. octocat/agent-skills) or set environment variable AGENT_SKILLS_GITHUB_REPO."
    exit 1
}

if ($Repository -notmatch '^([^/]+)/([^/]+)$') {
    Write-Error "Repository must be OWNER/REPO with a single slash (got: $Repository)"
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
        SourceRoot      = $extractRoot.FullName
        TargetProject   = $TargetProject
        Flavor          = $Flavor
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
