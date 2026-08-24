param([string]$TraktorRoot="")
$ErrorActionPreference = "Stop"

$Here = Split-Path -Parent $MyInvocation.MyCommand.Path

if (-not $TraktorRoot -and (Test-Path (Join-Path $Here ".last_root"))) {
  $TraktorRoot = (Get-Content (Join-Path $Here ".last_root") -Raw).Trim()
}

if (-not $TraktorRoot) {
  $TraktorRoot = Read-Host "Enter the modified Traktor Pro 4 folder"
}

$D2Dir = Join-Path $TraktorRoot "Resources64\qml\CSI\D2"
if (-not (Test-Path $D2Dir)) {
  Write-Host "D2 folder not found."
  exit 1
}

$backup = ""
if (Test-Path (Join-Path $Here ".last_backup")) {
  $backup = (Get-Content (Join-Path $Here ".last_backup") -Raw).Trim()
}

if (-not $backup -or -not (Test-Path $backup)) {
  $candidate = Get-ChildItem $D2Dir -Directory -Filter "PerformanceDisplay_BACKUP_v0_18_23_*" |
    Sort-Object Name |
    Select-Object -Last 1
  if ($candidate) { $backup = $candidate.FullName }
}

if (-not $backup -or -not (Test-Path $backup)) {
  Write-Host "Backup not found."
  exit 1
}

$files = @(
  "NativeDisplayWindow.qml",
  "NativeDeckPanel.qml",
  "NativeOverviewStripe.qml",
  "NativeBeatGridOverlay.qml",
  "NativeStripeCueMarkers.qml",
  "NativeFxPanel.qml",
  "NativeCueMarkerOverlay.qml"
)

Copy-Item (Join-Path $backup "D2.qml") (Join-Path $D2Dir "D2.qml") -Force

foreach ($f in $files) {
  $b = Join-Path $backup $f
  $dst = Join-Path $D2Dir $f
  if (Test-Path $b) {
    Copy-Item $b $dst -Force
  } elseif (Test-Path $dst) {
    Remove-Item $dst -Force
  }
}

Write-Host "Rollback complete." -ForegroundColor Green
