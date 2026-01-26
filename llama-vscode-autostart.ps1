# ============================================================
# llama.cpp Autostart - visible terminal (MCP safe)
# Qwen2.5-Coder-7B (CUDA / GPU)
# ============================================================

# Disable output buffering for real-time display
$PSDefaultParameterValues['*:ErrorAction'] = 'Continue'
$output = New-Object System.Diagnostics.ProcessStartInfo

# ============================================================
# Check if llama-server is already running
# ============================================================
$running = Get-CimInstance Win32_Process |
    Where-Object { $_.CommandLine -like "*llama-server.exe*" } |
    Select-Object -First 1

if ($running) {
    Write-Host "llama-server läuft bereits (PID: $($running.ProcessId))"
    exit 0
}

# ============================================================
# CONFIGURATION (aus zentraler Datei)
# ============================================================
$configPath = "C:\Users\marku\Documents\GitHub\artqcid\ai-projects\qwen2.5-7b-training\llama_config.json"
if (-not (Test-Path $configPath)) {
    Write-Host "ERROR: llama_config.json nicht gefunden: $configPath"
    Read-Host
    exit 1
}
$config = Get-Content $configPath | ConvertFrom-Json
$llama = $config.llama_cpp

$llamaCppPath = $llama.llamaCppPath
$modelPath    = $llama.modelPath
$port         = $llama.port
$ctxSize      = $llama.ctxSize
$batchSize    = $llama.batchSize
$ubatchSize   = $llama.ubatchSize
$parallel     = $llama.parallel
$threads      = $llama.threads
$gpuLayers    = $llama.gpuLayers
$cacheK       = $llama.cacheK
$cacheV       = $llama.cacheV
$temp         = $llama.temp
$topK         = $llama.topK
$topP         = $llama.topP
$repeatPen    = $llama.repeatPen
$mirostat     = $llama.mirostat
$flashAttn    = $llama.flashAttn
$chatTemplate = $llama.chatTemplate

# ============================================================
# CHECKS
# ============================================================
if (-not (Test-Path $llamaCppPath)) {
    Write-Host "ERROR: llama-server.exe not found"
    Read-Host
    exit 1
}

if (-not (Test-Path $modelPath)) {
    Write-Host "ERROR: model file not found"
    Read-Host
    exit 1
}

# ============================================================
# START SERVER (VISIBLE TERMINAL - NO BUFFERING)
# ============================================================
Clear-Host
Write-Host "============================================"
Write-Host " llama.cpp CUDA server"
Write-Host " Model: Qwen2.5-Coder-7B"
Write-Host " Server: http://127.0.0.1:$port"
Write-Host " GPU layers: $gpuLayers"
Write-Host "============================================"
Write-Host ""

# Starte llama-server direkt ohne Buffering
$process = New-Object System.Diagnostics.ProcessStartInfo
$process.FileName = $llamaCppPath
$process.Arguments = "--model `"$modelPath`" --chat-template $chatTemplate --port $port --ctx-size $ctxSize --batch-size $batchSize --ubatch-size $ubatchSize --parallel $parallel --threads $threads --n-gpu-layers $gpuLayers --cache-type-k $cacheK --cache-type-v $cacheV --temp $temp --top-k $topK --top-p $topP --repeat-penalty $repeatPen --mirostat $mirostat --flash-attn auto --no-mmap --fit off"
$process.UseShellExecute = $false
$process.RedirectStandardOutput = $false
$process.RedirectStandardError = $false
$process.CreateNoWindow = $false

$proc = [System.Diagnostics.Process]::Start($process)
$proc.WaitForExit()

Write-Host ""
Write-Host "llama.cpp beendet"
