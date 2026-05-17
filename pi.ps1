#!/usr/bin/env pwsh

param(
    [Parameter(Mandatory=$false, Position=0)]
    [string]$project
)

$projectsPath = "C:\Users\bfang\Projects"
$llamaServerPath = $projectsPath + "\llama\llama-server.exe"

$process = Get-Process -Name "llama-server" -ErrorAction SilentlyContinue

if (!$process) {
    $args = @(
        "-m", "D:\ai-models\unsloth\Qwen3.6-27B-GGUF\Qwen3.6-27B-UD-IQ3_XXS.gguf",
        "--temp", "0.6",
        "--top-p", "0.95",
        "--top-k", "20",
        "--min-p", "0.0",
        "--presence-penalty", "0.0",
        "--repeat-penalty", "1.0",
        "--fit", "off",
        "--no-mmap",
        "--n-gpu-layers", "-1",
        "--parallel", "1",
        "--flash-attn", "on",
        "--cache-type-v", "q8_0",
        "--cache-type-k", "q8_0",
        "--cache-ram", "4096",
        "-c", "50000"
    )
    Start-Process $llamaServerPath -ArgumentList $args -NoNewWindow -RedirectStandardError "NUL"
}

function WaitForDocker {
    docker info *> $null
    if ($LASTEXITCODE -ne 0) {
        return $true
    }
    return $false
}

if (WaitForDocker -eq $true) {
    Write-Host "Starting Docker..."
    Start-Process "C:\Program Files\Docker\Docker\Docker Desktop.exe"
    while (WaitForDocker -eq $true) {
        Start-Sleep -Seconds 1
    }
}

if ($project) {
    $projectPath = $projectsPath + "\" + $project 
} else {
    $project = Split-Path -Leaf $PWD
    $projectPath = $PWD
} 
$volume = $project -replace "[-.]", "_"
# Prepare volume
$args = @(
    "run",
    "--rm",
    "--mount",
    "src=${volume},destination=/mnt",
    "--workdir", "/mnt"
    "alpine",
    "sh", "-c", "mkdir -p node_modules .pnpm-store && chown 1000:1000 /mnt/node_modules .pnpm-store"
)
docker @args

# Start docker container
$args = @(
    "run"
    "--rm", 
    "-it",
    "--volume", "$projectPath\:/app/$project",
    "--mount", "type=volume,src=$volume,volume-subpath=node_modules,destination=/app/$project/node_modules"
    "--mount", "src=$volume,volume-subpath=.pnpm-store,destination=/app/$project/.pnpm-store"
    "--workdir", "/app/$project",
    "--env", "ANTHROPIC_API_KEY=sk-not-a-real-key"
    "agent", 
    "tmux"
)
docker @args

