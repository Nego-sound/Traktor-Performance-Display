param([string]$TraktorRoot="")
$ErrorActionPreference = "Stop"

$ExpectedOriginal = "8bdfde9883f379796ddcc848eae78c39986bce15c9bdbb46620f3ab24388b838"
$ExpectedPatched  = "bbd8d2c351178c50f81651cfaf78c2e4c7fbba7a210b0e0640e7b05f33ae93cf"
$Here = Split-Path -Parent $MyInvocation.MyCommand.Path
$Payload = Join-Path $Here "payload"

function Fail([string]$m) {
  Write-Host ""
  Write-Host "ERROR: $m" -ForegroundColor Red
  Write-Host "Nothing further was changed."
  exit 1
}

Write-Host "Traktor Performance Display v0.18.23 - Windows"
Write-Host ""
Write-Host "This installer patches EXACTLY the Traktor folder you enter."
Write-Host "If you want a separate copy, make that copy yourself FIRST."
Write-Host ""
if (-not $TraktorRoot) {
  Write-Host "Typical folder: C:\Program Files\Native Instruments\Traktor Pro 4"
  $TraktorRoot = Read-Host "Enter the EXACT Traktor Pro 4 folder you want to patch"
}
if (-not (Test-Path $TraktorRoot)) { Fail "Traktor folder not found: $TraktorRoot" }
Write-Host ""
Write-Host "ABOUT TO PATCH:"
Write-Host "  $TraktorRoot"
$confirm = Read-Host "Type Y or YES to continue (pressing Enter alone cancels)"
$c = $confirm.Trim().ToUpper()
if ($c -ne "Y" -and $c -ne "YES") { Fail "Installation cancelled." }

$D2Dir = Join-Path $TraktorRoot "Resources64\qml\CSI\D2"
$D2 = Join-Path $D2Dir "D2.qml"
if (-not (Test-Path $D2)) { Fail "D2.qml not found at $D2" }

$current = (Get-FileHash -Algorithm SHA256 $D2).Hash.ToLower()
if ($current -eq $ExpectedPatched) { Fail "This build already appears to be installed." }
if ($current -ne $ExpectedOriginal) { Fail "Unsupported D2.qml. This installer is locked to clean Traktor Pro 4.5.0.7." }

$files = @(
  "D2.qml",
  "NativeDisplayWindow.qml",
  "NativeDeckPanel.qml",
  "NativeOverviewStripe.qml",
  "NativeBeatGridOverlay.qml",
  "NativeStripeCueMarkers.qml",
  "NativeFxPanel.qml",
  "NativeCueMarkerOverlay.qml"
)

foreach ($f in $files) {
  if (-not (Test-Path (Join-Path $Payload $f))) { Fail "Payload missing: $f" }
}

$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$backup = Join-Path $D2Dir ("PerformanceDisplay_BACKUP_v0_18_23_" + $stamp)
New-Item -ItemType Directory -Path $backup | Out-Null

Copy-Item $D2 (Join-Path $backup "D2.qml")

foreach ($f in $files | Where-Object { $_ -ne "D2.qml" }) {
  $src = Join-Path $D2Dir $f
  if (Test-Path $src) {
    Copy-Item $src (Join-Path $backup $f)
  }
}

Set-Content -Path (Join-Path $Here ".last_root") -Value $TraktorRoot
Set-Content -Path (Join-Path $Here ".last_backup") -Value $backup

foreach ($f in $files) {
  Copy-Item (Join-Path $Payload $f) (Join-Path $D2Dir $f) -Force
}


Write-Host ""
Write-Host "Verifying installed payload..."
$expectedFiles = @{
"D2.qml"="bbd8d2c351178c50f81651cfaf78c2e4c7fbba7a210b0e0640e7b05f33ae93cf";
"NativeDisplayWindow.qml"="3a7f2512866e2df3a0cd723d0c7cde2b97f16e896a6325fee6edb435303a0d95";
"NativeDeckPanel.qml"="2c84c8cc73b87fbd10e36366966b9de4a30e29fde894023d0cb8f53c4425d3eb";
"NativeOverviewStripe.qml"="28b24ff560f83c1f27fd98f905982bb3f6551cf632716471ada5ee5d191117a5";
"NativeBeatGridOverlay.qml"="4e8104621097dd8322820f748c33536d70c6d6bc5d7ba25920ea654d94704eb4";
"NativeStripeCueMarkers.qml"="5f54d153c06d9c3862d214189bc8c2cb028de8a6ca10ea713c914ed7673613c5";
"NativeFxPanel.qml"="fc09f9cce27d6725af3da6cbde1652bcd680f5c40550258f358e6eeea5484afc";
"NativeCueMarkerOverlay.qml"="eb68d2cab82bfd36cacdabe6943071236cb1e1222ba2430349bc0143c20b7235"
}
foreach ($kv in $expectedFiles.GetEnumerator()) {
  $fp = Join-Path $D2Dir $kv.Key
  if (-not (Test-Path $fp)) { Fail ("Installed file missing: " + $kv.Key) }
  $hh = (Get-FileHash -Algorithm SHA256 $fp).Hash.ToLower()
  if ($hh -ne $kv.Value) { Fail ("Verification failed: " + $kv.Key) }
  Write-Host ("  OK: " + $kv.Key)
}
$d2text = Get-Content $D2 -Raw
if ($d2text -notmatch "StandaloneDisplay4507") { Fail "D2 hook marker missing after install." }
if ($d2text -notmatch "NativeDisplayWindow.qml") { Fail "NativeDisplayWindow reference missing after install." }
Write-Host "  D2 standalone-display hook verified."

$newHash = (Get-FileHash -Algorithm SHA256 $D2).Hash.ToLower()
if ($newHash -ne $ExpectedPatched) { Fail "Post-install D2 verification failed." }

Write-Host ""
Write-Host "INSTALL COMPLETE" -ForegroundColor Green
Write-Host ""
Write-Host "Modified Traktor folder:"
Write-Host "  $TraktorRoot"
Write-Host ""
Write-Host "Backup:"
Write-Host "  $backup"
Write-Host ""
Write-Host "Ensure a Traktor Kontrol D2 mapping exists in Preferences > Controller Manager."
Write-Host "See README.txt."
