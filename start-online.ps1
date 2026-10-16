# Starts the Laravel API, Reverb, the Vite dev server and an ngrok tunnel.
# The Vite dev server proxies /api and /app (Reverb WebSocket), so the single
# ngrok URL serves the web admin, the REST API and the realtime channel.

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$backend = Join-Path $root 'tmc-ebm-system-web\backend'
$frontend = Join-Path $root 'tmc-ebm-system-web\frontend'

Start-Process powershell -WorkingDirectory $backend  -ArgumentList '-NoExit', '-Command', 'php artisan serve --host=127.0.0.1 --port=8000'
Start-Process powershell -WorkingDirectory $backend  -ArgumentList '-NoExit', '-Command', 'php artisan reverb:start'
Start-Process powershell -WorkingDirectory $frontend -ArgumentList '-NoExit', '-Command', 'npm run dev'

Start-Sleep -Seconds 3
Start-Process powershell -ArgumentList '-NoExit', '-Command', 'ngrok http 5180'

Write-Host ''
Write-Host 'Open the ngrok https URL in a browser for the web admin.'
Write-Host 'For the mobile app, run from tmcebms/:'
Write-Host '  flutter run --dart-define=API_BASE_URL=https://<ngrok-host>/api'
