#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Cleanup script to stop all servers when VSCode closes

.DESCRIPTION
    Stops RAG server, Embedding server, MCP server, and optionally Qdrant
    when VS Code is being closed.
#>

$ErrorActionPreference = "SilentlyContinue"

function Stop-ProcessByName {
    param([string]$ProcessName, [string]$CommandFilter = $null)
    
    $procs = Get-Process $ProcessName -ErrorAction SilentlyContinue
    
    if ($procs) {
        foreach ($proc in $procs) {
            if ($CommandFilter) {
                try {
                    $cmdline = (Get-CimInstance Win32_Process -Filter "ProcessId=$($proc.Id)" -ErrorAction SilentlyContinue).CommandLine
                    if ($cmdline -like "*$CommandFilter*") {
                        $proc | Stop-Process -Force -ErrorAction SilentlyContinue
                        Write-Host "Stopped $($proc.ProcessName) (PID: $($proc.Id))"
                    }
                } catch {}
            } else {
                $proc | Stop-Process -Force -ErrorAction SilentlyContinue
                Write-Host "Stopped $($proc.ProcessName) (PID: $($proc.Id))"
            }
        }
    }
}

Write-Host "=== Cleaning up servers ===" -ForegroundColor Yellow

# Stop RAG Server (Python process with rag_server)
Write-Host "Stopping RAG Server..." -ForegroundColor Cyan
Stop-ProcessByName "python" "rag_server"

# Stop Embedding Server (Python process with embedding)
Write-Host "Stopping Embedding Server..." -ForegroundColor Cyan
Stop-ProcessByName "python" "embedding"

# Stop MCP Server (Python process with mcp)
Write-Host "Stopping MCP Server..." -ForegroundColor Cyan
Stop-ProcessByName "python" "mcp"

# Stop Qdrant
Write-Host "Stopping Qdrant..." -ForegroundColor Cyan
Stop-ProcessByName "qdrant"

Write-Host "=== Cleanup complete ===" -ForegroundColor Green
