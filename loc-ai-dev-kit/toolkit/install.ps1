param(
    [string]$TargetDir = (Get-Location).Path
)

$ErrorActionPreference = "Stop"
$SrcDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ClaudeDir = Join-Path $TargetDir ".claude"

New-Item -ItemType Directory -Force -Path $ClaudeDir | Out-Null

function Copy-ClaudeDirectory {
    param([string]$Name)

    $src = Join-Path (Join-Path $SrcDir ".claude") $Name
    $dest = Join-Path $ClaudeDir $Name

    if (Test-Path $src) {
        if (Test-Path $dest) {
            Remove-Item -Recurse -Force $dest
        }

        Copy-Item -Recurse -Force $src $dest
        Write-Host "Installed .claude/$Name"
    }
}

Copy-ClaudeDirectory "commands"
Copy-ClaudeDirectory "skills"
Copy-ClaudeDirectory "agents"

$claudeMd = Join-Path $TargetDir "CLAUDE.md"
$template = Join-Path (Join-Path $SrcDir "templates") "CLAUDE.md"

if (-not (Test-Path $claudeMd)) {
    Copy-Item -Force $template $claudeMd
    Write-Host "Created CLAUDE.md template. Please customize it."
} else {
    Write-Host "CLAUDE.md exists, skipped."
}

Write-Host "Claude toolkit installed into $TargetDir."
