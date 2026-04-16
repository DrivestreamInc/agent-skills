<#
  Validates that each skills/<name>/SKILL.md exists and has YAML frontmatter
  with non-empty 'name' and 'description' (single-line values).
#>
[CmdletBinding()]
param(
    [Parameter()]
    [string] $SourceRoot = ""
)

$ErrorActionPreference = "Stop"

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not $SourceRoot) {
    $SourceRoot = Split-Path -Parent $ScriptDir
}

$skillsRoot = Join-Path $SourceRoot "skills"
if (-not (Test-Path -LiteralPath $skillsRoot)) {
    Write-Error "skills directory not found: $skillsRoot"
    exit 1
}

$failed = $false
Get-ChildItem -LiteralPath $skillsRoot -Directory | ForEach-Object {
    $dirName = $_.Name
    $skillMd = Join-Path $_.FullName "SKILL.md"
    if (-not (Test-Path -LiteralPath $skillMd)) {
        Write-Host "MISSING SKILL.md: $dirName" -ForegroundColor Red
        $script:failed = $true
        return
    }
    $raw = Get-Content -LiteralPath $skillMd -Raw
    if ($raw -notmatch '(?ms)\A---\s*\r?\n(.*?)\r?\n---\s*\r?\n') {
        Write-Host "INVALID frontmatter block: $dirName" -ForegroundColor Red
        $script:failed = $true
        return
    }
    $yaml = $Matches[1]
    if ($yaml -notmatch '(?m)^name:\s*(.+)\s*$') {
        Write-Host "MISSING or invalid name: $dirName" -ForegroundColor Red
        $script:failed = $true
        return
    }
    $fmName = $Matches[1].Trim().Trim("'`"")
    if ($yaml -notmatch '(?m)^description:\s*(.+)\s*$') {
        Write-Host "MISSING or invalid description: $dirName" -ForegroundColor Red
        $script:failed = $true
        return
    }
    $fmDesc = $Matches[1].Trim().Trim("'`"")
    if ([string]::IsNullOrWhiteSpace($fmDesc)) {
        Write-Host "EMPTY description: $dirName" -ForegroundColor Red
        $script:failed = $true
    }
    if ($dirName -ne $fmName) {
        Write-Host "WARN: folder '$dirName' != frontmatter name '$fmName'" -ForegroundColor Yellow
    }
}

if ($failed) {
    exit 1
}
Write-Host "All skills validated OK."
exit 0
