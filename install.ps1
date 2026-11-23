# Instala a status line no Claude Code (Windows)
$ErrorActionPreference = 'Stop'

$claudeDir = if ($env:CLAUDE_CONFIG_DIR) { $env:CLAUDE_CONFIG_DIR } else { Join-Path $HOME '.claude' }
$dest = Join-Path $claudeDir 'statusline.ps1'
$settings = Join-Path $claudeDir 'settings.json'

New-Item -ItemType Directory -Force -Path $claudeDir | Out-Null
Copy-Item (Join-Path $PSScriptRoot 'statusline.ps1') $dest -Force

if (Test-Path $settings) {
  Copy-Item $settings "$settings.bak" -Force
  $cfg = Get-Content $settings -Raw | ConvertFrom-Json
} else {
  $cfg = New-Object PSObject
}

$shell = if (Get-Command pwsh -ErrorAction SilentlyContinue) { 'pwsh' } else { 'powershell' }
$cmd = "$shell -NoProfile -ExecutionPolicy Bypass -File `"$dest`""
$sl = [PSCustomObject]@{ type = 'command'; command = $cmd }
$cfg | Add-Member -NotePropertyName statusLine -NotePropertyValue $sl -Force

$json = $cfg | ConvertTo-Json -Depth 20
[System.IO.File]::WriteAllText($settings, $json, (New-Object System.Text.UTF8Encoding $false))

Write-Host "Status line instalada em $dest"
Write-Host "settings.json atualizado (backup em $settings.bak). Reinicie o Claude Code."
