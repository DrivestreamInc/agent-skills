<#
  Merges canonical MCP server entries from mcps/servers.json into a target project's
  .cursor/mcp.json and/or .mcp.json (only keys docs-langchain and browser-use are managed).
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

$ManagedKeys = @("docs-langchain", "browser-use")

function Test-AgentMcpsInteractiveHost {
    try {
        return -not [System.Console]::IsInputRedirected
    } catch {
        return $false
    }
}

function Read-McpFlavorSelection {
    Write-Host "Where should MCP config be merged?"
    Write-Host "  1) Cursor  (.cursor/mcp.json)"
    Write-Host "  2) Claude  (.mcp.json)"
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

function Merge-McpServersIntoFile {
    param(
        [string] $CanonicalPath,
        [string] $DestPath
    )

    $canonical = Get-Content -LiteralPath $CanonicalPath -Raw | ConvertFrom-Json
    if (-not $canonical.mcpServers) {
        Write-Error "Canonical file missing mcpServers: $CanonicalPath"
        exit 1
    }

    $merged = @{}

    if (Test-Path -LiteralPath $DestPath) {
        $existing = Get-Content -LiteralPath $DestPath -Raw | ConvertFrom-Json
        if ($existing.mcpServers) {
            foreach ($prop in $existing.mcpServers.PSObject.Properties) {
                if ($prop.Name -notin $ManagedKeys) {
                    $merged[$prop.Name] = $prop.Value
                }
            }
        }
    }

    foreach ($key in $ManagedKeys) {
        $p = $canonical.mcpServers.PSObject.Properties[$key]
        if (-not $p) {
            Write-Error "Canonical mcpServers missing key: $key"
            exit 1
        }
        $merged[$key] = $p.Value
    }

    $outObj = @{ mcpServers = $merged }
    $json = $outObj | ConvertTo-Json -Depth 10 -Compress:$false
    return $json
}

function Write-McpJsonFile {
    param(
        [string] $DestPath,
        [string] $JsonContent
    )

    $dir = Split-Path -Parent $DestPath
    if ($dir -and -not (Test-Path -LiteralPath $dir)) {
        New-Item -ItemType Directory -Force -Path $dir | Out-Null
    }
    $utf8NoBom = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllText($DestPath, $JsonContent + "`n", $utf8NoBom)
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
} elseif (-not $NoInteractive -and (Test-AgentMcpsInteractiveHost)) {
    $resolvedFlavor = Read-McpFlavorSelection
} else {
    $resolvedFlavor = "Both"
}

$valid = @("Cursor", "Claude", "Both")
if ($resolvedFlavor -notin $valid) {
    Write-Error "Invalid flavor: $resolvedFlavor (use Cursor, Claude, or Both)"
    exit 1
}

$canonicalPath = Join-Path $SourceRoot "mcps\servers.json"
if (-not (Test-Path -LiteralPath $canonicalPath)) {
    Write-Error "MCP manifest not found: $canonicalPath"
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

function Install-McpFile {
    param([string] $RelativeDest)

    $destPath = Join-Path $resolvedTarget $RelativeDest
    if ($DryRun) {
        Write-Host "[dry-run] merge MCP servers -> $destPath"
        return
    }
    $json = Merge-McpServersIntoFile -CanonicalPath $canonicalPath -DestPath $destPath
    Write-McpJsonFile -DestPath $destPath -JsonContent $json.TrimEnd()
    Write-Host "Updated: $destPath"
}

switch ($resolvedFlavor) {
    "Cursor" { Install-McpFile -RelativeDest (Join-Path ".cursor" "mcp.json") }
    "Claude" { Install-McpFile -RelativeDest ".mcp.json" }
    "Both" {
        Install-McpFile -RelativeDest (Join-Path ".cursor" "mcp.json")
        Install-McpFile -RelativeDest ".mcp.json"
    }
}

if (-not $DryRun) {
    Write-Host "Done. MCP defaults merged under target: $resolvedTarget"
}
