# PawPrint — deploy script
#
# Builds the Flutter web app and deploys the build/ folder to a free static host.
# No credit card required. The first time you run this, the chosen host will
# ask for a one-time email signup.
#
# Usage (in PowerShell from the pawprint/ directory):
#   .\scripts\deploy.ps1 -Host netlify       # uses Netlify (interactive login first time)
#   .\scripts\deploy.ps1 -Host surge         # uses Surge.sh (email/password first time)
#   .\scripts\deploy.ps1 -Host cloudflared   # uses a free Cloudflare quick tunnel
#   .\scripts\deploy.ps1 -Host drop          # zips build/web for manual Netlify Drop upload
#
param(
  [ValidateSet('netlify','surge','cloudflared','drop')]
  [string]$Host = 'drop'
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

Write-Host "==> Building Flutter web (release)..." -ForegroundColor Cyan
flutter build web --release

if (-not (Test-Path 'build/web/index.html')) {
  Write-Error "build/web/index.html not found. Build failed."
  exit 1
}

$size = (Get-ChildItem build/web -Recurse | Measure-Object Length -Sum).Sum
Write-Host ("==> Build OK ({0:N1} MB)" -f ($size/1MB)) -ForegroundColor Green

switch ($Host) {
  'netlify' {
    if (-not (Get-Command netlify.cmd -ErrorAction SilentlyContinue)) {
      Write-Host "Installing netlify-cli..." -ForegroundColor Cyan
      & npm.cmd install -g netlify-cli --silent
    }
    Write-Host "==> Deploying to Netlify (browser login on first run)..." -ForegroundColor Cyan
    & netlify.cmd deploy --dir=build/web --prod
  }
  'surge' {
    Write-Host "==> Deploying to Surge (email signup on first run)..." -ForegroundColor Cyan
    & npx.cmd --yes surge build/web pawprint-$(Get-Random).surge.sh
  }
  'cloudflared' {
    if (-not (Get-Command cloudflared -ErrorAction SilentlyContinue)) {
      Write-Host "Downloading cloudflared..." -ForegroundColor Cyan
      $cf = "$env:USERPROFILE\cloudflared.exe"
      Invoke-WebRequest -Uri "https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-windows-amd64.exe" -OutFile $cf
      $env:PATH += ";$env:USERPROFILE"
    }
    Write-Host "==> Starting local server + Cloudflare quick tunnel..." -ForegroundColor Cyan
    Write-Host "Press Ctrl+C to stop." -ForegroundColor Yellow
    $port = 8765
    $srv = Start-Process -FilePath npx.cmd -ArgumentList "--yes","serve","build/web","-l",$port -PassThru -WindowStyle Hidden
    Start-Sleep -Seconds 3
    & cloudflared tunnel --url "http://localhost:$port"
  }
  'drop' {
    $zip = "pawprint-web-$(Get-Date -Format yyyyMMdd-HHmm).zip"
    $zipPath = Join-Path $root $zip
    Write-Host "==> Zipping build/web to $zip..." -ForegroundColor Cyan
    Compress-Archive -Path build/web/* -DestinationPath $zipPath -Force
    Write-Host ""
    Write-Host "==> Done! Upload this zip to https://app.netlify.com/drop" -ForegroundColor Green
    Write-Host "    (no signup needed, just drag and drop the zip onto the page)"
    Write-Host "    Zip: $zipPath"
  }
}
