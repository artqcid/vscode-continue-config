# Stop Llama.cpp Server
$proc = Get-Process llama-server -ErrorAction SilentlyContinue
if ($proc) {
    Write-Host "Stopping Llama Server (PID: $($proc.Id))..." -ForegroundColor Yellow
    $proc | Stop-Process -Force
    Write-Host "Llama Server stopped." -ForegroundColor Green
} else {
    Write-Host "Llama Server is not running." -ForegroundColor Gray
}
