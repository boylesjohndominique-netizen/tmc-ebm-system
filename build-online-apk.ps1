# Builds a release APK that talks to the online (Cloudflare) backend.
# Starts Laravel, Reverb and the Vite proxy if they are not already listening,
# opens a Cloudflare quick tunnel in front of the Vite proxy (which forwards
# /api and /app), then bakes the public URL into the APK.
#
# Quick-tunnel hostnames change on every restart, so re-run this script after
# restarting the tunnel.
#
#   .\build-online-apk.ps1                      # new tunnel + build
#   .\build-online-apk.ps1 -PublicUrl <url>     # reuse a running tunnel
#   .\build-online-apk.ps1 -SkipBuild           # only start tunnel / check it

param(
    [string]$PublicUrl = '',
    [switch]$SkipBuild
)

$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$backend = Join-Path $root 'tmc-ebm-system-web\backend'
$frontend = Join-Path $root 'tmc-ebm-system-web\frontend'
$app = Join-Path $root 'tmcebms'
$urlFile = Join-Path $root 'online-url.txt'

function Test-PortBusy([int]$Port) {
    return [bool](Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue)
}

if (-not (Test-PortBusy 8000)) {
    Start-Process powershell -WorkingDirectory $backend -ArgumentList '-NoExit', '-Command', 'php artisan serve --host=127.0.0.1 --port=8000'
}
if (-not (Test-PortBusy 8080)) {
    Start-Process powershell -WorkingDirectory $backend -ArgumentList '-NoExit', '-Command', 'php artisan reverb:start'
}
if (-not (Test-PortBusy 5180)) {
    Start-Process powershell -WorkingDirectory $frontend -ArgumentList '-NoExit', '-Command', 'npm run dev'
}

if ($PublicUrl) {
    $PublicUrl = $PublicUrl.TrimEnd('/')
} else {
    $cloudflared = (Get-Command cloudflared -ErrorAction SilentlyContinue).Source
    if (-not $cloudflared) { $cloudflared = 'C:\Program Files (x86)\cloudflared\cloudflared.exe' }
    if (-not (Test-Path $cloudflared)) {
        throw 'cloudflared not found. Install it with: winget install Cloudflare.cloudflared'
    }

    $log = Join-Path $env:TEMP 'cloudflared-online.log'
    if (Test-Path $log) { Remove-Item $log -Force }
    Start-Process powershell -ArgumentList '-NoExit', '-Command', "& '$cloudflared' tunnel --url http://127.0.0.1:5180 *> '$log'"

    for ($i = 0; $i -lt 60 -and -not $PublicUrl; $i++) {
        Start-Sleep -Seconds 1
        if (Test-Path $log) {
            $match = Select-String -Path $log -Pattern 'https://[a-z0-9-]+\.trycloudflare\.com' | Select-Object -First 1
            if ($match) { $PublicUrl = $match.Matches[0].Value }
        }
    }
    if (-not $PublicUrl) { throw "Could not read the Cloudflare URL. Check the tunnel window or $log" }
}

Set-Content -Path $urlFile -Value $PublicUrl

# Sanity check: /api/login with an empty body answers 422 only if the tunnel
# reaches Laravel through the Vite proxy.
try {
    Invoke-WebRequest "$PublicUrl/api/login" -Method POST -Body '{}' -ContentType 'application/json' -Headers @{ Accept = 'application/json' } -UseBasicParsing -TimeoutSec 30 | Out-Null
    Write-Host "Tunnel reachable: $PublicUrl"
} catch {
    $code = $_.Exception.Response.StatusCode.value__
    if ($code -eq 422) {
        Write-Host "Tunnel reachable: $PublicUrl"
    } else {
        throw "Tunnel check failed (HTTP $code). Is the Vite proxy on port 5180 running?"
    }
}

Write-Host ''
Write-Host "Online URL : $PublicUrl"
Write-Host "Web admin  : $PublicUrl/"
Write-Host "Mobile API : $PublicUrl/api"
Write-Host ''

if ($SkipBuild) {
    Write-Host 'Skipping APK build (-SkipBuild).'
    exit 0
}

Push-Location $app
try {
    flutter build apk --release "--dart-define=API_BASE_URL=$PublicUrl/api"
} finally {
    Pop-Location
}

Write-Host ''
Write-Host ('APK: ' + (Join-Path $app 'build\app\outputs\flutter-apk\app-release.apk'))
