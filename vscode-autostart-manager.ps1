#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Start all development servers with auto-cleanup on VSCode exit

.DESCRIPTION
    - Starts all necessary servers (Llama, Embedding, RAG, MCP)
    - Registers a cleanup handler that stops all servers when VSCode closes
    - Monitors VSCode process and cleans up when it exits

.NOTES
    Run this script manually or through VSCode startup tasks
#>

$ErrorActionPreference = "Stop"

function Write-Status {
    param([string]$Message, [string]$Status = "Info")
    $colors = @{
        "Success" = "Green"
        "Error"   = "Red"
        "Warning" = "Yellow"
        "Info"    = "Cyan"
    }
    Write-Host "[$Status] " -ForegroundColor $colors[$Status] -NoNewline
    Write-Host $Message
}

function Stop-AllServers {
    Write-Status "=== Stopping all servers ===" "Warning"
    
    # Stop RAG Server
    $ragProcs = Get-Process python -ErrorAction SilentlyContinue | ForEach-Object {
        try {
            $cmdline = (Get-CimInstance Win32_Process -Filter "ProcessId=$($_.Id)" -ErrorAction SilentlyContinue).CommandLine
            if ($cmdline -like '*rag_server*') { $_ }
        } catch {}
    }
    if ($ragProcs) {
        Write-Status "Stopping RAG Server..." "Info"
        $ragProcs | Stop-Process -Force -ErrorAction SilentlyContinue
        Start-Sleep -Milliseconds 500
    }
    
    # Stop Embedding Server
    $embedProcs = Get-Process python -ErrorAction SilentlyContinue | ForEach-Object {
        try {
            $cmdline = (Get-CimInstance Win32_Process -Filter "ProcessId=$($_.Id)" -ErrorAction SilentlyContinue).CommandLine
            if ($cmdline -like '*embedding*' -and $cmdline -notlike '*rag*') { $_ }
        } catch {}
    }
    if ($embedProcs) {
        Write-Status "Stopping Embedding Server..." "Info"
        $embedProcs | Stop-Process -Force -ErrorAction SilentlyContinue
        Start-Sleep -Milliseconds 500
    }
    
    # Stop MCP Server (narrow match to avoid killing unrelated processes)
    $mcpProcs = Get-Process python -ErrorAction SilentlyContinue | ForEach-Object {
        try {
            $cmdline = (Get-CimInstance Win32_Process -Filter "ProcessId=$($_.Id)" -ErrorAction SilentlyContinue).CommandLine
            if ($cmdline -match '\-m\s+mcp_server' -or $cmdline -match 'web_mcp\.py') { $_ }
        } catch {}
    }
    if ($mcpProcs) {
        Write-Status "Stopping MCP Server..." "Info"
        $mcpProcs | Stop-Process -Force -ErrorAction SilentlyContinue
        Start-Sleep -Milliseconds 500
    }
    
    # Stop Qdrant
    $qdrantProcs = Get-Process qdrant -ErrorAction SilentlyContinue
    if ($qdrantProcs) {
        Write-Status "Stopping Qdrant..." "Info"
        $qdrantProcs | Stop-Process -Force -ErrorAction SilentlyContinue
        Start-Sleep -Milliseconds 500
    }
    
    # Stop Llama Server
    $llamaProcs = Get-Process llama-server -ErrorAction SilentlyContinue
    if ($llamaProcs) {
        Write-Status "Stopping Llama Server..." "Info"
        $llamaProcs | Stop-Process -Force -ErrorAction SilentlyContinue
        Start-Sleep -Milliseconds 500
    }
    
    Write-Status "All servers stopped" "Success"
}

Write-Status "VSCode Auto-Cleanup Monitor Started" "Info"
Write-Status "Servers will be stopped when VSCode closes" "Info"

# Find VSCode process
$vscodeProcess = Get-Process code -ErrorAction SilentlyContinue | Select-Object -First 1

if ($vscodeProcess) {
    Write-Status "VSCode PID: $($vscodeProcess.Id)" "Info"
    Write-Status "Monitoring for VSCode exit..." "Info"
    
    # Wait for VSCode to exit
    while ($true) {
        $isRunning = Get-Process -Id $vscodeProcess.Id -ErrorAction SilentlyContinue
        if (-not $isRunning) {
            Write-Status "VSCode has closed - cleaning up servers" "Warning"
            Stop-AllServers
            exit 0
        }
        Start-Sleep -Seconds 2
    }
} else {
    Write-Status "VSCode process not found" "Error"
    exit 1
}
