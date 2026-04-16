<#
  Validates mcps/servers.json: parses as JSON, contains mcpServers with
  docs-langchain and browser-use, each with a url field.
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

$path = Join-Path $SourceRoot "mcps\servers.json"
if (-not (Test-Path -LiteralPath $path)) {
    Write-Error "File not found: $path"
    exit 1
}

$j = Get-Content -LiteralPath $path -Raw | ConvertFrom-Json
if (-not $j.mcpServers) {
    Write-Error "Missing mcpServers in mcps/servers.json"
    exit 1
}

$required = @("docs-langchain", "browser-use")
foreach ($name in $required) {
    $p = $j.mcpServers.PSObject.Properties[$name]
    if (-not $p) {
        Write-Error "Missing mcpServers entry: $name"
        exit 1
    }
    if (-not $p.Value.url) {
        Write-Error "Missing url for mcpServers.$name"
        exit 1
    }
}

$bu = $j.mcpServers.'browser-use'
if (-not $bu.headers.'x-browser-use-api-key') {
    Write-Error "browser-use missing headers.x-browser-use-api-key"
    exit 1
}

Write-Host "mcps/servers.json validated OK."
exit 0
